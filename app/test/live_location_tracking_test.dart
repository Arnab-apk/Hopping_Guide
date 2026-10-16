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
import 'package:kolkata_puja/services/pandal_user_state_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/services/theme_service.dart';
import 'package:kolkata_puja/utils/constants.dart';
import 'package:kolkata_puja/utils/navigation_heading.dart';
import 'package:kolkata_puja/services/navigation_session.dart';
import 'package:kolkata_puja/services/routing_service.dart';
import 'package:kolkata_puja/models/navigation_step.dart';
import 'package:kolkata_puja/widgets/leaflet_map_components.dart';
import 'package:latlong2/latlong.dart';

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
  late PandalUserStateService userState;

  setUp(() async {
    SharedPreferences.setMockInitialValues({'has_seen_app_tutorial': true});
    LocationService.enableTestMode = true;
    squadService = SquadService.instance;
    squadService.resetForTesting();
    themeService = ThemeService();
    trailService = CustomHoppingTrailService.instance;
    authService = AuthService.instance;
    userState = await PandalUserStateService.create();
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
        ChangeNotifierProvider<PandalUserStateService>.value(value: userState),
      ],
      child: MaterialApp(home: MapScreen(repository: _FakePandalRepo())),
    );
  }

  group('Live Location Tracking & Map Panning Tests', () {
    testWidgets('saved visited pins update without an active hopping trail', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestMapScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      MapScreen.pendingPandalAction.value = (
        pandal: (await _FakePandalRepo().byId('p1'))!,
        traceRoute: false,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      tester
          .widget<FlutterMap>(find.byType(FlutterMap))
          .mapController!
          .move(const LatLng(22.5760, 88.3630), 17);
      await tester.pump();
      final pin = find.byWidgetPredicate(
        (widget) =>
            widget is LeafletMarkerPin &&
            widget.category == LeafletPinCategory.pandal,
      );
      expect(tester.widget<LeafletMarkerPin>(pin.first).isVisited, isFalse);
      await userState.markVisited('p1');
      await tester.pump();
      expect(tester.widget<LeafletMarkerPin>(pin.first).isVisited, isTrue);
      await tester.pumpWidget(const SizedBox.shrink());
    });
    testWidgets(
      'navigation Start hides explore controls and confirmed End restores the map',
      (tester) async {
        await tester.pumpWidget(buildTestMapScreen());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        LocationService.instance.emitTestPosition(
          _createMockPosition(latitude: 22.5697, longitude: 88.3533),
        );
        NavigationSession.instance.preview(
          const WalkingRoute(
            customTitle: 'Home',
            points: [
              LatLng(22.5697, 88.3533),
              LatLng(22.5697, 88.3543),
              LatLng(22.5707, 88.3543),
            ],
            distanceMeters: 210,
            durationSeconds: 180,
            steps: [
              NavigationStep(
                instruction: 'Head out',
                pointIndex: 0,
                distanceMeters: 100,
                durationSeconds: 90,
                type: 'depart',
              ),
              NavigationStep(
                instruction: 'Turn left',
                pointIndex: 1,
                distanceMeters: 110,
                durationSeconds: 90,
                type: 'turn',
                modifier: 'left',
              ),
              NavigationStep(
                instruction: 'You have arrived',
                pointIndex: 2,
                distanceMeters: 0,
                durationSeconds: 0,
                type: 'arrive',
              ),
            ],
          ),
        );
        await tester.pump();
        expect(find.text('Start'), findsOneWidget);
        final destinationLayer = find.byKey(
          const ValueKey('route-destination-layer'),
        );
        expect(
          tester.widget<MarkerLayer>(destinationLayer).markers.single.point,
          const LatLng(22.5707, 88.3543),
        );
        await tester.tap(find.text('Start'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 800));
        expect(find.text('Head out'), findsOneWidget);
        expect(find.text('Uma Map'), findsNothing);
        expect(find.byType(LeafletZoomControl), findsNothing);
        expect(find.byType(FlutterMap), findsOneWidget);
        expect(
          tester.widget<MarkerLayer>(destinationLayer).markers.single.point,
          const LatLng(22.5707, 88.3543),
        );
        await tester.drag(find.byType(FlutterMap), const Offset(80, 0));
        await tester.pump();
        expect(find.byTooltip('Recenter'), findsOneWidget);
        await tester.tap(find.text('End'));
        await tester.pump();
        expect(find.text('End navigation?'), findsOneWidget);
        await tester.tap(find.text('End').last);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Uma Map'), findsOneWidget);
        expect(find.byType(LeafletZoomControl), findsOneWidget);
        expect(find.byType(FlutterMap), findsOneWidget);
        expect(destinationLayer, findsNothing);
        await tester.pumpWidget(const SizedBox.shrink());
        expect(tester.takeException(), isNull);
      },
    );
    testWidgets(
      'follow mode rotates with stationary compass and north reset holds',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(buildTestMapScreen());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        LocationService.instance.emitTestPosition(
          _createMockPosition(
            latitude: 22.5697,
            longitude: 88.3533,
            heading: 0,
            speed: 0,
          ),
        );
        LocationService.instance.emitTestHeading(90);
        await tester.pump();
        final controller = tester
            .widget<FlutterMap>(find.byType(FlutterMap))
            .mapController!;
        expect(controller.camera.rotation, 0);
        await tester.tap(find.byTooltip('Center & Follow My GPS'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 650));
        expect(
          shortestHeadingTurn(controller.camera.rotation, -90).abs(),
          lessThan(1),
        );
        LocationService.instance.emitTestHeading(359);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        LocationService.instance.emitTestHeading(1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(
          shortestHeadingTurn(controller.camera.rotation, -1).abs(),
          lessThan(2),
        );
        LocationService.instance.emitTestHeading(90);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        await tester.tap(find.byTooltip('Reset to North'));
        await tester.pump();
        LocationService.instance.emitTestHeading(180);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));
        expect(controller.camera.rotation, 0);
        await tester.pumpWidget(const SizedBox.shrink());
        LocationService.instance.emitTestHeading(double.nan);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('User marker moves coordinates when live location changes', (
      tester,
    ) async {
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
      final markerLayers = tester.widgetList<MarkerLayer>(
        find.byType(MarkerLayer),
      );
      final userMarkerLayer = markerLayers.firstWhere(
        (ml) => ml.markers.any(
          (m) =>
              (m.point.latitude - 22.5697).abs() < 0.0001 &&
              (m.point.longitude - 88.3533).abs() < 0.0001,
        ),
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
      final updatedLayers = tester.widgetList<MarkerLayer>(
        find.byType(MarkerLayer),
      );
      final movedMarkerLayer = updatedLayers.firstWhere(
        (ml) => ml.markers.any(
          (m) =>
              (m.point.latitude - 22.5720).abs() < 0.0001 &&
              (m.point.longitude - 88.3550).abs() < 0.0001,
        ),
      );
      expect(movedMarkerLayer, isNotNull);
      final movedMarker = movedMarkerLayer.markers.firstWhere(
        (m) => (m.point.latitude - 22.5720).abs() < 0.0001,
      );
      expect(movedMarker.point.latitude, equals(22.5720));
      expect(movedMarker.point.longitude, equals(88.3550));
    });

    testWidgets('Follow My GPS mode pans camera with user movement', (
      tester,
    ) async {
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

      // A walking-sized update should move the camera with the displayed dot.
      final pos2 = _createMockPosition(latitude: 22.5702, longitude: 88.3533);
      LocationService.instance.emitTestPosition(pos2);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 99));
      final flutterMap = tester.widget<FlutterMap>(find.byType(FlutterMap));
      final centerDuringMovement = flutterMap.mapController!.camera.center;
      expect(centerDuringMovement.latitude, greaterThan(pos1.latitude));
      expect(centerDuringMovement.latitude, lessThan(pos2.latitude));
      final userMarker = tester
          .widgetList<MarkerLayer>(find.byType(MarkerLayer))
          .expand((layer) => layer.markers)
          .firstWhere((marker) => marker.key == const ValueKey('my-location'));
      expect(
        centerDuringMovement.latitude,
        closeTo(userMarker.point.latitude, 0.000001),
      );
      await tester.pump(const Duration(milliseconds: 1100));

      // The FlutterMap camera center should now track the user's new position
      expect(
        flutterMap.mapController!.camera.center.latitude,
        closeTo(pos2.latitude, 0.000001),
      );
      await tester.pumpWidget(const SizedBox.shrink());
    });

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
          (w) =>
              w is Icon && w.icon == Icons.navigation_rounded && w.size == 26,
        );
        expect(userPinArrowFinder, findsOneWidget);

        // Verify Transform.rotate contains the calculated angle (45 degrees heading)
        final transforms = tester.widgetList<Transform>(find.byType(Transform));
        final arrowTransform = transforms.firstWhere(
          (t) =>
              (t.transform.getRotation().row1.y.abs() > 0.001 ||
              t.transform.getRotation().row0.x.abs() < 0.999),
          orElse: () => transforms.first,
        );
        expect(arrowTransform, isNotNull);
      },
    );
  });
}
