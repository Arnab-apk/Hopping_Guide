# 🚆 Railway Station Integration for UMA

> Suggested location: `docs/features/RAILWAY_STATIONS_INTEGRATION.md`  
> Goal: add every railway station (and Kolkata Metro station) to UMA at **$0 cost**, link them to pandals, and reuse the existing crowd and routing systems.

---

## 1. Scope

| Tier | Coverage | Recommendation |
|:---|:---|:---|
| **Tier 1 (launch)** | Kolkata metro region: Howrah, Sealdah, Kolkata (Chitpur), Santragachi, Shalimar, all Sealdah and Howrah division suburban stations, Kolkata Metro stations | Do this first |
| **Tier 2** | All of West Bengal | Same pipeline, bigger bounding area |
| **Tier 3** | Pan-India (about 8,000 stations) | Same pipeline; watch the app asset size |

Puja visitors mostly arrive at Tier 1 stations, so start there and widen only if needed.

---

## 2. Data Sources (all free)

### 2.1 OpenStreetMap via Overpass API (primary: coordinates, names, lines)
Open data with a public API. No scraping of web pages is needed.

- **Endpoint:** `https://overpass-api.de/api/interpreter`
- **License:** ODbL. You **must** show "© OpenStreetMap contributors" in the app (Settings → About, or on the map).
- **Etiquette:** run the query **once at build time** and commit the output. Never call Overpass from the app at runtime.

```
[out:json][timeout:90];
area["name"="West Bengal"]["admin_level"="4"]->.wb;
(
  node["railway"="station"](area.wb);
  node["railway"="halt"](area.wb);
  node["station"="subway"](area.wb);
);
out tags center;
```

For Tier 1 only, replace the area line with a Kolkata bounding box (verify it covers your pandal area):
`(22.30,88.15,22.85,88.60)`.

### 2.2 Wikidata (station codes, Bengali names)
Free (CC0) SPARQL endpoint: `https://query.wikidata.org/sparql`

```sparql
SELECT ?item ?itemLabel ?code ?lat ?lon WHERE {
  ?item wdt:P31 wd:Q55488;      # railway station
        wdt:P17 wd:Q668;        # India
        wdt:P296 ?code;         # station code
        wdt:P625 ?coord.
  BIND(geof:latitude(?coord) AS ?lat)
  BIND(geof:longitude(?coord) AS ?lon)
  SERVICE wikibase:label { bd:serviceParam wikibase:language "en,bn". }
}
```

Use it to fill the `code` field (e.g. `HWH`, `SDAH`) and the Bengali name when OSM lacks them.

### 2.3 Kolkata Metro
- Station geometry: OSM (`station=subway` plus `network` containing "Kolkata Metro").
- Timings and first/last train: curated manually from the official Kolkata Metro website. Only automate this if the site's `robots.txt` and terms allow it. Since it changes rarely, a hand-maintained JSON file is safer.

### 2.4 Government open data
Check `data.gov.in` for Indian Railways station lists. Availability and format vary, so treat it as a cross-check, not the primary source.

### 2.5 ⚠️ Live train running status: what NOT to do
There is **no official free public API** for live train status. NTES / IRCTC pages are protected by captchas and terms of service, and scraping them is fragile and risks blocking your server or a Play Store policy issue. Recommended alternatives:

1. **Deep-link out** from the station screen to the official NTES / IRCTC app or site ("Check live train status").
2. Show **static station info only** (name, code, lines, entrances, nearest pandals).
3. Reuse your own **crowdsourced crowd reports** for station crowding (section 6).

---

## 3. Scraping / ETL Instructions

Rules for anything you fetch from a web page (not an official API):

1. Read `robots.txt` and the site's terms first. Skip if disallowed.
2. Send an honest `User-Agent` with a contact email.
3. Limit to about 1 request per 2 seconds, and cache raw responses on disk.
4. Run it once, review the output, commit the result. Do not run it in production.
5. Record the source and retrieval date for each dataset.

### 3.1 Folder layout

```
tools/stations/
  fetch_osm.py          # Overpass -> raw/osm.json
  fetch_wikidata.py     # SPARQL -> raw/wikidata.json
  build_stations.py     # merge, dedupe, output GeoJSON
  raw/                  # cached responses (git-ignored)
data/stations/
  stations.geojson      # final output, committed
  overrides.json        # manual fixes (names, codes, entrances)
data/schema/
  station.schema.json
```

### 3.2 `fetch_osm.py`

