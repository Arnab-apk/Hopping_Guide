// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';

/// Heart rate biometric sensor data.
///
/// Represents heart rate readings in beats per minute, typically from a fitness
/// or health sensor.
///
/// {@category Sensor Data Source}
abstract class HeartRate extends SenseData {
  /// The heart rate measurement in beats per minute.
  ///
  /// ## Returns
  ///
  /// - [int]: Heart rate in BPM.
  int get heartRate;
}
