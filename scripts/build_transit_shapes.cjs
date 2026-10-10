// Derive per-station track geometry from a local Overpass snapshot. No secrets.
const fs=require('node:fs');
const source=JSON.parse(fs.readFileSync('scripts/data/transit_osm_source.json'));
const meters=(a,b)=>Math.hypot((a[0]-b[0])*111320,(a[1]-b[1])*102700);
const graphs={rail:new Map(),metro:new Map()};
for(const way of source.elements.filter(e=>e.type==='way'&&e.geometry&&e.nodes)){
 if(way.tags?.service==='yard'||way.tags?.service==='siding'||way.tags?.service==='spur')continue;
 const graph=graphs[way.tags.railway==='subway'?'metro':'rail'];
 for(let i=0;i<way.nodes.length;i++){
  const id=way.nodes[i],p=way.geometry[i];if(!p)continue;
  if(!graph.has(id))graph.set(id,{point:[p.lat,p.lon],edges:[]});
  if(i){const previous=graph.get(way.nodes[i-1]);if(!previous)continue;
   const length=meters(previous.point,[p.lat,p.lon]);
   previous.edges.push([id,length]);graph.get(id).edges.push([way.nodes[i-1],length]);
  }
 }
}
function path(graph,start,end){
 const nearest=p=>[...graph.entries()].map(([id,node])=>({id,d:meters(p,node.point)})).filter(n=>n.d<350).sort((a,b)=>a.d-b.d).slice(0,6);
 const starts=nearest(start), ends=nearest(end);if(!starts.length||!ends.length)return null;
 const destinations=new Map(ends.map(e=>[e.id,e.d]));
 const costs=new Map(starts.map(n=>[n.id,n.d]));const previous=new Map();const pending=new Set(starts.map(n=>n.id));const visited=new Set();
 let reached;
 while(pending.size){let current;let best=Infinity;for(const id of pending)if(costs.get(id)<best){best=costs.get(id);current=id;}
  pending.delete(current);visited.add(current);
  if(best>meters(start,end)*3+1500)break;
  if(destinations.has(current)){reached=current;break;}
  for(const [next,length]of graph.get(current).edges){if(visited.has(next))continue;
   const cost=best+length;if(cost<(costs.get(next)??Infinity)){costs.set(next,cost);previous.set(next,current);pending.add(next);}
  }
 }
 if(reached===undefined)return null;
 const points=[];let current=reached;while(current!==undefined){points.push(graph.get(current).point);current=previous.get(current);}
 points.reverse();
 // Retain the station anchors; the short link is the station's platform access.
 return [start,...points,end];
}
const field=(text,name)=>text.match(new RegExp('\\b'+name+":\\s*'([^']*)'"))?.[1];
function stations(text,type){const result=new Map();for(const match of text.matchAll(new RegExp(type+'\\(([\\s\\S]*?)\\n\\s{4}\\)','g'))){
 const body=match[1];const id=field(body,type==='MetroStation'?'id':'code');
 const lat=Number(body.match(/latitude:\s*([\d.-]+)/)?.[1]),lng=Number(body.match(/longitude:\s*([\d.-]+)/)?.[1]);
 if(id&&Number.isFinite(lat)&&Number.isFinite(lng))result.set(id,[lat,lng]);
 }return result;}
const metroText=fs.readFileSync('app/lib/repositories/metro_repository.dart','utf8');
const railText=fs.readFileSync('app/lib/repositories/railway_repository.dart','utf8');
const metro=stations(metroText,'MetroStation'), rail=stations(railText,'RailwayStationInfo');
const shapes={},missing=[];
function add(mode,line,ids,stationMap){for(let i=0;i<ids.length-1;i++){
 const from=stationMap.get(ids[i]),to=stationMap.get(ids[i+1]);if(!from||!to)throw new Error(`Station absent: ${line} ${ids[i]} ${ids[i+1]}`);
 let points=path(graphs[mode],from,to);
 // Some elevated metro track is tagged railway=rail rather than subway.
 if(!points&&mode==='metro')points=path(graphs.rail,from,to);
 const key=`${mode==='metro'?'metro':'rail'}:${line}|${ids[i]}|${ids[i+1]}`;
 if(points)shapes[key]=points.map(p=>p.map(v=>Number(v.toFixed(7))));else missing.push(key);
}}
for(const match of metroText.matchAll(/KolkataMetroLine\.(\w+):\s*\[([\s\S]*?)\]/g)){
 add('metro',match[1],[...match[2].matchAll(/'([^']+)'/g)].map(m=>m[1]),metro);
}
const corridorNames={circularRailwayStations:'circular',sealdahSouthStations:'sealdah_south',sealdahNorthStations:'sealdah_north',howrahMainStations:'howrah_main'};
for(const [list,line]of Object.entries(corridorNames)){
 const start=railText.indexOf(` ${list} = [`),end=railText.indexOf('\n  ];',start);
 if(start<0||end<0)throw new Error('Rail corridor missing '+list);
 const ids=[...railText.slice(start,end).matchAll(/\bcode:\s*'([^']+)'/g)].map(m=>m[1]);add('rail',line,ids,rail);
}
fs.writeFileSync('app/assets/data/transit_track_shapes.json',JSON.stringify({source:'OpenStreetMap / Overpass',license:'ODbL-1.0',retrievedAt:new Date().toISOString(),shapes,missing}));
console.log(JSON.stringify({metroStations:metro.size,railStations:rail.size,trackSections:Object.keys(shapes).length,missing}));
