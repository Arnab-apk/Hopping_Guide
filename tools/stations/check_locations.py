import json

with open('data/stations/stations.geojson', 'r', encoding='utf-8') as f:
    data = json.load(f)

print(f"Total stations: {len(data['features'])}")

corridor_keywords = [
    "Bardhaman", "Katwa", "Bandel", "Dankuni", "Kamarkundu", "Kalna", 
    "Nabadwip", "Bhatar", "Balgona", "Kaichar", "Sheoraphuli", "Memari", 
    "Saktigarh", "Tarakeswar", "Arambagh", "Goghat", "Singur", "Haripal"
]

print("\n--- STATIONS CHECKING COORDINATE ANOMALIES ---")
for f in data['features']:
    p = f['properties']
    lat, lon = p['lat'], p['lon']
    c_lon, c_lat = f['geometry']['coordinates']
    name = p['name']
    code = p.get('code')
    lines = p.get('lines', [])

    if abs(lat - c_lat) > 0.0001 or abs(lon - c_lon) > 0.0001:
        print(f"MISMATCH between geometry and properties: {name} geo=({c_lat},{c_lon}) prop=({lat},{lon})")

    if not (22.0 <= lat <= 24.0 and 87.2 <= lon <= 88.9):
        print(f"OUT OF REGIONAL BOUNDS: {name} [{code}] at ({lat}, {lon})")

print("\n--- ALL CORRIDOR STATIONS SORTED BY LINE ---")
corridor_stns = []
for f in data['features']:
    p = f['properties']
    lines = p.get('lines', [])
    for l in lines:
        if any(k.lower() in l.lower() for k in ["bardhaman", "katwa", "bandel", "chord", "main line"]):
            corridor_stns.append((l, p['name'], p.get('code'), p['lat'], p['lon']))
            break

print(f"Found {len(corridor_stns)} corridor stations:")
for l, name, code, lat, lon in sorted(corridor_stns, key=lambda x: (x[0], x[3])):
    print(f"  [{l}] {name} ({code}): lat={lat:.4f}, lon={lon:.4f}")
