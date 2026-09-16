// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:typed_data';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// A collection that holds markers of the same visual style and geometry.
///
/// [MarkerCollection] groups markers that share the same [MarkerType] and provides
/// operations to add, remove, query and perform hit-testing on markers.
///
/// Collections are the unit presented on a map view via [MapViewMarkerCollections]
/// and are commonly customized with [MarkerCollectionRenderSettings].
///
/// ## Example:
/// ```dart
/// final collection = MarkerCollection(markerType: MarkerType.point, name: 'POIs');
/// collection.add(Marker()..add(Coordinates(latitude: 52.0, longitude: 4.0)));
/// mapController.preferences.markers.add(collection);
/// ```
///
/// ## See also:
/// - [MapViewMarkerCollections] for displaying collections on a map view.
/// - [MarkerCollectionRenderSettings] for customizing the rendering of collections.
/// - [MarkerSketches] for an alternative collection with rich styling, allowing for
///  advanced visual customization.
///
/// {@category Markers}
class MarkerCollection extends GemAutoreleaseObject {
  /// Create a new [MarkerCollection].
  ///
  /// ## Parameters
  ///
  /// - [markerType]: The kind of marker geometry stored by this collection.
  /// - [name]: A human readable name for the collection.
  ///
  /// ## Returns
  ///
  /// - A new [MarkerCollection] instance that can be added to [MapViewMarkerCollections].
  factory MarkerCollection({
    required final MarkerType markerType,
    required final String name,
  }) {
    return MarkerCollection._create(0, markerType, name);
  }

  @internal
  MarkerCollection.init(super.id, final int mapId) : _mapId = mapId;
  final int _mapId;

  int get mapId => _mapId;

  /// Remove all markers from this collection.
  void clear() {
    objectMethod(pointerId, 'MarkerCollection', 'clear');
  }

  /// Add a marker to this collection.
  ///
  /// The optional [index] parameter inserts the marker at a specific position; by
  /// default the marker is appended to the end of the collection.
  ///
  /// ## Parameters
  ///
  /// - [marker]: The [Marker] instance to add.
  /// - [index]: Optional insert position. Use -1 to append (default).
  void add(final Marker marker, {final int index = -1}) {
    objectMethod(pointerId, 'MarkerCollection', 'add', args: marker.pointerId);
  }

