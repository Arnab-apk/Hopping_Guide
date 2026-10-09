import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../utils/haversine.dart';
import 'routing_service.dart';

/// Deterministic test/development input. Never replaces GPS in release builds.
class NavigationSimulator {
  NavigationSimulator(this.route);
  final WalkingRoute route;

  Position fixAt(
    double alongMeters,
    DateTime time, {
    double lateralMeters = 0,
    double accuracy = 8,
  }) {
    var remaining = alongMeters;
    var point = route.points.last;
    var heading = 0.0;
    for (var i = 0; i < route.points.length - 1; i++) {
      final a = route.points[i], b = route.points[i + 1];
      final length = haversineMeters(
        a.latitude,
        a.longitude,
        b.latitude,
        b.longitude,
      );
      if (remaining <= length || i == route.points.length - 2) {
        final t = length == 0 ? 0.0 : (remaining / length).clamp(0.0, 1.0);
        point = LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        );
        heading = calculateBearing(
          a.latitude,
          a.longitude,
          b.latitude,
          b.longitude,
        );
        break;
      }
      remaining -= length;
    }
    return Position(
      latitude: point.latitude + lateralMeters / 111320,
      longitude: point.longitude,
      timestamp: time,
      accuracy: accuracy,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: heading,
      headingAccuracy: 1,
      speed: 1.4,
      speedAccuracy: 0,
    );
  }
}
