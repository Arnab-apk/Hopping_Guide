import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/metro_station.dart';
import '../models/pandal.dart';
import '../models/navigation_step.dart';
import '../models/route_polyline_segment.dart';
export '../models/route_polyline_segment.dart';
import '../models/station.dart';
import '../repositories/metro_repository.dart';
import '../repositories/railway_repository.dart';
import 'routing_service.dart';
import 'location_service.dart';

/// Primary transit mode chosen for a journey.
enum TransitMode { road, metro, train }

/// Represents a single leg of a multimodal journey
abstract class RouteLeg {
  const RouteLeg({
    required this.startPoint,
    required this.endPoint,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.instructions,
  });

  final LatLng startPoint;
  final LatLng endPoint;
  final double distanceMeters;
  final double durationSeconds;
  final String instructions;

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  String get formattedDuration {
    final mins = (durationSeconds / 60).round();
    if (mins < 1) return '< 1 min';
    if (mins < 60) return '$mins min';
    final hrs = mins ~/ 60;
    final rem = mins % 60;
    return rem == 0 ? '${hrs}h' : '${hrs}h ${rem}m';
  }
}

/// Walking leg using pedestrian routing (OSRM/GemKit)
class WalkLeg extends RouteLeg {
  const WalkLeg({
    required super.startPoint,
    required super.endPoint,
    required super.distanceMeters,
    required super.durationSeconds,
    required super.instructions,
    required this.points,
    this.isFallback = false,
    this.steps = const [],
  });

  final List<LatLng> points;
  final bool isFallback;
  final List<NavigationStep> steps;

  String get modeLabel => 'Walk';
  String get modeIcon => '🚶';
}

/// Metro leg using Kolkata Metro network with authentic sequential track curves
class MetroLeg extends RouteLeg {
  const MetroLeg({
    required super.startPoint,
    required super.endPoint,
    required super.distanceMeters,
    required super.durationSeconds,
    required super.instructions,
    required this.entryStation,
    required this.exitStation,
    required this.line,
    required this.stationCount,
    this.trackPoints = const [],
    this.isInterchange = false,
    this.connectingLine,
  });

  final MetroStation entryStation;
  final MetroStation exitStation;
  final KolkataMetroLine line;
  final int stationCount;
  final List<LatLng> trackPoints;
  final bool isInterchange;
  final KolkataMetroLine? connectingLine;

  String get modeLabel => 'Metro';
  String get modeIcon => '🚇';

  String get lineLabel => line.label;
  String get lineColorHex => '#${line.color.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}';
}

/// Suburban train leg using Eastern / South Eastern / Circular Railway network
class TrainLeg extends RouteLeg {
  const TrainLeg({
    required super.startPoint,
    required super.endPoint,
    required super.distanceMeters,
    required super.durationSeconds,
    required super.instructions,
    required this.entryStation,
    required this.exitStation,
    required this.corridorName,
    required this.stationCount,
    this.trackPoints = const [],
  });

  final RailwayStationInfo entryStation;
  final RailwayStationInfo exitStation;
  final String corridorName;
  final int stationCount;
  final List<LatLng> trackPoints;

  String get modeLabel => 'Train';
  String get modeIcon => '🚆';
  String get lineColorHex => '#7B1FA2'; // Indian Railways Royal Purple
}

/// Complete multimodal route combining walk + transit (metro/train) legs
class MultimodalRoute {
  const MultimodalRoute({
    required this.legs,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.summary,
    this.primaryMode = TransitMode.road,
    this.bestModeBadge,
    this.isFallback = false,
  });

  final List<RouteLeg> legs;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final String summary;
  final TransitMode primaryMode;
  final String? bestModeBadge;
  final bool isFallback;

  TransitMode get transitMode => primaryMode;
  bool get isTrain => primaryMode == TransitMode.train;
  bool get isMetro => primaryMode == TransitMode.metro;
  bool get isRoad => primaryMode == TransitMode.road;

  List<LatLng> get allDisplayPoints => allPointsForMap;
  List<RoutePolylineSegment> get polylines => polylineSegments;

  /// Total walking distance across all walk legs
  double get totalWalkDistanceMeters => legs
      .whereType<WalkLeg>()
      .fold(0.0, (sum, leg) => sum + leg.distanceMeters);

