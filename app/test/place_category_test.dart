import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/models/place.dart';
import 'package:kolkata_puja/repositories/supplementary_repository.dart';
import 'package:kolkata_puja/screens/main_navigation_screen.dart';
import 'package:kolkata_puja/screens/pandal_list_screen.dart';
import 'package:kolkata_puja/utils/constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlaceCategory & Place Model Tests', () {
    test('PlaceCategory values are distinct', () {
      expect(PlaceCategory.values, contains(PlaceCategory.pandal));
      expect(PlaceCategory.values, contains(PlaceCategory.foodSpot));
      expect(PlaceCategory.pandal.name, 'pandal');
      expect(PlaceCategory.foodSpot.name, 'foodSpot');
    });

    test('Pandal model returns PlaceCategory.pandal', () {
      final pandal = Pandal(
        id: 'test_pandal',
        name: 'Test Pandal',
        lat: 22.5,
        lng: 88.3,
        zone: KolkataZone.northKolkata,
        theme: 'Traditional',
        timings: '24 hrs',
        imageUrl: '',
        description: 'Test',
      );
      expect(pandal.category, PlaceCategory.pandal);

      final place = Place.fromPandal(pandal);
      expect(place.id, 'test_pandal');
      expect(place.name, 'Test Pandal');
      expect(place.category, PlaceCategory.pandal);
      expect(place.isPandal, isTrue);
      expect(place.isFoodSpot, isFalse);
      expect(place.zone, KolkataZone.northKolkata);
      expect(place.theme, 'Traditional');
    });

    test('FoodSpot model returns PlaceCategory.foodSpot', () {
      const foodSpot = FoodSpot(
        id: 'f_golbari',
        name: 'Golbari',
        type: 'Kosha Mangsho',
        lat: 22.59,
        lng: 88.37,
        nearbyPandal: 'Shyambazar',
        mustTry: 'Kosha Mangsho with Paratha',
        priceRange: '₹₹',
        rating: 4.4,
      );
      expect(foodSpot.category, PlaceCategory.foodSpot);

      final place = Place.fromFoodSpot(foodSpot, zone: KolkataZone.northKolkata);
      expect(place.id, 'f_golbari');
      expect(place.name, 'Golbari');
      expect(place.category, PlaceCategory.foodSpot);
      expect(place.isPandal, isFalse);
      expect(place.isFoodSpot, isTrue);
      expect(place.mustTry, 'Kosha Mangsho with Paratha');
      expect(place.priceRange, '₹₹');
      expect(place.rating, 4.4);
      expect(place.zone, KolkataZone.northKolkata);
    });

    test('Place.fromDoc constructs correctly based on category field', () {
      final pandalDoc = {
        'name': 'Baghbazar Sarbojanin',
        'category': 'pandal',
        'lat': 22.6,
        'lng': 88.36,
        'zone': 'northKolkata',
        'theme': 'Heritage',
      };
      final pPlace = Place.fromDoc(pandalDoc, 'baghbazar');
      expect(pPlace.category, PlaceCategory.pandal);
      expect(pPlace.isPandal, isTrue);
      expect(pPlace.name, 'Baghbazar Sarbojanin');

      final foodDoc = {
        'name': 'Mitra Cafe',
        'category': 'foodSpot',
        'lat': 22.598,
        'lng': 88.369,
        'type': 'Cutlets',
        'mustTry': 'Brain Chop',
      };
      final fPlace = Place.fromDoc(foodDoc, 'mitra_cafe');
      expect(fPlace.category, PlaceCategory.foodSpot);
      expect(fPlace.isFoodSpot, isTrue);
      expect(fPlace.name, 'Mitra Cafe');
      expect(fPlace.mustTry, 'Brain Chop');
    });
  });

  group('Deep Link & Tab Navigation Tests', () {
    test('PandalListScreen.switchToCategory sets notifier and triggers MainNavigationScreen', () {
      PandalListScreen.externalCategoryNotifier.value = null;
      MainNavigationScreen.tabSwitchNotifier.value = null;

      PandalListScreen.switchToCategory(PlaceCategory.foodSpot);

      expect(PandalListScreen.externalCategoryNotifier.value, PlaceCategory.foodSpot);
      expect(MainNavigationScreen.tabSwitchNotifier.value, 1);
    });
  });
}
