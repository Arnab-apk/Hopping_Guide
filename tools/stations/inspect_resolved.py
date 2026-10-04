import json

with open('tools/stations/raw/resolved_corridor_stations.json', 'r', encoding='utf-8') as f:
    stns = json.load(f)

print(f"Total in resolved_corridor_stations.json: {len(stns)}")
for s in stns:
    lat, lon = s.get('lat'), s.get('lon')
    name = s.get('name')
    code = s.get('code')
    lines = s.get('lines', [])
    wiki = s.get('wiki')
    if lat is None or lon is None:
        print(f"MISSING: {name} [{code}]")
    elif not (22.5 <= lat <= 23.8 and 87.7 <= lon <= 88.6):
        print(f"OUTSIDE NORMAL CORRIDOR: {name} [{code}] ({lat}, {lon}) wiki: {wiki} lines: {lines}")
