// Audits every bundled map point. Source agreement is NOT on-site verification.
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '..');
const read = f => JSON.parse(fs.readFileSync(path.join(root, f), 'utf8'));
const norm = s => String(s || '').toLowerCase().replace(/&amp;/g, 'and').replace(/[^a-z0-9]/g, '');
const valid = (lat, lng) => Number.isFinite(lat) && Number.isFinite(lng) && Math.abs(lat) <= 90 && Math.abs(lng) <= 180 && !(lat === 0 && lng === 0);
const distance = (a, b) => {
  const r = Math.PI / 180, dlat = (a.lat - b.lat) * r, dlng = (a.lng - b.lng) * r;
  return 12742000 * Math.asin(Math.min(1, Math.sqrt(Math.sin(dlat / 2) ** 2 + Math.cos(a.lat * r) * Math.cos(b.lat * r) * Math.sin(dlng / 2) ** 2)));
};
const records = [], issues = [];
function add(category, file, p) {
  const record = {category, file, id: p.id, name: p.name, lat: p.lat, lng: p.lng, status: 'UNVERIFIED', evidence: [], ...p};
  records.push(record);
  if (!valid(record.lat, record.lng)) { record.status = 'INVALID'; issues.push({type: 'invalid_coordinate', category, id: record.id}); }
  else if (record.lat < 21.5 || record.lat > 24 || record.lng < 87 || record.lng > 90) issues.push({type: 'outside_service_region', category, id: record.id});
  return record;
}
const pandals = read('app/assets/data/pandals.json');
for (const p of pandals) add('pandal', 'app/assets/data/pandals.json', {id:p.id, name:p.name, lat:p.lat, lng:p.lng, sourceId:p.source_id});
for (const [file, category] of [['food_spots.json','food'], ['events.json','event']]) {
  for (const p of read(`app/assets/data/${file}`)) add(category, `app/assets/data/${file}`, {id:p.id,name:p.name,...p.coordinates});
}
const stations = read('app/assets/data/stations.geojson');
for (const f of stations.features) {
  const p = f.properties, c = f.geometry.coordinates;
  add('station', 'app/assets/data/stations.geojson', {id:f.id,name:p.name,lat:c[1],lng:c[0],kind:p.kind,code:p.code});
  if (p.lat !== c[1] || p.lon !== c[0]) issues.push({type:'station_geometry_property_mismatch',id:f.id});
  for (const [i,e] of (p.entrances || []).entries()) {
    add('station_entrance','app/assets/data/stations.geojson',{id:`${f.id}/entrance/${i}`,name:p.name,lat:e.lat,lng:e.lon ?? e.lng});
  }
}
const toilets = read('app/assets/data/toilets.json'), toiletMap = new Map(), ids = new Set(pandals.map(p=>p.id));
for (const row of toilets) {
  if (!ids.has(row.pandalId)) issues.push({type:'orphan_toilet_pandal',id:row.pandalId});
  for (const p of [row.nearestMale,row.nearestFemale,...row.allNearby].filter(Boolean)) {
    if (toiletMap.has(p.id) && distance(toiletMap.get(p.id),p)>1) issues.push({type:'conflicting_toilet_coordinate',id:p.id});
    toiletMap.set(p.id,p);
    const origin = pandals.find(x=>x.id===row.pandalId);
    if(origin && Math.abs(distance(origin,p)-p.distM)>75) issues.push({type:'stale_toilet_distance',id:row.pandalId,toiletId:p.id});
  }
}
for (const p of toiletMap.values()) add('toilet','app/assets/data/toilets.json',{id:p.id,name:p.name,lat:p.lat,lng:p.lng,source:p.source});
for (const [file,category,type] of [
  ['metro_repository.dart','metro','MetroStation'],['railway_repository.dart','rail','RailwayStationInfo'],
]) {
  const filePath = `app/lib/repositories/${file}`, text = fs.readFileSync(path.join(root,filePath),'utf8');
  const regex = new RegExp(`${type}\\(\\s*id:\\s*'([^']+)'([\\s\\S]*?)\\n\\s*\\),`, 'g');
  for (const m of text.matchAll(regex)) {
    const field = key => m[2].match(new RegExp(`${key}:\\s*'([^']+)'`))?.[1];
    const number = key => Number(m[2].match(new RegExp(`${key}:\\s*([\\d.-]+)`))?.[1]);
    add(category,filePath,{id:m[1],name:field('name'),code:field('code'),lat:number('latitude'),lng:number('longitude')});
  }
}
// Match original KML names only; never move a pin using a fuzzy name match.
const kml = fs.readFileSync(path.join(root,'scripts/thepujo_dump.kml'),'utf8');
const kmlPoints = [];
for(const m of kml.matchAll(/<Placemark[\s>]([\s\S]*?)<\/Placemark>/g)) {
  const name = m[1].match(/<name>([\s\S]*?)<\/name>/)?.[1]?.replace(/<!\[CDATA\[|\]\]>/g,'').replace(/&amp;/g,'&');
  const coords = m[1].match(/<coordinates>\s*([^<]+)<\/coordinates>/)?.[1]?.trim().split(',').map(Number);
  if(name && coords?.length>=2) kmlPoints.push({name,lat:coords[1],lng:coords[0]});
}
const osmPath = 'scripts/data/coordinate_osm_source.json';
const osmData = fs.existsSync(path.join(root,osmPath)) ? read(osmPath) : {elements:[],sources:[]};
const osm = osmData.elements.map(p=>({...p,lat:p.lat??p.center?.lat,lng:p.lon??p.center?.lon})).filter(p=>valid(p.lat,p.lng));
function evidence(record, point, url, type) {
  const offset = Math.round(distance(record,point));
  record.evidence.push({type,url,sourceLat:point.lat,sourceLng:point.lng,offsetMeters:offset});
  if(record.status!=='INVALID') record.status=offset<=20?'SOURCE_ALIGNED':'REVIEW_OFFSET';
}
for (const record of records) {
  const osmId = record.category==='station' ? record.id.match(/^stn_(\d+)$/)?.[1] : record.category==='toilet' ? record.id.match(/^osm_(\d+)$/)?.[1] : null;
  if(osmId) {
    const matches = osm.filter(p=>String(p.id)===osmId && (record.category!=='station'||p.tags?.railway==='station') && (record.category!=='toilet'||p.tags?.amenity==='toilets'));
    if(matches.length===1) evidence(record,matches[0],`https://www.openstreetmap.org/${matches[0].type}/${osmId}`,'OSM_ID');
  }
  if(record.category==='pandal') {
    const matches = kmlPoints.filter(p=>norm(p.name)===norm(record.name));
    if(matches.length===1) evidence(record,matches[0],'https://www.google.com/maps/d/viewer?mid=1GQ8KBEuldEMnoAmccpMiNdoHX-M8UQI','ORIGINAL_KML_NAME');
  }
  if(record.evidence.length===0 && ['food','metro','rail'].includes(record.category)) {
    const matches=osm.filter(p=>[p.tags?.name,p.tags?.['name:en'],p.tags?.alt_name].some(n=>n && norm(n)===norm(record.name)) && distance(record,p)<3000 && (record.category==='food'?['restaurant','cafe','fast_food'].includes(p.tags?.amenity):p.tags?.railway==='station' && (record.category==='metro' ? p.tags?.station==='subway'||p.tags?.subway==='yes' : p.tags?.station!=='subway' && p.tags?.subway!=='yes')));
    if(matches.length===1) evidence(record,matches[0],`https://www.openstreetmap.org/${matches[0].type}/${matches[0].id}`,'OSM_EXACT_NAME_CANDIDATE');
  }
}
for(const category of new Set(records.map(r=>r.category))) {
  const seen=new Map();
  for(const r of records.filter(r=>r.category===category)) {
    if(seen.has(r.id)) issues.push({type:'duplicate_id',category,id:r.id});
    seen.set(r.id,r);
  }
}
// Compare duplicated transit catalogues without assuming station centres are entrances.
for(const r of records.filter(r=>['metro','rail'].includes(r.category))) {
  const other=records.filter(p=>p.category==='station' && p.kind===r.category && ((p.code&&p.code===r.code)||norm(p.name.replace(/ Metro$/,''))===norm(r.name)));
  for(const p of other) if(distance(r,p)>75) issues.push({type:'conflicting_station_catalogues',id:r.id,otherId:p.id,offsetMeters:Math.round(distance(r,p))});
}
const summary={};
for(const r of records) { summary[r.category]??={total:0};summary[r.category].total++;summary[r.category][r.status]=(summary[r.category][r.status]||0)+1; }
const issueCounts={};for(const i of issues) issueCounts[i.type]=(issueCounts[i.type]||0)+1;
const result={generatedAt:new Date().toISOString(),scope:'All bundled fixed map points, station entrances and hard-coded transit station catalogues; excludes live GPS/group users.',limitations:'SOURCE_ALIGNED means agreement with a named map source, not surveyed accuracy or a verified public entrance. KML is a cached original source. Name candidates require human review before changes.',sources:osmData.sources,summary,issueCounts,records,issues};
fs.mkdirSync(path.join(root,'docs/audits'),{recursive:true});
fs.writeFileSync(path.join(root,'docs/audits/map_coordinates.json'),JSON.stringify(result,null,2)+'\n');
const csv=v=>'"'+String(v??'').replaceAll('"','""')+'"';
fs.writeFileSync(path.join(root,'docs/audits/map_coordinates.csv'),[['category','id','name','latitude','longitude','status','source','offset_m'].join(','),...records.map(r=>[r.category,r.id,r.name,r.lat,r.lng,r.status,r.evidence[0]?.url,r.evidence[0]?.offsetMeters].map(csv).join(','))].join('\n')+'\n');
console.log(JSON.stringify({summary,issueCounts},null,2));
module.exports={valid,distance};
