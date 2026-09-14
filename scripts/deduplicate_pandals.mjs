import fs from 'fs';

// Read original pandals
const originalPandals = JSON.parse(fs.readFileSync('app/assets/data/pandals.json', 'utf8'));
console.log('Original pandal count:', originalPandals.length);

// Make a safety backup
fs.writeFileSync('app/assets/data/pandals.backup.json', JSON.stringify(originalPandals, null, 2));

// Helper to find pandal by ID or Name
function findById(list, id) {
  return list.find(p => p.id === id);
}

// Map of canonical ID -> merged pandal object
const canonicalMap = new Map();

// Set of IDs to remove / absorb
const idsToAbsorb = new Set([
  'beleghata_33_pally_2',
  'hindustan_club_299',
  'jodhpur_park_292',
  'kankurgachi_mitali_sangha_2',
  'mitali_kankurgachi',
  'kankurgachi_yubak_brinda_2',
  'manoharpukur_youngs_224',
  'nepal_bhattacharjee_street_276',
  'rajdanga_naba_uday_sangha_289',
  '66_pally',
  'badamtala_ashar_sangha',
  'baghbazar_sarbojonin_durgotsav',
  'baghbazar_sarbojonin_durgotsab_exhibition',
  'chetla_agrani_club',
  'ekdalia_evergreen_club',
  'tridhara_sammilani',
  'md_ali_park',
  'muhammad_ali_park',
  'bayan_samity',
  'simla_byayam_samity',
  'kashi_bose_lane_durga_puja_samity',
  'lake_town_adhibasi_brindo_durga_puja_pandal',
  'laketown_adhibasi_brinda',
  'naktala_udayan_sangha_club',
  'naktala_udyan_sangha',
  'santhoshpur_lakepally',
  'trikon_park',
  'selimpur_pally_durga_puja_pandal',
  'sovabazar_rajbarir_durga_pujo',
  'sovabazar_beniatola',
  'bg_block',
  'manicktala_chaltabagan_loha_patty',
  'loha_patti',
  'jagat_mukharjee_park',
  'telenga_bagan',
  'darpanarayan_street',
  'ekush_pally_sarbojanin_durgotsab',
  'khelat_ghose_er_durga_pujo',
  'ramdulal_nibas_er_durga_pujo',
  'samaj_sebi',
  'shree_sangha',
  'labony_estate',
  'babubagan',
  'kumartuli_park',
  'kumortuli_sarbajanin',
  'college_square_sarbojanin_durgotsab_committee'
]);

