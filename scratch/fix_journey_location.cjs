const fs=require('fs');
for(const p of ['app/lib/screens/map_screen.dart','app/lib/screens/trail_route_screen.dart']){
let s=fs.readFileSync(p,'utf8');s=s.replaceAll('final fix = await LocationService.instance.currentPosition();',`var fix = await LocationService.instance.currentPosition();
      if (fix != null && DateTime.now().difference(fix.timestamp).abs() > const Duration(seconds: 30)) {
        fix = await LocationService.instance.updateLiveLocation();
      }`);fs.writeFileSync(p,s);}
const p='app/lib/services/custom_hopping_trail_service.dart';let s=fs.readFileSync(p,'utf8');
s=s.replace('final trail = _activeTrail!;\n\n    if (!trail.visitedPandalIds.contains(pandal.id)) {',`final trail = _activeTrail!;
    if (trail.currentTargetPandal?.id != pandal.id || trail.visitedPandalIds.contains(pandal.id)) return;

    if (!trail.visitedPandalIds.contains(pandal.id)) {`);
fs.writeFileSync(p,s);
