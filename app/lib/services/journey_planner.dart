import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/metro_station.dart';
import '../models/pandal.dart';
import '../repositories/metro_repository.dart';
import '../repositories/railway_repository.dart';
import '../utils/haversine.dart';
import 'multimodal_routing_service.dart' hide haversineMeters;
import 'routing_service.dart';
import 'transit_geometry.dart';

typedef JourneyRoadLoader = Future<WalkingRoute> Function({
  required LatLng start,
  required LatLng destination,
  required String destinationName,
  Pandal? targetPandal,
});

/// A connected itinerary: real pedestrian directions plus station-network rides.
/// Ride times are estimates, not departure times or live service guarantees.
class JourneyPlanner {
  JourneyPlanner({
    JourneyRoadLoader? roadLoader,
    JourneyRoadLoader? drivingLoader,
    Map<KolkataMetroLine, List<MetroStation>>? metroLines,
    Map<String, List<RailwayStationInfo>>? trainLines,
  }) : _roadLoader =
           roadLoader ?? RoutingService.instance.getLiveWalkingRouteToPoint,
       _drivingLoader =
           drivingLoader ?? RoutingService.instance.getLiveDrivingRouteToPoint,
       _metroLines =
           metroLines ??
           {
             for (final line in KolkataMetroLine.values)
               line: MetroRepository.getStationsForLine(line),
           },
       _trainLines = trainLines ?? RailwayRepository.instance.corridors;

  static final instance = JourneyPlanner();
  final JourneyRoadLoader _roadLoader;
  final JourneyRoadLoader _drivingLoader;
  final Map<KolkataMetroLine, List<MetroStation>> _metroLines;
  final Map<String, List<RailwayStationInfo>> _trainLines;

