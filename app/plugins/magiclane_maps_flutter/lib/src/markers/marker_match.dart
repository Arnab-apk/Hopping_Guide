// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// A single match found when querying the map for markers.
///
/// [MarkerMatch] represents one result returned by marker selection or hit tests
/// (for example from [GemMapController.cursorSelectionMarkers] or
/// [MapViewMarkerCollections.hitTest]). It exposes the matched [Marker], the
/// [MarkerCollection] it belongs to, the marker's index and part/segment that
/// was hit, the match [type], the distance from the query point, and the exact
/// matched [coordinates].
///
/// ## See also:
///
/// - [GemMapController.cursorSelectionMarkers] - obtain selection results.
/// - [MapViewMarkerCollections.hitTest] - perform hit tests across collections.
/// - [MarkerMatchType] - the kind of match detected.
///
/// {@category Markers}
class MarkerMatch extends GemAutoreleaseObject {
  MarkerMatch() : super(-1);

  @internal
  MarkerMatch.init(super.id);

  /// Returns the matched [Marker].
  ///
  /// ## Returns
  ///
  /// - The [Marker] instance that was matched by this hit.
  @Deprecated('Use marker getter instead')
  Marker getMarker() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerMatch',
      'getMarker',
    );

    return Marker.init(resultString['result']);
  }

  /// Returns the matched [Marker].
  ///
  /// ## Returns
  ///
  /// - The [Marker] instance that was matched by this hit.
  Marker get marker {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerMatch',
      'getMarker',
    );

    return Marker.init(resultString['result']);
  }

  /// Returns the [MarkerCollection] containing the matched marker.
  ///
  /// ## Returns
  ///
  /// - The [MarkerCollection] instance that contains the matched [Marker].
  MarkerCollection get markerCollection {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerMatch',
      'getMarkerCollection',
    );

    return MarkerCollection.init(resultString['result'], 0);
  }

  /// The zero-based index of the matched marker inside its collection.
  ///
  /// ## Returns
  ///
  /// - An integer representing the marker index within the collection.
  int get markerIndex {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerMatch',
      'getMarkerIndex',
    );

    return resultString['result'];
  }

  /// The part index that was hit for markers composed of multiple parts.
  ///
  /// ## Returns
  ///
  /// - An integer identifying the part.
  int get partIndex {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerMatch',
      'getPartIndex',
    );

    return resultString['result'];
  }

  /// The segment index that was hit.
  ///
  /// ## Returns
  ///
  /// - An integer identifying the segment.
  int get segment {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerMatch',
      'getSegment',
    );

    return resultString['result'];
  }

  /// The type of match that was detected.
  ///
  /// ## Returns
  ///
  /// - [MarkerMatchType] indicating the type of match.
  MarkerMatchType get type {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerMatch',
      'getType',
    );

    return MarkerMatchType.values[resultString['result']];
  }

  /// Distance from the query point to the matched position, in meters.
  ///
  /// ## Returns
  ///
  /// - Distance measured in meters as an integer.
  int get distance {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerMatch',
      'getDistance',
    );

    return resultString['result'];
  }

  /// The geographic coordinates of the match.
  ///
  /// ## Returns
  ///
  /// - A [Coordinates] object describing the matched position.
  Coordinates get coordinates {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerMatch',
      'getCoordinates',
    );

    return Coordinates.fromJson(resultString['result']);
  }
}

/// Marker match type
///
/// {@category Markers}
enum MarkerMatchType {
  /// None
  none,

  /// Match on a coordinate
  coordinate,

  /// Match on a coordinate group
  coordinateGroup,

  /// Match on marker contour ( for polyline and polygon types )
  contour,

  /// Match inside marker ( for polygon types )
  inside,
}

/// @nodoc
extension MarkerMatchTypeExtension on MarkerMatchType {
  int get id {
    switch (this) {
      case MarkerMatchType.none:
        return 0;
      case MarkerMatchType.coordinate:
        return 1;
      case MarkerMatchType.coordinateGroup:
        return 2;
      case MarkerMatchType.contour:
        return 3;
      case MarkerMatchType.inside:
        return 4;
    }
  }

  static MarkerMatchType fromId(final int id) {
    switch (id) {
      case 0:
        return MarkerMatchType.none;
      case 1:
        return MarkerMatchType.coordinate;
      case 2:
        return MarkerMatchType.coordinateGroup;
      case 3:
        return MarkerMatchType.contour;
      case 4:
        return MarkerMatchType.inside;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
