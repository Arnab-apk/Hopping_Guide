import fs from 'fs';

const currentPandals = JSON.parse(fs.readFileSync('app/assets/data/pandals.json', 'utf8'));
const kmlDump = fs.readFileSync('scripts/thepujo_dump.kml', 'utf8');

// Parse thepujo KML
const placemarkRegex = /<Placemark>([\s\S]*?)<\/Placemark>/g;
let pMatch;
const thepujoPandals = [];

while ((pMatch = placemarkRegex.exec(kmlDump)) !== null) {
  const pContent = pMatch[1];
  const nameMatch = pContent.match(/<name>(.*?)<\/name>/);
  const descMatch = pContent.match(/<description>([\s\S]*?)<\/description>/);
  const coordMatch = pContent.match(/<coordinates>\s*([^\s<]+)\s*<\/coordinates>/);

  const name = nameMatch ? nameMatch[1].trim() : '';
  const description = descMatch ? descMatch[1].trim() : '';
  const coordsRaw = coordMatch ? coordMatch[1].trim() : '';
  const parts = coordsRaw.split(',');
  const lng = parseFloat(parts[0]);
  const lat = parseFloat(parts[1]);

  if (name && !isNaN(lat) && !isNaN(lng)) {
    thepujoPandals.push({ name, description, lat, lng });
  }
}

console.log('Current pandals count:', currentPandals.length);
console.log('ThePujo scraped count:', thepujoPandals.length);

// Analyze current pandals
const pujoplanner = currentPandals.filter(p => !p.source_id || !p.source_id.startsWith('csv_'));
const csvPandals = currentPandals.filter(p => p.source_id && p.source_id.startsWith('csv_'));

console.log('Pujoplanner (original curated):', pujoplanner.length);
console.log('CSV pandals:', csvPandals.length);

// Let's see some CSV pandals
console.log('\nSample 5 CSV pandals:');
console.log(JSON.stringify(csvPandals.slice(0, 5).map(p => ({
  id: p.id,
  name: p.name,
  lat: p.lat,
  lng: p.lng,
  area: p.area,
  nearest_metro: p.nearest_metro
})), null, 2));

// Check name overlaps between thepujo and currentPandals
function norm(str) {
  return (str || '').toLowerCase().replace(/[^a-z0-9]/g, '');
}

const currentNormMap = new Map();
currentPandals.forEach(p => {
  currentNormMap.set(norm(p.name), p);
});

let matchedCount = 0;
let newCount = 0;
const matchedNames = [];
const newNames = [];

thepujoPandals.forEach(tp => {
  const n = norm(tp.name);
  if (currentNormMap.has(n)) {
    matchedCount++;
    matchedNames.push({ thepujo: tp.name, current: currentNormMap.get(n).name });
  } else {
    newCount++;
    newNames.push(tp.name);
  }
});

console.log('\nThePujo vs Current:');
console.log('Direct exact normalized matches:', matchedCount);
console.log('Brand new unique to ThePujo:', newCount);
console.log('Sample matched:', matchedNames.slice(0, 5));
console.log('Sample new from ThePujo:', newNames.slice(0, 10));

// Check distance of coordinates for matched
function haversineM(lat1, lon1, lat2, lon2) {
  const R = 6371e3;
  const phi1 = lat1 * Math.PI / 180;
  const phi2 = lat2 * Math.PI / 180;
  const dphi = (lat2 - lat1) * Math.PI / 180;
  const dlam = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(dphi/2)**2 + Math.cos(phi1)*Math.cos(phi2)*Math.sin(dlam/2)**2;
  return 2 * R * Math.asin(Math.sqrt(a));
}

let driftSum = 0;
let countWithDrift = 0;
matchedNames.slice(0, 50).forEach(m => {
  const curr = currentNormMap.get(norm(m.current));
  const tp = thepujoPandals.find(p => norm(p.name) === norm(m.thepujo));
  if (curr && tp) {
    const d = haversineM(curr.lat, curr.lng, tp.lat, tp.lng);
    driftSum += d;
    countWithDrift++;
  }
});
console.log(`Average coordinate difference for top matches: ${(driftSum / countWithDrift).toFixed(1)} meters`);