  Future<MultimodalRoute> plan({
    required LatLng origin,
    required LatLng destination,
    required String destinationName,
    Pandal? targetPandal,
    bool allowMetro = true,
    bool allowTrain = true,
    bool allowDriving = false,
  }) async {
    final roadCache = <String, Future<WalkLeg>>{};
    Future<WalkLeg> walk(
      LatLng from,
      LatLng to,
      String instruction, {
      bool transfer = false,
    }) {
      final key = '$from>$to>$transfer>$instruction';
      return roadCache.putIfAbsent(key, () async {
        if (_meters(from, to) < 10) {
          return WalkLeg(
            startPoint: from,
            endPoint: to,
            distanceMeters: 0,
            durationSeconds: 0,
            instructions: instruction,
            points: [from, to],
          );
        }
        final route = await _roadLoader(
          start: from,
          destination: to,
          destinationName: instruction,
          targetPandal: to == destination ? targetPandal : null,
        );
        if (route.isFallback ||
            route.points.length < 2 ||
            route.steps.isEmpty) {
          throw StateError(
            'Street directions are unavailable. Check your connection and retry.',
          );
        }
        if (transfer && route.distanceMeters > 1200) {
          throw StateError(
            '$instruction needs a ${route.distanceMeters.round()} m walk; try another interchange.',
          );
        }
        return WalkLeg(
          startPoint: from,
          endPoint: to,
          distanceMeters: route.distanceMeters,
          durationSeconds: route.durationSeconds,
          instructions: instruction,
          points: route.points,
          steps: route.steps,
        );
      });
    }

    MultimodalRoute? best;
    try {
      final direct = await walk(
        origin,
        destination,
        'Walk to $destinationName',
      );
      best = _route([direct]);
    } catch (_) {
      // A pedestrian route may be unavailable across a river; try the rail network.
    }
    if (_meters(origin, destination) >= 900 && (allowMetro || allowTrain)) {
      final candidates = _transitPaths(
        origin,
        destination,
        allowMetro,
        allowTrain,
      );
      for (final candidate in candidates.take(8)) {
        try {
          final legs = <RouteLeg>[];
          var cursor = origin;
          var i = 0;
          while (i < candidate.edges.length) {
            final edge = candidate.edges[i];
            if (edge.mode == TransitMode.road) {
              final access = await walk(
                cursor,
                edge.to.point,
                'Transfer on foot to ${edge.to.name}',
                transfer: true,
              );
              legs.add(
                WalkLeg(
                  startPoint: access.startPoint,
                  endPoint: access.endPoint,
                  distanceMeters: access.distanceMeters,
                  durationSeconds: access.durationSeconds + 180,
                  instructions: access.instructions,
                  points: access.points,
                  steps: access.steps,
                ),
              );
              cursor = edge.to.point;
              i++;
              continue;
            }
            if (_meters(cursor, edge.from.point) >= 10) {
              legs.add(
                await walk(
                  cursor,
                  edge.from.point,
                  'Walk to ${edge.from.name} station',
                ),
              );
            }
            final ride = <_TransitEdge>[edge];
            i++;
            while (i < candidate.edges.length &&
                candidate.edges[i].service == edge.service &&
                candidate.edges[i].mode == edge.mode) {
              ride.add(candidate.edges[i++]);
            }
            final last = ride.last;
            final points = <LatLng>[];
            var geometryEstimated = false;
            for (final hop in ride) {
              final section = await TransitGeometry.section(
                hop.service,
                hop.from.metro?.id ?? hop.from.train!.code,
                hop.to.metro?.id ?? hop.to.train!.code,
              );
              if (section == null) geometryEstimated = true;
              points.addAll(section ?? [hop.from.point, hop.to.point]);
            }
            var distance = 0.0;
            for (var p = 1; p < points.length; p++) {
              distance += _meters(points[p - 1], points[p]);
            }
            final seconds =
                ride.fold<double>(0, (sum, hop) => sum + hop.seconds) + 300;
            final instruction =
                'Take ${edge.serviceName} toward ${edge.toward}: '
                '${edge.from.name} to ${last.to.name} (${ride.length} ${ride.length == 1 ? 'stop' : 'stops'})';
            if (edge.mode == TransitMode.metro) {
              legs.add(
                MetroLeg(
                  startPoint: edge.from.point,
                  endPoint: last.to.point,
                  distanceMeters: distance,
                  durationSeconds: seconds,
                  instructions: instruction,
                  entryStation: edge.from.metro!,
                  exitStation: last.to.metro!,
                  line: edge.line!,
                  stationCount: ride.length,
                  trackPoints: points,
                  geometryEstimated: geometryEstimated,
                ),
              );
            } else {
              legs.add(
                TrainLeg(
                  startPoint: edge.from.point,
                  endPoint: last.to.point,
                  distanceMeters: distance,
                  durationSeconds: seconds,
                  instructions: instruction,
                  entryStation: edge.from.train!,
                  exitStation: last.to.train!,
                  corridorName: edge.serviceName,
                  stationCount: ride.length,
                  trackPoints: points,
                  geometryEstimated: geometryEstimated,
                ),
              );
            }
            cursor = last.to.point;
          }
          if (_meters(cursor, destination) >= 10) {
            legs.add(
              await walk(cursor, destination, 'Walk to $destinationName'),
            );
          }
          final route = _route(legs);
          if (best == null ||
              route.totalDurationSeconds < best.totalDurationSeconds) {
            best = route;
          }
        } catch (_) {
          // Reject the entire disconnected candidate, never invent a road connector.
        }
      }
    }
    if (allowDriving) {
      try {
        final drive = await _drivingLoader(
          start: origin,
          destination: destination,
          destinationName: destinationName,
          targetPandal: targetPandal,
        );
        if (!drive.isFallback &&
            drive.points.length >= 2 &&
            drive.steps.isNotEmpty) {
          final driveEnd = drive.points.last;
          final driveStart = drive.points.first;
          final needsAccess = _meters(origin, driveStart) > 25;
          final candidate = _route([
            if (needsAccess)
              await walk(
                origin,
                driveStart,
                'Walk to the car/taxi pickup point',
              ),
            DriveLeg(
              startPoint: needsAccess ? driveStart : origin,
              endPoint: driveEnd,
              distanceMeters: drive.distanceMeters,
              durationSeconds: drive.durationSeconds,
              instructions: 'Drive or take a taxi to $destinationName',
              points: drive.points,
              steps: drive.steps,
            ),
            if (_meters(driveEnd, destination) > 25)
              await walk(driveEnd, destination, 'Walk to $destinationName'),
          ]);
          if (best == null ||
              candidate.totalDurationSeconds < best.totalDurationSeconds) {
            best = candidate;
          }
        }
      } catch (_) {
        /* Retain the connected walking/transit option. */
      }
    }
    if (best == null) {
      throw StateError(
        'No connected route is available. Check your connection and retry.',
      );
    }
    return best;
  }

