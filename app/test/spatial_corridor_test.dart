import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/metro_station.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/repositories/supplementary_repository.dart';
import 'package:kolkata_puja/utils/constants.dart';
import 'package:kolkata_puja/utils/spatial_corridor.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('SpatialCorridorEngine Tests', () {
    // A walking route in North Kolkata:
    // From Sovabazar (22.5980, 88.3660) to Shyambazar (22.6040, 88.3710)
    final sampleRoute = [
      const LatLng(22.5980, 88.3660),
      const LatLng(22.6000, 88.3680),
      const LatLng(22.6040, 88.3710),
    ];

    // POI 1: Very close to route (approx 40m offset)
    const nearFood = FoodSpot(
      id: 'f1',
      name: 'Golbari Shyambazar',
      type: 'Restaurant',
      lat: 22.6038,
      lng: 22.6038 != 0 ? 88.3707 : 0,
      nearbyPandal: 'Shyambazar AV School',
      mustTry: 'Kosha Mangsho',
      priceRange: '₹₹',
    );

    // POI 2: About 120m offset from middle segment
    const nearMetro = MetroStation(
      id: 'm1',
      name: 'Shyambazar Metro',
      line: KolkataMetroLine.blue,
      latitude: 22.6042,
      longitude: 88.3715,
      isInterchange: false,
    );

    // POI 3: Close to the start of route
    final nearPandal = Pandal(
      id: 'p1',
      name: 'Sovabazar Rajbari',
      lat: 22.5982,
      lng: 88.3662,
      zone: KolkataZone.northKolkata,
      theme: 'Traditional Sabeki',
      timings: '24 Hours',
      imageUrl: '',
      description: 'Historical royal puja',
    );

    // POI 4: Far away in South Kolkata (Gariahat: 22.5180, 88.3650) > 8 km away
    const farFood = FoodSpot(
      id: 'f2',
      name: 'Bedouin Gariahat',
      type: 'Rolls',
      lat: 22.5180,
      lng: 88.3650,
      nearbyPandal: 'Ekdalia Evergreen',
      mustTry: 'Mutton Roll',
      priceRange: '₹',
    );

    test('empty polyline returns empty result', () {
      final result = SpatialCorridorEngine.searchAlongRoute(
        polyline: [],
        foodSpots: [nearFood, farFood],
      );

      expect(result.isEmpty, isTrue);
      expect(result.count, 0);
      expect(result.items, isEmpty);
    });

    test('filters POIs within 300m buffer and rejects far POIs', () {
      final result = SpatialCorridorEngine.searchAlongRoute(
        polyline: sampleRoute,
        foodSpots: [nearFood, farFood],
        metroStations: [nearMetro],
        pandals: [nearPandal],
        bufferMeters: 300.0,
      );

      expect(result.isNotEmpty, isTrue);
      expect(result.count, 3); // nearFood, nearMetro, nearPandal

      // Far food must be pruned by bounding box / distance
      final ids = result.items.map((i) => i.id).toList();
      expect(ids, contains('f1'));
      expect(ids, contains('m1'));
      expect(ids, contains('p1'));
      expect(ids, isNot(contains('f2')));

      // Verify perpendicular distance is within buffer
      for (final item in result.items) {
        expect(item.perpendicularDistanceMeters, lessThanOrEqualTo(300.0));
      }
    });

    test('sorts results by distanceAlongRouteMeters in encounter order', () {
      final result = SpatialCorridorEngine.searchAlongRoute(
        polyline: sampleRoute,
        foodSpots: [nearFood],
        metroStations: [nearMetro],
        pandals: [nearPandal],
      );

      expect(result.count, 3);

      // Sovabazar Rajbari is near the beginning of route
      expect(result.items[0].id, 'p1');

      // Golbari and Shyambazar Metro are near the end of route
      expect(result.items[0].distanceAlongRouteMeters,
          lessThan(result.items[1].distanceAlongRouteMeters));
      expect(result.items[1].distanceAlongRouteMeters,
          lessThanOrEqualTo(result.items[2].distanceAlongRouteMeters));
    });

    test('typed accessors filter correctly', () {
      final result = SpatialCorridorEngine.searchAlongRoute(
        polyline: sampleRoute,
        foodSpots: [nearFood],
        metroStations: [nearMetro],
        pandals: [nearPandal],
      );

      expect(result.foodSpots.length, 1);
      expect(result.foodSpots.first.name, 'Golbari Shyambazar');

      expect(result.metroStations.length, 1);
      expect(result.metroStations.first.name, 'Shyambazar Metro');

      expect(result.pandals.length, 1);
      expect(result.pandals.first.name, 'Sovabazar Rajbari');
    });

    test('item formatted strings produce accurate human outputs', () {
      final result = SpatialCorridorEngine.searchAlongRoute(
        polyline: sampleRoute,
        foodSpots: [nearFood],
      );

      final item = result.foodSpots.first;
      expect(item.formattedAlongDistance, contains('in '));
      expect(item.formattedDetourDistance, contains('off-route'));
      expect(item.subtitle, contains('Kosha Mangsho'));
      expect(item.badgeText, '₹₹');
    });

    test('single-point polyline handles search gracefully', () {
      final result = SpatialCorridorEngine.searchAlongRoute(
        polyline: [const LatLng(22.6040, 88.3710)],
        foodSpots: [nearFood, farFood],
        bufferMeters: 300.0,
      );

      expect(result.count, 1);
      expect(result.items.first.id, 'f1');
    });

    test('SpatialCorridor.findAlongPolyline filters and computes detour minutes', () {
      final matches = SpatialCorridor.findAlongPolyline<FoodSpot>(
        polyline: sampleRoute,
        items: [nearFood, farFood],
        getCoordinates: (f) => LatLng(f.lat, f.lng),
        maxCorridorMeters: 300.0,
      );

      expect(matches.length, 1);
      expect(matches.first.item.id, 'f1');
      expect(matches.first.distanceToCorridorMeters, lessThanOrEqualTo(300.0));
      expect(matches.first.estimatedDetourMinutes, greaterThanOrEqualTo(1));
    });

    test('SpatialCorridor.distanceToSegment measures accurately', () {
      const a = LatLng(22.5980, 88.3660);
      const b = LatLng(22.6040, 88.3660); // Straight North line
      const p = LatLng(22.6000, 88.3670); // Slightly to the East (~102m)

      final dist = SpatialCorridor.distanceToSegment(p, a, b);
      expect(dist, greaterThan(90));
      expect(dist, lessThan(120));
    });
  });
}
