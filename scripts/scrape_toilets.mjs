// scripts/scrape_toilets.mjs
// Fetches nearest public toilets (male & female) for every Kolkata Durga Puja pandal
// Sources: OpenStreetMap Overpass API + Kolkata Metro Station toilet facilities + KMC/Sulabh public toilet hubs.
// Output: ../data/toilets.json and ../app/assets/data/toilets.json

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PANDALS_DATA_JSON   = path.resolve(__dirname, '../data/pandals.json');
const PANDALS_ASSET_JSON  = path.resolve(__dirname, '../app/assets/data/pandals.json');
const OUT_DATA            = path.resolve(__dirname, '../data/toilets.json');
const OUT_ASSET           = path.resolve(__dirname, '../app/assets/data/toilets.json');

// Haversine distance in meters
function haversineMeters(lat1, lng1, lat2, lng2) {
  const R = 6371000;
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat / 2) ** 2 +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLng / 2) ** 2;
  return R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

// 1. Fetch from OpenStreetMap Overpass API
// Helper to check if a lat, lng point falls inside the Hooghly river corridor
function isPointInHooghlyRiver(lat, lng) {
  if (lat >= 22.645 && lat <= 22.665 && lng >= 88.354 && lng <= 88.361) return true;
  if (lat >= 22.615 && lat < 22.645 && lng >= 88.353 && lng <= 88.365) return true;
  if (lat >= 22.595 && lat < 22.615 && lng >= 88.353 && lng <= 88.3635) return true;
  if (lat >= 22.578 && lat < 22.595 && lng >= 88.3426 && lng <= 88.356) return true;
  if (lat >= 22.568 && lat < 22.578 && lng >= 88.337 && lng <= 88.345) return true;
  if (lat >= 22.558 && lat < 22.568 && lng >= 88.333 && lng <= 88.3425) return true;
  if (lat >= 22.545 && lat < 22.558 && lng >= 88.324 && lng <= 88.335) return true;
  if (lat >= 22.525 && lat < 22.545 && lng >= 88.305 && lng <= 88.325) return true;
  return false;
}

const INVALID_TOILET_IDS = new Set([
  'osm_12133871280', // Misplaced node directly in Hooghly river waters
]);

// 1. Fetch from OpenStreetMap Overpass API
async function fetchOsmToilets() {
  const query = `
    [out:json][timeout:15];
    (
      node["amenity"="toilets"](22.35,88.20,22.75,88.55);
      way["amenity"="toilets"](22.35,88.20,22.75,88.55);
    );
    out center tags;
  `;

  const endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
    'https://maps.mail.ru/osm/tools/overpass/api/interpreter'
  ];

  for (const url of endpoints) {
    try {
      console.log(`Querying OSM Overpass API at ${url}...`);
      const res = await fetch(url, {
        method: 'POST',
        signal: AbortSignal.timeout(10000),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'User-Agent': 'KolkataPujaGuide/1.0 (https://github.com/arnab/puja_proj)'
        },
        body: `data=${encodeURIComponent(query)}`
      });

      if (!res.ok) continue;
      const data = await res.json();
      if (!data.elements) continue;

      const toilets = data.elements.map(el => {
        const lat = el.lat ?? el.center?.lat;
        const lng = el.lon ?? el.center?.lon;
        const tags = el.tags || {};
        return {
          id: `osm_${el.id}`,
          lat,
          lng,
          name: tags.name || tags['name:en'] || (tags.operator ? `${tags.operator} Public Toilet` : 'Public Toilet'),
          male: tags.male !== 'no',
          female: tags.female !== 'no',
          fee: tags.fee === 'yes',
          access: tags.access || 'public',
          source: 'osm'
        };
      }).filter(t => t.lat && t.lng && !INVALID_TOILET_IDS.has(t.id) && !isPointInHooghlyRiver(t.lat, t.lng));

      console.log(`→ Successfully fetched ${toilets.length} toilets from OSM!`);
      return toilets;
    } catch (e) {
      console.warn(`Failed with ${url}: ${e.message}`);
    }
  }

  console.warn('Overpass API unreachable; falling back to cached valid OSM toilets from existing dataset...');
  try {
    const sourceFile = fs.existsSync(OUT_ASSET) ? OUT_ASSET : (fs.existsSync(OUT_DATA) ? OUT_DATA : null);
    if (sourceFile) {
      const existing = JSON.parse(fs.readFileSync(sourceFile, 'utf8'));
      const osmMap = new Map();
      for (const p of existing) {
        const list = [p.nearestMale, p.nearestFemale, ...(p.allNearby || [])].filter(Boolean);
        for (const t of list) {
          if (t.source === 'osm' && !osmMap.has(t.id) && !INVALID_TOILET_IDS.has(t.id) && !isPointInHooghlyRiver(t.lat, t.lng)) {
            osmMap.set(t.id, t);
          }
        }
      }
      const cached = Array.from(osmMap.values());
      if (cached.length > 0) {
        console.log(`→ Successfully recovered ${cached.length} valid OSM toilets from cache!`);
        return cached;
      }
    }
  } catch (e) {
    console.warn('Fallback error:', e.message);
  }

  return [];
}

