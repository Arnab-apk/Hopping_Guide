// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:math';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Rectangular geographic area aligned with latitude and longitude lines.
///
/// Represents a geographic rectangle defined by its top-left (northwest) and
/// bottom-right (southeast) corner coordinates. The rectangle's sides are
/// parallel to parallels and meridians, making it suitable for bounding boxes,
/// search areas, and map viewport definitions.
///
/// For a valid rectangle, the top-left coordinate must have:
/// - `latitude` greater than bottom-right latitude (north is "up")
/// - `longitude` less than bottom-right longitude (west is "left")
///
/// This class provides operations for rectangle intersection, union, containment
/// testing, and various construction methods from bounds or center points.
///
/// A valid `RectangleGeographicArea` requires:
/// - `topLeft.latitude > bottomRight.latitude`
/// - `topLeft.longitude < bottomRight.longitude`
///
/// The constructor does not enforce these constraints, so callers must ensure
/// proper coordinate ordering.
///
/// ## See also:
///
/// - [GeographicArea]: Abstract base class for all geographic areas.
/// - [CircleGeographicArea]: Circular geographic area implementation.
/// - [PolygonGeographicArea]: Polygonal geographic area implementation.
///
/// {@category Geographic}
class RectangleGeographicArea implements GeographicArea {
  /// Creates a rectangular geographic area from corner coordinates.
  ///
  /// Constructs a rectangle using the specified top-left (northwest) and
  /// bottom-right (southeast) corner coordinates. The rectangle's sides will
  /// be aligned with latitude and longitude lines.
  ///
  /// ## Parameters
  ///
  /// - [topLeft]: The northwest corner coordinate. Should have latitude greater
  ///   than [bottomRight] and longitude less than [bottomRight] for a valid rectangle.
  /// - [bottomRight]: The southeast corner coordinate.
  ///
  /// ## Note
  ///
  /// The constructor does not validate coordinate ordering. Ensure that
  /// `topLeft.latitude > bottomRight.latitude` and
  /// `topLeft.longitude < bottomRight.longitude` for correct behavior.
  RectangleGeographicArea({required this.topLeft, required this.bottomRight});

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory RectangleGeographicArea.fromJson(final Map<String, dynamic> json) {
    return RectangleGeographicArea(
      topLeft: Coordinates.fromJson(json['topleft']),
      bottomRight: Coordinates.fromJson(json['bottomright']),
    );
  }

  /// The northwest corner coordinate of the rectangle.
  ///
  /// Represents the top-left point with the highest latitude and lowest
  /// longitude values of the rectangle boundaries. For a valid rectangle,
  /// this coordinate's latitude should be greater than [bottomRight] latitude.
  Coordinates topLeft;

