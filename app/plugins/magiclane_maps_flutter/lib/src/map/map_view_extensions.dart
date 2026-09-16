// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Map View Extensions
///
/// A compact set of view-scoped helpers that extend the native map view with lightweight,
/// platform-proxied utilities for view tuning and small integrations.
///
/// These helpers provide convenience features for performance and interaction tuning,
/// integrations with sensing/positioning subsystems, and small view-level configuration
/// (for example: enforcing zoom limits, toggling low-end CPU optimizations, switching
/// reduced-rate navigation updates, and starting/stopping enhanced position-tracking
/// visualizations).
///
/// {@category Maps & 3D Scenes}
class MapViewExtensions {
  // ignore: unused_element
  MapViewExtensions._() : _pointerId = -1, _mapId = -1, _mapControllerId = -1;

  @internal
  MapViewExtensions.init(
    final int id,
    final int mapId,
    final int mapControllerId,
  ) : _pointerId = id,
      _mapId = mapId,
      _mapControllerId = mapControllerId;

  final dynamic _pointerId;
  final dynamic _mapId;
  final dynamic _mapControllerId;

  int get pointerId => _pointerId;
  int get mapId => _mapId;
  int get mapControllerId => _mapControllerId;

  /// Get group highlighted item index for the given highlighted item index (in original list).
  ///
  /// Returns the index of the group item that contains the highlighted item identified
  /// by [idx]. Use [highlightId] to resolve the group within a specific highlight
  /// collection when multiple highlight sets are present.
  ///
  /// ## Parameters
  ///
  /// - [idx]: The highlighted item index in the original list to look up.
  /// - [highlightId]: Optional highlight collection id (defaults to 0).
  ///
  /// ## Returns
  ///
  /// - The group index in the highlighted items' original list. On error the function
  /// returns an error code as an integer.
  int getHighlightGroupItemIndex(final int idx, {final int highlightId = 0}) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewExtensions',
      'getHighlightGroupItemIndex',
      args: <String, int>{'idx': idx, 'highlightId': highlightId},
      dependencyId: _mapControllerId,
    );

    return resultString['result'];
  }

  /// Get the maximum allowed zoom level.
  ///
  /// Returns the maximum zoom level that the map view currently allows. The value
  /// is provided by the native map view implementation.
  ///
  /// ## Returns
  ///
  /// - The maximum allowed zoom level as an integer.
  ///
  /// ## Also see:
  ///
  /// - [GemMapController.maxZoomLevel] - The maximum zoom level from the map controller.
  int get maximumAllowedZoomLevel {
    throw UnimplementedError(
      'Unimplemented method: get maximumAllowedZoomLevel',
    );
    // try {
    //   final resultString = GemKitPlatform.instance.callObjectMethod(jsonEncode({
    //     'id': _pointerId,
    //     'MapViewExtensions',
    //     'getMaximumAllowedZoomLevel',
    //     'args': {}
    //   }));
    //
    //   return resultString['result'];
    // } catch (e) {
    //   rethrow;
    // }
  }

  /// Get the minimum allowed zoom level.
  ///
  /// Returns the minimum zoom level that the map view currently enforces.
  ///
  /// ## Returns
  ///
  /// - The minimum allowed zoom level as an integer.
  ///
  /// ## Also see:
  ///
  /// - [GemMapController.minZoomLevel] - The minimum zoom level from the map controller.
  int get minimumAllowedZoomLevel {
    throw UnimplementedError(
      'Unimplemented method: get minimumAllowedZoomLevel',
    );
    // try {
    //   final resultString = GemKitPlatform.instance.callObjectMethod(jsonEncode({
    //     'id': _pointerId,
    //     'MapViewExtensions',
    //     'getMinimumAllowedZoomLevel',
    //     'args': {}
    //   }));
    //
    //   return resultString['result'];
    // } catch (e) {
    //   rethrow;
    // }
  }

  /// Set the maximum allowed zoom level.
  ///
  /// Update the maximum zoom level that the map view will accept. The change is
  /// applied to the underlying native view and may affect rendering and interaction.
  ///
  /// ## Parameters
  ///
  /// - [zoomLevel]: The maximum allowed zoom level to set.
  ///
  /// ## Also see:
  ///
  /// - [GemMapController.maxZoomLevel] — Get the current maximum allowed zoom level.
  set maximumAllowedZoomLevel(final int zoomLevel) {
    throw UnimplementedError(
      'Unimplemented method: set maximumAllowedZoomLevel',
    );
    // try {
    //   final result = GemKitPlatform.instance.callObjectMethod(jsonEncode({
    //     'id': _pointerId,
    //     'MapViewExtensions',
    //     'setMaximumAllowedZoomLevel',
    //     'args': zoomLevel
    //   }));

    //   final error = GemErrorExtension.fromCode(result['gemApiError'] as int);
    //   if(error != GemError.success) {
    //     throw error;
    //   }
    // } catch (e) {
    //   rethrow;
    // }
  }

  /// Set the minimum allowed zoom level.
  ///
  /// Update the minimum zoom level that the map view will accept. The change is
  /// applied to the underlying native view and may affect rendering and interaction.
  ///
  /// ## Parameters
  ///
  /// - [zoomLevel]: The minimum allowed zoom level to set.
  ///
  /// ## Also see:
  ///
  /// - [GemMapController.minZoomLevel] — Get the current minimum allowed zoom level.
  set minimumAllowedZoomLevel(final int zoomLevel) {
    throw UnimplementedError(
      'Unimplemented method: set minimumAllowedZoomLevel',
    );
    // try {
    //   final result = GemKitPlatform.instance.callObjectMethod(jsonEncode({
    //     'id': _pointerId,
    //     'MapViewExtensions',
    //     'setMinimumAllowedZoomLevel',
    //     'args': zoomLevel
    //   }));

    //   final error = GemErrorExtension.fromCode(result['gemApiError'] as int);
    //   if(error != GemError.success) {
    //     throw error;
    //   }
    // } catch (e) {
    //   rethrow;
    // }
  }

  /// Enable or disable optimizations for low-end CPUs.
  ///
  /// When enabled, the map view applies heuristics and reduced-cost rendering
  /// paths intended to improve responsiveness on devices with limited CPU power.
  ///
  /// ## Parameters
  ///
  /// - [bEnable]: True to enable optimizations, false to disable them.
  ///
  /// ## Also see:
  ///
  /// - [lowEndCPUOptimizations] — Get the current state of low-end CPU optimizations.
  set lowEndCPUOptimizations(final bool bEnable) {
    objectMethod(
      _pointerId,
      'MapViewExtensions',
      'setLowEndCPUOptimizations',
      args: bEnable,
      dependencyId: _mapControllerId,
    );
  }

  /// Get the low-end CPU optimizations flag.
  ///
  /// ## Returns
  ///
  /// - True when low-end CPU optimizations are enabled, false otherwise.
  ///
  /// ## Also see:
  ///
  /// - [lowEndCPUOptimizations] — Enable or disable low-end CPU optimizations.
  bool get lowEndCPUOptimizations {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewExtensions',
      'getLowEndCPUOptimizations',
      dependencyId: _mapControllerId,
    );

    return resultString['result'];
  }

  /// Get the navigation route low-rate update flag.
  ///
  /// When enabled, navigation route updates are delivered at a lower rate to
  /// reduce CPU and network usage during active navigation.
  ///
  /// ## Returns
  ///
  /// - True if navigation route low-rate updates are enabled, false otherwise.
  ///
  /// ## Also see:
  ///
  /// - [navigationRouteLowRateUpdate] — Enable or disable low-rate navigation updates.
  bool get navigationRouteLowRateUpdate {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewExtensions',
      'getNavigationRouteLowRateUpdate',
      dependencyId: _mapControllerId,
    );

    return resultString['result'];
  }

  /// Enable or disable navigation route low-rate updates.
  ///
  /// ## Parameters
  ///
  /// - [bEnable]: True to enable lower-rate navigation updates, false to disable.
  ///
  /// ## Also see:
  ///
  /// - [navigationRouteLowRateUpdate] — Get the current state of low-rate navigation updates.
  set navigationRouteLowRateUpdate(final bool bEnable) {
    objectMethod(
      _pointerId,
      'MapViewExtensions',
      'setNavigationRouteLowRateUpdate',
      args: bEnable,
      dependencyId: _mapControllerId,
    );
  }

  /// Get the navigation route update rate.
  ///
  /// The update rate controls how frequently the active navigation route is
  /// recomputed and re-rendered. Lower rates reduce CPU and battery usage at
  /// the cost of less frequent visual updates.
  ///
  /// ## Returns
  ///
  /// - The current [RouteUpdateRate] applied to navigation route updates.
  ///
  /// ## Also see:
  ///
  /// - [navigationRouteUpdateRate] (setter) — Set the navigation route update rate.
  /// - [navigationRouteLowRateUpdate] — Convenience flag for low-rate updates.
  RouteUpdateRate get navigationRouteUpdateRate {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewExtensions',
      'getNavigationRouteUpdateRate',
      dependencyId: _mapControllerId,
    );

    return RouteUpdateRateExtension.fromId(resultString['result'] as int);
  }

  /// Set the navigation route update rate.
  ///
  /// Choose how frequently the active navigation route is recomputed and
  /// re-rendered. Higher rates produce smoother visual updates at the cost of
  /// additional CPU and battery usage.
  ///
  /// ## Parameters
  ///
  /// - [rate]: The desired [RouteUpdateRate] for navigation route updates.
  ///
  /// ## Also see:
  ///
  /// - [navigationRouteUpdateRate] (getter) — Get the current navigation route update rate.
  /// - [navigationRouteLowRateUpdate] — Convenience flag for low-rate updates.
  set navigationRouteUpdateRate(final RouteUpdateRate rate) {
    objectMethod(
      _pointerId,
      'MapViewExtensions',
      'setNavigationRouteUpdateRate',
      args: rate.id,
      dependencyId: _mapControllerId,
    );
  }

  /// Start improved position tracking and render a marker polyline for tracked positions.
  ///
  /// This method enables an enhanced visualization that draws a polyline between
  /// relevant map link points for positions provided by a sense data source. The
  /// visualization is updated at the requested frequency and uses the supplied
  /// rendering [settings].
  ///
  /// ## Parameters
  ///
  /// - [updatePositionMs]: Update interval in milliseconds for the tracked positions.
  ///   High frequency values may reduce rendering performance on low-end devices.
  /// - [settings]: Marker collection rendering settings used to draw the tracked
  ///   positions on the map view.
  /// - [dataSource]: Optional DataSource whose positions will be tracked. If null,
  ///   the PositionService's default data source is used when available.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success.
  /// - [GemError.notFound] when no data source is available and none was provided.
  /// - Other [GemError] values for platform-specific errors.
  ///
  /// ## Also see:
  ///
  /// - [stopTrackPositions] — Stop the improved position tracking visualization.
  /// - [trackedPositions] — Get the current tracked positions.
  /// - [isTrackedPositions] — Check if position tracking is currently active.
  GemError startTrackPositions({
    required int updatePositionMs,
    required MarkerCollectionRenderSettings settings,
    DataSource? dataSource,
  }) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewExtensions',
      'startTrackPositions',
      args: <String, Object>{
        'updatePositionMs': updatePositionMs,
        'settings': settings,
        if (dataSource != null) 'dataSource': dataSource.pointerId,
      },
      dependencyId: _mapControllerId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Stop the improved position tracking visualization.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] when tracking was stopped successfully.
  /// - [GemError.notFound] if tracking was not running.
  ///
  /// ## Also see:
  ///
  /// - [startTrackPositions] — Start improved position tracking visualization.
  /// - [trackedPositions] — Get the current tracked positions.
  /// - [isTrackedPositions] — Check if position tracking is currently active.
  GemError stopTrackPositions() {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewExtensions',
      'stopTrackPositions',
      dependencyId: _mapControllerId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Get the current tracked positions as a list of coordinates.
  ///
  /// ## Returns
  ///
  /// - A list of tracked [Coordinates]. If tracking is not active an empty list is
  /// returned.
  ///
  /// ## Also see:
  ///
  /// - [startTrackPositions] — Start improved position tracking visualization.
  /// - [stopTrackPositions] — Stop the improved position tracking visualization.
  /// - [isTrackedPositions] — Check if position tracking is currently active.
  List<Coordinates> get trackedPositions {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewExtensions',
      'getTrackedPositions',
      dependencyId: _mapControllerId,
    );

    final List<Coordinates> coords = (resultString['result'] as List<dynamic>)
        .map((dynamic e) => Coordinates.fromJson(e))
        .toList();

    return coords;
  }

  /// Check whether position tracking is currently active in the map view.
  ///
  /// ## Returns
  ///
  /// - True when tracked position visualization is active, false otherwise.
  ///
  /// ## Also see:
  ///
  /// - [startTrackPositions] — Start improved position tracking visualization.
  /// - [stopTrackPositions] — Stop the improved position tracking visualization.
  /// - [trackedPositions] — Get the current tracked positions.
  bool get isTrackedPositions {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewExtensions',
      'isTrackedPositions',
      dependencyId: _mapControllerId,
    );

    return resultString['result'] as bool;
  }
}