  /// Total metro distance across all metro legs
  double get totalMetroDistanceMeters => legs
      .whereType<MetroLeg>()
      .fold(0.0, (sum, leg) => sum + leg.distanceMeters);

  /// Total train distance across all train legs
  double get totalTrainDistanceMeters => legs
      .whereType<TrainLeg>()
      .fold(0.0, (sum, leg) => sum + leg.distanceMeters);

  /// Walk legs only
  List<WalkLeg> get walkLegs => legs.whereType<WalkLeg>().toList();

  /// Metro legs only
  List<MetroLeg> get metroLegs => legs.whereType<MetroLeg>().toList();

  /// Train legs only
  List<TrainLeg> get trainLegs => legs.whereType<TrainLeg>().toList();

  String get formattedTotalDistance {
    if (totalDistanceMeters < 1000) {
      return '${totalDistanceMeters.round()} m';
    } else {
      return '${(totalDistanceMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  String get formattedTotalDuration {
    final mins = (totalDurationSeconds / 60).round();
    if (mins < 1) return '< 1 min';
    if (mins < 60) return '$mins min';
    final hrs = mins ~/ 60;
    final rem = mins % 60;
    return rem == 0 ? '${hrs}h' : '${hrs}h ${rem}m';
  }

  /// Get all continuous points for map rendering and camera bounding,
  /// smoothly traversing street curves and railway/metro alignments without straight chords!
  List<LatLng> get allPointsForMap {
    final points = <LatLng>[];
    for (final leg in legs) {
      if (leg is WalkLeg) {
        points.addAll(leg.points);
      } else if (leg is MetroLeg) {
        if (leg.trackPoints.isNotEmpty) {
          points.addAll(leg.trackPoints);
        } else {
          points.add(leg.entryStation.toLatLng());
          points.add(leg.exitStation.toLatLng());
        }
      } else if (leg is TrainLeg) {
        if (leg.trackPoints.isNotEmpty) {
          points.addAll(leg.trackPoints);
        } else {
          points.add(leg.entryStation.toLatLng());
          points.add(leg.exitStation.toLatLng());
        }
      }
    }
    return points;
  }

  /// Get polyline segments by type for styled rendering on the map:
  /// - Walk: Gold / Cyan glowing street lines
  /// - Metro: Vibrant Kolkata Metro brand lines following sequential stations
  /// - Train: Royal Purple Indian Railways track lines following sequential rail stations
  List<RoutePolylineSegment> get polylineSegments {
    final segments = <RoutePolylineSegment>[];
    for (final leg in legs) {
      if (leg is WalkLeg) {
        segments.add(RoutePolylineSegment(
          points: leg.points,
          type: RouteSegmentType.walk,
          color: const Color(0xFFFFD700), // Festival Gold
          isFallback: leg.isFallback,
        ));
      } else if (leg is MetroLeg) {
        final pts = leg.trackPoints.isNotEmpty
            ? leg.trackPoints
            : [leg.entryStation.toLatLng(), leg.exitStation.toLatLng()];
        segments.add(RoutePolylineSegment(
          points: pts,
          type: RouteSegmentType.metro,
          color: leg.line.color,
          line: leg.line,
        ));
      } else if (leg is TrainLeg) {
        final pts = leg.trackPoints.isNotEmpty
            ? leg.trackPoints
            : [leg.entryStation.toLatLng(), leg.exitStation.toLatLng()];
        segments.add(RoutePolylineSegment(
          points: pts,
          type: RouteSegmentType.train,
          color: const Color(0xFF7B1FA2), // Railway Purple
        ));
      }
    }
    return segments;
  }
}

/// Multimodal routing service: compares Road vs Metro vs Suburban Train
/// and determines the SHORTEST distance and most optimal travel option with realistic track alignments.
class MultimodalRoutingService {
  MultimodalRoutingService._();
  static final MultimodalRoutingService instance = MultimodalRoutingService._();

  final RoutingService _routing = RoutingService.instance;
  final LocationService _location = LocationService.instance;

