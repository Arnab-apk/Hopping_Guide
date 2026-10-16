import 'package:flutter_test/flutter_test.dart';
import 'package:kolkata_puja/models/metro_station.dart';
import 'package:kolkata_puja/services/multimodal_routing_service.dart';
import 'package:kolkata_puja/services/return_home_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

const point = LatLng(22.5, 88.3);
MetroStation station(String id) => MetroStation(
  id: id,
  name: id,
  line: KolkataMetroLine.blue,
  latitude: 22.5,
  longitude: 88.3,
);
WalkLeg walk(int minutes) => WalkLeg(
  startPoint: point,
  endPoint: point,
  distanceMeters: 100,
  durationSeconds: minutes * 60,
  instructions: 'Walk',
  points: const [point, point],
);
MetroLeg ride(String from, String to) => MetroLeg(
  startPoint: point,
  endPoint: point,
  distanceMeters: 2000,
  durationSeconds: 600,
  instructions: '$from to $to',
  entryStation: station(from),
  exitStation: station(to),
  line: KolkataMetroLine.blue,
  stationCount: 2,
);
MultimodalRoute route(List<RouteLeg> legs) => MultimodalRoute(
  legs: legs,
  totalDistanceMeters: 3000,
  totalDurationSeconds: 2000,
  summary: 'Return',
);
Map<String, dynamic> record(
  String from,
  String to,
  String departure,
  String arrival,
) => {
  'service': 'metro:blue',
  'from': from,
  'to': to,
  'service_date': '2026-10-16',
  'departure': departure,
  'arrival': arrival,
  'verified_at': '2026-10-15T10:00:00+05:30',
  'valid_until': '2026-10-17T06:00:00+05:30',
  'source_url': 'https://mtp.indianrailways.gov.in/notice.pdf',
};
final now = DateTime.parse('2026-10-16T18:00:00+05:30');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'backwards planning includes transfer walk and buffer at each boarding',
    () {
      final runs = [
        VerifiedTransitRun.fromJson(
          record(
            'A',
            'B',
            '2026-10-16T23:00:00+05:30',
            '2026-10-16T23:20:00+05:30',
          ),
        ),
        VerifiedTransitRun.fromJson(
          record(
            'A',
            'B',
            '2026-10-16T23:20:00+05:30',
            '2026-10-16T23:40:00+05:30',
          ),
        ),
        VerifiedTransitRun.fromJson(
          record(
            'C',
            'D',
            '2026-10-17T00:00:00+05:30',
            '2026-10-17T00:30:00+05:30',
          ),
        ),
      ];
      final result = ReturnHomeService.check(
        route: route([
          walk(10),
          ride('A', 'B'),
          walk(10),
          ride('C', 'D'),
          walk(5),
        ]),
        timetable: runs,
        serviceDate: '2026-10-16',
        now: now,
      );
      expect(result.leaveBy, DateTime.parse('2026-10-16T22:30:00+05:30'));
      expect(result.runs.first.departure, runs.first.departure);
      expect(result.reason, isNull);
    },
  );
  test('missing transfer coverage never produces a partial leave-by claim', () {
    final result = ReturnHomeService.check(
      route: route([ride('A', 'B'), ride('C', 'D')]),
      timetable: [
        VerifiedTransitRun.fromJson(
          record(
            'C',
            'D',
            '2026-10-16T23:00:00+05:30',
            '2026-10-16T23:30:00+05:30',
          ),
        ),
      ],
      serviceDate: '2026-10-16',
      now: now,
    );
    expect(result.leaveBy, isNull);
    expect(result.runs, isEmpty);
  });
  test('rejects reverse direction, wrong operating date, expired and future verification', () {
    final base = record(
      'A',
      'B',
      '2026-10-16T23:00:00+05:30',
      '2026-10-16T23:30:00+05:30',
    );
    for (final data in [
      {...base, 'from': 'B', 'to': 'A'},
      {...base, 'service_date': '2026-10-15'},
      {...base, 'valid_until': '2026-10-16T23:00:00+05:30'},
      {...base, 'verified_at': '2026-10-16T22:00:00+05:30'},
    ]) {
      final expired = data['valid_until'] == '2026-10-16T23:00:00+05:30';
      final result = ReturnHomeService.check(
        route: route([ride('A', 'B')]),
        timetable: [VerifiedTransitRun.fromJson(data)],
        serviceDate: '2026-10-16',
        now: expired ? DateTime.parse('2026-10-17T01:00:00+05:30') : now,
      );
      expect(result.leaveBy, isNull);
    }
  });
  test('explicitly flags a missed leave-by time', () {
    final result = ReturnHomeService.check(
      route: route([walk(10), ride('A', 'B')]),
      timetable: [
        VerifiedTransitRun.fromJson(
          record(
            'A',
            'B',
            '2026-10-16T23:00:00+05:30',
            '2026-10-16T23:30:00+05:30',
          ),
        ),
      ],
      serviceDate: '2026-10-16',
      now: DateTime.parse('2026-10-16T22:45:00+05:30'),
    );
    expect(result.reason, contains('has passed'));
  });
  test('requires official source, timezone and valid arrival order', () {
    final base = record(
      'A',
      'B',
      '2026-10-16T23:00:00+05:30',
      '2026-10-16T23:30:00+05:30',
    );
    for (final data in [
      {
        ...base,
        'source_url': 'https://indianrailways.gov.in.example.org/times',
      },
      {...base, 'departure': '2026-10-16T23:00:00'},
      {...base, 'arrival': '2026-10-16T22:00:00+05:30'},
    ]) {
      expect(() => VerifiedTransitRun.fromJson(data), throwsFormatException);
    }
  });
  test('walking only needs no timetable and cannot promise a last train', () {
    final result = ReturnHomeService.check(
      route: route([walk(20)]),
      timetable: [],
      serviceDate: '2026-10-16',
      now: now,
    );
    expect(result.leaveBy, isNull);
    expect(result.reason, contains('no public transport'));
  });
  test('saves return station and buffer across sessions', () async {
    SharedPreferences.setMockInitialValues({});
    await ReturnHomeService.save('station-a', 25);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ReturnHomeService.homeKey), 'station-a');
    expect(prefs.getInt(ReturnHomeService.bufferKey), 25);
  });
}
