const fs=require('fs'); function edit(p,f){fs.writeFileSync(p,f(fs.readFileSync(p,'utf8').replace(/\r\n/g,'\n')));}
edit('app/lib/screens/map_screen.dart',s=>{
let a=s.indexOf('  WalkingRoute _multimodalToWalkingRoute('),b=s.indexOf('  Future<void> _findAndHighlightNearestPandal()',a); s=s.slice(0,a)+s.slice(b);
a=s.indexOf('  Future<void> _highlightRouteToMember('); b=s.indexOf('  Future<void> _highlightRouteToFoodSpot(',a);
s=s.slice(0,a)+`  Future<void> _highlightRouteToMember(SquadMember member) async {
    _openDestinationJourney(LatLng(member.latitude, member.longitude), member.name);
  }

`+s.slice(b);
// Preserve user cancellation even when a long provider request is pending.
s=s.replace('    final revision = _journey.revision;', '    final revision = _journey.revision;\n    final navigationGeneration = _navigation.generation;');
s=s.replace('if (!mounted || revision != _journey.revision) return null;', 'if (!mounted || revision != _journey.revision || navigationGeneration != _navigation.generation) return null;');
// Let the engine own ordinary multi-stop reroutes outside a journey.
s=s.replace('_journey.active ? _replanCurrentJourney(origin) : _rerouteSingleDestination(origin)', '_replanCurrentJourney(origin)');
// Actual formatted assignment replaced below separately.
a=s.indexOf('  Future<WalkingRoute?> _rerouteSingleDestination('); b=s.indexOf('  void _onJourneyChanged()',a); s=s.slice(0,a)+s.slice(b);
return s;});
edit('app/lib/services/navigation_session.dart',s=>s.replace('  int _generation = 0;', '  int _generation = 0;\n  int get generation => _generation;'));
edit('app/lib/services/live_tracking_enhancements.dart',s=>s.replace('LiveTrackingEngine.forTesting(this._routing);','LiveTrackingEngine.forTesting(this._routing, {DateTime Function()? now}) : _now = now ?? DateTime.now;').replace('LiveTrackingEngine._() : _routing = RoutingService.instance;', 'LiveTrackingEngine._() : _routing = RoutingService.instance, _now = DateTime.now;').replace('  final LocationService _location', '  final DateTime Function() _now;\n  final LocationService _location').replace('_deviationMonitor.update(fix, _activeRoute!.points)', '_deviationMonitor.update(fix, _activeRoute!.points, now: _now())'));
edit('app/test/navigation_session_test.dart',s=>s.replace('LiveTrackingEngine.forTesting(routing);','LiveTrackingEngine.forTesting(routing, now: () => clock);').replace('clock = clock.add(const Duration(seconds: 1));', 'clock = clock.add(const Duration(seconds: 3));').replace('var clock = DateTime(2026, 10, 10, 12);','var clock = DateTime.now();'));
edit('app/test/mapbox_routing_test.dart',s=>s.replace('timestamp: DateTime(2026, 10, 10, 0, 0, second),','timestamp: DateTime.now().add(Duration(seconds: second)),').replace('position(22.5501, 2)', 'position(22.5501, 3)').replace('position(22.5502, 3)', 'position(22.5502, 6)'));