  // Metro average speed: ~35 km/h including stops = ~9.7 m/s
  static const double _metroSpeedMps = 9.7;
  // Average dwell time per station: 30 seconds
  static const double _stationDwellSeconds = 30.0;
  // Transfer penalty at interchange: 3 minutes
  static const double _interchangePenaltySeconds = 180.0;

  /// Find nearest metro station to a coordinate
  MetroStation? findNearestStation(LatLng position) {
    MetroStation? nearest;
    double minDist = double.infinity;

    for (final station in MetroRepository.allStations) {
      final dist = haversineMeters(
        position.latitude, position.longitude,
        station.latitude, station.longitude,
      );
      if (dist < minDist) {
        minDist = dist;
        nearest = station;
      }
    }
    return nearest;
  }

  /// Find k-nearest metro stations
  List<MetroStation> findNearestStations(LatLng position, int k) {
    final stationsWithDist = MetroRepository.allStations.map((s) {
      final dist = haversineMeters(
        position.latitude, position.longitude,
        s.latitude, s.longitude,
      );
      return (station: s, distance: dist);
    }).toList()
      ..sort((a, b) => a.distance.compareTo(b.distance));
    return stationsWithDist.take(k).map((e) => e.station).toList();
  }

  /// Find nearest suburban train station to a coordinate
  RailwayStationInfo? findNearestTrainStation(LatLng position, {double maxDistanceKm = 3.5}) {
    return RailwayRepository.instance.findNearestStation(position, maxDistanceKm: maxDistanceKm);
  }

  /// Find k-nearest suburban train stations
  List<RailwayStationInfo> findNearestTrainStations(LatLng position, int k, {double maxDistanceKm = 3.5}) {
    return RailwayRepository.instance.findNearestStations(position, k, maxDistanceKm: maxDistanceKm);
  }

  /// Compute shortest metro path between two stations using Dijkstra
  MetroPath? computeMetroPath(MetroStation from, MetroStation to) {
    if (from.id == to.id) return null;

    // Build adjacency graph
    final adj = <String, List<MetroEdge>>{};
    for (final line in KolkataMetroLine.values) {
      final stations = MetroRepository.getStationsForLine(line);
      for (int i = 0; i < stations.length - 1; i++) {
        final a = stations[i];
        final b = stations[i + 1];
        final dist = haversineMeters(
          a.latitude, a.longitude, b.latitude, b.longitude,
        );
        final travelTime = (dist / _metroSpeedMps) + _stationDwellSeconds;

        adj.putIfAbsent(a.id, () => []).add(MetroEdge(
          toId: b.id, line: line, distance: dist, duration: travelTime));
        adj.putIfAbsent(b.id, () => []).add(MetroEdge(
          toId: a.id, line: line, distance: dist, duration: travelTime));
      }
    }

    // Add interchange connections (zero distance, transfer penalty)
    for (final station in MetroRepository.allStations) {
      if (station.isInterchange) {
        for (final otherLine in station.connectingLines) {
          final otherStations = MetroRepository.getStationsForLine(otherLine);
          final match = otherStations.where((s) =>
            haversineMeters(s.latitude, s.longitude,
              station.latitude, station.longitude) < 100).toList();
          for (final m in match) {
            adj.putIfAbsent(station.id, () => []).add(MetroEdge(
              toId: m.id, line: otherLine, distance: 0, duration: _interchangePenaltySeconds));
          }
        }
      }
    }

    // Dijkstra
    final dist = <String, double>{};
    final prev = <String, MetroEdge?>{};
    final visited = <String>{};
    final pq = <_PQNode>[];

    dist[from.id] = 0;
    pq.add(_PQNode(id: from.id, dist: 0));

    while (pq.isNotEmpty) {
      pq.sort((a, b) => a.dist.compareTo(b.dist));
      final current = pq.removeAt(0);
      if (visited.contains(current.id)) continue;
      visited.add(current.id);

      if (current.id == to.id) break;

      for (final edge in adj[current.id] ?? []) {
        if (visited.contains(edge.toId)) continue;
        final alt = dist[current.id]! + edge.duration;
        if (alt < (dist[edge.toId] ?? double.infinity)) {
          dist[edge.toId] = alt;
          prev[edge.toId] = edge;
          pq.add(_PQNode(id: edge.toId, dist: alt));
        }
      }
    }

    if (!dist.containsKey(to.id)) return null;

    // Reconstruct path
    var edges = <MetroEdge>[];
    String? curr = to.id;
    while (curr != null && prev.containsKey(curr) && prev[curr] != null) {
      edges.add(prev[curr]!);
      String? prevId;
      for (final e in adj.entries) {
        if (e.value.any((ed) => ed.toId == curr && ed.line == prev[curr]!.line && ed.distance == prev[curr]!.distance)) {
          prevId = e.key;
          break;
        }
      }
      curr = prevId;
    }
    edges = edges.reversed.toList();

    // Group by line for leg creation
    final legs = <MetroPathLeg>[];
    MetroPathLeg? currentLeg;
    for (final edge in edges) {
      if (currentLeg == null || currentLeg.line != edge.line) {
        currentLeg = MetroPathLeg(line: edge.line, edges: [edge]);
        legs.add(currentLeg);
      } else {
        currentLeg.edges.add(edge);
      }
    }

    return MetroPath(
      from: from,
      to: to,
      legs: legs,
      totalDuration: dist[to.id]!,
      totalDistance: edges.fold(0.0, (sum, e) => sum + e.distance),
    );
  }

