// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';

/// Acceleration sensor data in three-dimensional space.
///
/// Measures linear movement of the device along the X, Y, and Z axes. Useful for
/// detecting motion, steps, or sudden changes in speed.
///
/// {@category Sensor Data Source}
abstract class Acceleration extends SenseData {
  /// The acceleration along the X axis.
  ///
  /// ## Returns
  ///
  /// - [double]: Acceleration value in the specified [unit].
  double get x;

  /// The acceleration along the Y axis.
  ///
  /// ## Returns
  ///
  /// - [double]: Acceleration value in the specified [unit].
  double get y;

  /// The acceleration along the Z axis.
  ///
  /// ## Returns
  ///
  /// - [double]: Acceleration value in the specified [unit].
  double get z;

  /// The unit of measurement for acceleration values.
  ///
  /// ## Returns
  ///
  /// - [UnitOfMeasurementAcceleration]: The unit (e.g., g-force).
  UnitOfMeasurementAcceleration get unit;
}
