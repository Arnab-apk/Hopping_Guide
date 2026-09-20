import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/repositories/local_pandal_repository.dart';
import 'package:kolkata_puja/repositories/metro_repository.dart';
import 'package:kolkata_puja/repositories/supplementary_repository.dart';
import 'package:kolkata_puja/services/custom_hopping_trail_service.dart';
import 'package:kolkata_puja/services/omni_search_service.dart';
import 'package:kolkata_puja/services/pandal_user_state_service.dart';
import 'package:kolkata_puja/services/routing_service.dart';
import 'package:kolkata_puja/services/squad_service.dart';
import 'package:kolkata_puja/services/theme_service.dart';
import 'package:kolkata_puja/utils/constants.dart';
import 'package:kolkata_puja/utils/pandal_spatial_cluster.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Feature 1: Interactive Spatial Map & Pandal Dataset Integrity', () {
    test('Master dataset loads 338 verified authentic deduplicated pandals with valid coordinates', () async {
      final repo = LocalAssetPandalRepository();
      final pandals = await repo.all();

      expect(pandals.length, equals(338));

      for (final p in pandals) {
        // Must have non-empty ID and name
        expect(p.id.isNotEmpty, isTrue, reason: 'Pandal missing id: ${p.name}');
        expect(p.name.isNotEmpty, isTrue, reason: 'Pandal missing name: ${p.id}');

        // Must be in realistic Greater Kolkata / suburban coordinate box
        expect(p.lat, greaterThan(22.3), reason: 'Latitude too far south: ${p.name} (${p.lat})');
        expect(p.lat, lessThan(23.2), reason: 'Latitude too far north: ${p.name} (${p.lat})');
        expect(p.lng, greaterThan(88.1), reason: 'Longitude too far west: ${p.name} (${p.lng})');
        expect(p.lng, lessThan(88.7), reason: 'Longitude too far east: ${p.name} (${p.lng})');

        // Must have a valid zone assigned
        expect(KolkataZone.values.contains(p.zone), isTrue);

        // Must have theme and timings
        expect(p.theme.isNotEmpty, isTrue, reason: 'Pandal missing theme: ${p.name}');
        expect(p.timings.isNotEmpty, isTrue, reason: 'Pandal missing timings: ${p.name}');
      }
    });

    test('Spatial Clustering Engine isolates clusters and handles zoom thresholds', () async {
      final repo = LocalAssetPandalRepository();
      final pandals = await repo.all();

      // At overview zoom 11.0, count of clustered items must be significantly fewer than 387
      final bounds = LatLngBounds(const LatLng(22.4, 88.2), const LatLng(22.8, 88.6));
      final clusters = PandalSpatialClusterer.cluster(
        allPandals: pandals,
        zoom: 11.0,
        visibleBounds: bounds,
      );

      expect(clusters.length, lessThan(pandals.length));
      expect(clusters.any((c) => c.isCluster), isTrue);

      // Cache returns instantly for small pan
      final cached = PandalSpatialClusterer.cluster(
        allPandals: pandals,
        zoom: 11.0,
        visibleBounds: LatLngBounds(const LatLng(22.401, 88.201), const LatLng(22.801, 88.601)),
      );
      expect(identical(clusters, cached), isTrue);
    });
  });

  group('Feature 2: Kolkata Metro Transit Network Integrity', () {
    test('Metro network contains all 55 stations mapped across 5 operational lines', () {
      final stations = MetroRepository.allStations;
      expect(stations.length, equals(55));

      final lines = stations.map((s) => s.line).toSet();
      expect(lines.length, equals(5)); // Blue, Green, Purple, Orange, Yellow

      // Esplanade, Kavi Subhash, and Noapara are major interchange hubs
      final esplanade = stations.firstWhere((s) => s.name.contains('Esplanade'));
      expect(esplanade.isInterchange, isTrue);

      // Verify all stations have valid coordinates
      for (final stn in stations) {
        expect(stn.latitude, inInclusiveRange(22.4, 22.8));
        expect(stn.longitude, inInclusiveRange(88.25, 88.50));
      }
    });

    test('Metro search and nearest station lookup functions correctly', () {
      final shyambazarResults = MetroRepository.allStations.where(
        (s) => s.name.toLowerCase().contains('shyambazar'),
      ).toList();
      expect(shyambazarResults, isNotEmpty);
      expect(shyambazarResults.first.id, equals('shyambazar'));

      // Dakshineswar lookup
      final dakshineswar = MetroRepository.allStations.firstWhere(
        (s) => s.matchesId('dakshineswar'),
      );
      expect(dakshineswar.name, contains('Dakshineswar'));
    });
  });

  group('Feature 3: Culinary & Food Directory Integrity', () {
    test('All 66 food spots are curated with ratings, coordinates, and type info', () async {
      final repo = SupplementaryRepository();
      final spots = await repo.getFoodSpots();

      expect(spots.length, equals(66));

      for (final s in spots) {
        expect(s.id.isNotEmpty, isTrue);
        expect(s.name.isNotEmpty, isTrue);
        expect(s.lat, inInclusiveRange(22.40, 23.10));
        expect(s.lng, inInclusiveRange(88.20, 88.60));
        expect(s.rating, inInclusiveRange(3.5, 5.0));
        expect(s.type.isNotEmpty, isTrue);
      }
    });
  });

  group('Feature 4: Universal Omni-Search HUD Integrity', () {
    test('OmniSearch indexes across Pandals, Metro, and Food simultaneously', () async {
      final pandalRepo = LocalAssetPandalRepository();
      final suppRepo = SupplementaryRepository();

      final results = await Future.wait([
        pandalRepo.all(),
        suppRepo.getFoodSpots(),
      ]);

      final pandals = results[0] as List<Pandal>;
      final foodSpots = results[1] as List<FoodSpot>;
      final metroStations = MetroRepository.allStations;

      // Search across all
      final allResults = OmniSearchService.instance.search(
        query: 'Bagbazar',
        pandals: pandals,
        metroStations: metroStations,
        foodSpots: foodSpots,
      );
      expect(allResults.any((r) => r.type == OmniResultType.pandal), isTrue);

      // Metro search
      final metroResults = OmniSearchService.instance.search(
        query: 'Blue',
        category: OmniCategory.metro,
        pandals: pandals,
        metroStations: metroStations,
        foodSpots: foodSpots,
      );
      expect(metroResults, isNotEmpty);
      expect(metroResults.every((r) => r.type == OmniResultType.metro), isTrue);

      // Food search
      final foodResults = OmniSearchService.instance.search(
        query: 'Biryani',
        category: OmniCategory.food,
        pandals: pandals,
        metroStations: metroStations,
        foodSpots: foodSpots,
      );
      expect(foodResults, isNotEmpty);
      expect(foodResults.every((r) => r.type == OmniResultType.food), isTrue);
    });
  });

  group('Feature 5: Pedestrian Routing & Dual-Mode Transit ETAs', () {
    test('findNearestPandal locates geographically closest pandal correctly', () {
      final p1 = Pandal(
        id: 'p1',
        name: 'Nearby Pandal',
        lat: 22.5650,
        lng: 88.3520,
        zone: KolkataZone.centralKolkata,
        theme: 'T',
        timings: '24/7',
        imageUrl: '',
        description: '',
      );
      final p2 = Pandal(
        id: 'p2',
        name: 'Distant Pandal',
        lat: 22.6500,
        lng: 88.4500,
        zone: KolkataZone.northKolkata,
        theme: 'T',
        timings: '24/7',
        imageUrl: '',
        description: '',
      );

      final userLoc = const LatLng(22.5645, 88.3516);
      final nearest = RoutingService.instance.findNearestPandal(
        userPosition: userLoc,
        pandals: [p1, p2],
      );
      expect(nearest?.id, equals('p1'));
    });

    test('WalkingRoute formatting outputs human-readable units and transit recommendations', () {
      final shortRoute = WalkingRoute(
        customTitle: 'Nearby Temple',
        points: const [LatLng(22.56, 88.35), LatLng(22.565, 88.352)],
        distanceMeters: 1600,
        durationSeconds: 1280, // ~21 mins
      );
      expect(shortRoute.formattedDistance, '1.6 km');
      expect(shortRoute.formattedDuration, '21 mins walk');
      expect(shortRoute.isTransitRecommended, isFalse);

      final longRoute = WalkingRoute(
        customTitle: 'Far Pandal',
        points: const [LatLng(22.56, 88.35), LatLng(22.48, 88.38)],
        distanceMeters: 9200,
        durationSeconds: 7360,
        drivingDurationSeconds: 1800, // 30 mins
      );
      expect(longRoute.formattedDistance, '9.2 km');
      expect(longRoute.isTransitRecommended, isTrue);
      expect(longRoute.formattedTransitDuration, isNotNull);
    });
  });

  group('Feature 6: Curated Heritage Circuits & Trail Planner', () {
    test('All curated hopping circuit stop IDs resolve to valid master pandals', () async {
      final repo = LocalAssetPandalRepository();
      final pandals = await repo.all();
      final pandalMap = {for (final p in pandals) p.id: p};

      // The 5 Curated Routes
      final curatedRoutePandalIds = [
        // North Heritage Walk
        'hatibagan_sarbojanin', 'kasi_bose_lane', 'nalin_sarkar_street',
        'nabin_pally', 'kumortuli_park_sarbojanin', 'ahiritola', 'bagbazar_sarbajanin',
        // South Classics
        'ballygunge_cultural', 'ekdalia_evergreen', 'singhi_park',
        'maddox_square', 'deshapriya_park', 'tridhara',
        // South-West Themes
        'suruchi_sangha', 'chetla_agrani', 'mudiali_club',
        'shib_mandir', 'badamtala', 'behala_natun_dal',
        // Zamindar Bonedi Bari Trail
        'chatu_babu_latu_babus_thakur_bari', 'sovabazar_rajbari',
        'shimla_street', 'college_square', 'santosh_mitra_square',
        // Salt Lake VIP Marvels
        'sree_bhumi_sporting_club', 'lake_town_adibashi_brinda',
        'dum_dum_park_tarun_sangha', 'dum_dum_park_bharat_chakra',
        'fd_block_durga_puja',
      ];

      for (final id in curatedRoutePandalIds) {
        expect(pandalMap.containsKey(id), isTrue, reason: 'Curated route references missing pandal id: "$id"');
      }
    });

    test('CustomHoppingTrailService generates and manages trails', () {
      final trailService = CustomHoppingTrailService.instance;
      final p1 = Pandal(id: 'c1', name: 'Stop 1', lat: 22.5995, lng: 88.3712, zone: KolkataZone.northKolkata, theme: 'Sabeki', timings: 'Open', imageUrl: '', description: '', rating: 4.8);
      final p2 = Pandal(id: 'c2', name: 'Stop 2', lat: 22.5980, lng: 88.3735, zone: KolkataZone.northKolkata, theme: 'Sabeki', timings: 'Open', imageUrl: '', description: '', rating: 4.6);

      final trail = trailService.generateTrail(
        startPos: const LatLng(22.5995, 88.3712),
        startLabel: 'North Gate',
        style: HoppingStyle.heritage,
        timeBudgetMinutes: 90,
        transitMode: HoppingTransitMode.walking,
        allPandals: [p1, p2],
      );

      expect(trail.stops.isNotEmpty, isTrue);
      trailService.startTrail(trail);
      expect(trailService.hasActiveTrail, isTrue);

      trailService.endTrail();
      expect(trailService.hasActiveTrail, isFalse);
    });
  });

  group('Feature 7: Live Squad Tracking & Invite Code Generation', () {
    test('SquadService creates squad with PUJA### invite code and manages state', () async {
      final squadService = SquadService.instance;
      await squadService.leaveSquad();
      expect(squadService.hasActiveSquad, isFalse);

      await squadService.createSquad('Bagbazar Squad', 'Bagbazar Ghat Crossing');
      expect(squadService.hasActiveSquad, isTrue);
      expect(squadService.squadCode?.length, equals(8));
      expect(squadService.squadCode, startsWith('PUJA'));
      expect(squadService.meetupPointName, equals('Bagbazar Ghat Crossing'));

      await squadService.leaveSquad();
      expect(squadService.hasActiveSquad, isFalse);
    });
  });

  group('Feature 8: Emergency Lifeline & Public Safety Helplines', () {
    test('All Kolkata emergency services have valid telephone URI strings', () async {
      final repo = SupplementaryRepository();
      final helplines = await repo.getHelplines();

      expect(helplines, isNotEmpty);
      for (final h in helplines) {
        expect(h.label.isNotEmpty, isTrue);
        expect(h.number.isNotEmpty, isTrue);
        final uri = Uri.parse('tel:${h.number}');
        expect(uri.scheme, equals('tel'));
      }
    });
  });

  group('Feature 9: Theme & Aesthetics System', () {
    test('ThemeService defaults to Dark Mode and toggles properly', () async {
      SharedPreferences.setMockInitialValues({});
      final themeService = ThemeService();
      await themeService.init();

      expect(themeService.isDarkMode, isTrue);
      await themeService.toggleTheme();
      expect(themeService.isDarkMode, isFalse);
      await themeService.toggleTheme();
      expect(themeService.isDarkMode, isTrue);
    });
  });

  group('Feature 10: Offline Personal Tracker & Bookmark Persistence', () {
    test('PandalUserStateService manages favorites, visited progress, and counts', () async {
      SharedPreferences.setMockInitialValues({});
      final userState = await PandalUserStateService.create();

      expect(userState.isFavorite('pandal_1'), isFalse);
      expect(userState.isVisited('pandal_1'), isFalse);

      await userState.toggleFavorite('pandal_1');
      expect(userState.isFavorite('pandal_1'), isTrue);

      await userState.toggleVisited('pandal_1');
      expect(userState.isVisited('pandal_1'), isTrue);
      expect(userState.visitedCount, equals(1));

      await userState.toggleVisited('pandal_1');
      expect(userState.isVisited('pandal_1'), isFalse);
      expect(userState.visitedCount, equals(0));
    });
  });
}
