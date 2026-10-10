import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/models/metro_station.dart';
import 'package:kolkata_puja/models/navigation_step.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/repositories/railway_repository.dart';
import 'package:kolkata_puja/services/journey_planner.dart';
import 'package:kolkata_puja/services/journey_session.dart';
import 'package:kolkata_puja/services/multimodal_routing_service.dart'
    hide haversineMeters;
import 'package:kolkata_puja/services/routing_service.dart';
import 'package:kolkata_puja/services/transit_geometry.dart';
import 'package:kolkata_puja/utils/constants.dart';
import 'package:kolkata_puja/utils/haversine.dart';

MetroStation metro(
  String id,
  double longitude, [
  KolkataMetroLine line = KolkataMetroLine.blue,
]) => MetroStation(
  id: id,
  name: id,
  line: line,
  latitude: 22.6,
  longitude: longitude,
);
RailwayStationInfo train(String id, double longitude) => RailwayStationInfo(
  id: id,
  name: id,
  code: id,
  latitude: 22.6,
  longitude: longitude,
  corridorId: 'test',
  corridorName: 'Test suburban line',
);
Future<WalkingRoute> streets({
  required LatLng start,
  required LatLng destination,
  required String destinationName,
  Pandal? targetPandal,
}) async {
  final distance =
      haversineMeters(
        start.latitude,
        start.longitude,
        destination.latitude,
        destination.longitude,
      ) *
      1.2;
  return WalkingRoute(
    targetPandal: targetPandal,
    points: [
      start,
      LatLng(
        (start.latitude + destination.latitude) / 2,
        (start.longitude + destination.longitude) / 2,
      ),
      destination,
    ],
    distanceMeters: distance,
    durationSeconds: distance / 1.25,
    steps: [
      NavigationStep(
        instruction: 'Depart',
        pointIndex: 0,
        distanceMeters: distance,
        durationSeconds: distance / 1.25,
        type: 'depart',
      ),
      const NavigationStep(
        instruction: 'Arrive',
        pointIndex: 2,
        distanceMeters: 0,
        durationSeconds: 0,
        type: 'arrive',
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'metro keeps boarding station, both directions and station count',
    () async {
      final planner = JourneyPlanner(
        roadLoader: streets,
        trainLines: {},
        metroLines: {
          KolkataMetroLine.blue: [
            metro('a', 88.24),
            metro('b', 88.30),
            metro('c', 88.36),
          ],
        },
      );
      for (final reverse in [false, true]) {
        final route = await planner.plan(
          origin: LatLng(22.6, reverse ? 88.361 : 88.239),
          destination: LatLng(22.6, reverse ? 88.239 : 88.361),
          destinationName: 'Pandal',
        );
        final ride = route.metroLegs.single;
        expect(ride.entryStation.id, reverse ? 'c' : 'a');
        expect(ride.exitStation.id, reverse ? 'a' : 'c');
        expect(ride.stationCount, 2);
        expect(ride.instructions, contains('toward ${reverse ? 'a' : 'c'}'));
        expect(ride.trackPoints.first, ride.startPoint);
        expect(ride.trackPoints.last, ride.endPoint);
        expect(route.walkLegs.every((leg) => leg.steps.isNotEmpty), isTrue);
        for (var i = 1; i < route.legs.length; i++) {
          expect(route.legs[i].startPoint, route.legs[i - 1].endPoint);
        }
      }
    },
  );
  test(
    'line changes are explicit and preserve both service instructions',
    () async {
      final planner = JourneyPlanner(
        roadLoader: streets,
        trainLines: {},
        metroLines: {
          KolkataMetroLine.blue: [
            metro('a', 88.24),
            metro('interchange', 88.30),
          ],
          KolkataMetroLine.green: [
            metro('interchange', 88.30, KolkataMetroLine.green),
            metro('c', 88.36, KolkataMetroLine.green),
          ],
        },
      );
      final route = await planner.plan(
        origin: const LatLng(22.6, 88.239),
        destination: const LatLng(22.6, 88.361),
        destinationName: 'Pandal',
      );
      expect(route.metroLegs.map((r) => r.line), [
        KolkataMetroLine.blue,
        KolkataMetroLine.green,
      ]);
      expect(
        route.legs.whereType<WalkLeg>().any(
          (r) => r.instructions.startsWith('Transfer'),
        ),
        isTrue,
      );
    },
  );
  test('train and metro combine with routed pedestrian transfer', () async {
    final planner = JourneyPlanner(
      roadLoader: streets,
      trainLines: {
        'test': [train('r1', 88.24), train('r2', 88.30)],
      },
      metroLines: {
        KolkataMetroLine.blue: [metro('m1', 88.307), metro('m2', 88.36)],
      },
    );
    final route = await planner.plan(
      origin: const LatLng(22.6, 88.239),
      destination: const LatLng(22.6, 88.361),
      destinationName: 'Pandal',
    );
    expect(route.bestModeBadge, 'Train + Metro');
    expect(route.trainLegs.single.entryStation.code, 'r1');
    expect(route.metroLegs.single.entryStation.id, 'm1');
    final transfer = route.walkLegs.firstWhere(
      (r) => r.instructions.startsWith('Transfer'),
    );
    expect(transfer.steps, isNotEmpty);
    expect(transfer.points.length, 3);
  });
  test(
    'barrier between nearby stations rejects disconnected itinerary',
    () async {
      Future<WalkingRoute> road({
        required LatLng start,
        required LatLng destination,
        required String destinationName,
        Pandal? targetPandal,
      }) async {
        if (destinationName.startsWith('Transfer') ||
            destinationName == 'Walk to Pandal') {
          throw StateError('No pedestrian crossing');
        }
        return streets(
          start: start,
          destination: destination,
          destinationName: destinationName,
        );
      }

      final planner = JourneyPlanner(
        roadLoader: road,
        trainLines: {
          'test': [train('r1', 88.24), train('r2', 88.30)],
        },
        metroLines: {
          KolkataMetroLine.blue: [metro('m1', 88.3005), metro('m2', 88.36)],
        },
      );
      await expectLater(
        planner.plan(
          origin: const LatLng(22.6, 88.239),
          destination: const LatLng(22.6, 88.361),
          destinationName: 'Pandal',
        ),
        throwsStateError,
      );
    },
  );
  test(
    'street fallback cannot masquerade as connected walking route',
    () async {
      final planner = JourneyPlanner(
        metroLines: {},
        trainLines: {},
        roadLoader:
            ({
              required start,
              required destination,
              required destinationName,
              targetPandal,
            }) async => WalkingRoute(
              points: [start, destination],
              distanceMeters: 200,
              durationSeconds: 100,
              isFallback: true,
            ),
      );
      await expectLater(
        planner.plan(
          origin: const LatLng(22.6, 88.24),
          destination: const LatLng(22.6, 88.25),
          destinationName: 'Pandal',
        ),
        throwsStateError,
      );
    },
  );
  test('transit switches leave a complete real street itinerary', () async {
    final planner = JourneyPlanner(roadLoader: streets);
    final route = await planner.plan(
      origin: const LatLng(22.6, 88.24),
      destination: const LatLng(22.6, 88.36),
      destinationName: 'Pandal',
      allowMetro: false,
      allowTrain: false,
    );
    expect(route.legs.single, isA<WalkLeg>());
    expect(route.walkLegs.single.steps.last.type, 'arrive');
  });
  test(
    'mapped track geometry follows curves and reverses consistently',
    () async {
      final forward = await TransitGeometry.section(
        'rail:howrah_main',
        'HWH',
        'LLH',
      );
      final reverse = await TransitGeometry.section(
        'rail:howrah_main',
        'LLH',
        'HWH',
      );
      expect(forward, isNotNull);
      expect(forward!.length, greaterThan(5));
      expect(reverse, forward.reversed.toList());
    },
  );
  test(
    'journey visits a pandal only after its final walk and moves to next stop',
    () async {
      final planner = JourneyPlanner(
        roadLoader: streets,
        trainLines: {},
        metroLines: {
          KolkataMetroLine.blue: [metro('a', 88.24), metro('c', 88.36)],
        },
      );
      Pandal pandal(String id, double longitude) => Pandal(
        id: id,
        name: id,
        lat: 22.6,
        lng: longitude,
        zone: KolkataZone.northKolkata,
        theme: '',
        timings: '',
        imageUrl: '',
        description: '',
      );
      final first = pandal('first', 88.361), second = pandal('second', 88.363);
      final ride = await planner.plan(
        origin: const LatLng(22.6, 88.239),
        destination: LatLng(first.lat, first.lng),
        destinationName: first.name,
        targetPandal: first,
      );
      final walk = await planner.plan(
        origin: LatLng(first.lat, first.lng),
        destination: LatLng(second.lat, second.lng),
        destinationName: second.name,
        targetPandal: second,
      );
      final session = JourneySession()..load([first, second], [ride, walk]);
      expect(session.walkingRoute!.targetPandal, isNull);
      session.beginWalking();
      expect(session.advance(), isNull);
      expect(session.walking, isFalse);
      expect(session.leg, isA<MetroLeg>());
      expect(session.walkingRoute, isNull);
      expect(session.advance(), isNull);
      expect(session.walkingRoute!.targetPandal, first);
      expect(session.advance(), first);
      expect(session.target, second);
      expect(session.advance(), second);
      expect(session.active, isFalse);
      session.dispose();
    },
  );
}
