import https from 'https';
import fs from 'fs';
import path from 'path';

const KML_URL = 'https://www.google.com/maps/d/kml?mid=1GQ8KBEuldEMnoAmccpMiNdoHX-M8UQI&forcekml=1';
const LOCAL_KML_PATH = 'scripts/thepujo_dump.kml';
const OUTPUT_JSON_PATH = 'data/thepujo_scraped.json';

// All 43 Kolkata Metro Stations from MetroRepository
const METRO_STATIONS = [
  // Line 1 (Blue Line)
  { id: 'm_dakshineswar', name: 'Dakshineswar (Blue)', lat: 22.6536, lng: 88.3582 },
  { id: 'm_baranagar', name: 'Baranagar (Blue)', lat: 22.6416, lng: 88.3697 },
  { id: 'm_noapara', name: 'Noapara (Blue)', lat: 22.6375, lng: 88.3847 },
  { id: 'm_dumdum', name: 'Dum Dum (Blue)', lat: 22.6217, lng: 88.3789 },
  { id: 'm_belgachia', name: 'Belgachia (Blue)', lat: 22.6049, lng: 88.3813 },
  { id: 'm_shyambazar', name: 'Shyambazar (Blue)', lat: 22.5997, lng: 88.3712 },
  { id: 'm_shobhabazar', name: 'Sovabazar Sutanuti (Blue)', lat: 22.5925, lng: 88.3653 },
  { id: 'm_girish_park', name: 'Girish Park (Blue)', lat: 22.5855, lng: 88.3606 },
  { id: 'm_mg_road', name: 'MG Road (Blue)', lat: 22.5794, lng: 88.3605 },
  { id: 'm_central', name: 'Central (Blue)', lat: 22.5714, lng: 88.3592 },
  { id: 'm_chandni_chowk', name: 'Chandni Chowk (Blue)', lat: 22.5663, lng: 88.3556 },
  { id: 'm_esplanade', name: 'Esplanade (Blue/Green)', lat: 22.5647, lng: 88.3516 },
  { id: 'm_park_street', name: 'Park Street (Blue)', lat: 22.5529, lng: 88.3513 },
  { id: 'm_maidan', name: 'Maidan (Blue)', lat: 22.5447, lng: 88.3497 },
  { id: 'm_rabindra_sadan', name: 'Rabindra Sadan (Blue)', lat: 22.5372, lng: 88.3475 },
  { id: 'm_netaji_bhavan', name: 'Netaji Bhavan (Blue)', lat: 22.5311, lng: 88.3467 },
  { id: 'm_jatin_das_park', name: 'Jatin Das Park (Blue)', lat: 22.5222, lng: 88.3472 },
  { id: 'm_kalighat', name: 'Kalighat (Blue)', lat: 22.5158, lng: 88.3464 },
  { id: 'm_rabindra_sarobar', name: 'Rabindra Sarobar (Blue)', lat: 22.5081, lng: 88.3456 },
  { id: 'm_uttam_kumar', name: 'Mahanayak Uttam Kumar (Blue)', lat: 22.4975, lng: 88.3450 },
  { id: 'm_netaji_kudghat', name: 'Netaji Kudghat (Blue)', lat: 22.4856, lng: 88.3461 },
  { id: 'm_masterda_surya_sen', name: 'Masterda Surya Sen (Blue)', lat: 22.4764, lng: 88.3533 },
  { id: 'm_gitanjali', name: 'Gitanjali Naktala (Blue)', lat: 22.4703, lng: 88.3622 },
  { id: 'm_kavi_nazrul', name: 'Kavi Nazrul (Blue)', lat: 22.4636, lng: 88.3736 },
  { id: 'm_shahid_khudiram', name: 'Shahid Khudiram (Blue)', lat: 22.4572, lng: 88.3886 },
  { id: 'm_kavi_subhash', name: 'Kavi Subhash (Blue/Orange)', lat: 22.4589, lng: 88.3986 },

  // Line 2 (Green Line)
  { id: 'm_howrah_maidan', name: 'Howrah Maidan (Green)', lat: 22.5856, lng: 88.3242 },
  { id: 'm_howrah_station', name: 'Howrah Station Metro (Green)', lat: 22.5847, lng: 88.3431 },
  { id: 'm_mahakaran', name: 'Mahakaran (Green)', lat: 22.5739, lng: 88.3494 },
  { id: 'm_sealdah', name: 'Sealdah Metro (Green)', lat: 22.5672, lng: 88.3711 },
  { id: 'm_phoolbagan', name: 'Phoolbagan (Green)', lat: 22.5703, lng: 88.3931 },
  { id: 'm_saltlake_stadium', name: 'Salt Lake Stadium (Green)', lat: 22.5706, lng: 88.4042 },
  { id: 'm_bengal_chemical', name: 'Bengal Chemical (Green)', lat: 22.5772, lng: 88.4069 },
  { id: 'm_city_centre', name: 'City Centre Salt Lake (Green)', lat: 22.5878, lng: 88.4097 },
  { id: 'm_central_park', name: 'Central Park Karunamoyee (Green)', lat: 22.5872, lng: 88.4194 },
  { id: 'm_karunamoyee', name: 'Karunamoyee (Green)', lat: 22.5833, lng: 88.4239 },
  { id: 'm_sector_v', name: 'Salt Lake Sector V (Green)', lat: 22.5786, lng: 88.4319 },

  // Line 3 (Purple Line)
  { id: 'm_majerhat', name: 'Majerhat (Purple)', lat: 22.5208, lng: 88.3242 },
  { id: 'm_taratala', name: 'Taratala (Purple)', lat: 22.5103, lng: 88.3181 },
  { id: 'm_behala_chowrasta', name: 'Behala Chowrasta (Purple)', lat: 22.4922, lng: 88.3117 },

  // Line 6 (Orange Line)
  { id: 'm_hemanta_mukhopadhyay', name: 'Hemanta Mukhopadhyay Ruby (Orange)', lat: 22.5133, lng: 88.4014 }
];

