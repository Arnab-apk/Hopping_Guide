import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/models/station.dart';
import 'package:kolkata_puja/repositories/station_repository.dart';
import 'package:kolkata_puja/utils/haversine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Station Model Tests', () {
    test('Station.fromFeature parses valid GeoJSON feature', () {
      final feature = {
        'type': 'Feature',
        'id': 'stn_seed_hwh',
        'geometry': {
          'type': 'Point',
          'coordinates': [88.3426, 22.5839],
        },
        'properties': {
          'id': 'stn_seed_hwh',
          'name': 'Howrah Junction',
          'name_bn': 'হাওড়া জংশন',
          'code': 'HWH',
          'kind': 'rail',
          'operator': 'Eastern Railway / South Eastern Railway',
          'network': 'Indian Railways',
          'lines': ['Howrah Main Line', 'Howrah-Bardhaman Chord'],
          'entrances': [],
        },
      };

      final stn = Station.fromFeature(feature);

      expect(stn.id, equals('stn_seed_hwh'));
      expect(stn.name, equals('Howrah Junction'));
      expect(stn.nameBn, equals('হাওড়া জংশন'));
      expect(stn.code, equals('HWH'));
      expect(stn.kind, equals('rail'));
      expect(stn.isRail, isTrue);
      expect(stn.isMetro, isFalse);
      expect(stn.lat, closeTo(22.5839, 0.0001));
      expect(stn.lon, closeTo(88.3426, 0.0001));
      expect(stn.displayName, equals('Howrah Junction (HWH)'));
      expect(stn.fullDisplayName, contains('হাওড়া জংশন'));
      expect(stn.lines.length, equals(2));
    });

    test('Station.toFeature serializes back correctly', () {
      const stn = Station(
        id: 'stn_123',
        name: 'Dum Dum Junction',
        nameBn: 'দমদম জংশন',
        code: 'DDJ',
        kind: 'rail',
        lat: 22.6219,
        lon: 88.3934,
        network: 'Eastern Railway',
      );

      final feature = stn.toFeature();
      expect(feature['type'], equals('Feature'));
      expect(feature['id'], equals('stn_123'));
      final props = feature['properties'] as Map<String, dynamic>;
      expect(props['name'], equals('Dum Dum Junction'));
      expect(props['code'], equals('DDJ'));
      final geom = feature['geometry'] as Map<String, dynamic>;
      expect(geom['coordinates'], equals([88.3934, 22.6219]));
    });

    test('NearestStationInfo serialization and deserialization', () {
      final map = {
        'id': 'stn_seed_sdah',
        'name': 'Sealdah',
        'name_bn': 'শিয়ালদহ',
        'code': 'SDAH',
        'kind': 'rail',
        'distance_m': 650,
      };

      final info = NearestStationInfo.fromMap(map);
      expect(info.id, equals('stn_seed_sdah'));
      expect(info.name, equals('Sealdah'));
      expect(info.nameBn, equals('শিয়ালদহ'));
      expect(info.code, equals('SDAH'));
      expect(info.distanceM, equals(650));
      expect(info.isRail, isTrue);
      expect(info.isMetro, isFalse);

      final serialized = info.toMap();
      expect(serialized['distance_m'], equals(650));
      expect(serialized['code'], equals('SDAH'));
    });
  });

  group('Pandal Nearest Stations Integration Tests', () {
    test('Pandal parses precomputed nearest_stations from JSON', () {
      final json = {
        'name': 'College Square',
        'zone': 'North Kolkata',
        'lat': 22.5744,
        'lng': 88.3629,
        'nearest_stations': [
          {
            'id': 'stn_seed_sdah',
            'name': 'Sealdah',
            'name_bn': 'শিয়ালদহ',
            'code': 'SDAH',
            'kind': 'rail',
            'distance_m': 920,
          },
          {
            'id': 'stn_mg_road',
            'name': 'Mahatma Gandhi Road Metro',
            'kind': 'metro',
            'distance_m': 450,
          },
        ],
      };

      final pandal = Pandal.fromMap('pandal_test_1', json);
      expect(pandal.nearestStations, isNotEmpty);
      expect(pandal.nearestStations.length, equals(2));
      expect(pandal.nearestStations.first.name, equals('Sealdah'));
      expect(pandal.nearestStations.first.distanceM, equals(920));
      expect(pandal.nearestStations[1].isMetro, isTrue);

      final serialized = pandal.toFirestore();
      expect(serialized['nearest_stations'], isA<List>());
      expect((serialized['nearest_stations'] as List).length, equals(2));
    });
  });

  group('StationRepository Integration Tests', () {
    test('StationRepository loads bundled GeoJSON asset', () async {
      final repo = StationRepository.instance;
      await repo.load();

      expect(repo.isLoaded, isTrue);
      expect(repo.all.length, greaterThanOrEqualTo(200));

      final railList = repo.railStations;
      final metroList = repo.metroStations;
      expect(railList, isNotEmpty);
      expect(metroList, isNotEmpty);
      expect(railList.length + metroList.length, equals(repo.all.length));
    });

    test('StationRepository search works for name, IR code, and Bengali name', () async {
      final repo = StationRepository.instance;
      await repo.load();

      // Search by English name
      final howrah = repo.search('Howrah Junction');
      expect(howrah, isNotEmpty);
      expect(howrah.any((s) => s.code == 'HWH'), isTrue);

      // Search by IR Station Code
      final sdah = repo.search('SDAH');
      expect(sdah, isNotEmpty);
      expect(sdah.first.name, contains('Sealdah'));

      // Search by Bengali name
      final bnSearch = repo.search('হাওড়া');
      expect(bnSearch, isNotEmpty);

      // Search by Chitpur
      final koaa = repo.search('KOAA');
      expect(koaa, isNotEmpty);
      expect(koaa.first.name, contains('Kolkata'));
    });

    test('StationRepository getNearest returns sorted stations by proximity', () async {
      final repo = StationRepository.instance;
      await repo.load();

      // Coordinates at College Street / Central Kolkata
      final nearest = repo.getNearest(const LatLng(22.5744, 88.3629), limit: 5);

      expect(nearest.length, equals(5));
      // Distances should be in ascending order
      for (int i = 0; i < nearest.length - 1; i++) {
        final d1 = haversineMeters(22.5744, 88.3629, nearest[i].lat, nearest[i].lon);
        final d2 = haversineMeters(22.5744, 88.3629, nearest[i + 1].lat, nearest[i + 1].lon);
        expect(d1, lessThanOrEqualTo(d2));
      }
    });

    test('StationRepository findById and findByCode', () async {
      final repo = StationRepository.instance;
      await repo.load();

      final hwh = repo.findByCode('HWH');
      expect(hwh, isNotNull);
      expect(hwh!.name, contains('Howrah'));

      final byId = repo.findById(hwh.id);
      expect(byId, isNotNull);
      expect(byId!.code, equals('HWH'));
    });
  });
}
