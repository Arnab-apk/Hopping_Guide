import 'dart:math' as math;
import 'package:latlong2/latlong.dart';

import '../models/metro_station.dart';
import '../models/pandal.dart';
import '../repositories/supplementary_repository.dart';

/// Represents a matched point of interest within an active walking corridor.
class CorridorMatch<T> {
  final T item;
  final double distanceToCorridorMeters;
  final int estimatedDetourMinutes;

  CorridorMatch({
    required this.item,
    required this.distanceToCorridorMeters,
    required this.estimatedDetourMinutes,
  });
}

/// Core spatial corridor engine for vector distance calculations along polylines.
class SpatialCorridor {
  static const double _earthRadiusM = 6371000.0;
  // 4.5 km/h human walk speed = 1.25 m/s. Factored by 1.25 urban street circuity.
  static const double _effectiveWalkingSpeedMps = 1.25 / 1.25; // 1.0 m/s

  /// Calculates perpendicular distance from Point P to segment AB in meters.
  static double distanceToSegment(LatLng p, LatLng a, LatLng b) {
    final double x = _degToRad(p.longitude - a.longitude) *
        math.cos(_degToRad((a.latitude + p.latitude) / 2.0));
    final double y = _degToRad(p.latitude - a.latitude);

    final double dx = _degToRad(b.longitude - a.longitude) *
        math.cos(_degToRad((a.latitude + b.latitude) / 2.0));
    final double dy = _degToRad(b.latitude - a.latitude);

    final double segmentLenSq = dx * dx + dy * dy;
    if (segmentLenSq == 0.0) {
      return const Distance().as(LengthUnit.Meter, p, a);
    }

    final double t = math.max(0.0, math.min(1.0, (x * dx + y * dy) / segmentLenSq));
    final double projX = t * dx;
    final double projY = t * dy;

    final double distRad = math.sqrt((x - projX) * (x - projX) + (y - projY) * (y - projY));
    return distRad * _earthRadiusM;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Filters points of interest within [maxCorridorMeters] of [polyline].
  static List<CorridorMatch<T>> findAlongPolyline<T>({
    required List<LatLng> polyline,
    required List<T> items,
    required LatLng Function(T) getCoordinates,
    double maxCorridorMeters = 300.0,
  }) {
    if (polyline.length < 2) return [];

    final List<CorridorMatch<T>> matches = [];

    for (final item in items) {
      final point = getCoordinates(item);
      double minDistance = double.infinity;

      for (int i = 0; i < polyline.length - 1; i++) {
        final dist = distanceToSegment(point, polyline[i], polyline[i + 1]);
        if (dist < minDistance) {
          minDistance = dist;
        }
      }

      if (minDistance <= maxCorridorMeters) {
        // Round-trip diversion cost (off trail + return to trail)
        final detourSeconds = (minDistance * 2) / _effectiveWalkingSpeedMps;
        final detourMins = (detourSeconds / 60).ceil();

        matches.add(
          CorridorMatch(
            item: item,
            distanceToCorridorMeters: minDistance,
            estimatedDetourMinutes: math.max(1, detourMins),
          ),
        );
      }
    }

    matches.sort((a, b) => a.distanceToCorridorMeters.compareTo(b.distanceToCorridorMeters));
    return matches;
  }

  /// Convenience wrapper delegating to [SpatialCorridorEngine.searchAlongRoute].
  static CorridorSearchResult searchAlongRoute({
    required List<LatLng> polyline,
    List<FoodSpot> foodSpots = const [],
    List<MetroStation> metroStations = const [],
    List<Pandal> pandals = const [],
    double bufferMeters = SpatialCorridorEngine.defaultBufferMeters,
  }) {
    return SpatialCorridorEngine.searchAlongRoute(
      polyline: polyline,
      foodSpots: foodSpots,
      metroStations: metroStations,
      pandals: pandals,
      bufferMeters: bufferMeters,
    );
  }
}

/// The category of a point of interest (POI) detected within the walking corridor.
enum CorridorItemType {
  food,
  metro,
  pandal,
}

/// A spatial item located within the buffer zone of an active walking polyline.
class CorridorItem {
  const CorridorItem({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    required this.perpendicularDistanceMeters,
    required this.distanceAlongRouteMeters,
    this.foodSpot,
    this.metroStation,
    this.pandal,
  });

  final String id;
  final String name;
  final CorridorItemType type;
  final double latitude;
  final double longitude;

