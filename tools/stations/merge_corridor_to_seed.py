import json
import re

with open("tools/stations/seed_stations.py", "r", encoding="utf-8") as f:
    seed_content = f.read()

with open("tools/stations/raw/corridor_features.json", "r", encoding="utf-8") as f:
    new_features = json.load(f)

# Extract existing codes in seed_stations.py
existing_codes = set(re.findall(r'"code":\s*"([^"]+)"', seed_content))
print(f"Existing station codes in seed_stations.py: {len(existing_codes)}")

to_add = []
for feat in new_features:
    props = feat["properties"]
    code = props.get("code")
    name = props.get("name")
    if code in existing_codes:
        print(f"  Skipping existing code {code}: {name}")
        continue
    to_add.append(feat)

print(f"Features to add to seed_stations.py: {len(to_add)}")

# Group stations by line for clean organization in seed_stations.py
main_line = []
chord_line = []
bandel_katwa = []
bwn_katwa = []
other_links = []

for feat in to_add:
    lines = feat["properties"].get("lines", [])
    if any("Barddhaman-Katwa" in l for l in lines):
        bwn_katwa.append(feat)
    elif any("Bandel-Katwa" in l for l in lines):
        bandel_katwa.append(feat)
    elif any("Chord" in l for l in lines):
        chord_line.append(feat)
    elif any("Howrah Main Line" in l for l in lines):
        main_line.append(feat)
    else:
        other_links.append(feat)

print(f"  Main Line (Serampore to Bardhaman): {len(main_line)}")
print(f"  Chord Line (Belanagar to Bardhaman): {len(chord_line)}")
print(f"  Bandel to Katwa Line: {len(bandel_katwa)}")
print(f"  Bardhaman to Katwa Line: {len(bwn_katwa)}")
print(f"  Connecting branches: {len(other_links)}")

# Format JSON entries nicely
def format_feat(feat):
    p = feat["properties"]
    c = feat["geometry"]["coordinates"]
    lines_str = json.dumps(p.get("lines", []), ensure_ascii=False)
    name_bn_str = f'"{p["name_bn"]}"' if p.get("name_bn") else 'None'
    code_str = f'"{p["code"]}"' if p.get("code") else 'None'
    return f"""    {{
        "type": "Feature",
        "id": "{feat["id"]}",
        "geometry": {{"type": "Point", "coordinates": [{c[0]}, {c[1]}]}},
        "properties": {{
            "id": "{p["id"]}",
            "name": "{p["name"]}",
            "name_bn": {name_bn_str},
            "code": {code_str},
            "kind": "rail",
            "lat": {p["lat"]},
            "lon": {p["lon"]},
            "network": "Eastern Railway",
            "lines": {lines_str}
        }}
    }}"""

sections_str = []

if main_line:
    sections_str.append("    # --- Howrah-Bardhaman Main Line (Extended to Barddhaman Junction) ---")
    sections_str.extend([format_feat(f) for f in main_line])

if chord_line:
    sections_str.append("    # --- Howrah-Bardhaman Chord Line (Dankuni to Saktigarh/Barddhaman) ---")
    sections_str.extend([format_feat(f) for f in chord_line])

if bandel_katwa:
    sections_str.append("    # --- Bandel-Katwa Line (Bandel Junction to Katwa Junction) ---")
    sections_str.extend([format_feat(f) for f in bandel_katwa])

if bwn_katwa:
    sections_str.append("    # --- Barddhaman-Katwa Line (Barddhaman to Katwa Junction) ---")
    sections_str.extend([format_feat(f) for f in bwn_katwa])

if other_links:
    sections_str.append("    # --- Connecting Links (Naihati-Bandel & Sheoraphuli-Tarakeswar) ---")
    sections_str.extend([format_feat(f) for f in other_links])

insert_text = ",\n" + ",\n".join(sections_str)

# Find the last closing bracket of CURATED_TIER1_STATIONS
last_bracket_idx = seed_content.rfind("]")
if last_bracket_idx == -1:
    raise ValueError("Could not find closing bracket in seed_stations.py")

new_seed_content = seed_content[:last_bracket_idx].rstrip() + insert_text + "\n]\n"

with open("tools/stations/seed_stations.py", "w", encoding="utf-8") as f:
    f.write(new_seed_content)

print("Updated tools/stations/seed_stations.py successfully!")
