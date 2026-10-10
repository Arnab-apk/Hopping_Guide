import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/services/route_deviation_monitor.dart';
import 'package:kolkata_puja/services/journey_planner.dart';
import 'package:kolkata_puja/services/multimodal_routing_service.dart';
import 'package:kolkata_puja/services/routing_service.dart';
import 'package:kolkata_puja/services/route_guidance.dart';

import 'journey_planner_test.dart' as fixtures;

void main() {
  const path = [LatLng(22.6, 88.3), LatLng(22.6, 88.32)];
  final base = DateTime(2026, 10, 10, 12);
  Position fix(int seconds, {double accuracy = 5, double latitude = 22.601}) =>
      Position(
        latitude: latitude,
        longitude: 88.31,
        timestamp: base.add(Duration(seconds: seconds)),
        accuracy: accuracy,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 90,
        headingAccuracy: 1,
        speed: 1.4,
        speedAccuracy: 1,
      );
  test(
    'detour needs sustained fresh evidence, resets on return and cools down',
    () {
      final monitor = RouteDeviationMonitor();
      bool emit(int s, {double lat = 22.601, double accuracy = 5}) =>
          monitor.update(
            fix(s, latitude: lat, accuracy: accuracy),
            path,
            now: base.add(Duration(seconds: s)),
          );
      expect(emit(0), false);
      expect(emit(3), false);
      expect(emit(6), true);
      expect(emit(7), false);
      expect(emit(10), false);
      expect(emit(13), false);
      expect(emit(15, lat: 22.6), false);
      expect(emit(24), false);
      expect(emit(27), false);
      expect(emit(30), true);
    },
  );
  test('stale, duplicate and inaccurate GPS cannot trigger a reroute', () {
    final monitor = RouteDeviationMonitor();
    for (var s = 0; s < 15; s++) {
      expect(
        monitor.update(
          fix(s, accuracy: 70),
          path,
          now: base.add(Duration(seconds: s)),
        ),
        false,
      );
      expect(
        monitor.update(fix(s), path, now: base.add(const Duration(minutes: 1))),
        false,
      );
      expect(monitor.update(fix(0), path, now: base), false);
    }
  });
  test('accuracy radius prevents noisy parallel-street rerouting', () {
    final monitor = RouteDeviationMonitor();
    for (var s = 0; s < 15; s += 3) {
      expect(
        monitor.update(
          fix(s, accuracy: 30, latitude: 22.6004),
          path,
          now: base.add(Duration(seconds: s)),
        ),
        false,
      );
    }
  });
  test(
    'driving comparison is optional and supplies automotive guidance',
    () async {
      var calls = 0;
      final planner = JourneyPlanner(
        roadLoader: fixtures.streets,
        metroLines: {},
        trainLines: {},
        drivingLoader:
            ({
              required start,
              required destination,
              required destinationName,
              targetPandal,
            }) async {
              calls++;
              final road = await fixtures.streets(
                start: start,
                destination: destination,
                destinationName: destinationName,
              );
              return WalkingRoute(
                points: road.points,
                steps: road.steps,
                transitMode: 'drive',
                distanceMeters: road.distanceMeters,
                durationSeconds: 90,
              );
            },
      );
      final walking = await planner.plan(
        origin: path.first,
        destination: path.last,
        destinationName: 'Test',
      );
      expect(calls, 0);
      expect(walking.legs.single, isNot(isA<DriveLeg>()));
      final fastest = await planner.plan(
        origin: path.first,
        destination: path.last,
        destinationName: 'Test',
        allowDriving: true,
      );
      expect(fastest.legs.single, isA<DriveLeg>());
      expect(fastest.totalWalkDistanceMeters, 0);
      expect(fastest.bestModeBadge, 'Car/taxi');
      final leg = fastest.legs.single as DriveLeg;
      final driving = WalkingRoute(
        points: leg.points,
        steps: leg.steps,
        transitMode: 'drive',
        distanceMeters: leg.distanceMeters,
        durationSeconds: leg.durationSeconds,
      );
      expect(RouteGuidance.at(driving, path.first), isNotNull);
    },
  );
  test(
    'unavailable driving provider retains connected walking route',
    () async {
      final planner = JourneyPlanner(
        roadLoader: fixtures.streets,
        metroLines: {},
        trainLines: {},
        drivingLoader: ({
          required start,
          required destination,
          required destinationName,
          targetPandal,
        }) async => throw StateError('offline'),
      );
      final route = await planner.plan(
        origin: path.first,
        destination: path.last,
        destinationName: 'Test',
        allowDriving: true,
      );
      expect(route.bestModeBadge, 'Walk');
      expect(route.isFallback, false);
    },
  );
}
