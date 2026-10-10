const fs=require('fs');
const p='scratch/prepare_route_pins_release.cjs';
let s=fs.readFileSync(p,'utf8');
const files=[
'app/lib/screens/map_screen.dart','app/lib/screens/trail_route_screen.dart',
'app/lib/widgets/journey_map_markers.dart','app/lib/widgets/journey_card.dart','app/lib/widgets/navigation_overlay.dart',
'app/lib/services/journey_planner.dart','app/lib/services/journey_session.dart','app/lib/services/route_deviation_monitor.dart',
'app/lib/services/live_tracking_enhancements.dart','app/lib/services/mapbox_directions_service.dart',
'app/lib/services/multimodal_routing_service.dart','app/lib/services/navigation_session.dart',
'app/lib/services/route_guidance.dart','app/lib/services/routing_service.dart',
'app/test/adaptive_routes_test.dart','app/test/adaptive_routes_live_test.dart','app/test/journey_planner_test.dart',
'app/test/mapbox_routing_test.dart','app/test/navigation_session_test.dart','docs/ADAPTIVE_ROUTES_RELEASE_NOTES.md'];
s=s.replace(/for\(const file of \[[^\]]+\]\)/,`for(const file of ${JSON.stringify(files)})`);
s=s.replace('fix(map): restore familiar pandal and station pins throughout journeys','feat(navigation): compare transport modes and adapt directions to detours');
fs.writeFileSync(p,s);
const pub='scratch/publish_video_release.cjs';
fs.writeFileSync(pub,fs.readFileSync(pub,'utf8').replace("?'Pandal and station pins'", "?'Adaptive directions and route pins'").replace('docs/ROUTE_PINS_RELEASE_NOTES.md','docs/ADAPTIVE_ROUTES_RELEASE_NOTES.md'));
