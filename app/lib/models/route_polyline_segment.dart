import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import 'metro_station.dart';

/// A typed section of the route displayed on the map.
class RoutePolylineSegment {
  const RoutePolylineSegment({
    required this.points,
    required this.type,
    required this.color,
    this.line,
    this.isFallback = false,
  });

  final List<LatLng> points;
  final RouteSegmentType type;
  final Color color;
  final KolkataMetroLine? line;
  final bool isFallback;
}

enum RouteSegmentType { walk, metro, train }
