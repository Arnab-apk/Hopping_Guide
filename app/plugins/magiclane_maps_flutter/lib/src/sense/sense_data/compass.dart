// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';

/// Compass sensor data providing directional heading.
///
/// Gives the device's heading relative to magnetic or true north using magnetometer data.
///
/// {@category Sensor Data Source}
abstract class Compass extends SenseData {
  /// The compass heading in degrees.
  ///
  /// ## Returns
  ///
  /// - [double]: Heading value in degrees (0-360).
  double get heading;

  /// The accuracy of the compass measurement.
  ///
  /// ## Returns
  ///
  /// - [CompassAccuracy]: The reliability level of the heading.
  CompassAccuracy get accuracy;
}

/// Accuracy levels for compass heading measurements.
///
/// Indicates the reliability of the directional heading provided by the compass sensor.
///
/// ## See also:
///
/// - [Compass] — Compass sensor data providing directional heading.
///
/// {@category Sensor Data Source}
enum CompassAccuracy {
  /// Compass accuracy is unknown or could not be determined.
  unknown,

  /// Low accuracy; directional heading may be unreliable.
  low,

  /// Medium accuracy; directional heading is moderately reliable but not highly precise.
  medium,

  /// High accuracy; directional heading is very reliable and precise.
  high,
}

/// @nodoc
extension CompassAccuracyExtension on CompassAccuracy {
  static CompassAccuracy fromId(final int value) {
    switch (value) {
      case 0:
        return CompassAccuracy.unknown;
      case 1:
        return CompassAccuracy.low;
      case 2:
        return CompassAccuracy.medium;
      case 3:
        return CompassAccuracy.high;
      default:
        throw ArgumentError('Invalid id');
    }
  }

  int get id {
    switch (this) {
      case CompassAccuracy.unknown:
        return 0;
      case CompassAccuracy.low:
        return 1;
      case CompassAccuracy.medium:
        return 2;
      case CompassAccuracy.high:
        return 3;
    }
  }
}
