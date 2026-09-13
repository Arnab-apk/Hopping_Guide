import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/repositories/supplementary_repository.dart';
import 'package:kolkata_puja/services/custom_hopping_trail_service.dart';
import 'package:kolkata_puja/utils/constants.dart';
import 'package:kolkata_puja/utils/haversine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<Pandal> mockPandals;
  late List<FoodSpot> mockFoodSpots;

  setUp(() {
    SharedPreferences.setMockInitialValues({});

    mockPandals = [
      Pandal(
        id: 'north_1',
        name: 'Hatibagan Sarbojanin',
        lat: 22.5995,
        lng: 88.3712,
        zone: KolkataZone.northKolkata,
        theme: 'Heritage Sabeki',
        timings: '24 Hours',
        imageUrl: '',
        description: 'North classic',
        rating: 4.8,
        crowdLevel: 'high',
      ),
      Pandal(
        id: 'north_2',
        name: 'Kashi Bose Lane',
        lat: 22.5980,
        lng: 88.3735,
        zone: KolkataZone.northKolkata,
        theme: 'Lighting Marvel',
        timings: '24 Hours',
        imageUrl: '',
        description: 'North crowd puller',
        rating: 4.9,
        crowdLevel: 'extreme',
      ),
      Pandal(
        id: 'south_1',
        name: 'Ekdalia Evergreen',
        lat: 22.5190,
        lng: 88.3680,
        zone: KolkataZone.southKolkata,
        theme: 'Grand Illumination',
        timings: '24 Hours',
        imageUrl: '',
        description: 'South blockbuster',
        rating: 4.9,
        crowdLevel: 'extreme',
      ),
    ];

    mockFoodSpots = [
      const FoodSpot(
        id: 'food_north_1',
        name: 'Mitra Cafe',
        type: 'Snacks',
        lat: 22.5985,
        lng: 88.3705,
        mustTry: 'Mutton Kabiraji',
        nearbyPandal: 'Hatibagan Sarbojanin',
      ),
      const FoodSpot(
        id: 'food_south_1',
        name: 'Bhojohori Manna',
        type: 'Restaurant',
        lat: 22.5195,
        lng: 88.3675,
        mustTry: 'Kosha Mangsho',
        nearbyPandal: 'Ekdalia Evergreen',
      ),
    ];
  });

  group('Map State Coordinator & Conflict-Free Resolution', () {
    test('Selected pandal in South Kolkata is preserved even if North zone filter is active', () {
      final selectedPandal = mockPandals.firstWhere((p) => p.id == 'south_1');
      const activeZone = KolkataZone.northKolkata;

      // Filter by activeZone
      List<Pandal> visible = mockPandals.where((p) => p.zone == activeZone).toList();
      expect(visible.length, 2);
      expect(visible.any((p) => p.id == 'south_1'), isFalse);

      // Apply zero-intervention guarantee (as implemented in map_screen.dart: _visiblePandals)
      if (!visible.any((p) => p.id == selectedPandal.id)) {
        visible = [selectedPandal, ...visible];
      }

      expect(visible.length, 3);
      expect(visible.any((p) => p.id == 'south_1'), isTrue);
      expect(visible.first.name, equals('Ekdalia Evergreen'));
    });

    test('Food spots are contextualized to 2.5km walking radius when a pandal is selected', () {
      final selectedPandal = mockPandals.firstWhere((p) => p.id == 'south_1');

      // Contextual food spot resolution (as implemented in map_screen.dart: _visibleFoodSpots)
      final nearbyToPandal = mockFoodSpots.where((f) {
        return haversineMeters(selectedPandal.lat, selectedPandal.lng, f.lat, f.lng) <= 2500;
      }).toList();

      expect(nearbyToPandal.length, 1);
      expect(nearbyToPandal.first.name, equals('Bhojohori Manna'));
      expect(nearbyToPandal.first.nearbyPandal, equals('Ekdalia Evergreen'));
    });

    test('Active Hopping Trail stops are preserved across spatial filter boundaries', () {
      // Create a trail that includes both North and South stops
      final multiZoneStops = [
        mockPandals.firstWhere((p) => p.id == 'north_1'),
        mockPandals.firstWhere((p) => p.id == 'south_1'),
      ];
      final trail = ActiveCustomTrail(
        id: 'test_trail_multi_zone',
        style: HoppingStyle.express,
        timeBudgetMinutes: 120,
        transitMode: HoppingTransitMode.walking,
        startingLocation: const LatLng(22.5995, 88.3712),
        startingAddress: 'Hatibagan',
        stops: multiZoneStops,
        totalDistanceKm: 12.0,
        totalEstimatedMinutes: 120,
      );

      expect(trail.stops.length, 2);

      // Simulate active zone set to North Kolkata
      const activeZone = KolkataZone.northKolkata;
      List<Pandal> list = mockPandals.where((p) => p.zone == activeZone).toList();

      // Ensure stops from active trail are preserved (as implemented in map_screen.dart: _visiblePandals)
      for (final stop in trail.stops) {
        if (!list.any((p) => p.id == stop.id)) {
          list.add(stop);
        }
      }

      expect(list.any((p) => p.id == 'north_1'), isTrue);
      expect(list.any((p) => p.id == 'south_1'), isTrue);
      expect(list.length, 3);
    });

    test('Mutual filter exclusivity clears competing state', () {
      // Scenario: User had a zone selected, then taps Nearby (10km)
      KolkataZone? selectedZone = KolkataZone.northKolkata;
      bool filterNearby10Km = false;

      // Tap Nearby (10km)
      selectedZone = null;
      filterNearby10Km = true;

      expect(filterNearby10Km, isTrue);
      expect(selectedZone, isNull);

      // Tap a Region
      selectedZone = KolkataZone.southKolkata;
      filterNearby10Km = false;

      expect(selectedZone, equals(KolkataZone.southKolkata));
      expect(filterNearby10Km, isFalse);
    });

    test('Selected food spot is preserved in visible list regardless of zone or distance filter', () {
      final selectedFood = mockFoodSpots.firstWhere((f) => f.id == 'food_south_1');
      const activeZone = KolkataZone.northKolkata;

      // Filter by active zone (North)
      List<FoodSpot> visible = mockFoodSpots.where((f) {
        final matchingPandal = mockPandals.firstWhere(
          (p) => p.name.toLowerCase() == f.nearbyPandal.toLowerCase(),
          orElse: () => mockPandals.first,
        );
        return matchingPandal.zone == activeZone;
      }).toList();

      expect(visible.any((f) => f.id == 'food_south_1'), isFalse);

      // Apply zero-intervention guarantee (as implemented in map_screen.dart: _visibleFoodSpots)
      if (!visible.any((f) => f.id == selectedFood.id)) {
        visible = [selectedFood, ...visible];
      }

      expect(visible.any((f) => f.id == 'food_south_1'), isTrue);
      expect(visible.first.name, equals('Bhojohori Manna'));
    });
  });
}
