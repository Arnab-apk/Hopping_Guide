import json
import urllib.request
import urllib.parse
import math
import sys

R_EARTH = 6371000

def haversine(p1, p2):
    lat1, lon1 = p1
    lat2, lon2 = p2
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    dphi = phi2 - phi1
    dlambda = math.radians(lon2 - lon1)
    a = math.sin(dphi / 2.0) ** 2 + math.cos(phi1) * math.cos(phi2) * math.sin(dlambda / 2.0) ** 2
    return 2 * R_EARTH * math.asin(math.sqrt(a))

def main():
    with open('data/stations/stations.geojson', 'r', encoding='utf-8') as f:
        data = json.load(f)

    rail_stations = [ft for ft in data['features'] if ft['properties']['kind'] == 'rail']
    print(f"Loaded {len(rail_stations)} railway stations.")

    # Build title variations for each station
    query_to_stns = {}
    for ft in rail_stations:
        p = ft['properties']
        name = p['name']
        cname = name.replace(' Junction', '').replace(' Halt', '').replace(' Metro', '').strip()
        variations = [
            f"{name} railway station",
            f"{cname} railway station",
        ]
        if 'Bally' in name:
            if p['lat'] < 22.653 and p['lon'] > 88.345:
                variations.append("Bally Ghat railway station")
            elif p['lat'] < 22.653 and p['lon'] < 88.341:
                variations.append("Bally Halt railway station")
        if 'Belur' in name and p['lon'] > 88.345:
            variations.append("Belur Math railway station")
        if 'Barrackpore' in name and p['lat'] < 22.70:
            variations.append("New Barrackpore railway station")

        for v in variations:
            if v not in query_to_stns:
                query_to_stns[v] = []
            query_to_stns[v].append(ft)

    all_titles = list(query_to_stns.keys())
    print(f"Total titles to query in batch: {len(all_titles)}")

    chunk_size = 50
    wiki_results = {} # title -> (lat, lon)

    for i in range(0, len(all_titles), chunk_size):
        chunk = all_titles[i:i+chunk_size]
        url = 'https://en.wikipedia.org/w/api.php?action=query&prop=coordinates|pageprops&redirects=1&format=json&titles=' + urllib.parse.quote('|'.join(chunk))
        req = urllib.request.Request(url, headers={'User-Agent': 'PujaHopperFastAuditor/1.0'})
        try:
            with urllib.request.urlopen(req, timeout=8) as resp:
                res = json.loads(resp.read().decode('utf-8'))
                query = res.get('query', {})
                normalized = {n['from']: n['to'] for n in query.get('normalized', [])}
                redirects = {r['from']: r['to'] for r in query.get('redirects', [])}
                pages = query.get('pages', {})

                for pid, p in pages.items():
                    title = p.get('title')
                    coords = p.get('coordinates', [])
                    if coords:
                        c = coords[0]
                        coord = (c['lat'], c['lon'])
                        wiki_results[title] = coord
                        # reverse map from original chunk
                        for orig in chunk:
                            target = orig
                            target = normalized.get(target, target)
                            target = redirects.get(target, target)
                            if target == title:
                                wiki_results[orig] = coord
        except Exception as e:
            print(f"Error on chunk {i}: {e}")

    print(f"Resolved coordinates for {len(wiki_results)} titles.")

    # Audit each station
    discrepancies = []
    matched_count = 0

    for ft in rail_stations:
        p = ft['properties']
        name = p['name']
        cname = name.replace(' Junction', '').replace(' Halt', '').replace(' Metro', '').strip()
        v1 = f"{name} railway station"
        v2 = f"{cname} railway station"

        official = wiki_results.get(v1) or wiki_results.get(v2)
        # Check special cases
        if not official:
            for k in wiki_results:
                if cname.lower() in k.lower() and 'railway station' in k.lower():
                    official = wiki_results[k]
                    break

        if official:
            matched_count += 1
            dist = haversine((p['lat'], p['lon']), official)
            if dist > 500:
                discrepancies.append({
                    'id': p['id'],
                    'name': name,
                    'code': p.get('code'),
                    'current': (p['lat'], p['lon']),
                    'official': official,
                    'distance_m': round(dist, 1),
                    'lines': p.get('lines', [])
                })

    print(f"\nTotal stations verified against online Wikipedia: {matched_count}/{len(rail_stations)}")
    print(f"Discrepancies > 500m found: {len(discrepancies)}")
    for d in sorted(discrepancies, key=lambda x: -x['distance_m']):
        print(f"  * {d['name']} [{d['code']}] (lines: {d['lines']}):")
        print(f"      Current:  lat={d['current'][0]:.5f}, lon={d['current'][1]:.5f}")
        print(f"      Official: lat={d['official'][0]:.5f}, lon={d['official'][1]:.5f}")
        print(f"      Error:    {d['distance_m']} meters away!")

if __name__ == '__main__':
    main()
