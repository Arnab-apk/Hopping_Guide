const fs = require('node:fs');

// User-supplied Chinsurah locations, including shared pins for grouped venues.
const locations = [
  ['chinsurah_azad_hind_club', 'Chuchura Azad Hind Club', 22.8839, 88.3745, 'Pearabagan / Chinsurah Station Road', 'Nationalist and Historical Themes', 'One of Chinsurah\'s largest crowd-pullers, known for grand nationalist and historical concepts, including a Vande Mataram tribute.'],
  ['chinsurah_chapatala_sarbojanin', 'Chapatala Sarbojanin Durgotsav', 22.8882, 88.3845, 'Netaji Subhas Road, Chapatala More', 'Cultural Icons and Heritage', 'A historic community puja with over 80 years of celebrations, known for tributes to cultural icons such as Bengali actor Uttam Kumar.'],
  ['chinsurah_panchanantala_sarbojonin', 'Panchanantala Sarbojanin', 22.8879, 88.3814, 'Kamarpara Road, near Deshbandhu School', 'Artistic Themes and Tranquility', 'Renowned for artistic aesthetics exploring tranquility, including the concept Snigdhato.'],
  ['chinsurah_rathtala_durgotsav', 'Chuchura Rathtala Durgotsav', 22.8861, 88.3721, 'Rathtala More', 'Traditional Architecture and Lighting', 'Known for traditional architectural decor and high-energy ambient lighting near Rathtala More.'],
  ['chinsurah_peyarabagan_sarbojanin', 'Peyara Bagan Sarbojanin', 22.8821, 88.3752, 'Pearabagan', 'Social Messages and Modern Theme Crafts', 'A popular community puja integrating social messages into complex modern theme crafts.'],
  ['chinsurah_akhan_bazar_durga_puja', 'Akhan Bazar Durga Puja', 22.8967, 88.3871, 'Akhan Bazar', 'Decorative Lighting', 'A commercial-belt puja drawing heavy foot traffic with massive decorative lighting panels.'],
  ['chinsurah_karbala_more_durgotsav', 'Karbala More Durgotsav Committee', 22.8941, 88.3789, 'Karbala More, towards Pipulpati', 'Community Durga Puja', 'A prominent gateway puja at the Karbala More intersection on the northern side of Chinsurah towards Pipulpati.'],
  ['chinsurah_chokbaazar_sarbojanin', 'Chokbaazar Sarbojanin', 22.8912, 88.3908, 'Chokbaazar', 'Environmental and Rural Themes', 'Known for environmentally conscious and rural-focused themes, including Jol Jongol Jomi Jibon.'],
  ['chinsurah_tola_phatak_sarbojanin', 'Tola Phatak Sarbojanin', 22.8845, 88.3894, 'Near Tola Phatak bus stop', 'Community Durga Puja', 'Located just off the main road near Tola Phatak bus stop, making it a convenient early stop during a puja parikrama.'],
  ['chinsurah_pirtala_sarbojanin', 'Beguntala & Pirtala More', 22.8890, 88.3795, 'Beguntala / Pirtala More', 'Clay Art and Community Celebration', 'Neighborhood favorites featuring beautiful clay structures and vibrant community involvement. This shared area pin represents Beguntala and Pirtala More.'],
  ['bandel_keota_nabin_sangha', 'Keota Ujjwal Sangha & Nabin Sangha', 22.9095, 88.3820, 'Keota, towards Bandel', 'Grand Community Pandals', 'Community pandals on the outskirts towards Bandel, known for their grand scale. This shared neighborhood pin represents Keota Ujjwal Sangha and Nabin Sangha.'],
  ['chinsurah_adhya_bari_bonedi', 'Adhya Bari (Kamarpara)', 22.8885, 88.3821, 'Kamarpara lane', 'Bonedi Bari - Hara-Gauri Idol', 'A heritage household puja with nearly 300 years of history, worshipping a rare Hara-Gauri (Shiva-Durga) idol without Mahishasura.'],
  ['chinsurah_mondal_bari_bonedi', 'Mondal Bari (Kamarpara)', 22.8881, 88.3819, 'Kamarpara, near Panchanantala', 'Bonedi Bari - Traditional Household Rituals', 'A heritage household puja over 185 years old, with historical links to India\'s freedom struggle and visits by Netaji Subhas Chandra Bose and Mahatma Gandhi.'],
  ['chinsurah_halder_bari_bonedi', 'Halder Bari (Sandeshwar Tala)', 22.8928, 88.3925, 'Sandeshwar Tala, near the temple ghat', 'Bonedi Bari - Mahishasuramardini Idol', 'A heritage household puja over 450 years old. The Vaishnava family worships Mahishasuramardini and substitutes animal sacrifices with a wax gourd.'],
];

const stations = JSON.parse(fs.readFileSync('data/stations/stations.geojson', 'utf8')).features;
function nearby(lat, lng) {
  const rad = n => n * Math.PI / 180;
  return stations.filter(s => s.geometry?.coordinates?.length >= 2).map(s => {
    const [lon, latitude] = s.geometry.coordinates;
    const a = Math.sin(rad(latitude - lat) / 2) ** 2 + Math.cos(rad(lat)) * Math.cos(rad(latitude)) * Math.sin(rad(lon - lng) / 2) ** 2;
    const p = s.properties;
    return {id: s.id || p.id, name: p.name, name_bn: p.name_bn ?? null, code: p.code ?? null, kind: p.kind, distance_m: Math.round(6371000 * 2 * Math.asin(Math.sqrt(a)))};
  }).sort((a, b) => a.distance_m - b.distance_m).slice(0, 3);
}

for (const path of ['app/assets/data/pandals.json', 'data/pandals.json']) {
  const pandals = JSON.parse(fs.readFileSync(path, 'utf8'));
  let added = 0;
  for (const [id, name, lat, lng, neighborhood, theme, description] of locations) {
    let p = pandals.find(p => p.id === id);
    if (!p) {
      p = {id, name, lat, lng, zone: 'hooghlyChinsurah', area: '', region: 'Hooghly', theme, timings: 'Visiting hours not confirmed', transport: [], nearest_metro: null, nearest_metro_list: [], nearest_railway: null, nearest_railway_list: [], special_features: [], image_url: '', description, category: 'pandal'};
      pandals.push(p);
      added++;
    }
    Object.assign(p, {name, lat, lng, area: `${neighborhood}, Chinsurah`, theme, description, special_features: [theme], nearest_stations: nearby(lat, lng)});
  }
  fs.writeFileSync(path, JSON.stringify(pandals, null, 2));
  console.log(`${path}: ${added} added, ${locations.length - added} updated, ${pandals.length} total`);
}

// Preserve untouched CSV rows and keep the seed fallback aligned with JSON.
const pandals = JSON.parse(fs.readFileSync('data/pandals.json', 'utf8'));
const csvPath = 'data/pandals.csv';
const lines = fs.readFileSync(csvPath, 'utf8').split(/\r?\n/);
const columns = lines[0].split(',');
for (const [id] of locations) {
  const p = pandals.find(p => p.id === id);
  const row = columns.map(key => {
    const value = key === 'transport' ? (p[key] || []).join('; ') : p[key] ?? '';
    return typeof value === 'number' ? value : `"${String(value).replace(/"/g, '""')}"`;
  }).join(',');
  const i = lines.findIndex(line => line.startsWith(`"${id}",`));
  if (i >= 0) lines[i] = row;
  else if (lines.at(-1) === '') lines.splice(lines.length - 1, 0, row);
  else lines.push(row);
}
fs.writeFileSync(csvPath, lines.join('\n'));
