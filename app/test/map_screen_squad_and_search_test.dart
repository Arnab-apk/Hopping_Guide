import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/models/squad_member.dart';
import 'package:kolkata_puja/repositories/pandal_repository.dart';
import 'package:kolkata_puja/screens/map_screen.dart';
import 'package:kolkata_puja/services/auth_service.dart';
import 'package:kolkata_puja/services/custom_hopping_trail_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/services/theme_service.dart';
import 'package:kolkata_puja/utils/constants.dart';

class MockPandalRepository extends PandalRepository {
  final List<Pandal> _pandals;
  MockPandalRepository([List<Pandal>? pandals])
      : _pandals = pandals ?? [
          Pandal(
            id: 'p1',
            name: 'Sreebhumi Sporting Club',
            lat: 22.5996,
            lng: 88.4011,
            zone: KolkataZone.northKolkata,
            theme: 'Heritage Sabeki',
            timings: '24 Hours',
            imageUrl: '',
            description: 'North classic',
            rating: 4.9,
            crowdLevel: 'high',
          ),
          Pandal(
            id: 'p2',
            name: 'Ekdalia Evergreen Club',
            lat: 22.5186,
            lng: 88.3686,
            zone: KolkataZone.southKolkata,
            theme: 'South blockbuster',
            timings: '24 Hours',
            imageUrl: '',
            description: 'South classic',
            rating: 4.8,
            crowdLevel: 'high',
          ),
        ];

  @override
  Future<List<Pandal>> all() async => _pandals;

  @override
  Future<List<Pandal>> byZone(KolkataZone zone) async =>
      _pandals.where((p) => p.zone == zone).toList();

  @override
  Future<Pandal?> byId(String id) async =>
      _pandals.cast<Pandal?>().firstWhere((p) => p?.id == id, orElse: () => null);

  @override
  Stream<List<Pandal>> watchAll() => Stream.value(_pandals);
}