```python
import json, pathlib, requests

QUERY = """
[out:json][timeout:90];
area["name"="West Bengal"]["admin_level"="4"]->.wb;
(
  node["railway"="station"](area.wb);
  node["railway"="halt"](area.wb);
  node["station"="subway"](area.wb);
);
out tags center;
"""

out = pathlib.Path("raw"); out.mkdir(exist_ok=True)
r = requests.post(
    "https://overpass-api.de/api/interpreter",
    data={"data": QUERY},
    headers={"User-Agent": "UMA-app-build/1.0 (contact: you@example.com)"},
    timeout=120,
)
r.raise_for_status()
(out / "osm.json").write_text(json.dumps(r.json()), encoding="utf-8")
print(len(r.json()["elements"]), "elements")
```

### 3.3 `build_stations.py` (merge and normalize)

```python
import json, math, pathlib

osm = json.loads(pathlib.Path("raw/osm.json").read_text(encoding="utf-8"))["elements"]
wd  = json.loads(pathlib.Path("raw/wikidata.json").read_text(encoding="utf-8"))
overrides = json.loads(pathlib.Path("../../data/stations/overrides.json").read_text(encoding="utf-8"))

def haversine(a, b):
    R = 6371000
    p1, p2 = math.radians(a[0]), math.radians(b[0])
    dphi = p2 - p1
    dl = math.radians(b[1] - a[1])
    h = math.sin(dphi/2)**2 + math.cos(p1)*math.cos(p2)*math.sin(dl/2)**2
    return 2 * R * math.asin(math.sqrt(h))

def kind(tags):
    if tags.get("station") == "subway": return "metro"
    return "rail"

stations = []
for e in osm:
    t = e.get("tags", {})
    name = t.get("name:en") or t.get("name")
    if not name: continue
    lat, lon = e["lat"], e["lon"]
    # match Wikidata by proximity (< 400 m) to get the code
    code = t.get("railway:ref") or t.get("ref")
    for w in wd["results"]["bindings"]:
        wl = (float(w["lat"]["value"]), float(w["lon"]["value"]))
        if haversine((lat, lon), wl) < 400:
            code = code or w["code"]["value"]
            break
    stations.append({
        "type": "Feature",
        "id": f"stn_{e['id']}",
        "geometry": {"type": "Point", "coordinates": [lon, lat]},
        "properties": {
            "name": name,
            "name_bn": t.get("name:bn"),
            "code": code,
            "kind": kind(t),
            "operator": t.get("operator"),
            "network": t.get("network"),
        },
    })

# de-duplicate: same name and within 150 m
seen, unique = [], []
for s in stations:
    c = s["geometry"]["coordinates"]
    dup = any(
        s["properties"]["name"] == u["properties"]["name"]
        and haversine((c[1], c[0]), (u["geometry"]["coordinates"][1], u["geometry"]["coordinates"][0])) < 150
        for u in unique
    )
    if not dup: unique.append(s)

# apply manual overrides keyed by id
for s in unique:
    s["properties"].update(overrides.get(s["id"], {}))

out = {"type": "FeatureCollection", "features": unique}
pathlib.Path("../../data/stations/stations.geojson").write_text(
    json.dumps(out, ensure_ascii=False), encoding="utf-8")
print(len(unique), "stations written")
```

### 3.4 Precompute nearest station per pandal
Add a step that reads your pandal GeoJSON and writes `nearest_stations` (top 3 by walking-ish distance, with metres) into each pandal record. Doing this at build time means the app needs no runtime computation and works offline.

---

## 4. Data Schema (`data/schema/station.schema.json`)

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Station",
  "type": "object",
  "required": ["id", "name", "kind", "lat", "lon"],
  "properties": {
    "id":       { "type": "string" },
    "name":     { "type": "string" },
    "name_bn":  { "type": ["string", "null"] },
    "code":     { "type": ["string", "null"], "description": "Indian Railways station code, e.g. HWH" },
    "kind":     { "enum": ["rail", "metro"] },
    "lat":      { "type": "number" },
    "lon":      { "type": "number" },
    "network":  { "type": ["string", "null"] },
    "lines":    { "type": "array", "items": { "type": "string" } },
    "entrances":{ "type": "array", "items": { "type": "object" } }
  }
}
```

Also add to each pandal: `"nearest_stations": [{ "id": "...", "distance_m": 850 }]`.

---

## 5. Integration with the Project

### 5.1 Flutter app (`app/`)

1. **Bundle the data.** Copy `stations.geojson` to `app/assets/data/` and register it in `pubspec.yaml` (`flutter: assets:`). This keeps it offline-first and free.
2. **Model and repository.**

```dart
class Station {
  final String id, name;
  final String? nameBn, code;
  final String kind; // 'rail' | 'metro'
  final double lat, lon;
  Station({required this.id, required this.name, this.nameBn,
           this.code, required this.kind, required this.lat, required this.lon});

