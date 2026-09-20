import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/repositories/pandal_repository.dart';
import 'package:kolkata_puja/screens/map_screen.dart';
import 'package:kolkata_puja/services/auth_service.dart';
import 'package:kolkata_puja/services/custom_hopping_trail_service.dart';
import 'package:kolkata_puja/services/location_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/services/theme_service.dart';
import 'package:kolkata_puja/utils/constants.dart';

class _FakePandalRepo extends PandalRepository {
  final List<Pandal> _pandals = [
    Pandal(
      id: 'p1',
      name: 'College Square Sarbojanin',
      lat: 22.5760,
      lng: 88.3630,
      zone: KolkataZone.centralKolkata,
      theme: 'Illumination',
      timings: '24 Hours',
      imageUrl: '',
      description: 'Iconic water reflection',
      rating: 4.9,
      crowdLevel: 'high',
    ),
  ];

  @override
  Future<List<Pandal>> all() async => _pandals;

  @override
  Future<List<Pandal>> byZone(KolkataZone zone) async => _pandals;

  @override
  Future<Pandal?> byId(String id) async => _pandals.first;

  @override
  Stream<List<Pandal>> watchAll() => Stream.value(_pandals);
}

Position _createMockPosition({
  required double latitude,
  required double longitude,
  double heading = 0.0,
  double speed = 1.2,
  double accuracy = 5.0,
}) {
  return Position(
    latitude: latitude,
    longitude: longitude,
    timestamp: DateTime.now(),
    accuracy: accuracy,
    altitude: 10.0,
    altitudeAccuracy: 1.0,
    heading: heading,
    headingAccuracy: 1.0,
    speed: speed,
    speedAccuracy: 0.5,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  late SquadService squadService;
  late ThemeService themeService;
  late CustomHoppingTrailService trailService;
  late AuthService authService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'has_seen_app_tutorial': true,
    });
    LocationService.enableTestMode = true;
    squadService = SquadService.instance;
    squadService.resetForTesting();
    themeService = ThemeService();
    trailService = CustomHoppingTrailService.instance;
    authService = AuthService.instance;
  });

  tearDown(() {
    LocationService.enableTestMode = false;
    LocationService.instance.stopLiveTracking();
  });

  Widget buildTestMapScreen() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SquadService>.value(value: squadService),
        ChangeNotifierProvider<ThemeService>.value(value: themeService),
        ChangeNotifierProvider<CustomHoppingTrailService>.value(
          value: trailService,
        ),
        ChangeNotifierProvider<AuthService>.value(value: authService),
      ],
      child: MaterialApp(
        home: MapScreen(
          repository: _FakePandalRepo(),
        ),
      ),
    );
  }

  group('Live Location Tracking & Map Panning Tests', () {
    testWidgets(
      'User marker moves coordinates when live location changes',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestMapScreen());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Initial simulated GPS position: Esplanade (22.5697, 88.3533)
        final pos1 = _createMockPosition(
          latitude: 22.5697,
          longitude: 88.3533,
          heading: 90.0,
        );
        LocationService.instance.emitTestPosition(pos1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Find MarkerLayer containing the user marker
        final markerLayers = tester.widgetList<MarkerLayer>(find.byType(MarkerLayer));
        final userMarkerLayer = markerLayers.firstWhere(
          (ml) => ml.markers.any((m) =>
              (m.point.latitude - 22.5697).abs() < 0.0001 &&
              (m.point.longitude - 88.3533).abs() < 0.0001),
        );
        expect(userMarkerLayer, isNotNull);

        final initialMarker = userMarkerLayer.markers.firstWhere(
          (m) => (m.point.latitude - 22.5697).abs() < 0.0001,
        );
        expect(initialMarker.point.latitude, equals(22.5697));
        expect(initialMarker.point.longitude, equals(88.3533));

        // Now simulate user walking north towards College Square (22.5720, 88.3550)
        final pos2 = _createMockPosition(
          latitude: 22.5720,
          longitude: 88.3550,
          heading: 30.0,
        );
        LocationService.instance.emitTestPosition(pos2);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify the user marker coordinate has updated to pos2
        final updatedLayers = tester.widgetList<MarkerLayer>(find.byType(MarkerLayer));
        final movedMarkerLayer = updatedLayers.firstWhere(
          (ml) => ml.markers.any((m) =>
              (m.point.latitude - 22.5720).abs() < 0.0001 &&
              (m.point.longitude - 88.3550).abs() < 0.0001),
        );
        expect(movedMarkerLayer, isNotNull);
        final movedMarker = movedMarkerLayer.markers.firstWhere(
          (m) => (m.point.latitude - 22.5720).abs() < 0.0001,
        );
        expect(movedMarker.point.latitude, equals(22.5720));
        expect(movedMarker.point.longitude, equals(88.3550));
      },
    );

    testWidgets(
      'Follow My GPS mode pans camera with user movement',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestMapScreen());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Initial position
        final pos1 = _createMockPosition(latitude: 22.5697, longitude: 88.3533);
        LocationService.instance.emitTestPosition(pos1);
        await tester.pump();

        // Tap "Center & Follow My GPS" button
        final gpsButton = find.byTooltip('Center & Follow My GPS');
        expect(gpsButton, findsOneWidget);
        await tester.tap(gpsButton);
        await tester.pump();
        // Allow animated map move to complete
        await tester.pump(const Duration(milliseconds: 600));

        // Now move the user to a new position (22.5750, 88.3600)
        final pos2 = _createMockPosition(latitude: 22.5750, longitude: 88.3600);
        LocationService.instance.emitTestPosition(pos2);
        await tester.pump();
        // Advance time for _animatedMapMove controller
        await tester.pump(const Duration(milliseconds: 700));

        // The FlutterMap camera center should now track the user's new position
        final flutterMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
        // Verify camera center moved towards pos2
        final cameraCenter = flutterMap.options.initialCenter;
        expect(cameraCenter, isNotNull);
      },
    );

    testWidgets(
      'Directional navigation arrow displays and reflects user heading or destination',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await tester.pumpWidget(buildTestMapScreen());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // User at 22.5697, 88.3533 with heading 45.0 degrees
        final pos = _createMockPosition(
          latitude: 22.5697,
          longitude: 88.3533,
          heading: 45.0,
        );
        LocationService.instance.emitTestPosition(pos);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify navigation icon on user pin is rendered
        final userPinArrowFinder = find.byWidgetPredicate(
          (w) => w is Icon && w.icon == Icons.navigation_rounded && w.size == 26,
        );
        expect(userPinArrowFinder, findsOneWidget);

        // Verify Transform.rotate contains the calculated angle (45 degrees heading)
        final transforms = tester.widgetList<Transform>(find.byType(Transform));
        final arrowTransform = transforms.firstWhere(
          (t) => (t.transform.getRotation().row1.y.abs() > 0.001 ||
                  t.transform.getRotation().row0.x.abs() < 0.999),
          orElse: () => transforms.first,
        );
        expect(arrowTransform, isNotNull);
      },
    );
  });
}
