import urllib.request
import urllib.parse
import json

sparql = """
SELECT ?item ?itemLabel ?itemDescription ?code ?coord WHERE {
  ?item wdt:P31/wdt:P279* wd:Q55488 .
  OPTIONAL { ?item wdt:P1329 ?code . }
  ?item wdt:P625 ?coord .
  ?item wdt:P131* wd:Q1356 .
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en,bn". }
}
"""

url = 'https://query.wikidata.org/sparql?query=' + urllib.parse.quote(sparql) + '&format=json'
req = urllib.request.Request(url, headers={'User-Agent': 'PujaHopperStationBot/1.0 (test@example.com)'})

try:
    with urllib.request.urlopen(req, timeout=15) as resp:
        data = json.loads(resp.read().decode('utf-8'))
        results = data['results']['bindings']
        print(f"Wikidata returned {len(results)} railway stations in West Bengal!")
        with open('tools/stations/raw/wikidata_wb_stations.json', 'w', encoding='utf-8') as f:
            json.dump(results, f, indent=2, ensure_ascii=False)
except Exception as e:
    print('Error querying SPARQL:', e)
