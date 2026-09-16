// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:typed_data';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/position.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
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

/// Factory for creating sensor data instances.
///
/// Provides static factory methods to produce various [SenseData] subtype instances
/// for testing, mocking, or custom data injection.
///
/// {@category Sensor Data Source}
abstract class SenseDataFactory {
  /// Creates a new [GemPosition] instance from provided parameters.
  ///
  /// ## Parameters
  ///
  /// - [acquisitionTime]: When the position was acquired (defaults to current time).
  /// - [satelliteTime]: Satellite timestamp (defaults to current time).
  /// - [provider]: Position provider (defaults to [Provider.gps]).
  /// - [fixQuality]: Quality of the position fix (defaults to [PositionQuality.high]).
  /// - [latitude]: Latitude in degrees (default: 0.0).
  /// - [longitude]: Longitude in degrees (default: 0.0).
  /// - [altitude]: Altitude in meters (default: 0.0).
  /// - [speed]: Speed in meters per second (default: 0.0).
  /// - [speedAccuracy]: Speed accuracy in m/s (default: -1.0).
  /// - [course]: Course/heading in degrees (default: 0.0).
  /// - [courseAccuracy]: Course accuracy in degrees (default: -1.0).
  /// - [accuracyH]: Horizontal accuracy in meters (default: -1.0).
  /// - [accuracyV]: Vertical accuracy in meters (default: -1.0).
  /// - [hasCoordinates]: Whether coordinates are valid (default: true).
  /// - [hasAltitude]: Whether altitude is valid (default: true).
  /// - [hasSpeed]: Whether speed is valid (default: true).
  /// - [hasSpeedAccuracy]: Whether speed accuracy is valid (default: false).
  /// - [hasCourse]: Whether course is valid (default: true).
  /// - [hasCourseAccuracy]: Whether course accuracy is valid (default: false).
  /// - [hasHorizontalAccuracy]: Whether horizontal accuracy is valid (default: false).
  /// - [hasVerticalAccuracy]: Whether vertical accuracy is valid (default: false).
  ///
  /// ## Returns
  ///
  /// - [GemPosition]: The created position instance.
  static GemPosition producePosition({
    final DateTime? acquisitionTime,
    final DateTime? satelliteTime,
    final Provider provider = Provider.gps,
    final PositionQuality fixQuality = PositionQuality.high,
    final double latitude = 0.0,
    final double longitude = 0.0,
    final double altitude = 0.0,
    final double speed = 0.0,
    final double speedAccuracy = -1.0,
    final double course = 0.0,
    final double courseAccuracy = -1.0,
    final double accuracyH = -1.0,
    final double accuracyV = -1.0,
    final bool hasCoordinates = true,
    final bool hasAltitude = true,
    final bool hasSpeed = true,
    final bool hasSpeedAccuracy = false,
    final bool hasCourse = true,
    final bool hasCourseAccuracy = false,
    final bool hasHorizontalAccuracy = false,
    final bool hasVerticalAccuracy = false,
  }) {
    return GemPositionImpl(
      type: DataType.position,
      acquisitionTime: acquisitionTime ?? DateTime.now(),
      satelliteTime: satelliteTime ?? DateTime.now(),
      provider: provider,
      fixQuality: fixQuality,
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      speed: speed,
      speedAccuracy: speedAccuracy,
      course: course,
      courseAccuracy: courseAccuracy,
      accuracyH: accuracyH,
      accuracyV: accuracyV,
      hasCoordinates: hasCoordinates,
      hasAltitude: hasAltitude,
      hasSpeed: hasSpeed,
      hasSpeedAccuracy: hasSpeedAccuracy,
      hasCourse: hasCourse,
      hasCourseAccuracy: hasCourseAccuracy,
      hasHorizontalAccuracy: hasHorizontalAccuracy,
      hasVerticalAccuracy: hasVerticalAccuracy,
    );
  }

