// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// A specialized, per-marker render configuration collection.
///
/// [MarkerSketches] extends [MarkerCollection] and allows per-marker render
/// presets so each sketch can have a distinct visual style. These collections
/// are singletons (one per [MarkerType]) and should be obtained using
/// [MapViewMarkerCollections.getSketches].
///
/// Typical use cases include temporary annotations, user-drawn markers, or per-item styling when a global
/// [MarkerCollectionRenderSettings] is not sufficient.
///
/// ## Example:
/// ```dart
/// final MarkerSketches sketches = controller.preferences.markers.getSketches(MarkerType.point);
/// final Marker marker = Marker()..add(Coordinates(latitude: 39.76741, longitude: -46.8962));
/// marker.name = 'HelloMarker';
///
/// sketches.addMarker(marker, settings: MarkerRenderSettings(labelTextSize: 3.0));
/// ```
///
/// ## See also:
///
/// - [MapViewMarkerCollections.getSketches] - obtain sketches for a given type.
/// - [MarkerRenderSettings] - per-marker render options.
/// - [MarkerCollection] - collection of markers with shared settings.
///
/// {@category Markers}
class MarkerSketches extends MarkerCollection {
  @internal
  MarkerSketches.init(super.id, super.mapId) : super.init();

  /// Add a new sketch with optional per-marker render settings.
  ///
  /// This inserts [marker] into the sketches collection. If [settings] is
  /// provided it overrides any collection-level render settings for this
  /// specific marker. The optional [index] controls the insertion position;
  /// pass `-1` (the default) to append at the end (topmost).
  ///
  /// ## Parameters
  ///
  /// - [marker]: The [Marker] to add to the sketches collection.
  /// - [settings]: Optional [MarkerRenderSettings] used only for this marker.
  /// - [index]: Optional insertion index. `-1` appends the marker.
  void addMarker(
    final Marker marker, {
    MarkerRenderSettings? settings,
    int index = -1,
  }) {
    settings ??= MarkerRenderSettings();
    objectMethod(
      pointerId,
      'MarkerSketches',
      'addSketches',
      args: <String, Object>{
        'marker': marker.pointerId,
        'settings': settings,
        'index': index,
      },
    );
  }

  /// Retrieve the render settings for the sketch at [index].
  ///
  /// If [index] is invalid a default [MarkerRenderSettings] instance is
  /// returned (callers should treat this as the default styling for that
  /// marker).
  ///
  /// ## Parameters
  ///
  /// - [index]: The zero-based marker index in the sketches collection.
  ///
  /// ## Returns
  ///
  /// - The [MarkerRenderSettings] currently applied to the sketch, or a
  ///   default instance when the index is out of range.
  MarkerRenderSettings getRenderSettings(int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerSketches',
      'getRenderSettings',
      args: index,
    );

    return MarkerRenderSettings.fromJson(resultString['result']);
  }

  /// Update the render settings for a sketch at [index].
  ///
  /// Use this to change the appearance of an existing sketch. The provided
  /// [settings] will replace the per-marker settings for that index.
  ///
  /// ## Parameters
  ///
  /// - [index]: The zero-based marker index whose settings should be updated.
  /// - [settings]: The new [MarkerRenderSettings] to apply.
  void setRenderSettings(int index, MarkerRenderSettings settings) {
    objectMethod(
      pointerId,
      'MarkerSketches',
      'setRenderSettings',
      args: <String, Object>{'marker': index, 'settings': settings},
    );
  }
}