// 2. Curated Kolkata Metro Station Public Toilets
// Every Kolkata Metro station is equipped with separate Male & Female public toilet facilities.
const metroToilets = [
  // Line 1: Blue Line
  { id: 'metro_dakshineswar', name: 'Dakshineswar Metro Station Public Toilet', lat: 22.6540, lng: 88.3638 },
  { id: 'metro_baranagar', name: 'Baranagar Metro Station Public Toilet', lat: 22.6416, lng: 88.3697 },
  { id: 'metro_noapara', name: 'Noapara Metro Station Public Toilet', lat: 22.6375, lng: 88.3847 },
  { id: 'metro_dumdum', name: 'Dum Dum Metro Station Public Toilet', lat: 22.6217, lng: 88.3789 },
  { id: 'metro_belgachia', name: 'Belgachia Metro Station Public Toilet', lat: 22.6049, lng: 88.3813 },
  { id: 'metro_shyambazar', name: 'Shyambazar Metro Station Public Toilet', lat: 22.5997, lng: 88.3712 },
  { id: 'metro_shobhabazar', name: 'Shobhabazar Sutanuti Metro Public Toilet', lat: 22.5975, lng: 88.3664 },
  { id: 'metro_girishpark', name: 'Girish Park Metro Station Public Toilet', lat: 22.5855, lng: 88.3607 },
  { id: 'metro_mgroad', name: 'MG Road Metro Station Public Toilet', lat: 22.5806, lng: 88.3605 },
  { id: 'metro_central', name: 'Central Metro Station Public Toilet', lat: 22.5694, lng: 88.3589 },
  { id: 'metro_chandnichowk', name: 'Chandni Chowk Metro Public Toilet', lat: 22.5653, lng: 88.3568 },
  { id: 'metro_esplanade', name: 'Esplanade Metro Interchange Public Toilet', lat: 22.5645, lng: 88.3516 },
  { id: 'metro_parkstreet', name: 'Park Street Metro Station Public Toilet', lat: 22.5516, lng: 88.3514 },
  { id: 'metro_maidan', name: 'Maidan Metro Station Public Toilet', lat: 22.5451, lng: 88.3496 },
  { id: 'metro_rabindrasadan', name: 'Rabindra Sadan Metro Public Toilet', lat: 22.5375, lng: 88.3475 },
  { id: 'metro_netajibhavan', name: 'Netaji Bhavan Metro Public Toilet', lat: 22.5312, lng: 88.3468 },
  { id: 'metro_jatindaspark', name: 'Jatin Das Park Metro Public Toilet', lat: 22.5234, lng: 88.3462 },
  { id: 'metro_kalighat', name: 'Kalighat Metro Station Public Toilet', lat: 22.5186, lng: 88.3458 },
  { id: 'metro_rabindrasarobar', name: 'Rabindra Sarobar Metro Public Toilet', lat: 22.5085, lng: 88.3454 },
  { id: 'metro_mahanayakuttam', name: 'Mahanayak Uttam Kumar (Tollygunge) Metro Public Toilet', lat: 22.4998, lng: 88.3449 },
  { id: 'metro_netaji', name: 'Netaji (Kudghat) Metro Public Toilet', lat: 22.4896, lng: 88.3454 },
  { id: 'metro_masterdasuryasen', name: 'Masterda Surya Sen (Bansdroni) Metro Public Toilet', lat: 22.4795, lng: 88.3541 },
  { id: 'metro_gitanjali', name: 'Gitanjali (Naktala) Metro Public Toilet', lat: 22.4715, lng: 88.3642 },
  { id: 'metro_kavinazrul', name: 'Kavi Nazrul (Garia Bazar) Metro Public Toilet', lat: 22.4646, lng: 88.3756 },
  { id: 'metro_shahidkhudiram', name: 'Shahid Khudiram (Birji) Metro Public Toilet', lat: 22.4632, lng: 88.3888 },
  { id: 'metro_kavisubhash', name: 'Kavi Subhash (New Garia) Metro Public Toilet', lat: 22.4665, lng: 88.3986 },

  // Line 2: Green Line (East-West)
  { id: 'metro_howrahmaidan', name: 'Howrah Maidan Metro Public Toilet', lat: 22.5843, lng: 88.3286 },
  { id: 'metro_howrah', name: 'Howrah Railway Station Metro Public Toilet', lat: 22.5845, lng: 88.3406 },
  { id: 'metro_mahakaran', name: 'Mahakaran (BBD Bagh) Metro Public Toilet', lat: 22.5714, lng: 88.3468 },
  { id: 'metro_sealdah', name: 'Sealdah Metro Station Public Toilet', lat: 22.5672, lng: 88.3714 },
  { id: 'metro_phoolbagan', name: 'Phoolbagan Metro Station Public Toilet', lat: 22.5698, lng: 88.3881 },
  { id: 'metro_saltlakestadium', name: 'Salt Lake Stadium Metro Public Toilet', lat: 22.5714, lng: 88.4025 },
  { id: 'metro_bengalchemical', name: 'Bengal Chemical Metro Public Toilet', lat: 22.5772, lng: 88.4053 },
  { id: 'metro_citycentre', name: 'City Centre Salt Lake Metro Public Toilet', lat: 22.5878, lng: 88.4089 },
  { id: 'metro_centralpark', name: 'Central Park Metro Public Toilet', lat: 22.5912, lng: 88.4147 },
  { id: 'metro_karunamoyee', name: 'Karunamoyee Bus Terminus Metro Public Toilet', lat: 22.5867, lng: 88.4208 },
  { id: 'metro_sectorv', name: 'Salt Lake Sector V Metro Public Toilet', lat: 22.5803, lng: 88.4336 },

  // Line 3: Purple Line
  { id: 'metro_joka', name: 'Joka Metro Station Public Toilet', lat: 22.4568, lng: 88.3039 },
  { id: 'metro_thakurpukur', name: 'Thakurpukur Metro Station Public Toilet', lat: 22.4682, lng: 88.3072 },
  { id: 'metro_sakherbazar', name: 'Sakher Bazar Metro Station Public Toilet', lat: 22.4824, lng: 88.3121 },
  { id: 'metro_behalachowrasta', name: 'Behala Chowrasta Metro Public Toilet', lat: 22.4936, lng: 88.3149 },
  { id: 'metro_behalabazar', name: 'Behala Bazar Metro Public Toilet', lat: 22.5052, lng: 88.3182 },
  { id: 'metro_taratala', name: 'Taratala Metro Station Public Toilet', lat: 22.5154, lng: 88.3208 },
  { id: 'metro_majerhat', name: 'Majerhat Railway/Metro Public Toilet', lat: 22.5228, lng: 88.3242 },

  // Line 6: Orange Line
  { id: 'metro_satyajitray', name: 'Satyajit Ray (Hiland Park) Metro Public Toilet', lat: 22.4842, lng: 88.3989 },
  { id: 'metro_jyotirindranandi', name: 'Jyotirindra Nandi (Mukundapur) Metro Public Toilet', lat: 22.4982, lng: 88.3995 },
  { id: 'metro_kavisukanta', name: 'Kavi Sukanta (Kalikapur) Metro Public Toilet', lat: 22.5089, lng: 88.4002 },
  { id: 'metro_ruby', name: 'Hemanta Mukhopadhyay (Ruby Crossing) Metro Public Toilet', lat: 22.5186, lng: 88.4014 }
].map(m => ({
  ...m,
  male: true,
  female: true,
  fee: true,
  access: 'public',
  source: 'metro'
}));

