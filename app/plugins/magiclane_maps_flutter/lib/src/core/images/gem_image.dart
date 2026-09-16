// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:typed_data';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// @nodoc
class GemImage {
  GemImage({this.image, this.format, this.imageId = -1}) {
    _computeAspectRatio();
  }
  final Uint8List? image;
  final ImageFileFormat? format;
  final int? imageId;
  double aspectRatioX = 1.0;
  double aspectRatioY = 1.0;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (image != null) {
      json['image'] = image;
    }
    if (format != null) {
      json['format'] = format!.id;
    }
    if (imageId != null) {
      json['imageId'] = imageId;
    }

    json['aspectRatioX'] = aspectRatioX;
    json['aspectRatioY'] = aspectRatioY;

    return json;
  }

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  static GemImage fromJson(final Map<String, dynamic> json) {
    return GemImage(
      image: utf8.encode(json['image']),
      format: ImageFileFormatExtension.fromId(json['format']),
      imageId: json['imageId'],
    );
  }

  @override
  bool operator ==(covariant final GemImage other) {
    if (identical(this, other)) {
      return true;
    }

    return other.image == image &&
        other.format == format &&
        other.imageId == imageId;
  }

  (int, int)? _getImageDimensionsPng(final Uint8List imageData) {
    if (imageData[0] == 0x89 &&
        imageData[1] == 0x50 &&
        imageData[2] == 0x4E &&
        imageData[3] == 0x47) {
      // PNG Width/Height are stored at bytes 16-23
      final int width = imageData.buffer.asByteData().getUint32(16);
      final int height = imageData.buffer.asByteData().getUint32(20);
      return (width, height);
    }
    return null;
  }

  (int, int)? _getImageDimensionsJpeg(final Uint8List imageData) {
    if (imageData[0] == 0xFF && imageData[1] == 0xD8) {
      int offset = 2;
      while (offset < imageData.length) {
        if (imageData[offset] == 0xFF) {
          final int marker = imageData[offset + 1];
          final int length =
              imageData.buffer.asByteData().getUint16(offset + 2) + 2;

          // Check for SOF0 marker (start of frame) where dimensions are stored
          if (marker == 0xC0 || marker == 0xC2) {
            final int height = imageData.buffer.asByteData().getUint16(
              offset + 5,
            );
            final int width = imageData.buffer.asByteData().getUint16(
              offset + 7,
            );
            return (width, height);
          }

          offset += length;
        } else {
          break; // Invalid JPEG format
        }
      }
    }
    return null;
  }

  (int, int)? _getImageDimensionsBmp(final Uint8List imageData) {
    if (imageData[0] == 0x42 && imageData[1] == 0x4D) {
      // BMP Width/Height are stored at bytes 18-25 (4 bytes each)
      final int width = imageData.buffer.asByteData().getUint32(
        18,
        Endian.little,
      );
      final int height = imageData.buffer.asByteData().getUint32(
        22,
        Endian.little,
      );
      return (width, height);
    }
    return null;
  }

  (int, int)? _getImageDimensionsGif(final Uint8List imageData) {
    if (imageData.length < 10) {
      return null; // Not enough data for a GIF header
    }

    // Check for GIF signature ("GIF" at the start, followed by "87a" or "89a" version)
    if (imageData[0] == 0x47 && imageData[1] == 0x49 && imageData[2] == 0x46) {
      final int width = imageData.buffer.asByteData().getUint16(
        6,
        Endian.little,
      );
      final int height = imageData.buffer.asByteData().getUint16(
        8,
        Endian.little,
      );
      return (width, height);
    }
    // Not a GIF file
    return null;
  }

  (int, int) _getImageDimensions(
    final Uint8List imageData,
    final ImageFileFormat format,
  ) {
    if (imageData.length < 24) {
      return (1, 1); // Not enough data
    }
    switch (format) {
      case ImageFileFormat.png:
        return _getImageDimensionsPng(imageData) ?? (1, 1);
      case ImageFileFormat.jpeg:
        return _getImageDimensionsJpeg(imageData) ?? (1, 1);
      case ImageFileFormat.bmp:
        return _getImageDimensionsBmp(imageData) ?? (1, 1);
      case ImageFileFormat.gif:
        return _getImageDimensionsGif(imageData) ?? (1, 1);
      case ImageFileFormat.autoDetect:
        return _getImageDimensionsPng(imageData) ??
            _getImageDimensionsJpeg(imageData) ??
            _getImageDimensionsBmp(imageData) ??
            (1, 1);

      case ImageFileFormat.tga:
        return (1, 1);
      case ImageFileFormat.pvrtc:
        return (1, 1);
    }
  }

  void _computeAspectRatio() {
    if (image != null) {
      final (int, int) imgDimensions = _getImageDimensions(image!, format!);
      if (imgDimensions.$1 > imgDimensions.$2) {
        aspectRatioX =
            imgDimensions.$1.toDouble() / imgDimensions.$2.toDouble();
        aspectRatioY = 1.0;
      } else if (imgDimensions.$1 < imgDimensions.$2) {
        aspectRatioX = 1.0;
        aspectRatioY =
            imgDimensions.$2.toDouble() / imgDimensions.$1.toDouble();
      } else {
        aspectRatioX = 1.0;
        aspectRatioY = 1.0;
      }
    }
  }

  @override
  int get hashCode {
    return image.hashCode ^ format.hashCode ^ imageId.hashCode;
  }
}
