// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/sense_data_impl.dart';
import 'package:meta/meta.dart';

/// @nodoc
class BatteryImpl extends SenseDataImpl implements Battery {
  BatteryImpl({
    required super.type,
    required super.acquisitionTime,
    required this.health,
    required this.level,
    required this.lowBatteryNoticed,
    required this.pluggedType,
    required this.state,
    required this.temperature,
    required this.voltage,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory BatteryImpl.fromJson(final Map<String, dynamic> json) {
    return BatteryImpl(
      type: DataTypeExtension.fromId(json['senseDataType']),
      acquisitionTime: DateTime.fromMillisecondsSinceEpoch(
        json['acquisitionTimestamp'],
        isUtc: true,
      ),
      health: BatteryHealthExtension.fromId(json['health']),
      level: json['level'],
      lowBatteryNoticed: json['lowBattery'],
      pluggedType: PluggedTypeExtension.fromId(json['pluggedType']),
      state: BatteryStateExtension.fromId(json['state']),
      temperature: json['temperature'],
      voltage: json['voltage'],
    );
  }

  @override
  BatteryHealth health;

  @override
  int level;

  @override
  bool lowBatteryNoticed;

  @override
  PluggedType pluggedType;

  @override
  BatteryState state;

  @override
  int temperature;

  @override
  int voltage;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['senseDataType'] = type.id;
    json['acquisitionTimestamp'] = acquisitionTime.millisecondsSinceEpoch;

    json['health'] = health.id;
    json['level'] = level;
    json['lowBattery'] = lowBatteryNoticed;
    json['pluggedType'] = pluggedType.id;
    json['state'] = state.id;
    json['temperature'] = temperature;
    json['voltage'] = voltage;

    return json;
  }

  @override
  bool operator ==(covariant final Battery other) {
    return health == other.health &&
        level == other.level &&
        lowBatteryNoticed == other.lowBatteryNoticed &&
        pluggedType == other.pluggedType &&
        state == other.state &&
        temperature == other.temperature &&
        voltage == other.voltage &&
        acquisitionTime.millisecondsSinceEpoch ==
            other.acquisitionTime.millisecondsSinceEpoch;
  }

  @override
  int get hashCode {
    return health.hashCode ^
        level.hashCode ^
        lowBatteryNoticed.hashCode ^
        pluggedType.hashCode ^
        state.hashCode ^
        temperature.hashCode ^
        voltage.hashCode ^
        acquisitionTime.hashCode;
  }
}
