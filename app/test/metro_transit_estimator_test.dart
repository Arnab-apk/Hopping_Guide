import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/models/metro_station.dart';
import 'package:kolkata_puja/repositories/metro_repository.dart';
import 'package:kolkata_puja/services/metro_transit_estimator.dart';

void main() {
  group('MetroTransitEstimator Tests', () {
    final shyambazar = MetroRepository.allStations.firstWhere((s) => s.matchesId('shyambazar'));
    final shobhabazar = MetroRepository.allStations.firstWhere((s) => s.matchesId('shobhabazar-sutanuti'));
    final mgRoad = MetroRepository.allStations.firstWhere((s) => s.matchesId('mahatma-gandhi-road'));
    final sectorV = MetroRepository.allStations.firstWhere((s) => s.matchesId('salt-lake-sector-v'));

    test('Same-line short hop: hop count and travel minutes are sane', () {
      final hops = MetroTransitEstimator.sameLineHopCount(shyambazar, shobhabazar);
      expect(hops, equals(1));

      // Same line hop between Shyambazar and MG Road (3 hops apart: Girish Park, MG Road)
      final hopsToMg = MetroTransitEstimator.sameLineHopCount(shyambazar, mgRoad);
      expect(hopsToMg, equals(3));

      // Estimate between points located right near Shyambazar and MG Road (~2.5 km direct)
      final estimate = MetroTransitEstimator.estimate(
        LatLng(shyambazar.latitude + 0.001, shyambazar.longitude),
        LatLng(mgRoad.latitude - 0.001, mgRoad.longitude),
        walkingSpeedKmH: 4.5,
      );

      expect(estimate, isNotNull);
      expect(estimate!.requiresInterchange, isFalse);
      expect(estimate.boardingStation.id, equals('shyambazar'));
      expect(estimate.alightingStation.id, equals('mahatma-gandhi-road'));
      expect(estimate.interchangeStation, isNull);
      // 3 hops * 2.5 min + 4 min boarding wait + walk time
      expect(estimate.totalMinutes, greaterThan(11.5));
    });

    test('Cross-line pair requiring exactly one interchange applies transfer penalty', () {
      final interchange = MetroTransitEstimator.findInterchange(
        KolkataMetroLine.blue,
        KolkataMetroLine.green,
      );
      expect(interchange, isNotNull);
      expect(interchange!.id, equals('esplanade'));

      // From Shyambazar (North Kolkata, Blue Line) to Sector V (Salt Lake, Green Line)
      final estimate = MetroTransitEstimator.estimate(
        LatLng(shyambazar.latitude, shyambazar.longitude),
        LatLng(sectorV.latitude, sectorV.longitude),
        walkingSpeedKmH: 4.5,
      );

      expect(estimate, isNotNull);
      expect(estimate!.requiresInterchange, isTrue);
      expect(estimate.interchangeStation, isNotNull);
      expect(estimate.interchangeStation!.id, equals('esplanade'));
      expect(estimate.boardingStation.id, equals('shyambazar'));
      expect(estimate.alightingStation.id, equals('salt-lake-sector-v'));

      // Hops: Shyambazar to Esplanade = 5 hops
      // Esplanade to Sector V = 8 hops
      // Ride = (5 + 8) * 2.5 = 32.5 min + 4.0 boarding + 9.0 interchange penalty = 45.5 min minimum
      expect(estimate.totalMinutes, greaterThanOrEqualTo(45.5));
    });

    test('Close pair (< 1.5 km direct) returns null — metro overhead erases benefit', () {
      // Two points only 400m apart near Shyambazar
      const pointA = LatLng(22.5997, 88.3712);
      const pointB = LatLng(22.6025, 88.3720);

      final estimate = MetroTransitEstimator.estimate(
        pointA,
        pointB,
        walkingSpeedKmH: 4.5,
      );

      expect(estimate, isNull);
    });

    test('Pair with point beyond max walk radius (> 1.2 km) returns null', () {
      // Point A near Shyambazar
      const pointA = LatLng(22.5997, 88.3712);
      // Point B far east in Rajarhat / New Town Action Area III where no metro station exists within 1.2km
      const pointB = LatLng(22.5700, 88.4800);

      final estimate = MetroTransitEstimator.estimate(
        pointA,
        pointB,
        walkingSpeedKmH: 4.5,
      );

      expect(estimate, isNull);
    });
  });
}
