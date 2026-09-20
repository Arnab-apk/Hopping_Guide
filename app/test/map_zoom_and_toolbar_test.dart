import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/repositories/pandal_repository.dart';
import 'package:kolkata_puja/screens/map_screen.dart';
import 'package:kolkata_puja/services/auth_service.dart';
import 'package:kolkata_puja/services/custom_hopping_trail_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/services/theme_service.dart';
import 'package:kolkata_puja/utils/constants.dart';
import 'package:kolkata_puja/widgets/leaflet_map_components.dart';

class _FakePandalRepository extends PandalRepository {
  final List<Pandal> _pandals = [
    Pandal(
      id: 'p1',
      name: 'Hatibagan Sarbojanin',
      lat: 22.5996,
      lng: 88.4011,
      zone: KolkataZone.northKolkata,
      theme: 'Tradition',
      timings: '24 Hours',
      imageUrl: '',
      description: 'North classic',
      rating: 4.8,
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('LeafletZoomControl Unit & Widget Tests', () {
    testWidgets('renders plus and minus with matching dimensions and callbacks',
        (tester) async {
      int zoomInTaps = 0;
      int zoomOutTaps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: LeafletZoomControl(
                width: 46,
                buttonHeight: 44,
                borderRadius: 16,
                isDark: true,
                onZoomIn: () => zoomInTaps++,
                onZoomOut: () => zoomOutTaps++,
              ),
            ),
          ),
        ),
      );

      // Verify icons are present
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);

      // Verify tooltips
      expect(find.byTooltip('Zoom In'), findsOneWidget);
      expect(find.byTooltip('Zoom Out'), findsOneWidget);

      // Verify tap callbacks
      await tester.tap(find.byIcon(Icons.add));
      await tester.pump();
      expect(zoomInTaps, equals(1));

      await tester.tap(find.byIcon(Icons.remove));
      await tester.pump();
      expect(zoomOutTaps, equals(1));
    });
  });

  group('MapScreen Unified Floating Toolbar Tests', () {
    late SquadService squadService;
    late ThemeService themeService;
    late CustomHoppingTrailService trailService;
    late AuthService authService;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'has_seen_app_tutorial': true,
      });
      squadService = SquadService.instance;
      squadService.resetForTesting();
      themeService = ThemeService();
      trailService = CustomHoppingTrailService.instance;
      authService = AuthService.instance;
    });

    testWidgets('renders zoom control, quick tools, and GPS buttons in vertical alignment',
        (tester) async {
      tester.view.physicalSize = const Size(1440, 2560);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MultiProvider(
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
              repository: _FakePandalRepository(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // 1. Verify Zoom control is rendered
      expect(find.byType(LeafletZoomControl), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.remove), findsOneWidget);

      // 2. Verify Quick Tools and GPS buttons are rendered with tooltips
      expect(find.byTooltip('Map Tools & Settings'), findsOneWidget);
      expect(find.byTooltip('Center & Follow My GPS'), findsOneWidget);
      expect(find.byIcon(Icons.tune_rounded), findsOneWidget);
      expect(find.byIcon(Icons.my_location), findsOneWidget);

      // 3. Verify horizontal alignment (all share identical right edge and center X)
      final zoomCenter = tester.getCenter(find.byType(LeafletZoomControl));
      final toolsCenter = tester.getCenter(find.byTooltip('Map Tools & Settings'));
      final gpsCenter = tester.getCenter(find.byTooltip('Center & Follow My GPS'));

      expect((zoomCenter.dx - toolsCenter.dx).abs(), lessThan(1.0));
      expect((toolsCenter.dx - gpsCenter.dx).abs(), lessThan(1.0));

      // 4. Verify vertical ordering (Zoom above Tools, Tools above GPS)
      expect(zoomCenter.dy, lessThan(toolsCenter.dy));
      expect(toolsCenter.dy, lessThan(gpsCenter.dy));
    });
  });
}
