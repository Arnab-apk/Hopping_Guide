const fs=require('node:fs');
async function main(){
 const query='[out:json][timeout:25];node[railway=station](22.55,88.28,22.73,88.39);out body;';
 const res=await fetch('https://overpass-api.de/api/interpreter?data='+encodeURIComponent(query),{headers:{'User-Agent':'UMA-route-data/1.0'},signal:AbortSignal.timeout(45000)});
 if(!res.ok)throw new Error('Station download HTTP '+res.status);
 const data=await res.json();fs.writeFileSync('scratch/all_station_source.json',JSON.stringify(data));
 console.log('Downloaded station records:',data.elements.length);
}
main().catch(e=>{console.error(e.message);process.exitCode=1;});
