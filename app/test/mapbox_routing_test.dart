import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/services/routing_service.dart';
import 'package:kolkata_puja/services/mapbox_directions_service.dart';
import 'package:kolkata_puja/services/route_guidance.dart';
import 'package:kolkata_puja/widgets/mapbox_navigation_guidance.dart';
import 'package:kolkata_puja/services/live_tracking_enhancements.dart';
import 'package:kolkata_puja/services/location_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:geolocator/geolocator.dart';

const _start = LatLng(22.55, 88.35);
const _turn = LatLng(22.551, 88.35);
const _end = LatLng(22.551, 88.351);

String _response(List<LatLng> points) => jsonEncode({
  'code': 'Ok',
  'routes': [
    {
      'distance': 220,
      'duration': 180,
      'geometry': {
        'type': 'LineString',
        'coordinates': points.map((p) => [p.longitude, p.latitude]).toList(),
      },
      'legs': [
        {
          'steps': [
            for (var i = 0; i < points.length; i++)
              {
                'distance': i == points.length - 1 ? 0 : 110,
                'duration': i == points.length - 1 ? 0 : 90,
                'name': 'Kolkata Street',
                'maneuver': {
                  'type': i == 0
                      ? 'depart'
                      : i == points.length - 1
                      ? 'arrive'
                      : 'turn',
                  'modifier': 'right',
                  'instruction': i == points.length - 1
                      ? 'You have arrived'
                      : i == 0
                      ? 'Head north'
                      : 'Turn right onto Kolkata Street',
                  'location': [points[i].longitude, points[i].latitude],
                },
              },
          ],
        },
      ],
    },
  ],
});

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'driving uses the automotive traffic profile and retains maneuvers',
    () async {
      final requests = <Uri>[];
      final routing = RoutingService(
        mapboxAccessToken: 'test',
        client: MockClient((request) async {
          requests.add(request.url);
          return http.Response(_response([_start, _turn, _end]), 200);
        }),
      );
      await routing.getLiveWalkingRouteToPoint(
        start: _start,
        destination: _end,
        destinationName: 'Walk',
      );
      final drive = await routing.getLiveDrivingRouteToPoint(
        start: _start,
        destination: _end,
        destinationName: 'Taxi',
      );
      expect(requests.last.path, contains('/driving-traffic/'));
      expect(requests.length, 2);
      expect(drive.isDriving, true);
      expect(drive.steps.length, 3);
      expect(RouteGuidance.at(drive, _turn), isNotNull);
    },
  );

  testWidgets(
    'the final leg guides toward the destination until arrival is confirmed',
    (tester) async {
      LocationService.enableTestMode = true;
      SquadService.enableTestMode = true;
      final engine = LiveTrackingEngine.instance;
      addTearDown(() {
        engine.stopTracking();
        LocationService.enableTestMode = false;
        SquadService.enableTestMode = false;
      });
      final service = RoutingService(
        mapboxAccessToken: 'test',
        client: MockClient(
          (_) async => http.Response(_response([_start, _turn, _end]), 200),
        ),
      );
      final route = await service.getLiveWalkingRouteToPoint(
        start: _start,
        destination: _end,
        destinationName: 'Test destination',
      );
      await engine.startTracking(
        destination: _end,
        destinationName: 'Test destination',
        precomputedRoute: route,
      );
      LocationService.instance.emitTestPosition(
        Position(
          latitude: 22.551,
          longitude: 88.3505,
          timestamp: DateTime(2026, 10, 10),
          accuracy: 5,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 1.2,
          speedAccuracy: 0,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: MapboxNavigationGuidance(route: route),
            ),
          ),
        ),
      );
      expect(find.text('Continue to Test destination'), findsOneWidget);
      expect(find.text('You have arrived'), findsNothing);
      expect(tester.takeException(), isNull);
      engine.stopTracking();
      await tester.pumpWidget(const SizedBox());
    },
  );

  test('concurrent live requests share one provider call without sharing destination labels', () async {
    var calls = 0;
    final response = Completer<http.Response>();
    final service = RoutingService(
      mapboxAccessToken: 'test-token',
      client: MockClient((_) {
        calls++;
        return response.future;
      }),
    );
    final first = service.getLiveWalkingRouteToPoint(
      start: _start,
      destination: _end,
      destinationName: 'First',
    );
    final second = service.getLiveWalkingRouteToPoint(
      start: _start,
      destination: _end,
      destinationName: 'Second',
    );
    response.complete(http.Response(_response([_start, _turn, _end]), 200));
    expect((await first).destinationTitle, 'First');
    expect((await second).destinationTitle, 'Second');
    expect(calls, 1);
  });

  testWidgets(
    'stopping guidance while a reroute is pending prevents stale route replacement',
    (tester) async {
      LocationService.enableTestMode = true;
      SquadService.enableTestMode = true;
      final response = Completer<http.Response>();
      var calls = 0;
      final service = RoutingService(
        mapboxAccessToken: 'test',
        client: MockClient((_) {
          calls++;
          return response.future;
        }),
      );
      final engine = LiveTrackingEngine.forTesting(service);
      final initial = RoutingService(
        mapboxAccessToken: 'test',
        client: MockClient(
          (_) async => http.Response(_response([_start, _turn, _end]), 200),
        ),
      );
      final route = await initial.getLiveWalkingRouteToPoint(
        start: _start,
        destination: _end,
        destinationName: 'Test',
      );
      var updates = 0;
      engine.onRouteRecalculated = (_) => updates++;
      Position position(double latitude, int second) => Position(
        latitude: latitude,
        longitude: 88.352,
        timestamp: DateTime.now().add(Duration(seconds: second)),
        accuracy: 5,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 1.2,
        speedAccuracy: 0,
      );
      await engine.startTracking(
        destination: _end,
        destinationName: 'Test',
        precomputedRoute: route,
      );
      LocationService.instance.emitTestPosition(position(22.55, 0));
      LocationService.instance.emitTestPosition(position(22.5501, 3));
      LocationService.instance.emitTestPosition(position(22.5502, 6));
      await tester.pump(const Duration(seconds: 16));
      expect(calls, 1);
      engine.stopTracking();
      response.complete(http.Response(_response([_start, _turn, _end]), 200));
      await tester.pump();
      expect(engine.activeRoute, isNull);
      expect(engine.guidance, isNull);
      expect(updates, 0);
      engine.dispose();
      LocationService.enableTestMode = false;
      SquadService.enableTestMode = false;
      await tester.pump(const Duration(minutes: 1));
      expect(tester.takeException(), isNull);
    },
  );

  test('walking profile returns geometry, duration and provider maneuvers; cache retains steps', () async {
    var requests = 0;
    final service = RoutingService(
      mapboxAccessToken: 'test-token',
      client: MockClient((request) async {
        requests++;
        expect(request.url.host, 'api.mapbox.com');
        expect(
          request.url.path,
          contains('/mapbox/walking/88.35,22.55;88.351,22.551'),
        );
        expect(request.url.queryParameters['steps'], 'true');
        expect(request.url.queryParameters['access_token'], 'test-token');
        return http.Response(_response([_start, _turn, _end]), 200);
      }),
    );
    final route = await service.getLiveWalkingRouteToPoint(
      start: _start,
      destination: _end,
      destinationName: 'First',
    );
    expect(route.isFallback, isFalse);
    expect(route.durationSeconds, 180);
    expect(route.steps[1].instruction, 'Turn right onto Kolkata Street');
    expect(route.steps.map((s) => s.pointIndex), [0, 1, 2]);
    final cached = await service.getWalkingRouteToPoint(
      start: _start,
      destination: _end,
      destinationName: 'Renamed',
    );
    expect(cached.destinationTitle, 'Renamed');
    expect(cached.steps.length, 3);
    expect(requests, 1);
  });

  test(
    'guidance measures distance along streets and advances past a maneuver',
    () async {
      final service = RoutingService(
        mapboxAccessToken: 'test-token',
        client: MockClient(
          (_) async => http.Response(_response([_start, _turn, _end]), 200),
        ),
      );
      final route = await service.getLiveWalkingRouteToPoint(
        start: _start,
        destination: _end,
        destinationName: 'Test',
      );
      final before = RouteGuidance.at(route, const LatLng(22.5505, 88.35))!;
      expect(before.step.type, 'turn');
      expect(before.distanceToTurnMeters, closeTo(55.6, 1));
      expect(before.remainingMeters, greaterThan(before.distanceToTurnMeters));
      final after = RouteGuidance.at(route, const LatLng(22.551, 88.3505))!;
      expect(after.step.type, 'arrive');
      expect(after.arrived, isFalse);
      expect(RouteGuidance.at(route, _end)!.arrived, isTrue);
      final preview = WalkingRoute(
        points: [_start, _end],
        distanceMeters: 220,
        durationSeconds: 180,
        isFallback: true,
        steps: route.steps,
      );
      expect(RouteGuidance.at(preview, _start), isNull);
    },
  );

  for (final status in [401, 403, 429, 500]) {
    test(
      'HTTP $status cannot become live guidance or expose the token',
      () async {
        final service = RoutingService(
          mapboxAccessToken: 'test-secret',
          client: MockClient((_) async => http.Response('Denied', status)),
        );
        await expectLater(
          service.getLiveWalkingRouteToPoint(
            start: _start,
            destination: _end,
            destinationName: 'Test',
          ),
          throwsA(
            isA<MapboxRoutingException>().having(
              (e) => e.toString(),
              'safe message',
              isNot(contains('test-secret')),
            ),
          ),
        );
        final preview = await service.getWalkingRouteToPoint(
          start: _start,
          destination: _end,
          destinationName: 'Test',
        );
        expect(preview.isFallback, isTrue);
        expect(preview.steps, isEmpty);
      },
    );
  }

  test('network exceptions are sanitized and malformed/no-route responses are handled', () async {
    for (final body in [
      'not json',
      '{"code":"NoRoute","routes":[]}',
      '{"code":"Ok","routes":[]}',
    ]) {
      final provider = MapboxDirectionsService(
        accessToken: 'secret',
        client: MockClient((_) async => http.Response(body, 200)),
      );
      await expectLater(
        provider.walking([_start, _end]),
        throwsA(isA<MapboxRoutingException>()),
      );
    }
    final provider = MapboxDirectionsService(
      accessToken: 'secret',
      client: MockClient(
        (request) async => throw http.ClientException(request.url.toString()),
      ),
    );
    await expectLater(
      provider.walking([_start, _end]),
      throwsA(
        isA<MapboxRoutingException>().having(
          (e) => e.toString(),
          'safe message',
          isNot(contains('secret')),
        ),
      ),
    );
  });

  test(
    'long trails split at 25 coordinates without changing visit order',
    () async {
      final waypoints = List.generate(
        30,
        (i) => LatLng(22.55 + i * 0.001, 88.35),
      );
      final visited = <List<LatLng>>[];
      final provider = MapboxDirectionsService(
        accessToken: 'test-token',
        client: MockClient((request) async {
          final points = request.url.pathSegments.last.split(';').map((value) {
            final pair = value.split(',');
            return LatLng(double.parse(pair[1]), double.parse(pair[0]));
          }).toList();
          visited.add(points);
          return http.Response(_response(points), 200);
        }),
      );
      final route = await provider.walking(waypoints);
      expect(visited.map((part) => part.length), [25, 6]);
      expect(visited[1].first, visited[0].last);
      expect(route.points, waypoints);
      expect(route.steps.where((step) => step.type == 'arrive').length, 1);
      expect(route.steps.last.pointIndex, 29);
    },
  );

  testWidgets('Mapbox maneuver preview fits a compact screen with large text', (
    tester,
  ) async {
    final service = RoutingService(
      mapboxAccessToken: 'test',
      client: MockClient(
        (_) async => http.Response(_response([_start, _turn, _end]), 200),
      ),
    );
    final route = await service.getLiveWalkingRouteToPoint(
      start: _start,
      destination: _end,
      destinationName: 'Test',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(2)),
            child: SizedBox(
              width: 200,
              child: MapboxNavigationGuidance(route: route),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Directions by Mapbox · Preview'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