function haversineMeters(lat1, lon1, lat2, lon2) {
  const R = 6371e3;
  const phi1 = (lat1 * Math.PI) / 180;
  const phi2 = (lat2 * Math.PI) / 180;
  const dphi = ((lat2 - lat1) * Math.PI) / 180;
  const dlam = ((lon2 - lon1) * Math.PI) / 180;
  const a =
    Math.sin(dphi / 2) ** 2 +
    Math.cos(phi1) * Math.cos(phi2) * Math.sin(dlam / 2) ** 2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

function getNearestMetro(lat, lng) {
  let closest = null;
  let minD = Infinity;

  for (const s of METRO_STATIONS) {
    const d = haversineMeters(lat, lng, s.lat, s.lng);
    if (d < minD) {
      minD = d;
      closest = s;
    }
  }

  // Also check if another station is very close (within 1.2km)
  const nearby = [];
  if (closest) nearby.push(closest.name);

  for (const s of METRO_STATIONS) {
    if (s.id !== closest.id) {
      const d = haversineMeters(lat, lng, s.lat, s.lng);
      if (d < 1200) {
        nearby.push(s.name);
      }
    }
  }

  return {
    nearest: closest ? closest.name : 'Shyambazar (Blue)',
    list: nearby
  };
}

function getNearestRailway(lat, lng, zone) {
  if (lng < 88.34 && lat >= 22.57) return 'Howrah Railway Station';
  if (zone === 'northKolkata') {
    if (lng > 88.39) return 'Bidhannagar Road';
    if (lat >= 22.61) return 'Dum Dum Junction';
    return 'Kolkata Station (Circular)';
  }
  if (zone === 'eastKolkata') return 'Bidhannagar Road';
  if (zone === 'southKolkata') {
    if (lng < 88.34) return 'Majerhat Railway Station';
    return 'Ballygunge Junction';
  }
  return 'Sealdah Railway Station';
}

function cleanText(str) {
  if (!str) return '';
  return str
    .replace(/<!\[CDATA\[([\s\S]*?)\]\]>/g, '$1')
    .replace(/&amp;/g, '&')
    .replace(/&#39;/g, "'")
    .replace(/&quot;/g, '"')
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .trim();
}

function assignZoneAndArea(name, lat, lng, folder) {
  const cleanFolder = cleanText(folder).toLowerCase();
  const cleanName = cleanText(name).toLowerCase();

  // Salt Lake / New Town detection
  if (
    cleanFolder.includes('salt lake') ||
    cleanName.includes('salt lake') ||
    cleanName.match(/\b[a-z]{1,2}\s+block\b/i) ||
    cleanName.includes('new town') ||
    (lng >= 88.405 && lat >= 22.565 && lat <= 22.63)
  ) {
    return {
      zone: 'eastKolkata',
      area: cleanName.includes('salt lake') ? 'Salt Lake, Kolkata' : 'Salt Lake / East Kolkata',
      region: 'East'
    };
  }

  // Howrah
  if (lng < 88.338 && lat >= 22.56) {
    return {
      zone: 'howrah',
      area: 'Howrah',
      region: 'Howrah'
    };
  }

  // South Kolkata
  if (cleanFolder.includes('south') || lat < 22.545) {
    let subArea = 'South Kolkata';
    if (lat < 22.50) subArea = 'Behala / Kudghat, South Kolkata';
    else if (lng < 88.345) subArea = 'Kalighat / Chetla, South Kolkata';
    else if (lng >= 88.36) subArea = 'Gariahat / Ballygunge, South Kolkata';
    else subArea = 'Bhowanipore / South Kolkata';

    return {
      zone: 'southKolkata',
      area: subArea,
      region: 'South'
    };
  }

  // North Kolkata
  if (cleanFolder.includes('north') || lat >= 22.575) {
    let subArea = 'North Kolkata';
    if (lat >= 22.61) subArea = 'Dum Dum / Lake Town, North Kolkata';
    else if (cleanName.includes('kumartuli')) subArea = 'Kumartuli, North Kolkata';
    else if (cleanName.includes('baghbazar') || cleanName.includes('bagbazar')) subArea = 'Bagbazar, North Kolkata';
    else if (cleanName.includes('hatibagan')) subArea = 'Hatibagan, North Kolkata';
    else subArea = 'Shyambazar / Maniktala, North Kolkata';

    return {
      zone: 'northKolkata',
      area: subArea,
      region: 'North'
    };
  }

  // Central Kolkata (default for between 22.545 and 22.575)
  return {
    zone: 'centralKolkata',
    area: 'Central Kolkata (College Square / Bowbazar)',
    region: 'Central'
  };
}

export async function fetchAndScrapeThePujo() {
  console.log('Fetching/Reading ThePujo Google MyMaps KML...');
  let xml = '';

  if (fs.existsSync(LOCAL_KML_PATH)) {
    xml = fs.readFileSync(LOCAL_KML_PATH, 'utf8');
    console.log(`Loaded cached KML from ${LOCAL_KML_PATH} (${xml.length} bytes)`);
  } else {
    xml = await new Promise((resolve, reject) => {
      https.get(KML_URL, res => {
        let buf = '';
        res.on('data', chunk => (buf += chunk));
        res.on('end', () => resolve(buf));
      }).on('error', reject);
    });
    fs.writeFileSync(LOCAL_KML_PATH, xml);
    console.log(`Downloaded KML (${xml.length} bytes)`);
  }

  // Parse Folders
  const folderRegex = /<Folder>([\s\S]*?)<\/Folder>/g;
  let fMatch;
  const parsedPandals = [];
  const seenSlugs = new Set();

  while ((fMatch = folderRegex.exec(xml)) !== null) {
    const folderContent = fMatch[1];
    const folderNameMatch = folderContent.match(/<name>(.*?)<\/name>/);
    const folderName = folderNameMatch ? cleanText(folderNameMatch[1]) : 'Iconic Pujos';

    const placemarkRegex = /<Placemark>([\s\S]*?)<\/Placemark>/g;
    let pMatch;

    while ((pMatch = placemarkRegex.exec(folderContent)) !== null) {
      const pContent = pMatch[1];
      const nameMatch = pContent.match(/<name>(.*?)<\/name>/);
      const descMatch = pContent.match(/<description>([\s\S]*?)<\/description>/);
      const coordMatch = pContent.match(/<coordinates>\s*([^\s<]+)\s*<\/coordinates>/);

      const rawName = nameMatch ? cleanText(nameMatch[1]) : '';
      const rawDesc = descMatch ? cleanText(descMatch[1]) : '';
      const coordsRaw = coordMatch ? coordMatch[1].trim() : '';

      if (!rawName || !coordsRaw) continue;

      const parts = coordsRaw.split(',');
      const lng = parseFloat(parts[0]);
      const lat = parseFloat(parts[1]);

      if (isNaN(lat) || isNaN(lng)) continue;
      // Discard any points outside Kolkata wider metropolitan area
      if (lat < 22.35 || lat > 22.75 || lng < 88.15 || lng > 88.55) continue;

      // Base slug
      let slug = rawName
        .toLowerCase()
        .replace(/[^a-z0-9]+/g, '_')
        .replace(/^_+|_+$/g, '');
      if (!slug) slug = `thepujo_${parsedPandals.length + 1}`;
      if (seenSlugs.has(slug)) {
        slug = `${slug}_${parsedPandals.length + 1}`;
      }
      seenSlugs.add(slug);

      const isBonediBari = folderName.toLowerCase().includes('bonedi bari') || rawName.toLowerCase().includes('barir');
      const { zone, area, region } = assignZoneAndArea(rawName, lat, lng, folderName);
      const metro = getNearestMetro(lat, lng);
      const railway = getNearestRailway(lat, lng, zone);

      // Extract image URL if in description
      let imgUrl = '';
      const imgMatch = rawDesc.match(/https?:\/\/[^\s"'<>]+\.(?:jpg|jpeg|png|webp)/i);
      if (imgMatch) {
        imgUrl = imgMatch[0];
      }

      // Theme
      let theme = 'Traditional Bengali';
      if (isBonediBari) theme = 'Centuries-Old Bonedi Bari Heritage';
      else if (zone === 'eastKolkata') theme = 'Modern Artistic Theme';
      else if (rawName.toLowerCase().includes('tarun sangha') || rawName.toLowerCase().includes('sporting')) theme = 'Innovative Cultural Installation';

      // Special features
      const features = [];
      if (isBonediBari) {
        features.push('Centuries-Old Heritage Rituals', 'Traditional Ekchala Pratima', 'Historical Jamindar Family Puja');
      } else {
        features.push('Grand Mandap Illumination', 'Cultural Exhibition', 'High Footfall Iconic Venue');
      }

      const description = rawDesc && rawDesc.length > 5 && !rawDesc.toLowerCase().startsWith('durga puja of')
        ? rawDesc
        : `${rawName} is one of the celebrated Durga Puja celebrations located in ${area}. Known for its cultural devotion and festive atmosphere.`;

      parsedPandals.push({
        id: slug,
        source_id: `thepujo_${parsedPandals.length + 1}`,
        name: rawName,
        lat,
        lng,
        zone,
        area,
        region,
        rating: isBonediBari ? 4.7 : 4.5,
        theme,
        crowd_level: isBonediBari ? 'medium' : 'high',
        timings: isBonediBari ? '6:00 AM - 10:00 PM' : '12:00 AM - 12:00 PM',
        transport: ['Metro', 'Bus', 'Auto-rickshaw'],
        nearest_metro: metro.nearest,
        nearest_metro_list: metro.list,
        nearest_railway: railway,
        nearest_railway_list: [railway],
        special_features: features,
        image_url: imgUrl,
        description
      });
    }
  }

  console.log(`Parsed ${parsedPandals.length} valid Kolkata pandals from ThePujo KML.`);
  fs.mkdirSync('data', { recursive: true });
  fs.writeFileSync(OUTPUT_JSON_PATH, JSON.stringify(parsedPandals, null, 2));
  console.log(`Saved output to ${OUTPUT_JSON_PATH}`);
  return parsedPandals;
}

fetchAndScrapeThePujo();
