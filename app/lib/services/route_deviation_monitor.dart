import 'dart:math' as math;

import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../utils/haversine.dart';

/// Requires sustained, fresh GPS evidence before changing a route.
class RouteDeviationMonitor {
  DateTime? _lastFix, _firstOffRoute, _lastRequest;
  int _count = 0;

  void reset() {
    _lastFix = _firstOffRoute = _lastRequest = null;
    _count = 0;
  }

  bool update(
    Position fix,
    List<LatLng> points, {
    DateTime? now,
    double tolerance = 35,
  }) {
    final time = now ?? DateTime.now();
    if (points.length < 2 ||
        !fix.accuracy.isFinite ||
        fix.accuracy < 0 ||
        fix.accuracy > 35 ||
        !fix.latitude.isFinite ||
        !fix.longitude.isFinite ||
        time.difference(fix.timestamp).abs() > const Duration(seconds: 10) ||
        (_lastFix != null && !fix.timestamp.isAfter(_lastFix!))) {
      return false;
    }
    if (_lastFix != null &&
        fix.timestamp.difference(_lastFix!) > const Duration(seconds: 15)) {
      _firstOffRoute = null;
      _count = 0;
    }
    _lastFix = fix.timestamp;
    final distance = distanceToPath(
      LatLng(fix.latitude, fix.longitude),
      points,
    );
    if (distance <= math.max(tolerance, fix.accuracy * 2)) {
      _firstOffRoute = null;
      _count = 0;
      return false;
    }
    _firstOffRoute ??= fix.timestamp;
    _count++;
    if (_count < 3 ||
        fix.timestamp.difference(_firstOffRoute!) <
            const Duration(seconds: 5) ||
        (_lastRequest != null &&
            time.difference(_lastRequest!) < const Duration(seconds: 20))) {
      return false;
    }
    _lastRequest = time;
    _firstOffRoute = null;
    _count = 0;
    return true;
  }

  static double distanceToPath(LatLng p, List<LatLng> points) {
    var best = double.infinity;
    final scale = math.cos(p.latitude * math.pi / 180);
    for (var i = 1; i < points.length; i++) {
      final a = points[i - 1], b = points[i];
      final x = (b.longitude - a.longitude) * scale;
      final y = b.latitude - a.latitude;
      final length = x * x + y * y;
      final t = length == 0
          ? 0.0
          : (((p.longitude - a.longitude) * scale * x +
                        (p.latitude - a.latitude) * y) /
                    length)
                .clamp(0.0, 1.0);
      best = math.min(
        best,
        haversineMeters(
          p.latitude,
          p.longitude,
          a.latitude + t * y,
          a.longitude + t * (b.longitude - a.longitude),
        ),
      );
    }
    return best;
  }
}
