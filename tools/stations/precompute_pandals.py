"""
Precompute nearest railway/metro stations for every Durga Puja pandal.
Output:
    Adds `nearest_stations` (top 3 by haversine distance with distance_m) into
    data/pandals.json and app/assets/data/pandals.json.
"""
import json
import math
import pathlib

R_EARTH = 6371000

def haversine(p1, p2):
    lat1, lon1 = p1
    lat2, lon2 = p2
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = phi2 - phi1
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2.0) ** 2
    return int(round(2 * R_EARTH * math.asin(math.sqrt(a))))

def main():
    repo_root = pathlib.Path(__file__).parent.parent.parent
    stations_path = repo_root / "data" / "stations" / "stations.geojson"
    data_pandals_path = repo_root / "data" / "pandals.json"
    app_pandals_path = repo_root / "app" / "assets" / "data" / "pandals.json"

    if not stations_path.exists():
        print(f"Error: {stations_path} does not exist. Run build_stations.py first.")
        return

    stations_data = json.loads(stations_path.read_text(encoding="utf-8"))
    features = stations_data.get("features", [])
    print(f"Loaded {len(features)} stations.")

    stations = []
    for f in features:
        props = f.get("properties", {})
        coords = f.get("geometry", {}).get("coordinates", [])
        if len(coords) < 2:
            continue
        stations.append({
            "id": f.get("id") or props.get("id"),
            "name": props.get("name"),
            "name_bn": props.get("name_bn"),
            "code": props.get("code"),
            "kind": props.get("kind"),
            "lat": coords[1],
            "lon": coords[0],
        })

    for path in [data_pandals_path, app_pandals_path]:
        if not path.exists():
            print(f"Warning: {path} does not exist. Skipping.")
            continue
        pandals = json.loads(path.read_text(encoding="utf-8"))
        print(f"Processing {len(pandals)} pandals in {path.name}...")

        for p in pandals:
            p_lat = p.get("lat")
            p_lng = p.get("lng")
            if p_lat is None or p_lng is None:
                continue

            station_distances = []
            for stn in stations:
                d = haversine((p_lat, p_lng), (stn["lat"], stn["lon"]))
                station_distances.append({
                    "id": stn["id"],
                    "name": stn["name"],
                    "name_bn": stn.get("name_bn"),
                    "code": stn.get("code"),
                    "kind": stn["kind"],
                    "distance_m": d
                })

            station_distances.sort(key=lambda x: x["distance_m"])
            p["nearest_stations"] = station_distances[:3]

        path.write_text(json.dumps(pandals, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"Updated {len(pandals)} pandals in {path}")

if __name__ == "__main__":
    main()