  /// Perpendicular detour distance from the walking polyline in meters.
  final double perpendicularDistanceMeters;

  /// Cumulative walking distance along the route to this item's closest projection point.
  final double distanceAlongRouteMeters;

  final FoodSpot? foodSpot;
  final MetroStation? metroStation;
  final Pandal? pandal;

  /// Human-readable subtitle describing the item.
  String get subtitle {
    switch (type) {
      case CorridorItemType.food:
        final parts = <String>[];
        if (foodSpot?.mustTry != null && foodSpot!.mustTry!.isNotEmpty) {
          parts.add(foodSpot!.mustTry!);
        } else {
          parts.add(foodSpot?.type ?? 'Food Spot');
        }
        if (foodSpot?.priceRange != null && foodSpot!.priceRange!.isNotEmpty) {
          parts.add(foodSpot!.priceRange!);
        }
        return parts.join(' • ');

      case CorridorItemType.metro:
        if (metroStation != null) {
          return metroStation!.subtitle;
        }
        return 'Metro Station';

      case CorridorItemType.pandal:
        if (pandal != null) {
          final themeStr = pandal!.theme.isNotEmpty ? ' • ${pandal!.theme}' : '';
          return '${pandal!.zoneLabel}$themeStr';
        }
        return 'Pandal';
    }
  }

  /// Compact badge text (e.g. price range, metro line, or zone).
  String get badgeText {
    switch (type) {
      case CorridorItemType.food:
        return foodSpot?.priceRange ?? 'FOOD';
      case CorridorItemType.metro:
        return metroStation?.line.label.split(' ').first ?? 'METRO';
      case CorridorItemType.pandal:
        return pandal?.zoneLabel ?? 'PANDAL';
    }
  }

  /// Formatted walking progress along route (e.g. "in 350 m" or "in 1.2 km").
  String get formattedAlongDistance {
    if (distanceAlongRouteMeters < 1000) {
      return 'in ${distanceAlongRouteMeters.round()} m';
    }
    return 'in ${(distanceAlongRouteMeters / 1000).toStringAsFixed(1)} km';
  }

  /// Formatted perpendicular detour distance (e.g. "30 m off-route").
  String get formattedDetourDistance {
    if (perpendicularDistanceMeters < 1000) {
      return '${perpendicularDistanceMeters.round()} m off-route';
    }
    return '${(perpendicularDistanceMeters / 1000).toStringAsFixed(1)} km off-route';
  }
}

/// Aggregated result of a spatial corridor search along an active polyline.
class CorridorSearchResult {
  const CorridorSearchResult({
    required this.items,
    required this.bufferMeters,
    required this.polylineLengthMeters,
  });

  /// All POIs found in the corridor, sorted ascending by [CorridorItem.distanceAlongRouteMeters].
  final List<CorridorItem> items;

  /// The corridor buffer width used for search (e.g. 300.0 meters).
  final double bufferMeters;

  /// Total length of the active walking polyline in meters.
  final double polylineLengthMeters;

  bool get isEmpty => items.isEmpty;
  bool get isNotEmpty => items.isNotEmpty;
  int get count => items.length;

  List<CorridorItem> get foodSpots =>
      items.where((i) => i.type == CorridorItemType.food).toList();

  List<CorridorItem> get metroStations =>
      items.where((i) => i.type == CorridorItemType.metro).toList();

  List<CorridorItem> get pandals =>
      items.where((i) => i.type == CorridorItemType.pandal).toList();

  static const empty = CorridorSearchResult(
    items: [],
    bufferMeters: 300.0,
    polylineLengthMeters: 0.0,
  );
}

/// High-performance in-memory vector corridor search engine.
///
/// Operates with 0 network bytes and sub-millisecond execution times.
/// Uses bounding-box spatial pruning, equirectangular planar projection,
/// and point-to-segment Euclidean distance calculations.
class SpatialCorridorEngine {
  const SpatialCorridorEngine._();

  static const double defaultBufferMeters = 300.0;
  static const double _earthRadiusMeters = 6371000.0;
  static const double _degToRad = math.pi / 180.0;
  static const double _metersPerDegreeLat = _earthRadiusMeters * _degToRad; // ~111,195 m

