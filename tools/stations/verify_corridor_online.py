import json
import urllib.request
import urllib.parse
import math
import time

R_EARTH = 6371000

def haversine(p1, p2):
    lat1, lon1 = p1
    lat2, lon2 = p2
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = phi2 - phi1
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2.0) ** 2
    return 2 * R_EARTH * math.asin(math.sqrt(a))

def search_wiki_station(query):
    url = f"https://en.wikipedia.org/w/api.php?action=query&list=search&srsearch={urllib.parse.quote(query)}&srlimit=1&format=json"
    req = urllib.request.Request(url, headers={'User-Agent': 'PujaHopperStationAuditor/1.0'})
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            results = data.get('query', {}).get('search', [])
            if results:
                return results[0]['title']
    except Exception as e:
        pass
    return None

def fetch_wiki_coords_single(title):
    url = f"https://en.wikipedia.org/w/api.php?action=query&prop=coordinates|pageprops&redirects=1&format=json&titles={urllib.parse.quote(title)}"
    req = urllib.request.Request(url, headers={'User-Agent': 'PujaHopperStationAuditor/1.0'})
    try:
        with urllib.request.urlopen(req, timeout=5) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            pages = data.get('query', {}).get('pages', {})
            for pid, p in pages.items():
                coords = p.get('coordinates', [])
                if coords:
                    return coords[0]['lat'], coords[0]['lon'], p.get('title')
    except Exception as e:
        pass
    return None

def main():
    with open('data/stations/stations.geojson', 'r', encoding='utf-8') as f:
        data = json.load(f)

    # Focus on corridor stations and suspicious stations
    corridor_keywords = [
        "bardhaman", "katwa", "bandel", "chord", "main line", "sealdah", "howrah", "tarakeswar"
    ]
    
    stns = []
    for ft in data['features']:
        p = ft['properties']
        lines = p.get('lines', [])
        is_corridor = any(any(k in l.lower() for k in corridor_keywords) for l in lines)
        if p['kind'] == 'rail' and (is_corridor or not lines):
            stns.append(ft)

    print(f"Checking {len(stns)} target rail stations...")

    anomalies = []
    for ft in stns:
        p = ft['properties']
        name = p['name']
        code = p.get('code')
        curr_coord = (p['lat'], p['lon'])

        # Try search query
        search_q = f'"{name}" railway station West Bengal'
        best_title = search_wiki_station(search_q)
        if not best_title:
            search_q = f'{name} railway station'
            best_title = search_wiki_station(search_q)

        if best_title:
            res = fetch_wiki_coords_single(best_title)
            if res:
                olat, olon, resolved_title = res
                dist = haversine(curr_coord, (olat, olon))
                if dist > 600:
                    anomalies.append({
                        'id': p['id'],
                        'name': name,
                        'code': code,
                        'current': curr_coord,
                        'official': (olat, olon),
                        'distance_m': round(dist, 1),
                        'resolved_title': resolved_title
                    })
                else:
                    # within 600m
                    pass
        time.sleep(0.05)

    print(f"\n--- DISCREPANCIES FOUND ({len(anomalies)}) ---")
    for a in sorted(anomalies, key=lambda x: -x['distance_m']):
        print(f"  * {a['name']} [{a['code']}]: {a['distance_m']}m away!")
        print(f"      Current:  {a['current']}")
        print(f"      Official: {a['official']} ({a['resolved_title']})")

if __name__ == '__main__':
    main()
