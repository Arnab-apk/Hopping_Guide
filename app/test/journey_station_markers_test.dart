import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/models/metro_station.dart';
import 'package:kolkata_puja/models/pandal.dart';
import 'package:kolkata_puja/repositories/metro_repository.dart';
import 'package:kolkata_puja/repositories/railway_repository.dart';
import 'package:kolkata_puja/services/multimodal_routing_service.dart';
import 'package:kolkata_puja/widgets/journey_map_markers.dart';

MultimodalRoute itinerary(List<RouteLeg> legs) => MultimodalRoute(
  legs: legs,
  totalDistanceMeters: 1000,
  totalDurationSeconds: 800,
  summary: 'Test trail',
);

void main() {
  final stop = Pandal.fromMap('central_stop', {
    'name': 'Central stop',
    'lat': 22.5697,
    'lng': 88.3533,
    'theme': 'Traditional',
  });
  const start = LatLng(22.57, 88.354);
  const end = LatLng(22.5697, 88.3533);
  for (final driving in [false, true]) {
    test(
      'unrelated station pins are hidden on ${driving ? 'car' : 'walking'} trails',
      () {
        final leg = driving
            ? DriveLeg(
                startPoint: start,
                endPoint: end,
                distanceMeters: 100,
                durationSeconds: 60,
                instructions: 'Drive',
                points: [start, end],
                steps: const [],
              )
            : WalkLeg(
                startPoint: start,
                endPoint: end,
                distanceMeters: 100,
                durationSeconds: 90,
                instructions: 'Walk',
                points: [start, end],
                steps: const [],
              );
        final markers = buildJourneyMarkers(
          stops: [stop],
          routes: [
            itinerary([leg]),
          ],
        );
        final labels = markers
            .map((m) => (m.child as Tooltip).message!)
            .toList();
        expect(markers, hasLength(1));
        expect(labels.where((label) => label.startsWith('Stop ')), [
          'Stop 1: Central stop',
        ]);
        expect(labels.any((label) => label.contains('Dakshineswar')), isFalse);
        expect((markers.last.child as Tooltip).message, 'Stop 1: Central stop');
      },
    );
  }

  test(
    'metro route pins include intermediate stations once across repeated legs',
    () {
      final stations = MetroRepository.getStationsForLine(KolkataMetroLine.blue)
          .take(4)
          .toList();
      final leg = MetroLeg(
        startPoint: stations.first.toLatLng(),
        endPoint: stations.last.toLatLng(),
        distanceMeters: 5000,
        durationSeconds: 900,
        instructions: 'Ride metro',
        entryStation: stations.first,
        exitStation: stations.last,
        line: KolkataMetroLine.blue,
        stationCount: 3,
      );
      final markers = buildJourneyMarkers(
        stops: [],
        routes: [
          itinerary([leg, leg]),
        ],
      );
      expect(markers.length, 4);
      expect(markers.map((marker) => marker.key).toSet().length, 4);
      for (final station in stations) {
        expect(
          markers.any(
            (marker) =>
                marker.key == ValueKey('journey_station_metro:${station.id}'),
          ),
          isTrue,
        );
      }
    },
  );

  test('train route pins include intermediate stations in either direction and deduplicate', () {
    final stations = RailwayRepository.howrahMainStations.take(5).toList();
    TrainLeg leg(bool reverse) => TrainLeg(
      startPoint: (reverse ? stations.last : stations.first).toLatLng(),
      endPoint: (reverse ? stations.first : stations.last).toLatLng(),
      distanceMeters: 5000,
      durationSeconds: 1000,
      instructions: 'Ride train',
      entryStation: reverse ? stations.last : stations.first,
      exitStation: reverse ? stations.first : stations.last,
      corridorName: stations.first.corridorName,
      stationCount: 4,
    );
    final markers = buildJourneyMarkers(
      stops: [],
      routes: [
        itinerary([leg(false), leg(true)]),
      ],
    );
    expect(markers.length, 5);
    expect(markers.map((marker) => marker.key).toSet().length, 5);
    for (final station in stations) {
      expect(
        markers.any(
          (marker) =>
              marker.key == ValueKey('journey_station_rail:${station.code}'),
        ),
        isTrue,
      );
    }
  });
}
