import json

with open('data/stations/stations.geojson', 'r', encoding='utf-8') as f:
    d = json.load(f)

target_codes = {'MUG', 'MBE', 'SHBC', 'KMAE', 'NDIM', 'KMDC', 'KJME', 'KCY', 'SPS', 'GRAE', 'GUH', 'BP', 'NBE', 'BLY', 'BEQ', 'GIA', 'SHBC', 'KJRA', 'KJRM'}
for ft in d['features']:
    p = ft['properties']
    if p.get('code') in target_codes:
        print(f"{p['name']} [{p.get('code')}] @ ({p['lat']}, {p['lon']}) - lines: {p.get('lines')}")