  /// Computes a direct road / pedestrian route
  Future<MultimodalRoute> computeRoadRoute({
    required LatLng origin,
    required LatLng destination,
    String? destinationName,
    Pandal? targetPandal,
  }) async {
    final walkRoute = await _routing.getWalkingRouteToPoint(
      start: origin,
      destination: destination,
      destinationName: destinationName ?? 'Destination',
      targetPandal: targetPandal,
    );

    return MultimodalRoute(
      legs: [
        WalkLeg(
          startPoint: origin,
          endPoint: destination,
          distanceMeters: walkRoute.distanceMeters,
          durationSeconds: walkRoute.durationSeconds,
          instructions: 'Direct road route to ${destinationName ?? 'destination'}',
          points: walkRoute.points,
          steps: walkRoute.steps,
          isFallback: walkRoute.isFallback,
        )
      ],
      totalDistanceMeters: walkRoute.distanceMeters,
      totalDurationSeconds: walkRoute.durationSeconds,
      summary: 'Walk ${walkRoute.formattedDistance} (${walkRoute.formattedDuration})',
      primaryMode: TransitMode.road,
      bestModeBadge: '🚶 Shortest: Direct Road',
      isFallback: walkRoute.isFallback,
    );
  }

  /// Computes the best Metro-assisted route (if viable)
  Future<MultimodalRoute?> computeMetroRouteCandidate({
    required LatLng origin,
    required LatLng destination,
    String? destinationName,
    Pandal? targetPandal,
    double maxWalkDistanceKm = 2.5,
  }) async {
    final originStations = findNearestStations(origin, 3);
    final destStations = findNearestStations(destination, 3);

    MultimodalRoute? bestMetro;
    double bestScore = double.infinity;

    for (final entryStation in originStations) {
      for (final exitStation in destStations) {
        if (entryStation.id == exitStation.id) continue;

        final walkToEntry = await _routing.getWalkingRouteToPoint(
          start: origin,
          destination: entryStation.toLatLng(),
          destinationName: entryStation.name,
        );
        if (walkToEntry.distanceMeters > maxWalkDistanceKm * 1000) continue;

        final metroPath = computeMetroPath(entryStation, exitStation);
        if (metroPath == null) continue;

        final walkFromExit = await _routing.getWalkingRouteToPoint(
          start: exitStation.toLatLng(),
          destination: destination,
          destinationName: destinationName ?? 'Destination',
          targetPandal: targetPandal,
        );
        if (walkFromExit.distanceMeters > maxWalkDistanceKm * 1000) continue;

        final legs = <RouteLeg>[];

        // Walk to entry
        legs.add(WalkLeg(
          startPoint: origin,
          endPoint: entryStation.toLatLng(),
          distanceMeters: walkToEntry.distanceMeters,
          durationSeconds: walkToEntry.durationSeconds,
          instructions: 'Walk to ${entryStation.name} Metro (${entryStation.line.label})',
          points: walkToEntry.points,
          isFallback: walkToEntry.isFallback,
        ));

        // Metro legs with realistic curves and sequential stations
        for (final leg in metroPath.legs) {
          final legStart = leg.edges.first;
          final legEnd = leg.edges.last;
          final entrySt = MetroRepository.findById(legStart.toId) ?? entryStation;
          final exitSt = MetroRepository.findById(legEnd.toId) ?? exitStation;

          // Extract sequenced track coordinates without straight lines
          final trackPoints = MetroRepository.getTrackPolylineBetween(entrySt, exitSt);

          legs.add(MetroLeg(
            startPoint: entrySt.toLatLng(),
            endPoint: exitSt.toLatLng(),
            distanceMeters: leg.edges.fold(0.0, (s, e) => s + e.distance),
            durationSeconds: leg.edges.fold(0.0, (s, e) => s + e.duration),
            instructions: 'Take ${leg.line.label} ${entrySt.name} → ${exitSt.name} (${leg.edges.length} stops)',
            entryStation: entrySt,
            exitStation: exitSt,
            line: leg.line,
            stationCount: leg.edges.length,
            trackPoints: trackPoints,
            isInterchange: leg != metroPath.legs.first,
            connectingLine: leg != metroPath.legs.first ? metroPath.legs[metroPath.legs.indexOf(leg) - 1].line : null,
          ));
        }

        // Walk from exit
        legs.add(WalkLeg(
          startPoint: exitStation.toLatLng(),
          endPoint: destination,
          distanceMeters: walkFromExit.distanceMeters,
          durationSeconds: walkFromExit.durationSeconds,
          instructions: 'Walk from ${exitStation.name} Metro to ${destinationName ?? 'destination'}',
          points: walkFromExit.points,
          isFallback: walkFromExit.isFallback,
        ));

        final totalDist = legs.fold(0.0, (s, l) => s + l.distanceMeters);
        final totalDuration = legs.fold(0.0, (s, l) => s + l.durationSeconds);
        final walkDist = legs.whereType<WalkLeg>().fold(0.0, (s, l) => s + l.distanceMeters);

        final score = totalDuration + (walkDist * 0.4);

        if (score < bestScore) {
          bestScore = score;
          bestMetro = MultimodalRoute(
            legs: legs,
            totalDistanceMeters: totalDist,
            totalDurationSeconds: totalDuration,
            summary: _buildSummary(legs),
            primaryMode: TransitMode.metro,
            bestModeBadge: '🚇 Shortest: Metro',
          );
        }
      }
    }

    return bestMetro;
  }

