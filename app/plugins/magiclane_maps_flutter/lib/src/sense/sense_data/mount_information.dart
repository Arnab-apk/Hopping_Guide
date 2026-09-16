// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';

/// Device mounting information sensor data.
///
/// Describes how the device is physically mounted or oriented within a fixed system,
/// such as in a vehicle.
///
/// {@category Sensor Data Source}
abstract class MountInformation extends SenseData {
  /// Whether the device is mounted for camera use (in a fixed vertical mount, in a car).
  ///
  /// ## Returns
  ///
  /// - [bool]: True if mounted for camera use, false otherwise.
  bool get isMountedForCameraUse;

  /// Whether the device is mounted in portrait orientation.
  ///
  /// ## Returns
  ///
  /// - [bool]: True if mounted in portrait mode, false otherwise.
  bool get isPortraitMode;
}
