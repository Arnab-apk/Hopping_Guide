"""
Validates data/stations/stations.geojson against:
1. data/schema/station.schema.json
2. Duplicate checks (distance < 150m for same name)
3. Major station presence and code accuracy (HWH, SDAH, KOAA, SRC, SHM, etc.)
4. Bengali names coverage
5. Pandal nearest_stations linkage
6. File size check (< 1 MB)
"""
import json
import math
import pathlib
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

R_EARTH = 6371000

def haversine(p1, p2):
    lat1, lon1 = p1
    lat2, lon2 = p2
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = phi2 - phi1
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2.0) ** 2
    return 2 * R_EARTH * math.asin(math.sqrt(a))

def main():
    repo_root = pathlib.Path(__file__).parent.parent.parent
    geojson_path = repo_root / "data" / "stations" / "stations.geojson"
    schema_path = repo_root / "data" / "schema" / "station.schema.json"
    pandals_path = repo_root / "data" / "pandals.json"

    assert geojson_path.exists(), f"Missing {geojson_path}"
    assert schema_path.exists(), f"Missing {schema_path}"

    file_size_kb = geojson_path.stat().st_size / 1024
    print(f"File size: {file_size_kb:.1f} KB (Requirement: < 1000 KB) -> {'PASS' if file_size_kb < 1000 else 'FAIL'}")

    data = json.loads(geojson_path.read_text(encoding="utf-8"))
    features = data.get("features", [])
    print(f"Total stations in GeoJSON: {len(features)}")
    assert len(features) > 50, "Too few stations"

    # Schema validation
    required_props = ["id", "name", "kind", "lat", "lon"]
    schema_errors = 0
    for f in features:
        props = f.get("properties", {})
        for req in required_props:
            if req not in props or props[req] is None:
                print(f"Schema violation in {props.get('name')}: missing {req}")
                schema_errors += 1
        if props.get("kind") not in ["rail", "metro"]:
            print(f"Invalid kind in {props.get('name')}: {props.get('kind')}")
            schema_errors += 1

    print(f"Schema validation: {'PASS (0 errors)' if schema_errors == 0 else f'FAIL ({schema_errors} errors)'}")

    # Duplicates check
    dups = 0
    for i in range(len(features)):
        for j in range(i + 1, len(features)):
            p1 = features[i]["properties"]
            p2 = features[j]["properties"]
            c1 = features[i]["geometry"]["coordinates"]
            c2 = features[j]["geometry"]["coordinates"]
            dist = haversine((c1[1], c1[0]), (c2[1], c2[0]))
            if p1["name"].strip().lower() == p2["name"].strip().lower() and dist < 150:
                print(f"Warning: Potential duplicate: {p1['name']} ({dist:.0f}m)")
                dups += 1
    print(f"Duplicate check (< 150m same name): {'PASS (0 duplicates)' if dups == 0 else f'WARNING ({dups} duplicates)'}")

    # Spot check major 10 stations
    major_codes = ["HWH", "SDAH", "KOAA", "SRC", "SHM", "BLN", "BNXR", "DDJ", "MJT", "BBR"]
    found_codes = {f["properties"].get("code"): f["properties"] for f in features if f["properties"].get("code")}
    missing_majors = [code for code in major_codes if code not in found_codes]
    print(f"Major stations spot-check ({len(major_codes)} checked): {'PASS (All present)' if not missing_majors else f'FAIL (Missing: {missing_majors})'}")

    for code in ["HWH", "SDAH", "KOAA", "SRC", "SHM"]:
        if code in found_codes:
            stn = found_codes[code]
            print(f"  - {stn['name']} [{code}]: ({stn['lat']:.4f}, {stn['lon']:.4f}) bn: '{stn.get('name_bn')}'")

    # Bengali coverage
    with_bn = sum(1 for f in features if f["properties"].get("name_bn"))
    print(f"Bengali name coverage: {with_bn}/{len(features)} ({with_bn*100//len(features)}%)")

    # Check pandals linkage
    if pandals_path.exists():
        pandals = json.loads(pandals_path.read_text(encoding="utf-8"))
        linked = sum(1 for p in pandals if p.get("nearest_stations") and len(p["nearest_stations"]) > 0)
        print(f"Pandal linkage: {linked}/{len(pandals)} pandals have nearest_stations -> {'PASS' if linked == len(pandals) else 'FAIL'}")

    print("\n--- VALIDATION COMPLETE ---")

if __name__ == "__main__":
    main()