  /// Creates a new [Acceleration] instance from provided parameters.
  ///
  /// ## Parameters
  ///
  /// - [acquisitionTime]: When the acceleration was measured (defaults to current time).
  /// - [x]: Acceleration on X axis (default: 0.0).
  /// - [y]: Acceleration on Y axis (default: 0.0).
  /// - [z]: Acceleration on Z axis (default: 0.0).
  /// - [unit]: Unit of measurement (defaults to [UnitOfMeasurementAcceleration.g]).
  ///
  /// ## Returns
  ///
  /// - [Acceleration]: The created acceleration instance.
  static Acceleration produceAcceleration({
    final DateTime? acquisitionTime,
    final double x = 0.0,
    final double y = 0.0,
    final double z = 0.0,
    final UnitOfMeasurementAcceleration unit = UnitOfMeasurementAcceleration.g,
  }) {
    return AccelerationImpl(
      type: DataType.acceleration,
      acquisitionTime: acquisitionTime ?? DateTime.now(),
      x: x,
      y: y,
      z: z,
      unit: unit,
    );
  }

  /// Creates a new [Compass] instance from provided parameters.
  ///
  /// ## Parameters
  ///
  /// - [acquisitionTime]: When the compass reading was taken (defaults to current time).
  /// - [heading]: Compass heading in degrees (default: 0.0).
  /// - [accuracy]: Accuracy level (defaults to [CompassAccuracy.unknown]).
  ///
  /// ## Returns
  ///
  /// - [Compass]: The created compass instance.
  static Compass produceCompass({
    final DateTime? acquisitionTime,
    final double heading = 0.0,
    final CompassAccuracy accuracy = CompassAccuracy.unknown,
  }) {
    return CompassImpl(
      type: DataType.compass,
      acquisitionTime: acquisitionTime ?? DateTime.now(),
      heading: heading,
      accuracy: accuracy,
    );
  }

  /// Creates a new [Attitude] instance from provided parameters.
  ///
  /// ## Parameters
  ///
  /// - [acquisitionTime]: When the attitude measurement was taken (defaults to current time).
  /// - [roll]: Roll angle in degrees (default: 0.0).
  /// - [pitch]: Pitch angle in degrees (default: 0.0).
  /// - [yaw]: Yaw angle in degrees (default: 0.0).
  /// - [rollNoise]: Roll noise variance in degrees squared (default: 0.0).
  /// - [pitchNoise]: Pitch noise variance in degrees squared (default: 0.0).
  /// - [yawNoise]: Yaw noise variance in degrees squared (default: 0.0).
  /// - [hasRollNoise]: Whether roll noise is available (default: false).
  /// - [hasPitchNoise]: Whether pitch noise is available (default: false).
  /// - [hasYawNoise]: Whether yaw noise is available (default: false).
  ///
  /// ## Returns
  ///
  /// - [Attitude]: The created attitude instance.
  static Attitude produceAttitude({
    final DateTime? acquisitionTime,
    final double roll = 0.0,
    final double pitch = 0.0,
    final double yaw = 0.0,
    final double rollNoise = 0.0,
    final double pitchNoise = 0.0,
    final double yawNoise = 0.0,
    final bool hasRollNoise = false,
    final bool hasPitchNoise = false,
    final bool hasYawNoise = false,
  }) {
    return AttitudeImpl(
      type: DataType.attitude,
      acquisitionTime: acquisitionTime ?? DateTime.now(),
      roll: roll,
      pitch: pitch,
      yaw: yaw,
      rollNoise: rollNoise,
      pitchNoise: pitchNoise,
      yawNoise: yawNoise,
      hasRollNoise: hasRollNoise,
      hasPitchNoise: hasPitchNoise,
      hasYawNoise: hasYawNoise,
    );
  }

