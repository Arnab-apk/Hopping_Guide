// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Enumeration of supported geographic area types for spatial representation.
///
/// Defines the concrete type used for geographic area implementations within
/// the SDK.
///
/// ## Values
///
/// - [undefined]: An undefined geographic area type used as fallback.
/// - [circle]: A circular geographic area defined by center point and radius.
/// - [rectangle]: A rectangular area aligned with latitude/longitude lines.
/// - [polygon]: A polygonal area defined by a sequence of coordinate vertices.
/// - [tileCollection]: An area represented as a collection of map tiles.
///
/// ## See also:
///
/// - [GeographicArea]: Abstract base class for all geographic area types.
/// - [RectangleGeographicArea]: Rectangular geographic area implementation.
/// - [CircleGeographicArea]: Circular geographic area implementation.
/// - [PolygonGeographicArea]: Polygonal geographic area implementation.
///
/// {@category Geographic}
enum GeographicAreaType {
  /// Undefined area type.
  undefined,

  /// Circle area.
  circle,

  /// Rectangle area.
  rectangle,

  /// Polygon area.
  polygon,

  /// Area represented as a collection of tiles.
  tileCollection,
}

/// @nodoc
extension GeographicAreaTypeExtension on GeographicAreaType {
  int get id {
    switch (this) {
      case GeographicAreaType.undefined:
        return 0;
      case GeographicAreaType.circle:
        return 1;
      case GeographicAreaType.rectangle:
        return 2;
      case GeographicAreaType.polygon:
        return 3;
      case GeographicAreaType.tileCollection:
        return 4;
    }
  }

  static GeographicAreaType fromId(final int id) {
    switch (id) {
      case 0:
        return GeographicAreaType.undefined;
      case 1:
        return GeographicAreaType.circle;
      case 2:
        return GeographicAreaType.rectangle;
      case 3:
        return GeographicAreaType.polygon;
      case 4:
        return GeographicAreaType.tileCollection;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Abstract base class for representing geographic areas on the WGS 84 ellipsoid.
///
/// Geographic areas define spatial regions used throughout the SDK for various
/// purposes including map centering, search area restriction, geofencing, and
/// representing the spatial extent of entities like landmarks, routes, and
/// traffic events. The framework supports rectangles, circles, polygons, and
/// tile collections as concrete implementations.
///
/// All geometric calculations are performed in two dimensions, with altitude
/// values in [Coordinates] being ignored for containment and intersection tests.
/// Geographic areas provide common operations for spatial queries and conversions
/// between different area types where possible.
///
/// ## Common Operations
///
/// All geographic area implementations provide methods for:
/// - Point containment testing via [containsCoordinates]
/// - Bounding box calculation via [boundingBox]
/// - Center point computation via [centerPoint]
/// - Type conversion via [convert]
/// - Empty state checking via [isDefault]
///
/// ## See also:
///
/// - [RectangleGeographicArea]: Rectangular areas aligned with latitude/longitude.
/// - [CircleGeographicArea]: Circular areas defined by center and radius.
/// - [PolygonGeographicArea]: Complex polygonal areas with high precision.
/// - [TilesCollectionGeographicArea]: Areas represented as map tile collections.
///
/// {@category Geographic}
abstract class GeographicArea {
  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory GeographicArea.fromJson(final Map<String, dynamic> json) {
    switch (json['type']) {
      case 1:
        return CircleGeographicArea.fromJson(json);
      case 2:
        return RectangleGeographicArea.fromJson(json);
      case 3:
        return PolygonGeographicArea.fromJson(json);
      default:
        return RectangleGeographicArea(
          topLeft: Coordinates(),
          bottomRight: Coordinates(),
        );
    }
  }

  /// Tests whether a coordinate point lies within this geographic area.
  ///
  /// Performs a containment test to determine if the specified coordinate
  /// falls inside the boundaries of this geographic area. The exact algorithm
  /// depends on the concrete implementation.
  ///
  /// Altitude values are ignored in the calculation.
  ///
  /// ## Parameters
  ///
  /// - [point]: The [Coordinates] to test for containment. Only latitude and
  ///   longitude are considered; altitude is ignored.
  ///
  /// ## Returns
  ///
  /// - `true` when the point lies inside the area boundaries, `false` otherwise.
  bool containsCoordinates(final Coordinates point);

  /// Gets the smallest rectangle that completely encloses this geographic area.
  ///
  /// Computes the minimal axis-aligned bounding rectangle that contains the
  /// entire geographic area. For rectangles, this returns the rectangle itself.
  /// For circles and polygons, this calculates the enclosing rectangle with
  /// sides parallel to latitude and longitude lines.
  ///
  /// ## Returns
  ///
  /// - A [RectangleGeographicArea] representing the smallest enclosing rectangle.
  RectangleGeographicArea get boundingBox;

  /// Gets the representative center point of this geographic area.
  ///
  /// Calculates a coordinate that represents the geographic center of the area.
  /// The exact computation method depends on the area type: rectangles use the
  /// midpoint of corners, circles return their center coordinate, and polygons
  /// compute the centroid of their vertices.
  ///
  /// ## Returns
  ///
  /// - A [Coordinates] object representing the center point of the area.
  Coordinates get centerPoint;

  /// Indicates whether this geographic area is in a default or empty state.
  ///
  /// Checks if the geographic area contains default values that represent
  /// an uninitialized or empty state.
  ///
  /// ## Returns
  ///
  /// - `true` when the area is in default/empty state, `false` otherwise.
  bool get isDefault;

  /// Gets the specific type identifier for this geographic area implementation.
  ///
  /// Returns the [GeographicAreaType] enum value that corresponds to the
  /// concrete class implementing this geographic area.
  ///
  GeographicAreaType get type;

  /// Attempts to convert this geographic area to a different type.
  ///
  /// Tries to create a new geographic area of the specified type that
  /// approximates the same spatial region. Conversion success depends on
  /// the source and target types - some conversions may result in loss of
  /// precision or may not be possible at all.
  ///
  /// ## Parameters
  ///
  /// - [toType]: The desired target [GeographicAreaType] for conversion.
  ///
  /// ## Returns
  ///
  /// - A new [GeographicArea] of the requested type on successful conversion,
  ///   or `null` if conversion is not possible or fails.
  GeographicArea? convert(GeographicAreaType toType);

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson();

  /// Resets this geographic area to its default empty state.
  ///
  /// Clears all coordinate and parameter data, returning the area to an
  /// uninitialized state.
  void reset();
}
