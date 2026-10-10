const fs=require('node:fs');const file='app/lib/screens/map_screen.dart';let s=fs.readFileSync(file,'utf8');
const preview=s.indexOf('  Future<void> _previewTrailNavigation(');const previewEnd=s.indexOf('  Widget _buildTrailSummaryBar(',preview);
if(preview<0||previewEnd<0)throw new Error('Preview markers absent');
s=s.slice(0,preview)+`  Future<void> _offerActiveTrailDirections() async {
    final trail = CustomHoppingTrailService.instance.activeTrail;
    final target = trail?.currentTargetPandal;
    if (target != null && await offerTrailNavigation(context,target.name) && mounted) {
      await _previewTrailNavigation(trail!);
    }
  }

  Future<void> _previewTrailNavigation(ActiveCustomTrail trail) async {
    final remaining = trail.stops.skip(trail.currentStopIndex)
        .where((stop) => !trail.visitedPandalIds.contains(stop.id)).toList();
    MapScreen.openTrailRoute(context,remaining,allowMetro:trail.allowMetro,allowTrain:trail.allowTrain);
  }

`+s.slice(previewEnd);
const start=s.indexOf('  List<Polyline> _buildTrailPolylines(');const end=s.indexOf('  List<Marker> _buildTrailMarkers(',start);
if(start<0||end<0)throw new Error('Polyline markers absent');
s=s.slice(0,start)+`  List<Polyline> _buildTrailPolylines(ActiveCustomTrail trail, LatLng? liveLoc, bool isDark) {
    final key = trail.id + '_' + identityHashCode(trail).toString() + '_' + trail.routeRevision.toString() + '_' + isDark.toString();
    if (_cachedTrailCoreKey != key || _cachedTrailCorePolylines == null) {
      _cachedTrailCoreKey = key;
      _cachedTrailCorePolylines = [
        for (final journey in trail.routedJourneys)
          ...buildHighlightedRoutePolylines(WalkingRoute(points:journey.allDisplayPoints,
            distanceMeters:journey.totalDistanceMeters,durationSeconds:journey.totalDurationSeconds,
            segments:journey.polylines),isDark),
      ];
    }
    return _cachedTrailCorePolylines!;
  }

`+s.slice(end);
s=s.replace("tooltip: trail.hasTransitLegs\n                ? 'Walking directions to next stop'\n                : 'Walk this trail',","tooltip: 'Trail route and directions',");
fs.writeFileSync(file,s);