  /// Computes the best Suburban Train-assisted route (if viable)
  Future<MultimodalRoute?> computeTrainRouteCandidate({
    required LatLng origin,
    required LatLng destination,
    String? destinationName,
    Pandal? targetPandal,
    double maxWalkDistanceKm = 2.5,
  }) async {
    final originStations = findNearestTrainStations(origin, 3, maxDistanceKm: maxWalkDistanceKm);
    final destStations = findNearestTrainStations(destination, 3, maxDistanceKm: maxWalkDistanceKm);

    MultimodalRoute? bestTrain;
    double bestScore = double.infinity;

    for (final entryStation in originStations) {
      for (final exitStation in destStations) {
        if (entryStation.code == exitStation.code) continue;

        final trainPath = RailwayRepository.instance.computeTrainPath(entryStation, exitStation);
        if (trainPath == null) continue;

        final walkToEntry = await _routing.getWalkingRouteToPoint(
          start: origin,
          destination: entryStation.toLatLng(),
          destinationName: entryStation.name,
        );
        if (walkToEntry.distanceMeters > maxWalkDistanceKm * 1000) continue;

        final walkFromExit = await _routing.getWalkingRouteToPoint(
          start: exitStation.toLatLng(),
          destination: destination,
          destinationName: destinationName ?? 'Destination',
          targetPandal: targetPandal,
        );
        if (walkFromExit.distanceMeters > maxWalkDistanceKm * 1000) continue;

        final legs = <RouteLeg>[];

        // Walk to train station
        legs.add(WalkLeg(
          startPoint: origin,
          endPoint: entryStation.toLatLng(),
          distanceMeters: walkToEntry.distanceMeters,
          durationSeconds: walkToEntry.durationSeconds,
          instructions: 'Walk to ${entryStation.name} Station (${entryStation.code})',
          points: walkToEntry.points,
          isFallback: walkToEntry.isFallback,
        ));

        // Suburban Train leg with real track coordinates and stop-by-stop line path
        legs.add(TrainLeg(
          startPoint: entryStation.toLatLng(),
          endPoint: exitStation.toLatLng(),
          distanceMeters: trainPath.totalDistanceMeters,
          durationSeconds: trainPath.totalDurationSeconds,
          instructions: 'Take ${trainPath.corridorName} ${entryStation.name} → ${exitStation.name} (${trainPath.stationCount} stops)',
          entryStation: entryStation,
          exitStation: exitStation,
          corridorName: trainPath.corridorName,
          stationCount: trainPath.stationCount,
          trackPoints: trainPath.trackPoints,
        ));

        // Walk from exit station to destination
        legs.add(WalkLeg(
          startPoint: exitStation.toLatLng(),
          endPoint: destination,
          distanceMeters: walkFromExit.distanceMeters,
          durationSeconds: walkFromExit.durationSeconds,
          instructions: 'Walk from ${exitStation.name} to ${destinationName ?? 'destination'}',
          points: walkFromExit.points,
          isFallback: walkFromExit.isFallback,
        ));

        final totalDist = legs.fold(0.0, (s, l) => s + l.distanceMeters);
        final totalDuration = legs.fold(0.0, (s, l) => s + l.durationSeconds);
        final walkDist = legs.whereType<WalkLeg>().fold(0.0, (s, l) => s + l.distanceMeters);

        final score = totalDuration + (walkDist * 0.4);

        if (score < bestScore) {
          bestScore = score;
          bestTrain = MultimodalRoute(
            legs: legs,
            totalDistanceMeters: totalDist,
            totalDurationSeconds: totalDuration,
            summary: _buildSummary(legs),
            primaryMode: TransitMode.train,
            bestModeBadge: '🚆 Shortest: Train',
          );
        }
      }
    }

    return bestTrain;
  }

