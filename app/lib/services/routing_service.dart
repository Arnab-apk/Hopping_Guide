import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:simplify/simplify.dart';

import '../models/pandal.dart';
import '../utils/haversine.dart';

/// Douglas-Peucker polyline simplification (tolerance of ~5 meters / 0.00005 deg).
/// Reduces dense multi-thousand point route coordinates to a lightweight, visually
/// identical polyline that renders with high GPU performance.
List<LatLng> optimizeRoute(List<LatLng> rawOrsCoordinates, {double tolerance = 0.00005}) {
  if (rawOrsCoordinates.length <= 2) return rawOrsCoordinates;

  // Convert LatLng to Point for the simplifier (x = lng, y = lat)
  final points = rawOrsCoordinates
      .map((latLng) => Point<double>(latLng.longitude, latLng.latitude))
      .toList();

  // Douglas-Peucker simplification
  final simplified = simplify(points, tolerance: tolerance, highestQuality: true);

  return simplified.map((p) => LatLng(p.y, p.x)).toList();
}

/// Representation of an active walking path to a Pandal or Squad Member
class WalkingRoute {
  const WalkingRoute({
    this.targetPandal,
    this.customTitle,
    required this.points,
    required this.distanceMeters,
    required this.durationSeconds,
    this.drivingDurationSeconds,
    this.isFallback = false,
  });

  final Pandal? targetPandal;
  final String? customTitle;
  final List<LatLng> points;
  final double distanceMeters;
  final double durationSeconds;
  final double? drivingDurationSeconds;
  final bool isFallback;

  String get destinationTitle => targetPandal?.name ?? customTitle ?? 'Destination';

  String get formattedDistance {
    if (distanceMeters < 1000) {
      return '${distanceMeters.round()} m';
    } else {
      return '${(distanceMeters / 1000).toStringAsFixed(1)} km';
    }
  }

  bool get isTransitRecommended =>
      distanceMeters > 3500 && drivingDurationSeconds != null && drivingDurationSeconds! > 0;

  String? get formattedTransitDuration {
    if (drivingDurationSeconds == null || drivingDurationSeconds! <= 0) return null;
    return _formatTimeString((drivingDurationSeconds! / 60).round(), 'drive/transit');
  }

  /// Formatted duration with realistic walking pace (4.5 km/h).
  /// For long distances (> 3.5 km), displays both driving/transit and walk times.
  String get formattedDuration {
    final walkMins = (durationSeconds / 60).round();
    final walkStr = _formatTimeString(walkMins, 'walk');

    // If long distance (> 3.5 km) and driving/transit time is known, show both
    if (isTransitRecommended) {
      return '$formattedTransitDuration · $walkStr';
    }

    return walkStr;
  }

  static String _formatTimeString(int totalMinutes, String mode) {
    if (totalMinutes < 1) {
      return '< 1 min $mode';
    } else if (totalMinutes < 60) {
      return '$totalMinutes mins $mode';
    } else {
      final hours = totalMinutes ~/ 60;
      final remMins = totalMinutes % 60;
      if (remMins == 0) {
        return '${hours}h $mode';
      }
      return '${hours}h ${remMins}m $mode';
    }
  }
}

/// Service that computes walking paths between the user's location and pandals or squad members.
/// Utilizes the free OSRM foot routing engine with offline geodesic fallback.
class RoutingService {
  RoutingService({http.Client? client}) : _client = client ?? http.Client();

  static final RoutingService instance = RoutingService();
  final http.Client _client;

  /// High-concurrency route cache to eliminate redundant public API requests
  /// Max 200 entries with LRU eviction to prevent memory leak
  final Map<String, ({WalkingRoute route, DateTime timestamp})> _routeCache = {};
  static const int _maxCacheSize = 200;
  int _consecutiveFailures = 0;
  DateTime? _circuitBreakerUntil;

  /// Invalidate cached routes
  void clearRouteCache() => _routeCache.clear();

  /// Reset circuit breaker state for tests or manual retries
  void resetCircuitBreaker() {
    _consecutiveFailures = 0;
    _circuitBreakerUntil = null;
  }

  /// Auto-reset circuit breaker after cooldown period
  void _maybeResetCircuitBreaker() {
    if (_circuitBreakerUntil != null && DateTime.now().isAfter(_circuitBreakerUntil!)) {
      _consecutiveFailures = 0;
      _circuitBreakerUntil = null;
      debugPrint('[RoutingService] 🔄 Circuit breaker auto-reset after cooldown');
    }
  }

  void _recordFailure() {
    _consecutiveFailures++;
    // Trip circuit breaker after 3 consecutive failures to avoid
    // overloading public servers during high-concurrency festival peaks.
    if (_consecutiveFailures >= 3) {
      _circuitBreakerUntil = DateTime.now().add(const Duration(seconds: 20));
    }
  }

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

