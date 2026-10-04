import json
import sys
import re

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

import verify_resolved
resolved = verify_resolved.resolved

# Apply manual fills
for s in resolved:
    code = s["code"]
    if code in verify_resolved.MANUAL_FILLS:
        fill = verify_resolved.MANUAL_FILLS[code]
        if s.get("lat") is None: s["lat"] = fill["lat"]
        if s.get("lon") is None: s["lon"] = fill["lon"]
        if not s.get("name_bn"): s["name_bn"] = fill["name_bn"]

# Additional Bengali name fixes
BN_FIXES = {
    "BOI": "বৈঁচি",
    "MTFA": "মেরতলা ফালেয়া হল্ট",
    "LKX": "লক্ষ্মীপুর",
    "SHE": "শেওড়াফুলি জংশন",
    "CGR": "চন্দননগর",
    "CNS": "চুঁচুড়া",
    "HGY": "হুগলি",
    "PDA": "পাণ্ডুয়া",
    "MYM": "মেমারি",
    "ABKA": "অম্বিকা কালনা",
    "NDAE": "নবদ্বীপ ধাম",
    "BWN": "বর্ধমান জংশন",
    "KWAE": "কাটোয়া জংশন",
    "DKAE": "ডানকুনি জংশন",
    "KQU": "কামারকুণ্ডু জংশন",
    "TAK": "তারকেশ্বর",
    "HYG": "হুগলি ঘাট",
    "GFAE": "গরিফা"
}

for s in resolved:
    code = s["code"]
    if code in BN_FIXES:
        s["name_bn"] = BN_FIXES[code]
    elif s.get("name_bn"):
        s["name_bn"] = s["name_bn"].replace(" রেলওয়ে স্টেশন", "").replace(" জংশন", " জংশন").strip()

# Add the additional Bardhaman-Katwa stops if not already in resolved
extra_bwn_katwa = [
    {"code": "KMRA", "name": "Kamnara", "name_bn": "কামরানা", "lat": 23.299241, "lon": 87.880341, "lines": ["Barddhaman-Katwa Line"]},
    {"code": "KSHT", "name": "Kshetia", "name_bn": "খেতিয়া", "lat": 23.312641, "lon": 87.884739, "lines": ["Barddhaman-Katwa Line"]},
    {"code": "CMDG", "name": "Chamardighi", "name_bn": "চামরদিঘী", "lat": 23.333685, "lon": 87.889890, "lines": ["Barddhaman-Katwa Line"]},
    {"code": "KJRA", "name": "Karjanagram", "name_bn": "করজনাগ্রাম", "lat": 23.352835, "lon": 87.894094, "lines": ["Barddhaman-Katwa Line"]},
]

existing_codes = {s["code"] for s in resolved}
for extra in extra_bwn_katwa:
    if extra["code"] not in existing_codes:
        resolved.append(extra)

def make_feature_id(name):
    clean = re.sub(r"[^a-zA-Z0-9]+", "_", name.lower()).strip("_")
    return f"stn_{clean}"

features = []
for s in resolved:
    fid = make_feature_id(s["name"])
    features.append({
        "type": "Feature",
        "id": fid,
        "geometry": {
            "type": "Point",
            "coordinates": [round(float(s["lon"]), 6), round(float(s["lat"]), 6)]
        },
        "properties": {
            "id": fid,
            "name": s["name"],
            "name_bn": s.get("name_bn"),
            "code": s.get("code"),
            "kind": "rail",
            "lat": round(float(s["lat"]), 6),
            "lon": round(float(s["lon"]), 6),
            "network": "Eastern Railway",
            "lines": s.get("lines", ["Eastern Railway"])
        }
    })

print(f"Generated {len(features)} new corridor station features.")

with open("tools/stations/raw/corridor_features.json", "w", encoding="utf-8") as f:
    json.dump(features, f, indent=2, ensure_ascii=False)

print("Saved to tools/stations/raw/corridor_features.json")
