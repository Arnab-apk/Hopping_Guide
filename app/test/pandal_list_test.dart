import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/models/place.dart';
import 'package:kolkata_puja/repositories/pandal_repository.dart';
import 'package:kolkata_puja/screens/pandal_list_screen.dart';
import 'package:kolkata_puja/services/pandal_user_state_service.dart';
import 'package:kolkata_puja/utils/constants.dart';

class MockPandalRepository implements PandalRepository {
  final List<Pandal> mockPandals = [
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
      description: 'Iconic North Kolkata puja',
      nearestMetro: 'Shyambazar (Blue)',
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
      timings: '6:00 AM - 11:00 PM',
      imageUrl: '',
      description: 'Iconic South Kolkata puja',
      nearestMetro: 'Gariahat',
    ),
  ];

  final List<Place> mockFoodSpots = const [
    Place(
      id: 'f_golbari',
      name: 'Golbari (New Punjabi Hotel)',
      category: PlaceCategory.foodSpot,
      lat: 22.6000,
      lng: 88.3700,
      type: 'Iconic Kosha Mangsho & Paratha',
      mustTry: 'Kosha Mangsho',
      nearbyPandal: 'Shyambazar',
      rating: 4.4,
    ),
  ];

  @override
  Future<List<Pandal>> all() async => mockPandals;

  @override
  Future<List<Pandal>> byZone(KolkataZone zone) async =>
      mockPandals.where((p) => p.zone == zone).toList();

  @override
  Future<Pandal?> byId(String id) async {
    try {
      return mockPandals.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<Pandal>> watchAll() async* {
    yield mockPandals;
  }

  @override
  Future<List<Place>> getPlaces({
    required PlaceCategory category,
    KolkataZone? zoneFilter,
    String? searchQuery,
  }) async {
    if (category == PlaceCategory.pandal) {
      final list = zoneFilter != null ? await byZone(zoneFilter) : await all();
      var places = list.map(Place.fromPandal).toList();
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        places = places.where((p) => p.name.toLowerCase().contains(q)).toList();
      }
      return places;
    } else {
      var places = List<Place>.from(mockFoodSpots);
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        places = places.where((p) => p.name.toLowerCase().contains(q)).toList();
      }
      return places;
    }
  }
}

