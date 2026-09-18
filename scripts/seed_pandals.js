// Seeds curated and scraped pandals into Firestore.
// Usage:
//   1) npm install                          (in this scripts/ folder)
//   2) export FIREBASE_PROJECT_ID=<proj>   (Windows: $env:FIREBASE_PROJECT_ID=...)
//   3) npm run seed                         (use `seed:dry` to preview first)
//
// Reads data/pandals.json if present, otherwise falls back to data/pandals.csv.
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const jsonPath = join(__dirname, '..', 'data', 'pandals.json');
const csvPath = join(__dirname, '..', 'data', 'pandals.csv');
const dryRun = process.argv.includes('--dry-run');

let records = [];

if (existsSync(jsonPath)) {
  records = JSON.parse(readFileSync(jsonPath, 'utf8'));
  console.log(`Loaded ${records.length} pandals from ${jsonPath}`);
} else if (existsSync(csvPath)) {
  records = parse(readFileSync(csvPath, 'utf8'), {
    columns: true,
    skip_empty_lines: true,
    trim: true,
  });
  console.log(`Parsed ${records.length} pandal rows from ${csvPath}`);
} else {
  console.error('No pandal data file found in data/ directory.');
  process.exit(1);
}

if (dryRun) {
  console.log('--dry-run: not writing to Firestore.\n');
  console.table(
    records.slice(0, 15).map((r) => ({
      id: r.id,
      name: r.name,
      zone: r.zone,
      rating: r.rating,
      crowd: r.crowd_level,
      metro: r.nearest_metro,
    }))
  );
  console.log(`... and ${Math.max(0, records.length - 15)} more pandals.`);
  process.exit(0);
}

const projectId = process.env.FIREBASE_PROJECT_ID;
const app = initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore(app);

// Firestore batches are limited to 500 operations per batch
const BATCH_SIZE = 400;
for (let i = 0; i < records.length; i += BATCH_SIZE) {
  const chunk = records.slice(i, i + BATCH_SIZE);
  const batch = db.batch();

  for (const r of chunk) {
    const docRef = db.collection('pandals').doc(r.id);
    batch.set(docRef, {
      name: r.name,
      category: r.category || 'pandal',
      lat: Number(r.lat),
      lng: Number(r.lng),
      zone: r.zone,
      area: r.area || null,
      region: r.region || null,
      rating: r.rating != null ? Number(r.rating) : null,
      theme: r.theme || 'Traditional',
      crowd_level: r.crowd_level || null,
      timings: r.timings || null,
      image_url: r.image_url || '',
      description: r.description || '',
      transport: Array.isArray(r.transport) ? r.transport : [],
      nearest_metro: r.nearest_metro || null,
      nearest_metro_list: Array.isArray(r.nearest_metro_list) ? r.nearest_metro_list : [],
      nearest_railway: r.nearest_railway || null,
      nearest_railway_list: Array.isArray(r.nearest_railway_list) ? r.nearest_railway_list : [],
      special_features: Array.isArray(r.special_features) ? r.special_features : [],
    });
  }

  await batch.commit();
  console.log(`Committed batch of ${chunk.length} pandals.`);
}

console.log(`Successfully seeded ${records.length} pandals into Firestore collection 'pandals'.`);
