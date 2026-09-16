// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Geographic area represented as a collection of map tiles.
///
/// Represents complex geographic regions using a collection of map tiles
/// rather than geometric primitives.
///
/// This class acts as a proxy to an underlying native platform object and
/// delegates most operations to that implementation. For serialization and
/// most SDK interactions, it uses its computed [boundingBox] representation.
///
/// ## Limitations
///
/// - Some operations are unsupported.
///
/// ## Use Cases
///
/// Tile collection areas are suitable for:
/// - Representing the are where a [Route] is bounded.
///
/// ## See also:
///
/// - [GeographicArea]: Abstract base class for all geographic areas.
/// - [RectangleGeographicArea]: Simple rectangular area implementation.
/// - [RouteBase.tilesGeographicArea]: Method returning tile collection area.
///
/// {@category Geographic}
class TilesCollectionGeographicArea extends GemAutoreleaseObject
    implements GeographicArea {
  // ignore: unused_element
  TilesCollectionGeographicArea._() : super(-1);

  @internal
  TilesCollectionGeographicArea.init(super.id);

  @override
  Coordinates get centerPoint {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TilesCollectionGeographicArea',
      'getCenterPoint',
    );

    return Coordinates.fromJson(resultString['result']);
  }

  @override
  RectangleGeographicArea get boundingBox {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TilesCollectionGeographicArea',
      'getBoundingBox',
    );

    return RectangleGeographicArea.fromJson(resultString['result']);
  }

  @override
  bool containsCoordinates(final Coordinates coords) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TilesCollectionGeographicArea',
      'containsCoordinates',
      args: coords,
    );

    return resultString['result'];
  }

  @override
  bool get isDefault => boundingBox.isDefault;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = boundingBox.toJson();
    json['type'] = GeographicAreaType.tileCollection.id;
    json['pointerId'] = pointerId;
    return json;
  }

  @override
  GeographicAreaType get type => GeographicAreaType.tileCollection;

  @override
  void reset() {
    objectMethod(pointerId, 'TilesCollectionGeographicArea', 'reset');
  }

  @override
  GeographicArea? convert(GeographicAreaType toType) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TilesCollectionGeographicArea',
      'convert',
      args: toType.id,
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
