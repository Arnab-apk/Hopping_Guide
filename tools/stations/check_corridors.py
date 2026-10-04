import json

with open('data/stations/stations.geojson', encoding='utf-8') as f:
    gj = json.load(f)

def stations_on_line(line_substr):
    return [f for f in gj['features']
            if any(line_substr in (l or '') for l in f['properties'].get('lines', []))]

bwn_katwa = stations_on_line('Barddhaman-Katwa')
bandel_katwa = stations_on_line('Bandel-Katwa')
chord = stations_on_line('Howrah-Bardhaman Chord')
main = stations_on_line('Howrah Main Line')

print(f'=== Barddhaman-Katwa Line ({len(bwn_katwa)} stations) ===')
for s in sorted(bwn_katwa, key=lambda x: x['geometry']['coordinates'][1]):
    p = s['properties']
    c = p.get('coordinates', x['geometry']['coordinates'][::-1] if False else [0,0])
    coords = x['geometry']['coordinates'] if False else s['geometry']['coordinates']
    print(f"  [{p.get('code','')}] {p['name']}  lat={coords[1]:.4f} lon={coords[0]:.4f}")

print(f'\n=== Bandel-Katwa Line ({len(bandel_katwa)} stations) ===')
for s in sorted(bandel_katwa, key=lambda x: x['geometry']['coordinates'][1]):
    p = s['properties']
    coords = s['geometry']['coordinates']
    print(f"  [{p.get('code','')}] {p['name']}  lat={coords[1]:.4f} lon={coords[0]:.4f}")

print(f'\n=== Howrah-Bardhaman Chord ({len(chord)} stations) ===')
for s in sorted(chord, key=lambda x: x['geometry']['coordinates'][0]):
    p = s['properties']
    coords = s['geometry']['coordinates']
    print(f"  [{p.get('code','')}] {p['name']}  lat={coords[1]:.4f} lon={coords[0]:.4f}")

print(f'\n=== Howrah Main Line ({len(main)} stations) ===')
for s in sorted(main, key=lambda x: x['geometry']['coordinates'][0]):
    p = s['properties']
    coords = s['geometry']['coordinates']
    print(f"  [{p.get('code','')}] {p['name']}  lat={coords[1]:.4f} lon={coords[0]:.4f}")
