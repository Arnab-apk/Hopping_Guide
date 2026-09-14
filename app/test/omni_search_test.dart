import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/repositories/metro_repository.dart';
import 'package:kolkata_puja/repositories/supplementary_repository.dart';
import 'package:kolkata_puja/services/omni_search_service.dart';
import 'package:kolkata_puja/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<Pandal> mockPandals = [
    Pandal(
      id: 'p1',
      name: 'Ekdalia Evergreen Club',
      zone: KolkataZone.southKolkata,
      lat: 22.5222,
      lng: 88.3656,
      nearestMetro: 'Gariahat',
      theme: 'Traditional heritage temple',
      timings: 'Open 24 hours',
      imageUrl: '',
      description: 'South Kolkata heritage pandal',
      rating: 4.8,
    ),
    Pandal(
      id: 'p2',
      name: 'Shreebhumi Sporting Club',
      zone: KolkataZone.northKolkata,
      lat: 22.5997,
      lng: 88.3999,
      nearestMetro: 'Ultadanga',
      theme: 'Disneyland replica',
      timings: 'Open 24 hours',
      imageUrl: '',
      description: 'Grand themed pandal',
      rating: 4.9,
    ),
    Pandal(
      id: 'p3',
      name: 'Santosh Mitra Square',
      zone: KolkataZone.centralKolkata,
      lat: 22.5694,
      lng: 88.3653,
      nearestMetro: 'Central',
      theme: 'Ayodhya Ram Mandir replica',
      timings: 'Open 24 hours',
      imageUrl: '',
      description: 'Popular Central Kolkata pandal',
      rating: 4.7,
    ),
  ];

  final mockFoodSpots = [
    const FoodSpot(
      id: 'f1',
      name: 'Golbari (New Punjabi Hotel)',
      type: 'Iconic Kosha Mangsho & Paratha',
      lat: 22.6006,
      lng: 88.3704,
      nearbyPandal: 'Shyambazar 5 Point Crossing Sarbojanin',
      rating: 4.4,
      mustTry: 'Kosha Mangsho & Triangle Paratha',
    ),
    const FoodSpot(
      id: 'f2',
      name: 'Mitra Cafe (Shyambazar)',
      type: 'Colonial Bengali Heritage Snacks',
      lat: 22.5997,
      lng: 88.3712,
      nearbyPandal: 'Jagat Mukherjee Park',
      rating: 4.5,
      mustTry: 'Diamond Fish Fry, Brain Chop',
    ),
    const FoodSpot(
      id: 'f3',
      name: 'Arsalan Biryani (Park Circus)',
      type: 'Kolkata Mughlai & Biryani',
      lat: 22.5447,
      lng: 88.3667,
      nearbyPandal: 'Park Circus Sarbojanin',
      rating: 4.6,
      mustTry: 'Mutton Biryani Special',
    ),
  ];

  group('OmniSearchService Multi-Entity Universal Search Tests', () {
    test('Searches across pandals, metro, and food spots simultaneously in All mode', () {
      final results = OmniSearchService.instance.search(
        query: 'Shyam',
        pandals: mockPandals,
        foodSpots: mockFoodSpots,
        metroStations: MetroRepository.allStations,
        category: OmniCategory.all,
      );

      expect(results.isNotEmpty, isTrue);

      // Should find Shyambazar Metro
      final hasMetro = results.any(
        (r) => r.type == OmniResultType.metro && r.title.contains('Shyambazar'),
      );
      expect(hasMetro, isTrue);

      // Should find Mitra Cafe or Golbari (near Shyambazar)
      final hasFood = results.any(
        (r) => r.type == OmniResultType.food && (r.title.contains('Shyambazar') || r.subtitle.contains('Shyambazar')),
      );
      expect(hasFood, isTrue);
    });

    test('Filters strictly by category when requested', () {
      // Metro only
      final metroOnly = OmniSearchService.instance.search(
        query: 'Shyam',
        pandals: mockPandals,
        foodSpots: mockFoodSpots,
        metroStations: MetroRepository.allStations,
        category: OmniCategory.metro,
      );
      expect(metroOnly.every((r) => r.type == OmniResultType.metro), isTrue);

      // Food only
      final foodOnly = OmniSearchService.instance.search(
        query: 'Mitra',
        pandals: mockPandals,
        foodSpots: mockFoodSpots,
        metroStations: MetroRepository.allStations,
        category: OmniCategory.food,
      );
      expect(foodOnly.every((r) => r.type == OmniResultType.food), isTrue);
      expect(foodOnly.any((r) => r.title.contains('Mitra Cafe')), isTrue);

      // Pandals only
      final pandalsOnly = OmniSearchService.instance.search(
        query: 'Mitra',
        pandals: mockPandals,
        foodSpots: mockFoodSpots,
        metroStations: MetroRepository.allStations,
        category: OmniCategory.pandals,
      );
      expect(pandalsOnly.every((r) => r.type == OmniResultType.pandal), isTrue);
      expect(pandalsOnly.any((r) => r.title.contains('Santosh Mitra')), isTrue);
    });

    test('Searches by food cuisine, dish specialty, or price', () {
      final results = OmniSearchService.instance.search(
        query: 'Biryani',
        pandals: mockPandals,
        foodSpots: mockFoodSpots,
        metroStations: MetroRepository.allStations,
        category: OmniCategory.all,
      );

      expect(results.isNotEmpty, isTrue);
      final topResult = results.first;
      expect(topResult.type, equals(OmniResultType.food));
      expect(topResult.title, contains('Arsalan'));
    });

    test('Searches metro stations by line keyword', () {
      final results = OmniSearchService.instance.search(
        query: 'Blue Line',
        pandals: mockPandals,
        foodSpots: mockFoodSpots,
        metroStations: MetroRepository.allStations,
        category: OmniCategory.metro,
      );

      expect(results.isNotEmpty, isTrue);
      expect(results.every((r) => r.type == OmniResultType.metro), isTrue);
    });
  });
}