  /// Creates a new [Battery] instance from provided parameters.
  ///
  /// ## Parameters
  ///
  /// - [acquisitionTime]: When the battery data was captured (defaults to current time).
  /// - [level]: Battery charge level as percentage 0-100 (default: 100).
  /// - [state]: Charging state (defaults to [BatteryState.unknown]).
  /// - [health]: Battery health status (defaults to [BatteryHealth.unknown]).
  /// - [lowBatteryNoticed]: Whether low battery condition detected (default: false).
  /// - `pluggedType`: Power source type (defaults to `PluggedType.unplugged`).
  /// - [voltage]: Battery voltage in millivolts (default: 0).
  /// - [temperature]: Battery temperature (default: 0).
  ///
  /// ## Returns
  ///
  /// - [Battery]: The created battery instance.
  static Battery produceBattery({
    final DateTime? acquisitionTime,
    final int level = 0,
    final BatteryState state = BatteryState.unknown,
    final BatteryHealth health = BatteryHealth.unknown,
    final bool lowBatteryNoticed = false,
    final PluggedType pluggedType = PluggedType.unplugged,
    final int voltage = 0,
    final int temperature = 0,
  }) {
    return BatteryImpl(
      type: DataType.battery,
      acquisitionTime: acquisitionTime ?? DateTime.now(),
      level: level,
      state: state,
      health: health,
      lowBatteryNoticed: lowBatteryNoticed,
      pluggedType: pluggedType,
      voltage: voltage,
      temperature: temperature,
    );
  }

  /// Creates a new [MagneticField] instance from provided parameters.
  ///
  /// ## Parameters
  ///
  /// - [acquisitionTime]: When the magnetic field reading was taken (defaults to current time).
  /// - [x]: Magnetic field X-axis component in microteslas (default: 0.0).
  /// - [y]: Magnetic field Y-axis component in microteslas (default: 0.0).
  /// - [z]: Magnetic field Z-axis component in microteslas (default: 0.0).
  ///
  /// ## Returns
  ///
  /// - [MagneticField]: The created magnetic field instance.
  static MagneticField produceMagneticField({
    final DateTime? acquisitionTime,
    final double x = 0.0,
    final double y = 0.0,
    final double z = 0.0,
  }) {
    return MagneticFieldImpl(
      type: DataType.magneticField,
      acquisitionTime: acquisitionTime ?? DateTime.now(),
      x: x,
      y: y,
      z: z,
    );
  }

  /// Creates a new [Orientation] instance from provided parameters.
  ///
  /// ## Parameters
  ///
  /// - [acquisitionTime]: When the orientation was determined (defaults to current time).
  /// - [orientation]: The current orientation (defaults to [OrientationType.unknown]).
  /// - `faceType`: The facing direction (defaults to `FaceType.unknown`).
  ///
  /// ## Returns
  ///
  /// - [Orientation]: The created orientation instance.
  static Orientation produceOrientation({
    final DateTime? acquisitionTime,
    final OrientationType orientation = OrientationType.unknown,
    final FaceType face = FaceType.unknown,
  }) {
    return OrientationImpl(
      type: DataType.orientation,
      acquisitionTime: acquisitionTime ?? DateTime.now(),
      orientation: orientation,
      face: face,
    );
  }

  /// Creates a new [RotationRate] instance from provided parameters.
  ///
  /// ## Parameters
  ///
  /// - [acquisitionTime]: When the rotation rate was measured (defaults to current time).
  /// - [x]: Rotation rate around X-axis in radians/second (default: 0.0).
  /// - [y]: Rotation rate around Y-axis in radians/second (default: 0.0).
  /// - [z]: Rotation rate around Z-axis in radians/second (default: 0.0).
  ///
  /// ## Returns
  ///
  /// - [RotationRate]: The created rotation rate instance.
  static RotationRate produceRotationRate({
    final DateTime? acquisitionTime,
    final double x = 0.0,
    final double y = 0.0,
    final double z = 0.0,
  }) {
    return RotationRateImpl(
      type: DataType.rotationRate,
      acquisitionTime: acquisitionTime ?? DateTime.now(),
      x: x,
      y: y,
      z: z,
    );
  }

