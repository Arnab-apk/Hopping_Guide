"""
Fetch Indian Railway stations with codes, Bengali names, and coordinates from Wikidata.
License: CC0 1.0 Universal (Public Domain).
Usage:
    python fetch_wikidata.py
"""
import json
import pathlib
import sys
import requests

WIKIDATA_SPARQL_ENDPOINT = "https://query.wikidata.org/sparql"

SPARQL_QUERY = """
SELECT ?item ?itemLabel ?code ?lat ?lon WHERE {
  ?item wdt:P31/wdt:P279* wd:Q55488; # railway station or subclass
        wdt:P17 wd:Q668;             # India
        wdt:P296 ?code;              # station code
        wdt:P625 ?coord.
  BIND(geof:latitude(?coord) AS ?lat)
  BIND(geof:longitude(?coord) AS ?lon)
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en,bn". }
}
"""

def main():
    out_dir = pathlib.Path(__file__).parent / "raw"
    out_dir.mkdir(parents=True, exist_ok=True)
    out_file = out_dir / "wikidata.json"

    print("Fetching station data from Wikidata SPARQL endpoint...")
    headers = {
        "User-Agent": "UMA-KolkataPuja-App/1.0 (contact: arnab@example.com)",
        "Accept": "application/sparql-results+json",
    }

    try:
        r = requests.get(
            WIKIDATA_SPARQL_ENDPOINT,
            params={"query": SPARQL_QUERY, "format": "json"},
            headers=headers,
            timeout=180,
        )
        r.raise_for_status()
        data = r.json()
        bindings = data.get("results", {}).get("bindings", [])
        out_file.write_text(json.dumps(data, indent=2, ensure_ascii=False), encoding="utf-8")
        print(f"Success! {len(bindings)} Wikidata stations written to {out_file}")
    except Exception as e:
        print(f"Error fetching Wikidata: {e}", file=sys.stderr)
        # If network error or timeout, ensure fallback raw exists
        if not out_file.exists():
            out_file.write_text(json.dumps({"results": {"bindings": []}}), encoding="utf-8")
        sys.exit(1)

if __name__ == "__main__":
    main()
