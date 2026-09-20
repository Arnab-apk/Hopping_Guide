import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/models/metro_station.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/utils/constants.dart';
import 'package:kolkata_puja/services/trail_optimizer.dart';

Pandal _createTestPandal({
  required String id,
  required String name,
  required double lat,
  required double lng,
  KolkataZone zone = KolkataZone.northKolkata,
}) {
  return Pandal(
    id: id,
    name: name,
    lat: lat,
    lng: lng,
    zone: zone,
    theme: 'Traditional',
    timings: '24 Hours',
    imageUrl: 'https://example.com/img.jpg',
    description: 'Test pandal description',
  );
}

void main() {
  group('TrailOptimizer Tests', () {
    test('Edge case: 0 and 1 stops', () {
      const start = LatLng(22.5995, 88.3712); // Shyambazar
      final res0 = TrailOptimizer.optimizePandalStops(start: start, stops: []);
      expect(res0.orderedStops, isEmpty);
      expect(res0.totalDurationMinutes, 0.0);

      final p1 = _createTestPandal(
        id: 'hatibagan',
        name: 'Hatibagan Sarbojanin',
        lat: 22.5980,
        lng: 88.3710,
      );
      final res1 = TrailOptimizer.optimizePandalStops(start: start, stops: [p1]);
      expect(res1.orderedStops.length, 1);
      expect(res1.orderedStops.first.id, 'hatibagan');
      expect(res1.visitOrderIndices, [0]);
      expect(res1.totalDistanceKm, greaterThan(0));
    });

    test('Reversal Test: Optimizer finds shortest path, not mirroring input order', () {
      // Start in North Kolkata (Shyambazar)
      const start = LatLng(22.6000, 88.3700);

      // Pandal A: South Kolkata (Ekdalia Evergreen) ~9 km away
      final pandalSouth = _createTestPandal(
        id: 'ekdalia',
        name: 'Ekdalia Evergreen',
        zone: KolkataZone.southKolkata,
        lat: 22.5180,
        lng: 88.3650,
      );

      // Pandal B: North Kolkata (Hatibagan Sarbojanin) ~200 m away
      final pandalNorth = _createTestPandal(
        id: 'hatibagan',
        name: 'Hatibagan Sarbojanin',
        zone: KolkataZone.northKolkata,
        lat: 22.5985,
        lng: 88.3705,
      );

      // Deliberately pass South Kolkata FIRST, and North Kolkata SECOND
      final List<Pandal> inputOrder = [pandalSouth, pandalNorth];

      final result = TrailOptimizer.optimizePandalStops(
        start: start,
        stops: inputOrder,
      );

      // The optimizer MUST visit Hatibagan (North) FIRST, then Ekdalia (South) SECOND.
      // Visiting South first then coming back North would double the distance!
      expect(result.orderedStops.first.id, 'hatibagan');
      expect(result.orderedStops.last.id, 'ekdalia');
      expect(result.visitOrderIndices, [1, 0]); // Stop 1 (Hatibagan) visited first, then Stop 0 (Ekdalia)
    });

    test('Exact Held-Karp with 5 collinear points', () {
      // 5 points in a straight line from 1.0 km to 5.0 km
      // Start at 0 km
      // Even if scrambled, optimal visit order must be 1, 2, 3, 4, 5
      const start = LatLng(22.500, 88.300);
      final p1 = _createTestPandal(id: 'p1', name: 'P1', lat: 22.510, lng: 88.300);
      final p2 = _createTestPandal(id: 'p2', name: 'P2', lat: 22.520, lng: 88.300);
      final p3 = _createTestPandal(id: 'p3', name: 'P3', lat: 22.530, lng: 88.300);
      final p4 = _createTestPandal(id: 'p4', name: 'P4', lat: 22.540, lng: 88.300);
      final p5 = _createTestPandal(id: 'p5', name: 'P5', lat: 22.550, lng: 88.300);

      // Input shuffled
      final List<Pandal> shuffled = [p3, p5, p1, p4, p2];
      final res = TrailOptimizer.optimizePandalStops(start: start, stops: shuffled);

      final ids = res.orderedStops.map((p) => p.id).toList();
      expect(ids, ['p1', 'p2', 'p3', 'p4', 'p5']);
    });

    test('Heuristic 2-opt for N > 12 stops', () {
      const start = LatLng(22.500, 88.300);
      // Generate 15 collinear pandals
      final stops = List.generate(15, (i) {
        return _createTestPandal(
          id: 'p_$i',
          name: 'Pandal $i',
          lat: 22.500 + ((i + 1) * 0.005),
          lng: 88.300,
        );
      });

      // Reverse stops
      final List<Pandal> reversedInput = stops.reversed.toList();
      final res = TrailOptimizer.optimizePandalStops(start: start, stops: reversedInput);

      expect(res.orderedStops.length, 15);
      // The first stop from start must be the closest one (p_0)
      expect(res.orderedStops.first.id, 'p_0');
      expect(res.orderedStops.last.id, 'p_14');
    });

    test('Multi-modal optimization: cross-city North to South pandals use Metro when allowMetro is true', () {
      // Start in North Kolkata (Shyambazar Metro)
      const start = LatLng(22.5997, 88.3712);

      // Pandal in North Kolkata (Bagbazar Sarbojanin ~500m from Shyambazar)
      final bagbazar = _createTestPandal(
        id: 'bagbazar',
        name: 'Bagbazar Sarbojanin',
        lat: 22.6025,
        lng: 88.3680,
      );

      // Pandal in South Kolkata (Naktala Udayan Sangha ~14.5 km away, right near Gitanjali Metro)
      final naktala = _createTestPandal(
        id: 'naktala',
        name: 'Naktala Udayan Sangha',
        zone: KolkataZone.southKolkata,
        lat: 22.4703,
        lng: 88.3622,
      );

      // 1. Without metro (walking only)
      final walkOnly = TrailOptimizer.optimizePandalStops(
        start: start,
        stops: [bagbazar, naktala],
        allowMetro: false,
      );
      // Walking 14.5km takes > 200 minutes
      expect(walkOnly.totalDurationMinutes, greaterThan(180.0));
      expect(walkOnly.legs.every((l) => l.mode == LegMode.walk), isTrue);

      // 2. With metro enabled
      final multiModal = TrailOptimizer.optimizePandalStops(
        start: start,
        stops: [bagbazar, naktala],
        allowMetro: true,
      );

      // Optimizer still visits close Bagbazar first, then South Kolkata Naktala second
      expect(multiModal.orderedStops.first.id, equals('bagbazar'));
      expect(multiModal.orderedStops.last.id, equals('naktala'));

      // Total duration is dramatically reduced by taking Blue Line metro (~50 mins instead of 200+ mins)
      expect(multiModal.totalDurationMinutes, lessThan(90.0));
      expect(multiModal.totalDurationMinutes, lessThan(walkOnly.totalDurationMinutes));

      // The leg from Bagbazar to Naktala resolves to metro
      final metroLeg = multiModal.legs.firstWhere((l) => l.mode == LegMode.metro);
      expect(metroLeg.metroDetail, isNotNull);
      expect(metroLeg.metroDetail!.boardingStation.line, equals(KolkataMetroLine.blue));
      expect(metroLeg.metroDetail!.alightingStation.line, equals(KolkataMetroLine.blue));
      expect(
        ['masterda-surya-sen', 'gitanjali'],
        contains(metroLeg.metroDetail!.alightingStation.id),
      );
    });
  });
}