  /// Creates a new [Temperature] instance from provided parameters.
  ///
  /// ## Parameters
  ///
  /// - [acquisitionTime]: When the temperature measurement was taken (defaults to current time).
  /// - [temperature]: Temperature value in degrees Celsius (default: 0.0).
  /// - [level]: Temperature level indicator (defaults to [TemperatureLevel.normal]).
  ///
  /// ## Returns
  ///
  /// - [Temperature]: The created temperature instance.
  static Temperature produceTemperature({
    final DateTime? acquisitionTime,
    final double temperature = 0.0,
    final TemperatureLevel level = TemperatureLevel.unknown,
  }) {
    return TemperatureImpl(
      type: DataType.temperature,
      acquisitionTime: acquisitionTime ?? DateTime.now(),
      temperature: temperature,
      level: level,
    );
  }

  /// Creates a new [MountInformation] instance from provided parameters.
  ///
  /// ## Parameters
  ///
  /// - [acquisitionTime]: When the mount information was recorded (defaults to current time).
  /// - [isMountedForCameraUse]: Whether the device is mounted for camera use (default: false).
  /// - [isPortraitMode]: Whether the device is in portrait mode (default: false).
  ///
  /// ## Returns
  ///
  /// - [MountInformation]: The created mount information instance.
  static MountInformation produceMountInformation({
    final DateTime? acquisitionTime,
    final bool isMountedForCameraUse = false,
    final bool isPortraitMode = false,
  }) {
    return MountInformationImpl(
      type: DataType.mountInformation,
      acquisitionTime: acquisitionTime ?? DateTime.now(),
      isMountedForCameraUse: isMountedForCameraUse,
      isPortraitMode: isPortraitMode,
    );
  }

  /// Creates a new [HeartRate] instance from provided parameters.
  ///
  /// ## Parameters
  ///
  /// - [acquisitionTime]: When the heart rate measurement was taken (defaults to current time).
  /// - [heartRate]: Heart rate in beats per minute (default: 0.0).
  ///
  /// ## Returns
  ///
  /// - [HeartRate]: The created heart rate instance.
  static HeartRate produceHeartRate({
    final DateTime? acquisitionTime,
    final int heartRate = 0,
  }) {
    return HeartRateImpl(
      type: DataType.heartRate,
      acquisitionTime: acquisitionTime ?? DateTime.now(),
      heartRate: heartRate,
    );
  }

  /// Creates a new [NmeaChunk] instance from provided parameters.
  ///
  /// ## Parameters
  ///
  /// - [acquisitionTime]: When the NMEA chunk was received (defaults to current time).
  /// - [nmeaChunk]: The raw NMEA data string (default: empty string).
  ///
  /// ## Returns
  ///
  /// - [NmeaChunk]: The created NMEA chunk instance.
  static NmeaChunk produceNmeaChunk({
    final DateTime? acquisitionTime,
    required final String nmeaChunk,
  }) {
    return NmeaChunkImpl(
      type: DataType.nmeaChunk,
      acquisitionTime: acquisitionTime ?? DateTime.now(),
      nmeaChunk: nmeaChunk,
    );
  }

  /// Creates a new [Camera] instance from provided parameters.
  ///
  /// ## Parameters
  ///
  /// - [acquisitionTime]: When the camera frame was captured (defaults to current time).
  /// - [cameraConfiguration]: Camera configuration settings (default: empty configuration).
  /// - [rawCameraBuffer]: Image data as byte list (default: empty list).
  ///
  /// ## Returns
  ///
  /// - [Camera]: The created camera instance.
  static Camera produceCamera({
    final DateTime? acquisitionTime,
    required CameraConfiguration cameraConfiguration,
    required Uint8List rawCameraBuffer,
  }) {
    final dynamic dataBufferPointer = GemKitPlatform.instance.toNativePointer(
      rawCameraBuffer,
    );

    final OperationResult result = staticMethod(
      'SenseDataFactory',
      'produceCamera',
      args: <String, Object?>{
        'acquisitionTimestamp':
            (acquisitionTime ?? DateTime.now()).millisecondsSinceEpoch,
        'cameraConfiguration': cameraConfiguration.toJson(),
        'rawCameraBuffer': dataBufferPointer.address,
        'rawCameraBufferSize': rawCameraBuffer.length,
      },
    );
    return CameraImpl.fromJson(result['result']);
  }
}
