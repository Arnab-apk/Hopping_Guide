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

/// Ultra-fast spatial grid clustering, viewport culling & memoization engine.
/// Operates in sub-millisecond time to guarantee buttery smooth 60/120 FPS map performance.
class PandalSpatialClusterer {
  PandalSpatialClusterer._();

  // --- High-Performance L1 Cluster Cache ---
  static List<PandalClusterItem>? _cachedResult;
  static double _lastZoom = -1.0;
  static int _lastListLength = -1;
  static String? _lastSelectedId;
  static int _lastPriorityHash = 0;
  static double _lastCenterLat = 0.0;
  static double _lastCenterLng = 0.0;
  static double _lastLatSpan = 0.0;
  static double _lastLngSpan = 0.0;

  /// Clear cache if data is refreshed externally
  static void invalidateCache() {
    _cachedResult = null;
    _lastZoom = -1.0;
    _lastListLength = -1;
    _lastCenterLat = 0.0;
    _lastCenterLng = 0.0;
    _lastLatSpan = 0.0;
    _lastLngSpan = 0.0;
  }

  /// Alias for invalidateCache
  static void clearCache() => invalidateCache();

  /// Clusters pandals adaptively based on map camera zoom and visible viewport bounds.
  static List<PandalClusterItem> cluster({
    List<Pandal>? allPandals,
    List<Pandal>? pandals,
    required double zoom,
    required LatLngBounds visibleBounds,
    Pandal? selectedPandal,
    Set<String>? priorityPandalIds,
  }) {
    final list = pandals ?? allPandals ?? const [];
    if (list.isEmpty) return const [];

    final selectedId = selectedPandal?.id;
    final priorityHash = priorityPandalIds?.length ?? 0;

    final latSpan = (visibleBounds.north - visibleBounds.south).abs();
    final lngSpan = (visibleBounds.east - visibleBounds.west).abs();
    final centerLat = (visibleBounds.north + visibleBounds.south) / 2.0;
    final centerLng = (visibleBounds.east + visibleBounds.west) / 2.0;

    // Fast Cache Check: If zoom delta < 0.08, list length & selection unchanged,
    // viewport span delta within 10%, and camera center has drifted < 15% of viewport
    // (well within the pre-buffered 35% margin), return the memoized list instantly (0ms).
    if (_cachedResult != null &&
        (zoom - _lastZoom).abs() < 0.08 &&
        list.length == _lastListLength &&
        selectedId == _lastSelectedId &&
        priorityHash == _lastPriorityHash &&
        _lastLatSpan > 0.0 &&
        _lastLngSpan > 0.0 &&
        (latSpan - _lastLatSpan).abs() < _lastLatSpan * 0.10 &&
        (lngSpan - _lastLngSpan).abs() < _lastLngSpan * 0.10 &&
        (centerLat - _lastCenterLat).abs() < _lastLatSpan * 0.15 &&
        (centerLng - _lastCenterLng).abs() < _lastLngSpan * 0.15) {
      return _cachedResult!;
    }

    // Expanded viewport bounds (35% margin) to eliminate marker pop-in during fast flick/pan
    final minLat = visibleBounds.south - (latSpan * 0.35);
    final maxLat = visibleBounds.north + (latSpan * 0.35);
    final minLng = visibleBounds.west - (lngSpan * 0.35);
    final maxLng = visibleBounds.east + (lngSpan * 0.35);

    // Zoom thresholds and grid steps (in degrees)
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
      gridStep = 0.001; // Street view
    }

    final Map<int, List<Pandal>> buckets = {};
    final Set<String> priorityIds = priorityPandalIds ?? const {};
    final List<PandalClusterItem> priorityItems = [];

    // 1. Fast viewport filter & spatial bucketing
    for (int i = 0; i < list.length; i++) {
      final p = list[i];

      // Selected pandal or active trail stops are kept as individual priority items
      final isSelected = selectedId == p.id;
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

      // Viewport culling against the 35% expanded buffer
      if (p.lat < minLat || p.lat > maxLat || p.lng < minLng || p.lng > maxLng) {
        continue;
      }

      if (isStreetView) {
        // At street view, individual visible pandals are added directly
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

      // Quantize coordinates into integer spatial hash key for O(1) bucketing
      final gx = (p.lng / gridStep).round();
      final gy = (p.lat / gridStep).round();
      final key = (gy * 100000) + gx;

      buckets.putIfAbsent(key, () => []).add(p);
    }

    final List<PandalClusterItem> result;

    if (isStreetView) {
      result = priorityItems;
    } else {
      // 2. Aggregate buckets into ClusterItems
      result = List.of(priorityItems);

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
    }

    // Save to L1 memoization cache
    _cachedResult = result;
    _lastZoom = zoom;
    _lastListLength = list.length;
    _lastSelectedId = selectedId;
    _lastPriorityHash = priorityHash;
    _lastCenterLat = centerLat;
    _lastCenterLng = centerLng;
    _lastLatSpan = latSpan;
    _lastLngSpan = lngSpan;

    return result;
  }
}
