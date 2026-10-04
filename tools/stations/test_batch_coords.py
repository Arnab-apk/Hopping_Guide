import urllib.request
import urllib.parse
import json

titles = [
    'Barrackpore railway station',
    'New Barrackpore railway station',
    'Bally railway station',
    'Bally Ghat railway station',
    'Bally Halt railway station',
    'Belur railway station',
    'Belur Math railway station',
    'Sibaichandi railway station',
    'Gurap railway station',
    'Barddhaman Junction railway station',
    'Katwa Junction railway station',
    'Kamalakantapur railway station',
    'Garia railway station',
    'New Garia railway station',
    'Tollygunge railway station'
]

url = 'https://en.wikipedia.org/w/api.php?action=query&prop=coordinates|pageprops&format=json&titles=' + urllib.parse.quote('|'.join(titles))
req = urllib.request.Request(url, headers={'User-Agent': 'PujaHopperBot/1.0'})
with urllib.request.urlopen(req) as resp:
    data = json.loads(resp.read().decode('utf-8'))

pages = data.get('query', {}).get('pages', {})
for pid, page in pages.items():
    title = page.get('title')
    coords = page.get('coordinates', [])
    if coords:
        c = coords[0]
        print(f"{title}: lat={c['lat']:.5f}, lon={c['lon']:.5f}")
    else:
        print(f"{title}: NO COORDS (missing={'missing' in page})")