// Merging definitions:
// Each merge defines:
// - canonicalId
// - absorbIds: [id1, id2, ...]
// - overrides: { field: value }
const mergeConfigs = [
  {
    canonicalId: 'beleghata_33_pally',
    absorbIds: ['beleghata_33_pally_2'],
    overrides: {
      name: 'Beleghata 33 Pally',
      bengaliName: 'বেলেঘাটা ৩৩ পল্লী',
      zone: 'centralKolkata',
      area: 'Beleghata, Central Kolkata',
      description: 'Beleghata 33 Pally is renowned for its elaborate artistic pandals and social themes that reflect Bengali culture and heritage.',
      theme: 'Social & Cultural Theme',
      rating: 4.4,
      nearest_metro: 'Phoolbagan (Green)'
    }
  },
  {
    // Bosepukur Sitala Mandir has 2 entries with the SAME ID bosepukur_sitala_mandir
    canonicalId: 'bosepukur_sitala_mandir',
    absorbIds: [],
    overrides: {
      name: 'Bosepukur Sitala Mandir',
      bengaliName: 'বোসপুকুর শীতলা মন্দির',
      zone: 'southKolkata',
      area: 'Kasba / Bosepukur, South Kolkata',
      lat: 22.516581,
      lng: 88.388023,
      description: 'Bosepukur Sitala Mandir is one of the celebrated Durga Puja celebrations in South Kolkata, known for pioneering unique rural and craft themes using clay and earthen cups.',
      theme: 'Artistic Craft & Rural Heritage',
      rating: 4.6,
      nearest_metro: 'Kalighat (Blue)'
    }
  },
  {
    canonicalId: 'hindustan_club',
    absorbIds: ['hindustan_club_299'],
    overrides: {
      name: 'Hindustan Club',
      bengaliName: 'হিন্দুস্তান ক্লাব',
      zone: 'southKolkata',
      area: 'Gariahat / Ballygunge, South Kolkata',
      lat: 22.520149,
      lng: 88.361259,
      description: 'Hindustan Club is one of the celebrated Durga Puja celebrations in Ballygunge, attracting thousands with elegant lighting and traditional idols.',
      theme: 'Traditional Bengali',
      rating: 4.5
    }
  },
  {
    canonicalId: 'jodhpur_park',
    absorbIds: ['jodhpur_park_292'],
    overrides: {
      name: 'Jodhpur Park',
      bengaliName: 'যোধপুর পার্ক',
      zone: 'southKolkata',
      area: 'Jodhpur Park, South Kolkata',
      lat: 22.5058175,
      lng: 88.3639986,
      description: 'Jodhpur Park is one of the grandest Durga Puja celebrations in South Kolkata, famous for eco-friendly architectural marvels and cutting-edge light craft.',
      theme: 'Contemporary Architecture & Illumination',
      rating: 4.7
    }
  },
  {
    canonicalId: 'kankurgachi_mitali_sangha',
    absorbIds: ['kankurgachi_mitali_sangha_2', 'mitali_kankurgachi'],
    overrides: {
      name: 'Kankurgachi Mitali Sangha',
      bengaliName: 'কাঁকুড়গাছি মিতালী সংঘ',
      zone: 'northKolkata',
      area: 'Kankurgachi / Phoolbagan, North Kolkata',
      lat: 22.580042,
      lng: 88.393974,
      description: 'Kankurgachi Mitali Sangha is a major crowd-puller in North-East Kolkata, renowned for its deeply thoughtful thematic art and majestic idol sculpts.',
      theme: 'Artistic & Social Heritage',
      rating: 4.6,
      nearest_metro: 'Phoolbagan (Green)'
    }
  },
  {
    canonicalId: 'kankurgachi_yubak_brinda',
    absorbIds: ['kankurgachi_yubak_brinda_2'],
    overrides: {
      name: 'Kankurgachi Yubak Brinda',
      bengaliName: 'কাঁকুড়গাছি যুবক বৃন্দ',
      zone: 'northKolkata',
      area: 'Kankurgachi, North Kolkata',
      lat: 22.57939898236481,
      lng: 88.3880997159656,
      description: 'Kankurgachi Yubak Brinda is celebrated for innovative pandal designs that combine traditional devotion with modern creative aesthetics.',
      theme: 'Creative Contemporary',
      rating: 4.4,
      nearest_metro: 'Phoolbagan (Green)'
    }
  },
  {
    canonicalId: 'manoharpukur_youngs',
    absorbIds: ['manoharpukur_youngs_224'],
    overrides: {
      name: 'Manoharpukur Youngs',
      bengaliName: 'মনোহরপুকুর ইয়ংস',
      zone: 'southKolkata',
      area: 'Manoharpukur / Sarat Bose Rd, South Kolkata',
      lat: 22.518682,
      lng: 88.356216, // Correct location on Manoharpukur Rd, fixing Bakul Bagan overlap!
      description: 'Manoharpukur Youngs is one of the celebrated Durga Puja celebrations in South Kolkata, known for soulful traditional pratima and artistic mandap aesthetics.',
      theme: 'Traditional Bengali & Artistic Lighting',
      rating: 4.5
    }
  },
  {
    // Nalin Sarkar Street has 2 entries with SAME ID nalin_sarkar_street
    canonicalId: 'nalin_sarkar_street',
    absorbIds: [],
    overrides: {
      name: 'Nalin Sarkar Street',
      bengaliName: 'নলীন সরকার স্ট্রিট',
      zone: 'northKolkata',
      area: 'Shyambazar / Hatibagan, North Kolkata',
      lat: 22.5953765,
      lng: 88.3731609,
      description: 'Nalin Sarkar Street is one of the celebrated Durga Puja celebrations in Shyambazar, winning multiple accolades for creative sculpture and heritage atmosphere.',
      theme: 'Sculptural Art & Indigenous Heritage',
      rating: 4.6,
      nearest_metro: 'Shyambazar (Blue)'
    }
  },
  {
    canonicalId: 'nepal_bhattacharjee_street',
    absorbIds: ['nepal_bhattacharjee_street_276'],
    overrides: {
      name: 'Nepal Bhattacharjee Street',
      bengaliName: 'নেপাল ভট্টাচার্য স্ট্রিট',
      zone: 'southKolkata',
      area: 'Kalighat / Chetla, South Kolkata',
      lat: 22.5180222,
      lng: 88.3426217,
      description: 'Nepal Bhattacharjee Street Club is celebrated for authentic neighborhood Durga Puja spirit, innovative craftwork, and classic clay idols.',
      theme: 'Traditional Bengali & Eco-Friendly Art',
      rating: 4.5,
      nearest_metro: 'Kalighat (Blue)'
    }
  },
  {
    // Pally Mangal Samity has 2 entries with SAME ID pally_mangal_samity
    canonicalId: 'pally_mangal_samity',
    absorbIds: [],
    overrides: {
      name: 'Pally Mangal Samity',
      bengaliName: 'পল্লী মঙ্গল সমিতি',
      zone: 'southKolkata',
      area: 'Gariahat / Jodhpur Park, South Kolkata',
      lat: 22.503017,
      lng: 88.36396,
      description: 'Pally Mangal Samity is one of the celebrated community Durga Pujas in South Kolkata, creating warm festive memories with classic decor.',
      theme: 'Traditional Bengali',
      rating: 4.5
    }
  },
  {
    canonicalId: 'rajdanga_naba_uday_sangha',
    absorbIds: ['rajdanga_naba_uday_sangha_289'],
    overrides: {
      name: 'Rajdanga Naba Uday Sangha',
      bengaliName: 'রাজডাঙ্গা নব উদয় সংঘ',
      zone: 'southKolkata',
      area: 'Kasba / Rajdanga, South Kolkata',
      lat: 22.5166272,
      lng: 88.3902285,
      description: 'Rajdanga Naba Uday Sangha is a premier South Kolkata spectacle known for massive concept pavilions and intricate artistic detailing.',
      theme: 'Artistic Concept & Architectural Splendor',
      rating: 4.7
    }
  },
  {
    canonicalId: '66_palli',
    absorbIds: ['66_pally'],
    overrides: {
      name: '66 Palli',
      bengaliName: '৬৬ পল্লী',
      zone: 'southKolkata',
      area: 'Kalighat, South Kolkata',
      lat: 22.518148,
      lng: 88.342644,
      description: '66 Palli is famous for pathbreaking theme installations and social messages, situated near Kalighat in South Kolkata.',
      theme: 'Concept Theme & Social Message',
      rating: 4.6,
      nearest_metro: 'Kalighat (Blue)'
    }
  },
  {
    canonicalId: 'badamtala',
    absorbIds: ['badamtala_ashar_sangha'],
    overrides: {
      name: 'Badamtala Ashar Sangha',
      bengaliName: 'বাদামতলা আষাঢ় সংঘ',
      zone: 'southKolkata',
      area: 'Kalighat / Rashbehari, South Kolkata',
      lat: 22.51786,
      lng: 88.34399,
      description: 'Badamtala Ashar Sangha is an iconic, multi-award-winning South Kolkata powerhouse celebrated for spectacular conceptual themes and serene, lifelike idols.',
      theme: 'Grand Concept & Master Sculpting',
      rating: 4.7,
      nearest_metro: 'Kalighat (Blue)'
    }
  },
  {
    canonicalId: 'bagbazar_sarbajanin',
    absorbIds: ['baghbazar_sarbojonin_durgotsav', 'baghbazar_sarbojonin_durgotsab_exhibition'],
    overrides: {
      name: 'Bagbazar Sarbajanin',
      bengaliName: 'বাগবাজার সর্বজনীন',
      zone: 'northKolkata',
      area: 'Bagbazar, North Kolkata',
      lat: 22.6046649,
      lng: 88.3659778,
      description: 'Bagbazar Sarbajanin Durgotsav is one of the oldest (over a century) and most prestigious traditional community pujas in Kolkata, famous for classical Ekchala pratima and grand carnival atmosphere on the banks of the Ganges.',
      theme: 'Centuries-Old Traditional Ekchala Sabeki',
      rating: 4.8,
      nearest_metro: 'Shyambazar (Blue)',
      nearest_railway: 'Bagbazar (Circular)'
    }
  },
  {
    canonicalId: 'chetla_agrani',
    absorbIds: ['chetla_agrani_club'],
    overrides: {
      name: 'Chetla Agrani Club',
      bengaliName: 'চেতলা অগ্রণী ক্লাব',
      zone: 'southKolkata',
      area: 'Kalighat / Chetla, South Kolkata',
      lat: 22.51645,
      lng: 88.33715,
      description: 'Chetla Agrani Club is a legendary mega-puja celebrated for monumental structural installations, visionary thematic architecture, and royal illumination.',
      theme: 'Monumental Architectural Theme',
      rating: 4.8,
      nearest_metro: 'Kalighat (Blue)'
    }
  },
  {
    canonicalId: 'ekdalia_evergreen',
    absorbIds: ['ekdalia_evergreen_club'],
    overrides: {
      name: 'Ekdalia Evergreen Club',
      bengaliName: 'একডালিয়া এভারগ্রীন ক্লাব',
      zone: 'southKolkata',
      area: 'Gariahat, South Kolkata',
      lat: 22.52111,
      lng: 88.36645,
      description: 'Ekdalia Evergreen Club is an enduring hallmark of Kolkata Durga Puja, recreating India\'s historic temples with dazzling Chandannagar illumination and a majestic Sabeki pratima.',
      theme: 'Temple Replica & Chandannagar Lighting',
      rating: 4.9,
      nearest_metro: 'Kalighat (Blue)'
    }
  },
  {
    canonicalId: 'tridhara',
    absorbIds: ['tridhara_sammilani'],
    overrides: {
      name: 'Tridhara Sammilani',
      bengaliName: 'ত্রিধারা সম্মিলনী',
      zone: 'southKolkata',
      area: 'Ballygunge / Rashbehari, South Kolkata',
      lat: 22.519238,
      lng: 88.355377,
      description: 'Tridhara Sammilani is a crown jewel of South Kolkata hopping, renowned for mind-bending creative themes, artistic craftsmanship, and immaculate idol artistry.',
      theme: 'Innovative Concept & Artistic Brilliance',
      rating: 4.8,
      nearest_metro: 'Jatin Das Park (Blue)'
    }
  },
  {
    canonicalId: 'mohammed_ali_park',
    absorbIds: ['md_ali_park', 'muhammad_ali_park'],
    overrides: {
      name: 'Mohammed Ali Park',
      bengaliName: 'মহম্মদ আলী পার্ক',
      zone: 'centralKolkata',
      area: 'College Street / MG Road, Central Kolkata',
      lat: 22.57724810401376,
      lng: 88.36072417400061,
      description: 'Mohammed Ali Park is a monumental Central Kolkata puja celebrated for grand replicas of world monuments and forts, reflected across its central reservoir.',
      theme: 'Palatial Replica & Grand Illumination',
      rating: 4.7,
      nearest_metro: 'Mahatma Gandhi Road (Blue)'
    }
  },
  {
    canonicalId: 'simla_byam_samity',
    absorbIds: ['bayan_samity', 'simla_byayam_samity'],
    overrides: {
      name: 'Simla Byam Samity',
      bengaliName: 'শিমলা ব্যায়াম সমিতি',
      zone: 'northKolkata',
      area: 'Simla / Vivekananda Road, North Kolkata',
      lat: 22.5853694,
      lng: 88.3650092,
      description: 'Founded in 1926 by revolutionaries of India\'s independence movement, Simla Byam Samity stands as an historic heritage Sabeki puja with a fearless patriotic soul and traditional warrior goddess.',
      theme: 'Revolutionary Heritage & Veer Sabeki',
      rating: 4.7,
      nearest_metro: 'Girish Park (Blue)'
    }
  },
  {
    canonicalId: 'kasi_bose_lane',
    absorbIds: ['kashi_bose_lane_durga_puja_samity'],
    overrides: {
      name: 'Kashi Bose Lane Durga Puja Samity',
      bengaliName: 'কাশী বোস লেন দুর্গোৎসব সমিতি',
      zone: 'northKolkata',
      area: 'Hatibagan, North Kolkata',
      lat: 22.5908979,
      lng: 88.3689174,
      description: 'Kashi Bose Lane is a titan of North Kolkata Durga Puja, captivating audiences with emotionally profound architectural concepts and hyper-detailed thematic installations.',
      theme: 'Award-Winning Conceptual Architecture',
      rating: 4.8,
      nearest_metro: 'Shyambazar (Blue)'
    }
  },
  {
    canonicalId: 'lake_town_adibashi_brinda',
    absorbIds: ['lake_town_adhibasi_brindo_durga_puja_pandal', 'laketown_adhibasi_brinda'],
    overrides: {
      name: 'Lake Town Adibashi Brinda',
      bengaliName: 'লেক টাউন আদিবাসী বৃন্দ',
      zone: 'northKolkata',
      area: 'Lake Town, North Kolkata',
      lat: 22.6044899963704,
      lng: 88.4039660357379,
      description: 'Lake Town Adibashi Brinda is one of the premier community attractions in North Kolkata, renowned for grand visual spectacles, artisanal craftwork, and soulful idol crafting.',
      theme: 'Artistic Grandeur & Cultural Expression',
      rating: 4.6
    }
  },
  {
    canonicalId: 'naktala_udayan_sangha',
    absorbIds: ['naktala_udayan_sangha_club', 'naktala_udyan_sangha'],
    overrides: {
      name: 'Naktala Udayan Sangha',
      bengaliName: 'নাকতলা উদয়ন সংঘ',
      zone: 'southKolkata',
      area: 'Naktala / Garia, South Kolkata',
      lat: 22.474174,
      lng: 88.36705,
      description: 'Naktala Udayan Sangha is universally acclaimed as one of Kolkata\'s most innovative mega-themes, redefining pandal artistry with futuristic and metaphysical concepts.',
      theme: 'Pioneering Contemporary Art & Philosophy',
      rating: 4.8,
      nearest_metro: 'Gitanjali (Blue)'
    }
  },
  {
    canonicalId: 'santoshpur_lake_pally',
    absorbIds: ['santhoshpur_lakepally'],
    overrides: {
      name: 'Santoshpur Lake Pally',
      bengaliName: 'সন্তোষপুর লেক পল্লী',
      zone: 'southKolkata',
      area: 'Santoshpur / Jadavpur, South Kolkata',
      lat: 22.491508,
      lng: 88.382774,
      description: 'Santoshpur Lake Pally is famous across Bengal for transforming indigenous raw materials into world-class contemporary art installations.',
      theme: 'Master Craft & Material Innovation',
      rating: 4.7
    }
  },
  {
    canonicalId: 'santoshpur_trikon_park',
    absorbIds: ['trikon_park'],
    overrides: {
      name: 'Santoshpur Trikon Park',
      bengaliName: 'সন্তোষপুর ত্রিকোণ পার্ক',
      zone: 'southKolkata',
      area: 'Santoshpur, South Kolkata',
      lat: 22.492996,
      lng: 88.378448,
      description: 'Santoshpur Trikon Park is renowned for peaceful artistic ambience, creative traditional pandals, and community festivities.',
      theme: 'Artistic Traditional',
      rating: 4.5
    }
  },
  {
    canonicalId: 'selimpur_pally',
    absorbIds: ['selimpur_pally_durga_puja_pandal'],
    overrides: {
      name: 'Selimpur Pally',
      bengaliName: 'সেলিমপুর পল্লী',
      zone: 'southKolkata',
      area: 'Dhakuria / Selimpur, South Kolkata',
      lat: 22.505087,
      lng: 88.368149,
      description: 'Selimpur Pally is a powerhouse in the Dhakuria circuit, celebrated for experiential installations, atmospheric lighting, and touching social themes.',
      theme: 'Experiential Installation & Art',
      rating: 4.7
    }
  },
  {
    canonicalId: 'sovabazar_rajbari',
    absorbIds: ['sovabazar_rajbarir_durga_pujo'],
    overrides: {
      name: 'Sovabazar Rajbari',
      bengaliName: 'শোভাবাজার রাজবাড়ি',
      zone: 'northKolkata',
      area: 'Sovabazar, North Kolkata',
      lat: 22.596798,
      lng: 88.367233,
      description: 'Founded in 1757 by Raja Nabakrishna Deb, the Shobhabazar Rajbari Bonedi puja is the historical pinnacle of Kolkata Durga Puja, held in the iconic open Natmandir with heritage rituals and classical Ekchala pratima.',
      theme: 'Centuries-Old Bonedi Bari Heritage (1757)',
      rating: 4.9,
      nearest_metro: 'Sovabazar Sutanuti (Blue)'
    }
  },
  {
    canonicalId: 'beniatola',
    absorbIds: ['sovabazar_beniatola'],
    overrides: {
      name: 'Beniatola Sarbojanin',
      bengaliName: 'বেনিয়াটোলা সর্বজনীন',
      zone: 'northKolkata',
      area: 'Sovabazar / Beniatola, North Kolkata',
      lat: 22.59592,
      lng: 88.36091,
      description: 'Beniatola Sarbojanin is a celebrated heritage community puja in North Kolkata, noted for deep artistic roots, folk aesthetics, and authentic warm hospitality.',
      theme: 'Traditional Folk & Heritage Art',
      rating: 4.6,
      nearest_metro: 'Sovabazar Sutanuti (Blue)'
    }
  },
  {
    canonicalId: 'salt_lake_bg_block',
    absorbIds: ['bg_block'],
    overrides: {
      name: 'Salt Lake BG Block',
      bengaliName: 'সল্টলেক বি জি ব্লক',
      zone: 'eastKolkata',
      area: 'Sector 2, Salt Lake',
      lat: 22.59545,
      lng: 88.42312,
      description: 'Salt Lake BG Block is celebrated for its spacious thematic grounds, vibrant community cultural programs, and elegant pandal architecture.',
      theme: 'Contemporary Cultural Theme',
      rating: 4.5
    }
  },
  {
    canonicalId: 'chaltabagan',
    absorbIds: ['manicktala_chaltabagan_loha_patty', 'loha_patti'],
    overrides: {
      name: 'Manicktala Chaltabagan Loha Patty',
      bengaliName: 'মানিকতলা চালতাবাগান লোহাপট্টি',
      zone: 'northKolkata',
      area: 'Manicktala, North Kolkata',
      lat: 22.58489,
      lng: 88.37209,
      description: 'Manicktala Chaltabagan is one of Kolkata\'s most famous pujas, celebrated for the lively Dhunuchi Naach, glass and brass craftwork, and dazzling illumination.',
      theme: 'Dhunuchi Heritage & Craft Grandeur',
      rating: 4.8,
      nearest_metro: 'Girish Park (Blue)'
    }
  },
  {
    canonicalId: 'jagat_mukherjee_park',
    absorbIds: ['jagat_mukharjee_park'],
    overrides: {
      name: 'Jagat Mukherjee Park',
      bengaliName: 'জগৎ মুখার্জী পার্ক',
      zone: 'northKolkata',
      area: 'Shyambazar, North Kolkata',
      lat: 22.599777,
      lng: 88.36615,
      description: 'Jagat Mukherjee Park is a staple of the North Kolkata trail, acclaimed for intricate miniature craft, moving water installations, and serene idol artistry.',
      theme: 'Artistic Miniature & Kinetic Craft',
      rating: 4.6,
      nearest_metro: 'Shyambazar (Blue)'
    }
  },
  {
    canonicalId: 'telengabagan',
    absorbIds: ['telenga_bagan'],
    overrides: {
      name: 'Telengabagan',
      bengaliName: 'তেলেঙ্গাবাগান',
      zone: 'northKolkata',
      area: 'Ultadanga, North Kolkata',
      lat: 22.59492,
      lng: 88.38540,
      description: 'Telengabagan Sarbojanin in Ultadanga is a trailblazer in thematic pandal art, known for pioneering thought-provoking environmental and cultural installations.',
      theme: 'Social Thought & Conceptual Art',
      rating: 4.7
    }
  },
  {
    canonicalId: 'darpanarayan_tagore_street_pally_samity',
    absorbIds: ['darpanarayan_street'],
    overrides: {
      name: 'Darpanarayan Tagore Street Pally Samity',
      bengaliName: 'দর্পনারায়ণ ঠাকুর স্ট্রিট পল্লী সমিতি',
      zone: 'northKolkata',
      area: 'Pathuriaghata, North Kolkata',
      lat: 22.587505,
      lng: 88.354111,
      description: 'A deeply historic community puja nestled in the historic lanes of Old North Kolkata, retaining vintage aristocratic charm and traditional festivities.',
      theme: 'Vintage Heritage & Traditional Sabeki',
      rating: 4.5
    }
  },
  {
    canonicalId: 'ballygunge_21_pally',
    absorbIds: ['ekush_pally_sarbojanin_durgotsab'],
    overrides: {
      name: 'Ballygunge 21 Pally',
      bengaliName: 'বালিগঞ্জ ২১ পল্লী',
      zone: 'southKolkata',
      area: 'Ballygunge, South Kolkata',
      lat: 22.529325,
      lng: 88.369217,
      description: 'Ballygunge 21 Pally (Ekush Pally) creates captivating aesthetic pavilions reflecting Bengal\'s deep artistic traditions and contemporary expressions.',
      theme: 'Artistic Craft & Community Heritage',
      rating: 4.6
    }
  },
  {
    canonicalId: 'khelat_chandra_ghosh_bari_pujo',
    absorbIds: ['khelat_ghose_er_durga_pujo'],
    overrides: {
      name: 'Khelat Chandra Ghosh Bari Pujo',
      bengaliName: 'খেলাত চন্দ্র ঘোষ বাড়ি পুজো',
      zone: 'northKolkata',
      area: 'Pathuriaghata, North Kolkata',
      lat: 22.5887689,
      lng: 88.3565391,
      description: 'One of the grandest Bonedi baris of North Kolkata, Khelat Ghosh Bari features a majestic marble courtyard and 85-foot long grand thakur-dalan where Durga Puja has been celebrated since 1846.',
      theme: 'Aristocratic Bonedi Heritage (1846)',
      rating: 4.8,
      nearest_metro: 'Girish Park (Blue)'
    }
  },
  {
    canonicalId: 'chatu_babu_latu_babus_thakur_bari',
    absorbIds: ['ramdulal_nibas_er_durga_pujo'],
    overrides: {
      name: 'Chatu Babu & Latu Babu\'s Thakur Bari',
      bengaliName: 'ছাতু বাবু ও লাটু বাবুর ঠাকুর বাড়ি',
      zone: 'northKolkata',
      area: 'Beadon Street, North Kolkata',
      lat: 22.5903828059963,
      lng: 88.36437047116512,
      description: 'Started in 1770 by merchant prince Ramdulal De (Deb) and carried on by his illustrious sons Chatu Babu and Latu Babu, this bonedi puja features the rare iconographic detail of Jaya and Bijaya flanking the goddess.',
      theme: 'Centuries-Old Bonedi Bari Heritage (1770)',
      rating: 4.9,
      nearest_metro: 'Girish Park (Blue)'
    }
  },
  {
    canonicalId: 'samaj_sebi_sangha',
    absorbIds: ['samaj_sebi'],
    overrides: {
      name: 'Samaj Sebi Sangha',
      bengaliName: 'সমাজ সেবী সংঘ',
      zone: 'southKolkata',
      area: 'Lake View Road / Ballygunge, South Kolkata',
      lat: 22.51559,
      lng: 88.35772,
      description: 'Samaj Sebi Sangha is celebrated throughout the city for touching humanitarian themes, inclusive pandal designs (such as tactile paths for visually impaired), and peaceful artistry.',
      theme: 'Social Consciousness & Inclusive Art',
      rating: 4.8,
      nearest_metro: 'Kalighat (Blue)'
    }
  },
  {
    canonicalId: 'behala_sree_sangha',
    absorbIds: ['shree_sangha'],
    overrides: {
      name: 'Behala Sree Sangha',
      bengaliName: 'বেহালা শ্রী সংঘ',
      zone: 'southKolkata',
      area: 'Behala, South Kolkata',
      lat: 22.49658,
      lng: 88.31422,
      description: 'Behala Sree Sangha is a major highlight of the South-West Kolkata trail, famed for vast architectural thematic replicas and warm neighborhood community bonding.',
      theme: 'Grand Architecture & Community Festivity',
      rating: 4.6
    }
  },
  {
    canonicalId: 'salt_lake_laboni',
    absorbIds: ['labony_estate'],
    overrides: {
      name: 'Salt Lake Laboni',
      bengaliName: 'সল্টলেক লাবণী',
      zone: 'eastKolkata',
      area: 'Sector 1, Salt Lake',
      lat: 22.59124,
      lng: 88.40956,
      description: 'Laboni Estate in Salt Lake is renowned for peaceful family atmosphere, vibrant cultural soirees, and creative contemporary community pandals.',
      theme: 'Contemporary Community Art',
      rating: 4.5
    }
  },
  {
    canonicalId: 'babubagan_club',
    absorbIds: ['babubagan'],
    overrides: {
      name: 'Babubagan Club',
      bengaliName: 'বাবুবাগান ক্লাব',
      zone: 'southKolkata',
      area: 'Dhakuria, South Kolkata',
      lat: 22.50799,
      lng: 88.36852,
      description: 'Babubagan Club in Dhakuria is famed for breathtaking thematic mandaps inspired by historic temple architecture and commemorative art coins.',
      theme: 'Heritage Architecture & Commemorative Art',
      rating: 4.8,
      nearest_metro: 'Kalighat (Blue)'
    }
  },
  {
    canonicalId: 'kumortuli_park_sarbojanin',
    absorbIds: ['kumartuli_park'],
    overrides: {
      name: 'Kumartuli Park Sarbojanin',
      bengaliName: 'কুমোরটুলি পার্ক সর্বজনীন',
      zone: 'northKolkata',
      area: 'Sovabazar / Kumartuli, North Kolkata',
      lat: 22.598995,
      lng: 88.361366,
      description: 'Kumartuli Park Sarbojanin is a premier attraction of North Kolkata, fusing classical clay craftsmanship from local potters with cutting-edge conceptual design and grand scale.',
      theme: 'Clay Craftsmanship & Majestic Pavilion',
      rating: 4.8,
      nearest_metro: 'Sovabazar Sutanuti (Blue)'
    }
  },
  {
    canonicalId: 'kumartuli_sarbojanin',
    absorbIds: ['kumortuli_sarbajanin'],
    overrides: {
      name: 'Kumartuli Sarbojanin Durgotsav',
      bengaliName: 'কুমোরটুলি সর্বজনীন দুর্গোৎসব',
      zone: 'northKolkata',
      area: 'Kumartuli, North Kolkata',
      lat: 22.600859,
      lng: 88.363274,
      description: 'Founded in 1931 right in the heart of Kolkata\'s legendary idol-makers\' colony, Kumartuli Sarbojanin is steeped in living history with pure traditional sabeki idols created by master sculptors.',
      theme: 'Artisanal Heritage Sabeki (1931)',
      rating: 4.8,
      nearest_metro: 'Sovabazar Sutanuti (Blue)'
    }
  },
  {
    canonicalId: 'college_square',
    absorbIds: ['college_square_sarbojanin_durgotsab_committee'],
    overrides: {
      name: 'College Square Sarbojanin Durgotsab',
      bengaliName: 'কলেজ স্কোয়ার সর্বজনীন দুর্গোৎসব',
      zone: 'centralKolkata',
      area: 'College Street, Central Kolkata',
      lat: 22.574865,
      lng: 88.364578,
      description: 'College Square is an unforgettable Kolkata institution, famous for sprawling temple and palace replicas illuminated with hundreds of thousands of lights reflected in the historic swimming pool tank.',
      theme: 'Illuminated Palace on Water',
      rating: 4.9,
      nearest_metro: 'Central (Blue)'
    }
  }
];

