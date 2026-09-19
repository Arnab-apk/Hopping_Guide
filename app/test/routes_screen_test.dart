import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/repositories/pandal_repository.dart';
import 'package:kolkata_puja/screens/routes_screen.dart';
import 'package:kolkata_puja/utils/constants.dart';

class MockRoutesPandalRepository extends PandalRepository {
  final List<Pandal> pandals = [
    // North Kolkata Heritage Walk stops (7 stops - longest circuit)
    Pandal(
      id: 'hatibagan_sarbojanin',
      name: 'Hatibagan Sarbojanin',
      lat: 22.5947,
      lng: 88.3720,
      zone: KolkataZone.northKolkata,
      area: 'North Kolkata',
      region: 'North',
      rating: 4.5,
      theme: 'Traditional',
      crowdLevel: 'high',
      timings: '12:00 AM - 12:00 PM',
      imageUrl: '',
      description: 'Traditional idol',
      nearestMetro: 'Shyambazar',
    ),
    Pandal(
      id: 'kasi_bose_lane',
      name: 'Kasi Bose Lane',
      lat: 22.5912,
      lng: 88.3734,
      zone: KolkataZone.northKolkata,
      area: 'North Kolkata',
      region: 'North',
      rating: 4.6,
      theme: 'Theme',
      crowdLevel: 'high',
      timings: '12:00 AM - 12:00 PM',
      imageUrl: '',
      description: 'Artistic theme',
      nearestMetro: 'Shyambazar',
    ),
    Pandal(
      id: 'nalin_sarkar_street',
      name: 'Nalin Sarkar Street',
      lat: 22.5930,
      lng: 88.3745,
      zone: KolkataZone.northKolkata,
      area: 'North Kolkata',
      region: 'North',
      rating: 4.4,
      theme: 'Creative',
      crowdLevel: 'medium',
      timings: '12:00 AM - 12:00 PM',
      imageUrl: '',
      description: 'Unique lighting',
      nearestMetro: 'Shyambazar',
    ),
    Pandal(
      id: 'nabin_pally',
      name: 'Nabin Pally',
      lat: 22.5950,
      lng: 88.3760,
      zone: KolkataZone.northKolkata,
      area: 'North Kolkata',
      region: 'North',
      rating: 4.3,
      theme: 'Cultural',
      crowdLevel: 'medium',
      timings: '12:00 AM - 12:00 PM',
      imageUrl: '',
      description: 'Heritage',
      nearestMetro: 'Shyambazar',
    ),
    Pandal(
      id: 'kumortuli_park_sarbojanin',
      name: 'Kumartuli Park',
      lat: 22.5990,
      lng: 88.3650,
      zone: KolkataZone.northKolkata,
      area: 'North Kolkata',
      region: 'North',
      rating: 4.7,
      theme: 'Clay Artisans',
      crowdLevel: 'high',
      timings: '12:00 AM - 12:00 PM',
      imageUrl: '',
      description: 'Clay sculptors',
      nearestMetro: 'Sovabazar',
    ),
    Pandal(
      id: 'ahiritola',
      name: 'Ahiritola Sarbojanin',
      lat: 22.5975,
      lng: 88.3610,
      zone: KolkataZone.northKolkata,
      area: 'North Kolkata',
      region: 'North',
      rating: 4.5,
      theme: 'Riverfront',
      crowdLevel: 'high',
      timings: '12:00 AM - 12:00 PM',
      imageUrl: '',
      description: 'Ghat puja',
      nearestMetro: 'Sovabazar',
    ),
    Pandal(
      id: 'bagbazar_sarbajanin',
      name: 'Bagbazar Sarbojanin',
      lat: 22.6025,
      lng: 88.3667,
      zone: KolkataZone.northKolkata,
      area: 'North Kolkata',
      region: 'North',
      rating: 4.8,
      theme: 'Daaker Saaj',
      crowdLevel: 'high',
      timings: '12:00 AM - 12:00 PM',
      imageUrl: '',
      description: '100+ year historic puja',
      nearestMetro: 'Shyambazar',
    ),
    // South Kolkata Grand Circuit stops (6 stops)
    Pandal(
      id: 'ballygunge_cultural',
      name: 'Ballygunge Cultural',
      lat: 22.5210,
      lng: 88.3620,
      zone: KolkataZone.southKolkata,
      area: 'South Kolkata',
      region: 'South',
      rating: 4.6,
      theme: 'Grand Theme',
      crowdLevel: 'high',
      timings: '12:00 AM - 12:00 PM',
      imageUrl: '',
      description: 'Popular South puja',
      nearestMetro: 'Jatin Das Park',
    ),
    Pandal(
      id: 'ekdalia_evergreen',
      name: 'Ekdalia Evergreen',
      lat: 22.5245,
      lng: 88.3688,
      zone: KolkataZone.southKolkata,
      area: 'South Kolkata',
      region: 'South',
      rating: 4.8,
      theme: 'Traditional',
      crowdLevel: 'high',
      timings: '12:00 AM - 12:00 PM',
      imageUrl: '',
      description: 'Chandelier palace',
      nearestMetro: 'Gariahat',
    ),
    Pandal(
      id: 'singhi_park',
      name: 'Singhi Park',
      lat: 22.5230,
      lng: 88.3670,
      zone: KolkataZone.southKolkata,
      area: 'South Kolkata',
      region: 'South',
      rating: 4.7,
      theme: 'Temple replica',
      crowdLevel: 'high',
      timings: '12:00 AM - 12:00 PM',
      imageUrl: '',
      description: 'Lighting from Chandannagar',
      nearestMetro: 'Gariahat',
    ),
    Pandal(
      id: 'maddox_square',
      name: 'Maddox Square',
      lat: 22.5310,
      lng: 88.3580,
      zone: KolkataZone.southKolkata,
      area: 'South Kolkata',
      region: 'South',
      rating: 4.9,
      theme: 'Open Park Adda',
      crowdLevel: 'very high',
      timings: '12:00 AM - 12:00 PM',
      imageUrl: '',
      description: 'Classic adda ground',
      nearestMetro: 'Netaji Bhavan',
    ),
    Pandal(
      id: 'deshapriya_park',
      name: 'Deshapriya Park',
      lat: 22.5180,
      lng: 88.3560,
      zone: KolkataZone.southKolkata,
      area: 'South Kolkata',
      region: 'South',
      rating: 4.5,
      theme: 'Colossal structure',
      crowdLevel: 'high',
      timings: '12:00 AM - 12:00 PM',
      imageUrl: '',
      description: 'Grand park puja',
      nearestMetro: 'Kalighat',
    ),
    Pandal(
      id: 'tridhara',
      name: 'Tridhara Sammilani',
      lat: 22.5190,
      lng: 88.3610,
      zone: KolkataZone.southKolkata,
      area: 'South Kolkata',
      region: 'South',
      rating: 4.7,
      theme: 'Artistic fusion',
      crowdLevel: 'high',
      timings: '12:00 AM - 12:00 PM',
      imageUrl: '',
      description: 'Theme wonder',
      nearestMetro: 'Kalighat',
    ),
  ];

