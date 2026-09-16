// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Map view perspective modes for camera positioning
///
/// Defines whether the map is displayed in a flat, top-down view or a tilted perspective view.
/// Use with [FollowPositionPreferences.setPerspective] to switch between modes during follow position.
///
/// ## See also:
///
/// - [FollowPositionPreferences.perspective] - Get the current perspective
/// - [FollowPositionPreferences.setPerspective] - Change the perspective with optional animation
///
/// {@category Maps & 3D Scenes}
enum MapViewPerspective {
  /// Flat, top-down 2D view with no tilt
  ///
  /// The map is displayed as a flat plane viewed from directly above, similar to a traditional paper map.
  /// This mode provides the clearest view of geographic relationships but lacks depth perception.
  twoDimensional,

  /// Perspective 3D view with camera tilt
  ///
  /// The map is displayed with a tilted camera angle, providing depth and a sense of perspective.
  /// Buildings and terrain appear three-dimensional, making it easier to understand spatial relationships
  /// and navigate complex urban environments.
  threeDimensional,
}

/// @nodoc
extension MapViewPerspectiveExtension on MapViewPerspective {
  int get id {
    switch (this) {
      case MapViewPerspective.twoDimensional:
        return 0;
      case MapViewPerspective.threeDimensional:
        return 1;
    }
  }

  static MapViewPerspective fromId(final int id) {
    switch (id) {
      case 0:
        return MapViewPerspective.twoDimensional;
      case 1:
        return MapViewPerspective.threeDimensional;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Map rotation behavior during follow position mode
///
/// Defines how the map rotates when following the device position. The rotation can be based on
/// device heading, compass sensor, or a fixed angle.
///
/// ## See also:
///
/// - [FollowPositionPreferences.mapRotationMode] - Get the current rotation mode and angle
/// - [FollowPositionPreferences.setMapRotationMode] - Change the rotation mode
///
/// {@category Maps & 3D Scenes}
enum FollowPositionMapRotationMode {
  /// Rotate map based on device heading from position sensor
  ///
  /// The map rotates to match the direction of travel as determined by the position sensor (GPS).
  /// This mode works well during navigation, keeping the route direction always pointing upward.
  /// The rotation is derived from consecutive position updates.
  positionHeading,

  /// Rotate map based on compass sensor orientation
  ///
  /// The map rotates to match the device's physical orientation as detected by the compass (magnetometer).
  /// This mode provides immediate feedback when the device is rotated, even when stationary.
  /// May be affected by magnetic interference in some environments.
  compass,

  /// Keep map at a fixed rotation angle
  ///
  /// The map maintains a constant rotation angle regardless of device movement or orientation.
  /// The angle is specified via the `mapAngle` parameter in [FollowPositionPreferences.setMapRotationMode].
  /// Useful for maintaining a specific map orientation, such as north-up (angle 0).
  fixed,
}

/// @nodoc
extension FollowPositionMapRotationModeExtension
    on FollowPositionMapRotationMode {
  int get id {
    switch (this) {
      case FollowPositionMapRotationMode.positionHeading:
        return 0;
      case FollowPositionMapRotationMode.compass:
        return 1;
      case FollowPositionMapRotationMode.fixed:
        return 2;
    }
  }

  static FollowPositionMapRotationMode fromId(final int id) {
    switch (id) {
      case 0:
        return FollowPositionMapRotationMode.positionHeading;
      case 1:
        return FollowPositionMapRotationMode.compass;
      case 2:
        return FollowPositionMapRotationMode.fixed;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
