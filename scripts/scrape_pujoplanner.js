// Scraper and normalizer for Kolkata Durga Puja data from https://www.pujoplanner.com/pandals
// Usage:
//   npm run scrape
//
// Extracts:
//   - 105 Pandals (GPS coords, metro/railway, crowd level, ratings, themes, timings)
//   - Food & Bhog Spots
//   - Cultural Events
//   - Emergency Helplines
//   - First Aid Guidelines

import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const dataDir = path.join(__dirname, '..', 'data');

const TARGET_URL = 'https://www.pujoplanner.com/pandals';

function slugify(name) {
  return name
    .toLowerCase()
    .replace(/['’]/g, '')
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '');
}

function mapZone(region, area) {
  const r = (region || '').toLowerCase();
  const a = (area || '').toLowerCase();
  if (r.includes('north') || a.includes('north')) return 'northKolkata';
  if (r.includes('central') || a.includes('central')) return 'centralKolkata';
  if (r.includes('south') || a.includes('south')) return 'southKolkata';
  if (r.includes('salt') || a.includes('salt')) return 'saltLake';
  if (r.includes('town') || a.includes('new town')) return 'newTown';
  return 'centralKolkata';
}

function escapeCsv(val) {
  if (val === null || val === undefined) return '';
  const str = String(val);
  if (str.includes(',') || str.includes('"') || str.includes('\n')) {
    return `"${str.replace(/"/g, '""')}"`;
  }
  return str;
}

function extractBalancedArray(code, searchPattern) {
  const idx = code.indexOf(searchPattern);
  if (idx === -1) return null;
  const startBracket = code.indexOf('[', idx);
  if (startBracket === -1) return null;

  let depth = 0;
  let inString = false;
  let stringChar = '';
  let escape = false;

  for (let i = startBracket; i < code.length; i++) {
    const char = code[i];
    if (escape) {
      escape = false;
      continue;
    }
    if (char === '\\') {
      escape = true;
      continue;
    }
    if (inString) {
      if (char === stringChar) inString = false;
      continue;
    }
    if (char === '"' || char === "'" || char === '`') {
      inString = true;
      stringChar = char;
      continue;
    }
    if (char === '[') {
      depth++;
    } else if (char === ']') {
      depth--;
      if (depth === 0) {
        const raw = code.slice(startBracket, i + 1);
        return new Function(`return ${raw}`)();
      }
    }
  }
  return null;
}

async function scrape() {
  console.log(`[1/5] Fetching ${TARGET_URL}...`);
  const htmlRes = await fetch(TARGET_URL);
  const html = await htmlRes.text();

  const scriptMatch = html.match(/src=[\"'](\/assets\/index-[^\"']+\.js)[\"']/);
  if (!scriptMatch) {
    throw new Error('Could not find main assets script in HTML.');
  }

  const bundleUrl = new URL(scriptMatch[1], TARGET_URL).toString();
  console.log(`[2/5] Downloading JS bundle from ${bundleUrl}...`);
  const bundleRes = await fetch(bundleUrl);
  const code = await bundleRes.text();

  console.log(`[3/5] Extracting datasets from bundle (${(code.length / 1024).toFixed(1)} KB)...`);

  // 1. Pandals
  const rawPandals = extractBalancedArray(code, '=[{id:"1",name:"Hatibagan Sarbojanin"');
  if (!rawPandals) {
    throw new Error('Failed to extract pandals array from bundle.');
  }
  console.log(`  - Found ${rawPandals.length} pandals`);

  // 2. Food spots
  const rawFood = extractBalancedArray(code, 'P=[{id:"f1"');
  if (rawFood) console.log(`  - Found ${rawFood.length} food / bhog spots`);

  // 3. Events
  const rawEvents = extractBalancedArray(code, 'B=[{id:"e1"');
  if (rawEvents) console.log(`  - Found ${rawEvents.length} cultural events`);

  // 4. Helplines
  const rawHelplines = extractBalancedArray(code, 'dG=[{label:"Police Helpline"');
  if (rawHelplines) console.log(`  - Found ${rawHelplines.length} emergency helplines`);

  // 5. Safety tips
  const rawSafety = extractBalancedArray(code, 'hG=[{title:"Heat Exhaustion"');
  if (rawSafety) console.log(`  - Found ${rawSafety.length} safety / first-aid guides`);

  console.log('[4/5] Normalizing schema...');
  const seenSlugs = new Map();
  const normalizedPandals = rawPandals.map((item, index) => {
    let baseSlug = slugify(item.name);
    if (!baseSlug) baseSlug = `pandal_${index + 1}`;
    let slug = baseSlug;
    let counter = 1;
    while (seenSlugs.has(slug)) {
      counter++;
      slug = `${baseSlug}_${counter}`;
    }
    seenSlugs.set(slug, true);

    const zone = mapZone(item.region, item.area);
    const nearestMetroStr = Array.isArray(item.nearestMetro) && item.nearestMetro.length > 0
      ? item.nearestMetro.join(', ')
      : null;
    const nearestRailwayStr = Array.isArray(item.nearestRailway) && item.nearestRailway.length > 0
      ? item.nearestRailway.join(', ')
      : null;

    return {
      id: slug,
      source_id: item.id,
      name: item.name.trim(),
      lat: Number(item.coordinates.lat),
      lng: Number(item.coordinates.lng),
      zone: zone,
      area: item.area || '',
      region: item.region || '',
      rating: Number(item.rating) || 0,
      theme: item.theme || 'Traditional',
      crowd_level: (item.crowdLevel || 'Medium').toLowerCase(),
      timings: item.timings || '12:00 AM - 12:00 PM',
      transport: Array.isArray(item.transport) ? item.transport : [],
      nearest_metro: nearestMetroStr,
      nearest_metro_list: Array.isArray(item.nearestMetro) ? item.nearestMetro : [],
      nearest_railway: nearestRailwayStr,
      nearest_railway_list: Array.isArray(item.nearestRailway) ? item.nearestRailway : [],
      special_features: Array.isArray(item.specialFeatures) ? item.specialFeatures : [],
      image_url: '',
      description: item.description || `${item.name} pandal in ${item.area}.`
    };
  });

  console.log('[5/5] Writing files to data/ directory...');
  fs.writeFileSync(path.join(dataDir, 'scraped_pujoplanner_raw.json'), JSON.stringify(rawPandals, null, 2));
  fs.writeFileSync(path.join(dataDir, 'pandals.json'), JSON.stringify(normalizedPandals, null, 2));

  // CSV output
  const headers = [
    'id', 'name', 'lat', 'lng', 'zone', 'area', 'region', 'rating',
    'theme', 'crowd_level', 'timings', 'image_url', 'description',
    'nearest_metro', 'nearest_railway'
  ];
  const csvRows = [headers.join(',')];
  for (const p of normalizedPandals) {
    csvRows.push([
      escapeCsv(p.id),
      escapeCsv(p.name),
      escapeCsv(p.lat),
      escapeCsv(p.lng),
      escapeCsv(p.zone),
      escapeCsv(p.area),
      escapeCsv(p.region),
      escapeCsv(p.rating),
      escapeCsv(p.theme),
      escapeCsv(p.crowd_level),
      escapeCsv(p.timings),
      escapeCsv(p.image_url),
      escapeCsv(p.description),
      escapeCsv(p.nearest_metro),
      escapeCsv(p.nearest_railway)
    ].join(','));
  }
  fs.writeFileSync(path.join(dataDir, 'pandals.csv'), csvRows.join('\n'));

  if (rawFood) fs.writeFileSync(path.join(dataDir, 'food_spots.json'), JSON.stringify(rawFood, null, 2));
  if (rawEvents) fs.writeFileSync(path.join(dataDir, 'events.json'), JSON.stringify(rawEvents, null, 2));
  if (rawHelplines) fs.writeFileSync(path.join(dataDir, 'helplines.json'), JSON.stringify(rawHelplines, null, 2));
  if (rawSafety) fs.writeFileSync(path.join(dataDir, 'safety_first_aid.json'), JSON.stringify(rawSafety, null, 2));

  console.log(`\nSuccessfully scraped and saved ${normalizedPandals.length} pandals!`);
}

scrape().catch((err) => {
  console.error('Scraping error:', err);
  process.exit(1);
});
