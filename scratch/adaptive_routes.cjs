const fs = require('fs');
function edit(p, fn) {const s=fs.readFileSync(p,'utf8').replace(/\r\n/g,'\n'); fs.writeFileSync(p,fn(s));}
edit('app/lib/services/mapbox_directions_service.dart',s=>s
.replace('Future<MapboxRouteData> walking(List<LatLng> waypoints) async {',`Future<MapboxRouteData> walking(List<LatLng> waypoints) => directions(waypoints);
  Future<MapboxRouteData> driving(List<LatLng> waypoints) => directions(waypoints, driving: true);
  Future<MapboxRouteData> directions(List<LatLng> waypoints, {bool driving = false}) async {`)
.replace('_request(waypoints.sublist(start, end))','_request(waypoints.sublist(start, end), driving: driving)')
.replace('_request(List<LatLng> waypoints) async','_request(List<LatLng> waypoints, {bool driving = false}) async')
.replace("'/directions/v5/mapbox/walking/$coordinates'","'/directions/v5/mapbox/${driving ? 'driving-traffic' : 'walking'}/$coordinates'")
.replaceAll('Walking directions','Street directions').replaceAll('walking directions','street directions').replaceAll('No walking route','No street route'));
edit('app/lib/services/routing_service.dart',s=>s
.replace("bool get isWalk => transitMode == 'walk';", "bool get isWalk => transitMode == 'walk';\n  bool get isDriving => transitMode == 'drive';\n  bool get isNavigable => isWalk || isDriving;")
.replace('final walkMins = (durationSeconds / 60).round();',"if (isDriving) return _formatTimeString((durationSeconds / 60).round(), 'car/taxi');\n    final walkMins = (durationSeconds / 60).round();")
.replace('  Future<WalkingRoute> _mapboxRoute({',`  Future<WalkingRoute> getLiveDrivingRouteToPoint({
    required LatLng start, required LatLng destination,
    required String destinationName, Pandal? targetPandal,
  }) async {
    final data = await _mapbox.driving([start, destination]);
    return WalkingRoute(points: data.points, steps: data.steps,
      distanceMeters: data.distanceMeters, durationSeconds: data.durationSeconds,
      customTitle: destinationName, targetPandal: targetPandal,
      transitMode: 'drive', waypoints: [start, destination]);
  }

  Future<WalkingRoute> _mapboxRoute({`));
for(const p of ['navigation_session','route_guidance']) edit('app/lib/services/'+p+'.dart',s=>s.replace('!next.isWalk','!next.isNavigable').replace('!route.isWalk','!route.isNavigable'));
edit('app/lib/services/multimodal_routing_service.dart',s=>s
.replace('/// Metro leg using Kolkata',`/// A road leg with automotive maneuvers; shares geometry storage with WalkLeg.
class DriveLeg extends WalkLeg {
  const DriveLeg({required super.startPoint, required super.endPoint,
    required super.distanceMeters, required super.durationSeconds,
    required super.instructions, required super.points, required super.steps});
  @override
  String get modeLabel => 'Car/taxi';
}

/// Metro leg using Kolkata`)
.replace('.whereType<WalkLeg>()\n      .fold', '.whereType<WalkLeg>()\n      .where((leg) => leg is! DriveLeg)\n      .fold')
.replace('color: const Color(0xFFFFD700), // Festival Gold', 'color: leg is DriveLeg ? const Color(0xFF1976D2) : const Color(0xFFFFD700),'));
edit('app/lib/services/journey_planner.dart',s=>s
.replace('JourneyRoadLoader? roadLoader,','JourneyRoadLoader? roadLoader,\n    JourneyRoadLoader? drivingLoader,')
.replace('_metroLines =\n', '_drivingLoader = drivingLoader ?? RoutingService.instance.getLiveDrivingRouteToPoint,\n       _metroLines =\n')
.replace('final JourneyRoadLoader _roadLoader;', 'final JourneyRoadLoader _roadLoader;\n  final JourneyRoadLoader _drivingLoader;')
.replace('bool allowTrain = true,','bool allowTrain = true,\n    bool allowDriving = false,')
.replace('route.totalDurationSeconds < best.totalDurationSeconds * .9','route.totalDurationSeconds < best.totalDurationSeconds')
.replace('    if (best == null) {',`    if (allowDriving) {
      try {
        final drive = await _drivingLoader(start: origin, destination: destination,
          destinationName: destinationName, targetPandal: targetPandal);
        if (!drive.isFallback && drive.points.length >= 2 && drive.steps.isNotEmpty) {
          final candidate = _route([DriveLeg(startPoint: origin, endPoint: destination,
            distanceMeters: drive.distanceMeters, durationSeconds: drive.durationSeconds,
            instructions: 'Drive or take a taxi to $destinationName',
            points: drive.points, steps: drive.steps)]);
          if (best == null || candidate.totalDurationSeconds < best.totalDurationSeconds) best = candidate;
        }
      } catch (_) { /* Retain the connected walking/transit option. */ }
    }
    if (best == null) {`)
.replace(": 'Walk',", ": legs.any((leg) => leg is DriveLeg) ? 'Car/taxi' : 'Walk',"));
edit('app/lib/services/journey_session.dart',s=>s
.replace('  bool walking = false;', '  bool walking = false;\n  bool allowMetro = true, allowTrain = true, allowDriving = true;\n  int revision = 0;')
.replace('void load(List<Pandal> targets, List<MultimodalRoute> journeys) {','void load(List<Pandal> targets, List<MultimodalRoute> journeys, {bool metro = true, bool train = true, bool driving = true}) {\n    revision++;\n    allowMetro = metro; allowTrain = train; allowDriving = driving;')
.replace('      points: current.points,',"      transitMode: current is DriveLeg ? 'drive' : 'walk',\n      points: current.points,")
.replace('  void beginWalking() {',`  void replaceCurrent(MultimodalRoute next) {
    if (!active || next.legs.isEmpty) return;
    revision++;
    routes = List.unmodifiable([...routes.take(stopIndex), next, ...routes.skip(stopIndex + 1)]);
    legIndex = 0;
    walking = false;
    _skipEmptyWalks();
    notifyListeners();
  }

  void beginWalking() {`)
.replace('    legIndex++;','    revision++;\n    legIndex++;')
.replace('  void end() {','  void end() {\n    revision++;'));
