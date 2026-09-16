// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:core';
import 'dart:math';

import 'package:meta/meta.dart';

/// Compare extension for Comparable types
///
/// Used internally. The API user should not use this extension directly.
///
/// @nodoc
extension Compare<T> on Comparable<T> {
  bool operator <=(final T other) => compareTo(other) <= 0;
  bool operator >=(final T other) => compareTo(other) >= 0;
  bool operator <(final T other) => compareTo(other) < 0;
  bool operator >(final T other) => compareTo(other) > 0;
}

/// A small value object holding X and Y coordinates.
///
/// Used internally. The API user should not use this class directly.
///
/// ## See also:
///
/// - [Point] - A standard Dart alternative.
///
/// @nodoc
class XyType<T extends num> {
  XyType({required this.x, required this.y});

  XyType.fromPoint(final Point<T> point) : x = point.x, y = point.y;

  /// Deserialize from JSON-compatible map
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory XyType.fromJson(final Map<String, dynamic> json) {
    return XyType<T>(x: json['x'] ?? 0, y: json['y'] ?? 0);
  }
  T x;
  T y;

  Point<T> get point => Point<T>(x, y);

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['x'] = x;
    json['y'] = y;
    return json;
  }

  @override
  bool operator ==(covariant final XyType<T> other) {
    if (identical(this, other)) {
      return true;
    }

    return other.x == x && other.y == y;
  }

  @override
  int get hashCode {
    return x.hashCode ^ y.hashCode;
  }
}

/// Rectangle-like value object with generic numeric coordinates.
///
/// Used internally. The API user should not use this class directly.
///
/// ## See also:
///
/// - [Rectangle] - A standard Dart alternative.
///
/// @nodoc
class RectType<T extends num> {
  RectType({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Deserialize from JSON-compatible map
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory RectType.fromJson(final Map<String, dynamic> json) {
    return RectType<T>(
      x: json['x'] ?? 0,
      y: json['y'] ?? 0,
      width: json['width'] ?? 0,
      height: json['height'] ?? 0,
    );
  }

  /// Create an object from a [Rectangle]
  factory RectType.fromRectangle(final Rectangle<T> rectangle) => RectType<T>(
    x: rectangle.left,
    y: rectangle.top,
    width: rectangle.width,
    height: rectangle.height,
  );
  T x;
  T y;
  T width;
  T height;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['x'] = x;
    json['y'] = y;
    json['width'] = width;
    json['height'] = height;
    return json;
  }

  @override
  bool operator ==(covariant final RectType<T> other) {
    if (identical(this, other)) {
      return true;
    }

    return other.x == x &&
        other.y == y &&
        other.width == width &&
        other.height == height;
  }

  /// Transform the object to a [Rectangle]
  Rectangle<T> get toRectangle => Rectangle<T>(x, y, width, height);

  @override
  int get hashCode {
    return x.hashCode ^ y.hashCode ^ width.hashCode ^ height.hashCode;
  }
}

/// RGBA colour value used for serialisation
///
/// Used internally. The API user should not use this class directly.
///
/// ## See also:
///
/// - [Color] - A standard Dart alternative.
///
/// @nodoc
class Rgba {
  Rgba({this.r = 0, this.g = 0, this.b = 0, this.a = 255});

  factory Rgba.fromDoubleValue({
    required final double r,
    required final double g,
    required final double b,
    final double a = 1.0,
  }) {
    return Rgba(
      r: (r * 255).toInt(),
      g: (g * 255).toInt(),
      b: (b * 255).toInt(),
      a: (a * 255).toInt(),
    );
  }

  factory Rgba.transparent() {
    return Rgba(a: 0);
  }

  /// Deserialize from JSON-compatible map
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory Rgba.fromJson(final Map<String, dynamic> json) {
    return Rgba(r: json['r'], g: json['g'], b: json['b'], a: json['a']);
  }
  int r;
  int g;
  int b;
  int a;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['r'] = r;
    json['g'] = g;
    json['b'] = b;
    json['a'] = a;
    return json;
  }

  @override
  bool operator ==(covariant final Rgba other) {
    if (identical(this, other)) {
      return true;
    }
    return r == other.r && g == other.g && b == other.b && a == other.a;
  }

  @override
  int get hashCode {
    return r.hashCode ^ g.hashCode ^ b.hashCode ^ a.hashCode;
  }

  @override
  String toString() {
    return 'Rgba(r: $r, g: $g, b: $b, a: $a)';
  }
}

/// Simple generic pair container.
///
/// Used internally. The API user should not use this class directly.
/// Use the tuple already provided by Dart instead.
///
/// @nodoc
class Pair<T1, T2> {
  /// Constructor for the pair class.
  Pair(this.first, this.second);

  /// First element.
  final T1 first;

  /// Second element.
  final T2 second;

  @override
  bool operator ==(covariant final Pair<T1, T2> other) {
    if (identical(this, other)) {
      return true;
    }
    return first == other.first && second == other.second;
  }

  @override
  int get hashCode => first.hashCode ^ second.hashCode;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'first': first, 'second': second};
  }
}

/// @nodoc
class NativeObject {
  NativeObject(this.address, this.length);
  dynamic address;
  int length;
}
