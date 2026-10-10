import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/models/navigation_step.dart';
import 'package:kolkata_puja/services/live_tracking_enhancements.dart';
import 'package:kolkata_puja/services/location_service.dart';
import 'package:kolkata_puja/services/navigation_session.dart';
import 'package:kolkata_puja/services/navigation_simulator.dart';
import 'package:kolkata_puja/services/route_guidance.dart';
import 'package:kolkata_puja/services/routing_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/widgets/navigation_overlay.dart';

const start = LatLng(22.55, 88.35),
    turn = LatLng(22.55, 88.352),
    end = LatLng(22.552, 88.352);
WalkingRoute fixture() => const WalkingRoute(
  customTitle: 'Home',
  points: [start, turn, end],
  distanceMeters: 430,
  durationSeconds: 360,
  waypoints: [start, end],
  steps: [
    NavigationStep(
      instruction: 'Head out',
      pointIndex: 0,
      distanceMeters: 200,
      durationSeconds: 180,
      type: 'depart',
    ),
    NavigationStep(
      instruction: 'Turn left onto Lane',
      pointIndex: 1,
      distanceMeters: 230,
      durationSeconds: 180,
      type: 'turn',
      modifier: 'left',
      roadName: 'Lane',
    ),
    NavigationStep(
      instruction: 'You have arrived',
      pointIndex: 2,
      distanceMeters: 0,
      durationSeconds: 0,
      type: 'arrive',
    ),
  ],
);

String providerResponse() => jsonEncode({
  'code': 'Ok',
  'routes': [
    {
      'geometry': {
        'coordinates': [
          [88.35, 22.55],
          [88.352, 22.55],
          [88.352, 22.552],
        ],
      },
      'distance': 430,
      'duration': 360,
      'legs': [
        {
          'steps': [
            for (final step in fixture().steps)
              {
                'distance': step.distanceMeters,
                'duration': step.durationSeconds,
                'name': step.roadName,
                'maneuver': {
                  'instruction': step.instruction,
                  'type': step.type,
                  'modifier': step.modifier,
                  'location': [
                    fixture().points[step.pointIndex].longitude,
                    fixture().points[step.pointIndex].latitude,
                  ],
                },
              },
          ],
        },
      ],
    },
  ],
});

