// Read-only OSM query; never writes to app assets or a remote database.
const fs = require('node:fs');
const path = require('node:path');
const output = path.join(__dirname, 'data', 'coordinate_osm_source.json');
const queries = [
  '[out:json][timeout:25];node[railway=station](22.15,88.05,23.2,88.7);out body;',
  '[out:json][timeout:25];nwr[amenity=toilets](22.3,88.15,23.1,88.6);out center tags;',
  '[out:json][timeout:25];nwr[amenity~"restaurant|cafe|fast_food"][name](22.3,88.15,23.1,88.6);out center tags;',
];
(async () => {
 const cached = fs.existsSync(output) ? JSON.parse(fs.readFileSync(output,'utf8')) : {};
 const elements = new Map((cached.elements || []).map(p=>[`${p.type}/${p.id}`,p]));
 const sources = cached.sources || [];
 for (const query of queries) {
  if (sources.some(s=>s.query===query)) continue;
  let fetched = false;
  for (const endpoint of ['https://overpass.private.coffee/api/interpreter']) {
    try {
      const response = await fetch(`${endpoint}?${new URLSearchParams({data: query})}`, {
        headers: {'User-Agent': 'UMA-route-data/1.0'}, signal: AbortSignal.timeout(45000),
      });
      if (!response.ok) throw new Error(`HTTP ${response.status}`);
      const data = await response.json();
      if (!Array.isArray(data.elements) || data.remark) throw new Error(data.remark || 'Invalid OSM response');
      sources.push({endpoint, query, retrievedAt: new Date().toISOString(), timestamp: data.osm3s?.timestamp_osm_base, license: 'ODbL-1.0'});
      for (const element of data.elements) elements.set(`${element.type}/${element.id}`, element);
      fs.mkdirSync(path.dirname(output), {recursive: true});
      fs.writeFileSync(output, JSON.stringify({sources, elements: [...elements.values()]}));
      console.log(`Saved ${data.elements.length} OSM features to ${output}`);
      fetched = true;
      break;
    } catch (error) { console.log(`${endpoint}: ${error.message}`); }
  }
  if (!fetched) process.exitCode = 1;
 }
})();
