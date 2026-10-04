import json
import math

R_EARTH = 6371000

def haversine(p1, p2):
    lat1, lon1 = p1
    lat2, lon2 = p2
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = phi2 - phi1
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2.0) ** 2
    return 2 * R_EARTH * math.asin(math.sqrt(a))

with open('data/stations/stations.geojson', 'r', encoding='utf-8') as f:
    d = json.load(f)

features = d['features']
print(f"Total features: {len(features)}")

# Check duplicates by name
by_name = {}
for ft in features:
    name = ft['properties']['name'].strip().lower()
    by_name.setdefault(name, []).append(ft)

print("\n--- DUPLICATE NAMES ---")
for name, list_ft in by_name.items():
    if len(list_ft) > 1:
        print(f"Name '{name}' appears {len(list_ft)} times:")
        for ft in list_ft:
            p = ft['properties']
            print(f"   id={p['id']}, code={p.get('code')}, kind={p['kind']}, coords=({p['lat']}, {p['lon']}), lines={p.get('lines')}")

# Check proximity duplicates (< 300m)
print("\n--- NEARBY STATIONS (< 350m) ---")
for i in range(len(features)):
    for j in range(i + 1, len(features)):
        f1, f2 = features[i], features[j]
        p1, p2 = f1['properties'], f2['properties']
        dist = haversine((p1['lat'], p1['lon']), (p2['lat'], p2['lon']))
        if dist < 350:
            print(f"Distance {dist:.1f}m between '{p1['name']}' [{p1['kind']}, {p1.get('code')}] and '{p2['name']}' [{p2['kind']}, {p2.get('code')}]")
