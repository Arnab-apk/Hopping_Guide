import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/services/custom_hopping_trail_service.dart';
import 'package:kolkata_puja/services/location_service.dart';
import 'package:kolkata_puja/utils/constants.dart';
import 'package:kolkata_puja/widgets/custom_trail_planner_dialog.dart';

class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterLocalNotificationsPlatform.instance = _FakeNotificationsPlatform();
    LocationService.enableTestMode = true;
  });

  tearDown(() {
    LocationService.enableTestMode = false;
  });

  final List<Pandal> testPandals = [
    Pandal(
      id: 'pandal_1',
      name: 'Bagbazar Sarbojanin',
      lat: 22.6025,
      lng: 88.3685,
      zone: KolkataZone.northKolkata,
      theme: 'Traditional Dokra Art',
      timings: '24 Hours',
      imageUrl: '',
      description: 'Centenary traditional puja',
    ),
    Pandal(
      id: 'pandal_2',
      name: 'Kumartuli Park',
      lat: 22.6001,
      lng: 88.3662,
      zone: KolkataZone.northKolkata,
      theme: 'Clay artisan heritage',
      timings: '24 Hours',
      imageUrl: '',
      description: 'Heritage pandal',
    ),
    Pandal(
      id: 'pandal_3',
      name: 'Ahiritola Sarbojanin',
      lat: 22.5935,
      lng: 88.3582,
      zone: KolkataZone.northKolkata,
      theme: 'Ganga ghat river heritage',
      timings: '24 Hours',
      imageUrl: '',
      description: 'Riverfront pandal',
    ),
  ];

  Widget createTestWidget({
    required CustomHoppingTrailService trailService,
    VoidCallback? onTrailStarted,
  }) {
    return ChangeNotifierProvider<CustomHoppingTrailService>.value(
      value: trailService,
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ElevatedButton(
                onPressed: () {
                  CustomTrailPlannerDialog.show(
                    context,
                    initialLocation: const LatLng(22.6000, 88.3700),
                    initialLocationLabel: 'Shyambazar Five-Point Crossing',
                    pandals: testPandals,
                    onTrailStarted: onTrailStarted,
                  );
                },
                child: const Text('Open Builder'),
              );
            },
          ),
        ),
      ),
    );
  }

  testWidgets('CustomTrailPlannerDialog 3-step wizard workflow and optimization execution', (tester) async {
    final trailService = CustomHoppingTrailService.instance;

    bool trailStartedCalled = false;

    await tester.pumpWidget(
      createTestWidget(
        trailService: trailService,
        onTrailStarted: () => trailStartedCalled = true,
      ),
    );

    // Open Dialog
    await tester.tap(find.text('Open Builder'));
    await tester.pumpAndSettle();

    // Verify Step 1: Starting Point
    expect(find.text('Custom Trail Builder'), findsOneWidget);
    expect(find.textContaining('Step 1: Starting Point'), findsOneWidget);
    expect(find.textContaining('Shyambazar'), findsWidgets);
    expect(find.text('Next: Choose Pandals'), findsOneWidget);

    // Tap Next -> Step 2: Choose Pandals
    await tester.tap(find.text('Next: Choose Pandals'));
    await tester.pumpAndSettle();

    // Verify Step 2 UI
    expect(find.textContaining('Step 2: Choose Pandals'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // Search bar
    expect(find.text('Select at least 2'), findsOneWidget);

    // Find checkboxes in the pandal picker list
    final checkboxes = find.byType(Checkbox);
    expect(checkboxes, findsNWidgets(3));

    // Select first pandal
    await tester.tap(checkboxes.at(0));
    await tester.pumpAndSettle();
    expect(find.textContaining('1 pandals selected'), findsOneWidget);

    // Select second pandal
    await tester.tap(checkboxes.at(1));
    await tester.pumpAndSettle();
    expect(find.textContaining('2 pandals selected'), findsOneWidget);
    expect(find.text('Ready to optimize'), findsOneWidget);

    // Tap Continue -> Step 3: Review & Generate
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify Step 3 UI
    expect(find.textContaining('Step 3: Review & Generate'), findsOneWidget);
    expect(find.text('Generate My Custom Trail'), findsOneWidget);

    // Tap Generate My Custom Trail
    await tester.tap(find.text('Generate My Custom Trail'));
    await tester.pumpAndSettle();

    // Dialog should dismiss and trail should be active in service
    expect(trailStartedCalled, isTrue);
    expect(trailService.hasActiveTrail, isTrue);
    expect(trailService.activeTrail!.totalStops, 2);
    expect(find.text('Custom Trail Builder'), findsNothing);
  });

  test('ActiveCustomTrail stores routed stats and CustomHoppingTrailService updates single source of truth', () async {
    final trailService = CustomHoppingTrailService.instance;

    final activeTrail = ActiveCustomTrail.custom(
      id: 'test_trail_123',
      startingLocation: const LatLng(22.6000, 88.3700),
      startingAddress: 'Shyambazar',
      stops: [testPandals[0], testPandals[1]],
      totalDistanceKm: 47.4, // original straight-line distance
      totalEstimatedMinutes: 722, // original straight-line duration
    );

    await trailService.startTrail(activeTrail);
    expect(trailService.hasActiveTrail, isTrue);
    expect(trailService.activeTrail!.routedDistanceKm, isNull);
    expect(trailService.activeTrail!.remainingEstimatedMinutes, 722);

    int notificationCount = 0;
    void listener() => notificationCount++;
    trailService.addListener(listener);

    // Simulate GemKit RoutingService calculating real pedestrian route
    final roadPolyline = [
      const LatLng(22.6000, 88.3700),
      const LatLng(22.6010, 88.3690),
      const LatLng(22.6025, 88.3685),
      const LatLng(22.6001, 88.3662),
    ];

    trailService.updateRoutedStats(
      distanceKm: 1.8,
      durationMinutes: 28,
      remainingDistanceKm: 1.8,
      remainingDurationMinutes: 28,
      polyline: roadPolyline,
    );

    expect(notificationCount, 1);
    final updated = trailService.activeTrail!;
    expect(updated.routedDistanceKm, 1.8);
    expect(updated.routedEstimatedMinutes, 28);
    expect(updated.remainingRoutedDistanceKm, 1.8);
    expect(updated.remainingRoutedDurationMinutes, 28);
    // Verified single source of truth:
    expect(updated.remainingEstimatedMinutes, 28);
    expect(updated.routedPolyline, isNotNull);
    expect(updated.routedPolyline!.length, 4);

    // Advance stop - remaining routed metrics invalidate until next leg/route calculation
    await trailService.recordAutoVisit(testPandals[0]);
    expect(trailService.activeTrail!.visitedPandalIds.contains('pandal_1'), isTrue);
    expect(trailService.activeTrail!.remainingRoutedDistanceKm, isNull);
    expect(trailService.activeTrail!.remainingRoutedDurationMinutes, isNull);

    trailService.removeListener(listener);
    await trailService.endTrail();
  });
}

