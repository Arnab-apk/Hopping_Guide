// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Polygonal geographic area defined by a sequence of coordinate vertices.
///
/// Represents complex geographic regions with irregular boundaries using a
/// series of connected coordinate points. This implementation provides the
/// highest precision for representing detailed geographic boundaries such as
/// administrative regions, natural features, or custom area definitions.
///
/// The polygon is defined by an ordered list of coordinates that form the
/// boundary vertices. The polygon is automatically closed by connecting the
/// last vertex back to the first vertex.
///
/// ## Polygon Requirements
///
/// For correct operation, polygons should have:
/// - At least 3 coordinate vertices to form a valid shape
/// - No self-intersecting edges that cross each other
/// - No overlapping segments that trace the same path
///
/// ## Use Cases
///
/// Polygonal areas are ideal for:
/// - Administrative boundaries (countries, states, cities)
/// - Natural geographic features (lakes, forests, parks)
/// - Custom business districts or service areas
/// - Precise geofencing with complex shapes
///
/// ## See also:
///
/// - [GeographicArea]: Abstract base class for all geographic areas.
/// - [RectangleGeographicArea]: Simple rectangular areas.
/// - [CircleGeographicArea]: Circular areas with center and radius.
///
/// {@category Geographic}
class PolygonGeographicArea implements GeographicArea {
  /// Creates a polygonal geographic area from a list of coordinate vertices.
  ///
  /// Constructs a polygon using the provided coordinates as vertices. The
  /// polygon boundary is formed by connecting consecutive coordinates in order,
  /// with the last coordinate automatically connected back to the first to
  /// close the shape.
  ///
  /// ## Parameters
  ///
  /// - [coordinates]: An ordered list of [Coordinates] defining the polygon
  ///   vertices. Should contain at least 3 points for a valid polygon.
  ///
  /// ## Important
  ///
  /// For correct behavior, ensure the coordinate list has at least 3 vertices
  /// and avoid self-intersecting or overlapping edges.
  ///
  /// ## See also:
  ///
  /// - [GeographicArea]: Abstract base class for geographic areas.
  PolygonGeographicArea({this.coordinates = const <Coordinates>[]});

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory PolygonGeographicArea.fromJson(final Map<String, dynamic> json) {
    final List<Coordinates> coords = (json['coordinates'] as List<dynamic>)
        .map((dynamic e) => Coordinates.fromJson(e))
        .toList();
    return PolygonGeographicArea(coordinates: coords);
  }

  /// The ordered list of coordinates defining the polygon boundary.
  ///
  /// Each coordinate represents a vertex of the polygon. The boundary is
  /// formed by connecting consecutive coordinates, with the last coordinate
  /// automatically connected to the first to close the polygon shape.
  ///
  /// A valid polygon should have at least 3 coordinates to form a proper area.
  List<Coordinates> coordinates;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['coordinates'] = coordinates;
    json['type'] = 3;
    return json;
  }

  @override
  RectangleGeographicArea get boundingBox {
    if (coordinates.isEmpty) {
      return RectangleGeographicArea(
        topLeft: Coordinates(),
        bottomRight: Coordinates(),
      );
    }

    late double left, right, top, bottom;
    left = right = coordinates.first.longitude;
    top = bottom = coordinates.first.latitude;

    for (final Coordinates coordinate in coordinates) {
      right = max(right, coordinate.longitude);
      bottom = min(bottom, coordinate.latitude);
      left = min(left, coordinate.longitude);
      top = max(top, coordinate.latitude);
    }

    return RectangleGeographicArea(
      topLeft: Coordinates(longitude: left, latitude: top),
      bottomRight: Coordinates(longitude: right, latitude: bottom),
    );
  }

  @override
  Coordinates get centerPoint {
    final int nVecs = coordinates.length;

    if (nVecs < 3) {
      return Coordinates();
    }

    double ai, atmp = 0, xtmp = 0, ytmp = 0;

    int i = nVecs - 1;
    int j = 0;

    while (j < nVecs) {
      final Coordinates ci = coordinates[i];
      final Coordinates cj = coordinates[j];

      ai = _crossProductScalarValue(
        ci.longitude,
        ci.latitude,
        cj.longitude,
        cj.latitude,
      );
      atmp += ai;

      xtmp += (cj.longitude + ci.longitude) * ai;
      ytmp += (cj.latitude + ci.latitude) * ai;

      i = j++;
    }

    if (atmp == 0) {
      return Coordinates();
    }

    return Coordinates(
      longitude: xtmp / (3 * atmp),
      latitude: ytmp / (3 * atmp),
    );
  }

  @override
  bool containsCoordinates(final Coordinates point) {
    final int nVecs = coordinates.length;
    if (nVecs < 3) {
      return false;
    }

    int i = 0;
    int j = nVecs - 1;

    bool status = false;

    while (i < nVecs) {
      final Coordinates ci = coordinates[i];
      final Coordinates cj = coordinates[j];

      if ((ci.latitude > point.latitude) != (cj.latitude > point.latitude)) {
        final double intersectLongitude =
            (point.latitude - ci.latitude) *
                (cj.longitude - ci.longitude) /
                (cj.latitude - ci.latitude) +
            ci.longitude;

        if (point.longitude < intersectLongitude) {
          status = !status;
        }
      }

      j = i++;
    }

    return status;
  }

  @override
  bool get isDefault => boundingBox.isDefault;

  double _crossProductScalarValue(
    final double ax,
    final double ay,
    final double bx,
    final double by,
  ) {
    return ax * by - ay * bx;
  }

  @override
  bool operator ==(covariant final PolygonGeographicArea other) {
    if (identical(this, other)) {
      return true;
    }

    return listEquals(other.coordinates, coordinates);
  }

  @override
  int get hashCode {
    int hash = 0;
    for (final Coordinates coordinate in coordinates) {
      hash = hash ^ coordinate.hashCode;
    }

    return hash;
  }

  @override
  String toString() => 'PolygonGeographicArea(coordinates: $coordinates)';

  @override
  GeographicAreaType get type => GeographicAreaType.polygon;

  @override
  void reset() {
    coordinates = <Coordinates>[];
  }

  @override
  GeographicArea? convert(GeographicAreaType toType) {
    final OperationResult resultString = staticMethod(
      'GeographicArea',
      'convert',
      args: <String, dynamic>{
        'toType': toType.id,
        'fromType': GeographicAreaType.polygon.id,
        'coordinates': coordinates.map((Coordinates e) => e.toJson()).toList(),
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
