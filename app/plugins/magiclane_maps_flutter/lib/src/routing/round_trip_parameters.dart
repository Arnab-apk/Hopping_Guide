// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/routing.dart';
import 'package:meta/meta.dart';

/// Round trip parameters
///
/// {@category Routing}
class RoundTripParameters {
  /// Creates a new instance of [RoundTripParameters].
  ///
  /// ## Parameters
  ///
  /// - [range]: Approximate desired size of the roundtrip; meaning is the same as for the route ranges feature.
  /// - [rangeType]: The units in which the range is expressed. Default means dependent on the route type like for Ranges. Other options are distance in meters and time in seconds.
  /// - [randomSeed]: If set to 0, generate a random route; any other number, use it as the seed for deterministic randomness.
  RoundTripParameters({
    required this.range,
    this.rangeType = RangeType.defaultType,
    this.randomSeed = 0,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory RoundTripParameters.fromJson(final Map<String, dynamic> json) {
    return RoundTripParameters(
      range: json['range'],
      rangeType: RangeTypeExtension.fromId(json['rangeType']),
      randomSeed: json['randomSeed'] ?? 0,
    );
  }

  /// Approximate desired size of the roundtrip; meaning is the same as for the route ranges feature.
  int range;

  /// The units in which the range is expressed. Default means dependent on the route type like for Ranges. Other options are distance in meters and time in seconds.
  RangeType rangeType;

  /// If set to 0, generate a random route; any other number, use it as the seed for deterministic randomness.
  int randomSeed;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'range': range,
      'rangeType': rangeType.id,
      'randomSeed': randomSeed,
    };
  }

  @override
  bool operator ==(covariant final RoundTripParameters other) {
    if (identical(this, other)) {
      return true;
    }

    return other.range == range &&
        other.rangeType == rangeType &&
        other.randomSeed == randomSeed;
  }

  @override
  int get hashCode {
    return Object.hash(range, rangeType, randomSeed);
  }
}
