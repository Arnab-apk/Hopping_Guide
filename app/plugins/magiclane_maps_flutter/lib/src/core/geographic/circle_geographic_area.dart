// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Circular geographic area defined by center coordinates and radius in meters.
///
/// Represents a circular region around a specific geographic point, useful for
/// proximity-based operations, geofencing applications, and simple area
/// approximations. The circle is defined by its center point and a radius
/// measured in meters from that center.
///
/// The containment test uses the great-circle distance between the test point
/// and the center, comparing it against the specified radius.
///
/// ## See also:
///
/// - [GeographicArea]: Abstract base class for all geographic areas.
/// - [RectangleGeographicArea]: Rectangular geographic area implementation.
/// - [PolygonGeographicArea]: Polygonal geographic area for complex shapes.
///
/// {@category Geographic}
class CircleGeographicArea implements GeographicArea {
  /// Creates a circular geographic area with specified center and radius.
  ///
  /// Constructs a circle defined by a center coordinate point and a radius
  /// measured in meters. The resulting area includes all points within the
  /// specified distance from the center point.
  ///
  /// ## Parameters
  ///
  /// - [radius]: The radius of the circle in meters. Must be non-negative.
  /// - [centerCoordinates]: The [Coordinates] of the circle's center point.
  ///
  /// ## See also:
  ///
  /// - [GeographicArea]: Abstract base class for geographic areas.
  CircleGeographicArea({required this.radius, required this.centerCoordinates});

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory CircleGeographicArea.fromJson(final Map<String, dynamic> json) {
    return CircleGeographicArea(
      radius: json['radius'],
      centerCoordinates: Coordinates.fromJson(json['centerCoordinates']),
    );
  }

  /// The radius of the circle in meters.
  ///
  /// Defines the maximum distance from the [centerCoordinates] that is
  /// considered inside the circular area. A radius of 0 indicates an
  /// empty or default circle.
  int radius;

  /// The center point of the circular area.
  ///
  /// All points within [radius] meters of these coordinates are considered
  /// to be contained within the circular geographic area.
  Coordinates centerCoordinates;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['radius'] = radius;
    json['centerCoordinates'] = centerCoordinates;
    json['type'] = 1;

    return json;
  }

  @override
  RectangleGeographicArea get boundingBox {
    return RectangleGeographicArea(
      topLeft: centerCoordinates.copyWithMetersOffset(
        metersLatitude: -radius,
        metersLongitude: -radius,
      ),
      bottomRight: centerCoordinates.copyWithMetersOffset(
        metersLatitude: radius,
        metersLongitude: radius,
      ),
    );
  }

  @override
  Coordinates get centerPoint {
    return centerCoordinates.copy;
  }

  @override
  bool containsCoordinates(final Coordinates point) {
    return point.distance(centerCoordinates, ignoreAltitude: true) <= radius;
  }

  @override
  bool get isDefault => radius == 0;

  @override
  bool operator ==(covariant final CircleGeographicArea other) {
    if (identical(this, other)) {
      return true;
    }

    return other.radius == radius &&
        other.centerCoordinates == centerCoordinates;
  }

  @override
  int get hashCode => radius.hashCode ^ centerCoordinates.hashCode;

  @override
  String toString() =>
      'CircleGeographicArea(radius: $radius, centerCoordinates: $centerCoordinates)';
  @override
  GeographicAreaType get type => GeographicAreaType.circle;

  @override
  void reset() {
    radius = 0;
    centerCoordinates = Coordinates();
  }

  @override
  GeographicArea? convert(GeographicAreaType toType) {
    final OperationResult resultString = staticMethod(
      'GeographicArea',
      'convert',
      args: <String, dynamic>{
        'toType': toType.id,
        'fromType': GeographicAreaType.circle.id,
        'radius': radius,
        'centerCoordinates': centerCoordinates.toJson(),
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
