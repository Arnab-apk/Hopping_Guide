import 'package:flutter_local_notifications_platform_interface/flutter_local_notifications_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/services/custom_hopping_trail_service.dart';
import 'package:kolkata_puja/services/pandal_user_state_service.dart';
import 'package:kolkata_puja/services/routing_service.dart';
import 'package:kolkata_puja/utils/constants.dart';

/// No-op fake so [NotificationProgressService] can initialize in tests without
/// a registered native plugin (which would otherwise throw a
/// [LateInitializationError] on the platform interface singleton).
class _FakeNotificationsPlatform extends FlutterLocalNotificationsPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Pandal> mockPandals;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    // Ensure the platform-interface singleton is initialized before any trail
    // operation touches [NotificationProgressService].
    FlutterLocalNotificationsPlatform.instance =
        _FakeNotificationsPlatform();

    mockPandals = [
      Pandal(
        id: 'pandal_1',
        name: 'Hatibagan Sarbojanin',
        lat: 22.5995,
        lng: 88.3712,
        zone: KolkataZone.northKolkata,
        theme: 'Traditional Clay Idols',
        timings: '24 Hours',
        imageUrl: '',
        description: 'Heritage Sabeki Puja in North Kolkata',
        rating: 4.8,
        crowdLevel: 'high',
      ),
      Pandal(
        id: 'pandal_2',
        name: 'Kashi Bose Lane',
        lat: 22.5980,
        lng: 88.3735,
        zone: KolkataZone.northKolkata,
        theme: 'Lighting Extravaganza',
        timings: '24 Hours',
        imageUrl: '',
        description: 'Blockbuster grand crowd puller',
        rating: 4.9,
        crowdLevel: 'extreme',
      ),
      Pandal(
        id: 'pandal_3',
        name: 'Nalin Sarkar Street',
        lat: 22.5970,
        lng: 88.3750,
        zone: KolkataZone.northKolkata,
        theme: 'Artistic Concept',
        timings: '24 Hours',
        imageUrl: '',
        description: 'Peaceful neighborhood pandal with intricate art',
        rating: 4.4,
        crowdLevel: 'low',
      ),
      Pandal(
        id: 'pandal_4',
        name: 'Sovabazar Rajbari',
        lat: 22.5990,
        lng: 88.3660,
        zone: KolkataZone.northKolkata,
        theme: 'Bonedi Bari Heritage',
        timings: '6 AM - 10 PM',
        imageUrl: '',
        description: 'Aristocratic household tradition dating to 1757',
        rating: 4.7,
        crowdLevel: 'medium',
      ),
    ];
  });

  group('CustomHoppingTrailService Algorithm & Geofence Tests', () {
    test('generateTrail generates valid ordered stops within time budget', () {
      final service = CustomHoppingTrailService.instance;
      const start = LatLng(22.5995, 88.3712); // Shyambazar / Hatibagan

      final trail = service.generateTrail(
        startPos: start,
        startLabel: 'Hatibagan Junction',
        style: HoppingStyle.heritage,
        timeBudgetMinutes: 90,
        transitMode: HoppingTransitMode.walking,
        allPandals: mockPandals,
      );

      expect(trail.stops.isNotEmpty, isTrue);
      expect(trail.totalEstimatedMinutes, lessThanOrEqualTo(90 + 15));
      expect(trail.totalDistanceKm, greaterThan(0.0));
      expect(trail.style, equals(HoppingStyle.heritage));
    });

    test('generateTrail blockbuster style prioritizes blockbuster and high ratings', () {
      final service = CustomHoppingTrailService.instance;
      const start = LatLng(22.5995, 88.3712);

      final trail = service.generateTrail(
        startPos: start,
        startLabel: 'Hatibagan Junction',
        style: HoppingStyle.blockbuster,
        timeBudgetMinutes: 60,
        transitMode: HoppingTransitMode.walking,
        allPandals: mockPandals,
      );

      expect(trail.stops.isNotEmpty, isTrue);
      // Pandal 2 (Kashi Bose Lane) is rated 4.9 extreme crowd
      expect(trail.stops.any((p) => p.name.contains('Kashi Bose') || p.name.contains('Hatibagan')), isTrue);
    });

    test('Auto-Visit triggers when user location is within 80m threshold', () async {
      final prefs = await SharedPreferences.getInstance();
      final userState = PandalUserStateService(prefs);
      final service = CustomHoppingTrailService.instance..attachUserStateService(userState);

      const start = LatLng(22.5995, 88.3712);
      final trail = service.generateTrail(
        startPos: start,
        startLabel: 'Hatibagan',
        style: HoppingStyle.express,
        timeBudgetMinutes: 120,
        transitMode: HoppingTransitMode.walking,
        allPandals: mockPandals,
      );

      await service.startTrail(trail);
      expect(service.hasActiveTrail, isTrue);
      expect(service.activeTrail!.visitedCount, equals(0));

      final firstTarget = service.currentTarget!;
      expect(firstTarget, isNotNull);

      // 1. Simulate user position far away (e.g., 2 km away) -> should NOT auto-visit
      final farLocation = LatLng(firstTarget.lat + 0.02, firstTarget.lng + 0.02);
      service.checkProximityAndAutoVisit(farLocation);
      expect(service.activeTrail!.visitedCount, equals(0));
      expect(service.activeTrail!.currentStopIndex, equals(0));

      // 2. Simulate user position close (within ~30m of target) -> SHOULD auto-visit
      final closeLocation = LatLng(firstTarget.lat + 0.0001, firstTarget.lng + 0.0001);
      service.checkProximityAndAutoVisit(closeLocation);

      expect(service.activeTrail!.visitedCount, equals(1));
      expect(service.activeTrail!.visitedPandalIds.contains(firstTarget.id), isTrue);
      expect(userState.isVisited(firstTarget.id), isTrue);

      // 3. Clean up
      await service.endTrail();
      expect(service.hasActiveTrail, isFalse);
    });

    test('skipCurrentStop advances to next stop without marking visited', () async {
      final service = CustomHoppingTrailService.instance;
      const start = LatLng(22.5995, 88.3712);
      final trail = service.generateTrail(
        startPos: start,
        startLabel: 'Hatibagan',
        style: HoppingStyle.heritage,
        timeBudgetMinutes: 120,
        transitMode: HoppingTransitMode.walking,
        allPandals: mockPandals,
      );

      await service.startTrail(trail);
      expect(service.activeTrail!.currentStopIndex, equals(0));

      await service.skipCurrentStop();
      expect(service.activeTrail!.currentStopIndex, equals(1));
      expect(service.activeTrail!.visitedCount, equals(0));

      await service.endTrail();
    });

    test('generateOptimizedTrail sanitizes remote user location (> 2.5 km away) and does not inflate trail distance', () {
      final service = CustomHoppingTrailService.instance;
      // Remote user position ~38.5 km north (e.g., near Kalyani / Barrackpore)
      const remoteUserPos = LatLng(22.9500, 88.3712);

      final trail = service.generateOptimizedTrail(
        startPos: remoteUserPos,
        startLabel: 'Home (Remote GPS)',
        selectedPandals: [mockPandals[0], mockPandals[1]], // Hatibagan Sarbojanin & Kashi Bose Lane
      );

      // Trail metrics MUST NOT include the 38.5 km cross-district march!
      // The two pandals in Hatibagan are ~250m apart.
      expect(trail.totalDistanceKm, lessThan(3.0));
      // Total estimated time must be realistic (~30-35 mins), not 580 minutes!
      expect(trail.totalEstimatedMinutes, lessThan(60));
      // Starting location is anchored at the first pandal, not the remote GPS
      expect(trail.startingLocation.latitude, closeTo(mockPandals[0].lat, 0.01));
    });

    test('RoutingService getMultiStopRoute computes valid route across waypoints', () async {
      final waypoints = [
        LatLng(mockPandals[0].lat, mockPandals[0].lng),
        LatLng(mockPandals[1].lat, mockPandals[1].lng),
        LatLng(mockPandals[2].lat, mockPandals[2].lng),
      ];

      final route = await RoutingService.instance.getMultiStopRoute(
        waypoints: waypoints,
        routeTitle: 'North Kolkata Heritage Hop',
      );

      expect(route.points.length, greaterThanOrEqualTo(2));
      expect(route.distanceMeters, greaterThan(0));
      expect(route.durationSeconds, greaterThan(0));
      expect(route.customTitle, equals('North Kolkata Heritage Hop'));
    });

    test('recordAutoVisit smoothly updates remaining routed distance and minutes', () async {
      final service = CustomHoppingTrailService.instance;
      const start = LatLng(22.5995, 88.3712);
      final trail = service.generateTrail(
        startPos: start,
        startLabel: 'Hatibagan',
        style: HoppingStyle.express,
        timeBudgetMinutes: 120,
        transitMode: HoppingTransitMode.walking,
        allPandals: mockPandals.take(2).toList(),
      );

      await service.startTrail(trail);

      // Manually set initial routed stats
      service.updateRoutedStats(
        distanceKm: 2.0,
        durationMinutes: 40,
        polyline: [const LatLng(22.5995, 88.3712), const LatLng(22.5980, 88.3735)],
        remainingDistanceKm: 2.0,
        remainingDurationMinutes: 40,
      );

      expect(service.activeTrail!.remainingRoutedDistanceKm, equals(2.0));
      expect(service.activeTrail!.remainingRoutedDurationMinutes, equals(40));

      // Record visit for first pandal (1 out of 2 visited -> 50% remaining)
      await service.recordAutoVisit(mockPandals[0]);

      expect(service.activeTrail!.remainingRoutedDistanceKm, equals(1.0));
      expect(service.activeTrail!.remainingRoutedDurationMinutes, equals(20));

      await service.endTrail();
    });
  });
}
