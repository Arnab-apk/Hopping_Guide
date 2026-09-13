const fs = require('fs');

// Read existing pandals
const existing = JSON.parse(fs.readFileSync('app/assets/data/pandals.json', 'utf8'));
console.log('Existing pandals count:', existing.length);
const existingNames = new Set(existing.map(p => p.name.toLowerCase().trim()));

// Read CSV
const csv = fs.readFileSync('C:/Users/arnab/.gemini/antigravity-ide/brain/977ebf11-fb23-4bc9-9ab7-6215d226bcea/.user_uploaded/media_1789314880029.csv', 'utf8');

function parseCSV(text) {
  const lines = text.trim().split(/\r?\n/);
  const rows = [];
  for (let i = 1; i < lines.length; i++) {
    const line = lines[i].trim();
    if (!line) continue;
    const row = [];
    let inQuotes = false;
    let field = '';
    for (let c = 0; c < line.length; c++) {
      const char = line[c];
      if (char === '"') {
        if (inQuotes && line[c + 1] === '"') {
          field += '"';
          c++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char === ',' && !inQuotes) {
        row.push(field);
        field = '';
      } else {
        field += char;
      }
    }
    row.push(field);
    rows.push(row);
  }
  return rows;
}

const rows = parseCSV(csv);
console.log('Total parsed CSV rows:', rows.length);

const uniqueInCsv = new Map();
const duplicatesInCsv = [];
const overlapsWithExisting = [];

for (const r of rows) {
  const [pandal_id, name, theme, location, description, year_established, avg_rating] = r;
  if (!name) continue;
  const norm = name.toLowerCase().trim();
  if (existingNames.has(norm)) {
    overlapsWithExisting.push(name);
  } else if (uniqueInCsv.has(norm)) {
    duplicatesInCsv.push(name);
  } else {
    uniqueInCsv.set(norm, {
      pandal_id: parseInt(pandal_id) || 0,
      name: name.trim(),
      theme: (theme || 'Traditional').trim(),
      location: (location || 'Central Kolkata').trim(),
      description: (description || '').trim(),
      year_established: parseInt(year_established) || 1990,
      avg_rating: parseFloat(avg_rating) || 4.2
    });
  }
}

console.log('Unique new pandal names from CSV:', uniqueInCsv.size);
console.log('Duplicate rows within CSV:', duplicatesInCsv.length);
console.log('Overlaps with existing 117 pandals:', overlapsWithExisting.length);

const locations = new Set();
for (const v of uniqueInCsv.values()) {
  locations.add(v.location);
}
console.log('Locations found:', Array.from(locations));

// Look at some sample base names
const baseNames = new Set();
for (const v of uniqueInCsv.values()) {
  const base = v.name.replace(/\s+\d+$/, '').trim();
  baseNames.add(base);
}
console.log('Total unique base area names:', baseNames.size);
console.log('Sample base area names:', Array.from(baseNames).slice(0, 20));
