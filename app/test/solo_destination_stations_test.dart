import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:kolkata_puja/models/station.dart';
import 'package:kolkata_puja/widgets/destination_station_markers.dart';

void main() {
  const origin = LatLng(22.57, 88.35);
  Station station(String id, String kind, double lat) =>
      Station(id: id, name: id, kind: kind, lat: lat, lon: 88.35);

  test(
    'solo road destination shows both station types without a transit leg',
    () {
      final markers = buildDestinationStationMarkers(
        origin: origin,
        destination: origin,
        stations: [
          station('metro', 'metro', 22.571),
          station('rail', 'rail', 22.572),
          station('remote', 'rail', 23.5),
        ],
      );
      expect(markers, hasLength(2));
      expect(
        markers.map((m) => (m.child as Tooltip).message),
        containsAll(['Nearby metro: metro', 'Nearby train: rail']),
      );
      expect(markers.map((m) => m.key).toSet(), hasLength(2));
    },
  );

  test('pins are capped per endpoint and type, deduplicated and local', () {
    final markers = buildDestinationStationMarkers(
      origin: origin,
      destination: origin,
      stations: [
        for (final kind in ['metro', 'rail'])
          for (var i = 1; i <= 20; i++)
            station('$kind$i', kind, 22.57 + i / 1000),
      ],
    );
    expect(markers, hasLength(4));
    expect(
      markers.map((m) => m.key),
      contains(const ValueKey('destination_station_rail1')),
    );
    expect(
      buildDestinationStationMarkers(
        origin: const LatLng(0, 0),
        destination: const LatLng(0, 0),
        stations: [station('far', 'rail', 22.57)],
      ),
      isEmpty,
    );
  });
}
