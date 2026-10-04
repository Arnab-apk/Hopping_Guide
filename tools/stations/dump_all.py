import json

with open('data/stations/stations.geojson', 'r', encoding='utf-8') as f:
    d = json.load(f)

with open('tools/stations/all_stations_dump.txt', 'w', encoding='utf-8') as out:
    for i, ft in enumerate(d['features']):
        p = ft['properties']
        name = p.get('name')
        code = p.get('code')
        lat = p.get('lat')
        lon = p.get('lon')
        lines = p.get('lines', [])
        kind = p.get('kind')
        out.write(f"{i:3d} | {name:<35} | {code or '----':<5} | {kind:<5} | {lat:9.5f}, {lon:9.5f} | {lines}\n")

print(f"Dumped {len(d['features'])} stations to tools/stations/all_stations_dump.txt")
