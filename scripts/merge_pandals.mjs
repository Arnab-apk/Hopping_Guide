import fs from 'fs';
import path from 'path';

const csvPath = 'C:/Users/arnab/.gemini/antigravity-ide/brain/977ebf11-fb23-4bc9-9ab7-6215d226bcea/.user_uploaded/media_1789314880029.csv';
const assetPandalsJson = 'app/assets/data/pandals.json';
const dataPandalsJson = 'data/pandals.json';
const dataPandalsCsv = 'data/pandals.csv';

// 46 Base Areas Metadata for realistic Kolkata distribution
const BASE_AREAS = {
  'Ahiritola': {
    lat: 22.5947, lng: 88.3603,
    zone: 'northKolkata', area: 'Ahiritola, North Kolkata', region: 'North',
    metro: 'Sovabazar Sutanuti (Blue)', railway: 'Sovabazar Ahiritola (Circular)',
  },
  'Badamtala Ashar Sangha': {
    lat: 22.5182, lng: 88.3437,
    zone: 'southKolkata', area: 'Kalighat, South Kolkata', region: 'South',
    metro: 'Kalighat (Blue)', railway: 'Majerhat Railway Station',
  },
  'Bagbazar': {
    lat: 22.6046, lng: 88.3656,
    zone: 'northKolkata', area: 'Bagbazar, North Kolkata', region: 'North',
    metro: 'Shyambazar (Blue)', railway: 'Bagbazar (Circular)',
  },
  'Baguiati': {
    lat: 22.6180, lng: 88.4280,
    zone: 'northKolkata', area: 'Baguiati, North Kolkata', region: 'North',
    metro: 'Dum Dum (Blue)', railway: 'Bidhannagar Road',
  },
  'Ballygunge Cultural': {
    lat: 22.5163, lng: 88.3558,
    zone: 'southKolkata', area: 'Ballygunge, South Kolkata', region: 'South',
    metro: 'Kalighat (Blue)', railway: 'Ballygunge Junction',
  },
  'Baranagar': {
    lat: 22.6420, lng: 88.3750,
    zone: 'northKolkata', area: 'Baranagar, North Kolkata', region: 'North',
    metro: 'Baranagar (Blue)', railway: 'Baranagar Road',
  },
  'Barisha Club': {
    lat: 22.4840, lng: 88.3120,
    zone: 'southKolkata', area: 'Barisha, Behala, South Kolkata', region: 'South',
    metro: 'Behala Chowrasta (Purple)', railway: 'Majerhat Railway Station',
  },
  'Behala Friends': {
    lat: 22.5014, lng: 88.3204,
    zone: 'southKolkata', area: 'Behala, South Kolkata', region: 'South',
    metro: 'Behala Bazar (Purple)', railway: 'Majerhat Railway Station',
  },
  'Behala Nutan Dal': {
    lat: 22.5002, lng: 88.3202,
    zone: 'southKolkata', area: 'Behala, South Kolkata', region: 'South',
    metro: 'Behala Bazar (Purple)', railway: 'Majerhat Railway Station',
  },
  'Belgharia': {
    lat: 22.6620, lng: 88.3840,
    zone: 'northKolkata', area: 'Belgharia, North Kolkata', region: 'North',
    metro: 'Dakshineswar (Blue)', railway: 'Belgharia Railway Station',
  },
  'Chaltabagan': {
    lat: 22.5852, lng: 88.3690,
    zone: 'northKolkata', area: 'Maniktala, North Kolkata', region: 'North',
    metro: 'Girish Park (Blue)', railway: 'Sealdah',
  },
  'Chetla Agrani': {
    lat: 22.5164, lng: 88.3368,
    zone: 'southKolkata', area: 'Chetla, South Kolkata', region: 'South',
    metro: 'Kalighat (Blue)', railway: 'Majerhat Railway Station',
  },
  'College Square': {
    lat: 22.5748, lng: 88.3644,
    zone: 'centralKolkata', area: 'College Street, Central Kolkata', region: 'Central',
    metro: 'Central (Blue)', railway: 'Sealdah',
  },
  'Deshapriya Park': {
    lat: 22.5188, lng: 88.3535,
    zone: 'southKolkata', area: 'Deshapriya Park, South Kolkata', region: 'South',
    metro: 'Kalighat (Blue)', railway: 'Ballygunge Junction',
  },
  'Dum Dum Park': {
    lat: 22.6110, lng: 88.4146,
    zone: 'northKolkata', area: 'Dum Dum Park, North Kolkata', region: 'North',
    metro: 'Dum Dum (Blue)', railway: 'Bidhannagar Road',
  },
  'Ekdalia Evergreen': {
    lat: 22.5214, lng: 88.3666,
    zone: 'southKolkata', area: 'Gariahat, South Kolkata', region: 'South',
    metro: 'Kalighat (Blue)', railway: 'Ballygunge Junction',
  },
  'Haridevpur': {
    lat: 22.4780, lng: 88.3280,
    zone: 'southKolkata', area: 'Haridevpur, South Kolkata', region: 'South',
    metro: 'Mahanayak Uttam Kumar (Blue)', railway: 'Majerhat Railway Station',
  },
  'Hatibagan Sarbojonin': {
    lat: 22.5947, lng: 88.3720,
    zone: 'northKolkata', area: 'Hatibagan, North Kolkata', region: 'North',
    metro: 'Shyambazar (Blue)', railway: 'Kolkata Station (Circular)',
  },
  'Hindustan Park': {
    lat: 22.5182, lng: 88.3619,
    zone: 'southKolkata', area: 'Gariahat, South Kolkata', region: 'South',
    metro: 'Kalighat (Blue)', railway: 'Ballygunge Junction',
  },
  'Jodhpur Park': {
    lat: 22.5030, lng: 88.3620,
    zone: 'southKolkata', area: 'Jodhpur Park, South Kolkata', region: 'South',
    metro: 'Rabindra Sarobar (Blue)', railway: 'Dhakuria Railway Station',
  },
  'Kalikapur': {
    lat: 22.5010, lng: 88.3980,
    zone: 'southKolkata', area: 'Kalikapur, South Kolkata', region: 'South',
    metro: 'Hemanta Mukherjee (Orange)', railway: 'Jadabpur Railway Station',
  },
  'Kankurgachi': {
    lat: 22.5800, lng: 88.3942,
    zone: 'northKolkata', area: 'Kankurgachi, North Kolkata', region: 'North',
    metro: 'Bengal Chemical (Green)', railway: 'Bidhannagar Road',
  },
  'Kasba Bosepukur': {
    lat: 22.5195, lng: 88.3849,
    zone: 'southKolkata', area: 'Kasba, South Kolkata', region: 'South',
    metro: 'Hemanta Mukherjee (Orange)', railway: 'Ballygunge Junction',
  },
  'Kashi Bose Lane': {
    lat: 22.5909, lng: 88.3689,
    zone: 'northKolkata', area: 'Maniktala, North Kolkata', region: 'North',
    metro: 'Shyambazar (Blue)', railway: 'Sovabazar Ahiritola (Circular)',
  },
  'Khardah': {
    lat: 22.7210, lng: 88.3820,
    zone: 'northKolkata', area: 'Khardah, North Kolkata', region: 'North',
    metro: 'Dakshineswar (Blue)', railway: 'Khardaha Railway Station',
  },
  'Kumartuli Park': {
    lat: 22.5990, lng: 88.3620,
    zone: 'northKolkata', area: 'Kumartuli, North Kolkata', region: 'North',
    metro: 'Sovabazar Sutanuti (Blue)', railway: 'Sovabazar Ahiritola (Circular)',
  },
  'Lake Town': {
    lat: 22.6084, lng: 88.4004,
    zone: 'northKolkata', area: 'Lake Town, North Kolkata', region: 'North',
    metro: 'Belgachia (Blue)', railway: 'Bidhannagar Road',
  },
  'Mudiali': {
    lat: 22.5102, lng: 88.3463,
    zone: 'southKolkata', area: 'Kalighat, South Kolkata', region: 'South',
    metro: 'Rabindra Sarobar (Blue)', railway: 'Tollygunge Railway Station',
  },
  'Naktala Udayan Sangha': {
    lat: 22.4744, lng: 88.3666,
    zone: 'southKolkata', area: 'Naktala, South Kolkata', region: 'South',
    metro: 'Gitanjali (Blue)', railway: 'Garia Railway Station',
  },
  'New Alipore': {
    lat: 22.5080, lng: 88.3280,
    zone: 'southKolkata', area: 'New Alipore, South Kolkata', region: 'South',
    metro: 'Rabindra Sarobar (Blue)', railway: 'New Alipore Railway Station',
  },
  'Park Circus': {
    lat: 22.5440, lng: 88.3680,
    zone: 'centralKolkata', area: 'Park Circus, Central Kolkata', region: 'Central',
    metro: 'Rabindra Sadan (Blue)', railway: 'Park Circus Railway Station',
  },
  'Patuli': {
    lat: 22.4720, lng: 88.3850,
    zone: 'southKolkata', area: 'Patuli, South Kolkata', region: 'South',
    metro: 'Kavi Subhash (Blue)', railway: 'Baghajatin Railway Station',
  },
  'Rajdanga Naba Uday': {
    lat: 22.5150, lng: 88.3920,
    zone: 'southKolkata', area: 'Kasba / Rajdanga, South Kolkata', region: 'South',
    metro: 'Hemanta Mukherjee (Orange)', railway: 'Ballygunge Junction',
  },
  'Salt Lake BJ Block': {
    lat: 22.5870, lng: 88.4110,
    zone: 'saltLake', area: 'Sector II, Salt Lake', region: 'East',
    metro: 'Karunamoyee (Green)', railway: 'Bidhannagar Road',
  },
  'Salt Lake FD Block': {
    lat: 22.5760, lng: 88.4120,
    zone: 'saltLake', area: 'Sector III, Salt Lake', region: 'East',
    metro: 'City Centre (Green)', railway: 'Bidhannagar Road',
  },
  'Samaj Sebi Sangha': {
    lat: 22.5160, lng: 88.3563,
    zone: 'southKolkata', area: 'Lake View Road, South Kolkata', region: 'South',
    metro: 'Kalighat (Blue)', railway: 'Ballygunge Junction',
  },
  'Santosh Mitra Square': {
    lat: 22.5662, lng: 88.3657,
    zone: 'centralKolkata', area: 'Bowbazar, Central Kolkata', region: 'Central',
    metro: 'Central (Blue)', railway: 'Sealdah',
  },
  'Selimpur Pally': {
    lat: 22.5020, lng: 88.3680,
    zone: 'southKolkata', area: 'Selimpur, South Kolkata', region: 'South',
    metro: 'Rabindra Sarobar (Blue)', railway: 'Dhakuria Railway Station',
  },
  'Shibmandir': {
    lat: 22.5110, lng: 88.3498,
    zone: 'southKolkata', area: 'Mudiali, South Kolkata', region: 'South',
    metro: 'Rabindra Sarobar (Blue)', railway: 'Tollygunge Railway Station',
  },
  'Sinthi': {
    lat: 22.6280, lng: 88.3810,
    zone: 'northKolkata', area: 'Sinthi, North Kolkata', region: 'North',
    metro: 'Dum Dum (Blue)', railway: 'Dum Dum Junction',
  },
  'South City': {
    lat: 22.4980, lng: 88.3620,
    zone: 'southKolkata', area: 'Prince Anwar Shah Road, South Kolkata', region: 'South',
    metro: 'Rabindra Sarobar (Blue)', railway: 'Tollygunge Railway Station',
  },
  'Sovabazar Rajbari': {
    lat: 22.5960, lng: 88.3630,
    zone: 'northKolkata', area: 'Sovabazar, North Kolkata', region: 'North',
    metro: 'Sovabazar Sutanuti (Blue)', railway: 'Sovabazar Ahiritola (Circular)',
  },
  'Sreebhumi Sporting': {
    lat: 22.6000, lng: 88.4020,
    zone: 'northKolkata', area: 'Lake Town / Sreebhumi, North Kolkata', region: 'North',
    metro: 'Belgachia (Blue)', railway: 'Bidhannagar Road',
  },
  'Telenga Bagan': {
    lat: 22.5910, lng: 88.3810,
    zone: 'northKolkata', area: 'Ultadanga, North Kolkata', region: 'North',
    metro: 'Belgachia (Blue)', railway: 'Bidhannagar Road',
  },
  'Tridhara Sammilani': {
    lat: 22.5198, lng: 88.3554,
    zone: 'southKolkata', area: 'Monoharpukur Road, South Kolkata', region: 'South',
    metro: 'Kalighat (Blue)', railway: 'Ballygunge Junction',
  },
  'Ultadanga Pally': {
    lat: 22.5958, lng: 88.3847,
    zone: 'northKolkata', area: 'Ultadanga, North Kolkata', region: 'North',
    metro: 'Belgachia (Blue)', railway: 'Bidhannagar Road',
  },
};

