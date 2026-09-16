// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';

/// NMEA sentence data from GNSS receivers.
///
/// Raw navigation data in NMEA sentence format, typically from GNSS receivers for
/// high-precision tracking.
///
/// Only available on Android devices.
///
/// {@category Sensor Data Source}
abstract class NmeaChunk extends SenseData {
  /// The raw NMEA sentence string.
  ///
  /// ## Returns
  ///
  /// - [String]: The NMEA sentence text.
  String get nmeaChunk;
}