void main() {
  testWidgets('PandalListScreen renders search bar and pandal cards', (tester) async {
    final mockRepo = MockPandalRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: PandalListScreen(repository: mockRepo),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, 'Pandals'), findsOneWidget);
    expect(find.text('Hatibagan Sarbojanin'), findsOneWidget);
    expect(find.text('Ekdalia Evergreen'), findsOneWidget);
    // Food spots should NEVER appear on the pandals segment
    expect(find.text('Golbari (New Punjabi Hotel)'), findsNothing);

    // Test search filter
    await tester.enterText(find.byType(TextField), 'Ekdalia');
    await tester.pumpAndSettle();

    expect(find.text('Ekdalia Evergreen'), findsOneWidget);
    expect(find.text('Hatibagan Sarbojanin'), findsNothing);
  });

  testWidgets('PandalListScreen separates Pandals and Food Spots segments cleanly', (tester) async {
    final mockRepo = MockPandalRepository();

    await tester.pumpWidget(
      MaterialApp(
        home: PandalListScreen(repository: mockRepo),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Initial Pandals segment
    expect(find.widgetWithText(AppBar, 'Pandals'), findsOneWidget);
    expect(find.text('Pandals'), findsWidgets);
    expect(find.text('Food Spots'), findsOneWidget);
    expect(find.text('Hatibagan Sarbojanin'), findsOneWidget);
    expect(find.text('Golbari (New Punjabi Hotel)'), findsNothing);

    // 2. Switch to Food Spots segment
    await tester.tap(find.text('Food Spots'));
    await tester.pumpAndSettle();

    // Title should update and only food spots should render
    expect(find.text('Food Spots'), findsWidgets);
    expect(find.text('Golbari (New Punjabi Hotel)'), findsOneWidget);
    expect(find.text('Hatibagan Sarbojanin'), findsNothing);
    expect(find.text('Ekdalia Evergreen'), findsNothing);

    // Search hint should update
    expect(find.text('Search by restaurant, cuisine, area...'), findsOneWidget);

    // 3. Switch back to Pandals segment
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<PlaceCategory>),
        matching: find.text('Pandals'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Pandals'),
      ),
      findsOneWidget,
    );
    expect(find.text('Hatibagan Sarbojanin'), findsOneWidget);
    expect(find.text('Golbari (New Punjabi Hotel)'), findsNothing);
    expect(find.text('Search by pandal, area, metro, theme...'), findsOneWidget);
  });

  testWidgets('Control Audit: Hopped pill & progress bar are omitted on Food Spots, favorites are isolated', (tester) async {
    SharedPreferences.setMockInitialValues({
      'user_favorite_pandals': ['hatibagan_sarbojanin'], // 1 pandal favorited
      'user_visited_pandals': ['hatibagan_sarbojanin'],  // 1 pandal visited
    });
    final prefs = await SharedPreferences.getInstance();
    final userState = PandalUserStateService(prefs);
    final mockRepo = MockPandalRepository();

    await tester.pumpWidget(
      ChangeNotifierProvider<PandalUserStateService?>.value(
        value: userState,
        child: MaterialApp(
          home: PandalListScreen(repository: mockRepo),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. On Pandals segment:
    // "All (2)", "Favorites (1)", "Hopped (1)", "Nearby (10km)", "Regions"
    expect(find.text('All (2)'), findsOneWidget);
    expect(find.text('Favorites (1)'), findsOneWidget);
    expect(find.text('Hopped (1)'), findsOneWidget);
    expect(find.text('Nearby (10km)'), findsOneWidget);
    expect(find.text('Regions'), findsOneWidget);
    // Hopping progress bar is displayed on Pandals screen
    expect(find.textContaining('Hopping Progress: 1 of 2 Pandals Visited'), findsOneWidget);

    // 2. Switch to Food Spots segment:
    await tester.tap(find.text('Food Spots'));
    await tester.pumpAndSettle();

    // In Food Spots:
    // - "All (1)"
    // - "Favorites (0)" -> strictly 0 because the favorited item was a pandal!
    // - "Hopped" pill must NOT be rendered at all
    // - Hopping progress bar must NOT be rendered at all
    // - "Nearby (10km)" is shared and present
    // - "Regions" is present
    expect(find.text('All (1)'), findsOneWidget);
    expect(find.text('Favorites (0)'), findsOneWidget);
    expect(find.textContaining('Hopped'), findsNothing);
    expect(find.textContaining('Hopping Progress'), findsNothing);
    expect(find.text('Nearby (10km)'), findsOneWidget);
    expect(find.text('Regions'), findsOneWidget);

    // 3. Favorite a food spot
    await userState.toggleFavorite('f_golbari');
    await tester.pumpAndSettle();

    // Food Spots favorites count updates to 1
    expect(find.text('Favorites (1)'), findsOneWidget);

    // 4. Switch back to Pandals segment
    await tester.tap(find.text('Pandals'));
    await tester.pumpAndSettle();

    // Pandals favorites count must remain 1 (only hatibagan_sarbojanin, NOT bumped by f_golbari!)
    expect(find.text('Favorites (1)'), findsOneWidget);
    // Hopped pill & progress bar reappear cleanly
    expect(find.text('Hopped (1)'), findsOneWidget);
    expect(find.textContaining('Hopping Progress: 1 of 2 Pandals Visited'), findsOneWidget);

    // 5. Unfavorite pandal
    await userState.toggleFavorite('hatibagan_sarbojanin');
    await tester.pumpAndSettle();

    // Pandals favorites count becomes 0
    expect(find.text('Favorites (0)'), findsOneWidget);

    // Switch back to Food Spots to verify food spot favorites count is STILL 1
    await tester.tap(find.text('Food Spots'));
    await tester.pumpAndSettle();

    expect(find.text('Favorites (1)'), findsOneWidget);
    expect(find.textContaining('Hopped'), findsNothing);
    expect(find.textContaining('Hopping Progress'), findsNothing);
  });
}

