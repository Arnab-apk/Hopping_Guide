// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:ui';

import 'package:magiclane_maps_flutter/src/core/private/types.dart';
import 'package:meta/meta.dart';

/// Extension methods for [Color]
///
/// Used internally for serialization/deserialization.
///
/// @nodoc
extension ColorExtension on Color {
  /// Serializes [Color] to JSON-compatible map
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() => <String, double>{
    'r': r,
    'g': g,
    'b': b,
    'a': a,
  };

  /// Convert [Color] to GemKit [Rgba] class
  Rgba toRgba() => Rgba(
    r: (r * 255).toInt(),
    g: (g * 255).toInt(),
    b: (b * 255).toInt(),
    a: (a * 255).toInt(),
  );

  /// Deserialize [Color] from JSON-compatible map
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  static Color fromJson(final Map<String, dynamic> json) =>
      Color.fromARGB(json['a'], json['r'], json['g'], json['b']);

  /// Deserialize [Color] from JSON-compatible map, returning transparent color on error
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  static Color tryFromJson(final Map<String, dynamic>? json) {
    if (json == null) {
      return const Color(0x00000000);
    }
    try {
      return fromJson(json);
    } catch (e) {
      return const Color(0x00000000);
    }
  }
}