// Execute Deduplication
const finalPandals = [];
const seenIds = new Set();

// First index merge configs by canonicalId
const mergeMap = new Map(mergeConfigs.map(c => [c.canonicalId, c]));

for (const p of originalPandals) {
  // If this pandal is absorbed into a canonical one, skip it
  if (idsToAbsorb.has(p.id)) {
    console.log(`Absorbing and removing duplicate ID: ${p.id} (${p.name})`);
    continue;
  }

  // If this pandal is in mergeMap
  if (mergeMap.has(p.id)) {
    // Check if we already processed this canonical ID (for duplicate identical IDs like bosepukur_sitala_mandir)
    if (seenIds.has(p.id)) {
      console.log(`Removing second identical copy of ID: ${p.id} (${p.name})`);
      continue;
    }

    const cfg = mergeMap.get(p.id);
    const merged = { ...p, ...cfg.overrides };
    finalPandals.push(merged);
    seenIds.add(p.id);
    console.log(`Merged and enriched canonical: ${p.id} -> "${merged.name}" [${merged.zone}]`);
    continue;
  }

  // Check if somehow seen before
  if (seenIds.has(p.id)) {
    console.log(`Warning: Unexpected duplicate ID ${p.id} (${p.name}), skipping duplicate copy.`);
    continue;
  }

  finalPandals.push(p);
  seenIds.add(p.id);
}

console.log(`\nFinal unique pandal count: ${finalPandals.length} (reduced from ${originalPandals.length})`);
fs.writeFileSync('app/assets/data/pandals.json', JSON.stringify(finalPandals, null, 2));
console.log('Saved deduplicated pandals to app/assets/data/pandals.json');
