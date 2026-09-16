// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// A compact model representing a visual geometry placed on the map.
///
/// A [Marker] represents a visual geometry — for example a point, a polyline or a polygon —
/// positioned at geographic coordinates. Markers are suitable for annotations, waypoints or
/// temporary content that require only lightweight metadata (name, id) and a set of coordinates.
///
/// A marker can contain multiple parts; each part is a list of [Coordinates]. Parts allow a single
/// marker to represent multipart geometries (for example: multi-segment polylines or polygons).
///
/// Coordinates are managed using [add], [update], [delete], and [setCoordinates] methods and
/// the marker's geographic extent can be obtained via the [area] getter.
///
/// ## See also:
/// - [MarkerCollection] - for organizing multiple markers and displaying them on a map.
/// - [MarkerRenderSettings] - for customizing appearance of Markers.
/// - [MarkerCollectionRenderSettings] - for customizing appearance of MarkerCollections.
///
/// {@category Markers}
class Marker extends GemAutoreleaseObject {
  factory Marker() {
    return Marker._create();
  }

  /// Create a marker from a list of geographic coordinates.
  ///
  /// The created marker will contain a single part populated with the provided coordinates.
  ///
  /// ## Parameters
  ///
  /// - [coordinates]: A list of [Coordinates] that will be assigned to the marker's first part.
  ///
  /// ## Returns
  ///
  /// - A new [Marker] instance initialized with the provided coordinates.
  factory Marker.fromCoords(final List<Coordinates> coordinates) {
    return Marker._createFromCoords(coordinates);
  }

  /// Create a circular marker centered at [centerCoords].
  ///
  /// ## Parameters
  ///
  /// - [centerCoords]: Center of the circle as [Coordinates].
  /// - [radius]: Radius in meters.
  ///
  /// ## Returns
  ///
  /// - A new [Marker] representing a circular area.
  factory Marker.fromCircle(
    final Coordinates centerCoords,
    final double radius,
  ) {
    return Marker._createFromCircle(centerCoords, radius);
  }

  /// Create a rectangular marker defined by two corner coordinates.
  ///
  /// ## Parameters
  ///
  /// - [topLeft]: Coordinates of the rectangle top-left corner.
  /// - [bottomRight]: Coordinates of the rectangle bottom-right corner.
  ///
  /// ## Returns
  ///
  /// - A new [Marker] representing the rectangular area.
  factory Marker.fromRectangle(
    final Coordinates topLeft,
    final Coordinates bottomRight,
  ) {
    return Marker._createFromRectangle(topLeft, bottomRight);
  }

  /// Create an elliptical marker using horizontal and vertical radii around the center.
  ///
  /// ## Parameters
  ///
  /// - [centerCoords]: Center coordinates for the ellipse.
  /// - [horizRadius]: Horizontal radius in meters.
  /// - [vertRadius]: Vertical radius in meters.
  ///
  /// ## Returns
  ///
  /// - A new [Marker] representing the elliptical area.
  factory Marker.fromCircleRadii({
    required final Coordinates centerCoords,
    required final double horizRadius,
    required final double vertRadius,
  }) {
    return Marker._createFromCircleRadii(centerCoords, horizRadius, vertRadius);
  }

  /// Create a marker from an existing [GeographicArea].
  ///
  /// The area's shape will be converted to the marker representation.
  ///
  /// ## Parameters
  ///
  /// - [area]: Geographic area to convert into a marker.
  ///
  /// ## Returns
  ///
  /// - A new [Marker] whose geometry corresponds to the provided [area].
  factory Marker.fromArea(final GeographicArea area) {
    return Marker._createFromArea(area);
  }

  @internal
  Marker.init(super.id);

  dynamic get _pointerId => super.pointerId;

