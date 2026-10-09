import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

import '../models/navigation_step.dart';
import '../utils/haversine.dart';
import 'routing_service.dart';

class RouteGuidance {
  const RouteGuidance({
    required this.step,
    required this.stepIndex,
    required this.distanceToTurnMeters,
    required this.remainingMeters,
    required this.remainingSeconds,
    required this.deviationMeters,
    this.snappedPoint,
    this.segmentIndex = 0,
    this.arrived = false,
  });
  final NavigationStep step;
  final int stepIndex;
  final double distanceToTurnMeters;
  final double remainingMeters;
  final int remainingSeconds;
  final double deviationMeters;
  final LatLng? snappedPoint;
  final int segmentIndex;
  final bool arrived;

  static RouteGuidance? at(
    WalkingRoute route,
    LatLng position, {
    int? segmentHint,
  }) {
    if (route.isFallback ||
        !route.isWalk ||
        route.steps.isEmpty ||
        route.points.length < 2) {
      return null;
    }
    final cumulative = <double>[0];
    var bestDistance = double.infinity, along = 0.0;
    var bestPoint = route.points.first;
    var bestSegment = 0;
    final longitudeScale = math.cos(position.latitude * math.pi / 180);
    for (var i = 0; i < route.points.length - 1; i++) {
      final a = route.points[i], b = route.points[i + 1];
      final length = haversineMeters(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
      cumulative.add(cumulative.last + length);
    }
    void scan(int lo, int hi) {
      for (var i = lo; i < hi; i++) {
        final a = route.points[i], b = route.points[i + 1];
        final length = cumulative[i + 1] - cumulative[i];
        final ax = (a.longitude - position.longitude) * longitudeScale;
        final ay = a.latitude - position.latitude;
        final bx = (b.longitude - a.longitude) * longitudeScale;
        final by = b.latitude - a.latitude;
        final denominator = bx * bx + by * by;
        final t = denominator == 0
            ? 0.0
            : (-(ax * bx + ay * by) / denominator).clamp(0.0, 1.0);
        final projection = LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        );
        final deviation = haversineMeters(
          position.latitude,
          position.longitude,
          projection.latitude,
          projection.longitude,
        );
        if (deviation < bestDistance) {
          bestDistance = deviation;
          along = cumulative[i] + length * t;
          bestPoint = projection;
          bestSegment = i;
        }
      }
    }

    final last = route.points.length - 1;
    if (segmentHint == null) {
      scan(0, last);
    } else {
      scan(math.max(0, segmentHint - 5), math.min(last, segmentHint + 60));
      if (bestDistance > 60) {
        bestDistance = double.infinity;
        scan(0, last);
      }
    }
    final end = route.points.last;
    final arrived =
        cumulative.last - along <= 20 &&
        haversineMeters(
              position.latitude,
              position.longitude,
              end.latitude,
              end.longitude,
            ) <=
            20;
    var next = route.steps.length - 1;
    for (var i = 1; i < route.steps.length; i++) {
      final index = route.steps[i].pointIndex.clamp(0, cumulative.length - 1);
      if (cumulative[index] >= along - 2) {
        next = i;
        break;
      }
    }
    final remaining = math.max(0.0, cumulative.last - along);
    if (along < 20 && route.steps.first.type == 'depart') next = 0;
    return RouteGuidance(
      step: route.steps[next],
      stepIndex: next,
      distanceToTurnMeters: math.max(
        0.0,
        cumulative[route.steps[next].pointIndex.clamp(
              0,
              cumulative.length - 1,
            )] -
            along,
      ),
      remainingMeters: remaining,
      remainingSeconds: cumulative.last > 0
          ? (route.durationSeconds * remaining / cumulative.last).round()
          : 0,
      deviationMeters: bestDistance,
      snappedPoint: bestPoint,
      segmentIndex: bestSegment,
      arrived: arrived,
    );
  }
}
