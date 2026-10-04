"""
Build, merge, normalize and deduplicate railway and metro stations into canonical GeoJSON.
Input:
    tools/stations/raw/osm.json (from Overpass)
    tools/stations/raw/wikidata.json (from Wikidata SPARQL)
    data/stations/overrides.json (manual overrides & curation)
Output:
    data/stations/stations.geojson (canonical GeoJSON)
    app/assets/data/stations.geojson (bundled mobile app asset)
"""
import json
import math
import pathlib
import re
import shutil
import sys

# Earth radius in metres
R_EARTH = 6371000

def haversine(p1, p2):
    """Calculate distance in metres between (lat1, lon1) and (lat2, lon2)."""
    lat1, lon1 = p1
    lat2, lon2 = p2
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = phi2 - phi1
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2.0) ** 2
    return 2 * R_EARTH * math.asin(math.sqrt(a))

def determine_kind(tags):
    if tags.get("station") == "subway" or tags.get("railway") == "subway":
        return "metro"
    return "rail"

def normalize_name(n):
    """Normalize station name for fuzzy matching."""
    n = re.sub(r'\(.*?\)', '', n)
    n = n.lower()
    for s in ["railway station", "metro station", "junction", "metro", "halt", "station", "cantonment"]:
        n = n.replace(s, "")
    return re.sub(r'[^a-z0-9]', '', n)

EXCLUDE_NAMES = {
    "shiblung halt",
    "kamalakantapur",
    "karjana chehar"
}

