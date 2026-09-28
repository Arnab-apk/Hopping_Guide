"""
Fetch Railway and Metro stations from OpenStreetMap using the Overpass API.
License: Open Database License (ODbL) - © OpenStreetMap contributors.
Usage:
    python fetch_osm.py [--all-wb]
"""
import argparse
import json
import pathlib
import sys
import requests

QUERY_BBOX = """
[out:json][timeout:90];
(
  node["railway"="station"](22.30,88.15,22.85,88.60);
  node["railway"="halt"](22.30,88.15,22.85,88.60);
  node["station"="subway"](22.30,88.15,22.85,88.60);
);
out tags center;
"""

QUERY_WB = """
[out:json][timeout:120];
area["name"="West Bengal"]["admin_level"="4"]->.wb;
(
  node["railway"="station"](area.wb);
  node["railway"="halt"](area.wb);
  node["station"="subway"](area.wb);
);
out tags center;
"""

def main():
    parser = argparse.ArgumentParser(description="Fetch OSM railway & metro stations")
    parser.add_argument("--all-wb", action="store_true", help="Fetch for all West Bengal instead of Kolkata bbox")
    args = parser.parse_args()

    query = QUERY_WB if args.all_wb else QUERY_BBOX
    out_dir = pathlib.Path(__file__).parent / "raw"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "osm.json"

    print(f"Fetching stations from Overpass API ({'All West Bengal' if args.all_wb else 'Kolkata Metro Region'})...")
    endpoints = [
        "https://overpass-api.de/api/interpreter",
        "https://maps.mail.ru/osm/tools/overpass/api/interpreter",
        "https://overpass.kumi.systems/api/interpreter",
    ]

    response = None
    for endpoint in endpoints:
        try:
            print(f"Trying endpoint: {endpoint}")
            r = requests.post(
                endpoint,
                data={"data": query},
                headers={"User-Agent": "UMA-KolkataPuja-App/1.0 (contact: arnab@example.com)"},
                timeout=120,
            )
            r.raise_for_status()
            response = r.json()
            break
        except Exception as e:
            print(f"Warning: failed with {endpoint}: {e}")

    if response is None or "elements" not in response:
        print("Error: Failed to fetch from all Overpass endpoints", file=sys.stderr)
        sys.exit(1)

    out_file.write_text(json.dumps(response, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"Success! {len(response['elements'])} elements saved to {out_file}")

if __name__ == "__main__":
    main()
