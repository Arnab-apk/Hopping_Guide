// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';

/// Temperature severity levels.
///
/// Categorizes temperature readings into severity bands, useful for thermal
/// management and device safety monitoring.
///
/// ## See also:
///
/// - [Temperature] — Temperature sensor data.
///
/// {@category Sensor Data Source}
enum TemperatureLevel {
  /// Temperature level is unknown or could not be determined.
  unknown,

  /// Temperature level is normal (within safe operating range).
  normal,

  /// Fair temperature level (degrees > 35°C and ≤ 45°C).
  fair,

  /// Serious temperature level (degrees > 45°C and ≤ 55°C).
  serious,

  /// Critical temperature level (degrees > 55°C and ≤ 65°C).
  critical,

  /// Device is shutting down due to dangerously high temperature (degrees > 65°C).
  shuttingDown,
}

/// @nodoc
extension TemperatureLevelExtension on TemperatureLevel {
  static TemperatureLevel fromId(final int value) {
    switch (value) {
      case 0:
        return TemperatureLevel.unknown;
      case 1:
        return TemperatureLevel.normal;
      case 2:
        return TemperatureLevel.fair;
      case 3:
        return TemperatureLevel.serious;
      case 4:
        return TemperatureLevel.critical;
      case 5:
        return TemperatureLevel.shuttingDown;
      default:
        throw ArgumentError('Invalid id');
    }
  }

  int get id {
    switch (this) {
      case TemperatureLevel.unknown:
        return 0;
      case TemperatureLevel.normal:
        return 1;
      case TemperatureLevel.fair:
        return 2;
      case TemperatureLevel.serious:
        return 3;
      case TemperatureLevel.critical:
        return 4;
      case TemperatureLevel.shuttingDown:
        return 5;
    }
  }
}

/// Temperature sensor data.
///
/// Provides temperature readings, either ambient or internal device temperature,
/// along with a severity level indicator.
///
/// {@category Sensor Data Source}
abstract class Temperature extends SenseData {
  /// The temperature value in Celsius.
  ///
  /// ## Returns
  ///
  /// - [double]: Temperature in degrees Celsius.
  double get temperature;

  /// The severity level of the current temperature.
  ///
  /// ## Returns
  ///
  /// - [TemperatureLevel]: The categorized temperature level.
  TemperatureLevel get level;
}
