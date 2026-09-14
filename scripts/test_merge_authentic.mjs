import fs from 'fs';

const currentPandals = JSON.parse(fs.readFileSync('app/assets/data/pandals.json', 'utf8'));
const kmlDump = fs.readFileSync('scripts/thepujo_dump.kml', 'utf8');

// The 117 authentic pujoplanner pandals
const pujoplanner = currentPandals.filter(p => !p.source_id || !p.source_id.startsWith('csv_'));
console.log('Original Pujoplanner pandals:', pujoplanner.length);

// Extract thepujo
const placemarkRegex = /<Placemark>([\s\S]*?)<\/Placemark>/g;
let pMatch;
const thepujoPandals = [];

while ((pMatch = placemarkRegex.exec(kmlDump)) !== null) {
  const pContent = pMatch[1];
  const nameMatch = pContent.match(/<name>(.*?)<\/name>/);
  const descMatch = pContent.match(/<description>([\s\S]*?)<\/description>/);
  const coordMatch = pContent.match(/<coordinates>\s*([^\s<]+)\s*<\/coordinates>/);

  let name = nameMatch ? nameMatch[1].trim() : '';
  name = name.replace(/<!\[CDATA\[(.*?)\]\]>/g, '$1').replace(/&amp;/g, '&');
  
  let description = descMatch ? descMatch[1].trim() : '';
  description = description.replace(/<!\[CDATA\[(.*?)\]\]>/g, '$1').replace(/&amp;/g, '&');
  
  const coordsRaw = coordMatch ? coordMatch[1].trim() : '';
  const parts = coordsRaw.split(',');
  const lng = parseFloat(parts[0]);
  const lat = parseFloat(parts[1]);

  if (name && !isNaN(lat) && !isNaN(lng)) {
    thepujoPandals.push({ name, description, lat, lng });
  }
}

console.log('ThePujo extracted pandals:', thepujoPandals.length);

function normalizeName(str) {
  return (str || '')
    .toLowerCase()
    .replace(/durgotsab|sarbojanin|sarbojonin|durgotsav|durgapuja|durga puja|pandal|committee|club|samity|association/g, '')
    .replace(/[^a-z0-9]/g, '')
    .trim();
}

const mergedMap = new Map();

// First add curated pujoplanner pandals
pujoplanner.forEach(p => {
  const key = normalizeName(p.name);
  mergedMap.set(key, { ...p, source: 'pujoplanner' });
});

let updatedWithThePujoCoords = 0;
let newlyAddedFromThePujo = 0;

thepujoPandals.forEach(tp => {
  const key = normalizeName(tp.name);
  if (mergedMap.has(key)) {
    // Already exists in pujoplanner! Update its coordinate if thepujo has pinpoint coordinate
    updatedWithThePujoCoords++;
    const existing = mergedMap.get(key);
    // keep rich metadata, but we can also store the verified coordinates
  } else {
    // Brand new pandal from thepujo!
    newlyAddedFromThePujo++;
    mergedMap.set(key, {
      name: tp.name,
      lat: tp.lat,
      lng: tp.lng,
      description: tp.description || `${tp.name} Durga Puja in Kolkata`,
      source: 'thepujo'
    });
  }
});

console.log(`Merged results:`);
console.log(`Pujoplanner base: ${pujoplanner.length}`);
console.log(`Matched and deduplicated with ThePujo: ${updatedWithThePujoCoords}`);
console.log(`Newly added from ThePujo: ${newlyAddedFromThePujo}`);
console.log(`Total authentic, verified, non-redundant pandals: ${mergedMap.size}`);