    // 1. High-concurrency spatial quantization cache check (~10m grid)
    final cacheKey =
        '${startLat.toStringAsFixed(4)},${startLng.toStringAsFixed(4)}->${destLat.toStringAsFixed(4)},${destLng.toStringAsFixed(4)}';

    final cached = _routeCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < const Duration(minutes: 15)) {
      return WalkingRoute(
        targetPandal: targetPandal ?? cached.route.targetPandal,
        customTitle: destinationName,
        points: cached.route.points,
        distanceMeters: cached.route.distanceMeters,
        durationSeconds: cached.route.durationSeconds,
        drivingDurationSeconds: cached.route.drivingDurationSeconds,
        isFallback: cached.route.isFallback,
      );
    }

    // 2. Circuit Breaker check: If public OSRM is rate-limiting or down, skip network
    final now = DateTime.now();
    _maybeResetCircuitBreaker();
    if (_circuitBreakerUntil != null && now.isBefore(_circuitBreakerUntil!)) {
      return _buildGeodesicFallback(
        start: start,
        startLat: startLat,
        startLng: startLng,
        destLat: destLat,
        destLng: destLng,
        destinationName: destinationName,
        targetPandal: targetPandal,
      );
    }

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/foot/$startLng,$startLat;$destLng,$destLat?overview=full&geometries=geojson',
    );

    try {
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': 'KolkataPujaParikrama/1.0 (Android; Kolkata Durga Puja Hopper)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route0 = routes[0] as Map<String, dynamic>;
          final geometry = route0['geometry'] as Map<String, dynamic>?;
          final coordinates = geometry?['coordinates'] as List?;
          final distance = (route0['distance'] as num?)?.toDouble() ?? 0.0;
          final rawDuration = (route0['duration'] as num?)?.toDouble() ?? 0.0;

          if (coordinates != null && coordinates.isNotEmpty) {
            final points = coordinates.map((coord) {
              final pair = coord as List;
              return LatLng(
                (pair[1] as num).toDouble(),
                (pair[0] as num).toDouble(),
              );
            }).toList();

            final optimizedPoints = optimizeRoute(points);

            // Calibrated human pedestrian walking speed: 4.5 km/h = 1.25 m/s
            final walkingDurationSeconds = distance > 0 ? (distance / 1.25) : 0.0;

            final route = WalkingRoute(
              targetPandal: targetPandal,
              customTitle: destinationName,
              points: optimizedPoints,
              distanceMeters: distance,
              durationSeconds: walkingDurationSeconds,
              drivingDurationSeconds: rawDuration > 0 ? rawDuration : null,
              isFallback: false,
            );

            // Save to LRU cache and reset circuit breaker
            _consecutiveFailures = 0;
            _circuitBreakerUntil = null;
            if (_routeCache.length >= _maxCacheSize) {
              // LRU eviction: remove oldest entry
              String? oldestKey;
              DateTime? oldestTime;
              for (final entry in _routeCache.entries) {
                if (oldestTime == null || entry.value.timestamp.isBefore(oldestTime)) {
                  oldestTime = entry.value.timestamp;
                  oldestKey = entry.key;
                }
              }
              if (oldestKey != null) {
                _routeCache.remove(oldestKey);
              }
            }
            _routeCache[cacheKey] = (route: route, timestamp: now);

            debugPrint('[RoutingService] ✅ Street route OK: ${optimizedPoints.length} pts, ${(distance/1000).toStringAsFixed(2)} km → $destinationName');
            return route;
          }
        }
      } else {
        debugPrint('[RoutingService] ❌ OSRM HTTP ${response.statusCode} for $destinationName');
        _recordFailure();
      }
    } catch (e) {
      // Server error, network timeout, or socket exception
      debugPrint('[RoutingService] ❌ Exception routing to $destinationName: $e');
      _recordFailure();
    }

    // Geodesic fallback
    return _buildGeodesicFallback(
      start: start,
      startLat: startLat,
      startLng: startLng,
      destLat: destLat,
      destLng: destLng,
      destinationName: destinationName,
      targetPandal: targetPandal,
    );
  }

  WalkingRoute _buildGeodesicFallback({
    required LatLng start,
    required double startLat,
    required double startLng,
    required double destLat,
    required double destLng,
    required String destinationName,
    Pandal? targetPandal,
  }) {
    final directMeters = haversineMeters(startLat, startLng, destLat, destLng);
    final estimatedStreetMeters = directMeters * 1.25;
    final walkingDurationSeconds = estimatedStreetMeters / 1.25;
    final estimatedDrivingSeconds = estimatedStreetMeters / 11.1; // ~40 km/h driving

    return WalkingRoute(
      targetPandal: targetPandal,
      customTitle: destinationName,
      points: [start, LatLng(destLat, destLng)],
      distanceMeters: estimatedStreetMeters,
      durationSeconds: walkingDurationSeconds,
      drivingDurationSeconds: estimatedDrivingSeconds,
      isFallback: true,
    );
  }

  /// Fetches a walking route through an ordered sequence of waypoints (e.g. for custom pandal hopping trails).
  /// Utilizes multi-stop OSRM pedestrian routing with Douglas-Peucker simplification,
  /// spatial caching, and offline geodesic fallback.
  Future<WalkingRoute> getMultiStopRoute({
    required List<LatLng> waypoints,
    String? routeTitle,
  }) async {
    if (waypoints.length < 2) {
      return WalkingRoute(
        customTitle: routeTitle ?? 'Trail',
        points: waypoints,
        distanceMeters: 0,
        durationSeconds: 0,
        isFallback: false,
      );
    }

    // 1. Spatial quantization cache check
    final cacheKey = waypoints
        .map((p) => '${p.latitude.toStringAsFixed(3)},${p.longitude.toStringAsFixed(3)}')
        .join(';');

    final cached = _routeCache[cacheKey];
    if (cached != null &&
        DateTime.now().difference(cached.timestamp) < const Duration(minutes: 15)) {
      return cached.route;
    }

    // 2. Circuit Breaker check
    final now = DateTime.now();
    if (_circuitBreakerUntil != null && now.isBefore(_circuitBreakerUntil!)) {
      return _buildMultiStopGeodesicFallback(waypoints, routeTitle);
    }

    // 3. Format OSRM coordinates: lon1,lat1;lon2,lat2;lon3,lat3...
    final coordsParam = waypoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');

    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/foot/$coordsParam?overview=full&geometries=geojson',
    );

    try {
      final response = await _client.get(
        url,
        headers: {
          'User-Agent': 'KolkataPujaParikrama/1.0 (Android; Kolkata Durga Puja Hopper)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final routes = data['routes'] as List?;
        if (routes != null && routes.isNotEmpty) {
          final route0 = routes[0] as Map<String, dynamic>;
          final geometry = route0['geometry'] as Map<String, dynamic>?;
          final coordinates = geometry?['coordinates'] as List?;
          final distance = (route0['distance'] as num?)?.toDouble() ?? 0.0;
          final rawDuration = (route0['duration'] as num?)?.toDouble() ?? 0.0;

          if (coordinates != null && coordinates.isNotEmpty) {
            final points = coordinates.map((coord) {
              final pair = coord as List;
              return LatLng(
                (pair[1] as num).toDouble(),
                (pair[0] as num).toDouble(),
              );
            }).toList();

            final optimizedPoints = optimizeRoute(points);

            // Calibrated pedestrian walking speed: 4.5 km/h = 1.25 m/s
            final walkingDurationSeconds = distance > 0 ? (distance / 1.25) : 0.0;

            final route = WalkingRoute(
              customTitle: routeTitle ?? 'Trail',
              points: optimizedPoints,
              distanceMeters: distance,
              durationSeconds: walkingDurationSeconds,
              drivingDurationSeconds: rawDuration > 0 ? rawDuration : null,
              isFallback: false,
            );

            _consecutiveFailures = 0;
            _circuitBreakerUntil = null;
            if (_routeCache.length >= 100) _routeCache.clear();
            _routeCache[cacheKey] = (route: route, timestamp: now);

            debugPrint('[RoutingService] ✅ Multi-stop route OK: ${optimizedPoints.length} pts, ${(distance/1000).toStringAsFixed(2)} km for ${waypoints.length} stops');
            return route;
          }
        }
      }
      debugPrint('[RoutingService] ❌ OSRM HTTP ${response.statusCode} for multi-stop route');
      _recordFailure();
    } catch (e) {
      debugPrint('[RoutingService] ❌ Exception for multi-stop route: $e');
      _recordFailure();
    }

    return _buildMultiStopGeodesicFallback(waypoints, routeTitle);
  }

  WalkingRoute _buildMultiStopGeodesicFallback(List<LatLng> waypoints, String? title) {
    double totalMeters = 0.0;
    for (int i = 0; i < waypoints.length - 1; i++) {
      totalMeters += haversineMeters(
        waypoints[i].latitude,
        waypoints[i].longitude,
        waypoints[i + 1].latitude,
        waypoints[i + 1].longitude,
      );
    }
    final estimatedStreetMeters = totalMeters * 1.25;
    final walkingDurationSeconds = estimatedStreetMeters / 1.25;
    final estimatedDrivingSeconds = estimatedStreetMeters / 11.1;

    return WalkingRoute(
      customTitle: title ?? 'Trail',
      points: waypoints,
      distanceMeters: estimatedStreetMeters,
      durationSeconds: walkingDurationSeconds,
      drivingDurationSeconds: estimatedDrivingSeconds,
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