  /// Add a coordinate to this marker.
  ///
  /// Adds [coord] to the requested [part]. If [index] is provided and >= 0 the
  /// coordinate is inserted at that position; otherwise it is appended.
  ///
  /// ## Parameters
  ///
  /// - [coord]: The [Coordinates] to add.
  /// - [index]: Optional insertion index (default: -1, append).
  /// - [part]: Part index where the coordinate will be added (default: 0).
  void add(
    final Coordinates coord, {
    final int index = -1,
    final int part = 0,
  }) {
    objectMethod(
      _pointerId,
      'Marker',
      'add',
      args: <String, Object>{'coord': coord, 'index': index, 'part': part},
    );
  }

  /// Remove the coordinate at [index] from the specified [part].
  ///
  /// ## Parameters
  ///
  /// - [index]: Index of the coordinate to delete in the given part.
  /// - [part]: Part index (default: 0).
  void delete(final int index, {final int part = 0}) {
    objectMethod(
      _pointerId,
      'Marker',
      'del',
      args: <String, int>{'index': index, 'part': part},
    );
  }

  /// Delete a range of coordinates in a part.
  ///
  /// Removes coordinates starting at [from] and ending before [to]. If [to] is -1,
  /// deletion continues to the end of the part's coordinate list.
  ///
  /// ## Parameters
  ///
  /// - [from]: Start index (inclusive).
  /// - [to]: End index (exclusive) or -1 to delete until the end.
  /// - [part]: Part index (default: 0).
  void deleteRange(int from, int to, {int part = 0}) {
    objectMethod(
      _pointerId,
      'Marker',
      'delRange',
      args: <String, Object>{'from': from, 'to': to, 'part': part},
    );
  }

  /// Remove an entire part from this marker.
  ///
  /// ## Parameters
  ///
  /// - [part]: Index of the part to remove.
  void deletePart(final int part) {
    objectMethod(_pointerId, 'Marker', 'delPart', args: part);
  }

  /// Returns the geographic bounding rectangle that encloses the marker geometry.
  ///
  /// ## Returns
  ///
  /// - A [RectangleGeographicArea] describing the marker's enclosing bounds.
  /// If the marker has no coordinates, an empty area with [GeographicArea.isDefault] = `true` is returned.
  RectangleGeographicArea get area {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'Marker',
      'getArea',
    );

