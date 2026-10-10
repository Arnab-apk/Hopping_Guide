const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
const index=path.resolve('scratch',`map-release-index-${Date.now()}`);
const env={...process.env,GIT_INDEX_FILE:index};
const git=(args,options={})=>execFileSync('git',args,{env,encoding:'utf8',stdio:['pipe','pipe','pipe'],...options}).trim();
try {
  const parent=git(['rev-parse','release/group-video-v0.1.8']);git(['read-tree',parent]);
  for(const file of ["app/lib/screens/map_screen.dart","app/lib/screens/trail_route_screen.dart","app/lib/widgets/journey_map_markers.dart","app/lib/widgets/journey_card.dart","app/lib/widgets/navigation_overlay.dart","app/lib/services/journey_planner.dart","app/lib/services/journey_session.dart","app/lib/services/route_deviation_monitor.dart","app/lib/services/live_tracking_enhancements.dart","app/lib/services/mapbox_directions_service.dart","app/lib/services/multimodal_routing_service.dart","app/lib/services/navigation_session.dart","app/lib/services/route_guidance.dart","app/lib/services/routing_service.dart","app/test/adaptive_routes_test.dart","app/test/adaptive_routes_live_test.dart","app/test/journey_planner_test.dart","app/test/mapbox_routing_test.dart","app/test/navigation_session_test.dart","docs/ADAPTIVE_ROUTES_RELEASE_NOTES.md"]){
    const hash=git(['hash-object','-w','--',file]);git(['update-index','--add','--cacheinfo',`100644,${hash},${file}`]);
  }
  const tree=git(['write-tree']);
  const commit=git(['commit-tree',tree,'-p',parent],{input:'feat(navigation): compare transport modes and adapt directions to detours\n\nUse shared Leaflet pins for itinerary previews and active navigation, include intermediate metro stations, deduplicate station markers and expose names on tap.\n'});
  git(['update-ref','refs/heads/release/group-video-v0.1.9',commit]);
  const dir='app/build/releases/v0.1.9';fs.mkdirSync(dir,{recursive:true});
  const apk=`${dir}/UMA-v0.1.9.apk`;fs.copyFileSync('app/build/app/outputs/flutter-apk/app-release.apk',apk);
  const sha256=crypto.createHash('sha256').update(fs.readFileSync(apk)).digest('hex');
  fs.writeFileSync(`${dir}/SHA256SUMS.txt`,`${sha256}  UMA-v0.1.9.apk\n`);
  fs.writeFileSync(`${dir}/source.json`,JSON.stringify({commit,sha256,size:fs.statSync(apk).size}));console.log(JSON.stringify({commit,sha256,size:fs.statSync(apk).size}));
}finally{if(fs.existsSync(index))fs.unlinkSync(index);}
