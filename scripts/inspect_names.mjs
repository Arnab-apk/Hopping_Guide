import fs from 'fs';

const existing = JSON.parse(fs.readFileSync('app/assets/data/pandals.json', 'utf8'));

console.log('--- ALL EXISTING PANDALS ---');
existing.forEach((p, i) => {
  console.log(`${i + 1}. [${p.id}] "${p.name}" | zone: ${p.zone} | lat: ${p.lat}, lng: ${p.lng}`);
});