  /// Return the index of [marker] in this collection.
  ///
  /// ## Parameters
  ///
  /// - [marker]: The marker to search for.
  ///
  /// ## Returns
  ///
  /// - The zero-based index of the marker, or -1 if not found.
  int indexOf(final Marker marker) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerCollection',
      'indexOf',
      args: marker.pointerId,
    );

    return resultString['result'];
  }

  /// Remove the marker at [index] from this collection.
  ///
  /// ## Parameters
  ///
  /// - [index]: Index of the marker to delete.
  void delete(final int index) {
    objectMethod(pointerId, 'MarkerCollection', 'del', args: index);
  }

  /// The geographic bounding rectangle that encloses all markers in the collection.
  ///
  /// ## Returns
  ///
  /// - A [RectangleGeographicArea] that contains the collection's extent.
  /// If the collection does not contain any markers with coordinates, an empty
  /// area with [RectangleGeographicArea.isDefault] set to `true` is returned.
  RectangleGeographicArea get area {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerCollection',
      'getArea',
    );

    return RectangleGeographicArea.fromJson(resultString['result']);
  }

  /// The unique identifier assigned to this collection.
  ///
  /// ## Returns
  ///
  /// - An integer id.
  int get id {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerCollection',
      'getId',
    );

    return resultString['result'];
  }

  /// Retrieve the marker at [index].
  ///
  /// ## Parameters
  ///
  /// - [index]: Index of the marker to retrieve.
  ///
  /// ## Returns
  ///
  /// - The [Marker] at the given index, or `null` if the index is out of range.
  Marker? getMarkerAt(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerCollection',
      'getMarkerAt',
      args: index,
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return Marker.init(resultString['result']);
  }

  /// Find a marker in the collection by its unique id.
  ///
  /// ## Parameters
  ///
  /// - [id]: The marker id to search for.
  ///
  /// ## Returns
  ///
  /// - The matching [Marker], or `null` if no marker with that id exists.
  Marker? getMarkerById(final int id) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerCollection',
      'getMarkerById',
      args: id,
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return Marker.init(resultString['result']);
  }

  /// Get the head marker for the points group that contains [markerId].
  ///
  /// This requires the collection to be configured for points group rendering on the map
  /// (see [MarkerCollectionRenderSettings.buildPointsGroupConfig]). If group information
  /// is not available the API may return a reference to the queried marker and set an
  /// error status.
  ///
  /// ## Parameters
  ///
  /// - [markerId]: An id of a marker that belongs to the group.
  ///
  /// ## Returns
  ///
  /// - The group head [Marker], or `null` when not available.
  ///
  /// ## See also:
  ///
  /// - [getPointsGroupComponents] to retrieve the members of a points group.
  Marker? getPointsGroupHead(final int markerId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerCollection',
      'getPointsGroupHead',
      args: markerId,
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return Marker.init(resultString['result']);
  }

  /// Return the components (members) of a points group identified by [groupId].
  ///
  /// The collection must be configured with points group info available on the map
  /// (see [MarkerCollectionRenderSettings.buildPointsGroupConfig]). The returned list
  /// does **not** include the group head marker.
  ///
  /// ## Parameters
  ///
  /// - [groupId]: The id of the points group (usually the id returned by [getPointsGroupHead]).
  ///
  /// ## Returns
  ///
  /// - A [List<Marker>] containing the group members, or an empty list if none are found.
  ///
  /// ## See also:
  ///
  /// - [getPointsGroupHead] to retrieve the head marker of a points group.
  List<Marker> getPointsGroupComponents(final int groupId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerCollection',
      'getPointsGroupComponents',
      args: groupId,
    );

    return MarkerList.init(resultString['result']).toList();
  }

  /// The collection's human-readable name.
  ///
  /// ## Returns
  ///
  /// - The current collection name as a [String].
  String get name {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerCollection',
      'getName',
    );

    return resultString['result'];
  }

  /// Number of markers contained in this collection.
  ///
  /// ## Returns
  ///
  /// - An integer representing the collection size.
  int get size {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerCollection',
      'size',
    );

    return resultString['result'];
  }

  /// The [MarkerType] of markers stored in this collection.
  ///
  /// ## Returns
  ///
  /// - The marker type (point, polyline, polygon).
  MarkerType get type {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerCollection',
      'getType',
    );

    return MarkerTypeExtension.fromId(resultString['result']);
  }

  /// Set the collection's name.
  ///
  /// ## Parameters
  ///
  /// - [name]: New name for the collection.
  set name(final String name) {
    objectMethod(pointerId, 'MarkerCollection', 'setName', args: name);
  }

  /// Perform a hit test against all markers in this collection.
  ///
  /// Returns matches (see [MarkerMatch]) describing markers that intersect the
  /// provided geographic [coordinates]. An optional [ignoreMarker] may be supplied
  /// to exclude a specific marker from the test.
  ///
  /// ## Parameters
  ///
  /// - [coordinates]: Location used for the hit test.
  /// - [ignoreMarker]: Optional marker to ignore during hit testing.
  ///
  /// ## Returns
  ///
  /// - A [List<MarkerMatch>] describing the matched markers.
  List<MarkerMatch> hitTest(Coordinates coordinates, {Marker? ignoreMarker}) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerCollection',
      'hitTest',
      args: <String, Object>{
        'coords': coordinates,
        if (ignoreMarker != null) 'ignoreMarker': ignoreMarker.pointerId,
      },
    );
    return MarkerMatchList.init(resultString['result']).toList();
  }

  /// Serialize this collection to a binary buffer.
  ///
  /// The returned buffer can be later deserialized with [load].
  ///
  /// ## Returns
  ///
  /// - A [Uint8List] containing the serialized data on success, or `null` on error.
  ///
  /// ## See also:
  ///
  /// - [load] to deserialize a collection from a binary buffer.
  Uint8List? save() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MarkerCollection',
      'save',
    );

    if (resultString['gemApiError'] != 0) {
      return null;
    }

    final String encodedResult = resultString['result'];
    final Uint8List resultAsUint8List = base64Decode(encodedResult);
    return resultAsUint8List;
  }

  /// Deserialize a [MarkerCollection] from a binary buffer previously returned by [save].
  ///
  /// ## Parameters
  ///
  /// - [buffer]: Binary buffer containing a serialized marker collection.
  ///
  /// ## Returns
  ///
  /// - A new [MarkerCollection] on success, or `null` if deserialization failed.
  ///
  /// ## See also:
  ///
  /// - [save] to serialize a collection to a binary buffer.
  static MarkerCollection? load(Uint8List buffer) {
    final dynamic dataBufferPointer = GemKitPlatform.instance.toNativePointer(
      buffer,
    );
    final OperationResult resultString = staticMethod(
      'MarkerCollection',
      'load',
      args: <String, dynamic>{
        'dataBuffer': dataBufferPointer.address,
        'dataBufferSize': buffer.length,
      },
    );

    if (resultString['gemApiError'] != 0) {
      return null;
    }

    return MarkerCollection.init(resultString['result'], 0);
  }

  static MarkerCollection _create(
    final int mapId,
    final MarkerType markerType,
    final String name,
  ) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'MarkerCollection',
        'args': <String, dynamic>{
          'mapId': mapId,
          'type': markerType.id,
          'name': name,
        },
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return MarkerCollection.init(decodedVal['result'], mapId);
  }
}

/// The type of geometry represented by markers in a collection.
///
/// Use the type when creating a [MarkerCollection] to select how markers are
/// interpreted and rendered (point, polyline or polygon).
///
/// {@category Markers}
enum MarkerType {
  /// Multi-point marker
  point,

  /// Polyline marker
  polyline,

  /// Polygon marker
  polygon,
}

/// {@category Markers}
extension MarkerTypeExtension on MarkerType {
  int get id {
    switch (this) {
      case MarkerType.point:
        return 0;
      case MarkerType.polyline:
        return 1;
      case MarkerType.polygon:
        return 2;
    }
  }

  static MarkerType fromId(final int id) {
    switch (id) {
      case 0:
        return MarkerType.point;
      case 1:
        return MarkerType.polyline;
      case 2:
        return MarkerType.polygon;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
