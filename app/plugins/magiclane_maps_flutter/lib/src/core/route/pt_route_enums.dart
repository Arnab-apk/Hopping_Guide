// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Type of transit.
///
/// Enumeration describing the transit mode for public-transport segments.
///
/// {@category Route}
enum TransitType {
  /// Walk.
  walk,

  /// Bus.
  bus,

  /// Underground.
  underground,

  /// Railway.
  railway,

  /// Tram.
  tram,

  /// Water transport.
  waterTransport,

  /// Other.
  other,

  /// Shared bike.
  sharedBike,

  /// Shared scooter.
  sharedScooter,

  /// Shared car.
  sharedCar,

  /// Unknown.
  unknown,
}

/// @nodoc
extension TransitTypeExtension on TransitType {
  int get id {
    switch (this) {
      case TransitType.walk:
        return 0;
      case TransitType.bus:
        return 1;
      case TransitType.underground:
        return 2;
      case TransitType.railway:
        return 3;
      case TransitType.tram:
        return 4;
      case TransitType.waterTransport:
        return 5;
      case TransitType.other:
        return 6;
      case TransitType.sharedBike:
        return 7;
      case TransitType.sharedScooter:
        return 8;
      case TransitType.sharedCar:
        return 9;
      case TransitType.unknown:
        return 10;
    }
  }

  static TransitType fromId(final int id) {
    switch (id) {
      case 0:
        return TransitType.walk;
      case 1:
        return TransitType.bus;
      case 2:
        return TransitType.underground;
      case 3:
        return TransitType.railway;
      case 4:
        return TransitType.tram;
      case 5:
        return TransitType.waterTransport;
      case 6:
        return TransitType.other;
      case 7:
        return TransitType.sharedBike;
      case 8:
        return TransitType.sharedScooter;
      case 9:
        return TransitType.sharedCar;
      case 10:
        return TransitType.unknown;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Status of real-time information.
///
/// Describes the real-time status for segments and instructions (delay, onTime,
/// notAvailable).
///
/// {@category Route}
enum RealtimeStatus {
  /// Delay.
  delay,

  /// On time.
  onTime,

  /// Not available.
  notAvailable,
}

/// @nodoc
extension RealtimeStatusExtension on RealtimeStatus {
  int get id {
    switch (this) {
      case RealtimeStatus.delay:
        return 0;
      case RealtimeStatus.onTime:
        return 1;
      case RealtimeStatus.notAvailable:
        return 2;
    }
  }

  static RealtimeStatus fromId(final int id) {
    switch (id) {
      case 0:
        return RealtimeStatus.delay;
      case 1:
        return RealtimeStatus.onTime;
      case 2:
        return RealtimeStatus.notAvailable;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
