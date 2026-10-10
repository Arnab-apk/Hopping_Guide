import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/pandal.dart';
import '../repositories/metro_repository.dart';
import '../repositories/railway_repository.dart';
import '../services/multimodal_routing_service.dart';
import 'leaflet_map_components.dart';

/// The same pins used by the browse map, anchored to the connected itinerary.
List<Marker> buildJourneyMarkers({
  required List<Pandal> stops,
  required Iterable<MultimodalRoute> routes,
  int currentStopIndex = 0,
  bool includeNearbyStations = true,
}) {
  final itinerary = routes.toList();
  final markers = <Marker>[];
  final stations = <String>{};
  void station(
    String id,
    String label,
    LatLng point,
    Color color, {
    bool railway = false,
  }) {
    if (!stations.add(id)) return;
    markers.add(
      Marker(
        key: ValueKey('journey_station_$id'),
        rotate: true,
        point: point,
        width: 34,
        height: 44,
        alignment: Alignment.topCenter,
        child: Tooltip(
          message: label,
          triggerMode: TooltipTriggerMode.tap,
          child: LeafletMarkerPin.metro(lineColor: color, isRailway: railway),
        ),
      ),
    );
  }

  for (final route in itinerary) {
    for (final leg in route.legs) {
      if (leg is MetroLeg) {
        final ordered = MetroRepository.getStationsForLine(leg.line);
        final from = ordered.indexWhere((s) => s.id == leg.entryStation.id);
        final to = ordered.indexWhere((s) => s.id == leg.exitStation.id);
        final served = from >= 0 && to >= 0
            ? ordered.sublist(
                from < to ? from : to,
                (from > to ? from : to) + 1,
              )
            : [leg.entryStation, leg.exitStation];
        for (final stop in served) {
          station(
            'metro:${stop.id}',
            'Metro: ${stop.name} — ${leg.line.label}',
            stop.toLatLng(),
            leg.line.color,
          );
        }
      } else if (leg is TrainLeg) {
        var served = [leg.entryStation, leg.exitStation];
        for (final corridor in RailwayRepository.instance.corridors.values) {
          final from = corridor.indexWhere(
            (s) => s.code == leg.entryStation.code,
          );
          final to = corridor.indexWhere((s) => s.code == leg.exitStation.code);
          if (from < 0 || to < 0) continue;
          final section = corridor.sublist(
            from < to ? from : to,
            (from > to ? from : to) + 1,
          );
          served = from <= to ? section : section.reversed.toList();
          break;
        }
        for (final stop in served) {
          station(
            'rail:${stop.code}',
            'Train: ${stop.name} — ${leg.corridorName}',
            stop.toLatLng(),
            Colors.deepPurple,
            railway: true,
          );
        }
      }
    }
  }
  // Context stations remain visible even when a short circuit is entirely on
  // foot or the fastest approach is by car. Route legs still determine guidance.
  final anchors = <LatLng>[
    for (final stop in stops) LatLng(stop.lat, stop.lng),
    for (final route in itinerary) ...route.allDisplayPoints,
  ];
  if (includeNearbyStations && anchors.isNotEmpty) {
    final bounds = LatLngBounds.fromPoints(anchors);
    bool nearby(LatLng point) =>
        point.latitude >= bounds.south - 0.015 &&
        point.latitude <= bounds.north + 0.015 &&
        point.longitude >= bounds.west - 0.015 &&
        point.longitude <= bounds.east + 0.015;
    for (final stop in MetroRepository.allStations) {
      if (!nearby(stop.toLatLng())) continue;
      station(
        'metro:${stop.id}',
        'Nearby metro: ${stop.name} — ${stop.line.label}',
        stop.toLatLng(),
        stop.line.color,
      );
    }
    for (final stop in RailwayRepository.instance.allStations) {
      if (!nearby(stop.toLatLng())) continue;
      station(
        'rail:${stop.code}',
        'Nearby train: ${stop.name} — ${stop.corridorName}',
        stop.toLatLng(),
        Colors.deepPurple,
        railway: true,
      );
    }
  }
  // Draw pandals above station pins so the next visit stays easy to select.
  for (var i = 0; i < stops.length; i++) {
    final stop = stops[i];
    final current = i == currentStopIndex;
    markers.add(
      Marker(
        rotate: true,
        point: LatLng(stop.lat, stop.lng),
        width: current ? 46 : 36,
        height: current ? 59 : 47,
        alignment: Alignment.topCenter,
        child: Tooltip(
          message: 'Stop ${i + 1}: ${stop.name}',
          triggerMode: TooltipTriggerMode.tap,
          child: LeafletMarkerPin.pandal(
            size: current ? 46 : 36,
            trailIndex: i,
            isCurrentTrailStop: current,
            isVisited: i < currentStopIndex,
          ),
        ),
      ),
    );
  }
  return markers;
}
