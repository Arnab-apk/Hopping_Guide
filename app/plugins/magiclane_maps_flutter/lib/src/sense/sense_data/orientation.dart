// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';

/// Device orientation sensor data.
///
/// Combines multiple sensors (like accelerometer and magnetometer) to determine the
/// absolute device orientation including screen rotation and face direction.
///
/// {@category Sensor Data Source}
abstract class Orientation extends SenseData {
  /// The rotational orientation of the device display.
  ///
  /// ## Returns
  ///
  /// - [OrientationType]: The display orientation (portrait, landscape, etc.).
  OrientationType get orientation;

  /// The face orientation of the device.
  ///
  /// ## Returns
  ///
  /// - [FaceType]: Whether the screen is facing up or down.
  FaceType get face;
}

/// User interface orientation types.
///
/// Describes the rotational orientation of the device's display.
///
/// ## See also:
///
/// - [Orientation] — Device orientation sensor data.
///
/// {@category Sensor Data Source}
enum OrientationType {
  /// Orientation is unknown or could not be determined.
  unknown,

  /// Device is in portrait orientation.
  portrait,

  /// Device is in portrait orientation upside down.
  portraitUpsideDown,

  /// Device is in landscape orientation rotated left.
  landscapeLeft,

  /// Device is in landscape orientation rotated right.
  landscapeRight,
}

/// @nodoc
extension OrientationTypeExtension on OrientationType {
  static OrientationType fromId(final int value) {
    switch (value) {
      case 0:
        return OrientationType.unknown;
      case 1:
        return OrientationType.portrait;
      case 2:
        return OrientationType.portraitUpsideDown;
      case 3:
        return OrientationType.landscapeLeft;
      case 4:
        return OrientationType.landscapeRight;
      default:
        throw ArgumentError('Invalid id');
    }
  }

  int get id {
    switch (this) {
      case OrientationType.unknown:
        return 0;
      case OrientationType.portrait:
        return 1;
      case OrientationType.portraitUpsideDown:
        return 2;
      case OrientationType.landscapeLeft:
        return 3;
      case OrientationType.landscapeRight:
        return 4;
    }
  }
}

/// Device face orientation types.
///
/// Indicates whether the device screen is facing up or down.
///
/// ## See also:
///
/// - [Orientation] — Device orientation sensor data.
///
/// {@category Sensor Data Source}
enum FaceType {
  /// Face orientation is unknown or could not be determined.
  unknown,

  /// Device screen is facing up.
  faceUp,

  /// Device screen is facing down.
  faceDown,
}

/// @nodoc
extension FaceTypeExtension on FaceType {
  static FaceType fromId(final int value) {
    switch (value) {
      case 0:
        return FaceType.unknown;
      case 1:
        return FaceType.faceUp;
      case 2:
        return FaceType.faceDown;
      default:
        throw ArgumentError('Invalid id');
    }
  }

  int get id {
    switch (this) {
      case FaceType.unknown:
        return 0;
      case FaceType.faceUp:
        return 1;
      case FaceType.faceDown:
        return 2;
    }
  }
}
