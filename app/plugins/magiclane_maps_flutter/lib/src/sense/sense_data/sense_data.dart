// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';

/// Base class for all sensor data types.
///
/// Every sensor data instance has a data type identifier and an acquisition timestamp.
/// Subclasses represent specific sensor readings such as acceleration, compass, position, etc.
///
/// {@category Sensor Data Source}
abstract class SenseData {
  /// The type of this sensor data.
  ///
  /// ## Returns
  ///
  /// - [DataType]: The specific data type enum value identifying the kind of sensor reading.
  DataType get type;

  /// The time when this sensor data was acquired.
  ///
  /// ## Returns
  ///
  /// - [DateTime]: The acquisition time in UTC.
  DateTime get acquisitionTime;
}
