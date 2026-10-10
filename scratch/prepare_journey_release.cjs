const fs=require('node:fs');
const path=require('node:path');
const crypto=require('node:crypto');
const {execFileSync}=require('node:child_process');
const index=path.resolve('scratch',`journey-release-index-${Date.now()}`);
const env={...process.env,GIT_INDEX_FILE:index};
const git=(args,options={})=>execFileSync('git',args,{env,encoding:'utf8',stdio:['pipe','pipe','pipe'],...options}).trim();
const files=[
 'app/lib/repositories/railway_repository.dart','app/lib/screens/group_screen.dart','app/lib/screens/map_screen.dart',
 'app/lib/services/custom_hopping_trail_service.dart','app/lib/services/multimodal_routing_service.dart','app/lib/services/squad_service.dart',
 'app/lib/widgets/custom_trail_planner_dialog.dart','app/lib/widgets/route_polylines.dart',
 'app/lib/screens/trail_route_screen.dart','app/lib/services/journey_planner.dart','app/lib/services/journey_session.dart','app/lib/services/transit_geometry.dart',
 'app/lib/widgets/empty_states.dart','app/lib/widgets/journey_card.dart','app/lib/widgets/trail_navigation_prompt.dart','app/assets/data/transit_track_shapes.json',
 'app/test/custom_hopping_trail_test.dart','app/test/custom_trail_builder_test.dart','app/test/launch_layout_test.dart','app/test/squad_collaborative_hopping_test.dart',
 'app/test/journey_planner_test.dart','app/test/journey_live_smoke_test.dart','app/test/journey_behala_live_check_test.dart',
 'scripts/build_transit_shapes.cjs','scripts/data/transit_osm_source.json','docs/TRAIL_ROUTES_RELEASE_NOTES.md','docs/TRANSIT_TRACK_DATA.md'];
try{
 const parent=git(['rev-parse','release/group-video-v0.1.7']);git(['read-tree',parent]);
 for(const file of files){const hash=git(['hash-object','-w','--',file]);git(['update-index','--add','--cacheinfo',`100644,${hash},${file}`]);}
 const tree=git(['write-tree']);const commit=git(['commit-tree',tree,'-p',parent],{input:'feat(trails): connect street, suburban train and metro itineraries with staged navigation\n\nShow actual pedestrian connections, mapped track sections and explicit transfers. Prompt directions after optimisation, retain the real origin and preserve completed stops. Verify mixed transit journeys, live walking maneuvers, arrival progression and the full Flutter suite.\n'});
 git(['update-ref','refs/heads/release/group-video-v0.1.8',commit]);
 const dir='app/build/releases/v0.1.8';fs.mkdirSync(dir,{recursive:true});const apk=`${dir}/UMA-v0.1.8.apk`;fs.copyFileSync('app/build/app/outputs/flutter-apk/app-release.apk',apk);
 const sha256=crypto.createHash('sha256').update(fs.readFileSync(apk)).digest('hex');fs.writeFileSync(`${dir}/SHA256SUMS.txt`,`${sha256}  UMA-v0.1.8.apk\n`);
 fs.writeFileSync(`${dir}/source.json`,JSON.stringify({commit,sha256,size:fs.statSync(apk).size}));console.log(JSON.stringify({commit,sha256,size:fs.statSync(apk).size}));
}finally{if(fs.existsSync(index))fs.unlinkSync(index);}
