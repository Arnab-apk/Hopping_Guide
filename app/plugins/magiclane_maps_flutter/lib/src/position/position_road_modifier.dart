// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Current position road modifiers.
///
/// ## Also see:
///
/// - [GemImprovedPosition.roadModifiers] - The road modifiers of an improved position when available.
///
/// {@category Sensor Data Source}
enum RoadModifier {
  /// No modifier.
  none,

  /// Tunnel.
  tunnel,

  /// Bridge.
  bridge,

  /// Ramp.
  ramp,

  /// Tollway.
  tollway,

  /// Roundabout.
  roundabout,

  /// One way.
  oneWay,

  /// No U-turn.
  noUTurn,

  /// Left drive side.
  leftDriveSide,

  /// Motorway.
  motorway,

  /// Motorway link.
  motorwayLink,
}

/// @nodoc
extension RoadModifierExtension on RoadModifier {
  int get id {
    switch (this) {
      case RoadModifier.none:
        return 0;
      case RoadModifier.tunnel:
        return 1;
      case RoadModifier.bridge:
        return 2;
      case RoadModifier.ramp:
        return 4;
      case RoadModifier.tollway:
        return 8;
      case RoadModifier.roundabout:
        return 16;
      case RoadModifier.oneWay:
        return 32;
      case RoadModifier.noUTurn:
        return 64;
      case RoadModifier.leftDriveSide:
        return 128;
      case RoadModifier.motorway:
        return 256;
      case RoadModifier.motorwayLink:
        return 512;
    }
  }

  static RoadModifier fromId(final int id) {
    switch (id) {
      case 0:
        return RoadModifier.none;
      case 1:
        return RoadModifier.tunnel;
      case 2:
        return RoadModifier.bridge;
      case 4:
        return RoadModifier.ramp;
      case 8:
        return RoadModifier.tollway;
      case 16:
        return RoadModifier.roundabout;
      case 32:
        return RoadModifier.oneWay;
      case 64:
        return RoadModifier.noUTurn;
      case 128:
        return RoadModifier.leftDriveSide;
      case 256:
        return RoadModifier.motorway;
      case 512:
        return RoadModifier.motorwayLink;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
