// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';

/// Battery status information sensor data.
///
/// Provides comprehensive battery information including charge level, state, health,
/// voltage, temperature, and power connection status.
///
/// {@category Sensor Data Source}
abstract class Battery extends SenseData {
  /// The current battery charge level as a percentage.
  ///
  /// ## Returns
  ///
  /// - [int]: Battery level (0-100).
  int get level;

  /// The current battery operational state.
  ///
  /// ## Returns
  ///
  /// - [BatteryState]: The state (charging, discharging, etc.).
  BatteryState get state;

  /// The overall health condition of the battery.
  ///
  /// ## Returns
  ///
  /// - [BatteryHealth]: The health status.
  BatteryHealth get health;

  /// Whether a low battery warning has been detected.
  ///
  /// ## Returns
  ///
  /// - [bool]: True if a low battery warning has been noticed, false otherwise.
  bool get lowBatteryNoticed;

  /// The type of power source the device is connected to.
  ///
  /// ## Returns
  ///
  /// - [PluggedType]: The plugged-in power source type.
  PluggedType get pluggedType;

  /// The current battery voltage in millivolts.
  ///
  /// ## Returns
  ///
  /// - [int]: Voltage value in millivolts.
  int get voltage;

  /// The current battery temperature.
  ///
  /// ## Returns
  ///
  /// - [int]: Temperature value.
  int get temperature;
}

/// Battery charging and operational states.
///
/// Describes the current state of the device battery.
///
/// ## See also:
///
/// - [Battery] — Battery status information sensor data.
///
/// {@category Sensor Data Source}
enum BatteryState {
  /// Battery state is unknown or could not be determined.
  unknown,

  /// Battery is actively charging.
  charging,

  /// Battery is discharging (in use and not plugged in for charging).
  discharging,

  /// Battery is plugged in but not charging (may be maintaining a certain charge level).
  notCharging,

  /// Battery is fully charged.
  full,
}

/// @nodoc
extension BatteryStateExtension on BatteryState {
  static BatteryState fromId(final int value) {
    switch (value) {
      case 0:
        return BatteryState.unknown;
      case 1:
        return BatteryState.charging;
      case 2:
        return BatteryState.discharging;
      case 3:
        return BatteryState.notCharging;
      case 4:
        return BatteryState.full;
      default:
        throw ArgumentError('Invalid id');
    }
  }

  int get id {
    switch (this) {
      case BatteryState.unknown:
        return 0;
      case BatteryState.charging:
        return 1;
      case BatteryState.discharging:
        return 2;
      case BatteryState.notCharging:
        return 3;
      case BatteryState.full:
        return 4;
    }
  }
}

/// Power source connection types for a device.
///
/// Indicates what type of power source the device is connected to, if any.
///
/// ## See also:
///
/// - [Battery] — Battery status information sensor data.
///
/// {@category Sensor Data Source}
enum PluggedType {
  /// Device is not plugged in to any power source.
  unplugged,

  /// Device is plugged in to an AC power source.
  ac,

  /// Device is plugged in to a USB power source.
  usb,

  /// Device is plugged in to a wireless charging power source.
  wireless,
}

/// @nodoc
extension PluggedTypeExtension on PluggedType {
  static PluggedType fromId(final int value) {
    switch (value) {
      case 0:
        return PluggedType.unplugged;
      case 1:
        return PluggedType.ac;
      case 2:
        return PluggedType.usb;
      case 3:
        return PluggedType.wireless;
      default:
        throw ArgumentError('Invalid id');
    }
  }

  int get id {
    switch (this) {
      case PluggedType.unplugged:
        return 0;
      case PluggedType.ac:
        return 1;
      case PluggedType.usb:
        return 2;
      case PluggedType.wireless:
        return 3;
    }
  }
}

/// Battery health status indicators.
///
/// Represents the overall health condition of the device battery.
///
/// ## See also:
///
/// - [Battery] — Battery status information sensor data.
///
/// {@category Sensor Data Source}
enum BatteryHealth {
  /// Battery health is unknown or could not be determined.
  unknown,

  /// Battery is in good condition.
  good,

  /// Battery is overheating.
  overheat,

  /// Battery is no longer functional (dead).
  dead,

  /// Battery is experiencing over-voltage, which may indicate improper charging.
  overVoltage,

  /// Battery health status is unspecified or not determined.
  unspecifiedFailure,

  /// Battery is cold.
  cold,
}

/// @nodoc
extension BatteryHealthExtension on BatteryHealth {
  static BatteryHealth fromId(final int value) {
    switch (value) {
      case 0:
        return BatteryHealth.unknown;
      case 1:
        return BatteryHealth.good;
      case 2:
        return BatteryHealth.overheat;
      case 3:
        return BatteryHealth.dead;
      case 4:
        return BatteryHealth.overVoltage;
      case 5:
        return BatteryHealth.unspecifiedFailure;
      case 6:
        return BatteryHealth.cold;
      default:
        throw ArgumentError('Invalid id');
    }
  }

  int get id {
    switch (this) {
      case BatteryHealth.unknown:
        return 0;
      case BatteryHealth.good:
        return 1;
      case BatteryHealth.overheat:
        return 2;
      case BatteryHealth.dead:
        return 3;
      case BatteryHealth.overVoltage:
        return 4;
      case BatteryHealth.unspecifiedFailure:
        return 5;
      case BatteryHealth.cold:
        return 6;
    }
  }
}
