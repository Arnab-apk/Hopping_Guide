// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:typed_data';

import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

class CameraImpl extends GemAutoreleaseObject implements Camera {
  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory CameraImpl.fromJson(Map<String, dynamic> json) {
    final int pointerId = json['pointerId'];
    final CameraImpl res = CameraImpl.init(pointerId);

    final DataType type = DataTypeExtension.fromId(json['senseDataType']);
    final DateTime stamp = DateTime.fromMillisecondsSinceEpoch(
      json['acquisitionTimestamp'],
      isUtc: true,
    );
    final CameraConfiguration cameraConfig = CameraConfiguration.fromJson(
      json['cameraConfiguration'],
    );

    res.type = type;
    res.acquisitionTime = stamp;
    res.cameraConfiguration = cameraConfig;

    return res;
  }
  // ignore: unused_element
  CameraImpl._() : super(-1);

  CameraImpl.init(super.id);

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['senseDataType'] = type.id;
    json['pointerId'] = pointerId;
    return json;
  }

  @override
  DateTime acquisitionTime = DateTime.utc(0);

  @override
  DataType type = DataType.camera;

  @override
  CameraConfiguration cameraConfiguration = CameraConfiguration();

  @override
  Uint8List? get rgba8888 {
    final Uint8List? rawBuffer = rawCameraBuffer;

    if (rawBuffer == null) {
      return null;
    }

    if (cameraConfiguration.pixelFormat != ImagePixelFormat.yuv420_888) {
      return null;
    }

    return _convertYUV420ToRGBABytes(
      rawBuffer,
      cameraConfiguration.frameWidth,
      cameraConfiguration.frameHeight,
    );
  }

  @override
  Uint8List? get rawCameraBuffer =>
      GemKitPlatform.instance.callGetCameraBuffer(pointerId)!;

  Uint8List _convertYUV420ToRGBABytes(Uint8List src, int width, int height) {
    final Uint8List rgba = Uint8List(width * height * 4);
    final int uvStart = width * height;
    int index = 0, rgbaIndex = 0;
    int y, u, v;
    int r, g, b, a;
    int uvIndex = 0;

    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        uvIndex = i ~/ 2 * width + j - j % 2;

        y = src[rgbaIndex];
        u = src[uvStart + uvIndex];
        v = src[uvStart + uvIndex + 1];

        r = y + (1.164 * (v - 128)).toInt(); // r
        g = y - (0.392 * (u - 128)).toInt() - (0.813 * (v - 128)).toInt(); // g
        b = y + (2.017 * (u - 128)).toInt(); // b
        a = 255;

        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);

        index = rgbaIndex % width + i * width;
        rgba[index * 4 + 0] = r;
        rgba[index * 4 + 1] = g;
        rgba[index * 4 + 2] = b;
        rgba[index * 4 + 3] = a;
        rgbaIndex++;
      }
    }

    return rgba;
  }
}
