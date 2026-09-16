// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';

/// Magnetic field sensor data.
///
/// Reports raw magnetic field strength along three axes. Useful for environmental
/// sensing or heading correction.
///
/// {@category Sensor Data Source}
abstract class MagneticField extends SenseData {
  /// The magnetic field strength along the X axis in microteslas.
  ///
  /// ## Returns
  ///
  /// - [double]: X-axis field strength in microteslas (µT).
  double get x;

  /// The magnetic field strength along the Y axis in microteslas.
  ///
  /// ## Returns
  ///
  /// - [double]: Y-axis field strength in microteslas (µT).
  double get y;

  /// The magnetic field strength along the Z axis in microteslas.
  ///
  /// ## Returns
  ///
  /// - [double]: Z-axis field strength in microteslas (µT).
  double get z;
}
