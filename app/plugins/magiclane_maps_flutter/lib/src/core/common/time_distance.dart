// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Time and distance value object used for routing results.
///
/// [TimeDistance] separates unrestricted and restricted time/distance
/// components which allows callers to present more detailed ETA and routing
/// information (for example when parts of a route are subject to restrictions).
///
/// Instances are typically obtained from [NavigationInstruction] or
/// [RouteInstruction].
///
/// ## See also:
///
/// - [NavigationInstruction] - Obtain time and distance from/to various points
/// during navigation
/// - [RouteInstruction] - Obtain time and distance from/to various points from
/// route instructions
///
/// {@category Common}
class TimeDistance {
  /// Constructor with unrestricted and restricted times and distances
  ///
  /// The API user does not normally need to construct instances directly.
  ///
  /// ## Parameters
  ///
  /// - [unrestrictedTimeS]: Unrestricted time in seconds
  /// - [restrictedTimeS]: Restricted time in seconds
  /// - [unrestrictedDistanceM]: Unrestricted distance in meters
  /// - [restrictedDistanceM]: Restricted distance in meters
  /// - [ndBeginEndRatio]: Restricted begin/end ratio
  TimeDistance({
    this.unrestrictedTimeS = 0,
    this.restrictedTimeS = 0,
    this.unrestrictedDistanceM = 0,
    this.restrictedDistanceM = 0,
    this.ndBeginEndRatio = -1.0,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory TimeDistance.fromJson(final Map<String, dynamic> json) {
    return TimeDistance(
      unrestrictedTimeS: json['unrestrictedTimeS'] ?? 0,
      restrictedTimeS: json['restrictedTimeS'] ?? 0,
      unrestrictedDistanceM: json['unrestrictedDistanceM'] ?? 0,
      restrictedDistanceM: json['restrictedDistanceM'] ?? 0,
      ndBeginEndRatio: json['ndBeginEndRatio'] ?? -1.0,
    );
  }

  /// Unrestricted time in seconds.
  int unrestrictedTimeS;

  /// Restricted time in seconds
  int restrictedTimeS;

  /// Unrestricted distance in meters.
  int unrestrictedDistanceM;

  /// Restricted distance in meters
  int restrictedDistanceM;

  /// Restricted begin/end ratio.
  ///
  /// When >= 0 this value (0..1) splits restricted portions between the
  /// beginning and the end of the [TimeDistance]. A value of `-1` indicates no
  /// differentiation.
  double ndBeginEndRatio;

  /// Total time in seconds
  int get totalTimeS => unrestrictedTimeS + restrictedTimeS;

  /// Total distance in meters
  int get totalDistanceM => unrestrictedDistanceM + restrictedDistanceM;

  /// Check if empty (no travel time).
  bool get isEmpty => totalTimeS == 0;

  /// Check if not empty.
  bool get isNotEmpty => !isEmpty;

  /// Whether restricted begin/end differentiation is available.
  bool get hasRestrictedBeginEndDifferentiation => ndBeginEndRatio >= 0;

  /// Restricted time at begin (computed from [restrictedTimeS] and
  /// [ndBeginEndRatio]).
  int get restrictedTimeAtBegin {
    if (hasRestrictedBeginEndDifferentiation) {
      return (restrictedTimeS * (1 - ndBeginEndRatio)).round();
    }

    return 0;
  }

  /// Restricted time at end (computed from [restrictedTimeS] and
  /// [ndBeginEndRatio]).
  int get restrictedTimeAtEnd {
    if (hasRestrictedBeginEndDifferentiation) {
      return (restrictedTimeS * ndBeginEndRatio).round();
    }

    return 0;
  }

  /// Restricted distance at begin (computed from [restrictedDistanceM] and
  /// [ndBeginEndRatio]).
  int get restrictedDistanceAtBegin {
    if (hasRestrictedBeginEndDifferentiation) {
      return (restrictedDistanceM * (1 - ndBeginEndRatio)).round();
    }

    return 0;
  }

  /// Restricted distance at end (computed from [restrictedDistanceM] and
  /// [ndBeginEndRatio]).
  int get restrictedDistanceAtEnd {
    if (hasRestrictedBeginEndDifferentiation) {
      return (restrictedDistanceM * ndBeginEndRatio).round();
    }

    return 0;
  }

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['unrestrictedTimeS'] = unrestrictedTimeS;
    json['restrictedTimeS'] = restrictedTimeS;
    json['unrestrictedDistanceM'] = unrestrictedDistanceM;
    json['restrictedDistanceM'] = restrictedDistanceM;
    json['ndBeginEndRatio'] = ndBeginEndRatio;
    return json;
  }

  @override
  bool operator ==(covariant final TimeDistance other) {
    if (identical(this, other)) {
      return true;
    }

    return other.unrestrictedTimeS == unrestrictedTimeS &&
        other.restrictedTimeS == restrictedTimeS &&
        other.unrestrictedDistanceM == unrestrictedDistanceM &&
        other.restrictedDistanceM == restrictedDistanceM &&
        other.ndBeginEndRatio == ndBeginEndRatio;
  }

  @override
  int get hashCode {
    return Object.hash(
      unrestrictedTimeS,
      restrictedTimeS,
      unrestrictedDistanceM,
      restrictedDistanceM,
      ndBeginEndRatio,
    );
  }

  /// Adds two [TimeDistance] instances together.
  ///
  /// Parameters:
  ///
  /// - [other]: The other [TimeDistance] instance to add.
  ///
  /// Returns:
  ///
  /// - A new [TimeDistance] instance representing the sum of the two instances.
  TimeDistance operator +(final TimeDistance other) {
    return TimeDistance(
      unrestrictedTimeS: unrestrictedTimeS + other.unrestrictedTimeS,
      restrictedTimeS: restrictedTimeS + other.restrictedTimeS,
      unrestrictedDistanceM:
          unrestrictedDistanceM + other.unrestrictedDistanceM,
      restrictedDistanceM: restrictedDistanceM + other.restrictedDistanceM,
    );
  }
}