  /// Main entry point: automatically evaluates Road, Metro, and Suburban Train
  /// and returns the SHORTEST and most optimal distance option!
  Future<MultimodalRoute> computeRoute({
    required LatLng origin,
    required LatLng destination,
    String? destinationName,
    Pandal? targetPandal,
    bool preferMetro = true,
    double maxWalkDistanceKm = 3.0,
  }) async {
    debugPrint('[MultimodalRouting] Computing best shortest route from $origin to $destination');

    final directWalkDist = haversineMeters(
      origin.latitude, origin.longitude,
      destination.latitude, destination.longitude,
    );

    // 1. Direct road route
    final roadRoute = await computeRoadRoute(
      origin: origin,
      destination: destination,
      destinationName: destinationName,
      targetPandal: targetPandal,
    );

    // If close (< 900m), road walking is virtually always the shortest and fastest
    if (directWalkDist < 900) {
      debugPrint('[MultimodalRouting] Short distance (${(directWalkDist/1000).toStringAsFixed(2)} km) -> Direct Road');
      return roadRoute;
    }

    // 2. Evaluate Metro route candidate
    MultimodalRoute? metroRoute;
    try {
      metroRoute = await computeMetroRouteCandidate(
        origin: origin,
        destination: destination,
        destinationName: destinationName,
        targetPandal: targetPandal,
        maxWalkDistanceKm: maxWalkDistanceKm,
      );
    } catch (e) {
      debugPrint('[MultimodalRouting] Metro calculation exception: $e');
    }

    // 3. Evaluate Suburban Train route candidate
    MultimodalRoute? trainRoute;
    try {
      trainRoute = await computeTrainRouteCandidate(
        origin: origin,
        destination: destination,
        destinationName: destinationName,
        targetPandal: targetPandal,
        maxWalkDistanceKm: maxWalkDistanceKm,
      );
    } catch (e) {
      debugPrint('[MultimodalRouting] Train calculation exception: $e');
    }

    // 4. Compare all viable candidates to find the BEST & SHORTEST!
    // Candidates list
    final candidates = <MultimodalRoute>[roadRoute];
    if (metroRoute != null) candidates.add(metroRoute);
    if (trainRoute != null) candidates.add(trainRoute);

    MultimodalRoute best = roadRoute;

    // Pick candidate with shortest total distance or significantly faster transit time
    for (final candidate in candidates) {
      if (candidate == roadRoute) continue;

      final isDistanceShorter = candidate.totalDistanceMeters < best.totalDistanceMeters * 1.05;
      final isTimeShorter = candidate.totalDurationSeconds < best.totalDurationSeconds * 0.75;

      if (isDistanceShorter || isTimeShorter) {
        // If distance is very close, pick the one with less fatigue / faster duration
        if (candidate.totalDistanceMeters < best.totalDistanceMeters ||
            candidate.totalDurationSeconds < best.totalDurationSeconds) {
          best = candidate;
        }
      }
    }

    debugPrint('[MultimodalRouting] ✅ Best choice: ${best.bestModeBadge ?? best.summary}');
    return best;
  }