// Simple pseudo-random hash generator for deterministic micro-jitter
function getDeterministicOffset(seedStr, radiusDeg = 0.0075) {
  let hash = 0;
  for (let i = 0; i < seedStr.length; i++) {
    hash = (hash * 31 + seedStr.charCodeAt(i)) & 0xFFFFFFFF;
  }
  const angle = ((hash % 360) * Math.PI) / 180;
  const dist = ((Math.abs(hash >> 8) % 1000) / 1000) * radiusDeg;
  return {
    dLat: Math.sin(angle) * dist,
    dLng: Math.cos(angle) * dist,
  };
}

function parseCSV(text) {
  const rows = [];
  let row = [];
  let current = '';
  let inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (c === '"') {
      if (inQuotes && text[i+1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (c === ',' && !inQuotes) {
      row.push(current.trim());
      current = '';
    } else if ((c === '\r' || c === '\n') && !inQuotes) {
      if (c === '\r' && text[i+1] === '\n') i++;
      row.push(current.trim());
      if (row.length > 1 || (row.length === 1 && row[0] !== '')) {
        rows.push(row);
      }
      row = [];
      current = '';
    } else {
      current += c;
    }
  }
  if (current.length > 0 || row.length > 0) {
    row.push(current.trim());
    rows.push(row);
  }
  return rows;
}

// 1. Read existing curated dataset (filter out any previously generated csv_ items to be idempotent)
const allPandals = JSON.parse(fs.readFileSync(assetPandalsJson, 'utf8'));
const existingPandals = allPandals.filter(p => !p.source_id?.startsWith('csv_'));
console.log(`[INIT] Loaded ${existingPandals.length} existing curated pandals.`);

// 2. Track curated names and IDs to ensure no duplicates
const curatedNames = new Set();
const seenNames = new Set();
const seenIds = new Set();

for (const p of existingPandals) {
  const norm = p.name.trim().toLowerCase();
  curatedNames.add(norm);
  seenNames.add(norm);
  seenIds.add(p.id.trim().toLowerCase());
}

// 3. Read & Parse CSV
const csvContent = fs.readFileSync(csvPath, 'utf8');
const rows = parseCSV(csvContent);
const header = rows[0];
const dataRows = rows.slice(1);

console.log(`[CSV] Read ${dataRows.length} rows from CSV.`);

let duplicatesInCsvCount = 0;
let duplicatesWithCuratedCount = 0;
let newlyAddedCount = 0;

const mergedPandals = [...existingPandals];

for (const r of dataRows) {
  const pandalIdCsv = r[0];
  const name = r[1];
  const theme = r[2] || 'Traditional';
  const csvLocation = r[3] || 'Central Kolkata';
  const description = r[4] || '';
  const yearEstablished = parseInt(r[5], 10) || 1990;
  const avgRating = parseFloat(r[6]) || 4.0;

  if (!name) continue;

  const normalizedName = name.trim().toLowerCase();

  // Check if already in existing curated dataset
  if (curatedNames.has(normalizedName)) {
    duplicatesWithCuratedCount++;
    continue;
  }

  // Check if duplicate within CSV itself
  if (seenNames.has(normalizedName)) {
    duplicatesInCsvCount++;
    continue;
  }

  // Register name as seen
  seenNames.add(normalizedName);

  // Determine base area
  const match = name.match(/^(.+?)\s+\d+$/);
  const baseAreaName = match ? match[1].trim() : name.trim();

  // Lookup metadata for base area or fallback to sensible default
  let meta = BASE_AREAS[baseAreaName];
  if (!meta) {
    // Fallback based on csvLocation
    let fallbackZone = 'centralKolkata';
    let fallbackLat = 22.5662;
    let fallbackLng = 88.3657;
    if (csvLocation.includes('North')) {
      fallbackZone = 'northKolkata';
      fallbackLat = 22.5950;
      fallbackLng = 88.3700;
    } else if (csvLocation.includes('South')) {
      fallbackZone = 'southKolkata';
      fallbackLat = 22.5150;
      fallbackLng = 88.3550;
    } else if (csvLocation.includes('East')) {
      fallbackZone = 'saltLake';
      fallbackLat = 22.5800;
      fallbackLng = 88.4100;
    }
    meta = {
      lat: fallbackLat,
      lng: fallbackLng,
      zone: fallbackZone,
      area: `${baseAreaName}, ${csvLocation}`,
      region: csvLocation.replace(' Kolkata', ''),
      metro: 'Central (Blue)',
      railway: 'Sealdah',
    };
  }

  // Generate unique ID
  let slug = name.toLowerCase().replace(/[^a-z0-9]+/g, '_').replace(/^_+|_+$/g, '');
  if (seenIds.has(slug)) {
    slug = `${slug}_${pandalIdCsv}`;
  }
  seenIds.add(slug);

  // Compute deterministic coordinates with realistic jitter around neighborhood center
  const offset = getDeterministicOffset(name + pandalIdCsv, 0.0075);
  const lat = parseFloat((meta.lat + offset.dLat).toFixed(6));
  const lng = parseFloat((meta.lng + offset.dLng).toFixed(6));

  // Determine crowd level based on rating
  let crowdLevel = 'medium';
  if (avgRating >= 4.5) {
    crowdLevel = 'high';
  } else if (avgRating < 3.8) {
    crowdLevel = 'low';
  }

  const newPandal = {
    id: slug,
    source_id: `csv_${pandalIdCsv}`,
    name: name.trim(),
    lat: lat,
    lng: lng,
    zone: meta.zone,
    area: meta.area,
    region: meta.region,
    rating: parseFloat(avgRating.toFixed(1)),
    theme: theme.trim(),
    crowd_level: crowdLevel,
    timings: '12:00 AM - 12:00 PM',
    transport: ['Metro', 'Railway', 'Auto', 'Bus'],
    nearest_metro: meta.metro,
    nearest_metro_list: [meta.metro],
    nearest_railway: meta.railway,
    nearest_railway_list: [meta.railway],
    special_features: yearEstablished ? [`Est. ${yearEstablished}`] : [],
    image_url: '',
    description: description.trim(),
  };

  mergedPandals.push(newPandal);
  newlyAddedCount++;
}

console.log(`[MERGE STATS]`);
console.log(`- Existing curated pandals: ${existingPandals.length}`);
console.log(`- Duplicates matching curated pandals: ${duplicatesWithCuratedCount}`);
console.log(`- Duplicates found & eliminated within CSV: ${dataRows.length - newlyAddedCount - duplicatesWithCuratedCount}`);
console.log(`- New unique pandals added: ${newlyAddedCount}`);
console.log(`- Total merged pandals: ${mergedPandals.length}`);

// 4. Save to app/assets/data/pandals.json
fs.writeFileSync(assetPandalsJson, JSON.stringify(mergedPandals, null, 2), 'utf8');
console.log(`[SUCCESS] Wrote ${mergedPandals.length} pandals to ${assetPandalsJson}`);

// 5. Save to data/pandals.json
fs.writeFileSync(dataPandalsJson, JSON.stringify(mergedPandals, null, 2), 'utf8');
console.log(`[SUCCESS] Wrote ${mergedPandals.length} pandals to ${dataPandalsJson}`);

// 6. Generate data/pandals.csv
const csvHeader = 'id,name,lat,lng,zone,area,region,rating,theme,crowd_level,timings,image_url,description,nearest_metro,nearest_railway\n';
const csvLines = mergedPandals.map(p => {
  const escapeCsv = (str) => {
    if (!str) return '';
    if (str.includes(',') || str.includes('"') || str.includes('\n')) {
      return `"${str.replace(/"/g, '""')}"`;
    }
    return str;
  };
  return [
    p.id,
    escapeCsv(p.name),
    p.lat,
    p.lng,
    p.zone,
    escapeCsv(p.area),
    escapeCsv(p.region),
    p.rating ?? '',
    escapeCsv(p.theme),
    p.crowd_level ?? '',
    escapeCsv(p.timings),
    escapeCsv(p.image_url),
    escapeCsv(p.description),
    escapeCsv(p.nearest_metro),
    escapeCsv(p.nearest_railway),
  ].join(',');
}).join('\n');

fs.writeFileSync(dataPandalsCsv, csvHeader + csvLines + '\n', 'utf8');
console.log(`[SUCCESS] Wrote ${mergedPandals.length} pandals to ${dataPandalsCsv}`);
