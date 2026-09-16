// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:typed_data';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/map/map_view_path_collection.dart';
import 'package:meta/meta.dart';

/// Supported file formats for importing and exporting [Path] data.
///
/// Use these values with [Path.create] and [Path.exportAs] to control the
/// serialization format (for example GPX, KML or GeoJSON).
///
/// ## See also:
///
/// - [Path.create]
/// - [Path.exportAs]
///
/// {@category Geographic}
enum PathFileFormat {
  /// GPX format.
  gpx,

  /// KML format.
  kml,

  /// NMEA format.
  nmea,

  /// GeoJSON format.
  geoJson,

  /// Latitude, Longitude lines in txt file (debug purposes).
  latLonTxt,

  /// Longitude, Latitude lines in txt file (debug purposes).
  lonLatTxt,

  /// PackedGeometry
  packedGeometry,

  /// Google polyline format
  polyline,
}

/// @nodoc
extension PathFileFormatExtension on PathFileFormat {
  int get id {
    switch (this) {
      case PathFileFormat.gpx:
        return 0;
      case PathFileFormat.kml:
        return 1;
      case PathFileFormat.nmea:
        return 2;
      case PathFileFormat.geoJson:
        return 3;
      case PathFileFormat.latLonTxt:
        return 4;
      case PathFileFormat.lonLatTxt:
        return 5;
      case PathFileFormat.packedGeometry:
        return 6;
      case PathFileFormat.polyline:
        return 7;
    }
  }

  static PathFileFormat fromId(final int id) {
    switch (id) {
      case 0:
        return PathFileFormat.gpx;
      case 1:
        return PathFileFormat.kml;
      case 2:
        return PathFileFormat.nmea;
      case 3:
        return PathFileFormat.geoJson;
      case 4:
        return PathFileFormat.latLonTxt;
      case 5:
        return PathFileFormat.lonLatTxt;
      case 6:
        return PathFileFormat.packedGeometry;
      case 7:
        return PathFileFormat.polyline;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Represents a path object containing an ordered list of geographic coordinates.
///
/// A [Path] can be constructed from an in-memory list of [Coordinates] or
/// by importing a binary file (GPX, KML, GeoJSON, etc.). It provides
/// read-only access to its coordinates and waypoints and utility methods for
/// cloning, exporting and converting to landmarks.
///
///
/// ## See also:
///
/// - [PathFileFormat] for supported import/export formats.
/// - [MapViewPathCollection] for displaying multiple paths on a map.
///
/// {@category Geographic}
class Path extends GemAutoreleaseObject {
  /// Creates a [Path] from a list of coordinates and waypoints, with an optional name.
  ///
  /// ## Parameters
  ///
  /// - [coordinates]: The list of [Coordinates] defining the path. Defaults to an empty list.
  /// - [waypoints]: A list of integer indices referencing positions in [coordinates]. Defaults
  /// to an empty list.
  /// - [name]: An optional human readable name for the path. Defaults to an empty string.
  ///
  /// ## Returns
  ///
  /// - A new [Path] instance containing the provided coordinates, waypoints, and name
  factory Path({
    final List<Coordinates> coordinates = const <Coordinates>[],
    final List<int> waypoints = const <int>[],
    final String name = '',
  }) {
    final Path path = Path.fromCoordinatesWaypoints(
      coordinates: coordinates,
      waypoints: waypoints,
    );
    path.name = name;
    return path;
  }

  /// Creates a [Path] by importing binary data in a supported format.
  ///
  /// The [data] bytes contain the file contents (for example a GPX or KML
  /// file). The [format] controls how the bytes are interpreted. The returned
  /// [Path] instance is backed by the native SDK representation.
  ///
  /// ## Parameters
  ///
  /// - [data]: Binary file contents as a [Uint8List].
  /// - [format]: Optional [PathFileFormat] describing the data format. Defaults to [PathFileFormat.gpx].
  ///
  /// ## Returns
  ///
  /// - A new [Path] instance created from the provided data.
  factory Path.create({
    required final Uint8List data,
    final PathFileFormat format = PathFileFormat.gpx,
  }) {
    final dynamic nativeBuffer = GemKitPlatform.instance.toNativePointer(data);
    final dynamic resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'Path',
        'args': <String, dynamic>{
          'data': nativeBuffer.address,
          'dataLength': data.length,
          'format': format.id,
        },
      }),
    );
    GemKitPlatform.instance.freeNativePointer(nativeBuffer);
    final dynamic decodedVal = jsonDecode(resultString);

    return Path.init(decodedVal['result']);
  }

