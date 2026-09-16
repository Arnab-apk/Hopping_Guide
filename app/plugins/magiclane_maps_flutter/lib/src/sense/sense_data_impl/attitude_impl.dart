// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/sense_data_impl.dart';
import 'package:meta/meta.dart';

/// @nodoc
class AttitudeImpl extends SenseDataImpl implements Attitude {
  AttitudeImpl({
    required super.type,
    required super.acquisitionTime,
    required this.roll,
    required this.pitch,
    required this.yaw,
    required this.rollNoise,
    required this.hasPitchNoise,
    required this.hasRollNoise,
    required this.hasYawNoise,
    required this.pitchNoise,
    required this.yawNoise,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory AttitudeImpl.fromJson(final Map<String, dynamic> json) {
    return AttitudeImpl(
      type: DataTypeExtension.fromId(json['senseDataType']),
      acquisitionTime: DateTime.fromMillisecondsSinceEpoch(
        json['acquisitionTimestamp'],
        isUtc: true,
      ),
      roll: json['roll'],
      pitch: json['pitch'],
      yaw: json['yaw'],
      rollNoise: json['rollNoise'],
      pitchNoise: json['pitchNoise'],
      yawNoise: json['yawNoise'],
      hasPitchNoise: json['hasPitchNoise'],
      hasRollNoise: json['hasRollNoise'],
      hasYawNoise: json['hasYawNoise'],
    );
  }

  @override
  double roll;

  @override
  double pitch;

  @override
  double yaw;

  @override
  double rollNoise;

  @override
  double pitchNoise;

  @override
  double yawNoise;

  @override
  bool hasPitchNoise;

  @override
  bool hasRollNoise;

  @override
  bool hasYawNoise;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['senseDataType'] = type.id;
    json['acquisitionTimestamp'] = acquisitionTime.millisecondsSinceEpoch;

    json['roll'] = roll;
    json['pitch'] = pitch;
    json['yaw'] = yaw;
    json['rollNoise'] = rollNoise;
    json['pitchNoise'] = pitchNoise;
    json['yawNoise'] = yawNoise;
    json['hasPitchNoise'] = hasPitchNoise;
    json['hasRollNoise'] = hasRollNoise;
    json['hasYawNoise'] = hasYawNoise;

    return json;
  }

  @override
  bool operator ==(covariant final Attitude other) {
    return roll == other.roll &&
        pitch == other.pitch &&
        yaw == other.yaw &&
        rollNoise == other.rollNoise &&
        pitchNoise == other.pitchNoise &&
        yawNoise == other.yawNoise &&
        hasPitchNoise == other.hasPitchNoise &&
        hasRollNoise == other.hasRollNoise &&
        hasYawNoise == other.hasYawNoise &&
        acquisitionTime.millisecondsSinceEpoch ==
            other.acquisitionTime.millisecondsSinceEpoch;
  }

  @override
  int get hashCode {
    return roll.hashCode ^
        pitch.hashCode ^
        yaw.hashCode ^
        rollNoise.hashCode ^
        pitchNoise.hashCode ^
        yawNoise.hashCode ^
        hasPitchNoise.hashCode ^
        hasRollNoise.hashCode ^
        hasYawNoise.hashCode ^
        acquisitionTime.hashCode;
  }
}
