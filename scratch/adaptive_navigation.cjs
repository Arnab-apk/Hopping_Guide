const fs=require('fs');
function edit(p,fn){fs.writeFileSync(p,fn(fs.readFileSync(p,'utf8').replace(/\r\n/g,'\n')));}
if (false) edit('app/lib/services/live_tracking_enhancements.dart',s=>{
s="import 'route_deviation_monitor.dart';\n"+s;
s=s.replace('  int _consecutiveDeviations = 0;', '  final _deviationMonitor = RouteDeviationMonitor();\n  Future<WalkingRoute?> Function(LatLng origin)? replanJourney;');
s=s.replace('  static const int _maxDeviationsBeforeRecalc = 3;','');
const a=s.indexOf('  void _checkDeviation() {'), b=s.indexOf('  Future<void> _triggerRecalculation()',a);
s=s.slice(0,a)+`  void _checkDeviation() {
    final fix = _location.currentPositionSync;
    if (fix == null || _activeRoute == null || _guidance?.arrived == true || _isRecalculating) return;
    if (_deviationMonitor.update(fix, _activeRoute!.points)) {
      _triggerRecalculation();
    }
  }

`+s.slice(b);
s=s.replaceAll('    _consecutiveDeviations = 0;', '    _deviationMonitor.reset();');
// Keep debounce evidence across a completed request.
s=s.replace('    _deviationMonitor.reset();\n\n    try {','\n    try {');
s=s.replace('      final newRoute = remainingStops.length > 1',`      final WalkingRoute? newRoute;
      if (replanJourney != null) {
        newRoute = await replanJourney!(LatLng(pos.latitude, pos.longitude));
      } else if (_activeRoute?.isDriving == true) {
        newRoute = await _routing.getLiveDrivingRouteToPoint(
          start: LatLng(pos.latitude, pos.longitude), destination: _destination!,
          destinationName: _destinationName ?? 'Destination', targetPandal: _targetPandal);
      } else {
        newRoute = remainingStops.length > 1`);
s=s.replace('      if (generation != _trackingGeneration || newRoute.isFallback) return;', '      }\n      if (generation != _trackingGeneration || newRoute == null || newRoute.isFallback) return;\n      _destination = newRoute.points.last;\n      _destinationName = newRoute.destinationTitle;');
return s;});
edit('app/lib/screens/map_screen.dart',s=>{
s="import '../services/journey_planner.dart';\nimport '../services/route_deviation_monitor.dart';\n"+s;
// Route all static destination types through the same modal itinerary.
const replacements=[
['_highlightRouteToStation(Station station)', 'LatLng(station.lat, station.lon)', 'station.displayName'],
['_highlightRouteToMetroStation(MetroStation station)', 'LatLng(station.latitude, station.longitude)', 'station.name'],
['_highlightRouteToFoodSpot(FoodSpot spot)', 'LatLng(spot.lat, spot.lng)', 'spot.name'],
['_highlightRouteToToilet(ToiletEntry toilet)', 'LatLng(toilet.lat, toilet.lng)', 'toilet.displayName'],
];
for(const [sig,point,name] of replacements){
const start=s.indexOf('  Future<void> '+sig+' async {'); if(start<0)throw sig;
let i=s.indexOf('{',start), depth=1, end=i+1;
while(depth){if(s[end]==='{')depth++; if(s[end]==='}')depth--; end++;}
s=s.slice(0,start)+`  Future<void> ${sig} async {
    _openDestinationJourney(${point}, ${name});
  }`+s.slice(end);
}
const start=s.indexOf('  Future<void> _highlightRouteTo(\n'),end=s.indexOf('  WalkingRoute _multimodalToWalkingRoute(',start);
s=s.slice(0,start)+`  Future<void> _highlightRouteTo(Pandal pandal, {bool requireLive = true}) async {
    _openDestinationJourney(LatLng(pandal.lat, pandal.lng), pandal.name, pandal: pandal);
  }

  void _openDestinationJourney(LatLng point, String name, {Pandal? pandal}) {
    FocusScope.of(context).unfocus();
    final destination = pandal ?? Pandal(id: 'destination:' + point.latitude.toString() + ',' + point.longitude.toString(),
      name: name, lat: point.latitude, lng: point.longitude, zone: KolkataZone.centralKolkata,
      theme: '', timings: '', imageUrl: '', description: '');
    Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => TrailRouteScreen(
      stops: [destination], onUseJourney: _onJourneyStart)));
  }

`+s.slice(end);
// Remove now-unreferenced old converter and info dialog if only used internally.
// Replanning keeps the existing stop order and only replaces the current journey.
s=s.replace('  void _onJourneyStart() {\n    unawaited(_startJourneyWalking());\n  }',`  final _transitDeviation = RouteDeviationMonitor();
  bool _replanningJourney = false;

  void _onJourneyStart() {
    unawaited(_refreshJourneyAndStart());
  }

  Future<void> _refreshJourneyAndStart() async {
    if (!_journey.active || _replanningJourney) return;
    final fix = await LocationService.instance.updateLiveLocation();
    if (!mounted || fix == null || fix.accuracy > 50 ||
        DateTime.now().difference(fix.timestamp).abs() > const Duration(seconds: 15)) {
      if (mounted) _showStatusPill('Waiting for an accurate location. Try directions again.', icon: Icons.location_searching);
      return;
    }
    try {
      await _replanCurrentJourney(LatLng(fix.latitude, fix.longitude), automatic: false);
      if (mounted) await _startJourneyWalking();
    } catch (_) {
      if (mounted) _showStatusPill('Could not update the journey. Check your connection and retry.', icon: Icons.warning_amber);
    }
  }

  Future<WalkingRoute?> _replanCurrentJourney(LatLng origin, {bool automatic = true}) async {
    if (!_journey.active || _replanningJourney) return null;
    final revision = _journey.revision;
    final target = _journey.target!;
    final wasDriving = _journey.leg is DriveLeg;
    _replanningJourney = true;
    if (mounted) setState(() {});
    try {
      final next = await JourneyPlanner.instance.plan(origin: origin,
        destination: LatLng(target.lat, target.lng), destinationName: target.name,
        targetPandal: target, allowMetro: _journey.allowMetro && !(automatic && wasDriving),
        allowTrain: _journey.allowTrain && !(automatic && wasDriving),
        allowDriving: automatic ? wasDriving : _journey.allowDriving);
      if (!mounted || revision != _journey.revision) return null;
      _journey.replaceCurrent(next);
      _transitDeviation.reset();
      final road = _journey.walkingRoute;
      if (automatic && road != null && _navigation.active) _journey.beginWalking();
      if (automatic && road == null) {
        _navigation.end();
        _displayedRoute = null;
      }
      if (automatic) _showStatusPill('Route updated from your current location', icon: Icons.alt_route);
      return road;
    } finally {
      _replanningJourney = false;
      if (mounted) setState(() {});
    }
  }

  void _checkTransitDeviation() {
    if (!_journey.active || _journey.leg is WalkLeg || _replanningJourney) return;
    final fix = LocationService.instance.currentPositionSync;
    final leg = _journey.leg;
    // Approximate rail chords and underground GPS cannot establish a deviation.
    final points = leg is MetroLeg && !leg.geometryEstimated ? leg.trackPoints
        : leg is TrainLeg && !leg.geometryEstimated ? leg.trackPoints : const <LatLng>[];
    if (fix != null && _transitDeviation.update(fix, points, tolerance: 120)) {
      unawaited(_replanCurrentJourney(LatLng(fix.latitude, fix.longitude)).catchError((Object _) {
        if (mounted) _showStatusPill('Route update failed. Retry directions when connected.', icon: Icons.warning_amber);
        return null;
      }));
    }
  }`);
s=s.replace('      final route = await RoutingService.instance.getLiveWalkingRouteToPoint(\n        start: origin,', '      final loader = leg is DriveLeg ? RoutingService.instance.getLiveDrivingRouteToPoint : RoutingService.instance.getLiveWalkingRouteToPoint;\n      final route = await loader(\n        start: origin,');
s=s.replace('    _journey.addListener(_onJourneyChanged);', '    _navigation.engine.replanJourney = (origin) => _journey.active ? _replanCurrentJourney(origin) : _rerouteSingleDestination(origin);\n    _journey.addListener(_onJourneyChanged);');
s=s.replace('  void _onHeadingChanged() {', '  void _onHeadingChanged() {\n    _checkTransitDeviation();');
s=s.replace('    _journey.removeListener(_onJourneyChanged);', '    _navigation.engine.replanJourney = null;\n    _journey.removeListener(_onJourneyChanged);');
s=s.replace('  void _onJourneyChanged() {',`  Future<WalkingRoute?> _rerouteSingleDestination(LatLng origin) async {
    final route = _navigation.route;
    if (route == null) return null;
    final loader = route.isDriving ? RoutingService.instance.getLiveDrivingRouteToPoint : RoutingService.instance.getLiveWalkingRouteToPoint;
    return loader(start: origin, destination: route.points.last, destinationName: route.destinationTitle, targetPandal: route.targetPandal);
  }

  void _onJourneyChanged() {`);
s=s.replace('onDirections: _onJourneyStart,', 'onDirections: _onJourneyStart,\n                  updating: _replanningJourney,');
s=s.replace('await _startJourneyWalking();\n                } else', 'await _refreshJourneyAndStart();\n                } else');
return s;});
