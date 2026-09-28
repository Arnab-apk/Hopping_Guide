# Durga Puja Pandal Data Schema & Architecture

This directory documents the canonical schema for Durga Puja pandals, supplementary cultural event data, food/bhog spots, and emergency services scraped from [Pujo Planner](https://www.pujoplanner.com/pandals) and tailored for the Kolkata Puja Flutter mobile app.

---

## 1. Pandal Document Schema (`pandals` collection)

**Document ID format**: Lowercase snake_case slug derived from the pandal's English name (e.g. `hatibagan_sarbojanin`, `ekdalia_evergreen`).

### Field Definitions

| Field | Type | Required | Description | Sample Value |
|---|---|---|---|---|
| `name` | `string` | Yes | Official name of the pandal / puja committee | `"Hatibagan Sarbojanin"` |
| `lat` | `number` (double) | Yes | Latitude coordinates (WGS84) | `22.5947` |
| `lng` | `number` (double) | Yes | Longitude coordinates (WGS84) | `88.3720` |
| `zone` | `string` | Yes | Application zone enum (`northKolkata`, `centralKolkata`, `southKolkata`, `saltLake`, `newTown`) | `"northKolkata"` |
| `area` | `string` | No | Kolkata neighborhood/area name | `"North Kolkata"` |
| `region` | `string` | No | Broad region classification (`"North"`, `"Central"`, `"South"`) | `"North"` |
| `rating` | `number` (double) | No | Average visitor rating out of 5.0 | `4.5` |
| `theme` | `string` | Yes | Theme category (e.g., Traditional, Bonedi Bari, Art Replica) | `"Traditional"` |
| `crowd_level` | `string` | No | Crowd tier (`"low"`, `"medium"`, `"high"`) | `"high"` |
| `timings` | `string` | Yes | Open timings / visiting hours | `"12:00 AM - 12:00 PM"` |
| `image_url` | `string` | Yes | Banner / representative photograph URL | `"https://..."` |
| `description` | `string` | Yes | History, architectural highlights, or visitor notes | `"Hatibagan Sarbojanin pandal in North Kolkata."` |
| `transport` | `string[]` | No | Recommended modes of public transport | `["Metro", "Railway"]` |
| `nearest_metro` | `string?` | No | Nearest metro station with line specification | `"Shyambazar (Blue)"` |
| `nearest_metro_list` | `string[]` | No | List of nearby metro stations | `["Shyambazar (Blue)"]` |
| `nearest_railway` | `string?` | No | Nearest suburban or circular train station | `"Kolkata Station (Circular)"` |
| `nearest_railway_list` | `string[]` | No | List of nearby railway stations | `["Kolkata Station (Circular)"]` |
| `nearest_stations` | `object[]` | No | Precomputed top 3 nearest stations with walking distance in metres (`id`, `name`, `code`, `kind`, `distance_m`) | `[{"id":"stn_howrah","name":"Howrah Junction","code":"HWH","kind":"rail","distance_m":850}]` |
| `special_features` | `string[]` | No | Special amenities (e.g. VIP line, wheelchair access) | `[]` |

---

## 2. Station Document Schema (`data/schema/station.schema.json` / `data/stations/stations.geojson`)

Canonical GeoJSON schema for suburban rail terminals, suburban halts, circular railway, and Kolkata Metro stations.

### Field Definitions

| Field | Type | Required | Description | Sample Value |
|---|---|---|---|---|
| `id` | `string` | Yes | Unique station identifier slug | `"stn_howrah"` / `"stn_m_shyambazar"` |
| `name` | `string` | Yes | Official English station display name | `"Howrah Junction"` |
| `name_bn` | `string?` | No | Bengali script name | `"হাওড়া জংশন"` |
| `code` | `string?` | No | IRCTC or Metro station code | `"HWH"`, `"SDAH"` |
| `kind` | `string` | Yes | Transit mode enum (`"rail"`, `"metro"`) | `"rail"` |
| `lat` | `number` (double) | Yes | Latitude in WGS84 | `22.5839` |
| `lon` | `number` (double) | Yes | Longitude in WGS84 | `88.3426` |
| `network` | `string?` | No | Rail operator / transit authority | `"Eastern Railway"` |
| `lines` | `string[]` | No | Lines or corridors serving the station | `["Howrah Main Line"]` |
| `entrances` | `object[]` | No | Geo-tagged entry and exit gates | `[]` |

---

## 3. Supplementary Collections

### A. Food & Bhog Spots (`food_spots` collection / `data/food_spots.json`)
- `id`: `string` (`"f1"`, `"f2"`, ...)
- `name`: `string` (`"Bhog at Shreebhumi"`)
- `type`: `string` (`"Bhog"`, `"Street Food"`)
- `coordinates`: `{ "lat": number, "lng": number }`
- `nearby_pandal`: `string` (`"Shreebhumi Sporting Club"`)

### B. Cultural Events (`events` collection / `data/events.json`)
- `id`: `string` (`"e1"`, `"e2"`, ...)
- `name`: `string` (`"Dhunuchi Naach Competition"`)
- `type`: `string` (`"Dhunuchi Naach"`, `"Cultural Program"`)
- `coordinates`: `{ "lat": number, "lng": number }`
- `timing`: `string` (`"8:00 PM - 10:00 PM"`)
- `nearby_pandal`: `string` (`"Shreebhumi Sporting Club"`)

### C. Emergency Helplines (`data/helplines.json`)
- `label`: `string` (`"Police Helpline"`, `"Fire Department"`, etc.)
- `number`: `string` (`"100"`, `"101"`, `"102"`, `"1091"`, `"1077"`)

### D. Safety & First Aid (`data/safety_first_aid.json`)
- `title`: `string` (`"Heat Exhaustion"`, `"Fainting"`, `"Minor Burns"`)
- `content`: `string[]`

---

## 4. Data Files in Repository

- `data/stations/stations.geojson`: 206 normalized railway & metro stations in canonical GeoJSON format.
- `data/stations/overrides.json`: Manual overrides for bilingual station names, codes, and networks.
- `data/schema/station.schema.json`: JSON Schema (Draft 2020-12) definition for stations.
- `data/pandals.json`: 387 normalized pandals in JSON format with precomputed `nearest_stations`.
- `data/pandals.csv`: Normalized pandals in CSV format for spreadsheet editing or legacy tools.
- `data/schema/pandal.schema.json`: JSON Schema (Draft 2020-12) definition for pandals.
- `data/scraped_pujoplanner_raw.json`: Raw scraped data dump from pujoplanner.com.
- `data/food_spots.json`: Food and bhog locations.
- `data/events.json`: Cultural celebrations and competitions.
- `data/helplines.json`: Verified Kolkata emergency telephone numbers.
- `data/safety_first_aid.json`: Medical guidelines for festival crowds.