  /// Searches for [FoodSpot]s, [MetroStation]s, and optional [Pandal]s within
  /// [bufferMeters] (default 300m) of an active [polyline].
  ///
  /// Returns a [CorridorSearchResult] containing all items sorted by their
  /// along-route walking progress.
  static CorridorSearchResult searchAlongRoute({
    required List<LatLng> polyline,
    List<FoodSpot> foodSpots = const [],
    List<MetroStation> metroStations = const [],
    List<Pandal> pandals = const [],
    double bufferMeters = defaultBufferMeters,
  }) {
    if (polyline.isEmpty) {
      return CorridorSearchResult.empty;
    }

    // 1. Single-point polyline edge case
    if (polyline.length == 1) {
      final origin = polyline.first;
      return _searchAroundPoint(
        point: origin,
        foodSpots: foodSpots,
        metroStations: metroStations,
        pandals: pandals,
        bufferMeters: bufferMeters,
      );
    }

    // 2. Pre-process polyline segments and cumulative distances
    final segmentCount = polyline.length - 1;
    final segmentLengths = List<double>.filled(segmentCount, 0.0);
    final accumulatedDistances = List<double>.filled(polyline.length, 0.0);

    double totalPolylineMeters = 0.0;
    double minLat = polyline.first.latitude;
    double maxLat = polyline.first.latitude;
    double minLng = polyline.first.longitude;
    double maxLng = polyline.first.longitude;

    for (int i = 0; i < segmentCount; i++) {
      final a = polyline[i];
      final b = polyline[i + 1];

      // Expand bounding box
      if (b.latitude < minLat) minLat = b.latitude;
      if (b.latitude > maxLat) maxLat = b.latitude;
      if (b.longitude < minLng) minLng = b.longitude;
      if (b.longitude > maxLng) maxLng = b.longitude;

      final len = _segmentLength(a, b);
      segmentLengths[i] = len;
      totalPolylineMeters += len;
      accumulatedDistances[i + 1] = totalPolylineMeters;
    }

    // 3. Compute Bounding Box with buffer margin for instant O(1) candidate pruning
    final midLat = (minLat + maxLat) / 2.0;
    final metersPerDegreeLng = _metersPerDegreeLat * math.cos(midLat * _degToRad);

    final latBufferDeg = (bufferMeters * 1.1) / _metersPerDegreeLat;
    final lngBufferDeg = (bufferMeters * 1.1) / (metersPerDegreeLng.abs() > 1e-4 ? metersPerDegreeLng : 1.0);

    final bboxMinLat = minLat - latBufferDeg;
    final bboxMaxLat = maxLat + latBufferDeg;
    final bboxMinLng = minLng - lngBufferDeg;
    final bboxMaxLng = maxLng + lngBufferDeg;

    final results = <CorridorItem>[];

    // Helper to evaluate a POI candidate
    void evaluatePoi({
      required String id,
      required String name,
      required CorridorItemType type,
      required double lat,
      required double lng,
      FoodSpot? foodSpot,
      MetroStation? metroStation,
      Pandal? pandal,
    }) {
      // Step A: Bounding-box test (instant rejection)
      if (lat < bboxMinLat || lat > bboxMaxLat || lng < bboxMinLng || lng > bboxMaxLng) {
        return;
      }

      // Step B: Point-to-segment minimum distance search across polyline
      double minPerpDist = double.infinity;
      double bestAlongDist = 0.0;

      for (int i = 0; i < segmentCount; i++) {
        final a = polyline[i];
        final b = polyline[i + 1];
        final segLen = segmentLengths[i];

        if (segLen < 1e-3) continue;

        // Equirectangular planar projection for this segment
        final segMidLat = (a.latitude + b.latitude) / 2.0;
        final kx = _metersPerDegreeLat * math.cos(segMidLat * _degToRad);
        const ky = _metersPerDegreeLat;

        final vx = (b.longitude - a.longitude) * kx;
        final vy = (b.latitude - a.latitude) * ky;

        final wx = (lng - a.longitude) * kx;
        final wy = (lat - a.latitude) * ky;

        // Project w onto v
        final c1 = wx * vx + wy * vy;
        final c2 = vx * vx + vy * vy;

        double t = c2 > 0 ? c1 / c2 : 0.0;
        if (t < 0.0) t = 0.0;
        if (t > 1.0) t = 1.0;

        final projX = t * vx;
        final projY = t * vy;

        final dx = wx - projX;
        final dy = wy - projY;
        final dist = math.sqrt(dx * dx + dy * dy);

        if (dist < minPerpDist) {
          minPerpDist = dist;
          bestAlongDist = accumulatedDistances[i] + (t * segLen);
        }
      }

      // Step C: If within corridor buffer, record item
      if (minPerpDist <= bufferMeters) {
        results.add(
          CorridorItem(
            id: id,
            name: name,
            type: type,
            latitude: lat,
            longitude: lng,
            perpendicularDistanceMeters: minPerpDist,
            distanceAlongRouteMeters: bestAlongDist,
            foodSpot: foodSpot,
            metroStation: metroStation,
            pandal: pandal,
          ),
        );
      }
    }

    // 4. Evaluate Food Spots
    for (final spot in foodSpots) {
      evaluatePoi(
        id: spot.id,
        name: spot.name,
        type: CorridorItemType.food,
        lat: spot.lat,
        lng: spot.lng,
        foodSpot: spot,
      );
    }

    // 5. Evaluate Metro Stations
    for (final station in metroStations) {
      evaluatePoi(
        id: station.id,
        name: station.name,
        type: CorridorItemType.metro,
        lat: station.latitude,
        lng: station.longitude,
        metroStation: station,
      );
    }

    // 6. Evaluate Pandals (if provided)
    for (final p in pandals) {
      evaluatePoi(
        id: p.id,
        name: p.name,
        type: CorridorItemType.pandal,
        lat: p.latitude,
        lng: p.longitude,
        pandal: p,
      );
    }

    // 7. Sort by along-route progress (items encountered first appear first)
    results.sort((a, b) => a.distanceAlongRouteMeters.compareTo(b.distanceAlongRouteMeters));

    return CorridorSearchResult(
      items: results,
      bufferMeters: bufferMeters,
      polylineLengthMeters: totalPolylineMeters,
    );
  }