    return RectangleGeographicArea.fromJson(resultString['result']);
  }

  /// Return the coordinates for a specific part of the marker.
  ///
  /// ## Parameters
  ///
  /// - [part]: Part index to query (default: 0).
  ///
  /// ## Returns
  ///
  /// - A [List<Coordinates>] containing the coordinates for the requested part.
  /// Returns an empty list if the part has no coordinates or is invalid.
  List<Coordinates> getCoordinates({final int part = 0}) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'Marker',
      'getCoordinates',
      args: part,
    );

    final List<dynamic> listJson = resultString['result'];
    final List<Coordinates> retList = listJson
        .map((final dynamic categoryJson) => Coordinates.fromJson(categoryJson))
        .toList();
    return retList;
  }

  /// The unique identifier for this marker.
  ///
  /// ## Returns
  ///
  /// - An integer id assigned by the underlying engine.
  int get id {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'Marker',
      'getId',
    );

    return resultString['result'];
  }

  /// The marker's human readable name.
  ///
  /// ## Returns
  ///
  /// - The current name as a [String].
  String get name {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'Marker',
      'getName',
    );

    return resultString['result'];
  }

  /// Returns the bounding rectangle for a single part of the marker.
  ///
  /// ## Parameters
  ///
  /// - [part]: Part index to query.
  ///
  /// ## Returns
  ///
  /// - A [RectangleGeographicArea] that bounds the requested part.
  /// If the part has no coordinates, an empty area with [GeographicArea.isDefault] = `true` is returned.
  RectangleGeographicArea getPartArea(final int part) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'Marker',
      'getPartArea',
      args: part,
    );

    return RectangleGeographicArea.fromJson(resultString['result']);
  }

  /// The number of parts contained in this marker.
  ///
  /// ## Returns
  ///
  /// - An integer representing how many parts (lists of coordinates) this marker has.
  int get partCount {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'Marker',
      'getPartCount',
    );

    return resultString['result'];
  }

  /// Replace the coordinates for a specific part.
  ///
  /// If [part] equals the current [partCount], a new part will be appended and the
  /// provided coordinates will be assigned to it.
  ///
  /// ## Parameters
  ///
  /// - [coords]: New coordinates list for the part.
  /// - [part]: Optional part index. If omitted, part 0 is replaced.
  void setCoordinates(final List<Coordinates> coords, {final int part = 0}) {
    objectMethod(
      _pointerId,
      'Marker',
      'setCoordinates',
      args: <String, Object>{'coords': coords, 'part': part},
    );
  }

  /// Set the marker's human readable name.
  ///
  /// ## Parameters
  ///
  /// - [name]: New name for the marker.
  set name(final String name) {
    objectMethod(_pointerId, 'Marker', 'setName', args: name);
  }

  /// Update a specific coordinate in a part.
  ///
  /// ## Parameters
  ///
  /// - [coord]: New [Coordinates] value.
  /// - [index]: Index of the coordinate to update.
  /// - [part]: Optional part index (if omitted, part 0 is used).
  void update(final Coordinates coord, final int index, {final int part = 0}) {
    objectMethod(
      _pointerId,
      'Marker',
      'update',
      args: <String, Object>{'coord': coord, 'index': index, 'part': part},
    );
  }

  /// Returns the number of coordinates in the specified [part].
  ///
  /// ## Parameters
  ///
  /// - [part]: Part index to query (default: 0).
  ///
  /// ## Returns
  ///
  /// - The coordinates count for the requested part. If the part is invalid an
  ///   error code ([GemError.invalidInput].code) may be returned.
  int getCoordinatesCount({final int part = 0}) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'Marker',
      'getCoordinatesCount',
      args: part,
    );
    return resultString['result'];
  }

  /// Return the coordinate located at [index] in [part].
  ///
  /// ## Parameters
  ///
  /// - [index]: Index within the part.
  /// - [part]: Part index.
  ///
  /// ## Returns
  ///
  /// - The [Coordinates] object at the requested location. If the index or part are
  /// invalid then a coordinate with [Coordinates.isValid] false is returned.
  Coordinates getCoordinate(final int index, final int part) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'Marker',
      'getCoordinate',
      args: <String, dynamic>{'first': index, 'second': part},
    );
    return Coordinates.fromJson(resultString['result']);
  }

  static Marker _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{'class': 'Marker'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return Marker.init(decodedVal['result']);
  }

  static Marker _createFromCoords(final List<Coordinates> coordinates) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'Marker',
        'args': <String, Object>{'coordinates': coordinates},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return Marker.init(decodedVal['result']);
  }

  static Marker _createFromCircle(
    final Coordinates centerCoords,
    final double radius,
  ) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'Marker',
        'args': <String, Object>{'coordinates': centerCoords, 'radius': radius},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return Marker.init(decodedVal['result']);
  }

  static Marker _createFromCircleRadii(
    final Coordinates centerCoords,
    final double horizRadius,
    final double vertRadius,
  ) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'Marker',
        'args': <String, Object>{
          'coordinates': centerCoords,
          'horizRadius': horizRadius,
          'vertRadius': vertRadius,
        },
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return Marker.init(decodedVal['result']);
  }

  static Marker _createFromRectangle(
    final Coordinates topLeft,
    final Coordinates bottomRight,
  ) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'Marker',
        'args': <String, Object>{
          'topLeft': topLeft,
          'bottomRight': bottomRight,
        },
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return Marker.init(decodedVal['result']);
  }

  static Marker _createFromArea(final GeographicArea area) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'Marker',
        'args': <String, Object>{'area': area},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return Marker.init(decodedVal['result']);
  }
}
