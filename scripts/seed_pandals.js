// Seeds the curated pandal CSV into Firestore.
// Usage:
//   1) npm install                          (in this scripts/ folder)
//   2) export FIREBASE_PROJECT_ID=<proj>   (Windows: $env:FIREBASE_PROJECT_ID=...)
//   3) npm run seed                         (use `seed:dry` to preview first)
//
// Auth: uses the firebase-admin SDK. For the Spark (free) plan, run this on a
// machine where you've run `firebase login` so Application Default Credentials
// are available, OR set GOOGLE_APPLICATION_CREDENTIALS to a service-account
// key JSON (do NOT commit that key).
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { parse } from 'csv-parse/sync';
import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const __dirname = dirname(fileURLToPath(import.meta.url));
const csvPath = join(__dirname, '..', 'data', 'pandals.csv');
const dryRun = process.argv.includes('--dry-run');

const records = parse(readFileSync(csvPath, 'utf8'), {
  columns: true,
  skip_empty_lines: true,
  trim: true,
});

console.log(`Parsed ${records.length} pandal rows from ${csvPath}`);
if (dryRun) {
  console.log('--dry-run: not writing to Firestore.\n');
  console.table(records.map((r) => ({ id: r.id, name: r.name, zone: r.zone })));
  process.exit(0);
}

const projectId = process.env.FIREBASE_PROJECT_ID;
const app = initializeApp({ credential: applicationDefault(), projectId });
const db = getFirestore(app);
const batch = db.batch();

for (const r of records) {
  const docRef = db.collection('pandals').doc(r.id);
  batch.set(docRef, {
    name: r.name,
    lat: Number(r.lat),
    lng: Number(r.lng),
    zone: r.zone,
    theme: r.theme,
    timings: r.timings,
    image_url: r.image_url,
    description: r.description,
    nearest_metro: r.nearest_metro || null,
  });
}

await batch.commit();
console.log(`Seeded ${records.length} pandals into Firestore collection 'pandals'.`);
