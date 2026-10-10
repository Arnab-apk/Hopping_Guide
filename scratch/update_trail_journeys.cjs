const fs=require('node:fs');
const file='app/lib/services/custom_hopping_trail_service.dart';
let source=fs.readFileSync(file,'utf8');
const start=source.indexOf('  Future<void> calculateAndApplyRoadRoute(');
const end=source.indexOf('  /// Checks if the user is within',start);
if(start<0||end<0)throw new Error('Trail routing markers missing');
source=source.slice(0,start)+`  Future<void> calculateAndApplyRoadRoute(ActiveCustomTrail trail, {bool requireLive = false}) async {
    if (trail.stops.isEmpty) return;
    trail.isRouting = true;
    trail.routeError = null;
    if (identical(_activeTrail, trail)) notifyListeners();
    try {
      final journeys = <MultimodalRoute>[];
      var origin = trail.startingLocation;
      for (final stop in trail.stops) {
        journeys.add(await JourneyPlanner.instance.plan(
          origin: origin,
          destination: LatLng(stop.lat, stop.lng),
          destinationName: stop.name,
          targetPandal: stop,
          allowMetro: trail.allowMetro,
          allowTrain: trail.allowTrain,
        ));
        origin = LatLng(stop.lat, stop.lng);
      }
      if (!identical(_activeTrail, trail)) return;
      trail.routedJourneys = journeys;
      trail.routeRevision++;
      final distance = journeys.fold<double>(0, (sum, route) => sum + route.totalDistanceMeters);
      final seconds = journeys.fold<double>(0, (sum, route) => sum + route.totalDurationSeconds);
      updateRoutedStats(
        distanceKm: distance / 1000,
        durationMinutes: (seconds / 60 + trail.stops.length * 15).ceil(),
        polyline: [for (final journey in journeys) ...journey.allDisplayPoints],
      );
    } catch (_) {
      if (identical(_activeTrail, trail)) {
        trail.routeError = 'Could not load connected street and transit routes. Check your connection and retry.';
      }
      if (requireLive) rethrow;
    } finally {
      trail.isRouting = false;
      if (identical(_activeTrail, trail)) notifyListeners();
    }
  }

`+source.slice(end);
// Preserve the supplied origin, including the journey into Kolkata.
const anchorStart=source.indexOf('    // Check if startPos is in walking vicinity');
const anchorEnd=source.indexOf('    final result = TrailOptimizer.optimizePandalStops(',anchorStart);
if(anchorStart<0||anchorEnd<0)throw new Error('Optimizer markers missing');
source=source.slice(0,anchorStart)+'    final effectiveStart = startPos;\n\n'+source.slice(anchorEnd);
source=source.replace(/startingLocation: isUserClose\s*\? startPos\s*: LatLng\(result\.orderedStops\.first\.lat, result\.orderedStops\.first\.lng\),/,'startingLocation: startPos,');
source=source.replace('startingAddress: isUserClose ? startLabel : result.orderedStops.first.name,','startingAddress: startLabel,');
fs.writeFileSync(file,source);
