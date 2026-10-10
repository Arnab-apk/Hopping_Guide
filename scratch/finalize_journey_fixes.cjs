const fs=require('fs');
const edit=(p,f)=>fs.writeFileSync(p,f(fs.readFileSync(p,'utf8')));
edit('app/lib/screens/map_screen.dart',s=>{
s=s.replace('fix.accuracy <= 30) {','fix.accuracy <= 30 &&\n          DateTime.now().difference(fix.timestamp).abs() <= const Duration(seconds: 10)) {');
s=s.replace('onStart: () => _navigation.begin(),','onStart: () async {\n                if (_journey.active && _journey.leg is WalkLeg) {\n                  await _startJourneyWalking();\n                } else {\n                  await _navigation.begin();\n                }\n              },');
const start=s.indexOf('    // Station badges for metro-assisted legs');const end=s.indexOf('\n    return markers;',start);
s=s.slice(0,start)+`    // Boarding and alighting markers come from the connected itinerary.
    final stationPoints = <String>{};
    for (final journey in trail.routedJourneys) {
      for (final leg in journey.legs.where((leg) => leg is! WalkLeg)) {
        for (final point in [leg.startPoint, leg.endPoint]) {
          if (!stationPoints.add(point.toString())) continue;
          markers.add(Marker(point: point, width: 32, height: 32,
            child: Tooltip(message: leg.instructions,
              child: Icon(leg is MetroLeg ? Icons.subway : Icons.train,
                color: Colors.deepPurple))));
        }
      }
    }
`+s.slice(end);
s=s.replace("'$distStr · ${remainingMin > 0 ?", "'${trail.isRouting ? \"Loading route\" : trail.routeError != null ? \"Route unavailable — retry directions\" : distStr} · ${remainingMin > 0 ?");
return s;});
edit('app/lib/screens/trail_route_screen.dart',s=>s.replace('padding: const EdgeInsets.all(40),','padding: const EdgeInsets.all(40),\n                        maxZoom: 17,').replace('Ride times and rail alignments are estimates. Check service information at the station.','Ride times are estimates, not live departures. Dashed rail lines show approximate sections. Check service information at the station.'));
edit('app/lib/repositories/railway_repository.dart',s=>s.replace(/    RailwayStationInfo\(\s*id: 'rail_tph',[\s\S]*?\n    \),\n/,''));
edit('app/lib/services/squad_service.dart',s=>{
const start=s.indexOf('      final models = stops.map(SquadPandalStop.fromJson)',s.indexOf('Future<bool> optimizeSquadRoute'));const end=s.indexOf('\n    });',start);
return s.slice(0,start)+`      final active = plan['isHoppingActive'] == true;
      final index = ((plan['activeStopIndex'] as num?)?.toInt() ?? 0).clamp(0, stops.length);
      // Completed/skipped stops stay before the active portion, so optimising
      // cannot make an unvisited destination disappear behind the current index.
      final prefix = active ? stops.take(index).toList() : <Map<String,dynamic>>[];
      final remaining = active ? stops.skip(index).toList() : stops;
      final visited = remaining.where((s) => s['isVisited'] == true).toList();
      final pending = remaining.where((s) => s['isVisited'] != true).toList();
      final result = TrailOptimizer.optimizePandalStops(
        start: startPos,
        stops: pending.map(SquadPandalStop.fromJson).map((s) => s.toPandal()).toList(),
        allowMetro: true,
        allowTrain: true,
      );
      final byId = {for (final stop in pending) stop['id']: stop};
      final ordered = [...prefix, ...visited, ...result.orderedStops.map((p) => byId[p.id]!)];
      return {...plan, 'chosenPandals': ordered, 'activeStopIndex': prefix.length + visited.length};`+s.slice(end);
});
edit('app/lib/services/custom_hopping_trail_service.dart',s=>s.replaceAll('GemKit native RoutingService','the connected journey planner').replaceAll('GemKit route calculation','connected pedestrian and transit routes').replaceAll('GemKit RoutingService','the connected journey planner'));
fs.mkdirSync('scripts/data',{recursive:true});
fs.copyFileSync('scratch/transit_osm_source.json','scripts/data/transit_osm_source.json');
edit('scripts/build_transit_shapes.cjs',s=>s.replace('scratch/transit_osm_source.json','scripts/data/transit_osm_source.json'));
