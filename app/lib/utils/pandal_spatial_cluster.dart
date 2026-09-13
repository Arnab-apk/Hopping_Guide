import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../models/pandal.dart';
import 'constants.dart';

/// Represents either a single pandal marker or an aggregated cluster of nearby pandals.
class PandalClusterItem {
  final LatLng point;
  final int count;
  final List<Pandal> pandals;
  final Pandal? primaryPandal;
  final String label;

  const PandalClusterItem({
    required this.point,
    required this.count,
    required this.pandals,
    this.primaryPandal,
    this.label = '',
  });

  bool get isCluster => count > 1;
  String get id => isCluster ? 'cluster_${point.latitude}_${point.longitude}' : primaryPandal!.id;
}

/// Ultra-fast spatial grid clustering & viewport culling utility.
/// Operates in sub-millisecond time to guarantee buttery smooth 60 FPS map performance.
class PandalSpatialClusterer {
  const PandalSpatialClusterer._();

  /// Clusters pandals adaptively based on map camera zoom and visible viewport bounds.
  static List<PandalClusterItem> cluster({
    required List<Pandal> allPandals,
    required double zoom,
    required LatLngBounds visibleBounds,
    Pandal? selectedPandal,
    Set<String>? priorityPandalIds,
  }) {
    if (allPandals.isEmpty) return const [];

    // Expanded viewport bounds (25% margin) to prevent any marker pop-in during panning
    final latSpan = (visibleBounds.north - visibleBounds.south).abs();
    final lngSpan = (visibleBounds.east - visibleBounds.west).abs();
    final minLat = visibleBounds.south - (latSpan * 0.25);
    final maxLat = visibleBounds.north + (latSpan * 0.25);
    final minLng = visibleBounds.west - (lngSpan * 0.25);
    final maxLng = visibleBounds.east + (lngSpan * 0.25);

    // Zoom thresholds and grid steps (in degrees)
    // 1 deg lat is ~111 km. 0.035 deg is ~3.8 km, 0.015 deg is ~1.6 km, 0.005 deg is ~500 m.
    final bool isStreetView = zoom >= 14.8;
    final double gridStep;
    if (zoom < 12.0) {
      gridStep = 0.038;
    } else if (zoom < 13.2) {
      gridStep = 0.022;
    } else if (zoom < 14.0) {
      gridStep = 0.012;
    } else if (zoom < 14.8) {
      gridStep = 0.005;
    } else {
      gridStep = 0.001; // Street view: almost every pandal separate
    }

    final Map<int, List<Pandal>> buckets = {};
    final Set<String> priorityIds = priorityPandalIds ?? const {};
    final List<PandalClusterItem> priorityItems = [];

    // 1. Fast viewport filter & spatial bucketing
    for (int i = 0; i < allPandals.length; i++) {
      final p = allPandals[i];

      // Selected pandal or active trail stops are kept as individual priority items
      final isSelected = selectedPandal?.id == p.id;
      final isPriority = priorityIds.contains(p.id);

      if (isSelected || isPriority) {
        priorityItems.add(
          PandalClusterItem(
            point: LatLng(p.lat, p.lng),
            count: 1,
            pandals: [p],
            primaryPandal: p,
            label: p.name,
          ),
        );
        continue;
      }

      // Viewport culling
      if (p.lat < minLat || p.lat > maxLat || p.lng < minLng || p.lng > maxLng) {
        continue;
      }

      if (isStreetView) {
        // At street view, add each visible pandal as an individual item directly
        priorityItems.add(
          PandalClusterItem(
            point: LatLng(p.lat, p.lng),
            count: 1,
            pandals: [p],
            primaryPandal: p,
            label: p.name,
          ),
        );
        continue;
      }

      // Quantize coordinates into integer spatial hash key
      final gx = (p.lng / gridStep).round();
      final gy = (p.lat / gridStep).round();
      final key = (gy * 100000) + gx;

      buckets.putIfAbsent(key, () => []).add(p);
    }

    if (isStreetView) {
      return priorityItems;
    }

    // 2. Aggregate buckets into ClusterItems
    final List<PandalClusterItem> result = List.of(priorityItems);

    for (final group in buckets.values) {
      if (group.isEmpty) continue;

      if (group.length == 1) {
        final p = group.first;
        result.add(
          PandalClusterItem(
            point: LatLng(p.lat, p.lng),
            count: 1,
            pandals: group,
            primaryPandal: p,
            label: p.name,
          ),
        );
      } else {
        // Compute centroid
        double sumLat = 0.0;
        double sumLng = 0.0;
        for (int j = 0; j < group.length; j++) {
          sumLat += group[j].lat;
          sumLng += group[j].lng;
        }
        final centroid = LatLng(sumLat / group.length, sumLng / group.length);

        // Derive representative label
        final commonArea = group.first.area ?? group.first.zone.label;

        result.add(
          PandalClusterItem(
            point: centroid,
            count: group.length,
            pandals: group,
            primaryPandal: group.first,
            label: commonArea,
          ),
        );
      }
    }

    return result;
  }
}
