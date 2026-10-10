const fs=require('node:fs');
async function main(){
 const query='[out:json][timeout:45];(way[railway=rail](22.35,88.20,22.98,88.56);way[railway=subway](22.35,88.20,22.98,88.56););out body geom;';
 for(const host of ['https://overpass-api.de/api/interpreter']){
  try{const res=await fetch(host+'?data='+encodeURIComponent(query),{headers:{'User-Agent':'UMA-route-data/1.0','Accept':'application/json'},signal:AbortSignal.timeout(120000)});
   if(!res.ok){console.log('Transit data HTTP',res.status,(await res.text()).slice(0,150));continue;}
   const json=await res.json();fs.writeFileSync('scratch/transit_osm_source.json',JSON.stringify(json));
   console.log('Downloaded OSM transit elements:',json.elements.length);
   for(const node of json.elements.filter(e=>e.type==='node')) console.log(JSON.stringify({name:node.tags?.name,lat:node.lat,lng:node.lon}));
   return;
  }catch(e){console.log('Transit data request failed:',e.name);}
 }
 throw new Error('Transit geometry download unavailable');
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
