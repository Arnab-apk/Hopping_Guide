const fs=require('fs');
let p='app/lib/screens/trail_route_screen.dart';let s=fs.readFileSync(p,'utf8');s=s.replace("import '../widgets/route_polylines.dart';","import '../widgets/route_polylines.dart';\nimport '../widgets/journey_map_markers.dart';");
let start=s.indexOf('                      MarkerLayer('), end=s.indexOf('                      const RichAttributionWidget(',start);
s=s.slice(0,start)+`                      MarkerLayer(
                        markers: buildJourneyMarkers(stops: widget.stops, routes: routes),
                      ),
`+s.slice(end);fs.writeFileSync(p,s);
p='app/lib/screens/map_screen.dart';s=fs.readFileSync(p,'utf8').replace("import '../widgets/journey_card.dart';","import '../widgets/journey_card.dart';\nimport '../widgets/journey_map_markers.dart';");
start=s.indexOf('                MarkerLayer(',s.indexOf('if (_journey.active) ...['));end=s.indexOf('\n              ],\n              if (_navigation.active)',start);
s=s.slice(0,start)+`                MarkerLayer(
                  markers: buildJourneyMarkers(
                    stops: _journey.stops,
                    routes: _journey.routes.skip(_journey.stopIndex),
                    currentStopIndex: _journey.stopIndex,
                  ),
                ),`+s.slice(end);
s=s.replace('if (!isTrailActive)\n                  RepaintBoundary(', 'if (!isTrailActive && !_journey.active)\n                  RepaintBoundary(').replace('else if (activeTrail != null && activeTrail.stops.isNotEmpty)','else if (!_journey.active && activeTrail != null && activeTrail.stops.isNotEmpty)');
start=s.indexOf('    // Boarding and alighting markers come from the connected itinerary.');end=s.indexOf('\n    return markers;',start);
s=s.slice(0,start)+`    markers.addAll(buildJourneyMarkers(stops: const [], routes: trail.routedJourneys));
`+s.slice(end);fs.writeFileSync(p,s);
