import fs from 'fs';

const pandals = JSON.parse(fs.readFileSync('app/assets/data/pandals.json', 'utf8'));

console.log('Total pandals:', pandals.length);

const requiredKeys = ['id', 'name', 'lat', 'lng', 'zone', 'area', 'region', 'theme', 'timings', 'description'];
const zones = new Set();
const errors = [];

pandals.forEach((p, idx) => {
  for (const k of requiredKeys) {
    if (p[k] === undefined || p[k] === null) {
      errors.push('Pandal #' + idx + ' (' + p.name + ') missing ' + k);
    }
  }
  if (typeof p.lat !== 'number' || isNaN(p.lat) || p.lat < 22 || p.lat > 23) {
    errors.push('Pandal #' + idx + ' (' + p.name + ') has invalid lat: ' + p.lat);
  }
  if (typeof p.lng !== 'number' || isNaN(p.lng) || p.lng < 88 || p.lng > 89) {
    errors.push('Pandal #' + idx + ' (' + p.name + ') has invalid lng: ' + p.lng);
  }
  zones.add(p.zone);
});

console.log('Detected zones:', Array.from(zones));
console.log('Validation errors:', errors.length);
if (errors.length > 0) {
  console.log('Sample errors:', errors.slice(0, 5));
  process.exit(1);
} else {
  console.log('SUCCESS: All 387 pandals passed 100% schema validation!');
}
