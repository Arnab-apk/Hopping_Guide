// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:typed_data';

import 'package:magiclane_maps_flutter/sense.dart';
import 'package:meta/meta.dart';

/// Camera frame sensor data.
///
/// Provides camera frame data, including configuration metadata and raw/processed
/// image buffers. Typically used for computer vision or video recording features.
///
/// ## Also see:
///
/// - [CameraConfiguration] — Camera hardware and capture settings.
/// - [GemCameraPlayer] - Player widget for displaying camera frames.
///
/// {@category Sensor Data Source}
abstract class Camera extends SenseData {
  /// The camera configuration for this frame.
  ///
  /// ## Returns
  ///
  /// - [CameraConfiguration]: The camera hardware and capture settings.
  CameraConfiguration get cameraConfiguration;

  /// The raw camera buffer in YUV420 NV12 format.
  ///
  /// This format is guaranteed only when using the live data source provided by this SDK.
  /// If an external or unsupported data source is used, the format is not guaranteed.
  ///
  /// ## Returns
  ///
  /// - [Uint8List?]: Raw buffer bytes, or null if unavailable.
  Uint8List? get rawCameraBuffer;

  /// The processed RGBA8888 image data, ready for direct use.
  ///
  /// RGBA output is only valid if the original [rawCameraBuffer] was in YUV420 NV12 format,
  /// as guaranteed when using the live data source from this SDK.
  ///
  /// ## Returns
  ///
  /// - [Uint8List?]: RGBA buffer bytes, or null if unavailable.
  Uint8List? get rgba8888;
}

/// Image pixel encoding formats.
///
/// Defines various pixel formats used by camera sensors for encoding frame data.
///
/// ## See also:
///
/// - [CameraConfiguration] — Camera hardware and capture settings.
///
/// {@category Sensor Data Source}
enum ImagePixelFormat {
  /// Unknown or unspecified pixel format.
  unknown,

  /// RGB 888: 8-bit Red, 8-bit Green, 8-bit Blue.
  rgb888,

  /// BGR 888: 8-bit Blue, 8-bit Green, 8-bit Red.
  bgr888,

  /// ABGR 8888: 8-bit Alpha, 8-bit Blue, 8-bit Green, 8-bit Red.
  abgr8888,

  /// Alpha-only: 8-bit Alpha channel.
  alpha8,

  /// RGB 565: 5-bit Red, 6-bit Green, 5-bit Blue.
  rgb565,

  /// ARGB 8888: 8-bit Alpha, 8-bit Red, 8-bit Green, 8-bit Blue.
  argb8888,

  /// YUV 420 888: YCbCr color space (YUV).
  yuv420_888,

  /// YV12: YCrCb planar format.
  yv12,

  /// NV21: Android YUV format (semi-planar).
  nv21,
}

/// @nodoc
extension ImagePixelFormatExtension on ImagePixelFormat {
  static ImagePixelFormat fromId(final int value) {
    switch (value) {
      case 0:
        return ImagePixelFormat.unknown;
      case 1:
        return ImagePixelFormat.rgb888;
      case 2:
        return ImagePixelFormat.bgr888;
      case 3:
        return ImagePixelFormat.abgr8888;
      case 4:
        return ImagePixelFormat.alpha8;
      case 5:
        return ImagePixelFormat.rgb565;
      case 6:
        return ImagePixelFormat.argb8888;
      case 7:
        return ImagePixelFormat.yuv420_888;
      case 8:
        return ImagePixelFormat.yv12;
      case 9:
        return ImagePixelFormat.nv21;
      default:
        throw ArgumentError('Invalid ImagePixelFormat id: $value');
    }
  }

  int get id {
    switch (this) {
      case ImagePixelFormat.unknown:
        return 0;
      case ImagePixelFormat.rgb888:
        return 1;
      case ImagePixelFormat.bgr888:
        return 2;
      case ImagePixelFormat.abgr8888:
        return 3;
      case ImagePixelFormat.alpha8:
        return 4;
      case ImagePixelFormat.rgb565:
        return 5;
      case ImagePixelFormat.argb8888:
        return 6;
      case ImagePixelFormat.yuv420_888:
        return 7;
      case ImagePixelFormat.yv12:
        return 8;
      case ImagePixelFormat.nv21:
        return 9;
    }
  }
}