// 3. Iconic Kolkata Municipal Corporation (KMC) & Sulabh Shauchalay Hubs
const kmcPublicToilets = [
  // North Kolkata & Central Hubs
  { id: 'kmc_bagbazar_ghat', name: 'KMC Public Toilet — Bagbazar Launch Ghat', lat: 22.6045, lng: 88.3640 },
  { id: 'kmc_kumartuli_park', name: 'Sulabh Shauchalay — Kumartuli Park', lat: 22.5998, lng: 88.3639 },
  { id: 'kmc_hatibagan_crossing', name: 'KMC Pay & Use Toilet — Hatibagan Market Crossing', lat: 22.5971, lng: 88.3722 },
  { id: 'kmc_maniktala_crossing', name: 'Sulabh Complex — Maniktala Civic Centre', lat: 22.5872, lng: 88.3745 },
  { id: 'kmc_college_square', name: 'KMC Public Toilet — College Square Swimming Pool Side', lat: 22.5768, lng: 88.3638 },
  { id: 'kmc_sealdah_flyover', name: 'Sulabh Shauchalay — Sealdah Station South Gate', lat: 22.5658, lng: 88.3725 },
  { id: 'kmc_bowbazar', name: 'KMC Pay & Use — Bowbazar Crossing', lat: 22.5682, lng: 88.3624 },
  { id: 'kmc_new_market', name: 'KMC Public Toilet — Lindsay Street / New Market', lat: 22.5598, lng: 88.3532 },
  { id: 'kmc_babughat', name: 'Sulabh Shauchalay Complex — Babughat Bus Terminus', lat: 22.5645, lng: 88.3436 },
  { id: 'kmc_prinsep_ghat', name: 'KMC Public Toilet — Strand Road / Prinsep Ghat', lat: 22.5562, lng: 88.3356 },

  // South Kolkata Hubs
  { id: 'kmc_gariahata_more', name: 'KMC Pay & Use Toilet — Gariahat Pantaloons Crossing', lat: 22.5178, lng: 88.3654 },
  { id: 'kmc_deshapriya_park', name: 'Sulabh Shauchalay — Deshapriya Park North Gate', lat: 22.5204, lng: 88.3568 },
  { id: 'kmc_maddox_square', name: 'KMC Public Toilet — Maddox Square East Entrance', lat: 22.5282, lng: 88.3595 },
  { id: 'kmc_rashbehari_crossing', name: 'KMC Pay & Use — Rashbehari Avenue & SP Mukherjee Rd', lat: 22.5182, lng: 88.3465 },
  { id: 'kmc_kalighat_temple', name: 'Sulabh Shauchalay — Kalighat Temple Ghat Road', lat: 22.5165, lng: 88.3421 },
  { id: 'kmc_jadavpur_8b', name: 'Sulabh Complex — Jadavpur 8B Bus Terminus', lat: 22.4988, lng: 88.3712 },
  { id: 'kmc_santoshpur_jora_bridge', name: 'KMC Pay & Use Toilet — Santoshpur Jora Bridge', lat: 22.4942, lng: 88.3842 },
  { id: 'kmc_behala_chowrasta', name: 'KMC Public Toilet — Behala Chowrasta Tram Depot', lat: 22.4945, lng: 88.3156 },
  { id: 'kmc_tollygunge_phari', name: 'Sulabh Shauchalay — Tollygunge Phari / Prince Anwar Shah Rd', lat: 22.5082, lng: 88.3442 },
  { id: 'kmc_dhakuria_bridge', name: 'KMC Pay & Use Toilet — Dhakuria Railway Crossing', lat: 22.5098, lng: 88.3685 },
  { id: 'kmc_ballygunge_phari', name: 'KMC Public Toilet — Ballygunge Phari Crossing', lat: 22.5286, lng: 88.3689 },
  { id: 'kmc_hazra_crossing', name: 'Sulabh Shauchalay — Hazra Crossing Ashutosh Mukherjee Rd', lat: 22.5255, lng: 88.3468 },
  { id: 'kmc_park_circus_7point', name: 'Sulabh Shauchalay — Park Circus 7-Point Crossing', lat: 22.5412, lng: 88.3668 },
  { id: 'kmc_exide_crossing', name: 'KMC Pay & Use — Exide Crossing / Rabindra Sadan', lat: 22.5385, lng: 88.3472 },

  // Eastern Bypass & Salt Lake / New Town Hubs
  { id: 'kmc_ultadanga_hudco', name: 'Sulabh Complex — Ultadanga HUDCO Bus Terminus', lat: 22.5925, lng: 88.3912 },
  { id: 'kmc_kankurgachi_more', name: 'KMC Pay & Use — Kankurgachi 4 Point Crossing', lat: 22.5802, lng: 88.3868 },
  { id: 'kmc_saltlake_centralpark', name: 'Sulabh Public Toilet — Salt Lake Central Park 3rd Gate', lat: 22.5898, lng: 88.4162 },
  { id: 'kmc_saltlake_karunamoyee', name: 'KMC / BMC Public Toilet — Karunamoyee International Bus Stand', lat: 22.5862, lng: 88.4215 },
  { id: 'kmc_newtown_ecopark', name: 'HIDCO Public Toilet — Eco Park Gate 2', lat: 22.6052, lng: 88.4682 },
  { id: 'kmc_ruby_hospital', name: 'Sulabh Shauchalay — Ruby General Hospital Junction', lat: 22.5175, lng: 88.4022 },
  { id: 'kmc_sc_mallick_baghajatin', name: 'KMC Public Toilet — Baghajatin More / Raja SC Mallick Rd', lat: 22.4825, lng: 88.3752 },
  { id: 'kmc_garia_sheetala_mandir', name: 'KMC Pay & Use — Garia Sheetala Mandir Crossing', lat: 22.4638, lng: 88.3782 },
  { id: 'kmc_dumdum_park', name: 'Sulabh Shauchalay — Dum Dum Park VIP Road Crossing', lat: 22.6078, lng: 88.4062 },
  { id: 'kmc_sreebhumi_vip', name: 'KMC / South Dum Dum Public Toilet — Sreebhumi VIP Road Footbridge', lat: 22.6012, lng: 88.4018 },
  { id: 'kmc_lake_town_clocktower', name: 'Sulabh Public Toilet — Lake Town Clock Tower', lat: 22.6035, lng: 88.4042 },

  // Howrah Hubs
  { id: 'kmc_howrah_station_cab', name: 'Howrah Station Cab Road Public Toilet Complex', lat: 22.5855, lng: 88.3412 },
  { id: 'kmc_howrah_bus_stand', name: 'Sulabh Complex — Howrah Bus Stand / Riverfront', lat: 22.5862, lng: 88.3412 },
  { id: 'kmc_kadamtala_howrah', name: 'HMC Public Toilet — Kadamtala More Howrah', lat: 22.5762, lng: 88.3215 }
].map(k => ({
  ...k,
  male: true,
  female: true,
  fee: true,
  access: 'public',
  source: 'kmc_sulabh'
}));