  @override
  Future<List<Pandal>> all() async => pandals;

  @override
  Future<Pandal?> byId(String id) async =>
      pandals.cast<Pandal?>().firstWhere((p) => p?.id == id, orElse: () => null);

  @override
  Future<List<Pandal>> byZone(KolkataZone zone) async =>
      pandals.where((p) => p.zone == zone).toList();

  @override
  Stream<List<Pandal>> watchAll() => Stream.value(pandals);
}

void main() {
  testWidgets('RoutesScreen renders curated circuit cards', (tester) async {
    final mockRepo = MockRoutesPandalRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: RoutesScreen(repository: mockRepo),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Curated Circuits'), findsOneWidget);
    expect(find.text('North Kolkata Heritage Walk'), findsOneWidget);
    expect(find.text('South Kolkata Grand Circuit'), findsOneWidget);
  });

  testWidgets(
      'Expanding North Kolkata Heritage Walk (7 stops) shows Start Circuit on Map with proper bottom padding',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockRepo = MockRoutesPandalRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: RoutesScreen(repository: mockRepo),
      ),
    );
    await tester.pumpAndSettle();

    // Tap North Kolkata Heritage Walk card to expand
    final northCardHeader = find.text('North Kolkata Heritage Walk');
    expect(northCardHeader, findsOneWidget);
    await tester.tap(northCardHeader);
    await tester.pumpAndSettle();

    // Verify all 7 stops are rendered
    expect(find.text('Circuit Stops (7)'), findsOneWidget);
    expect(find.text('Hatibagan Sarbojanin'), findsOneWidget);
    expect(find.text('Bagbazar Sarbojanin'), findsOneWidget);

    // Verify Start Circuit on Map button exists and is fully visible
    final startButton = find.widgetWithText(ElevatedButton, 'Start Circuit on Map');
    expect(startButton, findsOneWidget);

    // Verify the button is wrapped inside a Padding with bottom padding >= 20
    final paddingFinder = find.ancestor(
      of: startButton,
      matching: find.byType(Padding),
    );
    expect(paddingFinder, findsWidgets);

    final buttonPaddingWidget = tester.widget<Padding>(paddingFinder.first);
    final insets = buttonPaddingWidget.padding as EdgeInsets;
    expect(insets.bottom, equals(20.0));
    expect(insets.left, equals(16.0));
    expect(insets.right, equals(16.0));
    expect(insets.top, equals(12.0));

    // Verify button has standard height (44px)
    final sizedBoxFinder = find.ancestor(
      of: startButton,
      matching: find.byType(SizedBox),
    );
    final buttonSizedBox = tester.widget<SizedBox>(sizedBoxFinder.first);
    expect(buttonSizedBox.height, equals(44.0));
  });

  testWidgets(
      'Expand -> Collapse -> Expand again maintains clean layout and no clipping',
      (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final mockRepo = MockRoutesPandalRepository();
    await tester.pumpWidget(
      MaterialApp(
        home: RoutesScreen(repository: mockRepo),
      ),
    );
    await tester.pumpAndSettle();

    final southCardHeader = find.text('South Kolkata Grand Circuit');

    // 1. Expand
    await tester.tap(southCardHeader);
    await tester.pumpAndSettle();
    expect(find.text('Start Circuit on Map'), findsOneWidget);
    expect(find.text('Circuit Stops (6)'), findsOneWidget);

    // 2. Collapse
    await tester.tap(southCardHeader);
    await tester.pumpAndSettle();
    expect(find.text('Start Circuit on Map'), findsNothing);

    // 3. Expand again
    await tester.tap(southCardHeader);
    await tester.pumpAndSettle();
    expect(find.text('Start Circuit on Map'), findsOneWidget);

    // Verify button position and geometry
    final buttonFinder = find.widgetWithText(ElevatedButton, 'Start Circuit on Map');
    final buttonRect = tester.getRect(buttonFinder);
    expect(buttonRect.height, equals(44.0));
    expect(buttonRect.width, greaterThan(200.0));
  });
}