/// Camera hardware and capture settings.
///
/// Encapsulates camera parameters including field of view, resolution, frame rate,
/// pixel format, focal lengths, exposure, and ISO settings.
///
/// ## See also:
///
/// - [ImagePixelFormat] — Pixel encoding formats used by cameras.
/// - [Camera] — Captured camera frame data.
///
/// {@category Sensor Data Source}
class CameraConfiguration {
  /// Creates a camera configuration with specified parameters.
  ///
  /// All parameters are optional and have default fallback values.
  ///
  /// ## Parameters
  ///
  /// - [horizontalFOV]: Horizontal field of view in radians (default: 0.0).
  /// - [verticalFOV]: Vertical field of view in radians (default: 0.0).
  /// - [frameWidth]: Frame width in pixels (default: 0).
  /// - [frameHeight]: Frame height in pixels (default: 0).
  /// - [pixelFormat]: The pixel format/encoding type (default: [ImagePixelFormat.unknown]).
  /// - [frameRate]: Frames per second (default: 0.0).
  /// - [orientation]: The frame orientation (default: [OrientationType.unknown]).
  /// - [focalLengthHorizontal]: Horizontal focal length in pixels (default: 0.0).
  /// - [focalLengthVertical]: Vertical focal length in pixels (default: 0.0).
  /// - [focalLengthMinimum]: Minimum focal length in millimeters (default: 0.0).
  /// - [physicalSensorWidth]: Physical sensor width in millimeters (default: 0.0).
  /// - [physicalSensorHeight]: Physical sensor height in millimeters (default: 0.0).
  /// - [exposure]: Exposure time in nanoseconds (default: 0.0).
  /// - [minExposure]: Minimum possible exposure in nanoseconds (default: 0.0).
  /// - [maxExposure]: Maximum possible exposure in nanoseconds (default: 0.0).
  /// - [exposureTargetOffset]: Exposure target offset in EV units (default: 0.0).
  /// - [isoValue]: Actual ISO sensitivity value (default: 0.0).
  /// - [minIso]: Minimum possible ISO value (default: 0.0).
  /// - [maxIso]: Maximum possible ISO value (default: 0.0).
  CameraConfiguration({
    this.horizontalFOV = 0.0,
    this.verticalFOV = 0.0,
    this.frameWidth = 0,
    this.frameHeight = 0,
    this.pixelFormat = ImagePixelFormat.unknown,
    this.frameRate = 0.0,
    this.orientation = OrientationType.unknown,
    this.focalLengthHorizontal = 0.0,
    this.focalLengthVertical = 0.0,
    this.focalLengthMinimum = 0.0,
    this.physicalSensorWidth = 0.0,
    this.physicalSensorHeight = 0.0,
    this.exposure = 0.0,
    this.minExposure = 0.0,
    this.maxExposure = 0.0,
    this.exposureTargetOffset = 0.0,
    this.isoValue = 0.0,
    this.minIso = 0.0,
    this.maxIso = 0.0,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory CameraConfiguration.fromJson(Map<String, dynamic> json) {
    return CameraConfiguration(
      horizontalFOV: (json['horizontalFOV'] ?? 0.0).toDouble(),
      verticalFOV: (json['verticalFOV'] ?? 0.0).toDouble(),
      frameWidth: json['frameWidth'] ?? 0,
      frameHeight: json['frameHeight'] ?? 0,
      pixelFormat: ImagePixelFormatExtension.fromId(json['pixelFormat'] ?? 0),
      frameRate: (json['frameRate'] ?? 0.0).toDouble(),
      orientation: OrientationTypeExtension.fromId(json['orientation'] ?? 0),
      focalLengthHorizontal: (json['focalLengthHorizontal'] ?? 0.0).toDouble(),
      focalLengthVertical: (json['focalLengthVertical'] ?? 0.0).toDouble(),
      focalLengthMinimum: (json['focalLengthMinimum'] ?? 0.0).toDouble(),
      physicalSensorWidth: (json['physicalSensorWidth'] ?? 0.0).toDouble(),
      physicalSensorHeight: (json['physicalSensorHeight'] ?? 0.0).toDouble(),
      exposure: (json['exposure'] ?? 0.0).toDouble(),
      minExposure: (json['minExposure'] ?? 0.0).toDouble(),
      maxExposure: (json['maxExposure'] ?? 0.0).toDouble(),
      exposureTargetOffset: (json['exposureTargetOffset'] ?? 0.0).toDouble(),
      isoValue: (json['isoValue'] ?? 0.0).toDouble(),
      minIso: (json['minIso'] ?? 0.0).toDouble(),
      maxIso: (json['maxIso'] ?? 0.0).toDouble(),
    );
  }

  /// Horizontal Field Of View in radians
  double horizontalFOV;

  /// Vertical Field Of View in radians
  double verticalFOV;

  /// Frame width in pixels
  int frameWidth;

  /// Frame height in pixels
  int frameHeight;

  /// The pixel format (encoding type)
  ImagePixelFormat pixelFormat;

  /// The frameRate value
  double frameRate;

  /// The frame orientation
  OrientationType orientation;

  /// The horizontal focal length in pixels
  double focalLengthHorizontal;

  /// The vertical focal length in pixels
  double focalLengthVertical;

  /// The minimum possible focal length in millimeters
  double focalLengthMinimum;

  /// The physical sensor width in millimeters
  double physicalSensorWidth;

  /// The physical sensor height in millimeters
  double physicalSensorHeight;

  /// Exposure in nanoseconds
  double exposure;

  /// The minimum possible exposure in nanoseconds
  double minExposure;

  /// The maximum possible exposure in nanoseconds
  double maxExposure;

  /// The exposure target offset in EV units
  double exposureTargetOffset;

  /// The actual ISO value
  double isoValue;

  /// The minimum possible ISO value
  double minIso;

  /// The maximum possible ISO value
  double maxIso;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'horizontalFOV': horizontalFOV,
      'verticalFOV': verticalFOV,
      'frameWidth': frameWidth,
      'frameHeight': frameHeight,
      'pixelFormat': pixelFormat.id,
      'frameRate': frameRate,
      'orientation': orientation.id,
      'focalLengthHorizontal': focalLengthHorizontal,
      'focalLengthVertical': focalLengthVertical,
      'focalLengthMinimum': focalLengthMinimum,
      'physicalSensorWidth': physicalSensorWidth,
      'physicalSensorHeight': physicalSensorHeight,
      'exposure': exposure,
      'minExposure': minExposure,
      'maxExposure': maxExposure,
      'exposureTargetOffset': exposureTargetOffset,
      'isoValue': isoValue,
      'minIso': minIso,
      'maxIso': maxIso,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CameraConfiguration &&
          runtimeType == other.runtimeType &&
          horizontalFOV == other.horizontalFOV &&
          verticalFOV == other.verticalFOV &&
          frameWidth == other.frameWidth &&
          frameHeight == other.frameHeight &&
          pixelFormat == other.pixelFormat &&
          frameRate == other.frameRate &&
          orientation == other.orientation &&
          focalLengthHorizontal == other.focalLengthHorizontal &&
          focalLengthVertical == other.focalLengthVertical &&
          focalLengthMinimum == other.focalLengthMinimum &&
          physicalSensorWidth == other.physicalSensorWidth &&
          physicalSensorHeight == other.physicalSensorHeight &&
          exposure == other.exposure &&
          minExposure == other.minExposure &&
          maxExposure == other.maxExposure &&
          exposureTargetOffset == other.exposureTargetOffset &&
          isoValue == other.isoValue &&
          minIso == other.minIso &&
          maxIso == other.maxIso;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    horizontalFOV,
    verticalFOV,
    frameWidth,
    frameHeight,
    pixelFormat,
    frameRate,
    orientation,
    focalLengthHorizontal,
    focalLengthVertical,
    focalLengthMinimum,
    physicalSensorWidth,
    physicalSensorHeight,
    exposure,
    minExposure,
    maxExposure,
    exposureTargetOffset,
    isoValue,
    minIso,
    maxIso,
  ]);
}