  /// Create a path from list of coordinates and waypoints.
  ///
  /// Creates a [Path] from a list of [Coordinates] and a list of waypoint indices.
  ///
  /// Waypoints are indices into the [coordinates] list
  ///
  /// ## Parameters
  ///
  /// - [coordinates]: The list of [Coordinates] defining the path.
  /// - [waypoints]: A list of integer indices referencing positions in [coordinates].
  ///
  /// ## Returns
  ///
  /// - A new [Path] instance containing the provided coordinates and waypoints.
  factory Path.fromCoordinatesWaypoints({
    required List<Coordinates> coordinates,
    required List<int> waypoints,
  }) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'Path',
        'args': <String, dynamic>{
          'coords': coordinates,
          'waypoints': waypoints,
        },
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);

    return Path.init(decodedVal['result']);
  }

  /// Create a path from a list of coordinates.
  ///
  /// Creates a [Path] from a list of [Coordinates].
  ///
  /// This is the most convenient constructor when you already have the
  /// coordinates available.
  ///
  /// ## Parameters
  ///
  /// - [coords]: The ordered list of [Coordinates] that make up the path.
  factory Path.fromCoordinates(final List<Coordinates> coords) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'Path',
        'args': <String, dynamic>{'coords': coords},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);

    return Path.init(decodedVal['result']);
  }
  // ignore: unused_element
  Path._() : super(-1);

  @internal
  Path.init(super.id);

  /// Clone reverse order path. Does not change the original path.
  /// Returns a new [Path] with the coordinate order reversed.
  ///
  /// The original [Path] is not modified.
  ///
  /// ## Returns
  ///
  /// - A new [Path] whose coordinates run in the reverse order of this path.
  Path cloneReverse() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Path',
      'cloneReverse',
    );

    return Path.init(resultString['result']);
  }

  /// Clone path from the given coordinates.
  ///
  /// Set start = end to create a circuit track.
  ///
  /// Creates a cloned [Path] using the provided [start] and [end] coordinates.
  ///
  /// If [start] and [end] are equal the resulting path will form a circuit.
  ///
  /// ## Parameters
  ///
  /// - [start]: The new starting [Coordinates].
  /// - [end]: The new ending [Coordinates].
  ///
  /// ## Returns
  ///
  /// - A new [Path] instance cloned from this path with the specified start and end coordinates.
  Path cloneStartEnd(final Coordinates start, final Coordinates end) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Path',
      'cloneStartEnd',
      args: <String, Coordinates>{'first': start, 'second': end},
    );

    return Path.init(resultString['result']);
  }

  /// Export path coordinates in the requested data format.
  ///
  /// Serializes the path into a textual representation using the given format.
  ///
  /// The returned string contains the full file content in the requested
  /// [PathFileFormat] (for example a GPX or GeoJSON document) and is suitable
  /// for writing to disk or sharing with other applications.
  ///
  /// ## Parameters
  ///
  /// - [pathFileFormat]: The target [PathFileFormat] to export as.
  ///
  /// ## Returns
  ///
  /// - A [String] containing the exported path data encoded in the chosen format.
  String exportAs(final PathFileFormat pathFileFormat) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Path',
      'exportAs',
      args: pathFileFormat.id,
    );

    final String encodedResult = resultString['result'];
    final Uint8List resultAsUint8List = base64Decode(encodedResult);
    final String result = utf8.decode(resultAsUint8List);

    return result;
  }

  /// Get path rectangle.
  ///
  /// The geographic bounding rectangle that contains this path.
  ///
  /// ## Returns
  ///
  /// - A [RectangleGeographicArea] describing the geographic area covered by the path.
  /// If the path contains no coordinates, an empty area with [RectangleGeographicArea.isDefault]
  /// set to `true` is returned.
  RectangleGeographicArea get area {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Path',
      'getArea',
    );

    return RectangleGeographicArea.fromJson(resultString['result']);
  }

  /// Get read-only access to the internal coordinates list.
  ///
  /// Read-only access to the list of [Coordinates] composing this path.
  ///
  /// Modifying the returned list does not affect the current object.
  ///
  /// ## Returns
  ///
  /// - A [List<Coordinates>] with the path's coordinates in order.
  List<Coordinates> get coordinates {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Path',
      'getCoordinates',
    );

    final List<dynamic> listJson = resultString['result'];
    final List<Coordinates> retList = listJson
        .map((final dynamic categoryJson) => Coordinates.fromJson(categoryJson))
        .toList();
    return retList;
  }

  /// Get a coordinate along the path given by a fraction of the path length between 0.0 (departure point) and 1.0 (destination).
  ///
  /// Calculates the [Coordinates] at the given [percent] along a path
  /// described by [coords]. The percent is a fraction in the range `0.0..1.0`
  /// where `0.0` represents the path start and `1.0` the path end.
  ///
  /// ## Parameters
  ///
  /// - [coords]: The list of [Coordinates] that define the path geometry.
  /// - [percent]: A double in the range 0.0..1.0 indicating the position along the path.
  ///
  /// ## Returns
  ///
  /// - The interpolated [Coordinates] at the requested percentage of the path.
  static Coordinates getCoordinatesAtPercent(
    final List<Coordinates> coords,
    final double percent,
  ) {
    final OperationResult resultString = staticMethod(
      'Path',
      'getCoordinatesAtPercent',
      args: <String, Object>{'coords': coords, 'percent': percent},
    );

    return Coordinates.fromJson(resultString['result']);
  }

  /// Get path name.
  ///
  /// The human readable name of the path.
  ///
  /// This value may be empty if no name has been set.
  ///
  /// ## Returns
  ///
  /// - The path name as a [String].
  String get name {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Path',
      'getName',
    );

    return resultString['result'];
  }

  /// Get read-only access to the internal waypoint list.
  ///
  /// Read-only access to the list of waypoint indices for this path.
  ///
  /// Waypoints are expressed as integer indices that reference positions in
  /// [coordinates].
  ///
  /// ## Returns
  ///
  /// - A [List<int>] containing waypoint indices.
  List<int> get wayPoints {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Path',
      'getWayPoints',
    );

    final List<int> listJson = (resultString['result'] as List<dynamic>)
        .map((final dynamic item) => item as int)
        .toList();
    return listJson;
  }

  /// Set path name.
  ///
  /// Sets the human readable name for this path.
  ///
  /// ## Parameters
  ///
  /// - [name]: The new name for the path.
  set name(final String name) {
    objectMethod(pointerId, 'Path', 'setName', args: name);
  }

  /// Create a new landmark list from a path.
  ///
  /// Converts this path into a list of [Landmark] objects.
  ///
  /// This is useful when you want to compute path-based routes.
  ///
  /// ## Returns
  ///
  /// - A [List<Landmark>] representing the path as landmarks.
  @Deprecated('Use landmarkList getter instead')
  List<Landmark> toLandmarkList() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Path',
      'toLandmarkList',
    );

    return LandmarkList.init(resultString['result']).toList();
  }

  /// Create a new landmark list from a path.
  ///
  /// Converts this path into a list of [Landmark] objects.
  ///
  /// This is useful when you want to compute path-based routes.
  ///
  /// ## Returns
  ///
  /// - A [List<Landmark>] representing the path as landmarks.
  List<Landmark> get landmarkList {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Path',
      'toLandmarkList',
    );

    return LandmarkList.init(resultString['result']).toList();
  }
}

/// Represents a match result when performing a hit test on a [MapViewPathCollection].
///
/// {@category Geographic}
class PathMatch {
  PathMatch({
    required this.path,
    required this.coords,
    required this.distance,
    required this.segment,
  });

  /// Deserializes a [PathMatch] instance from a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory PathMatch.fromJson(Map<String, dynamic> json) {
    return PathMatch(
      path: json['path'],
      coords: Coordinates.fromJson(json['coords']),
      distance: json['distance'],
      segment: json['segment'],
    );
  }

  /// Matched path index in the path collection.
  int path;

  /// Coordinates of the matched position along the path.
  Coordinates coords;

  /// Distance in meters from the tested location to the matched position.
  int distance;

  /// The segment index within the path where the match occurred.
  int segment;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'path': path,
      'coords': coords.toJson(),
      'distance': distance,
      'segment': segment,
    };
  }

  @override
  bool operator ==(covariant PathMatch other) {
    if (identical(this, other)) {
      return true;
    }
    return path == other.path &&
        coords == other.coords &&
        distance == other.distance &&
        segment == other.segment;
  }

  @override
  int get hashCode =>
      path.hashCode ^ coords.hashCode ^ distance.hashCode ^ segment.hashCode;
}
