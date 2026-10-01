import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../models/metro_station.dart';
import '../models/pandal.dart';
import '../repositories/metro_repository.dart';
import 'routing_service.dart';
import 'location_service.dart';

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
  });

  final List<LatLng> points;
  final bool isFallback;

  String get modeLabel => 'Walk';
  String get modeIcon => '🚶';
}

/// Metro leg using Kolkata Metro network
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
    this.isInterchange = false,
    this.connectingLine,
  });

  final MetroStation entryStation;
  final MetroStation exitStation;
  final KolkataMetroLine line;
  final int stationCount;
  final bool isInterchange;
  final KolkataMetroLine? connectingLine;

  String get modeLabel => 'Metro';
  String get modeIcon => '🚇';
  
  String get lineLabel => line.label;
  String get lineColorHex => '#${line.color.value.toRadixString(16).padLeft(8, '0').substring(2)}';
}

/// Complete multimodal route combining walk + metro legs
class MultimodalRoute {
  const MultimodalRoute({
    required this.legs,
    required this.totalDistanceMeters,
    required this.totalDurationSeconds,
    required this.summary,
    this.isFallback = false,
  });

  final List<RouteLeg> legs;
  final double totalDistanceMeters;
  final double totalDurationSeconds;
  final String summary;
  final bool isFallback;

  /// Total walking distance across all walk legs
  double get totalWalkDistanceMeters => legs
      .whereType<WalkLeg>()
      .fold(0.0, (sum, leg) => sum + leg.distanceMeters);

  /// Total metro distance across all metro legs
  double get totalMetroDistanceMeters => legs
      .whereType<MetroLeg>()
      .fold(0.0, (sum, leg) => sum + leg.distanceMeters);

  /// Walk legs only
  List<WalkLeg> get walkLegs => legs.whereType<WalkLeg>().toList();

  /// Metro legs only
  List<MetroLeg> get metroLegs => legs.whereType<MetroLeg>().toList();

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

  /// Get all points for map rendering (walk legs only, metro shown as straight line)
  List<LatLng> get allPointsForMap {
    final points = <LatLng>[];
    for (final leg in legs) {
      if (leg is WalkLeg) {
        points.addAll(leg.points);
      } else if (leg is MetroLeg) {
        // Add entry and exit stations for metro visualization
        points.add(leg.entryStation.toLatLng());
        points.add(leg.exitStation.toLatLng());
      }
    }
    return points;
  }

  /// Get polyline segments by type for styled rendering
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
        segments.add(RoutePolylineSegment(
          points: [leg.entryStation.toLatLng(), leg.exitStation.toLatLng()],
          type: RouteSegmentType.metro,
          color: leg.line.color,
          line: leg.line,
        ));
      }
    }
    return segments;
  }
}

/// Polyline segment for map rendering with style metadata
class RoutePolylineSegment {
  const RoutePolylineSegment({
    required this.points,
    required this.type,
    required this.color,
    this.line,
    this.isFallback = false,
  });

  final List<LatLng> points;
  final RouteSegmentType type;
  final Color color;
  final KolkataMetroLine? line;
  final bool isFallback;
}

enum RouteSegmentType { walk, metro }