def main():
    base_dir = pathlib.Path(__file__).parent
    repo_root = base_dir.parent.parent
    raw_dir = base_dir / "raw"
    osm_path = raw_dir / "osm.json"
    wd_path = raw_dir / "wikidata.json"
    overrides_path = repo_root / "data" / "stations" / "overrides.json"
    out_geojson_path = repo_root / "data" / "stations" / "stations.geojson"
    app_asset_path = repo_root / "app" / "assets" / "data" / "stations.geojson"

    out_geojson_path.parent.mkdir(parents=True, exist_ok=True)
    app_asset_path.parent.mkdir(parents=True, exist_ok=True)

    overrides = {}
    if overrides_path.exists():
        overrides = json.loads(overrides_path.read_text(encoding="utf-8"))

    wd_bindings = []
    if wd_path.exists():
        try:
            wd_data = json.loads(wd_path.read_text(encoding="utf-8"))
            wd_bindings = wd_data.get("results", {}).get("bindings", [])
        except Exception as e:
            print(f"Warning: could not parse wikidata.json: {e}")

    stations = []

    # Process OSM elements if raw/osm.json exists
    if osm_path.exists():
        osm_data = json.loads(osm_path.read_text(encoding="utf-8"))
        elements = osm_data.get("elements", [])
        for e in elements:
            t = e.get("tags", {})
            name = t.get("name:en") or t.get("name")
            if not name:
                continue

            lat = e.get("lat") or (e.get("center", {}).get("lat"))
            lon = e.get("lon") or (e.get("center", {}).get("lon"))
            if lat is None or lon is None:
                continue

            # Match Wikidata by proximity (< 450 m) to get official station code
            code = t.get("railway:ref") or t.get("ref")
            name_bn = t.get("name:bn")
            for w in wd_bindings:
                try:
                    wlat = float(w["lat"]["value"])
                    wlon = float(w["lon"]["value"])
                    if haversine((lat, lon), (wlat, wlon)) < 450:
                        code = code or w.get("code", {}).get("value")
                        if not name_bn and "itemLabel" in w:
                            val = w["itemLabel"]["value"]
                            # Detect Bengali characters
                            if any("\u0980" <= char <= "\u09ff" for char in val):
                                name_bn = val
                        break
                except (KeyError, ValueError):
                    continue

            station_id = f"stn_{e['id']}"
            kind = determine_kind(t)

            stations.append({
                "type": "Feature",
                "id": station_id,
                "geometry": {
                    "type": "Point",
                    "coordinates": [float(lon), float(lat)]
                },
                "properties": {
                    "id": station_id,
                    "name": name,
                    "name_bn": name_bn,
                    "code": code,
                    "kind": kind,
                    "lat": float(lat),
                    "lon": float(lon),
                    "network": t.get("network") or ("Kolkata Metro" if kind == "metro" else "Indian Railways"),
                    "operator": t.get("operator"),
                    "lines": [l.strip() for l in t.get("line", "").split(";") if l.strip()] if t.get("line") else [],
                    "entrances": []
                }
            })

    # Merge curated Tier 1 stations to guarantee all terminal, circular railway and metro stations are present
    from seed_stations import CURATED_TIER1_STATIONS
    for stn in CURATED_TIER1_STATIONS:
        sname_lower = stn["properties"]["name"].strip().lower()
        if any(ex in sname_lower for ex in EXCLUDE_NAMES):
            continue

        sc = stn["geometry"]["coordinates"]
        sname = stn["properties"]["name"].strip()
        scode = stn["properties"].get("code")
        skind = stn["properties"]["kind"]

        matched = False
        for existing in stations:
            ec = existing["geometry"]["coordinates"]
            ename = existing["properties"]["name"].strip()
            ecode = existing["properties"].get("code")
            ekind = existing["properties"]["kind"]
            dist = haversine((sc[1], sc[0]), (ec[1], ec[0]))

            code_match = (scode and ecode and scode == ecode)
            exact_name_match = (sname.lower() == ename.lower() and dist < 600)
            norm_name_match = (normalize_name(sname) == normalize_name(ename) and dist < 500)
            kind_proximity_match = (skind == ekind and dist < 120)

            if code_match or exact_name_match or norm_name_match or kind_proximity_match:
                matched = True
                if not existing["properties"].get("code") and scode:
                    existing["properties"]["code"] = scode
                if stn["properties"].get("name_bn"):
                    existing["properties"]["name_bn"] = stn["properties"]["name_bn"]
                if stn["properties"].get("lines"):
                    curr_lines = existing["properties"].get("lines", [])
                    for l in stn["properties"]["lines"]:
                        if l not in curr_lines:
                            curr_lines.append(l)
                    existing["properties"]["lines"] = curr_lines
                if skind == "metro":
                    existing["properties"]["kind"] = "metro"
                if len(sname) > len(ename) or ("metro" in sname.lower() and "metro" not in ename.lower()):
                    existing["properties"]["name"] = sname
                break

        if not matched:
            stations.append(stn)

    # Apply manual overrides keyed by station id, code, or exact matching name
    for s in stations:
        sid = s["properties"]["id"]
        code = s["properties"].get("code")
        name = s["properties"]["name"].strip().lower()

        matched_override = None
        if sid in overrides:
            matched_override = overrides[sid]
        elif code and code in overrides:
            matched_override = overrides[code]
        else:
            for k, v in overrides.items():
                v_name = v.get("name", "").strip().lower()
                v_code = v.get("code")
                # Strict exact matching ONLY
                if (v_code and code and v_code == code) or (v_name and v_name == name):
                    matched_override = v
                    break

        if matched_override:
            s["properties"].update(matched_override)
            if "lat" in matched_override and "lon" in matched_override:
                s["geometry"]["coordinates"] = [float(matched_override["lon"]), float(matched_override["lat"])]

        # Ensure lat/lon properties match geometry
        c = s["geometry"]["coordinates"]
        s["properties"]["lon"] = c[0]
        s["properties"]["lat"] = c[1]

    # De-duplicate
    unique = []
    for s in stations:
        s_name_lower = s["properties"]["name"].strip().lower()
        if any(ex in s_name_lower for ex in EXCLUDE_NAMES):
            continue

        s_coord = s["geometry"]["coordinates"]
        s_name = s["properties"]["name"].strip()
        s_code = s["properties"].get("code")
        s_kind = s["properties"]["kind"]
        dup = False

        for u in unique:
            u_coord = u["geometry"]["coordinates"]
            u_name = u["properties"]["name"].strip()
            u_code = u["properties"].get("code")
            u_kind = u["properties"]["kind"]
            dist = haversine((s_coord[1], s_coord[0]), (u_coord[1], u_coord[0]))

            # Different non-empty official codes -> definitely distinct stations (e.g. BLY vs BLYH vs BLYG)
            if s_code and u_code and s_code != u_code:
                continue

            code_match = (s_code and u_code and s_code == u_code)
            exact_name_match = (s_name.lower() == u_name.lower() and dist < 600)
            norm_name_match = (normalize_name(s_name) == normalize_name(u_name) and dist < 500)
            close_proximity_match = (s_kind == u_kind and dist < 80)

            if code_match or exact_name_match or norm_name_match or close_proximity_match:
                if not u["properties"].get("code") and s_code:
                    u["properties"]["code"] = s_code
                if not u["properties"].get("name_bn") and s["properties"].get("name_bn"):
                    u["properties"]["name_bn"] = s["properties"]["name_bn"]
                if s["properties"].get("lines"):
                    curr_lines = u["properties"].get("lines", [])
                    for l in s["properties"]["lines"]:
                        if l not in curr_lines:
                            curr_lines.append(l)
                    u["properties"]["lines"] = curr_lines
                dup = True
                break

        if not dup:
            unique.append(s)

    feature_collection = {
        "type": "FeatureCollection",
        "features": unique
    }

    out_geojson_path.write_text(json.dumps(feature_collection, indent=2, ensure_ascii=False), encoding="utf-8")
    shutil.copyfile(out_geojson_path, app_asset_path)

    print(f"Generated {len(unique)} stations in {out_geojson_path} and copied to {app_asset_path}")

if __name__ == "__main__":
    main()