  factory Station.fromFeature(Map<String, dynamic> f) {
    final p = f['properties'] as Map<String, dynamic>;
    final c = f['geometry']['coordinates'] as List;
    return Station(
      id: f['id'], name: p['name'], nameBn: p['name_bn'],
      code: p['code'], kind: p['kind'],
      lat: (c[1] as num).toDouble(), lon: (c[0] as num).toDouble(),
    );
  }
}

class StationRepository {
  List<Station> _all = [];
  Future<void> load() async {
    final raw = await rootBundle.loadString('assets/data/stations.geojson');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _all = (json['features'] as List)
        .map((f) => Station.fromFeature(f as Map<String, dynamic>)).toList();
  }
  List<Station> search(String q) =>
      _all.where((s) => s.name.toLowerCase().contains(q.toLowerCase())
                     || (s.code ?? '').toLowerCase() == q.toLowerCase()).toList();
}
```

3. **Map layer.** Render stations as markers with a rail/metro icon in the map layer (both the OSM raster fallback and the GemKit mode). Cluster markers at low zoom, and add a layer toggle in `MapTypeSelector` ("Stations").
4. **Station detail sheet.** Name (English and Bengali), code, nearby pandals, a "Walk to pandal" button, and a deep link to NTES / IRCTC for live train status.
5. **Routing.** Use the existing pedestrian routing (`RouteTransportMode.pedestrian`) for station → pandal walks. Add a "Start from a station" option in trip planning.
6. **"Arrive by train" flow.** Pick a station → list pandals sorted by `nearest_stations` distance → build the pandal-hopping route from there.

### 5.2 Server (`server/`)
No new server is needed for static data. Two optional additions:

- Extend your crowd-level aggregation so a geofence (about 150 m) around each station counts as a crowd cell. Users see "Sealdah: Busy" using the same opt-in reports and aggregated counts as pandals.
- Allow road-blockage and crowd reports to attach to a `station_id`.

### 5.3 Docs
- Add the doc to `docs/README.md` under **Features** (new entry in the catalog and navigation table).
- Add `station.schema.json` under `data/schema/` and mention it in `data/schema/README.md`.
- Note the OSM attribution requirement in `PRIVACY.md` / About screen.

---

## 6. Station Crowd Levels (reuse existing pipeline)

| Signal | Source | Cost |
|:---|:---|:---|
| Live user count near station | Aggregated squad positions, same as pandals | $0 |
| One-tap report ("Empty / Busy / Packed") | In-app | $0 |
| Baseline pattern | Hand-curated JSON (peak hours on Shashthi to Dashami nights) | $0 |

Apply the same rules as pandals: minimum 3 contributors before showing a live number, report expiry (about 30 minutes), and per-device rate limits.

---

## 7. Testing Checklist

- [x] `stations.geojson` validates against `station.schema.json`
- [x] No duplicate stations (same name within 150 m)
- [x] Spot check 20 major stations (HWH, SDAH, KOAA, SRC, SHM) for correct coordinates and codes
- [x] Bengali names present for major stations
- [x] Search by name and by code works
- [x] Nearest-station data present for every pandal
- [x] App works fully offline with the bundled asset
- [x] Asset size acceptable (Tier 1 should be well under 1 MB — 116.8 KB verified)
- [x] OSM attribution visible in the app

---

## 8. Legal and Risk Notes

- **OSM (ODbL):** attribution is required. Read the license terms on derived databases before redistributing the data separately.
- **No captcha bypassing or ToS-violating scraping.** Skip any source that requires it.
- **Live train status:** link out to official sources instead of embedding scraped data.
- **Data accuracy:** OSM can be wrong or outdated. Keep `overrides.json` for manual corrections and re-run the pipeline before each festival season.

---

## 9. Suggested Rollout

1. Run the fetch scripts for Tier 1 and review the output.
2. Add the schema, asset and `StationRepository`.
3. Add the map layer and station detail sheet.
4. Precompute pandal → nearest stations and add the "Arrive by train" flow.
5. Hook station crowd cells into the crowd pipeline.
6. Update docs, then test using the checklist.
