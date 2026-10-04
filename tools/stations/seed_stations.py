"""
Curated Tier 1 Railway and Metro stations for the Greater Kolkata Metro region.
Covers:
- Major Terminals: Howrah (HWH), Sealdah (SDAH), Kolkata (KOAA), Santragachi (SRC), Shalimar (SHM)
- Circular Railway stations (BBD Bag, Bagbazar, Sovabazar, Burrabazar, Princep Ghat, Eden Gardens, Majerhat, etc.)
- Suburban Hubs: Dum Dum Jn (DDJ), Bidhan Nagar Road (BNXR), Ballygunge (BLN), Jadavpur (JDP), Garia (GIA), Sonarpur (SPR), Baruipur (BRP), Belgharia (BLH), Agarpara (AGP), Sodepur (SEP), Khardaha (KDH), Barrackpore (BP), Naihati (NH), Bally (BLY), Belur (BEQ), Liluah (LLH), Uttarpara (UPA), Serampore (SRP), Bandel (BDC)
- Kolkata Metro lines (Blue Line 1, Green Line 2, Purple Line 3, Orange Line 6, Yellow Line 4)
"""

CURATED_TIER1_STATIONS = [
    # --- Major Terminals ---
    {
        "type": "Feature",
        "id": "stn_howrah",
        "geometry": {"type": "Point", "coordinates": [88.3426, 22.5839]},
        "properties": {
            "id": "stn_howrah",
            "name": "Howrah Junction",
            "name_bn": "হাওড়া জংশন",
            "code": "HWH",
            "kind": "rail",
            "lat": 22.5839,
            "lon": 88.3426,
            "network": "Eastern Railway / South Eastern Railway",
            "lines": ["Howrah Main Line", "South Eastern Main Line", "Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_sealdah",
        "geometry": {"type": "Point", "coordinates": [88.3718, 22.5674]},
        "properties": {
            "id": "stn_sealdah",
            "name": "Sealdah",
            "name_bn": "শিয়ালদহ",
            "code": "SDAH",
            "kind": "rail",
            "lat": 22.5674,
            "lon": 88.3718,
            "network": "Eastern Railway",
            "lines": ["Sealdah North", "Sealdah South", "Sealdah Main"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_kolkata",
        "geometry": {"type": "Point", "coordinates": [88.3768, 22.6027]},
        "properties": {
            "id": "stn_kolkata",
            "name": "Kolkata (Chitpur)",
            "name_bn": "কলকাতা টার্মিনাল",
            "code": "KOAA",
            "kind": "rail",
            "lat": 22.6027,
            "lon": 88.3768,
            "network": "Eastern Railway",
            "lines": ["Eastern Railway Main"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_santragachi",
        "geometry": {"type": "Point", "coordinates": [88.2818, 22.5807]},
        "properties": {
            "id": "stn_santragachi",
            "name": "Santragachi Junction",
            "name_bn": "সাঁতরাগাছি জংশন",
            "code": "SRC",
            "kind": "rail",
            "lat": 22.5807,
            "lon": 88.2818,
            "network": "South Eastern Railway",
            "lines": ["South Eastern Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_shalimar",
        "geometry": {"type": "Point", "coordinates": [88.3242, 22.5567]},
        "properties": {
            "id": "stn_shalimar",
            "name": "Shalimar",
            "name_bn": "শালিমার",
            "code": "SHM",
            "kind": "rail",
            "lat": 22.5567,
            "lon": 88.3242,
            "network": "South Eastern Railway",
            "lines": ["South Eastern Railway"]
        }
    },

    # --- Sealdah Main & North Suburban ---
    {
        "type": "Feature",
        "id": "stn_bidhan_nagar",
        "geometry": {"type": "Point", "coordinates": [88.3912, 22.5936]},
        "properties": {
            "id": "stn_bidhan_nagar",
            "name": "Bidhan Nagar Road",
            "name_bn": "বিধাননগর রোড",
            "code": "BNXR",
            "kind": "rail",
            "lat": 22.5936,
            "lon": 88.3912,
            "network": "Eastern Railway",
            "lines": ["Sealdah Main", "Sealdah North"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_dum_dum_jn",
        "geometry": {"type": "Point", "coordinates": [88.3934, 22.6219]},
        "properties": {
            "id": "stn_dum_dum_jn",
            "name": "Dum Dum Junction",
            "name_bn": "দমদম জংশন",
            "code": "DDJ",
            "kind": "rail",
            "lat": 22.6219,
            "lon": 88.3934,
            "network": "Eastern Railway",
            "lines": ["Sealdah Main", "Circular Railway"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_belgharia",
        "geometry": {"type": "Point", "coordinates": [88.3887, 22.6592]},
        "properties": {
            "id": "stn_belgharia",
            "name": "Belgharia",
            "name_bn": "বেলঘরিয়া",
            "code": "BLH",
            "kind": "rail",
            "lat": 22.6592,
            "lon": 88.3887,
            "network": "Eastern Railway",
            "lines": ["Sealdah Main"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_agarpara",
        "geometry": {"type": "Point", "coordinates": [88.3855, 22.6806]},
        "properties": {
            "id": "stn_agarpara",
            "name": "Agarpara",
            "name_bn": "আগরপাড়া",
            "code": "AGP",
            "kind": "rail",
            "lat": 22.6806,
            "lon": 88.3855,
            "network": "Eastern Railway",
            "lines": ["Sealdah Main"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_sodepur",
        "geometry": {"type": "Point", "coordinates": [88.3856, 22.6989]},
        "properties": {
            "id": "stn_sodepur",
            "name": "Sodepur",
            "name_bn": "সোদেপুর",
            "code": "SEP",
            "kind": "rail",
            "lat": 22.6989,
            "lon": 88.3856,
            "network": "Eastern Railway",
            "lines": ["Sealdah Main"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_khardaha",
        "geometry": {"type": "Point", "coordinates": [88.3798, 22.7231]},
        "properties": {
            "id": "stn_khardaha",
            "name": "Khardaha",
            "name_bn": "খড়দহ",
            "code": "KDH",
            "kind": "rail",
            "lat": 22.7231,
            "lon": 88.3798,
            "network": "Eastern Railway",
            "lines": ["Sealdah Main"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_barrackpore",
        "geometry": {"type": "Point", "coordinates": [88.3775, 22.7602]},
        "properties": {
            "id": "stn_barrackpore",
            "name": "Barrackpore",
            "name_bn": "ব্যারাকপুর",
            "code": "BP",
            "kind": "rail",
            "lat": 22.7602,
            "lon": 88.3775,
            "network": "Eastern Railway",
            "lines": ["Sealdah Main"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_naihati",
        "geometry": {"type": "Point", "coordinates": [88.4181, 22.8876]},
        "properties": {
            "id": "stn_naihati",
            "name": "Naihati Junction",
            "name_bn": "নৈহাটি জংশন",
            "code": "NH",
            "kind": "rail",
            "lat": 22.8876,
            "lon": 88.4181,
            "network": "Eastern Railway",
            "lines": ["Sealdah Main", "Naihati-Bandel Branch"]
        }
    },

    # --- Sealdah South Suburban ---
    {
        "type": "Feature",
        "id": "stn_park_circus",
        "geometry": {"type": "Point", "coordinates": [88.3725, 22.5442]},
        "properties": {
            "id": "stn_park_circus",
            "name": "Park Circus",
            "name_bn": "পার্ক সার্কাস",
            "code": "PQS",
            "kind": "rail",
            "lat": 22.5442,
            "lon": 88.3725,
            "network": "Eastern Railway",
            "lines": ["Sealdah South"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_ballygunge",
        "geometry": {"type": "Point", "coordinates": [88.3689, 22.5222]},
        "properties": {
            "id": "stn_ballygunge",
            "name": "Ballygunge Junction",
            "name_bn": "বালিগঞ্জ জংশন",
            "code": "BLN",
            "kind": "rail",
            "lat": 22.5222,
            "lon": 88.3689,
            "network": "Eastern Railway",
            "lines": ["Sealdah South", "Circular Railway"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_dhakuria",
        "geometry": {"type": "Point", "coordinates": [88.3678, 22.5085]},
        "properties": {
            "id": "stn_dhakuria",
            "name": "Dhakuria",
            "name_bn": "ঢাকুরিয়া",
            "code": "DHK",
            "kind": "rail",
            "lat": 22.5085,
            "lon": 88.3678,
            "network": "Eastern Railway",
            "lines": ["Sealdah South"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_jadavpur",
        "geometry": {"type": "Point", "coordinates": [88.3706, 22.4984]},
        "properties": {
            "id": "stn_jadavpur",
            "name": "Jadavpur",
            "name_bn": "যাদবপুর",
            "code": "JDP",
            "kind": "rail",
            "lat": 22.4984,
            "lon": 88.3706,
            "network": "Eastern Railway",
            "lines": ["Sealdah South"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_baghajatin",
        "geometry": {"type": "Point", "coordinates": [88.3761, 22.4862]},
        "properties": {
            "id": "stn_baghajatin",
            "name": "Baghajatin",
            "name_bn": "বাঘাযতীন",
            "code": "BGJT",
            "kind": "rail",
            "lat": 22.4862,
            "lon": 88.3761,
            "network": "Eastern Railway",
            "lines": ["Sealdah South"]
        }
    },

    {
        "type": "Feature",
        "id": "stn_sonarpur",
        "geometry": {"type": "Point", "coordinates": [88.4239, 22.4385]},
        "properties": {
            "id": "stn_sonarpur",
            "name": "Sonarpur Junction",
            "name_bn": "সোনারপুর জংশন",
            "code": "SPR",
            "kind": "rail",
            "lat": 22.4385,
            "lon": 88.4239,
            "network": "Eastern Railway",
            "lines": ["Sealdah South", "Canning Branch"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_baruipur",
        "geometry": {"type": "Point", "coordinates": [88.4411, 22.3619]},
        "properties": {
            "id": "stn_baruipur",
            "name": "Baruipur Junction",
            "name_bn": "বারুইপুর জংশন",
            "code": "BRP",
            "kind": "rail",
            "lat": 22.3619,
            "lon": 88.4411,
            "network": "Eastern Railway",
            "lines": ["Sealdah South", "Diamond Harbour Branch"]
        }
    },

    # --- Kolkata Circular Railway & Budge Budge Branch ---
    {
        "type": "Feature",
        "id": "stn_bagbazar",
        "geometry": {"type": "Point", "coordinates": [88.3611, 22.6041]},
        "properties": {
            "id": "stn_bagbazar",
            "name": "Bagbazar",
            "name_bn": "বাগবাজার",
            "code": "BBR",
            "kind": "rail",
            "lat": 22.6041,
            "lon": 88.3611,
            "network": "Eastern Railway",
            "lines": ["Circular Railway"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_sovabazar",
        "geometry": {"type": "Point", "coordinates": [88.3564, 22.5975]},
        "properties": {
            "id": "stn_sovabazar",
            "name": "Sovabazar Ahiritola",
            "name_bn": "শোভাবাজার আহিরীটোলা",
            "code": "SOLA",
            "kind": "rail",
            "lat": 22.5975,
            "lon": 88.3564,
            "network": "Eastern Railway",
            "lines": ["Circular Railway"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_burrabazar",
        "geometry": {"type": "Point", "coordinates": [88.3506, 22.5878]},
        "properties": {
            "id": "stn_burrabazar",
            "name": "Burrabazar",
            "name_bn": "বড়বাজার",
            "code": "BZB",
            "kind": "rail",
            "lat": 22.5878,
            "lon": 88.3506,
            "network": "Eastern Railway",
            "lines": ["Circular Railway"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_bbd_bag",
        "geometry": {"type": "Point", "coordinates": [88.3444, 22.5739]},
        "properties": {
            "id": "stn_bbd_bag",
            "name": "B.B.D. Bag",
            "name_bn": "বিবাদী বাগ",
            "code": "BBDB",
            "kind": "rail",
            "lat": 22.5739,
            "lon": 88.3444,
            "network": "Eastern Railway",
            "lines": ["Circular Railway"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_eden_gardens",
        "geometry": {"type": "Point", "coordinates": [88.3431, 22.5642]},
        "properties": {
            "id": "stn_eden_gardens",
            "name": "Eden Gardens",
            "name_bn": "ইডেন গার্ডেন্স",
            "code": "EDG",
            "kind": "rail",
            "lat": 22.5642,
            "lon": 88.3431,
            "network": "Eastern Railway",
            "lines": ["Circular Railway"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_princep_ghat",
        "geometry": {"type": "Point", "coordinates": [88.3308, 22.5558]},
        "properties": {
            "id": "stn_princep_ghat",
            "name": "Princep Ghat",
            "name_bn": "প্রিন্সেপ ঘাট",
            "code": "PPGT",
            "kind": "rail",
            "lat": 22.5558,
            "lon": 88.3308,
            "network": "Eastern Railway",
            "lines": ["Circular Railway"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_majerhat",
        "geometry": {"type": "Point", "coordinates": [88.3228, 22.5186]},
        "properties": {
            "id": "stn_majerhat",
            "name": "Majerhat",
            "name_bn": "মাঝেরহাট",
            "code": "MJT",
            "kind": "rail",
            "lat": 22.5186,
            "lon": 88.3228,
            "network": "Eastern Railway",
            "lines": ["Circular Railway", "Sealdah South Budge Budge"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_new_alipore",
        "geometry": {"type": "Point", "coordinates": [88.3331, 22.5117]},
        "properties": {
            "id": "stn_new_alipore",
            "name": "New Alipore",
            "name_bn": "নিউ আলিপুর",
            "code": "NACC",
            "kind": "rail",
            "lat": 22.5117,
            "lon": 88.3331,
            "network": "Eastern Railway",
            "lines": ["Circular Railway"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_tollygunge",
        "geometry": {"type": "Point", "coordinates": [88.3456, 22.5056]},
        "properties": {
            "id": "stn_tollygunge",
            "name": "Tollygunge",
            "name_bn": "টালিগঞ্জ",
            "code": "TLG",
            "kind": "rail",
            "lat": 22.5056,
            "lon": 88.3456,
            "network": "Eastern Railway",
            "lines": ["Circular Railway"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_lake_gardens",
        "geometry": {"type": "Point", "coordinates": [88.3581, 22.5094]},
        "properties": {
            "id": "stn_lake_gardens",
            "name": "Lake Gardens",
            "name_bn": "লেক গার্ডেন্স",
            "code": "LKF",
            "kind": "rail",
            "lat": 22.5094,
            "lon": 88.3581,
            "network": "Eastern Railway",
            "lines": ["Circular Railway"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_brace_bridge",
        "geometry": {"type": "Point", "coordinates": [88.2936, 22.5097]},
        "properties": {
            "id": "stn_brace_bridge",
            "name": "Brace Bridge",
            "name_bn": "ব্রেস ব্রিজ",
            "code": "BRJ",
            "kind": "rail",
            "lat": 22.5097,
            "lon": 88.2936,
            "network": "Eastern Railway",
            "lines": ["Budge Budge Branch"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_budge_budge",
        "geometry": {"type": "Point", "coordinates": [88.1819, 22.4828]},
        "properties": {
            "id": "stn_budge_budge",
            "name": "Budge Budge",
            "name_bn": "বজবজ",
            "code": "BGB",
            "kind": "rail",
            "lat": 22.4828,
            "lon": 88.1819,
            "network": "Eastern Railway",
            "lines": ["Budge Budge Branch"]
        }
    },

    # --- Howrah Division Suburban ---
    {
        "type": "Feature",
        "id": "stn_liluah",
        "geometry": {"type": "Point", "coordinates": [88.3375, 22.6172]},
        "properties": {
            "id": "stn_liluah",
            "name": "Liluah",
            "name_bn": "লিলুয়া",
            "code": "LLH",
            "kind": "rail",
            "lat": 22.6172,
            "lon": 88.3375,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_belur",
        "geometry": {"type": "Point", "coordinates": [88.3444, 22.6347]},
        "properties": {
            "id": "stn_belur",
            "name": "Belur",
            "name_bn": "বেলুড়",
            "code": "BEQ",
            "kind": "rail",
            "lat": 22.6347,
            "lon": 88.3444,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_bally",
        "geometry": {"type": "Point", "coordinates": [88.3431, 22.6517]},
        "properties": {
            "id": "stn_bally",
            "name": "Bally",
            "name_bn": "বালী",
            "code": "BLY",
            "kind": "rail",
            "lat": 22.6517,
            "lon": 88.3431,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line", "Bally-Dankuni Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_uttarpara",
        "geometry": {"type": "Point", "coordinates": [88.3417, 22.6681]},
        "properties": {
            "id": "stn_uttarpara",
            "name": "Uttarpara",
            "name_bn": "উত্তরপাড়া",
            "code": "UPA",
            "kind": "rail",
            "lat": 22.6681,
            "lon": 88.3417,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_hindmotor",
        "geometry": {"type": "Point", "coordinates": [88.3419, 22.6861]},
        "properties": {
            "id": "stn_hindmotor",
            "name": "Hind Motor",
            "name_bn": "হিন্দমোটর",
            "code": "HM",
            "kind": "rail",
            "lat": 22.6861,
            "lon": 88.3419,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_konnagar",
        "geometry": {"type": "Point", "coordinates": [88.3442, 22.7011]},
        "properties": {
            "id": "stn_konnagar",
            "name": "Konnagar",
            "name_bn": "কোন্নগর",
            "code": "KOG",
            "kind": "rail",
            "lat": 22.7011,
            "lon": 88.3442,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_rishra",
        "geometry": {"type": "Point", "coordinates": [88.3467, 22.7161]},
        "properties": {
            "id": "stn_rishra",
            "name": "Rishra",
            "name_bn": "রিষড়া",
            "code": "RIS",
            "kind": "rail",
            "lat": 22.7161,
            "lon": 88.3467,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_serampore",
        "geometry": {"type": "Point", "coordinates": [88.3422, 22.7533]},
        "properties": {
            "id": "stn_serampore",
            "name": "Serampore",
            "name_bn": "শ্রীরামপুর",
            "code": "SRP",
            "kind": "rail",
            "lat": 22.7533,
            "lon": 88.3422,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_bandel",
        "geometry": {"type": "Point", "coordinates": [88.3769, 22.9239]},
        "properties": {
            "id": "stn_bandel",
            "name": "Bandel Junction",
            "name_bn": "ব্যান্ডেল জংশন",
            "code": "BDC",
            "kind": "rail",
            "lat": 22.9239,
            "lon": 88.3769,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line", "Bandel-Katwa Line"]
        }
    },

    # --- Kolkata Metro (Blue Line 1) ---
    {
        "type": "Feature",
        "id": "stn_m_dakshineswar",
        "geometry": {"type": "Point", "coordinates": [88.3637, 22.6540]},
        "properties": {
            "id": "stn_m_dakshineswar",
            "name": "Dakshineswar Metro",
            "name_bn": "দক্ষিণেশ্বর মেট্রো",
            "code": "KDSW",
            "kind": "metro",
            "lat": 22.6540,
            "lon": 88.3637,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_baranagar",
        "geometry": {"type": "Point", "coordinates": [88.3789, 22.6535]},
        "properties": {
            "id": "stn_m_baranagar",
            "name": "Baranagar Metro",
            "name_bn": "বরাহনগর মেট্রো",
            "code": "KBAR",
            "kind": "metro",
            "lat": 22.6535,
            "lon": 88.3789,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_noapara",
        "geometry": {"type": "Point", "coordinates": [88.3939, 22.6397]},
        "properties": {
            "id": "stn_m_noapara",
            "name": "Noapara Metro",
            "name_bn": "নোয়াপাড়া মেট্রো",
            "code": "KNAP",
            "kind": "metro",
            "lat": 22.6397,
            "lon": 88.3939,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)", "Yellow Line (Line 4)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_dum_dum",
        "geometry": {"type": "Point", "coordinates": [88.3928, 22.6225]},
        "properties": {
            "id": "stn_m_dum_dum",
            "name": "Dum Dum Metro",
            "name_bn": "দমদম মেট্রো",
            "code": "KDMI",
            "kind": "metro",
            "lat": 22.6225,
            "lon": 88.3928,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_belgachia",
        "geometry": {"type": "Point", "coordinates": [88.3842, 22.6075]},
        "properties": {
            "id": "stn_m_belgachia",
            "name": "Belgachia Metro",
            "name_bn": "বেলগাছিয়া মেট্রো",
            "code": "KBEL",
            "kind": "metro",
            "lat": 22.6075,
            "lon": 88.3842,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_shyambazar",
        "geometry": {"type": "Point", "coordinates": [88.3711, 22.6017]},
        "properties": {
            "id": "stn_m_shyambazar",
            "name": "Shyambazar Metro",
            "name_bn": "শ্যামবাজার মেট্রো",
            "code": "KSYM",
            "kind": "metro",
            "lat": 22.6017,
            "lon": 88.3711,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_shobhabazar",
        "geometry": {"type": "Point", "coordinates": [88.3686, 22.5936]},
        "properties": {
            "id": "stn_m_shobhabazar",
            "name": "Shobhabazar Sutanuti Metro",
            "name_bn": "শোভাবাজার সুতানুটি মেট্রো",
            "code": "KSOB",
            "kind": "metro",
            "lat": 22.5936,
            "lon": 88.3686,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_girish_park",
        "geometry": {"type": "Point", "coordinates": [88.3639, 22.5858]},
        "properties": {
            "id": "stn_m_girish_park",
            "name": "Girish Park Metro",
            "name_bn": "গিরিশ পার্ক মেট্রো",
            "code": "KGIR",
            "kind": "metro",
            "lat": 22.5858,
            "lon": 88.3639,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_mg_road",
        "geometry": {"type": "Point", "coordinates": [88.3608, 22.5786]},
        "properties": {
            "id": "stn_m_mg_road",
            "name": "Mahatma Gandhi Road Metro",
            "name_bn": "মহাত্মা গান্ধী রোড মেট্রো",
            "code": "KMGR",
            "kind": "metro",
            "lat": 22.5786,
            "lon": 88.3608,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_central",
        "geometry": {"type": "Point", "coordinates": [88.3567, 22.5703]},
        "properties": {
            "id": "stn_m_central",
            "name": "Central Metro",
            "name_bn": "সেন্ট্রাল মেট্রো",
            "code": "KCEN",
            "kind": "metro",
            "lat": 22.5703,
            "lon": 88.3567,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_chandni_chowk",
        "geometry": {"type": "Point", "coordinates": [88.3533, 22.5647]},
        "properties": {
            "id": "stn_m_chandni_chowk",
            "name": "Chandni Chowk Metro",
            "name_bn": "চাঁদনী চক মেট্রো",
            "code": "KCHC",
            "kind": "metro",
            "lat": 22.5647,
            "lon": 88.3533,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_esplanade",
        "geometry": {"type": "Point", "coordinates": [88.3517, 22.5628]},
        "properties": {
            "id": "stn_m_esplanade",
            "name": "Esplanade Metro",
            "name_bn": "এসপ্ল্যানেড মেট্রো",
            "code": "KESP",
            "kind": "metro",
            "lat": 22.5628,
            "lon": 88.3517,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)", "Green Line (Line 2)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_park_street",
        "geometry": {"type": "Point", "coordinates": [88.3511, 22.5539]},
        "properties": {
            "id": "stn_m_park_street",
            "name": "Park Street Metro",
            "name_bn": "পার্ক স্ট্রিট মেট্রো",
            "code": "KPKX",
            "kind": "metro",
            "lat": 22.5539,
            "lon": 88.3511,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_maidan",
        "geometry": {"type": "Point", "coordinates": [88.3494, 22.5456]},
        "properties": {
            "id": "stn_m_maidan",
            "name": "Maidan Metro",
            "name_bn": "ময়দান মেট্রো",
            "code": "KMDN",
            "kind": "metro",
            "lat": 22.5456,
            "lon": 88.3494,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_rabindra_sadan",
        "geometry": {"type": "Point", "coordinates": [88.3469, 22.5381]},
        "properties": {
            "id": "stn_m_rabindra_sadan",
            "name": "Rabindra Sadan Metro",
            "name_bn": "রবীন্দ্র সদন মেট্রো",
            "code": "KRSD",
            "kind": "metro",
            "lat": 22.5381,
            "lon": 88.3469,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_netaji_bhavan",
        "geometry": {"type": "Point", "coordinates": [88.3453, 22.5303]},
        "properties": {
            "id": "stn_m_netaji_bhavan",
            "name": "Netaji Bhavan Metro",
            "name_bn": "নেতাজি ভবন মেট্রো",
            "code": "KBHV",
            "kind": "metro",
            "lat": 22.5303,
            "lon": 88.3453,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_jatin_das_park",
        "geometry": {"type": "Point", "coordinates": [88.3458, 22.5217]},
        "properties": {
            "id": "stn_m_jatin_das_park",
            "name": "Jatin Das Park Metro",
            "name_bn": "যতীন দাস পার্ক মেট্রো",
            "code": "KJDP",
            "kind": "metro",
            "lat": 22.5217,
            "lon": 88.3458,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_kalighat",
        "geometry": {"type": "Point", "coordinates": [88.3458, 22.5153]},
        "properties": {
            "id": "stn_m_kalighat",
            "name": "Kalighat Metro",
            "name_bn": "কালীঘাট মেট্রো",
            "code": "KKGH",
            "kind": "metro",
            "lat": 22.5153,
            "lon": 88.3458,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_rabindra_sarobar",
        "geometry": {"type": "Point", "coordinates": [88.3461, 22.5083]},
        "properties": {
            "id": "stn_m_rabindra_sarobar",
            "name": "Rabindra Sarobar Metro",
            "name_bn": "রবীন্দ্র সরোবর মেট্রো",
            "code": "KRSO",
            "kind": "metro",
            "lat": 22.5083,
            "lon": 88.3461,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_mahanayak_uttankumar",
        "geometry": {"type": "Point", "coordinates": [88.3453, 22.4975]},
        "properties": {
            "id": "stn_m_mahanayak_uttankumar",
            "name": "Mahanayak Uttam Kumar Metro",
            "name_bn": "মহানায়ক উত্তম কুমার মেট্রো",
            "code": "KMUK",
            "kind": "metro",
            "lat": 22.4975,
            "lon": 88.3453,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_netaji",
        "geometry": {"type": "Point", "coordinates": [88.3475, 22.4842]},
        "properties": {
            "id": "stn_m_netaji",
            "name": "Netaji (Kudghat) Metro",
            "name_bn": "নেতাজি মেট্রো",
            "code": "KNET",
            "kind": "metro",
            "lat": 22.4842,
            "lon": 88.3475,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_masterda_surya_sen",
        "geometry": {"type": "Point", "coordinates": [88.3547, 22.4744]},
        "properties": {
            "id": "stn_m_masterda_surya_sen",
            "name": "Masterda Surya Sen (Bansdroni) Metro",
            "name_bn": "মাস্টারদা সূর্য সেন মেট্রো",
            "code": "KMDS",
            "kind": "metro",
            "lat": 22.4744,
            "lon": 88.3547,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_gitanjali",
        "geometry": {"type": "Point", "coordinates": [88.3653, 22.4681]},
        "properties": {
            "id": "stn_m_gitanjali",
            "name": "Gitanjali (Naktala) Metro",
            "name_bn": "গীতাঞ্জলি মেট্রো",
            "code": "KGTN",
            "kind": "metro",
            "lat": 22.4681,
            "lon": 88.3653,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_kavi_nazrul",
        "geometry": {"type": "Point", "coordinates": [88.3756, 22.4628]},
        "properties": {
            "id": "stn_m_kavi_nazrul",
            "name": "Kavi Nazrul Metro",
            "name_bn": "কবি নজরুল মেট্রো",
            "code": "KKNZ",
            "kind": "metro",
            "lat": 22.4628,
            "lon": 88.3756,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_shahid_khudiram",
        "geometry": {"type": "Point", "coordinates": [88.3847, 22.4578]},
        "properties": {
            "id": "stn_m_shahid_khudiram",
            "name": "Shahid Khudiram Metro",
            "name_bn": "শহীদ ক্ষুদিরাম মেট্রো",
            "code": "KSKD",
            "kind": "metro",
            "lat": 22.4578,
            "lon": 88.3847,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_kavi_subhash",
        "geometry": {"type": "Point", "coordinates": [88.3975, 22.4575]},
        "properties": {
            "id": "stn_m_kavi_subhash",
            "name": "Kavi Subhash Metro",
            "name_bn": "কবি সুভাষ মেট্রো",
            "code": "KKSB",
            "kind": "metro",
            "lat": 22.4575,
            "lon": 88.3975,
            "network": "Kolkata Metro",
            "lines": ["Blue Line (Line 1)", "Orange Line (Line 6)"]
        }
    },

    # --- Kolkata Metro (Green Line 2 - East-West Corridor) ---
    {
        "type": "Feature",
        "id": "stn_m_howrah_maidan",
        "geometry": {"type": "Point", "coordinates": [88.3283, 22.5847]},
        "properties": {
            "id": "stn_m_howrah_maidan",
            "name": "Howrah Maidan Metro",
            "name_bn": "হাওড়া ময়দান মেট্রো",
            "code": "KHWM",
            "kind": "metro",
            "lat": 22.5847,
            "lon": 88.3283,
            "network": "Kolkata Metro",
            "lines": ["Green Line (Line 2)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_howrah_railway_metro",
        "geometry": {"type": "Point", "coordinates": [88.3411, 22.5836]},
        "properties": {
            "id": "stn_m_howrah_railway_metro",
            "name": "Howrah Station Metro",
            "name_bn": "হাওড়া স্টেশন মেট্রো",
            "code": "KHWH",
            "kind": "metro",
            "lat": 22.5836,
            "lon": 88.3411,
            "network": "Kolkata Metro",
            "lines": ["Green Line (Line 2)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_sealdah_metro",
        "geometry": {"type": "Point", "coordinates": [88.3711, 22.5669]},
        "properties": {
            "id": "stn_m_sealdah_metro",
            "name": "Sealdah Metro",
            "name_bn": "শিয়ালদহ মেট্রো",
            "code": "KSDH",
            "kind": "metro",
            "lat": 22.5669,
            "lon": 88.3711,
            "network": "Kolkata Metro",
            "lines": ["Green Line (Line 2)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_phoolbagan",
        "geometry": {"type": "Point", "coordinates": [88.3906, 22.5683]},
        "properties": {
            "id": "stn_m_phoolbagan",
            "name": "Phoolbagan Metro",
            "name_bn": "ফুলবাগান মেট্রো",
            "code": "KPBG",
            "kind": "metro",
            "lat": 22.5683,
            "lon": 88.3906,
            "network": "Kolkata Metro",
            "lines": ["Green Line (Line 2)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_salt_lake_stadium",
        "geometry": {"type": "Point", "coordinates": [88.4061, 22.5703]},
        "properties": {
            "id": "stn_m_salt_lake_stadium",
            "name": "Salt Lake Stadium Metro",
            "name_bn": "সল্টলেক স্টেডিয়াম মেট্রো",
            "code": "KSLS",
            "kind": "metro",
            "lat": 22.5703,
            "lon": 88.4061,
            "network": "Kolkata Metro",
            "lines": ["Green Line (Line 2)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_bengal_chemical",
        "geometry": {"type": "Point", "coordinates": [88.4069, 22.5786]},
        "properties": {
            "id": "stn_m_bengal_chemical",
            "name": "Bengal Chemical Metro",
            "name_bn": "বেঙ্গল কেমিক্যাল মেট্রো",
            "code": "KBCH",
            "kind": "metro",
            "lat": 22.5786,
            "lon": 88.4069,
            "network": "Kolkata Metro",
            "lines": ["Green Line (Line 2)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_city_centre",
        "geometry": {"type": "Point", "coordinates": [88.4075, 22.5878]},
        "properties": {
            "id": "stn_m_city_centre",
            "name": "City Centre Metro",
            "name_bn": "সিটি সেন্টার মেট্রো",
            "code": "KCTC",
            "kind": "metro",
            "lat": 22.5878,
            "lon": 88.4075,
            "network": "Kolkata Metro",
            "lines": ["Green Line (Line 2)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_central_park",
        "geometry": {"type": "Point", "coordinates": [88.4161, 22.5875]},
        "properties": {
            "id": "stn_m_central_park",
            "name": "Central Park Metro",
            "name_bn": "সেন্ট্রাল পার্ক মেট্রো",
            "code": "KCPK",
            "kind": "metro",
            "lat": 22.5875,
            "lon": 88.4161,
            "network": "Kolkata Metro",
            "lines": ["Green Line (Line 2)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_karunamoyee",
        "geometry": {"type": "Point", "coordinates": [88.4239, 22.5847]},
        "properties": {
            "id": "stn_m_karunamoyee",
            "name": "Karunamoyee Metro",
            "name_bn": "করুণাময়ী মেট্রো",
            "code": "KKMY",
            "kind": "metro",
            "lat": 22.5847,
            "lon": 88.4239,
            "network": "Kolkata Metro",
            "lines": ["Green Line (Line 2)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_sector_v",
        "geometry": {"type": "Point", "coordinates": [88.4325, 22.5808]},
        "properties": {
            "id": "stn_m_sector_v",
            "name": "Salt Lake Sector V Metro",
            "name_bn": "সল্টলেক সেক্টর ৫ মেট্রো",
            "code": "KSEC",
            "kind": "metro",
            "lat": 22.5808,
            "lon": 88.4325,
            "network": "Kolkata Metro",
            "lines": ["Green Line (Line 2)", "Orange Line (Line 6)"]
        }
    },

    # --- Kolkata Metro (Purple Line 3 - Joka-Majerhat) ---
    {
        "type": "Feature",
        "id": "stn_m_joka",
        "geometry": {"type": "Point", "coordinates": [88.2917, 22.4497]},
        "properties": {
            "id": "stn_m_joka",
            "name": "Joka Metro",
            "name_bn": "জোকা মেট্রো",
            "code": "KJOK",
            "kind": "metro",
            "lat": 22.4497,
            "lon": 88.2917,
            "network": "Kolkata Metro",
            "lines": ["Purple Line (Line 3)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_thakurpukur",
        "geometry": {"type": "Point", "coordinates": [88.3006, 22.4636]},
        "properties": {
            "id": "stn_m_thakurpukur",
            "name": "Thakurpukur Metro",
            "name_bn": "ঠাকুরপুকুর মেট্রো",
            "code": "KTHP",
            "kind": "metro",
            "lat": 22.4636,
            "lon": 88.3006,
            "network": "Kolkata Metro",
            "lines": ["Purple Line (Line 3)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_sakherbazar",
        "geometry": {"type": "Point", "coordinates": [88.3089, 22.4789]},
        "properties": {
            "id": "stn_m_sakherbazar",
            "name": "Sakherbazar Metro",
            "name_bn": "সখেরবাজার মেট্রো",
            "code": "KSKB",
            "kind": "metro",
            "lat": 22.4789,
            "lon": 88.3089,
            "network": "Kolkata Metro",
            "lines": ["Purple Line (Line 3)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_behala_chowrasta",
        "geometry": {"type": "Point", "coordinates": [88.3136, 22.4925]},
        "properties": {
            "id": "stn_m_behala_chowrasta",
            "name": "Behala Chowrasta Metro",
            "name_bn": "বেহালা চৌরাস্তা মেট্রো",
            "code": "KBHC",
            "kind": "metro",
            "lat": 22.4925,
            "lon": 88.3136,
            "network": "Kolkata Metro",
            "lines": ["Purple Line (Line 3)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_behala_bazar",
        "geometry": {"type": "Point", "coordinates": [88.3181, 22.5028]},
        "properties": {
            "id": "stn_m_behala_bazar",
            "name": "Behala Bazar Metro",
            "name_bn": "বেহালা বাজার মেট্রো",
            "code": "KBHZ",
            "kind": "metro",
            "lat": 22.5028,
            "lon": 88.3181,
            "network": "Kolkata Metro",
            "lines": ["Purple Line (Line 3)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_taratala",
        "geometry": {"type": "Point", "coordinates": [88.3197, 22.5117]},
        "properties": {
            "id": "stn_m_taratala",
            "name": "Taratala Metro",
            "name_bn": "তারাতলা মেট্রো",
            "code": "KTRT",
            "kind": "metro",
            "lat": 22.5117,
            "lon": 88.3197,
            "network": "Kolkata Metro",
            "lines": ["Purple Line (Line 3)"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_m_majerhat_metro",
        "geometry": {"type": "Point", "coordinates": [88.3225, 22.5181]},
        "properties": {
            "id": "stn_m_majerhat_metro",
            "name": "Majerhat Metro",
            "name_bn": "মাঝেরহাট মেট্রো",
            "code": "KMJT",
            "kind": "metro",
            "lat": 22.5181,
            "lon": 88.3225,
            "network": "Kolkata Metro",
            "lines": ["Purple Line (Line 3)"]
        }
    },
    # --- Howrah-Bardhaman Main Line (Extended to Barddhaman Junction) ---,
    {
        "type": "Feature",
        "id": "stn_sheoraphuli_junction",
        "geometry": {"type": "Point", "coordinates": [88.328397, 22.774737]},
        "properties": {
            "id": "stn_sheoraphuli_junction",
            "name": "Sheoraphuli Junction",
            "name_bn": "শেওড়াফুলি জংশন",
            "code": "SHE",
            "kind": "rail",
            "lat": 22.774737,
            "lon": 88.328397,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line", "Sheoraphuli-Tarakeswar Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_baidyabati",
        "geometry": {"type": "Point", "coordinates": [88.332038, 22.795492]},
        "properties": {
            "id": "stn_baidyabati",
            "name": "Baidyabati",
            "name_bn": "বৈদ্যবাটি",
            "code": "BBAE",
            "kind": "rail",
            "lat": 22.795492,
            "lon": 88.332038,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_bhadreshwar",
        "geometry": {"type": "Point", "coordinates": [88.341535, 22.82794]},
        "properties": {
            "id": "stn_bhadreshwar",
            "name": "Bhadreshwar",
            "name_bn": "ভদ্রেশ্বর",
            "code": "BHR",
            "kind": "rail",
            "lat": 22.82794,
            "lon": 88.341535,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_mankundu",
        "geometry": {"type": "Point", "coordinates": [88.346368, 22.846462]},
        "properties": {
            "id": "stn_mankundu",
            "name": "Mankundu",
            "name_bn": "মানকুণ্ডু",
            "code": "MUU",
            "kind": "rail",
            "lat": 22.846462,
            "lon": 88.346368,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_chandannagar",
        "geometry": {"type": "Point", "coordinates": [88.354421, 22.86747]},
        "properties": {
            "id": "stn_chandannagar",
            "name": "Chandannagar",
            "name_bn": "চন্দননগর",
            "code": "CGR",
            "kind": "rail",
            "lat": 22.86747,
            "lon": 88.354421,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_chuchura",
        "geometry": {"type": "Point", "coordinates": [88.3695, 22.890191]},
        "properties": {
            "id": "stn_chuchura",
            "name": "Chuchura",
            "name_bn": "চুঁচুড়া",
            "code": "CNS",
            "kind": "rail",
            "lat": 22.890191,
            "lon": 88.3695,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_hooghly",
        "geometry": {"type": "Point", "coordinates": [88.376163, 22.905827]},
        "properties": {
            "id": "stn_hooghly",
            "name": "Hooghly",
            "name_bn": "হুগলি",
            "code": "HGY",
            "kind": "rail",
            "lat": 22.905827,
            "lon": 88.376163,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_adisaptagram",
        "geometry": {"type": "Point", "coordinates": [88.379102, 22.954619]},
        "properties": {
            "id": "stn_adisaptagram",
            "name": "Adisaptagram",
            "name_bn": "আদিসপ্তগ্রাম",
            "code": "ADST",
            "kind": "rail",
            "lat": 22.954619,
            "lon": 88.379102,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_magra",
        "geometry": {"type": "Point", "coordinates": [88.368112, 22.984155]},
        "properties": {
            "id": "stn_magra",
            "name": "Magra",
            "name_bn": "মগরা",
            "code": "MUG",
            "kind": "rail",
            "lat": 22.984155,
            "lon": 88.368112,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_talandu",
        "geometry": {"type": "Point", "coordinates": [88.345583, 23.010525]},
        "properties": {
            "id": "stn_talandu",
            "name": "Talandu",
            "name_bn": "তালাণ্ডু",
            "code": "TLO",
            "kind": "rail",
            "lat": 23.010525,
            "lon": 88.345583,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_khanyan",
        "geometry": {"type": "Point", "coordinates": [88.315393, 23.046446]},
        "properties": {
            "id": "stn_khanyan",
            "name": "Khanyan",
            "name_bn": "খন্যান",
            "code": "KHN",
            "kind": "rail",
            "lat": 23.046446,
            "lon": 88.315393,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_pundooah",
        "geometry": {"type": "Point", "coordinates": [88.26968, 23.070651]},
        "properties": {
            "id": "stn_pundooah",
            "name": "Pundooah",
            "name_bn": "পাণ্ডুয়া",
            "code": "PDA",
            "kind": "rail",
            "lat": 23.070651,
            "lon": 88.26968,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_simlagarh",
        "geometry": {"type": "Point", "coordinates": [88.23161, 23.096234]},
        "properties": {
            "id": "stn_simlagarh",
            "name": "Simlagarh",
            "name_bn": "সিমলাগড়",
            "code": "SLG",
            "kind": "rail",
            "lat": 23.096234,
            "lon": 88.23161,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_bainchigram",
        "geometry": {"type": "Point", "coordinates": [88.216109, 23.106517]},
        "properties": {
            "id": "stn_bainchigram",
            "name": "Bainchigram",
            "name_bn": "বৈঁচিগ্রাম",
            "code": "BCGM",
            "kind": "rail",
            "lat": 23.106517,
            "lon": 88.216109,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_bainchi",
        "geometry": {"type": "Point", "coordinates": [88.196729, 23.119483]},
        "properties": {
            "id": "stn_bainchi",
            "name": "Bainchi",
            "name_bn": "বৈঁচি",
            "code": "BOI",
            "kind": "rail",
            "lat": 23.119483,
            "lon": 88.196729,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_debipur",
        "geometry": {"type": "Point", "coordinates": [88.155998, 23.144613]},
        "properties": {
            "id": "stn_debipur",
            "name": "Debipur",
            "name_bn": "দেবীপুর",
            "code": "DBP",
            "kind": "rail",
            "lat": 23.144613,
            "lon": 88.155998,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_bagila",
        "geometry": {"type": "Point", "coordinates": [88.122004, 23.160146]},
        "properties": {
            "id": "stn_bagila",
            "name": "Bagila",
            "name_bn": "বাগিলা",
            "code": "BGF",
            "kind": "rail",
            "lat": 23.160146,
            "lon": 88.122004,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_memari",
        "geometry": {"type": "Point", "coordinates": [88.095637, 23.172935]},
        "properties": {
            "id": "stn_memari",
            "name": "Memari",
            "name_bn": "মেমারি",
            "code": "MYM",
            "kind": "rail",
            "lat": 23.172935,
            "lon": 88.095637,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_nimo",
        "geometry": {"type": "Point", "coordinates": [88.069346, 23.180298]},
        "properties": {
            "id": "stn_nimo",
            "name": "Nimo",
            "name_bn": "নিমো",
            "code": "NMO",
            "kind": "rail",
            "lat": 23.180298,
            "lon": 88.069346,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_rasulpur",
        "geometry": {"type": "Point", "coordinates": [88.040742, 23.187509]},
        "properties": {
            "id": "stn_rasulpur",
            "name": "Rasulpur",
            "name_bn": "রসুলপুর",
            "code": "RSLR",
            "kind": "rail",
            "lat": 23.187509,
            "lon": 88.040742,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_palsit",
        "geometry": {"type": "Point", "coordinates": [88.003161, 23.196622]},
        "properties": {
            "id": "stn_palsit",
            "name": "Palsit",
            "name_bn": "পালসিট",
            "code": "PLAE",
            "kind": "rail",
            "lat": 23.196622,
            "lon": 88.003161,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line"]
        }
    },
    # --- Howrah-Bardhaman Chord Line (Dankuni to Saktigarh/Barddhaman) ---,
    {
        "type": "Feature",
        "id": "stn_saktigarh",
        "geometry": {"type": "Point", "coordinates": [87.968882, 23.207213]},
        "properties": {
            "id": "stn_saktigarh",
            "name": "Saktigarh",
            "name_bn": "শক্তিগড়",
            "code": "SKG",
            "kind": "rail",
            "lat": 23.207213,
            "lon": 87.968882,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line", "Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_gangpur",
        "geometry": {"type": "Point", "coordinates": [87.927095, 23.223521]},
        "properties": {
            "id": "stn_gangpur",
            "name": "Gangpur",
            "name_bn": "গাংপুর",
            "code": "GRP",
            "kind": "rail",
            "lat": 23.223521,
            "lon": 87.927095,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line", "Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_belanagar",
        "geometry": {"type": "Point", "coordinates": [88.317093, 22.661206]},
        "properties": {
            "id": "stn_belanagar",
            "name": "Belanagar",
            "name_bn": "বেলানগর",
            "code": "BZL",
            "kind": "rail",
            "lat": 22.661206,
            "lon": 88.317093,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_dankuni_junction",
        "geometry": {"type": "Point", "coordinates": [88.290975, 22.677995]},
        "properties": {
            "id": "stn_dankuni_junction",
            "name": "Dankuni Junction",
            "name_bn": "ডানকুনি জংশন",
            "code": "DKAE",
            "kind": "rail",
            "lat": 22.677995,
            "lon": 88.290975,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord", "Sealdah-Dankuni Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_gobra",
        "geometry": {"type": "Point", "coordinates": [88.279274, 22.695504]},
        "properties": {
            "id": "stn_gobra",
            "name": "Gobra",
            "name_bn": "গোবরা",
            "code": "GBRA",
            "kind": "rail",
            "lat": 22.695504,
            "lon": 88.279274,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_janai_road",
        "geometry": {"type": "Point", "coordinates": [88.265695, 22.720873]},
        "properties": {
            "id": "stn_janai_road",
            "name": "Janai Road",
            "name_bn": "জনাই রোড",
            "code": "JOX",
            "kind": "rail",
            "lat": 22.720873,
            "lon": 88.265695,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_begampur",
        "geometry": {"type": "Point", "coordinates": [88.255644, 22.737627]},
        "properties": {
            "id": "stn_begampur",
            "name": "Begampur",
            "name_bn": "বেগমপুর",
            "code": "BPAE",
            "kind": "rail",
            "lat": 22.737627,
            "lon": 88.255644,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_baruipara",
        "geometry": {"type": "Point", "coordinates": [88.237007, 22.766962]},
        "properties": {
            "id": "stn_baruipara",
            "name": "Baruipara",
            "name_bn": "বারুইপাড়া",
            "code": "BRPA",
            "kind": "rail",
            "lat": 22.766962,
            "lon": 88.237007,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_mirzapur_bankipur",
        "geometry": {"type": "Point", "coordinates": [88.222182, 22.790742]},
        "properties": {
            "id": "stn_mirzapur_bankipur",
            "name": "Mirzapur Bankipur",
            "name_bn": "মির্জাপুর বাঁকিপুর",
            "code": "MBE",
            "kind": "rail",
            "lat": 22.790742,
            "lon": 88.222182,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_balarambati",
        "geometry": {"type": "Point", "coordinates": [88.211622, 22.808031]},
        "properties": {
            "id": "stn_balarambati",
            "name": "Balarambati",
            "name_bn": "বলরামবাটী",
            "code": "BLAE",
            "kind": "rail",
            "lat": 22.808031,
            "lon": 88.211622,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_kamarkundu_junction",
        "geometry": {"type": "Point", "coordinates": [88.204736, 22.821698]},
        "properties": {
            "id": "stn_kamarkundu_junction",
            "name": "Kamarkundu Junction",
            "name_bn": "কামারকুণ্ডু জংশন",
            "code": "KQU",
            "kind": "rail",
            "lat": 22.821698,
            "lon": 88.204736,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord", "Sheoraphuli-Tarakeswar Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_madhusudanpur",
        "geometry": {"type": "Point", "coordinates": [88.193499, 22.845108]},
        "properties": {
            "id": "stn_madhusudanpur",
            "name": "Madhusudanpur",
            "name_bn": "মধুসূদনপুর",
            "code": "MDSE",
            "kind": "rail",
            "lat": 22.845108,
            "lon": 88.193499,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_chandanpur",
        "geometry": {"type": "Point", "coordinates": [88.176177, 22.8813]},
        "properties": {
            "id": "stn_chandanpur",
            "name": "Chandanpur",
            "name_bn": "চন্দনপুর",
            "code": "CDAE",
            "kind": "rail",
            "lat": 22.8813,
            "lon": 88.176177,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_porabazar",
        "geometry": {"type": "Point", "coordinates": [88.15914, 22.916427]},
        "properties": {
            "id": "stn_porabazar",
            "name": "Porabazar",
            "name_bn": "পোড়াবাজার",
            "code": "PBZ",
            "kind": "rail",
            "lat": 22.916427,
            "lon": 88.15914,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_belmuri",
        "geometry": {"type": "Point", "coordinates": [88.152331, 22.932727]},
        "properties": {
            "id": "stn_belmuri",
            "name": "Belmuri",
            "name_bn": "বেলমুড়ি",
            "code": "BMAE",
            "kind": "rail",
            "lat": 22.932727,
            "lon": 88.152331,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_dhaniakhali_halt",
        "geometry": {"type": "Point", "coordinates": [88.143651, 22.95019]},
        "properties": {
            "id": "stn_dhaniakhali_halt",
            "name": "Dhaniakhali Halt",
            "name_bn": "ধনিয়াখালি হল্ট",
            "code": "DNHL",
            "kind": "rail",
            "lat": 22.95019,
            "lon": 88.143651,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_sibaichandi",
        "geometry": {"type": "Point", "coordinates": [88.13369, 22.974465]},
        "properties": {
            "id": "stn_sibaichandi",
            "name": "Sibaichandi",
            "name_bn": "শিবাইচণ্ডী",
            "code": "SHBC",
            "kind": "rail",
            "lat": 22.974465,
            "lon": 88.13369,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_hajigarh",
        "geometry": {"type": "Point", "coordinates": [88.121403, 23.007032]},
        "properties": {
            "id": "stn_hajigarh",
            "name": "Hajigarh",
            "name_bn": "হাজিগড়",
            "code": "HIH",
            "kind": "rail",
            "lat": 23.007032,
            "lon": 88.121403,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_gurap",
        "geometry": {"type": "Point", "coordinates": [88.112282, 23.02534]},
        "properties": {
            "id": "stn_gurap",
            "name": "Gurap",
            "name_bn": "গুড়াপ",
            "code": "GRAE",
            "kind": "rail",
            "lat": 23.02534,
            "lon": 88.112282,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_jhapandanga",
        "geometry": {"type": "Point", "coordinates": [88.091187, 23.064129]},
        "properties": {
            "id": "stn_jhapandanga",
            "name": "Jhapandanga",
            "name_bn": "ঝাপানডাঙ্গা",
            "code": "JPQ",
            "kind": "rail",
            "lat": 23.064129,
            "lon": 88.091187,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_jaugram",
        "geometry": {"type": "Point", "coordinates": [88.080887, 23.078737]},
        "properties": {
            "id": "stn_jaugram",
            "name": "Jaugram",
            "name_bn": "জৌগ্রাম",
            "code": "JRAE",
            "kind": "rail",
            "lat": 23.078737,
            "lon": 88.080887,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_nabagram",
        "geometry": {"type": "Point", "coordinates": [88.066909, 23.09918]},
        "properties": {
            "id": "stn_nabagram",
            "name": "Nabagram",
            "name_bn": "নবগ্রাম",
            "code": "NBAE",
            "kind": "rail",
            "lat": 23.09918,
            "lon": 88.066909,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_masagram_junction",
        "geometry": {"type": "Point", "coordinates": [88.042129, 23.135782]},
        "properties": {
            "id": "stn_masagram_junction",
            "name": "Masagram Junction",
            "name_bn": "মসাগ্রাম",
            "code": "MSAE",
            "kind": "rail",
            "lat": 23.135782,
            "lon": 88.042129,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord", "Bankura-Damodar Railway"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_chanchai",
        "geometry": {"type": "Point", "coordinates": [88.025521, 23.157905]},
        "properties": {
            "id": "stn_chanchai",
            "name": "Chanchai",
            "name_bn": "চাঁচাই",
            "code": "CHC",
            "kind": "rail",
            "lat": 23.157905,
            "lon": 88.025521,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_palla_road",
        "geometry": {"type": "Point", "coordinates": [88.009121, 23.179393]},
        "properties": {
            "id": "stn_palla_road",
            "name": "Palla Road",
            "name_bn": "পাল্লা রোড",
            "code": "PRAE",
            "kind": "rail",
            "lat": 23.179393,
            "lon": 88.009121,
            "network": "Eastern Railway",
            "lines": ["Howrah-Bardhaman Chord"]
        }
    },
    # --- Bandel-Katwa Line (Bandel Junction to Katwa Junction) ---,
    {
        "type": "Feature",
        "id": "stn_bans_beria",
        "geometry": {"type": "Point", "coordinates": [88.395239, 22.957168]},
        "properties": {
            "id": "stn_bans_beria",
            "name": "Bans Beria",
            "name_bn": "বাঁশবেড়িয়া",
            "code": "BSAE",
            "kind": "rail",
            "lat": 22.957168,
            "lon": 88.395239,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_tribeni",
        "geometry": {"type": "Point", "coordinates": [88.398737, 22.991405]},
        "properties": {
            "id": "stn_tribeni",
            "name": "Tribeni",
            "name_bn": "ত্রিবেণী",
            "code": "TBAE",
            "kind": "rail",
            "lat": 22.991405,
            "lon": 88.398737,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_kuntighat",
        "geometry": {"type": "Point", "coordinates": [88.41305, 23.016351]},
        "properties": {
            "id": "stn_kuntighat",
            "name": "Kuntighat",
            "name_bn": "কুন্তীঘাট",
            "code": "KJU",
            "kind": "rail",
            "lat": 23.016351,
            "lon": 88.41305,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_dumurdaha",
        "geometry": {"type": "Point", "coordinates": [88.432234, 23.039851]},
        "properties": {
            "id": "stn_dumurdaha",
            "name": "Dumurdaha",
            "name_bn": "ডুমুরদহ",
            "code": "DMLE",
            "kind": "rail",
            "lat": 23.039851,
            "lon": 88.432234,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_khamargachhi",
        "geometry": {"type": "Point", "coordinates": [88.444013, 23.053988]},
        "properties": {
            "id": "stn_khamargachhi",
            "name": "Khamargachhi",
            "name_bn": "খামারগাছি",
            "code": "KMAE",
            "kind": "rail",
            "lat": 23.053988,
            "lon": 88.444013,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_jirat",
        "geometry": {"type": "Point", "coordinates": [88.461351, 23.097635]},
        "properties": {
            "id": "stn_jirat",
            "name": "Jirat",
            "name_bn": "জিরাট",
            "code": "JIT",
            "kind": "rail",
            "lat": 23.097635,
            "lon": 88.461351,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_balagarh",
        "geometry": {"type": "Point", "coordinates": [88.452913, 23.122107]},
        "properties": {
            "id": "stn_balagarh",
            "name": "Balagarh",
            "name_bn": "বলাগড়",
            "code": "BGAE",
            "kind": "rail",
            "lat": 23.122107,
            "lon": 88.452913,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_somra_bazar",
        "geometry": {"type": "Point", "coordinates": [88.432895, 23.138525]},
        "properties": {
            "id": "stn_somra_bazar",
            "name": "Somra Bazar",
            "name_bn": "সোমড়া বাজার",
            "code": "SOAE",
            "kind": "rail",
            "lat": 23.138525,
            "lon": 88.432895,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_behula",
        "geometry": {"type": "Point", "coordinates": [88.428691, 23.180586]},
        "properties": {
            "id": "stn_behula",
            "name": "Behula",
            "name_bn": "বেহুলা",
            "code": "BHLA",
            "kind": "rail",
            "lat": 23.180586,
            "lon": 88.428691,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_guptipara",
        "geometry": {"type": "Point", "coordinates": [88.416588, 23.197746]},
        "properties": {
            "id": "stn_guptipara",
            "name": "Guptipara",
            "name_bn": "গুপ্তিপাড়া",
            "code": "GPAE",
            "kind": "rail",
            "lat": 23.197746,
            "lon": 88.416588,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_ambika_kalna",
        "geometry": {"type": "Point", "coordinates": [88.353984, 23.211377]},
        "properties": {
            "id": "stn_ambika_kalna",
            "name": "Ambika Kalna",
            "name_bn": "অম্বিকা কালনা",
            "code": "ABKA",
            "kind": "rail",
            "lat": 23.211377,
            "lon": 88.353984,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_baghnapara",
        "geometry": {"type": "Point", "coordinates": [88.329471, 23.241464]},
        "properties": {
            "id": "stn_baghnapara",
            "name": "Baghnapara",
            "name_bn": "বাঘনাপাড়া",
            "code": "BGRA",
            "kind": "rail",
            "lat": 23.241464,
            "lon": 88.329471,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_dhatrigram",
        "geometry": {"type": "Point", "coordinates": [88.311875, 23.277974]},
        "properties": {
            "id": "stn_dhatrigram",
            "name": "Dhatrigram",
            "name_bn": "ধাত্রীগ্রাম",
            "code": "DTAE",
            "kind": "rail",
            "lat": 23.277974,
            "lon": 88.311875,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_nandaigram_halt",
        "geometry": {"type": "Point", "coordinates": [88.31521, 23.30745]},
        "properties": {
            "id": "stn_nandaigram_halt",
            "name": "Nandaigram Halt",
            "name_bn": "নন্দাইগ্রাম হল্ট",
            "code": "NDIM",
            "kind": "rail",
            "lat": 23.30745,
            "lon": 88.31521,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_samudragarh",
        "geometry": {"type": "Point", "coordinates": [88.324707, 23.335321]},
        "properties": {
            "id": "stn_samudragarh",
            "name": "Samudragarh",
            "name_bn": "সমুদ্রগড়",
            "code": "SMAE",
            "kind": "rail",
            "lat": 23.335321,
            "lon": 88.324707,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_kalinagar",
        "geometry": {"type": "Point", "coordinates": [88.335893, 23.365836]},
        "properties": {
            "id": "stn_kalinagar",
            "name": "Kalinagar",
            "name_bn": "কালীনগর",
            "code": "KLNT",
            "kind": "rail",
            "lat": 23.365836,
            "lon": 88.335893,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_nabadwip_dham",
        "geometry": {"type": "Point", "coordinates": [88.356472, 23.396593]},
        "properties": {
            "id": "stn_nabadwip_dham",
            "name": "Nabadwip Dham",
            "name_bn": "নবদ্বীপ ধাম",
            "code": "NDAE",
            "kind": "rail",
            "lat": 23.396593,
            "lon": 88.356472,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_bishnupriya",
        "geometry": {"type": "Point", "coordinates": [88.355435, 23.414048]},
        "properties": {
            "id": "stn_bishnupriya",
            "name": "Bishnupriya",
            "name_bn": "বিষ্ণুপ্রিয়া হল্ট",
            "code": "VNP",
            "kind": "rail",
            "lat": 23.414048,
            "lon": 88.355435,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_bhandartikuri",
        "geometry": {"type": "Point", "coordinates": [88.329977, 23.43295]},
        "properties": {
            "id": "stn_bhandartikuri",
            "name": "Bhandartikuri",
            "name_bn": "ভান্ডারটিকুরী",
            "code": "BFZ",
            "kind": "rail",
            "lat": 23.43295,
            "lon": 88.329977,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_purbasthali",
        "geometry": {"type": "Point", "coordinates": [88.324642, 23.454329]},
        "properties": {
            "id": "stn_purbasthali",
            "name": "Purbasthali",
            "name_bn": "পূর্বস্থলী",
            "code": "PSAE",
            "kind": "rail",
            "lat": 23.454329,
            "lon": 88.324642,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_mertala_phaleya_halt",
        "geometry": {"type": "Point", "coordinates": [88.320437, 23.480882]},
        "properties": {
            "id": "stn_mertala_phaleya_halt",
            "name": "Mertala Phaleya Halt",
            "name_bn": "মেরতলা ফালেয়া হল্ট",
            "code": "MTFA",
            "kind": "rail",
            "lat": 23.480882,
            "lon": 88.320437,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_lakshmipur",
        "geometry": {"type": "Point", "coordinates": [88.302841, 23.503257]},
        "properties": {
            "id": "stn_lakshmipur",
            "name": "Lakshmipur",
            "name_bn": "লক্ষ্মীপুর",
            "code": "LKX",
            "kind": "rail",
            "lat": 23.503257,
            "lon": 88.302841,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_belerhat",
        "geometry": {"type": "Point", "coordinates": [88.282917, 23.519307]},
        "properties": {
            "id": "stn_belerhat",
            "name": "Belerhat",
            "name_bn": "বেলেরহাট",
            "code": "BQH",
            "kind": "rail",
            "lat": 23.519307,
            "lon": 88.282917,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_patuli",
        "geometry": {"type": "Point", "coordinates": [88.251714, 23.547585]},
        "properties": {
            "id": "stn_patuli",
            "name": "Patuli",
            "name_bn": "পাটুলী",
            "code": "PTAE",
            "kind": "rail",
            "lat": 23.547585,
            "lon": 88.251714,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_agradwip",
        "geometry": {"type": "Point", "coordinates": [88.226117, 23.58096]},
        "properties": {
            "id": "stn_agradwip",
            "name": "Agradwip",
            "name_bn": "অগ্রদ্বীপ",
            "code": "AGAE",
            "kind": "rail",
            "lat": 23.58096,
            "lon": 88.226117,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_sahebtala",
        "geometry": {"type": "Point", "coordinates": [88.200996, 23.591585]},
        "properties": {
            "id": "stn_sahebtala",
            "name": "Sahebtala",
            "name_bn": "সাহেবতলা",
            "code": "SHBA",
            "kind": "rail",
            "lat": 23.591585,
            "lon": 88.200996,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_dainhat",
        "geometry": {"type": "Point", "coordinates": [88.170269, 23.60191]},
        "properties": {
            "id": "stn_dainhat",
            "name": "Dainhat",
            "name_bn": "দাঁইহাট",
            "code": "DHAE",
            "kind": "rail",
            "lat": 23.60191,
            "lon": 88.170269,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line"]
        }
    },
    # --- Barddhaman-Katwa Line (Barddhaman to Katwa Junction) ---,
    {
        "type": "Feature",
        "id": "stn_barddhaman_junction",
        "geometry": {"type": "Point", "coordinates": [87.869995, 23.250041]},
        "properties": {
            "id": "stn_barddhaman_junction",
            "name": "Barddhaman Junction",
            "name_bn": "বর্ধমান জংশন",
            "code": "BWN",
            "kind": "rail",
            "lat": 23.250041,
            "lon": 87.869995,
            "network": "Eastern Railway",
            "lines": ["Howrah Main Line", "Howrah-Bardhaman Chord", "Barddhaman-Katwa Line", "Barddhaman-Asansol Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_katwa_junction",
        "geometry": {"type": "Point", "coordinates": [88.1242, 23.6399]},
        "properties": {
            "id": "stn_katwa_junction",
            "name": "Katwa Junction",
            "name_bn": "কাটোয়া জংশন",
            "code": "KWAE",
            "kind": "rail",
            "lat": 23.6399,
            "lon": 88.1242,
            "network": "Eastern Railway",
            "lines": ["Bandel-Katwa Line", "Barddhaman-Katwa Line", "Katwa-Azimganj Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_karjana",
        "geometry": {"type": "Point", "coordinates": [87.892269, 23.344568]},
        "properties": {
            "id": "stn_karjana",
            "name": "Karjana",
            "name_bn": "করজনা",
            "code": "KJRA",
            "kind": "rail",
            "lat": 23.344568,
            "lon": 87.892269,
            "network": "Eastern Railway",
            "lines": ["Barddhaman-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_bhatar",
        "geometry": {"type": "Point", "coordinates": [87.924831, 23.406376]},
        "properties": {
            "id": "stn_bhatar",
            "name": "Bhatar",
            "name_bn": "ভাতাড়",
            "code": "BTRH",
            "kind": "rail",
            "lat": 23.406376,
            "lon": 87.924831,
            "network": "Eastern Railway",
            "lines": ["Barddhaman-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_amarun",
        "geometry": {"type": "Point", "coordinates": [87.909451, 23.369512]},
        "properties": {
            "id": "stn_amarun",
            "name": "Amarun",
            "name_bn": "আমারুন",
            "code": "ARNB",
            "kind": "rail",
            "lat": 23.369512,
            "lon": 87.909451,
            "network": "Eastern Railway",
            "lines": ["Barddhaman-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_balgona",
        "geometry": {"type": "Point", "coordinates": [87.950456, 23.45805]},
        "properties": {
            "id": "stn_balgona",
            "name": "Balgona",
            "name_bn": "বলগোনা",
            "code": "BGNA",
            "kind": "rail",
            "lat": 23.45805,
            "lon": 87.950456,
            "network": "Eastern Railway",
            "lines": ["Barddhaman-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_saota",
        "geometry": {"type": "Point", "coordinates": [87.977445, 23.48839]},
        "properties": {
            "id": "stn_saota",
            "name": "Saota",
            "name_bn": "সাওতা",
            "code": "SOF",
            "kind": "rail",
            "lat": 23.48839,
            "lon": 87.977445,
            "network": "Eastern Railway",
            "lines": ["Barddhaman-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_nigan",
        "geometry": {"type": "Point", "coordinates": [87.992506, 23.505156]},
        "properties": {
            "id": "stn_nigan",
            "name": "Nigan",
            "name_bn": "নিগান",
            "code": "NGX",
            "kind": "rail",
            "lat": 23.505156,
            "lon": 87.992506,
            "network": "Eastern Railway",
            "lines": ["Barddhaman-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_kaichar_halt",
        "geometry": {"type": "Point", "coordinates": [88.011826, 23.537565]},
        "properties": {
            "id": "stn_kaichar_halt",
            "name": "Kaichar Halt",
            "name_bn": "কৈচর হল্ট",
            "code": "KCY",
            "kind": "rail",
            "lat": 23.537565,
            "lon": 88.011826,
            "network": "Eastern Railway",
            "lines": ["Barddhaman-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_bankapasi",
        "geometry": {"type": "Point", "coordinates": [88.037219, 23.5704]},
        "properties": {
            "id": "stn_bankapasi",
            "name": "Bankapasi",
            "name_bn": "বনকাপাসী",
            "code": "BCF",
            "kind": "rail",
            "lat": 23.5704,
            "lon": 88.037219,
            "network": "Eastern Railway",
            "lines": ["Barddhaman-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_shrikhanda",
        "geometry": {"type": "Point", "coordinates": [88.065333, 23.599504]},
        "properties": {
            "id": "stn_shrikhanda",
            "name": "Shrikhanda",
            "name_bn": "শ্রীখণ্ড",
            "code": "SIZ",
            "kind": "rail",
            "lat": 23.599504,
            "lon": 88.065333,
            "network": "Eastern Railway",
            "lines": ["Barddhaman-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_sripat_shrikhanda",
        "geometry": {"type": "Point", "coordinates": [88.088180, 23.619106]},
        "properties": {
            "id": "stn_sripat_shrikhanda",
            "name": "Sripat Shrikhanda",
            "name_bn": "শ্রীপাট শ্রীখণ্ড",
            "code": "SPS",
            "kind": "rail",
            "lat": 23.619106,
            "lon": 88.088180,
            "network": "Eastern Railway",
            "lines": ["Barddhaman-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_kamnara",
        "geometry": {"type": "Point", "coordinates": [87.880341, 23.299241]},
        "properties": {
            "id": "stn_kamnara",
            "name": "Kamnara",
            "name_bn": "কামরানা",
            "code": "KMRA",
            "kind": "rail",
            "lat": 23.299241,
            "lon": 87.880341,
            "network": "Eastern Railway",
            "lines": ["Barddhaman-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_kshetia",
        "geometry": {"type": "Point", "coordinates": [87.884739, 23.312641]},
        "properties": {
            "id": "stn_kshetia",
            "name": "Kshetia",
            "name_bn": "খেতিয়া",
            "code": "KSHT",
            "kind": "rail",
            "lat": 23.312641,
            "lon": 87.884739,
            "network": "Eastern Railway",
            "lines": ["Barddhaman-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_chamardighi",
        "geometry": {"type": "Point", "coordinates": [87.88989, 23.333685]},
        "properties": {
            "id": "stn_chamardighi",
            "name": "Chamardighi",
            "name_bn": "চামরদিঘী",
            "code": "CMDG",
            "kind": "rail",
            "lat": 23.333685,
            "lon": 87.88989,
            "network": "Eastern Railway",
            "lines": ["Barddhaman-Katwa Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_karjanagram",
        "geometry": {"type": "Point", "coordinates": [87.894094, 23.352835]},
        "properties": {
            "id": "stn_karjanagram",
            "name": "Karjanagram",
            "name_bn": "করজনাগ্রাম",
            "code": "KJRM",
            "kind": "rail",
            "lat": 23.352835,
            "lon": 87.894094,
            "network": "Eastern Railway",
            "lines": ["Barddhaman-Katwa Line"]
        }
    },
    # --- Connecting Links (Naihati-Bandel & Sheoraphuli-Tarakeswar) ---,
    {
        "type": "Feature",
        "id": "stn_garifa",
        "geometry": {"type": "Point", "coordinates": [88.411495, 22.908499]},
        "properties": {
            "id": "stn_garifa",
            "name": "Garifa",
            "name_bn": "গরিফা",
            "code": "GFAE",
            "kind": "rail",
            "lat": 22.908499,
            "lon": 88.411495,
            "network": "Eastern Railway",
            "lines": ["Naihati-Bandel Branch"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_hooghly_ghat",
        "geometry": {"type": "Point", "coordinates": [88.396434, 22.904839]},
        "properties": {
            "id": "stn_hooghly_ghat",
            "name": "Hooghly Ghat",
            "name_bn": "হুগলি ঘাট",
            "code": "HYG",
            "kind": "rail",
            "lat": 22.904839,
            "lon": 88.396434,
            "network": "Eastern Railway",
            "lines": ["Naihati-Bandel Branch"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_diara",
        "geometry": {"type": "Point", "coordinates": [88.281483, 22.798358]},
        "properties": {
            "id": "stn_diara",
            "name": "Diara",
            "name_bn": "দিয়াড়া",
            "code": "DEA",
            "kind": "rail",
            "lat": 22.798358,
            "lon": 88.281483,
            "network": "Eastern Railway",
            "lines": ["Sheoraphuli-Tarakeswar Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_nasibpur",
        "geometry": {"type": "Point", "coordinates": [88.262608, 22.804985]},
        "properties": {
            "id": "stn_nasibpur",
            "name": "Nasibpur",
            "name_bn": "নসিবপুর",
            "code": "NSF",
            "kind": "rail",
            "lat": 22.804985,
            "lon": 88.262608,
            "network": "Eastern Railway",
            "lines": ["Sheoraphuli-Tarakeswar Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_singur",
        "geometry": {"type": "Point", "coordinates": [88.227696, 22.814835]},
        "properties": {
            "id": "stn_singur",
            "name": "Singur",
            "name_bn": "সিঙ্গুর",
            "code": "SIU",
            "kind": "rail",
            "lat": 22.814835,
            "lon": 88.227696,
            "network": "Eastern Railway",
            "lines": ["Sheoraphuli-Tarakeswar Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_nalikul",
        "geometry": {"type": "Point", "coordinates": [88.166773, 22.830301]},
        "properties": {
            "id": "stn_nalikul",
            "name": "Nalikul",
            "name_bn": "নালিকুল",
            "code": "NKL",
            "kind": "rail",
            "lat": 22.830301,
            "lon": 88.166773,
            "network": "Eastern Railway",
            "lines": ["Sheoraphuli-Tarakeswar Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_maliya",
        "geometry": {"type": "Point", "coordinates": [88.135964, 22.831567]},
        "properties": {
            "id": "stn_maliya",
            "name": "Maliya",
            "name_bn": "মালিয়া",
            "code": "MLYA",
            "kind": "rail",
            "lat": 22.831567,
            "lon": 88.135964,
            "network": "Eastern Railway",
            "lines": ["Sheoraphuli-Tarakeswar Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_haripal",
        "geometry": {"type": "Point", "coordinates": [88.119163, 22.831547]},
        "properties": {
            "id": "stn_haripal",
            "name": "Haripal",
            "name_bn": "হরিপাল",
            "code": "HPL",
            "kind": "rail",
            "lat": 22.831547,
            "lon": 88.119163,
            "network": "Eastern Railway",
            "lines": ["Sheoraphuli-Tarakeswar Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_kaikala",
        "geometry": {"type": "Point", "coordinates": [88.091581, 22.840565]},
        "properties": {
            "id": "stn_kaikala",
            "name": "Kaikala",
            "name_bn": "কৈকালা",
            "code": "KKAE",
            "kind": "rail",
            "lat": 22.840565,
            "lon": 88.091581,
            "network": "Eastern Railway",
            "lines": ["Sheoraphuli-Tarakeswar Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_bahirkhanda",
        "geometry": {"type": "Point", "coordinates": [88.069119, 22.852647]},
        "properties": {
            "id": "stn_bahirkhanda",
            "name": "Bahirkhanda",
            "name_bn": "বাহিরখণ্ড",
            "code": "BAHW",
            "kind": "rail",
            "lat": 22.852647,
            "lon": 88.069119,
            "network": "Eastern Railway",
            "lines": ["Sheoraphuli-Tarakeswar Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_loknath",
        "geometry": {"type": "Point", "coordinates": [88.034151, 22.871608]},
        "properties": {
            "id": "stn_loknath",
            "name": "Loknath",
            "name_bn": "লোকনাথ",
            "code": "LOK",
            "kind": "rail",
            "lat": 22.871608,
            "lon": 88.034151,
            "network": "Eastern Railway",
            "lines": ["Sheoraphuli-Tarakeswar Line"]
        }
    },
    {
        "type": "Feature",
        "id": "stn_tarakeswar",
        "geometry": {"type": "Point", "coordinates": [88.014213, 22.882403]},
        "properties": {
            "id": "stn_tarakeswar",
            "name": "Tarakeswar",
            "name_bn": "তারকেশ্বর",
            "code": "TAK",
            "kind": "rail",
            "lat": 22.882403,
            "lon": 88.014213,
            "network": "Eastern Railway",
            "lines": ["Sheoraphuli-Tarakeswar Line"]
        }
    }
]
