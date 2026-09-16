import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/config/pandal_theme_tokens.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/repositories/supplementary_repository.dart';
import 'package:kolkata_puja/utils/constants.dart';
import 'package:kolkata_puja/widgets/pandal_offline_card.dart';
import 'package:kolkata_puja/widgets/search_along_route_hud.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('PandalOfflineThemeTokens Tests', () {
    test('default tokens match OLED dark palette and contrast standards', () {
      const tokens = PandalOfflineThemeTokens();

      expect(tokens.crimsonVelvet, const Color(0xFF800020));
      expect(tokens.festivalGold, const Color(0xFFFFD700));
      expect(tokens.surfaceCard, const Color(0xFF16171D)); // OLED-safe
      expect(tokens.offlineBg, const Color(0xFF10281C));
      expect(tokens.offlineFg, const Color(0xFF4ADE80));
      expect(tokens.staleBg, const Color(0xFF2C1F0E));
      expect(tokens.staleFg, const Color(0xFFFBBF24));
    });

    test('copyWith works correctly', () {
      const tokens = PandalOfflineThemeTokens();
      final updated = tokens.copyWith(surfaceCard: const Color(0xFF112233));
      expect(updated.surfaceCard, const Color(0xFF112233));
      expect(updated.festivalGold, const Color(0xFFFFD700));
    });

    test('lerp interpolates between tokens', () {
      const a = PandalOfflineThemeTokens(surfaceCard: Color(0xFF000000));
      const b = PandalOfflineThemeTokens(surfaceCard: Color(0xFFFFFFFF));
      final result = a.lerp(b, 0.5);
      expect(result.surfaceCard, Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5));
    });
  });

  group('PandalOfflineCard Widget Tests', () {
    final testPandal = Pandal(
      id: 'bagbazar',
      name: 'Bagbazar Sarbojanin',
      lat: 22.6025,
      lng: 88.3688,
      zone: KolkataZone.northKolkata,
      theme: '107 Years Traditional Durga',
      timings: '24 Hours',
      imageUrl: '',
      description: 'One of the oldest community pujas',
      nearestMetro: 'Shyambazar',
      crowdLevel: 'High',
    );

    testWidgets('renders with offline badge, walking ETA, and buttons without layout error',
        (tester) async {
      bool walked = false;
      bool metroViewed = false;
      bool bookmarked = false;
      bool closed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [PandalOfflineThemeTokens()],
          ),
          home: Scaffold(
            body: PandalOfflineCard(
              pandal: testPandal,
              distanceMeters: 750,
              walkingEtaText: '10 min',
              syncStatus: OfflineSyncStatus.fullyCached,
              onStartRoute: () => walked = true,
              onShowMetro: () => metroViewed = true,
              onToggleBookmark: () => bookmarked = true,
              isBookmarked: true,
              onClose: () => closed = true,
            ),
          ),
        ),
      );

      // Verify title and zone
      expect(find.text('Bagbazar Sarbojanin'), findsOneWidget);
      expect(find.text('North Kolkata'), findsOneWidget);

      // Verify explicit offline badge
      expect(find.text('AVAILABLE OFFLINE'), findsOneWidget);

      // Verify walking ETA pill
      expect(find.textContaining('10 min (0.8 km)'), findsOneWidget);

      // Verify nearest metro pill
      expect(find.text('Shyambazar'), findsOneWidget);

      // Verify telemetry alert
      expect(find.textContaining('Congested cell towers detected'), findsOneWidget);

      // Tap buttons
      await tester.tap(find.text('Walk Guide'));
      expect(walked, isTrue);

      await tester.tap(find.text('Metro Route'));
      expect(metroViewed, isTrue);

      // Tap bookmark
      await tester.tap(find.byIcon(Icons.favorite_rounded));
      expect(bookmarked, isTrue);

      // Tap close
      await tester.tap(find.byIcon(Icons.close_rounded));
      expect(closed, isTrue);
    });
  });

  group('SearchAlongRouteHud Widget Tests', () {
    final route = [
      const LatLng(22.5980, 88.3660),
      const LatLng(22.6040, 88.3710),
    ];

    const food = FoodSpot(
      id: 'f1',
      name: 'Kolkata Kathi Roll',
      type: 'Snacks',
      lat: 22.6000,
      lng: 88.3680,
      nearbyPandal: 'Bagbazar',
      mustTry: 'Egg Chicken Roll',
      priceRange: '₹',
    );

    testWidgets('renders HUD carousel and handles selection and exit',
        (tester) async {
      FoodSpot? selectedSpot;
      bool cleared = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark().copyWith(
            extensions: const [PandalOfflineThemeTokens()],
          ),
          home: Scaffold(
            body: SearchAlongRouteHUD(
              activePolyline: route,
              allFoodSpots: const [food],
              onSelectFoodSpot: (spot) => selectedSpot = spot,
              onClearRoute: () => cleared = true,
            ),
          ),
        ),
      );

      // Verify header and spots count
      expect(find.text('ALONG TRAIL CORRIDOR (1 SPOTS)'), findsOneWidget);

      // Verify food item in carousel
      expect(find.text('Kolkata Kathi Roll'), findsOneWidget);
      expect(find.textContaining('detour'), findsOneWidget);

      // Tap food spot
      await tester.tap(find.text('Kolkata Kathi Roll'));
      expect(selectedSpot, isNotNull);
      expect(selectedSpot!.name, 'Kolkata Kathi Roll');

      // Tap Exit
      await tester.tap(find.text('Exit'));
      expect(cleared, isTrue);
    });
  });
}
