import fs from 'fs';
import path from 'path';

const ASSET_PANDALS_JSON = 'app/assets/data/pandals.json';
const DATA_PANDALS_JSON = 'data/pandals.json';
const DATA_PANDALS_CSV = 'data/pandals.csv';
const THEPUJO_JSON = 'data/thepujo_scraped.json';

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

function clean(s) {
  return (s || '')
    .toLowerCase()
    .replace(
      /durgotsab|sarbojanin|sarbojonin|sarbajanin|durgotsav|durgapuja|durga puja|committee|association/g,
      ''
    )
    .replace(/[^a-z0-9]/g, '')
    .trim();
}

export function mergeDatasets() {
  console.log('--- Merging Authentic Kolkata Durga Puja Datasets ---');

  // 1. Read existing pandals, extracting the authentic PujoPlanner entries (exclude synthetic csv_ entries)
  const existingRaw = JSON.parse(fs.readFileSync(ASSET_PANDALS_JSON, 'utf8'));
  const authenticPujoplanner = existingRaw.filter(
    p => !p.source_id || !p.source_id.startsWith('csv_')
  );
  console.log(`Loaded ${authenticPujoplanner.length} curated PujoPlanner pandals (purged ${existingRaw.length - authenticPujoplanner.length} synthetic CSV entries).`);

  // 2. Read ThePujo scraped pandals
  if (!fs.existsSync(THEPUJO_JSON)) {
    throw new Error(`Scraped data file ${THEPUJO_JSON} not found. Run scrape_thepujo.mjs first.`);
  }
  const thepujoPandals = JSON.parse(fs.readFileSync(THEPUJO_JSON, 'utf8'));
  console.log(`Loaded ${thepujoPandals.length} verified pandals from ThePujo.com.`);

  // 3. GIS + Name Deduplication
  const finalPandals = [];
  const matchedThePujoIds = new Set();

  let mergedCount = 0;
  let coordinateUpdatedCount = 0;

  for (const pp of authenticPujoplanner) {
    const cpp = clean(pp.name);
    let bestMatch = null;
    let minD = Infinity;

    for (const tp of thepujoPandals) {
      const ctp = clean(tp.name);
      const d = haversineMeters(pp.lat, pp.lng, tp.lat, tp.lng);
      const exact = cpp === ctp;
      const sub = (cpp.includes(ctp) || ctp.includes(cpp)) && d < 350;

      if (exact || sub) {
        if (d < minD) {
          minD = d;
          bestMatch = tp;
        }
      }
    }

    if (bestMatch) {
      matchedThePujoIds.add(bestMatch.id);
      mergedCount++;

      // Retain rich PujoPlanner metadata, but update coordinates to ThePujo's high-precision map pin
      const updatedPandal = {
        ...pp,
        lat: bestMatch.lat,
        lng: bestMatch.lng,
        // If PujoPlanner had generic description, enrich with ThePujo
        description:
          pp.description && pp.description.length > 30
            ? pp.description
            : bestMatch.description || pp.description,
        special_features: Array.from(
          new Set([...(pp.special_features || []), ...(bestMatch.special_features || [])])
        )
      };

      if (minD > 5) coordinateUpdatedCount++;
      finalPandals.push(updatedPandal);
    } else {
      // Keep unique PujoPlanner pandal as-is
      finalPandals.push(pp);
    }
  }

  // 4. Add remaining ThePujo pandals that were not matched
  let newAddedCount = 0;
  for (const tp of thepujoPandals) {
    if (!matchedThePujoIds.has(tp.id)) {
      // Check if another pandal in finalPandals already has virtually identical name and location
      const ctp = clean(tp.name);
      const isDupe = finalPandals.some(
        fp => clean(fp.name) === ctp && haversineMeters(fp.lat, fp.lng, tp.lat, tp.lng) < 100
      );

      if (!isDupe) {
        finalPandals.push(tp);
        newAddedCount++;
      }
    }
  }

  console.log(`\n--- Merge Summary ---`);
  console.log(`PujoPlanner Base: ${authenticPujoplanner.length}`);
  console.log(`ThePujo Scraped: ${thepujoPandals.length}`);
  console.log(`Overlapping Pandals Merged: ${mergedCount} (${coordinateUpdatedCount} updated with high-precision GPS)`);
  console.log(`Newly Added Genuine Pandals from ThePujo: ${newAddedCount}`);
  console.log(`Total Final Verified Non-Redundant Pandals: ${finalPandals.length}`);

  // 5. Sort alphabetically by name for deterministic ordering
  finalPandals.sort((a, b) => (a.name || '').localeCompare(b.name || ''));

  // 6. Write JSON files
  fs.writeFileSync(ASSET_PANDALS_JSON, JSON.stringify(finalPandals, null, 2));
  console.log(`Wrote ${ASSET_PANDALS_JSON} (${(fs.statSync(ASSET_PANDALS_JSON).size / 1024).toFixed(1)} KB)`);

  fs.mkdirSync('data', { recursive: true });
  fs.writeFileSync(DATA_PANDALS_JSON, JSON.stringify(finalPandals, null, 2));
  console.log(`Wrote ${DATA_PANDALS_JSON}`);

  // 7. Write CSV file
  const csvHeaders = [
    'id',
    'name',
    'lat',
    'lng',
    'zone',
    'area',
    'region',
    'rating',
    'theme',
    'crowd_level',
    'timings',
    'nearest_metro',
    'nearest_railway',
    'transport',
    'description'
  ];

  const csvRows = [csvHeaders.join(',')];
  for (const p of finalPandals) {
    const row = [
      `"${p.id || ''}"`,
      `"${(p.name || '').replace(/"/g, '""')}"`,
      p.lat,
      p.lng,
      `"${p.zone || ''}"`,
      `"${(p.area || '').replace(/"/g, '""')}"`,
      `"${p.region || ''}"`,
      p.rating || 4.5,
      `"${(p.theme || '').replace(/"/g, '""')}"`,
      `"${p.crowd_level || ''}"`,
      `"${p.timings || ''}"`,
      `"${(p.nearest_metro || '').replace(/"/g, '""')}"`,
      `"${(p.nearest_railway || '').replace(/"/g, '""')}"`,
      `"${(p.transport || []).join('; ')}"`,
      `"${(p.description || '').replace(/"/g, '""')}"`
    ];
    csvRows.push(row.join(','));
  }

  fs.writeFileSync(DATA_PANDALS_CSV, csvRows.join('\n'));
  console.log(`Wrote ${DATA_PANDALS_CSV}`);

  return finalPandals;
}

mergeDatasets();
