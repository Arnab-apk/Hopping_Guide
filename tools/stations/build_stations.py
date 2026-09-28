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
import sys
import shutil

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
        sc = stn["geometry"]["coordinates"]
        sname = stn["properties"]["name"].strip().lower()
        scode = stn["properties"].get("code")
        matched = False
        for existing in stations:
            ec = existing["geometry"]["coordinates"]
            ename = existing["properties"]["name"].strip().lower()
            ecode = existing["properties"].get("code")
            dist = haversine((sc[1], sc[0]), (ec[1], ec[0]))
            if (scode and ecode and scode == ecode) or (sname == ename and dist < 500) or dist < 180:
                matched = True
                if not existing["properties"].get("code") and scode:
                    existing["properties"]["code"] = scode
                if not existing["properties"].get("name_bn") and stn["properties"].get("name_bn"):
                    existing["properties"]["name_bn"] = stn["properties"]["name_bn"]
                break
        if not matched:
            stations.append(stn)

    # De-duplicate: same name or within 150m of another station of the same kind
    unique = []
    for s in stations:
        s_coord = s["geometry"]["coordinates"]
        s_name = s["properties"]["name"].strip().lower()
        s_kind = s["properties"]["kind"]
        dup = False
        for u in unique:
            u_coord = u["geometry"]["coordinates"]
            u_name = u["properties"]["name"].strip().lower()
            u_kind = u["properties"]["kind"]
            dist = haversine((s_coord[1], s_coord[0]), (u_coord[1], u_coord[0]))
            if (s_name == u_name and dist < 300) or (s_kind == u_kind and dist < 120):
                # Merge any missing fields into u
                if not u["properties"].get("code") and s["properties"].get("code"):
                    u["properties"]["code"] = s["properties"]["code"]
                if not u["properties"].get("name_bn") and s["properties"].get("name_bn"):
                    u["properties"]["name_bn"] = s["properties"]["name_bn"]
                dup = True
                break
        if not dup:
            unique.append(s)

    # Apply manual overrides keyed by station id, code, or matching name
    for s in unique:
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
                if (v_name and (v_name == name or v_name in name or name in v_name)) or (code and code == v_code):
                    matched_override = v
                    break

        if matched_override:
            s["properties"].update(matched_override)

        # Ensure lat/lon properties match geometry
        c = s["geometry"]["coordinates"]
        s["properties"]["lon"] = c[0]
        s["properties"]["lat"] = c[1]

    feature_collection = {
        "type": "FeatureCollection",
        "features": unique
    }

    out_geojson_path.write_text(json.dumps(feature_collection, indent=2, ensure_ascii=False), encoding="utf-8")
    shutil.copyfile(out_geojson_path, app_asset_path)

    print(f"Generated {len(unique)} stations in {out_geojson_path} and copied to {app_asset_path}")

if __name__ == "__main__":
    main()
