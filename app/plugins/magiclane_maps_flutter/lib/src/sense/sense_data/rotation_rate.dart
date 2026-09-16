// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';

/// Gyroscope rotation rate sensor data.
///
/// Measures the rate of rotation around the device's axes. Used to detect turns and
/// angular movement.
///
/// {@category Sensor Data Source}
abstract class RotationRate extends SenseData {
  /// The rotation rate around the X axis.
  ///
  /// ## Returns
  ///
  /// - [double]: Rotation rate in radians per second (rad/s).
  double get x;

  /// The rotation rate around the Y axis.
  ///
  /// ## Returns
  ///
  /// - [double]: Rotation rate in radians per second (rad/s).
  double get y;

  /// The rotation rate around the Z axis.
  ///
  /// ## Returns
  ///
  /// - [double]: Rotation rate in radians per second (rad/s).
  double get z;
}
