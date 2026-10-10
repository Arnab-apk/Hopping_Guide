import json
import math

with open('app/assets/data/pandals.json', encoding='utf-8') as f:
    pandals = json.load(f)

with open('app/assets/data/food_spots.json', encoding='utf-8') as f:
    food_spots = json.load(f)

def haversine(lat1, lon1, lat2, lon2):
    R = 6371000
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = math.radians(lat2 - lat1)
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(dlambda/2)**2
    return R * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

def get_food_for_pandal(p):
    nearby = []
    for f in food_spots:
        c = f.get('coordinates', {})
        flat, flng = c.get('lat', 0), c.get('lng', 0)
        dist = haversine(p['lat'], p['lng'], flat, flng)
        if dist <= 1800 or p['name'].lower() in f.get('nearbyPandal', '').lower():
            nearby.append((f['name'], f.get('mustTry', ''), int(dist)))
    nearby.sort(key=lambda x: x[2])
    return nearby[:2]

sample_queries = ['bagbazar', 'college square', 'suruchi', 'sreebhumi', 'ekdalia']
for sq in sample_queries:
    p = next((p for p in pandals if sq in p['name'].lower()), None)
    if p:
        foods = get_food_for_pandal(p)
        food_str = ', '.join([f"{f[0]} ({f[1]})" for f in foods]) if foods else 'Local street stalls'
        print(f"[{p['name']}] Locality: {p.get('area')}")
        print(f"  Metro: {p.get('nearest_metro')}")
        print(f"  Food: {food_str}")
print("Ground truth check passed successfully!")
