import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/pandal.dart';
import '../utils/haversine.dart';

/// Representation of an active walking path to a Pandal or Squad Member
class WalkingRoute {
  const WalkingRoute({
    this.targetPandal,
    this.customTitle,
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.isFallback = false,
  });

  final Pandal? targetPandal;
  final String? customTitle;
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final bool isFallback;

  String get destinationTitle => targetPandal?.name ?? customTitle ?? 'Destination';

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  String get formattedDuration {
    final mins = (durationSeconds / 60).round();
    if (mins < 1) {
      return '< 1 min walk';
    } else if (mins < 60) {
      return '$mins mins walk';
    } else {
      final hours = mins ~/ 60;
      final remMins = mins % 60;
      return '${hours}h ${remMins}m walk';
    }
  }
}

/// Service that computes walking paths between the user's location and pandals or squad members.
/// Utilizes the free OSRM foot routing engine with offline geodesic fallback.
class RoutingService {
  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  static final RoutingService instance = RoutingService();
  final http.Client _client;

  /// Fetches a real street walking route or computes direct walking corridor to a Pandal
  Future<WalkingRoute> getWalkingRoute({
    required LatLng start,
    required Pandal destination,
  }) async {
    return getWalkingRouteToPoint(
      start: start,
      destination: LatLng(destination.lat, destination.lng),
      destinationName: destination.name,
      targetPandal: destination,
    );
  }

  /// Fetches a walking route between any two LatLng coordinates (e.g. to a squad member)
  Future<WalkingRoute> getWalkingRouteToPoint({
    required LatLng start,
    required LatLng destination,
    required String destinationName,
    Pandal? targetPandal,
  }) async {
    final startLng = start.longitude;
    final startLat = start.latitude;
    final destLng = destination.longitude;
    final destLat = destination.latitude;

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/foot/$startLng,$startLat;$destLng,$destLat?overview=full&geometries=geojson',
    );

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route0 = routes[0] as Map<String, dynamic>;
          final geometry = route0['geometry'] as Map<String, dynamic>?;
          final coordinates = geometry?['coordinates'] as List?;
          final distance = (route0['distance'] as num?)?.toDouble() ?? 0.0;
          final duration = (route0['duration'] as num?)?.toDouble() ?? 0.0;

          if (coordinates != null && coordinates.isNotEmpty) {
            final points = coordinates.map((coord) {
              final pair = coord as List;
              return LatLng(
                (pair[1] as num).toDouble(),
                (pair[0] as num).toDouble(),
              );
            }).toList();

            return WalkingRoute(
              targetPandal: targetPandal,
              customTitle: destinationName,
              points: points,
              distanceMeters: distance,
              durationSeconds: duration,
              isFallback: false,
            );
          }
        }
      }
    } catch (_) {
      // Graceful fallback below
    }

    // Geodesic fallback (average pedestrian speed = 4.8 km/h or 1.33 m/s)
    final directMeters = haversineMeters(startLat, startLng, destLat, destLng);
    final walkingDurationSeconds = directMeters / 1.33;

    return WalkingRoute(
      targetPandal: targetPandal,
      customTitle: destinationName,
      points: [start, LatLng(destLat, destLng)],
      distanceMeters: directMeters,
      durationSeconds: walkingDurationSeconds,
      isFallback: true,
    );
  }

  /// Helper to find the closest pandal from a given coordinate
  Pandal? findNearestPandal({
    required LatLng userPosition,
    required List<Pandal> pandals,
  }) {
    if (pandals.isEmpty) return null;

    Pandal? closest;
    double minDistance = double.infinity;

    for (final p in pandals) {
      final dist = haversineMeters(
        userPosition.latitude,
        userPosition.longitude,
        p.lat,
        p.lng,
      );
      if (dist < minDistance) {
        minDistance = dist;
        closest = p;
      }
    }

    return closest;
  }
}
