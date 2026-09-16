// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// 3D point value object.
///
/// Small container for three double-precision coordinates.
/// Used usually by the [MapCamera] class.
///
/// ## Also see:
///
/// - [Point4d] - For 4D point/quaternion-like values
/// - [Coordinates] - For geographic coordinates
///
/// {@category Common}
class Point3d {
  /// Constructor for the point class.
  Point3d({this.x = 0.0, this.y = 0.0, this.z = 0.0});

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory Point3d.fromJson(final Map<String, dynamic> json) {
    return Point3d(x: json['x'], y: json['y'], z: json['z']);
  }

  /// The value on the X axis
  double x;

  /// The value on the Y axis
  double y;

  /// The value on the Z axis
  double z;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['x'] = x;
    json['y'] = y;
    json['z'] = z;
    return json;
  }

  @override
  String toString() {
    return 'Point3d(x: $x, y: $y, z: $z)';
  }

  @override
  bool operator ==(covariant final Point3d other) {
    if (identical(this, other)) {
      return true;
    }

    return other.x == x && other.y == y && other.z == z;
  }

  @override
  int get hashCode {
    return x.hashCode ^ y.hashCode ^ z.hashCode;
  }
}

/// 4D point / quaternion-like value object.
///
/// Stores four double-precision values commonly used for rotations or
/// homogeneous coordinates. Named `Point4d` for simplicity; treat `w`
/// according to your domain (often a quaternion scalar component).
///
/// Used usually by the [MapCamera] class.
///
/// ## Also see:
///
/// - [Point3d] - For 3D point/position values
/// - [Coordinates] - For geographic coordinates
///
/// {@category Common}
class Point4d {
  /// Constructor for the point class.
  Point4d({this.x = 0.0, this.y = 0.0, this.z = 0.0, this.w = 0.0});

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory Point4d.fromJson(final Map<String, dynamic> json) {
    return Point4d(x: json['x'], y: json['y'], z: json['z'], w: json['w']);
  }

  /// The value on the X axis
  double x;

  /// The value on the Y axis
  double y;

  /// The value on the Z axis
  double z;

  /// The value on the W axis
  double w;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['x'] = x;
    json['y'] = y;
    json['z'] = z;
    json['w'] = w;
    return json;
  }

  @override
  String toString() {
    return 'Point4d(x: $x, y: $y, z: $z, w: $w)';
  }

  @override
  bool operator ==(covariant final Point4d other) {
    if (identical(this, other)) {
      return true;
    }

    return other.x == x && other.y == y && other.z == z && other.w == w;
  }

  @override
  int get hashCode {
    return x.hashCode ^ y.hashCode ^ z.hashCode ^ w.hashCode;
  }
}

/// Position and orientation pair used by spatial APIs.
///
/// Combines a 3D position and a 4D orientation into a single container.
/// Useful for [MapCamera] and other spatial APIs.
///
/// {@category Common}
class PositionOrientation {
  /// Constructor for the class.
  ///
  /// ## Parameters
  ///
  /// - [position]: The object position
  /// - [orientation]: The object orientation
  PositionOrientation({required this.position, required this.orientation});

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory PositionOrientation.fromJson(final Map<String, dynamic> json) {
    return PositionOrientation(
      position: Point3d.fromJson(json['position']),
      orientation: Point4d.fromJson(json['orientation']),
    );
  }

  /// The object position
  Point3d position;

  /// The object orientation
  Point4d orientation;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['position'] = position.toJson();
    json['orientation'] = orientation.toJson();
    return json;
  }

  @override
  String toString() {
    return 'PositionOrientation(position: $position, orientation: $orientation)';
  }

  @override
  bool operator ==(covariant final PositionOrientation other) {
    if (identical(this, other)) {
      return true;
    }

    return other.position == position && other.orientation == orientation;
  }

  @override
  int get hashCode {
    return position.hashCode ^ orientation.hashCode;
  }
}