  MultimodalRoute _route(List<RouteLeg> legs) {
    final metro = legs.any((leg) => leg is MetroLeg);
    final train = legs.any((leg) => leg is TrainLeg);
    return MultimodalRoute(
      legs: legs,
      totalDistanceMeters: legs.fold(0, (sum, leg) => sum + leg.distanceMeters),
      totalDurationSeconds: legs.fold(
        0,
        (sum, leg) => sum + leg.durationSeconds,
      ),
      primaryMode: train
          ? TransitMode.train
          : metro
          ? TransitMode.metro
          : TransitMode.road,
      bestModeBadge: train && metro
          ? 'Train + Metro'
          : train
          ? 'Train + Walk'
          : metro
          ? 'Metro + Walk'
          : legs.any((leg) => leg is DriveLeg)
          ? 'Car/taxi'
          : 'Walk',
      summary: legs.map((leg) => leg.instructions).join(' → '),
    );
  }

  List<_TransitPath> _transitPaths(
    LatLng origin,
    LatLng destination,
    bool metro,
    bool train,
  ) {
    final nodes = <String, _TransitNode>{};
    final graph = <String, List<_TransitEdge>>{};
    void line(
      List<_TransitNode> stations,
      TransitMode mode,
      String service,
      String name,
      KolkataMetroLine? colorLine,
    ) {
      for (final station in stations) {
        nodes[station.id] = station;
        graph[station.id] = [];
      }
      for (var i = 0; i < stations.length - 1; i++) {
        final a = stations[i], b = stations[i + 1];
        final distance = _meters(a.point, b.point);
        final seconds = distance / (mode == TransitMode.metro ? 9.7 : 12) + 40;
        graph[a.id]!.add(
          _TransitEdge(
            a,
            b,
            mode,
            service,
            name,
            stations.last.name,
            distance,
            seconds,
            colorLine,
          ),
        );
        graph[b.id]!.add(
          _TransitEdge(
            b,
            a,
            mode,
            service,
            name,
            stations.first.name,
            distance,
            seconds,
            colorLine,
          ),
        );
      }
    }

    if (metro) {
      for (final entry in _metroLines.entries) {
        line(
          entry.value
              .map(
                (s) => _TransitNode(
                  'm:${entry.key.name}:${s.id}',
                  s.name,
                  s.toLatLng(),
                  metro: s,
                ),
              )
              .toList(),
          TransitMode.metro,
          'metro:${entry.key.name}',
          entry.key.label,
          entry.key,
        );
      }
    }
    if (train) {
      for (final entry in _trainLines.entries) {
        if (entry.value.isEmpty) continue;
        line(
          entry.value
              .map(
                (s) => _TransitNode(
                  'r:${entry.key}:${s.code}',
                  s.name,
                  s.toLatLng(),
                  train: s,
                ),
              )
              .toList(),
          TransitMode.train,
          'rail:${entry.key}',
          entry.value.first.corridorName,
          null,
        );
      }
    }
    final all = nodes.values.toList();
    for (var i = 0; i < all.length; i++) {
      for (var j = i + 1; j < all.length; j++) {
        final a = all[i], b = all[j];
        final sameStation =
            (a.metro != null && b.metro?.id == a.metro!.id) ||
            (a.train != null && b.train?.code == a.train!.code);
        final mixed = (a.metro != null) != (b.metro != null);
        final distance = _meters(a.point, b.point);
        if (sameStation || (mixed && distance <= 800)) {
          final seconds = distance * 1.35 / 1.25 + 180;
          graph[a.id]!.add(
            _TransitEdge(
              a,
              b,
              TransitMode.road,
              'transfer',
              'Transfer',
              '',
              distance,
              seconds,
              null,
            ),
          );
          graph[b.id]!.add(
            _TransitEdge(
              b,
              a,
              TransitMode.road,
              'transfer',
              'Transfer',
              '',
              distance,
              seconds,
              null,
            ),
          );
        }
      }
    }
    final start = all.where((n) => _meters(origin, n.point) <= 3000).toList()
      ..sort(
        (a, b) => _meters(origin, a.point).compareTo(_meters(origin, b.point)),
      );
    final finish =
        all.where((n) => _meters(destination, n.point) <= 3000).toList()..sort(
          (a, b) => _meters(
            destination,
            a.point,
          ).compareTo(_meters(destination, b.point)),
        );
    final results = <_TransitPath>[];
    // Nodes represent platforms on a specific line, so line changes carry a
    // transfer edge and cannot silently jump between services.
    for (final entry in start.take(6)) {
      final costs = <String, double>{
        entry.id: _meters(origin, entry.point) * 1.35 / 1.25 + 300,
      };
      final previous = <String, _TransitEdge>{};
      final pending = <String>{entry.id}, visited = <String>{};
      while (pending.isNotEmpty) {
        final current = pending.reduce(
          (a, b) => costs[a]! <= costs[b]! ? a : b,
        );
        pending.remove(current);
        visited.add(current);
        for (final edge in graph[current]!) {
          if (visited.contains(edge.to.id)) continue;
          final cost = costs[current]! + edge.seconds;
          if (cost < (costs[edge.to.id] ?? double.infinity)) {
            costs[edge.to.id] = cost;
            previous[edge.to.id] = edge;
            pending.add(edge.to.id);
          }
        }
      }
      for (final exit in finish.take(6)) {
        if (!previous.containsKey(exit.id)) continue;
        var cursor = exit.id;
        final reverse = <_TransitEdge>[];
        while (cursor != entry.id) {
          final edge = previous[cursor];
          if (edge == null) {
            reverse.clear();
            break;
          }
          reverse.add(edge);
          cursor = edge.from.id;
        }
        final edges = reverse.reversed.toList();
        if (!edges.any((edge) => edge.mode != TransitMode.road)) continue;
        results.add(
          _TransitPath(
            edges,
            costs[exit.id]! + _meters(exit.point, destination) * 1.35 / 1.25,
          ),
        );
      }
    }
    results.sort((a, b) => a.seconds.compareTo(b.seconds));
    final seen = <String>{};
    return results
        .where(
          (path) => seen.add(
            path.edges.map((e) => '${e.from.id}>${e.to.id}').join('|'),
          ),
        )
        .toList();
  }

  static double _meters(LatLng a, LatLng b) => math.max(
    0,
    haversineMeters(a.latitude, a.longitude, b.latitude, b.longitude),
  );
}

class _TransitNode {
  const _TransitNode(this.id, this.name, this.point, {this.metro, this.train});
  final String id, name;
  final LatLng point;
  final MetroStation? metro;
  final RailwayStationInfo? train;
}

class _TransitEdge {
  const _TransitEdge(
    this.from,
    this.to,
    this.mode,
    this.service,
    this.serviceName,
    this.toward,
    this.distance,
    this.seconds,
    this.line,
  );
  final _TransitNode from, to;
  final TransitMode mode;
  final String service, serviceName, toward;
  final double distance, seconds;
  final KolkataMetroLine? line;
}

class _TransitPath {
  const _TransitPath(this.edges, this.seconds);
  final List<_TransitEdge> edges;
  final double seconds;
}
