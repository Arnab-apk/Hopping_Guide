import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/utils/constants.dart';
import 'package:kolkata_puja/utils/pandal_spatial_cluster.dart';

void main() {
  group('PandalSpatialClusterer Tests', () {
    setUp(PandalSpatialClusterer.invalidateCache);
    final pandals = [
      Pandal(
        id: 'p1',
        name: 'Bagbazar Sarbojanin',
        lat: 22.6025,
        lng: 88.3685,
        zone: KolkataZone.northKolkata,
        theme: 'Traditional',
        timings: 'Open 24 hrs',
        imageUrl: '',
        description: '',
      ),
      Pandal(
        id: 'p2',
        name: 'Kumartuli Park',
        lat: 22.6010,
        lng: 88.3660,
        zone: KolkataZone.northKolkata,
        theme: 'Art & Heritage',
        timings: 'Open 24 hrs',
        imageUrl: '',
        description: '',
      ),
      Pandal(
        id: 'p3',
        name: 'Ekdalia Evergreen',
        lat: 22.5190,
        lng: 88.3670,
        zone: KolkataZone.southKolkata,
        theme: 'Illumination',
        timings: 'Open 24 hrs',
        imageUrl: '',
        description: '',
      ),
    ];

    test(
      'Zoom changes within a band reuse clusters while bounds are stable',
      () {
        final bounds = LatLngBounds(
          const LatLng(22.4, 88.2),
          const LatLng(22.7, 88.5),
        );
        final first = PandalSpatialClusterer.cluster(
          pandals: pandals,
          zoom: 14.1,
          visibleBounds: bounds,
        );
        final second = PandalSpatialClusterer.cluster(
          pandals: pandals,
          zoom: 14.6,
          visibleBounds: bounds,
        );
        expect(second, same(first));
        final changed = PandalSpatialClusterer.cluster(
          pandals: pandals,
          zoom: 14.6,
          visibleBounds: LatLngBounds(
            const LatLng(22.5, 88.3),
            const LatLng(22.6, 88.4),
          ),
        );
        expect(changed, isNot(same(first)));
      },
    );

    test('Changing a same-size region replaces cached pins', () {
      final bounds = LatLngBounds(
        const LatLng(22.4, 88.2),
        const LatLng(22.7, 88.5),
      );
      final first = PandalSpatialClusterer.cluster(
        pandals: [pandals[0]],
        zoom: 15,
        visibleBounds: bounds,
      );
      final second = PandalSpatialClusterer.cluster(
        pandals: [pandals[2]],
        zoom: 15,
        visibleBounds: bounds,
      );
      expect(first.single.id, 'p1');
      expect(second.single.id, 'p3');
    });

    test('Changing same-size trail priority sets updates individual pins', () {
      final bounds = LatLngBounds(
        const LatLng(22.4, 88.2),
        const LatLng(22.7, 88.5),
      );
      final first = PandalSpatialClusterer.cluster(
        pandals: pandals,
        zoom: 11.5,
        visibleBounds: bounds,
        priorityPandalIds: {'p1'},
      );
      final second = PandalSpatialClusterer.cluster(
        pandals: pandals,
        zoom: 11.5,
        visibleBounds: bounds,
        priorityPandalIds: {'p2'},
      );
      expect(first.first.id, 'p1');
      expect(second.first.id, 'p2');
    });

    test('Crossing a zoom threshold invalidates cached clusters', () {
      final nearby = [
        for (var i = 0; i < 2; i++)
          Pandal(
            id: 'near$i',
            name: 'Nearby $i',
            lat: 22.6000 + i * .0001,
            lng: 88.3600,
            zone: KolkataZone.northKolkata,
            theme: '',
            timings: '',
            imageUrl: '',
            description: '',
          ),
      ];
      final bounds = LatLngBounds(
        const LatLng(22.4, 88.2),
        const LatLng(22.7, 88.5),
      );
      final before = PandalSpatialClusterer.cluster(
        pandals: nearby,
        zoom: 14.79,
        visibleBounds: bounds,
      );
      final after = PandalSpatialClusterer.cluster(
        pandals: nearby,
        zoom: 14.81,
        visibleBounds: bounds,
      );
      expect(before.single.isCluster, isTrue);
      expect(after.length, 2);
      expect(after.every((item) => !item.isCluster), isTrue);
    });

    test('Returns empty when given empty list', () {
      final clusters = PandalSpatialClusterer.cluster(
        allPandals: [],
        zoom: 12.0,
        visibleBounds: LatLngBounds(
          const LatLng(22.4, 88.2),
          const LatLng(22.7, 88.5),
        ),
      );
      expect(clusters, isEmpty);
    });

    test('Clusters nearby north pandals together at low zoom (11.5)', () {
      final clusters = PandalSpatialClusterer.cluster(
        allPandals: pandals,
        zoom: 11.5,
        visibleBounds: LatLngBounds(
          const LatLng(22.4, 88.2),
          const LatLng(22.7, 88.5),
        ),
      );

      // p1 and p2 are very close (~200m), so at zoom 11.5 they cluster together
      final cluster = clusters.firstWhere((c) => c.isCluster);
      expect(cluster.count, greaterThanOrEqualTo(2));
      expect(cluster.pandals.map((p) => p.id), containsAll(['p1', 'p2']));
    });

    test(
      'Separates all pandals into individual markers at street zoom (15.0)',
      () {
        final clusters = PandalSpatialClusterer.cluster(
          allPandals: pandals,
          zoom: 15.0,
          visibleBounds: LatLngBounds(
            const LatLng(22.4, 88.2),
            const LatLng(22.7, 88.5),
          ),
        );

        // At zoom 15, none should be a cluster with count > 1
        for (final item in clusters) {
          expect(item.isCluster, isFalse);
          expect(item.count, equals(1));
        }
        expect(clusters.length, equals(3));
      },
    );

    test('Culls pandals outside viewport bounds', () {
      // Bounds only covering South Kolkata
      final southBounds = LatLngBounds(
        const LatLng(22.50, 88.35),
        const LatLng(22.53, 88.38),
      );
      final clusters = PandalSpatialClusterer.cluster(
        allPandals: pandals,
        zoom: 15.0,
        visibleBounds: southBounds,
      );

      expect(clusters.any((c) => c.primaryPandal?.id == 'p3'), isTrue);
      expect(clusters.any((c) => c.primaryPandal?.id == 'p1'), isFalse);
    });

    test('Always preserves selected pandal even outside viewport bounds', () {
      final southBounds = LatLngBounds(
        const LatLng(22.50, 88.35),
        const LatLng(22.53, 88.38),
      );
      final clusters = PandalSpatialClusterer.cluster(
        allPandals: pandals,
        zoom: 15.0,
        visibleBounds: southBounds,
        selectedPandal: pandals[0], // p1 in North Kolkata
      );

      expect(clusters.any((c) => c.primaryPandal?.id == 'p1'), isTrue);
    });
  });
}
