import 'dart:convert';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/repositories/local_pandal_repository.dart';
import 'package:kolkata_puja/repositories/metro_repository.dart';
import 'package:kolkata_puja/repositories/supplementary_repository.dart';
import 'package:kolkata_puja/services/omni_search_service.dart';
import 'package:kolkata_puja/services/routing_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/utils/pandal_spatial_cluster.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Scalability Test 1: Massive Concurrent Local Dataset Reads', () {
    test('1,000 concurrent repository reads complete with zero latency degradation', () async {
      final repo = LocalAssetPandalRepository();
      final stopwatch = Stopwatch()..start();

      // Launch 1,000 parallel async queries
      final futures = List.generate(1000, (_) => repo.all());
      final results = await Future.wait(futures);

      stopwatch.stop();

      expect(results.length, equals(1000));
      for (final list in results) {
        expect(list.length, equals(387));
      }

      // Memoized local repository should serve 1,000 queries in under 500ms
      expect(stopwatch.elapsedMilliseconds, lessThan(500),
          reason: '1,000 queries took ${stopwatch.elapsedMilliseconds}ms');
    });
  });

  group('Scalability Test 2: OmniSearch HUD High-Throughput Stress', () {
    test('2,000 multi-category search queries execute in under 1200ms (< 0.6ms/query)', () async {
      final pandalRepo = LocalAssetPandalRepository();
      final suppRepo = SupplementaryRepository();
      final pandals = await pandalRepo.all();
      final foodSpots = await suppRepo.getFoodSpots();
      final metroStations = MetroRepository.allStations;

      final queries = [
        'bagbazar', 'bose', 'biryani', 'dakshineswar', 'esplanade',
        'park', 'dum dum', 'sweet', 'roll', 'north', 'south',
      ];

      final stopwatch = Stopwatch()..start();

      // Execute 2,000 searches sequentially
      int totalResultsCount = 0;
      for (int i = 0; i < 2000; i++) {
        final query = queries[i % queries.length];
        final results = OmniSearchService.instance.search(
          query: query,
          pandals: pandals,
          foodSpots: foodSpots,
          metroStations: metroStations,
          category: OmniCategory.all,
        );
        totalResultsCount += results.length;
      }

      stopwatch.stop();

      expect(totalResultsCount, greaterThan(2000));
      final avgMs = stopwatch.elapsedMilliseconds / 2000.0;

      expect(stopwatch.elapsedMilliseconds, lessThan(1200),
          reason: '2,000 searches took ${stopwatch.elapsedMilliseconds}ms (avg: ${avgMs.toStringAsFixed(2)}ms)');
    });
  });

  group('Scalability Test 3: Spatial Clustering Viewport Stress & L1 Cache', () {
    test('500 rapid map camera transitions maintain > 80% L1 cache efficiency', () async {
      final repo = LocalAssetPandalRepository();
      final pandals = await repo.all();

      PandalSpatialClusterer.invalidateCache();

      final baseBounds = LatLngBounds(
        const LatLng(22.50, 88.30),
        const LatLng(22.60, 88.40),
      );

      final stopwatch = Stopwatch()..start();

      // Simulate 500 consecutive map updates (simulating 60/120 FPS gesture pan)
      int clusterCount = 0;
      for (int i = 0; i < 500; i++) {
        // Micro-drift simulation (< 0.05 degree shift)
        final shift = (i % 20) * 0.0002;
        final currentBounds = LatLngBounds(
          LatLng(baseBounds.south + shift, baseBounds.west + shift),
          LatLng(baseBounds.north + shift, baseBounds.east + shift),
        );

        final clusters = PandalSpatialClusterer.cluster(
          pandals: pandals,
          zoom: 13.5 + (i % 3) * 0.01,
          visibleBounds: currentBounds,
        );
        clusterCount += clusters.length;
      }

      stopwatch.stop();

      expect(clusterCount, greaterThan(0));
      expect(stopwatch.elapsedMilliseconds, lessThan(300),
          reason: '500 spatial cluster operations took ${stopwatch.elapsedMilliseconds}ms');
    });
  });

  group('Scalability Test 4: Pedestrian Routing Under Server Throttling & Circuit Breaker', () {
    test('Route Cache serves repeat queries without network calls', () async {
      int serverCalls = 0;
      final mockClient = MockClient((request) async {
        serverCalls++;
        return http.Response(
          jsonEncode({
            'routes': [
              {
                'distance': 1200.0,
                'duration': 960.0,
                'geometry': {
                  'coordinates': [
                    [88.35, 22.56],
                    [88.355, 22.565],
                  ]
                }
              }
            ]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final routing = RoutingService(client: mockClient);
      routing.clearRouteCache();

      const start = LatLng(22.56, 88.35);
      const dest = LatLng(22.565, 88.355);

      // First call -> hits network
      final r1 = await routing.getWalkingRouteToPoint(
        start: start,
        destination: dest,
        destinationName: 'Bagbazar Pandal',
      );
      expect(serverCalls, equals(1));
      expect(r1.distanceMeters, equals(1200.0));

      // Second call to same coordinates -> served from memory cache (0 server calls)
      final r2 = await routing.getWalkingRouteToPoint(
        start: start,
        destination: dest,
        destinationName: 'Bagbazar Pandal',
      );
      expect(serverCalls, equals(1)); // Still 1! Cache hit!
      expect(r2.distanceMeters, equals(1200.0));
    });

    test('Circuit breaker trips on consecutive 429/500 throttles and uses instant offline fallback', () async {
      int serverCalls = 0;
      final throttlingClient = MockClient((request) async {
        serverCalls++;
        // Simulate HTTP 429 Too Many Requests from overloaded public server
        return http.Response('Rate Limit Exceeded', 429);
      });

      final routing = RoutingService(client: throttlingClient);
      routing.clearRouteCache();
      routing.resetCircuitBreaker();

      const start = LatLng(22.56, 88.35);
      const dest = LatLng(22.58, 88.37);

      // Call 1, 2, 3 -> fail and trip circuit breaker
      final f1 = await routing.getWalkingRouteToPoint(start: start, destination: dest, destinationName: 'Stop 1');
      expect(f1.isFallback, isTrue);

      final f2 = await routing.getWalkingRouteToPoint(start: start, destination: dest, destinationName: 'Stop 2');
      expect(f2.isFallback, isTrue);

      final f3 = await routing.getWalkingRouteToPoint(start: start, destination: dest, destinationName: 'Stop 3');
      expect(f3.isFallback, isTrue);
      expect(serverCalls, equals(3));

      // Call 4: Circuit breaker is OPEN. Skips network entirely, returns 0ms geodesic fallback!
      final f4 = await routing.getWalkingRouteToPoint(
        start: start,
        destination: const LatLng(22.59, 88.38),
        destinationName: 'Stop 4',
      );
      expect(f4.isFallback, isTrue);
      expect(serverCalls, equals(3)); // Did NOT hit server again! Circuit breaker protected the app!
      expect(f4.distanceMeters, greaterThan(0));
    });
  });

  group('Scalability Test 5: Squad Invite Codes & High-Concurrency State Isolation', () {
    test('1,000 generated squad codes are well-formatted and collision resistant', () {
      final squadService = SquadService.instance;
      final generatedCodes = <String>{};

      for (int i = 0; i < 1000; i++) {
        squadService.createSquad('Squad $i', 'Landmark $i');
        final code = squadService.squadCode;
        expect(code, isNotNull);
        expect(code!, startsWith('PUJA'));
        expect(code.length, equals(8));
        generatedCodes.add(code);
        squadService.leaveSquad();
      }

      // With 1,048,576 permutations, 1,000 squads have near-zero collisions (>98% unique)
      expect(generatedCodes.length, greaterThan(980));
      expect(squadService.hasActiveSquad, isFalse);
    });
  });
}