  static double _segmentLength(LatLng a, LatLng b) {
    final midLat = (a.latitude + b.latitude) / 2.0;
    final kx = _metersPerDegreeLat * math.cos(midLat * _degToRad);
    const ky = _metersPerDegreeLat;

    final dx = (b.longitude - a.longitude) * kx;
    final dy = (b.latitude - a.latitude) * ky;
    return math.sqrt(dx * dx + dy * dy);
  }

  static CorridorSearchResult _searchAroundPoint({
    required LatLng point,
    required List<FoodSpot> foodSpots,
    required List<MetroStation> metroStations,
    required List<Pandal> pandals,
    required double bufferMeters,
  }) {
    final results = <CorridorItem>[];
    final kx = _metersPerDegreeLat * math.cos(point.latitude * _degToRad);
    const ky = _metersPerDegreeLat;

    void checkPoint({
      required String id,
      required String name,
      required CorridorItemType type,
      required double lat,
      required double lng,
      FoodSpot? foodSpot,
      MetroStation? metroStation,
      Pandal? pandal,
    }) {
      final dx = (lng - point.longitude) * kx;
      final dy = (lat - point.latitude) * ky;
      final dist = math.sqrt(dx * dx + dy * dy);
      if (dist <= bufferMeters) {
        results.add(
          CorridorItem(
            id: id,
            name: name,
            type: type,
            latitude: lat,
            longitude: lng,
            perpendicularDistanceMeters: dist,
            distanceAlongRouteMeters: 0.0,
            foodSpot: foodSpot,
            metroStation: metroStation,
            pandal: pandal,
          ),
        );
      }
    }

    for (final spot in foodSpots) {
      checkPoint(
        id: spot.id,
        name: spot.name,
        type: CorridorItemType.food,
        lat: spot.lat,
        lng: spot.lng,
        foodSpot: spot,
      );
    }
    for (final st in metroStations) {
      checkPoint(
        id: st.id,
        name: st.name,
        type: CorridorItemType.metro,
        lat: st.latitude,
        lng: st.longitude,
        metroStation: st,
      );
    }
    for (final p in pandals) {
      checkPoint(
        id: p.id,
        name: p.name,
        type: CorridorItemType.pandal,
        lat: p.latitude,
        lng: p.longitude,
        pandal: p,
      );
    }

    results.sort((a, b) => a.perpendicularDistanceMeters.compareTo(b.perpendicularDistanceMeters));

    return CorridorSearchResult(
      items: results,
      bufferMeters: bufferMeters,
      polylineLengthMeters: 0.0,
    );
  }
}
