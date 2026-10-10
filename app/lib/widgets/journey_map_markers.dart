import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/pandal.dart';
import '../repositories/metro_repository.dart';
import '../services/multimodal_routing_service.dart';
import 'leaflet_map_components.dart';

/// The same pins used by the browse map, anchored to the connected itinerary.
List<Marker> buildJourneyMarkers({
  required List<Pandal> stops,
  required Iterable<MultimodalRoute> routes,
  int currentStopIndex = 0,
}) {
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

  for (final route in routes) {
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
        for (final stop in [leg.entryStation, leg.exitStation]) {
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
