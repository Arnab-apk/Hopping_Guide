// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';

/// Device orientation attitude data in 3D space.
///
/// Describes the device's orientation expressed as Euler angles (roll, pitch, yaw)
/// along with optional noise variance measurements.
///
/// {@category Sensor Data Source}
abstract class Attitude extends SenseData {
  /// The device roll angle in degrees.
  ///
  /// ## Returns
  ///
  /// - [double]: Roll angle value.
  double get roll;

  /// The device pitch angle in degrees.
  ///
  /// ## Returns
  ///
  /// - [double]: Pitch angle value.
  double get pitch;

  /// The device yaw angle in degrees.
  ///
  /// ## Returns
  ///
  /// - [double]: Yaw angle value.
  double get yaw;

  /// The variance (noise) of the roll measurement in degrees squared.
  ///
  /// ## Returns
  ///
  /// - [double]: Roll noise variance value.
  double get rollNoise;

  /// The variance (noise) of the pitch measurement in degrees squared.
  ///
  /// ## Returns
  ///
  /// - [double]: Pitch noise variance value.
  double get pitchNoise;

  /// The variance (noise) of the yaw measurement in degrees squared.
  ///
  /// ## Returns
  ///
  /// - [double]: Yaw noise variance value.
  double get yawNoise;

  /// Whether roll noise data is available.
  ///
  /// ## Returns
  ///
  /// - [bool]: True if roll noise data is present, false otherwise.
  bool get hasRollNoise;

  /// Whether pitch noise data is available.
  ///
  /// ## Returns
  ///
  /// - [bool]: True if pitch noise data is present, false otherwise.
  bool get hasPitchNoise;

  /// Whether yaw noise data is available.
  ///
  /// ## Returns
  ///
  /// - [bool]: True if yaw noise data is present, false otherwise.
  bool get hasYawNoise;
}
