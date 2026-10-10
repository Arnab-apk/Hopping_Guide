const fs=require('fs');const {execFileSync}=require('child_process');const p='app/lib/screens/map_screen.dart';let s=execFileSync('git',['show','release/group-video-v0.1.8:'+p],{encoding:'utf8',maxBuffer:4e6}).replaceAll('\r\n','\n');
s=s.replace("import '../widgets/journey_card.dart';","import '../widgets/journey_card.dart';\nimport '../widgets/journey_map_markers.dart';");
let start=s.indexOf('                MarkerLayer(',s.indexOf('if (_journey.active) ...['));let end=s.indexOf('\n              ],\n              if (_navigation.active)',start);if(start<0||end<start)throw Error('Journey layer anchors missing');
s=s.slice(0,start)+`                MarkerLayer(
                  markers: buildJourneyMarkers(
                    stops: _journey.stops,
                    routes: _journey.routes.skip(_journey.stopIndex),
                    currentStopIndex: _journey.stopIndex,
                  ),
                ),`+s.slice(end);
s=s.replace('if (!isTrailActive)\n                  RepaintBoundary(', 'if (!isTrailActive && !_journey.active)\n                  RepaintBoundary(').replace('else if (activeTrail != null && activeTrail.stops.isNotEmpty)','else if (!_journey.active && activeTrail != null && activeTrail.stops.isNotEmpty)');
start=s.indexOf('    // Boarding and alighting markers come from the connected itinerary.');end=s.indexOf('\n    return markers;',start);if(start<0||end<start)throw Error('Trail marker anchors missing');
s=s.slice(0,start)+`    markers.addAll(buildJourneyMarkers(stops: const [], routes: trail.routedJourneys));
`+s.slice(end);fs.writeFileSync(p,s);