/// Multimodal routing service: combines Kolkata Metro + pedestrian walking
/// Provides door-to-pandal routing with unified ETA
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
          // Find the corresponding interchange station on the other line
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
      // Find previous node
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

  /// Main entry point: compute door-to-door multimodal route
  Future<MultimodalRoute> computeRoute({
    required LatLng origin,
    required LatLng destination,
    String? destinationName,
    Pandal? targetPandal,
    bool preferMetro = true,
    double maxWalkDistanceKm = 3.0,
  }) async {
    debugPrint('[MultimodalRouting] Computing route from $origin to $destination');

    // Direct walking distance
    final directWalkDist = haversineMeters(
      origin.latitude, origin.longitude,
      destination.latitude, destination.longitude,
    );

    // If very close, just walk
    if (directWalkDist <= 800 || !preferMetro) {
      debugPrint('[MultimodalRouting] Short distance (${(directWalkDist/1000).toStringAsFixed(2)} km), walking only');
      final walkRoute = await _routing.getWalkingRouteToPoint(
        start: origin,
        destination: destination,
        destinationName: destinationName ?? 'Destination',
        targetPandal: targetPandal,
      );
      return MultimodalRoute(
        legs: [WalkLeg(
          startPoint: origin,
          endPoint: destination,
          distanceMeters: walkRoute.distanceMeters,
          durationSeconds: walkRoute.durationSeconds,
          instructions: 'Walk directly to ${destinationName ?? 'destination'}',
          points: walkRoute.points,
          isFallback: walkRoute.isFallback,
        )],
        totalDistanceMeters: walkRoute.distanceMeters,
        totalDurationSeconds: walkRoute.durationSeconds,
        summary: 'Walk ${walkRoute.formattedDistance} (${walkRoute.formattedDuration})',
        isFallback: walkRoute.isFallback,
      );
    }

    // Find candidate metro entry/exit stations
    final originStations = findNearestStations(origin, 3);
    final destStations = findNearestStations(destination, 3);

    MultimodalRoute? bestRoute;
    double bestScore = double.infinity;

    // Try all combinations of entry/exit stations
    for (final entryStation in originStations) {
      for (final exitStation in destStations) {
        // Walk to entry station
        final walkToEntry = await _routing.getWalkingRouteToPoint(
          start: origin,
          destination: entryStation.toLatLng(),
          destinationName: entryStation.name,
        );

        // Skip if walk to metro is too long
        if (walkToEntry.distanceMeters > maxWalkDistanceKm * 1000) continue;

        // Metro path
        final metroPath = computeMetroPath(entryStation, exitStation);
        if (metroPath == null) continue;

        // Walk from exit station to destination
        final walkFromExit = await _routing.getWalkingRouteToPoint(
          start: exitStation.toLatLng(),
          destination: destination,
          destinationName: destinationName ?? 'Destination',
          targetPandal: targetPandal,
        );

        // Skip if walk from metro is too long
        if (walkFromExit.distanceMeters > maxWalkDistanceKm * 1000) continue;

        // Build multimodal route
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

        // Metro legs
        for (final leg in metroPath.legs) {
          final legStart = leg.edges.first;
          final legEnd = leg.edges.last;
          final entrySt = MetroRepository.findById(legStart.toId)!;
          final exitSt = MetroRepository.findById(legEnd.toId)!;
          
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

        final totalDistance = legs.fold(0.0, (s, l) => s + l.distanceMeters);
        final totalDuration = legs.fold(0.0, (s, l) => s + l.durationSeconds);
        final walkDistance = legs.whereType<WalkLeg>().fold(0.0, (s, l) => s + l.distanceMeters);

        // Score: prioritize time, then minimize walking
        final score = totalDuration + (walkDistance * 0.5);

        if (score < bestScore) {
          bestScore = score;
          bestRoute = MultimodalRoute(
            legs: legs,
            totalDistanceMeters: totalDistance,
            totalDurationSeconds: totalDuration,
            summary: _buildSummary(legs),
          );
        }
      }
    }

    // Fallback to walking only if no good metro route found
    if (bestRoute == null) {
      debugPrint('[MultimodalRouting] No viable metro route, falling back to walk');
      final walkRoute = await _routing.getWalkingRouteToPoint(
        start: origin,
        destination: destination,
        destinationName: destinationName ?? 'Destination',
        targetPandal: targetPandal,
      );
      return MultimodalRoute(
        legs: [WalkLeg(
          startPoint: origin,
          endPoint: destination,
          distanceMeters: walkRoute.distanceMeters,
          durationSeconds: walkRoute.durationSeconds,
          instructions: 'Walk directly to ${destinationName ?? 'destination'}',
          points: walkRoute.points,
          isFallback: walkRoute.isFallback,
        )],
        totalDistanceMeters: walkRoute.distanceMeters,
        totalDurationSeconds: walkRoute.durationSeconds,
        summary: 'Walk ${walkRoute.formattedDistance} (${walkRoute.formattedDuration})',
        isFallback: true,
      );
    }

    debugPrint('[MultimodalRouting] ✅ Best route: ${bestRoute.summary}');
    return bestRoute!;
  }

  String _buildSummary(List<RouteLeg> legs) {
    final parts = <String>[];
    for (final leg in legs) {
      if (leg is WalkLeg) {
        parts.add('🚶 ${leg.formattedDistance} (${leg.formattedDuration})');
      } else if (leg is MetroLeg) {
        parts.add('🚇 ${leg.line.label} ${leg.stationCount} stops (${leg.formattedDuration})');
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

  /// Compute route from current location to metro station
  Future<MultimodalRoute> computeRouteToStation({
    required MetroStation station,
    bool preferMetro = true,
  }) async {
    final pos = _location.currentPositionSync;
    final origin = pos != null 
        ? LatLng(pos.latitude, pos.longitude) 
        : LocationService.defaultKolkataCenter;
    
    return computeRoute(
      origin: origin,
      destination: station.toLatLng(),
      destinationName: station.name,
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

/// Haversine distance helper (copied from routing_service to avoid circular import)
double haversineMeters(double lat1, double lon1, double lat2, double lon2) {
  const double r = 6371000; // Earth radius in meters
  final dLat = _toRad(lat2 - lat1);
  final dLon = _toRad(lon2 - lon1);
  final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(_toRad(lat1)) * math.cos(_toRad(lat2)) *
      math.sin(dLon / 2) * math.sin(dLon / 2);
  final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  return r * c;
}

double _toRad(double deg) => deg * math.pi / 180;