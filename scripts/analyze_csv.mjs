import fs from 'fs';

const csvPath = 'C:/Users/arnab/.gemini/antigravity-ide/brain/977ebf11-fb23-4bc9-9ab7-6215d226bcea/.user_uploaded/media_1789314880029.csv';
const csvContent = fs.readFileSync(csvPath, 'utf8');
const existing = JSON.parse(fs.readFileSync('app/assets/data/pandals.json', 'utf8'));
const existingNames = new Set(existing.map(p => p.name.trim().toLowerCase()));

function parseCSV(text) {
  const rows = [];
  let row = [];
  let current = '';
  let inQuotes = false;
  for (let i = 0; i < text.length; i++) {
    const c = text[i];
    if (c === '"') {
      if (inQuotes && text[i+1] === '"') {
        current += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (c === ',' && !inQuotes) {
      row.push(current.trim());
      current = '';
    } else if ((c === '\r' || c === '\n') && !inQuotes) {
      if (c === '\r' && text[i+1] === '\n') i++;
      row.push(current.trim());
      if (row.length > 1 || (row.length === 1 && row[0] !== '')) {
        rows.push(row);
      }
      row = [];
      current = '';
    } else {
      current += c;
    }
  }
  if (current.length > 0 || row.length > 0) {
    row.push(current.trim());
    rows.push(row);
  }
  return rows;
}

const rows = parseCSV(csvContent);
const header = rows[0];
const data = rows.slice(1);
console.log('Header:', header);
console.log('Total data rows:', data.length);

const seenNames = new Set();
const duplicateRowsInCsv = [];
const duplicateWithExisting = [];
const uniqueNewRows = [];

for (const r of data) {
  const name = r[1];
  if (!name) continue;
  const norm = name.toLowerCase().replace(/\s+/g, ' ');
  if (existingNames.has(norm)) {
    duplicateWithExisting.push(name);
  } else if (seenNames.has(norm)) {
    duplicateRowsInCsv.push(name);
  } else {
    seenNames.add(norm);
    uniqueNewRows.push(r);
  }
}

console.log('Duplicate rows within CSV:', duplicateRowsInCsv.length);
console.log('Sample duplicates in CSV:', duplicateRowsInCsv.slice(0, 10));
console.log('Duplicates matching existing curated:', duplicateWithExisting.length, duplicateWithExisting.slice(0, 10));
console.log('Unique new rows to add:', uniqueNewRows.length);

const locations = new Set();
const themes = new Set();
const baseAreas = new Map();

for (const r of uniqueNewRows) {
  themes.add(r[2]);
  locations.add(r[3]);
  const m = r[1].match(/^(.+?)\s+\d+$/);
  const base = m ? m[1] : r[1];
  baseAreas.set(base, (baseAreas.get(base) || 0) + 1);
}

console.log('Locations in CSV:', Array.from(locations));
console.log('Themes in CSV:', Array.from(themes));
console.log('Base areas count:', baseAreas.size);
console.log('Top 30 Base areas:', Array.from(baseAreas.entries()).sort((a,b) => b[1] - a[1]).slice(0, 30));
