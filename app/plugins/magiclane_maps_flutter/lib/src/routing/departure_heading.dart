// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Departure heading
///
/// Contains information about the direction the user is facing.
///
/// {@category Routing}
class DepartureHeading {
  const DepartureHeading({this.heading = -1, this.accuracy = 0});

  /// Creates an instance from a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  factory DepartureHeading.fromJson(final Map<String, dynamic> json) {
    return DepartureHeading(heading: json['first'], accuracy: json['second']);
  }

  /// The departure heading in degrees.
  ///
  /// Values are in 0 - 360 interval with 0 representing the magnetic north.
  /// Value -1 means no departure heading is specified
  final double heading;

  /// The departure heading accuracy, in degrees.
  ///
  /// Values are in 0 - 90 interval. A typical value is 25 degrees
  final double accuracy;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    return <String, double>{'first': heading, 'second': accuracy};
  }

  @override
  bool operator ==(covariant final DepartureHeading other) {
    return other.heading == heading && other.accuracy == accuracy;
  }

  @override
  int get hashCode => heading.hashCode ^ accuracy.hashCode;
}