  /// The southeast corner coordinate of the rectangle.
  ///
  /// Represents the bottom-right point with the lowest latitude and highest
  /// longitude values of the rectangle boundaries. For a valid rectangle,
  /// this coordinate's latitude should be less than [topLeft] latitude.
  Coordinates bottomRight;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['topleft'] = topLeft.toJson();
    json['bottomright'] = bottomRight.toJson();
    json['type'] = 2;
    return json;
  }

  /// Tests whether this rectangle intersects with another rectangle.
  ///
  /// Determines if the two rectangles have any overlapping area, including
  /// cases where they share an edge or corner. The test uses standard
  /// rectangle intersection logic comparing the bounds of both rectangles.
  ///
  /// ## Parameters
  ///
  /// - [area]: The [RectangleGeographicArea] to test for intersection.
  ///
  /// ## Returns
  ///
  /// - `true` if the rectangles intersect or touch, `false` if they are completely separate.
  bool intersects(final RectangleGeographicArea area) {
    return bottomRight.longitude >= area.topLeft.longitude &&
        area.bottomRight.longitude >= topLeft.longitude &&
        topLeft.latitude >= area.bottomRight.latitude &&
        area.topLeft.latitude >= bottomRight.latitude;
  }

  /// Tests whether this rectangle completely contains another rectangle.
  ///
  /// Checks if the specified rectangle lies entirely within the bounds of this
  /// rectangle. The contained rectangle's bounds must be completely inside or
  /// exactly match this rectangle's bounds for the test to return true.
  ///
  /// ## Parameters
  ///
  /// - [area]: The [RectangleGeographicArea] to test for containment.
  ///
  /// ## Returns
  ///
  /// - `true` if this rectangle completely contains the other rectangle, `false` otherwise.
  bool contains(final RectangleGeographicArea area) {
    return bottomRight.longitude >= area.bottomRight.longitude &&
        topLeft.longitude <= area.topLeft.longitude &&
        topLeft.latitude >= area.topLeft.latitude &&
        bottomRight.latitude <= area.bottomRight.latitude;
  }

  /// Creates the union of this rectangle with another rectangle.
  ///
  /// Computes a new rectangle that encompasses both this rectangle and the
  /// specified rectangle. The resulting rectangle will be the smallest
  /// axis-aligned rectangle that contains both input rectangles completely.
  ///
  /// ## Parameters
  ///
  /// - [area]: The [RectangleGeographicArea] to unite with this rectangle.
  ///
  /// ## Returns
  ///
  /// - A new [RectangleGeographicArea] representing the union of both rectangles.
  RectangleGeographicArea makeUnion(final RectangleGeographicArea area) {
    return RectangleGeographicArea(
      topLeft: Coordinates(
        longitude: min(topLeft.longitude, area.topLeft.longitude),
        latitude: max(topLeft.latitude, area.topLeft.latitude),
      ),
      bottomRight: Coordinates(
        longitude: max(bottomRight.longitude, area.bottomRight.longitude),
        latitude: min(bottomRight.latitude, area.bottomRight.latitude),
      ),
    );
  }

  /// Creates the intersection of this rectangle with another rectangle.
  ///
  /// Computes a new rectangle representing the overlapping area between this
  /// rectangle and the specified rectangle. If the rectangles do not intersect,
  /// the result may be an invalid rectangle with no area.
  ///
  /// ## Parameters
  ///
  /// - [area]: The [RectangleGeographicArea] to intersect with this rectangle.
  ///
  /// ## Returns
  ///
  /// - A new [RectangleGeographicArea] representing the intersection area.
  ///   May be invalid (empty) if the rectangles do not overlap. The user is
  ///   responsible for checking validity after intersection.
  RectangleGeographicArea makeIntersection(final RectangleGeographicArea area) {
    return RectangleGeographicArea(
      topLeft: Coordinates(
        longitude: max(topLeft.longitude, area.topLeft.longitude),
        latitude: min(topLeft.latitude, area.topLeft.latitude),
      ),
      bottomRight: Coordinates(
        longitude: min(bottomRight.longitude, area.bottomRight.longitude),
        latitude: max(bottomRight.latitude, area.bottomRight.latitude),
      ),
    );
  }

  /// Creates a deep copy of this rectangle with identical coordinates.
  ///
  /// Generates a new [RectangleGeographicArea] instance with the same top-left
  /// and bottom-right coordinates as this rectangle. The new instance is
  /// completely independent and modifications to it will not affect the original instance.
  ///
  /// ## Returns
  ///
  /// - A new [RectangleGeographicArea] with identical coordinate values.
  RectangleGeographicArea get copy {
    return RectangleGeographicArea(
      topLeft: topLeft.copy,
      bottomRight: bottomRight.copy,
    );
  }

  /// Sets rectangle coordinates using minimum and maximum latitude/longitude bounds.
  ///
  /// Configures this rectangle by specifying the extreme coordinate values
  /// that define the rectangle's boundaries. This method does not validate the
  /// input values and the resulting rectangle may be invalid if the bounds are
  /// not provided in the correct order.
  ///
  /// ## Parameters
  ///
  /// - [minLat]: The minimum (southernmost) latitude value.
  /// - [maxLat]: The maximum (northernmost) latitude value.
  /// - [minLon]: The minimum (westernmost) longitude value.
  /// - [maxLon]: The maximum (easternmost) longitude value.
  void setFromBounds({
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
  }) {
    topLeft = Coordinates(latitude: maxLat, longitude: minLon);
    bottomRight = Coordinates(latitude: minLat, longitude: maxLon);
  }

  /// Sets rectangle coordinates using a center point and horizontal/vertical radii.
  ///
  /// Configures this rectangle by specifying a center coordinate and distances
  /// in meters extending horizontally and vertically from that center. The
  /// method calculates the appropriate corner coordinates to create a rectangle
  /// with the specified dimensions.
  ///
  /// ## Parameters
  ///
  /// - [coords]: The center [Coordinates] of the desired rectangle.
  /// - [horizRadius]: Horizontal radius in meters (east-west extent from center).
  /// - [vertRadius]: Vertical radius in meters (north-south extent from center).
  void setFromCenterAndRadii({
    required Coordinates coords,
    required double horizRadius,
    required double vertRadius,
  }) {
    topLeft = coords.copyWithMetersOffset(
      metersLatitude: vertRadius.toInt(),
      metersLongitude: -horizRadius.toInt(),
    );
    bottomRight = coords.copyWithMetersOffset(
      metersLatitude: -vertRadius.toInt(),
      metersLongitude: horizRadius.toInt(),
    );
  }

  @override
  bool get isDefault =>
      topLeft.longitude - bottomRight.longitude == 0.0 &&
      topLeft.latitude - bottomRight.latitude == 0.0;

  @override
  RectangleGeographicArea get boundingBox => copy;

  @override
  bool containsCoordinates(final Coordinates point) {
    return (point.longitude >= topLeft.longitude &&
            point.longitude <= bottomRight.longitude) &&
        (point.latitude <= topLeft.latitude &&
            point.latitude >= bottomRight.latitude);
  }

  @override
  Coordinates get centerPoint {
    final bool isAltitudeNull =
        topLeft.altitude == null || bottomRight.altitude == null;

    return Coordinates(
      latitude: (topLeft.latitude + bottomRight.latitude) * 0.5,
      longitude: (topLeft.longitude + bottomRight.longitude) * 0.5,
      altitude: isAltitudeNull
          ? null
          : (topLeft.altitude! + bottomRight.altitude!) * 0.5,
    );
  }

  @override
  bool operator ==(covariant final RectangleGeographicArea other) {
    if (identical(this, other)) {
      return true;
    }

    return other.topLeft == topLeft && other.bottomRight == bottomRight;
  }

  @override
  int get hashCode => topLeft.hashCode ^ bottomRight.hashCode;

  @override
  String toString() =>
      'RectangleGeographicArea(topleft: $topLeft, bottomright: $bottomRight)';

  @override
  GeographicAreaType get type => GeographicAreaType.rectangle;

  @override
  void reset() {
    topLeft = Coordinates();
    bottomRight = Coordinates();
  }

  @override
  GeographicArea? convert(GeographicAreaType toType) {
    final OperationResult resultString = staticMethod(
      'GeographicArea',
      'convert',
      args: <String, dynamic>{
        'toType': toType.id,
        'fromType': GeographicAreaType.rectangle.id,
        'topLeft': topLeft.toJson(),
        'bottomRight': bottomRight.toJson(),
      },
    );

    if (resultString['gemApiError'] != 0) {
      return null;
    }

    switch (toType) {
      case GeographicAreaType.rectangle:
        return RectangleGeographicArea.fromJson(resultString.data['result']);
      case GeographicAreaType.circle:
        return CircleGeographicArea.fromJson(resultString['result']);
      case GeographicAreaType.polygon:
        return PolygonGeographicArea.fromJson(resultString['result']);
      case GeographicAreaType.tileCollection:
        return TilesCollectionGeographicArea.init(resultString['result']);
      case GeographicAreaType.undefined:
        return RectangleGeographicArea(
          topLeft: Coordinates(),
          bottomRight: Coordinates(),
        );
    }
  }
}
