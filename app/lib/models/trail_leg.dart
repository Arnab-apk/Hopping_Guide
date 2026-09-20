import 'package:latlong2/latlong.dart';

import '../services/metro_transit_estimator.dart';
import '../utils/haversine.dart';

/// Transport mode used for a particular leg of a hopping trail.
enum LegMode { walk, metro }

/// Represents an individual leg between two consecutive stops or waypoints on a trail.
class TrailLeg {
  const TrailLeg({
    required this.from,
    required this.to,
    required this.mode,
    this.metroDetail,
  });

  final LatLng from;
  final LatLng to;
  final LegMode mode;
  final MetroLegEstimate? metroDetail;

  bool get isMetro => mode == LegMode.metro;
  bool get isWalk => mode == LegMode.walk;
}

/// Reconstructs the leg breakdown (walk vs metro) for an ordered sequence of points.
List<TrailLeg> buildLegBreakdown(
  List<LatLng> orderedPoints, {
  required bool allowMetro,
  required double walkingSpeedKmH,
  double circuityFactor = 1.25,
}) {
  final legs = <TrailLeg>[];
  if (orderedPoints.length < 2) return legs;

  final speedMPerMin = (walkingSpeedKmH * 1000.0) / 60.0;

  for (int i = 0; i < orderedPoints.length - 1; i++) {
    final a = orderedPoints[i];
    final b = orderedPoints[i + 1];
    final metro = allowMetro
        ? MetroTransitEstimator.estimate(a, b, walkingSpeedKmH: walkingSpeedKmH)
        : null;

    final walkDistM = haversineMeters(
          a.latitude,
          a.longitude,
          b.latitude,
          b.longitude,
        ) *
        circuityFactor;
    final walkMinutes = walkDistM / speedMPerMin;

    final bool useMetro = metro != null && metro.totalMinutes < walkMinutes;
    legs.add(
      TrailLeg(
        from: a,
        to: b,
        mode: useMetro ? LegMode.metro : LegMode.walk,
        metroDetail: useMetro ? metro : null,
      ),
    );
  }
  return legs;
}
