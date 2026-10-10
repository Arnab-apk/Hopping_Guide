const fs=require('node:fs');
const datasets=['scratch/all_station_source.json','scratch/howrah_station_source.json'].filter(fs.existsSync).flatMap(file=>JSON.parse(fs.readFileSync(file)).elements);
const normal=name=>(name||'').toLowerCase().replace(/junction|\bjn\b|\bstation\b|\s|[-.]/g,'');
const file='app/lib/repositories/railway_repository.dart';let changes=0;
let s=fs.readFileSync(file,'utf8');
s=s.replace(/RailwayStationInfo\(([\s\S]*?)\n {4}\)/g,(whole,body)=>{
 const name=body.match(/\bname:\s*'([^']+)'/)?.[1],code=body.match(/\bcode:\s*'([^']+)'/)?.[1];
 const matches=datasets.filter(node=>node.tags?.station!=='subway'&&
   (node.tags?.ref===code||normal(node.tags?.name)===normal(name)));
 if(matches.length!==1)return whole;
 changes++;const node=matches[0];
 return whole.replace(/latitude:\s*[\d.-]+/,`latitude: ${node.lat}`).replace(/longitude:\s*[\d.-]+/,`longitude: ${node.lon}`);
});
fs.writeFileSync(file,s);console.log('Verified railway station coordinate updates:',changes);