// Main scraping & calculation pipeline
async function main() {
  console.log('--- Kolkata Public Toilets Pipeline Starting ---');

  // Step 1: Fetch OSM Toilets
  const osmToilets = await fetchOsmToilets();

  // Step 2: Combine all toilets
  const allToilets = [...osmToilets, ...metroToilets, ...kmcPublicToilets];
  console.log(`Total toilet pool: ${allToilets.length} (${osmToilets.length} OSM + ${metroToilets.length} Metro + ${kmcPublicToilets.length} KMC/Sulabh)`);

  // Step 3: Load Pandals
  let pandals = [];
  if (fs.existsSync(PANDALS_ASSET_JSON)) {
    pandals = JSON.parse(fs.readFileSync(PANDALS_ASSET_JSON, 'utf8'));
  } else if (fs.existsSync(PANDALS_DATA_JSON)) {
    pandals = JSON.parse(fs.readFileSync(PANDALS_DATA_JSON, 'utf8'));
  }

  // Also merge with any extra pandals in data/pandals.json if available
  if (fs.existsSync(PANDALS_DATA_JSON)) {
    const extra = JSON.parse(fs.readFileSync(PANDALS_DATA_JSON, 'utf8'));
    const seen = new Set(pandals.map(p => p.id));
    for (const p of extra) {
      if (!seen.has(p.id)) {
        pandals.push(p);
        seen.add(p.id);
      }
    }
  }

  console.log(`Matching toilets for ${pandals.length} pandals...`);

  const results = [];
  let under500 = 0;
  let under1000 = 0;
  let under1500 = 0;

  for (const pandal of pandals) {
    const { id, name, lat, lng } = pandal;
    if (!lat || !lng) continue;

    // Calculate distance to every toilet
    const distances = allToilets.map(t => ({
      ...t,
      distM: Math.round(haversineMeters(lat, lng, t.lat, t.lng))
    }));

    // Sort by ascending distance
    distances.sort((a, b) => a.distM - b.distM);

    // Pick nearest male & nearest female
    const maleToilets   = distances.filter(t => t.male);
    const femaleToilets = distances.filter(t => t.female);

    const nearestMale   = maleToilets.length > 0 ? maleToilets[0] : null;
    const nearestFemale = femaleToilets.length > 0 ? femaleToilets[0] : null;

    // Top 3 unique toilets nearby
    const topNearby = distances.slice(0, 3);

    const closestDist = Math.min(nearestMale?.distM ?? Infinity, nearestFemale?.distM ?? Infinity);
    if (closestDist <= 500) under500++;
    if (closestDist <= 1000) under1000++;
    if (closestDist <= 1500) under1500++;

    results.push({
      pandalId: id,
      pandalName: name,
      nearestMale: nearestMale ? {
        id: nearestMale.id,
        lat: nearestMale.lat,
        lng: nearestMale.lng,
        name: nearestMale.name,
        male: nearestMale.male,
        female: nearestMale.female,
        fee: nearestMale.fee,
        access: nearestMale.access,
        distM: nearestMale.distM,
        source: nearestMale.source
      } : null,
      nearestFemale: nearestFemale ? {
        id: nearestFemale.id,
        lat: nearestFemale.lat,
        lng: nearestFemale.lng,
        name: nearestFemale.name,
        male: nearestFemale.male,
        female: nearestFemale.female,
        fee: nearestFemale.fee,
        access: nearestFemale.access,
        distM: nearestFemale.distM,
        source: nearestFemale.source
      } : null,
      allNearby: topNearby.map(t => ({
        id: t.id,
        lat: t.lat,
        lng: t.lng,
        name: t.name,
        male: t.male,
        female: t.female,
        fee: t.fee,
        access: t.access,
        distM: t.distM,
        source: t.source
      }))
    });
  }

  // Save to outputs
  const jsonContent = JSON.stringify(results, null, 2);
  fs.writeFileSync(OUT_DATA, jsonContent, 'utf8');
  fs.writeFileSync(OUT_ASSET, jsonContent, 'utf8');

  console.log('\n=========================================');
  console.log(`✅ Toilets dataset generated for ${results.length} pandals!`);
  console.log(`   Within 500m : ${under500} (${(under500 / results.length * 100).toFixed(1)}%)`);
  console.log(`   Within 1000m: ${under1000} (${(under1000 / results.length * 100).toFixed(1)}%)`);
  console.log(`   Within 1500m: ${under1500} (${(under1500 / results.length * 100).toFixed(1)}%)`);
  console.log(`   Written to:`);
  console.log(`     - ${OUT_DATA}`);
  console.log(`     - ${OUT_ASSET}`);
  console.log('=========================================\n');
}

main().catch(err => {
  console.error('Fatal error:', err);
  process.exit(1);
});