  String _buildSummary(List<RouteLeg> legs) {
    final parts = <String>[];
    for (final leg in legs) {
      if (leg is WalkLeg) {
        parts.add('🚶 ${leg.formattedDistance} (${leg.formattedDuration})');
      } else if (leg is MetroLeg) {
        parts.add('🚇 ${leg.line.label} ${leg.stationCount} stops (${leg.formattedDuration})');
      } else if (leg is TrainLeg) {
        parts.add('🚆 ${leg.corridorName} ${leg.stationCount} stops (${leg.formattedDuration})');
      }
    }
    return parts.join(' → ');
  }

  /// Compute route from current location to pandal
  Future<MultimodalRoute> computeRouteToPandal({
    required Pandal pandal,
    bool preferMetro = true,
  }) async {
    final pos = _location.currentPositionSync;
    final origin = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : LocationService.defaultKolkataCenter;

    return computeRoute(
      origin: origin,
      destination: LatLng(pandal.lat, pandal.lng),
      destinationName: pandal.name,
      targetPandal: pandal,
      preferMetro: preferMetro,
    );
  }

  /// Compute route from current location to station (metro or railway)
  Future<MultimodalRoute> computeRouteToStation({
    required dynamic station, // MetroStation or Station or RailwayStationInfo
    bool preferMetro = true,
  }) async {
    final pos = _location.currentPositionSync;
    final origin = pos != null
        ? LatLng(pos.latitude, pos.longitude)
        : LocationService.defaultKolkataCenter;

    final LatLng dest;
    final String name;

    if (station is MetroStation) {
      dest = station.toLatLng();
      name = station.name;
    } else if (station is Station) {
      dest = station.toLatLng();
      name = station.name;
    } else if (station is RailwayStationInfo) {
      dest = station.toLatLng();
      name = station.name;
    } else {
      throw ArgumentError('Unsupported station type: ${station.runtimeType}');
    }

    return computeRoute(
      origin: origin,
      destination: dest,
      destinationName: name,
      preferMetro: preferMetro,
    );
  }
}

/// Internal: Metro graph edge
class MetroEdge {
  const MetroEdge({
    required this.toId,
    required this.line,
    required this.distance,
    required this.duration,
  });

  final String toId;
  final KolkataMetroLine line;
  final double distance;
  final double duration;
}

/// Internal: Metro path leg (continuous same-line segment)
class MetroPathLeg {
  MetroPathLeg({required this.line, required this.edges});
  final KolkataMetroLine line;
  final List<MetroEdge> edges;
}

/// Internal: Complete metro path
class MetroPath {
  const MetroPath({
    required this.from,
    required this.to,
    required this.legs,
    required this.totalDuration,
    required this.totalDistance,
  });

  final MetroStation from;
  final MetroStation to;
  final List<MetroPathLeg> legs;
  final double totalDuration;
  final double totalDistance;
}

/// Internal: Priority queue node for Dijkstra
class _PQNode {
  _PQNode({required this.id, required this.dist});
  final String id;
  final double dist;
}

/// Haversine distance helper
double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  const double r = 6371000;
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

double _toRad(double deg) => deg * math.pi / 180;
