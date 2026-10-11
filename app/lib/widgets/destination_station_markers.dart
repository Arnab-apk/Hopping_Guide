import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/station.dart';
import '../utils/haversine.dart';
import 'leaflet_map_components.dart';

/// Bounded nearby context for a single destination, independent of travel mode.
/// These are nearby stations, not a claim that a train serves the road route.
List<Marker> buildDestinationStationMarkers({
  required LatLng origin,
  required LatLng destination,
  required List<Station> stations,
}) {
  final selected = <String, Station>{};
  for (final point in [origin, destination]) {
    for (final railway in [false, true]) {
      final nearby =
          stations
              .where((s) => railway ? s.isRail : s.isMetro)
              .map(
                (s) => (
                  station: s,
                  distance: haversineMeters(
                    point.latitude,
                    point.longitude,
                    s.lat,
                    s.lon,
                  ),
                ),
              )
              .where((s) => s.distance <= 5000)
              .toList()
            ..sort((a, b) => a.distance.compareTo(b.distance));
      for (final entry in nearby.take(2)) {
        selected[entry.station.id] = entry.station;
      }
    }
  }
  return [
    for (final station in selected.values)
      Marker(
        key: ValueKey('destination_station_${station.id}'),
        point: LatLng(station.lat, station.lon),
        rotate: true,
        width: 34,
        height: 44,
        alignment: Alignment.topCenter,
        child: Tooltip(
          message:
              'Nearby ${station.isRail ? 'train' : 'metro'}: ${station.displayName}',
          triggerMode: TooltipTriggerMode.tap,
          child: LeafletMarkerPin.metro(
            lineColor: station.isRail ? Colors.deepPurple : Colors.blue,
            isRailway: station.isRail,
          ),
        ),
      ),
  ];
}