Widget createTestApp({
  required SquadService squadService,
  required ThemeService themeService,
  required CustomHoppingTrailService trailService,
  required AuthService authService,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<SquadService>.value(value: squadService),
      ChangeNotifierProvider<ThemeService>.value(value: themeService),
      ChangeNotifierProvider<CustomHoppingTrailService>.value(value: trailService),
      ChangeNotifierProvider<AuthService>.value(value: authService),
    ],
    child: MaterialApp(
      home: MapScreen(
        repository: MockPandalRepository(),
      ),
    ),
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
    squadService = SquadService.instance;
    squadService.resetForTesting();
    themeService = ThemeService();
    trailService = CustomHoppingTrailService.instance;
    authService = AuthService.instance;
  });

  tearDown(() {
    squadService.leaveSquad();
  });

  Future<void> pumpMap(WidgetTester tester, [Duration duration = const Duration(milliseconds: 300)]) async {
    await tester.pump();
    await tester.pump(duration);
  }

  testWidgets('Issue 1: Squad status renders as a compact chip in filter row when squad is active',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Create a squad
    await squadService.createSquad('Kolkata Hoppers', 'Hatibagan Gate');
    expect(squadService.hasActiveSquad, isTrue);

    // 2. Pump MapScreen
    await tester.pumpWidget(createTestApp(
      squadService: squadService,
      themeService: themeService,
      trailService: trailService,
      authService: authService,
    ));
    await pumpMap(tester);

    // 3. Verify compact Squad chip is present in the filter row
    expect(find.text('Squad'), findsOneWidget);

    // 4. Verify the old full-width banner text is NOT permanently occupying a row outside the bottom sheet
    expect(find.text('Waiting for friends...'), findsNothing);

    // 5. Tap the Squad chip -> opens bottom sheet with details
    await tester.ensureVisible(find.text('Squad'));
    await tester.tap(find.text('Squad'));
    await pumpMap(tester, const Duration(milliseconds: 600));

    // 6. Verify bottom sheet content
    expect(find.text('Hopping Squad Active'), findsOneWidget);
    expect(find.text('INVITE CODE'), findsOneWidget);
    expect(find.text(squadService.squadCode!), findsOneWidget);
    expect(find.text('Waiting for friends...'), findsOneWidget);
    expect(find.text('Open Hopping Squad Hub'), findsOneWidget);

    // 7. Dismiss bottom sheet
    await tester.tap(find.byIcon(Icons.close_rounded));
    await pumpMap(tester, const Duration(milliseconds: 600));
    expect(find.text('Hopping Squad Active'), findsNothing);
  });

  testWidgets('Squad chip displays companion count when companions join',
      (tester) async {
    tester.view.physicalSize = const Size(1440, 2560);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // 1. Create a squad and add a companion
    await squadService.createSquad('Pujo Gang', 'Deshapriya Park');
    squadService.addCompanionForTesting(
      SquadMember(
        id: 'c1',
        name: 'Rohan Sen',
        latitude: 22.5800,
        longitude: 88.3700,
        status: 'At Pandal Gate',
        isHost: false,
        isUser: false,
        batteryLevel: 85,
        phoneNumber: '+91 98310 11223',
        lastSeen: DateTime.now(),
      ),
    );
    expect(squadService.companionMembers.length, equals(1));

    await tester.pumpWidget(createTestApp(
      squadService: squadService,
      themeService: themeService,
      trailService: trailService,
      authService: authService,
    ));
    await pumpMap(tester);

    // 2. Chip shows 'Squad (2)' (host + 1 companion)
    expect(find.text('Squad (2)'), findsOneWidget);

    // 3. Tapping chip shows companion in sheet
    await tester.ensureVisible(find.text('Squad (2)'));
    await tester.tap(find.text('Squad (2)'));
    await pumpMap(tester, const Duration(milliseconds: 600));

    expect(find.text('Companions Nearby (1)'), findsOneWidget);
    expect(find.text('Rohan Sen'), findsOneWidget);
    expect(find.text('Locate'), findsOneWidget);
  });

  testWidgets('Issue 2: Focusing or typing in search bar immediately unmounts filter chips row and suppresses banners',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await squadService.createSquad('Trail Buddies', 'Maddox Square');

    await tester.pumpWidget(createTestApp(
      squadService: squadService,
      themeService: themeService,
      trailService: trailService,
      authService: authService,
    ));
    await pumpMap(tester);

    // 1. Initially, filter row with Regions button and Squad chip is visible
    expect(find.text('Regions'), findsOneWidget);
    expect(find.text('Squad'), findsOneWidget);

    // 2. Tap on the search autocomplete field
    final searchFieldFinder = find.byType(TextField);
    expect(searchFieldFinder, findsOneWidget);

    await tester.tap(searchFieldFinder);
    await pumpMap(tester);

    // 3. Gated on _isSearchActive: filter chips row is now completely unmounted!
    expect(find.text('Regions'), findsNothing);
    expect(find.text('Squad'), findsNothing);

    // 4. Type text in search field
    await tester.enterText(searchFieldFinder, 'Sreebhumi');
    await pumpMap(tester);

    // Filter row remains unmounted while search has text
    expect(find.text('Regions'), findsNothing);
    expect(find.text('Squad'), findsNothing);

    // 5. Clear search using the clear button in PandalSearchAutocomplete
    final clearButtonFinder = find.byIcon(Icons.close_rounded);
    expect(clearButtonFinder, findsOneWidget);
    await tester.tap(clearButtonFinder);
    await pumpMap(tester);

    // 6. Filter row is restored cleanly with no leftover stale state
    expect(find.text('Regions'), findsOneWidget);
    expect(find.text('Squad'), findsOneWidget);
  });

  testWidgets('Search bar is always visible and contextual banner renders below the header without overlap',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestApp(
      squadService: squadService,
      themeService: themeService,
      trailService: trailService,
      authService: authService,
    ));
    await pumpMap(tester);

    // 1. Search bar is unconditionally visible before search
    final searchBarFinder = find.byType(TextField);
    expect(searchBarFinder, findsOneWidget);
    expect(find.text('Uma Map'), findsOneWidget);

    // 2. Tap Metro chip to trigger contextual banner
    final metroChipFinder = find.textContaining('Metro');
    expect(metroChipFinder, findsOneWidget);
    await tester.tap(metroChipFinder);
    await pumpMap(tester);

    // 3. Verify contextual banner appears with expected text
    final bannerFinder = find.textContaining('Showing 40+ Kolkata Metro stations on map');
    expect(bannerFinder, findsOneWidget);

    // 4. Verify banner is physically located below the AppBar (never overlapping title/icons)
    final appBarFinder = find.byType(AppBar);
    final appBarBottom = tester.getBottomLeft(appBarFinder).dy;
    final bannerTop = tester.getTopLeft(bannerFinder).dy;
    expect(bannerTop, greaterThan(appBarBottom));

    // 5. Longest realistic contextual message ("Showing all X pandals across Kolkata & Suburbs")
    final allChipFinder = find.textContaining('All');
    expect(allChipFinder, findsOneWidget);
    await tester.tap(allChipFinder);
    await pumpMap(tester);

    final longMessageFinder = find.textContaining('Showing all');
    expect(longMessageFinder, findsOneWidget);
    final longMessageTop = tester.getTopLeft(longMessageFinder).dy;
    expect(longMessageTop, greaterThan(appBarBottom));

    // 6. Activating search immediately hides filter chips AND contextual banner
    await tester.tap(searchBarFinder);
    await pumpMap(tester);

    expect(find.textContaining('Showing all'), findsNothing);
    expect(find.text('Regions'), findsNothing);
    expect(find.byType(TextField), findsOneWidget); // Search bar remains visible
  });
}

