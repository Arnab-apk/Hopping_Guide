// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/acceleration_impl.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/attitude_impl.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/battery_impl.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/camera_impl.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/compass_impl.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/gem_position_impl.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/heart_rate_impl.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/magnetic_field_impl.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/mount_information_impl.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/nmea_chunk_impl.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/orientation_impl.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/rotation_rate_impl.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/temperature_impl.dart';
import 'package:meta/meta.dart';

/// @nodoc
class SenseDataImpl implements SenseData {
  SenseDataImpl({required this.type, required this.acquisitionTime});

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory SenseDataImpl.fromJson(final Map<String, dynamic> json) {
    return SenseDataImpl(
      type: DataTypeExtension.fromId(json['senseDataType']),
      acquisitionTime: DateTime.fromMillisecondsSinceEpoch(
        json['acquisitionTimestamp'],
        isUtc: true,
      ),
    );
  }

  @override
  DateTime acquisitionTime;

  @override
  DataType type;

  /// Serializes the instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'acquisitionTimestamp': acquisitionTime.millisecondsSinceEpoch,
      'senseDataType': type.id,
    };
  }
}

/// Deserializes a JSON-compatible map to create an instance.
///
/// Used internally, not intended for direct use by consumers.
/// The expected map structure may change without notice.
@internal
SenseData senseFromJson(final Map<String, dynamic> json) {
  final DataType type = DataTypeExtension.fromId(json['senseDataType']);

  switch (type) {
    case DataType.acceleration:
      return AccelerationImpl.fromJson(json);
    case DataType.attitude:
      return AttitudeImpl.fromJson(json);
    case DataType.battery:
      return BatteryImpl.fromJson(json);
    case DataType.camera:
      return CameraImpl.fromJson(json);
    case DataType.compass:
      return CompassImpl.fromJson(json);
    case DataType.magneticField:
      return MagneticFieldImpl.fromJson(json);
    case DataType.orientation:
      return OrientationImpl.fromJson(json);
    case DataType.position:
      return GemPositionImpl.fromJson(json);
    case DataType.improvedPosition:
      return GemImprovedPositionImpl.fromJson(json);
    case DataType.rotationRate:
      return RotationRateImpl.fromJson(json);
    case DataType.temperature:
      return TemperatureImpl.fromJson(json);
    case DataType.notification:
      throw UnimplementedError();
    //return NotificationImpl.fromJson(json);
    case DataType.mountInformation:
      return MountInformationImpl.fromJson(json);
    case DataType.heartRate:
      return HeartRateImpl.fromJson(json);
    case DataType.nmeaChunk:
      return NmeaChunkImpl.fromJson(json);
    case DataType.unknown:
      return SenseDataImpl.fromJson(json);
    case DataType.gyroscope:
      return RotationRateImpl.fromJson(json);
  }
}
