import json
import requests
import sys

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8")

# Comprehensive catalog of all stations till Bardhaman and till Katwa
CORRIDOR_STATIONS = [
    # 1. Howrah-Bardhaman Main Line (Serampore to Bardhaman)
    {"code": "SHE", "name": "Sheoraphuli Junction", "wiki": "Sheoraphuli railway station", "lines": ["Howrah Main Line", "Sheoraphuli-Tarakeswar Line"]},
    {"code": "BBAE", "name": "Baidyabati", "wiki": "Baidyabati railway station", "lines": ["Howrah Main Line"]},
    {"code": "BHR", "name": "Bhadreshwar", "wiki": "Bhadreshwar railway station", "lines": ["Howrah Main Line"]},
    {"code": "MUU", "name": "Mankundu", "wiki": "Mankundu railway station", "lines": ["Howrah Main Line"]},
    {"code": "CGR", "name": "Chandannagar", "wiki": "Chandannagar railway station", "lines": ["Howrah Main Line"]},
    {"code": "CNS", "name": "Chuchura", "wiki": "Chuchura railway station", "lines": ["Howrah Main Line"]},
    {"code": "HGY", "name": "Hooghly", "wiki": "Hooghly railway station", "lines": ["Howrah Main Line"]},
    {"code": "BDC", "name": "Bandel Junction", "wiki": "Bandel Junction railway station", "lines": ["Howrah Main Line", "Bandel-Katwa Line", "Naihati-Bandel Branch"]},
    {"code": "ADST", "name": "Adisaptagram", "wiki": "Adisaptagram railway station", "lines": ["Howrah Main Line"]},
    {"code": "MUG", "name": "Magra", "wiki": "Magra railway station", "lines": ["Howrah Main Line"]},
    {"code": "TLO", "name": "Talandu", "wiki": "Talandu railway station", "lines": ["Howrah Main Line"]},
    {"code": "KHN", "name": "Khanyan", "wiki": "Khanyan railway station", "lines": ["Howrah Main Line"]},
    {"code": "PDA", "name": "Pundooah", "wiki": "Pundooah railway station", "lines": ["Howrah Main Line"]},
    {"code": "SLG", "name": "Simlagarh", "wiki": "Simlagarh railway station", "lines": ["Howrah Main Line"]},
    {"code": "BCGM", "name": "Bainchigram", "wiki": "Bainchigram railway station", "lines": ["Howrah Main Line"]},
    {"code": "BOI", "name": "Bainchi", "wiki": "Bainchi railway station", "lines": ["Howrah Main Line"]},
    {"code": "DBP", "name": "Debipur", "wiki": "Debipur railway station", "lines": ["Howrah Main Line"]},
    {"code": "BGF", "name": "Bagila", "wiki": "Bagila railway station", "lines": ["Howrah Main Line"]},
    {"code": "MYM", "name": "Memari", "wiki": "Memari railway station", "lines": ["Howrah Main Line"]},
    {"code": "NMO", "name": "Nimo", "wiki": "Nimo railway station", "lines": ["Howrah Main Line"]},
    {"code": "RSLR", "name": "Rasulpur", "wiki": "Rasulpur railway station", "lines": ["Howrah Main Line"]},
    {"code": "PLAE", "name": "Palsit", "wiki": "Palsit railway station", "lines": ["Howrah Main Line"]},
    {"code": "SKG", "name": "Saktigarh", "wiki": "Saktigarh railway station", "lines": ["Howrah Main Line", "Howrah-Bardhaman Chord"]},
    {"code": "GRP", "name": "Gangpur", "wiki": "Gangpur railway station", "lines": ["Howrah Main Line", "Howrah-Bardhaman Chord"]},
    {"code": "BWN", "name": "Barddhaman Junction", "wiki": "Barddhaman Junction railway station", "lines": ["Howrah Main Line", "Howrah-Bardhaman Chord", "Barddhaman-Katwa Line", "Barddhaman-Asansol Line"]},

    # 2. Howrah-Bardhaman Chord Line
    {"code": "BZL", "name": "Belanagar", "wiki": "Belanagar railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "DKAE", "name": "Dankuni Junction", "wiki": "Dankuni Junction railway station", "lines": ["Howrah-Bardhaman Chord", "Sealdah-Dankuni Line"]},
    {"code": "GBRA", "name": "Gobra", "wiki": "Gobra railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "JOX", "name": "Janai Road", "wiki": "Janai Road railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "BPAE", "name": "Begampur", "wiki": "Begampur railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "BRPA", "name": "Baruipara", "wiki": "Baruipara railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "MBE", "name": "Mirzapur Bankipur", "wiki": "Mirzapur Bankipur railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "BLAE", "name": "Balarambati", "wiki": "Balarambati railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "KQU", "name": "Kamarkundu Junction", "wiki": "Kamarkundu railway station", "lines": ["Howrah-Bardhaman Chord", "Sheoraphuli-Tarakeswar Line"]},
    {"code": "MDSE", "name": "Madhusudanpur", "wiki": "Madhusudanpur railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "CDAE", "name": "Chandanpur", "wiki": "Chandanpur railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "PBZ", "name": "Porabazar", "wiki": "Porabazar railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "BMAE", "name": "Belmuri", "wiki": "Belmuri railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "SHBC", "name": "Shiblung Halt", "wiki": "Shiblung Halt railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "DNHL", "name": "Dhaniakhali Halt", "wiki": "Dhaniakhali railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "GRAE", "name": "Sibaichandi", "wiki": "Sibaichandi railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "HIH", "name": "Hajigarh", "wiki": "Hajigarh railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "GUH", "name": "Gurap", "wiki": "Gurap railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "JPQ", "name": "Jhapandanga", "wiki": "Jhapandanga railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "JRAE", "name": "Jaugram", "wiki": "Jaugram railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "NBAE", "name": "Nabagram", "wiki": "Nabagram railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "MSAE", "name": "Masagram Junction", "wiki": "Masagram railway station", "lines": ["Howrah-Bardhaman Chord", "Bankura-Damodar Railway"]},
    {"code": "CHC", "name": "Chanchai", "wiki": "Chanchai railway station", "lines": ["Howrah-Bardhaman Chord"]},
    {"code": "PRAE", "name": "Palla Road", "wiki": "Palla Road railway station", "lines": ["Howrah-Bardhaman Chord"]},

    # 3. Bandel-Katwa Line
    {"code": "BSAE", "name": "Bans Beria", "wiki": "Bansh Baria railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "TBAE", "name": "Tribeni", "wiki": "Tribeni railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "KJU", "name": "Kuntighat", "wiki": "Kuntighat railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "DMLE", "name": "Dumurdaha", "wiki": "Dumurdaha railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "KMAE", "name": "Khamargachhi", "wiki": "Khamargachhi railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "JIT", "name": "Jirat", "wiki": "Jirat railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "BGAE", "name": "Balagarh", "wiki": "Balagarh railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "SOAE", "name": "Somra Bazar", "wiki": "Somra Bazar railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "BHLA", "name": "Behula", "wiki": "Behula railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "GPAE", "name": "Guptipara", "wiki": "Guptipara railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "ABKA", "name": "Ambika Kalna", "wiki": "Ambika Kalna railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "BGRA", "name": "Baghnapara", "wiki": "Baghnapara railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "DTAE", "name": "Dhatrigram", "wiki": "Dhatrigram railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "NDIM", "name": "Nandaigram Halt", "wiki": "Nandaigram Halt railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "SMAE", "name": "Samudragarh", "wiki": "Samudragarh railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "KLNT", "name": "Kalinagar", "wiki": "Kalinagar railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "NDAE", "name": "Nabadwip Dham", "wiki": "Nabadwip Dham railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "VNP", "name": "Bishnupriya", "wiki": "Bishnupriya railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "BFZ", "name": "Bhandartikuri", "wiki": "Bhandartikuri railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "PSAE", "name": "Purbasthali", "wiki": "Purbasthali railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "MTFA", "name": "Mertala Phaleya Halt", "wiki": "Mertala Phaleya railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "LKX", "name": "Lakshmipur", "wiki": "Lakshmipur railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "BQH", "name": "Belerhat", "wiki": "Belerhat railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "PTAE", "name": "Patuli", "wiki": "Patuli railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "AGAE", "name": "Agradwip", "wiki": "Agradwip railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "SHBA", "name": "Sahebtala", "wiki": "Sahebtala railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "DHAE", "name": "Dainhat", "wiki": "Dainhat railway station", "lines": ["Bandel-Katwa Line"]},
    {"code": "KWAE", "name": "Katwa Junction", "wiki": "Katwa Junction railway station", "lines": ["Bandel-Katwa Line", "Barddhaman-Katwa Line", "Katwa-Azimganj Line"]},

    # 4. Bardhaman-Katwa Line
    {"code": "KMDC", "name": "Kamalakantapur", "wiki": "Kamalakantapur railway station", "lines": ["Barddhaman-Katwa Line"]},
    {"code": "KJRM", "name": "Karjana", "wiki": "Karjana railway station", "lines": ["Barddhaman-Katwa Line"]},
    {"code": "KJME", "name": "Karjana Chehar", "wiki": "Karjana Chehar railway station", "lines": ["Barddhaman-Katwa Line"]},
    {"code": "BTRH", "name": "Bhatar", "wiki": "Bhatar railway station", "lines": ["Barddhaman-Katwa Line"]},
    {"code": "ARNB", "name": "Amarun", "wiki": "Amarun railway station", "lines": ["Barddhaman-Katwa Line"]},
    {"code": "BGNA", "name": "Balgona", "wiki": "Balgona railway station", "lines": ["Barddhaman-Katwa Line"]},
    {"code": "SOF", "name": "Saota", "wiki": "Saota railway station", "lines": ["Barddhaman-Katwa Line"]},
    {"code": "NGX", "name": "Nigan", "wiki": "Nigan railway station", "lines": ["Barddhaman-Katwa Line"]},
    {"code": "KCY", "name": "Kaichar Halt", "wiki": "Kaichar Halt railway station", "lines": ["Barddhaman-Katwa Line"]},
    {"code": "BCF", "name": "Bankapasi", "wiki": "Bankapasi railway station", "lines": ["Barddhaman-Katwa Line"]},
    {"code": "SIZ", "name": "Shrikhanda", "wiki": "Shrikhanda railway station", "lines": ["Barddhaman-Katwa Line"]},
    {"code": "SPS", "name": "Sripat Shrikhanda", "wiki": "Sripat Shrikhanda railway station", "lines": ["Barddhaman-Katwa Line"]},

    # 5. Naihati-Bandel branch link & Sheoraphuli-Kamarkundu branch
    {"code": "GFAE", "name": "Garifa", "wiki": "Garifa railway station", "lines": ["Naihati-Bandel Branch"]},
    {"code": "HYG", "name": "Hooghly Ghat", "wiki": "Hooghly Ghat railway station", "lines": ["Naihati-Bandel Branch"]},
    {"code": "DEA", "name": "Diara", "wiki": "Diara railway station", "lines": ["Sheoraphuli-Tarakeswar Line"]},
    {"code": "NSF", "name": "Nasibpur", "wiki": "Nasibpur railway station", "lines": ["Sheoraphuli-Tarakeswar Line"]},
    {"code": "SIU", "name": "Singur", "wiki": "Singur railway station", "lines": ["Sheoraphuli-Tarakeswar Line"]},
    {"code": "NKL", "name": "Nalikul", "wiki": "Nalikul railway station", "lines": ["Sheoraphuli-Tarakeswar Line"]},
    {"code": "MLYA", "name": "Maliya", "wiki": "Maliya railway station", "lines": ["Sheoraphuli-Tarakeswar Line"]},
    {"code": "HPL", "name": "Haripal", "wiki": "Haripal railway station", "lines": ["Sheoraphuli-Tarakeswar Line"]},
    {"code": "KKAE", "name": "Kaikala", "wiki": "Kaikala railway station", "lines": ["Sheoraphuli-Tarakeswar Line"]},
    {"code": "BAHW", "name": "Bahirkhanda", "wiki": "Bahirkhanda railway station", "lines": ["Sheoraphuli-Tarakeswar Line"]},
    {"code": "LOK", "name": "Loknath", "wiki": "Loknath railway station", "lines": ["Sheoraphuli-Tarakeswar Line"]},
    {"code": "TAK", "name": "Tarakeswar", "wiki": "Tarakeswar railway station", "lines": ["Sheoraphuli-Tarakeswar Line"]}
]

print(f"Total stations in list: {len(CORRIDOR_STATIONS)}")

# Let's batch query Wikipedia in groups of 20
titles = [s["wiki"] for s in CORRIDOR_STATIONS]
wiki_data = {}

for i in range(0, len(titles), 20):
    batch = titles[i:i+20]
    params = {
        "action": "query",
        "prop": "coordinates|langlinks",
        "lllang": "bn",
        "titles": "|".join(batch),
        "redirects": 1,
        "format": "json"
    }
    r = requests.get("https://en.wikipedia.org/w/api.php", params=params, headers={"User-Agent": "PujaProjectBot/1.0 (arnab@example.com)"})
    if r.status_code == 200:
        data = r.json().get("query", {})
        pages = data.get("pages", {})
        # Map redirects
        redirect_map = {red["from"]: red["to"] for red in data.get("redirects", [])}
        for pid, page in pages.items():
            t = page.get("title")
            coords = page.get("coordinates", [{}])[0]
            lat = coords.get("lat")
            lon = coords.get("lon")
            bn = None
            if "langlinks" in page and len(page["langlinks"]) > 0:
                bn = page["langlinks"][0].get("*")
            wiki_data[t] = {"lat": lat, "lon": lon, "name_bn": bn}

print(f"Fetched Wikipedia data for {len(wiki_data)} titles")

results = []
for s in CORRIDOR_STATIONS:
    target_wiki = s["wiki"]
    match = wiki_data.get(target_wiki)
    if not match:
        # Check if redirected title in wiki_data
        for wt, winfo in wiki_data.items():
            if target_wiki.lower().replace("junction ", "") in wt.lower():
                match = winfo
                break
    lat = match.get("lat") if match else None
    lon = match.get("lon") if match else None
    name_bn = match.get("name_bn") if match else None
    
    results.append({
        "code": s["code"],
        "name": s["name"],
        "name_bn": name_bn,
        "lat": lat,
        "lon": lon,
        "lines": s["lines"],
        "wiki": s["wiki"]
    })

missing_coords = [r for r in results if r["lat"] is None or r["lon"] is None]
print(f"Stations with coordinates: {len(results) - len(missing_coords)} / {len(results)}")
print(f"Missing coords ({len(missing_coords)}): {[m['name'] for m in missing_coords]}")

with open("tools/stations/raw/corridor_stations_extracted.json", "w", encoding="utf-8") as f:
    json.dump(results, f, indent=2, ensure_ascii=False)
