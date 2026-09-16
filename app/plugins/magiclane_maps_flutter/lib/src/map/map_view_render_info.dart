// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Information produced when the map view finishes a render pass.
///
/// Provides the data and camera transition statuses, the geographic area
/// visible in the view (as a polygon), and lists of marker and source IDs
/// that were rendered. Prefer [polygonArea] for accurate area calculations
/// when the map is rotated;
///
/// {@category Maps & 3D Scenes}
class MapViewRenderInfo {
  /// Creates a [MapViewRenderInfo] instance.
  ///
  /// Use this constructor to construct a render-info snapshot that describes
  /// what the map rendered during a single view cycle.
  ///
  /// ## Parameters
  ///
  /// - [dataTransitionStatus]: (ViewDataTransitionStatus) The status of data transitions for the view.
  /// - [cameraTransitionStatus]: (ViewCameraTransitionStatus) The status of camera transitions for the view.
  /// - [polygonArea]: (PolygonGeographicArea) The polygonal geographic area visible in the view.
  /// - [markersIds]: (`List<int>`) IDs of markers that were rendered during this view.
  /// - [sourcesIds]: (`List<int>`) IDs of sources that were rendered during this view.
  MapViewRenderInfo({
    required this.dataTransitionStatus,
    required this.cameraTransitionStatus,
    required this.polygonArea,
    required this.markersIds,
    required this.sourcesIds,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory MapViewRenderInfo.fromJson(final Map<String, dynamic> json) {
    final PolygonGeographicArea polygonArea = PolygonGeographicArea(
      coordinates: <Coordinates>[
        Coordinates.fromLatLong(json['leftTopX'], json['leftTopY']),
        Coordinates.fromLatLong(json['rightTopX'], json['rightTopY']),
        Coordinates.fromLatLong(json['rightBottomX'], json['rightBottomY']),
        Coordinates.fromLatLong(json['leftBottomX'], json['leftBottomY']),
      ],
    );
    return MapViewRenderInfo(
      dataTransitionStatus: ViewDataTransitionStatusExtension.fromId(
        json['viewDataTransitionStatus'] != 0,
      ),
      cameraTransitionStatus: ViewCameraTransitionStatusExtension.fromId(
        json['cameraStatus'] != 0,
      ),
      polygonArea: polygonArea,
      markersIds: json['markersIds'].cast<int>(),
      sourcesIds: json['sourcesIds'].cast<int>(),
    );
  }

  /// The view data transition status.
  ///
  /// Indicates whether view data transitions are complete or if online data
  /// is still expected to arrive. Use this to detect if rendered content may
  /// still change once additional data is received.
  final ViewDataTransitionStatus dataTransitionStatus;

  /// The view camera transition status.
  ///
  /// Describes whether the camera was stationary or moving during the
  /// render. Moving camera renders may be partial or interpolated.
  final ViewCameraTransitionStatus cameraTransitionStatus;

  /// The geographic bounding box that encloses the visible area.
  ///
  /// Deprecated: this getter computes a bounding rectangle from
  /// [polygonArea] and may be inaccurate when the map is rotated or at
  /// extreme zoom levels (near the poles or the antimeridian).
  @Deprecated(
    'This getter may be inaccurate for rotated views or extreme zoom levels; prefer polygonArea.',
  )
  RectangleGeographicArea get area => polygonArea.boundingBox;

  /// The polygonal geographic area that is rendered on the map.
  ///
  /// Provides the visible map area as a polygon. Use this when rotation or
  /// non-orthogonal views make a simple bounding rectangle (the `area` getter) inaccurate.
  ///
  /// This API is marked experimental and may change in future SDK
  /// versions. Results may also be imprecise at extreme zoom levels or near
  /// the poles/antimeridian.
  @experimental
  final PolygonGeographicArea polygonArea;

  /// The IDs of markers that are rendered on the map.
  ///
  /// These are the internal marker identifiers for marker objects that were
  /// visible during the render. They can be used to look up marker state or
  /// to notify external renderers about which IDs are currently visible.
  final List<int> markersIds;

  /// The IDs of sources that are rendered on the map.
  ///
  /// Sources correspond to data feeds or external renderers that produced
  /// the visible content. The IDs align with entries returned by the
  /// marker/source collections exposed by the map controller.
  final List<int> sourcesIds;

  /// A secondary bounding box for rendered content, if applicable.
  ///
  /// Deprecated: this field is legacy and may be null. It will be removed in
  /// a future release.
  @Deprecated('This field is legacy and may be removed in a future release.')
  final RectangleGeographicArea? areaSecond = null;
}

/// The status of view data transitions for a render pass.
///
/// Use this to determine whether the rendered content represents a final
/// state or if the view is still waiting for additional online data.
///
/// ## See also:
///
/// - [MapViewRenderInfo.dataTransitionStatus] — The data transition status for a render pass.
///
/// {@category Maps & 3D Scenes}
enum ViewDataTransitionStatus {
  /// All data transitions for the view are complete; no additional data is expected.
  complete,

  /// Data transitions are incomplete because additional online data is expected.
  incompleteOnline,
}

/// @nodoc
extension ViewDataTransitionStatusExtension on ViewDataTransitionStatus {
  bool get id {
    switch (this) {
      case ViewDataTransitionStatus.complete:
        return false;
      case ViewDataTransitionStatus.incompleteOnline:
        return true;
    }
  }

  static ViewDataTransitionStatus fromId(final bool id) {
    switch (id) {
      case false:
        return ViewDataTransitionStatus.complete;
      case true:
        return ViewDataTransitionStatus.incompleteOnline;
    }
  }
}

/// The camera transition status during a render.
///
/// Indicates whether the camera was stationary or moving while the view was
/// produced. Moving states typically imply the render might be transitional.
///
/// ## See also:
///
/// - [MapViewRenderInfo.cameraTransitionStatus] — The camera transition status for a render pass.
///
/// {@category Maps & 3D Scenes}
enum ViewCameraTransitionStatus {
  /// The camera was stationary during rendering.
  stationary,

  /// The camera was moving during rendering.
  moving,
}

/// @nodoc
extension ViewCameraTransitionStatusExtension on ViewCameraTransitionStatus {
  bool get id {
    switch (this) {
      case ViewCameraTransitionStatus.stationary:
        return false;
      case ViewCameraTransitionStatus.moving:
        return true;
    }
  }

  static ViewCameraTransitionStatus fromId(final bool id) {
    switch (id) {
      case false:
        return ViewCameraTransitionStatus.stationary;
      case true:
        return ViewCameraTransitionStatus.moving;
    }
  }
}