void main() {
  setUp(() {
    LocationService.enableTestMode = true;
    SquadService.enableTestMode = true;
  });
  tearDown(() {
    LocationService.enableTestMode = false;
    SquadService.enableTestMode = false;
  });

  testWidgets(
    'Start refreshes a stationary stale fix before activating guidance',
    (tester) async {
      final clock = DateTime.now();
      final engine = LiveTrackingEngine.forTesting(
        RoutingService(mapboxAccessToken: 'test'),
      );
      var refreshed = 0;
      final simulator = NavigationSimulator(fixture());
      LocationService.instance.emitTestPosition(
        simulator.fixAt(0, clock.subtract(const Duration(minutes: 2))),
      );
      final session = NavigationSession(
        engine: engine,
        now: () => clock,
        refreshPosition: () async {
          refreshed++;
          final fresh = simulator.fixAt(0, clock);
          LocationService.instance.emitTestPosition(fresh);
          return fresh;
        },
      );
      session.preview(fixture());
      expect(await session.begin(), isTrue);
      expect(refreshed, 1);
      expect(session.live, isTrue);
      session.dispose();
      engine.dispose();
      await tester.pump(const Duration(minutes: 1));
    },
  );

  test('geometry exposes connector endpoint and starts with depart', () {
    final simulator = NavigationSimulator(fixture());
    final off = simulator.fixAt(80, DateTime.now(), lateralMeters: 30);
    final snap = RouteGuidance.at(
      fixture(),
      LatLng(off.latitude, off.longitude),
    )!;
    expect(snap.deviationMeters, closeTo(30, 1));
    expect(snap.snappedPoint!.latitude, closeTo(start.latitude, 0.000001));
    expect(RouteGuidance.at(fixture(), start)!.step.type, 'depart');
    expect(RouteGuidance.at(fixture(), end)!.arrived, isTrue);
    expect(maneuverRotation('left'), -90);
    expect(navigationDistance(126), '130 m');
  });

  test(
    'segment hint keeps a returning route from jumping to the earlier leg',
    () {
      final points = <LatLng>[
        for (var i = 0; i < 100; i++) LatLng(22.55, 88.35 + i * 0.0001),
        for (var i = 99; i >= 0; i--) LatLng(22.55005, 88.35 + i * 0.0001),
      ];
      final route = WalkingRoute(
        points: points,
        distanceMeters: 2200,
        durationSeconds: 1200,
        steps: fixture().steps,
      );
      final snap = RouteGuidance.at(
        route,
        const LatLng(22.55002, 88.354),
        segmentHint: 155,
      )!;
      expect(snap.segmentIndex, greaterThan(100));
      final lost = RouteGuidance.at(
        route,
        const LatLng(22.55, 88.351),
        segmentHint: 80,
      )!;
      expect(lost.segmentIndex, lessThan(20));
    },
  );

  testWidgets(
    'simulator preview/start/turn/three fixes/reroute/arrival cleans up',
    (tester) async {
      var clock = DateTime(2026, 10, 10, 12);
      final response = Completer<http.Response>();
      var calls = 0;
      final routing = RoutingService(
        mapboxAccessToken: 'test',
        client: MockClient((_) {
          calls++;
          return response.future;
        }),
      );
      final engine = LiveTrackingEngine.forTesting(routing);
      final session = NavigationSession(engine: engine, now: () => clock);
      final simulator = NavigationSimulator(fixture());
      void emit(double along, {double lateral = 0, double accuracy = 8}) {
        clock = clock.add(const Duration(seconds: 1));
        LocationService.instance.emitTestPosition(
          simulator.fixAt(
            along,
            clock,
            lateralMeters: lateral,
            accuracy: accuracy,
          ),
        );
      }

      emit(0);
      session.preview(fixture());
      expect(session.state, NavigationState.previewing);
      expect(engine.activeRoute, isNull);
      expect(await session.begin(), isTrue);
      expect(session.title, 'Head out');
      emit(80);
      expect(session.title, 'Turn left onto Lane');
      expect(session.remainingMeters, lessThan(430));
      expect(session.live, isTrue);
      session.panAway();
      expect(session.following, isFalse);
      session.recenter();
      expect(session.following, isTrue);
      emit(85, lateral: 60);
      // Compass notifications carrying the same timestamp cannot count as new fixes.
      LocationService.instance.emitTestHeading(90);
      expect(calls, 0);
      emit(86, lateral: 60);
      expect(calls, 0);
      emit(87, lateral: 60);
      await tester.pump();
      expect(calls, 1);
      expect(session.state, NavigationState.rerouting);
      response.complete(http.Response(providerResponse(), 200));
      await tester.pump();
      expect(session.state, NavigationState.navigating);
      emit(300);
      expect(session.remainingMeters, lessThan(150));
      emit(301);
      await tester.pump(const Duration(seconds: 2));
      expect(
        engine.currentMetrics.etaToDestination!.inSeconds,
        engine.guidance!.remainingSeconds,
      );
      emit(500);
      expect(session.state, NavigationState.arrived);
      expect(session.title, 'You have arrived');
      await tester.pump(const Duration(seconds: 3));
      expect(session.state, NavigationState.idle);
      expect(engine.activeRoute, isNull);
      expect(LocationService.instance.isLiveTracking, isFalse);
      session.dispose();
      engine.dispose();
      await tester.pump(const Duration(minutes: 1));
    },
  );

  testWidgets(
    'offline reroute retains route, stale Live expires, End cancels pending work',
    (tester) async {
      var clock = DateTime.now();
      final engine = LiveTrackingEngine.forTesting(
        RoutingService(
          mapboxAccessToken: 'test',
          client: MockClient((_) async => throw StateError('offline')),
        ),
      );
      final session = NavigationSession(engine: engine, now: () => clock);
      final simulator = NavigationSimulator(fixture());
      LocationService.instance.emitTestPosition(simulator.fixAt(0, clock));
      session.preview(fixture());
      await session.begin();
      for (var i = 0; i < 3; i++) {
        clock = clock.add(const Duration(seconds: 1));
        LocationService.instance.emitTestPosition(
          simulator.fixAt(80, clock, lateralMeters: 60),
        );
      }
      await tester.pump();
      expect(session.route, isNotNull);
      expect(session.error, isNotNull);
      clock = clock.add(const Duration(seconds: 6));
      expect(session.live, isFalse);
      session.end();
      expect(engine.activeRoute, isNull);
      session.dispose();
      engine.dispose();
      await tester.pump(const Duration(minutes: 1));
    },
  );

  testWidgets('trail reroute keeps both outstanding stops in order', (
    tester,
  ) async {
    Uri? requested;
    final engine = LiveTrackingEngine.forTesting(
      RoutingService(
        mapboxAccessToken: 'test',
        client: MockClient((request) async {
          requested = request.url;
          return http.Response(providerResponse(), 200);
        }),
      ),
    );
    final original = fixture();
    final route = WalkingRoute(
      points: original.points,
      distanceMeters: original.distanceMeters,
      durationSeconds: original.durationSeconds,
      steps: original.steps,
      waypoints: const [start, turn, end],
    );
    var clock = DateTime.now();
    final simulator = NavigationSimulator(route);
    final session = NavigationSession(engine: engine, now: () => clock);
    LocationService.instance.emitTestPosition(simulator.fixAt(0, clock));
    session.preview(route);
    await session.begin();
    for (var i = 0; i < 3; i++) {
      clock = clock.add(const Duration(seconds: 1));
      LocationService.instance.emitTestPosition(
        simulator.fixAt(80, clock, lateralMeters: 60),
      );
    }
    await tester.pump();
    expect(requested!.path, contains(';88.352,22.55;88.352,22.552'));
    expect(session.route!.waypoints.length, 3);
    session.dispose();
    engine.dispose();
    await tester.pump(const Duration(minutes: 1));
  });

  testWidgets(
    'navigation cards fit compact large text, show Live and Recenter after pan',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final engine = LiveTrackingEngine.forTesting(
        RoutingService(mapboxAccessToken: 'test'),
      );
      final session = NavigationSession(engine: engine);
      LocationService.instance.emitTestPosition(
        NavigationSimulator(fixture()).fixAt(0, DateTime.now()),
      );
      session.preview(fixture());
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(360, 780),
              textScaler: TextScaler.linear(1.3),
            ),
            child: Scaffold(
              body: ListenableBuilder(
                listenable: session,
                builder: (context, _) => NavigationOverlay(
                  session: session,
                  onStart: session.begin,
                  onEnd: session.end,
                  onRecenter: session.recenter,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(find.text('Head out'), findsOneWidget);
      expect(find.text('● Live'), findsOneWidget);
      expect(find.byTooltip('Recenter'), findsNothing);
      session.panAway();
      await tester.pump();
      expect(find.byTooltip('Recenter'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      session.dispose();
      engine.dispose();
      await tester.pump(const Duration(minutes: 1));
    },
  );
}
