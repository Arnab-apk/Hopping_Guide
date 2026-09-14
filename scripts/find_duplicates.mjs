import fs from 'fs';

const pandals = JSON.parse(fs.readFileSync('app/assets/data/pandals.json', 'utf8'));

console.log('Total pandals loaded:', pandals.length);

// 1. Exact Name Matches (case-insensitive, trimmed)
const nameMap = new Map();
const exactDupes = new Map();

for (const p of pandals) {
  const normName = (p.name || '').trim().toLowerCase();
  if (!nameMap.has(normName)) {
    nameMap.set(normName, []);
  }
  nameMap.get(normName).push(p);
}

for (const [name, list] of nameMap.entries()) {
  if (list.length > 1) {
    exactDupes.set(name, list);
  }
}

console.log(`\n--- Exact Name Duplicates found: ${exactDupes.size} ---`);
for (const [name, list] of exactDupes.entries()) {
  console.log(`\nName: "${list[0].name}" (count: ${list.length})`);
  list.forEach((p, i) => {
    console.log(`  [${i + 1}] ID: ${p.id} | Zone: ${p.zone} | Area: ${p.area} | Lat: ${p.lat}, Lng: ${p.lng} | Metro: ${p.nearestMetro} | HasImg: ${!!p.imageUrl}`);
  });
}

// 2. Exact ID Duplicates
const idMap = new Map();
for (const p of pandals) {
  const id = p.id;
  if (!idMap.has(id)) {
    idMap.set(id, []);
  }
  idMap.get(id).push(p);
}
const idDupes = Array.from(idMap.entries()).filter(([_, list]) => list.length > 1);
console.log(`\n--- Exact ID Duplicates found: ${idDupes.length} ---`);
for (const [id, list] of idDupes) {
  console.log(`  ID: ${id} count: ${list.length} names: ${list.map(p => p.name).join(', ')}`);
}

// 3. Coordinate Proximity (distance < 50 meters)
function getDistanceMeters(lat1, lon1, lat2, lon2) {
  const R = 6371e3; // meters
  const phi1 = lat1 * Math.PI / 180;
  const phi2 = lat2 * Math.PI / 180;
  const deltaPhi = (lat2 - lat1) * Math.PI / 180;
  const deltaLambda = (lon2 - lon1) * Math.PI / 180;
  const a = Math.sin(deltaPhi / 2) * Math.sin(deltaPhi / 2) +
            Math.cos(phi1) * Math.cos(phi2) *
            Math.sin(deltaLambda / 2) * Math.sin(deltaLambda / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c;
}

console.log('\n--- Coordinate proximity (< 50m) with similar names ---');
for (let i = 0; i < pandals.length; i++) {
  for (let j = i + 1; j < pandals.length; j++) {
    const p1 = pandals[i];
    const p2 = pandals[j];
    const dist = getDistanceMeters(p1.lat, p1.lng, p2.lat, p2.lng);
    if (dist < 50) {
      console.log(`Distance ${dist.toFixed(1)}m: "${p1.name}" (${p1.id}) vs "${p2.name}" (${p2.id})`);
    }
  }
}

// 4. Normalized Name Comparison (ignoring common suffixes/words)
function cleanName(name) {
  return name.toLowerCase()
    .replace(/\b(sarbojanin|durgotsav|durgotsab|puja|committee|samity|club|association|sarbajanin|pujo)\b/g, '')
    .replace(/[^a-z0-9]/g, '')
    .trim();
}

console.log('\n--- Fuzzy / Normalized Name Matches ---');
const cleanMap = new Map();
for (const p of pandals) {
  const cn = cleanName(p.name);
  if (cn.length < 3) continue;
  if (!cleanMap.has(cn)) {
    cleanMap.set(cn, []);
  }
  cleanMap.get(cn).push(p);
}

for (const [cn, list] of cleanMap.entries()) {
  if (list.length > 1) {
    // Only print if not already identical in exactDupes
    const names = new Set(list.map(p => p.name.trim().toLowerCase()));
    if (names.size > 1) {
      console.log(`\nClean token: "${cn}"`);
      list.forEach(p => {
        console.log(`  - "${p.name}" (ID: ${p.id}, Zone: ${p.zone}, Lat: ${p.lat.toFixed(4)}, Lng: ${p.lng.toFixed(4)})`);
      });
    }
  }
}
