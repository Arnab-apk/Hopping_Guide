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
        "geometry": {"type": "Point", "coordinates": [88.4239, 22.8953]},
        "properties": {
            "id": "stn_naihati",
            "name": "Naihati Junction",
            "name_bn": "নৈহাটি জংশন",
            "code": "NH",
            "kind": "rail",
            "lat": 22.8953,
            "lon": 88.4239,
            "network": "Eastern Railway",
            "lines": ["Sealdah Main", "Bandel Branch"]
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
        "id": "stn_garia",
        "geometry": {"type": "Point", "coordinates": [88.3842, 22.4705]},
        "properties": {
            "id": "stn_garia",
            "name": "Garia",
            "name_bn": "গড়িয়া",
            "code": "GIA",
            "kind": "rail",
            "lat": 22.4705,
            "lon": 88.3842,
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
            "name": "Mahanayak Uttam Kumar (Tollygunge) Metro",
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
            "name": "Kavi Nazrul (Garia Bazar) Metro",
            "name_bn": "কাজী নজরুল ইসলাম মেট্রো",
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
            "name": "Kavi Subhash (New Garia) Metro",
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
    }
]
