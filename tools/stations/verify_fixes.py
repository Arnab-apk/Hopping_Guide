import json
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

with open('data/stations/stations.geojson', 'r', encoding='utf-8') as f:
    d = json.load(f)

stations = {ft['properties']['name']: ft for ft in d['features']}
by_code = {ft['properties'].get('code'): ft for ft in d['features'] if ft['properties'].get('code')}

print(f"Total stations in stations.geojson: {len(d['features'])}")

checks = [
    ("Barrackpore", "BP", 22.760, 88.371),
    ("New Barrackpore", "NBE", 22.686, 88.444),
    ("Bally", "BLY", 22.655, 88.340),
    ("Bally Ghat", "BLYG", 22.652, 88.348),
    ("Bally Halt", "BLYH", 22.652, 88.338),
    ("Belur", "BEQ", 22.635, 88.340),
    ("Belur Math", "BRMH", 22.631, 88.351),
    ("Garia", "GIA", 22.465, 88.405),
    ("New Garia", "NGRI", 22.472, 88.398),
    ("Naihati Junction", "NH", 22.887, 88.418),
    ("Sibaichandi", "SHBC", 22.974, 88.134),
    ("Gurap", "GRAE", 23.025, 88.112),
    ("Karjana", "KJRA", 23.344, 87.892),
    ("Karjanagram", "KJRM", 23.352, 87.894),
    ("Nandaigram Halt", "NDIM", 23.307, 88.315),
    ("Sripat Shrikhanda", "SPS", 23.619, 88.088),
    ("Barddhaman Junction", "BWN", 23.250, 87.870),
    ("Katwa Junction", "KWAE", 23.639, 88.124),
]

all_passed = True
for name, code, elat, elon in checks:
    stn = stations.get(name) or by_code.get(code)
    if not stn:
        print(f"FAILED: Station {name} [{code}] not found!")
        all_passed = False
        continue
    p = stn['properties']
    lat, lon = p['lat'], p['lon']
    if abs(lat - elat) > 0.015 or abs(lon - elon) > 0.015:
        print(f"FAILED LOCATION: {name} [{p.get('code')}]: found ({lat}, {lon}), expected ~({elat}, {elon})")
        all_passed = False
    else:
        print(f"PASS: {p['name']} [{p.get('code')}] ({lat:.4f}, {lon:.4f}) bn: '{p.get('name_bn')}' lines: {p.get('lines')}")

# Check that hallucinated / non-existent stations are absent
for forbidden in ["Shiblung", "Kamalakantapur", "Karjana Chehar"]:
    found = [s for s in stations if forbidden.lower() in s.lower()]
    if found:
        print(f"FAILED: Forbidden station still present: {found}")
        all_passed = False
    else:
        print(f"PASS: {forbidden} successfully absent.")

if all_passed:
    print("\nALL LOCATION VERIFICATION CHECKS PASSED!")
