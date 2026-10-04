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

def fetch_wiki_coords(titles):
    results = {}
    chunk_size = 40
    for i in range(0, len(titles), chunk_size):
        chunk = titles[i:i+chunk_size]
        title_str = '|'.join(chunk)
        url = 'https://en.wikipedia.org/w/api.php?action=query&prop=coordinates|pageprops&redirects=1&format=json&titles=' + urllib.parse.quote(title_str)
        req = urllib.request.Request(url, headers={'User-Agent': 'PujaHopperStationAuditor/1.0'})
        try:
            with urllib.request.urlopen(req, timeout=10) as resp:
                data = json.loads(resp.read().decode('utf-8'))
                query = data.get('query', {})
                normalized = {n['from']: n['to'] for n in query.get('normalized', [])}
                redirects = {r['from']: r['to'] for r in query.get('redirects', [])}
                pages = query.get('pages', {})
                for pid, p in pages.items():
                    title = p.get('title')
                    coords = p.get('coordinates', [])
                    if coords:
                        c = coords[0]
                        results[title] = (c['lat'], c['lon'])
                        wb = p.get('pageprops', {}).get('wikibase_item')
                        # also map original query keys
                        for orig in chunk:
                            curr = orig
                            curr = normalized.get(curr, curr)
                            curr = redirects.get(curr, curr)
                            if curr == title:
                                results[orig] = (c['lat'], c['lon'])
        except Exception as e:
            print(f"Error fetching chunk {i}: {e}")
        time.sleep(0.1)
    return results

def main():
    with open('data/stations/stations.geojson', 'r', encoding='utf-8') as f:
        data = json.load(f)

    rail_stations = [ft for ft in data['features'] if ft['properties']['kind'] == 'rail']
    print(f"Auditing {len(rail_stations)} rail stations...")

    # Build title queries
    title_map = {}
    for ft in rail_stations:
        p = ft['properties']
        name = p['name']
        # Clean name
        clean_name = name.replace(' Junction', '').replace(' Halt', '').strip()
        t1 = f"{clean_name} railway station"
        t2 = f"{name} railway station"
        title_map[t1] = ft
        title_map[t2] = ft

    titles = list(title_map.keys())
    print(f"Querying Wikipedia coordinates for {len(titles)} candidate titles...")
    wiki_coords = fetch_wiki_coords(titles)
    print(f"Received coordinates for {len(wiki_coords)} titles.")

    anomalies = []
    verified = 0

    for ft in rail_stations:
        p = ft['properties']
        name = p['name']
        clean_name = name.replace(' Junction', '').replace(' Halt', '').strip()
        t1 = f"{clean_name} railway station"
        t2 = f"{name} railway station"

        official_coord = wiki_coords.get(t1) or wiki_coords.get(t2)
        if official_coord:
            curr_coord = (p['lat'], p['lon'])
            dist = haversine(curr_coord, official_coord)
            if dist > 800:
                anomalies.append({
                    'id': p['id'],
                    'name': name,
                    'code': p.get('code'),
                    'current': curr_coord,
                    'official': official_coord,
                    'distance_m': round(dist, 1)
                })
            else:
                verified += 1
        else:
            # print unverified
            pass

    print(f"\n--- AUDIT RESULTS ---")
    print(f"Verified within 800m of official Wikipedia/OSM coordinates: {verified}")
    print(f"Anomalies (distance > 800m from official railway station): {len(anomalies)}")
    for a in sorted(anomalies, key=lambda x: -x['distance_m']):
        print(f"  * {a['name']} [{a['code']}]: {a['distance_m']}m off! Current {a['current']} vs Official {a['official']}")

if __name__ == '__main__':
    main()
