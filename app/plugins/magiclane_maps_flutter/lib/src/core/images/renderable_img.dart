// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:typed_data';
import 'dart:ui';

/// Container for rendered image data with bytes and dimensions.
///
/// Packages image bytes together with actual rendered width and height in pixels.
/// Returned by [ImgBase.getRenderableImage] and subclass implementations. Use
/// when you need to know the final dimensions of the rendered image, especially
/// important for vector images with `allowResize` enabled where the SDK chooses
/// optimal aspect ratio.
///
/// ## See also:
///
/// - [ImgBase.getRenderableImage] - Returns this container with image data
/// - [ImgBase.getRenderableImageBytes] - Returns only bytes without dimensions
///
/// {@category Images}
class RenderableImg {
  /// Creates a container for rendered image data.
  ///
  /// API users usually do not need to instantiate this directly - use
  /// [ImgBase.getRenderableImage] to obtain instances.
  ///
  /// ## Parameters
  ///
  /// - [width] - Rendered image width in pixels
  /// - [height] - Rendered image height in pixels
  /// - [bytes] - Raw image data suitable for [Image.memory]
  RenderableImg(this.width, this.height, this.bytes);

  /// Rendered image width in pixels.
  final int width;

  /// Rendered image height in pixels.
  final int height;

  /// Rendered image bytes suitable for display with [Image.memory].
  ///
  /// Contains the same data returned by [ImgBase.getRenderableImageBytes].
  final Uint8List bytes;

  /// Rendered image dimensions as [Size].
  ///
  /// It contains the rendered width and height which can be different from
  /// the requested size when `allowResize` is enabled in subclasses. It can also
  /// be different from the recommended size if custom sizes were provided.
  ///
  /// ## Returns
  ///
  /// - [Size] with width and height as doubles
  Size get size => Size(width.toDouble(), height.toDouble());
}

/// Enumerates known image file formats.
///
/// Supported image file formats.
///
/// Enumerates the image file formats that the SDK can produce or accept
/// when rendering images (for example via [ImgBase.getRenderableImage]).
///
/// Some formats may not be supported on all platforms.
///
/// {@category Images}
enum ImageFileFormat {
  /// BMP image file format.
  bmp,

  /// JPEG image file format.
  jpeg,

  /// GIF image file format.
  gif,

  /// PNG image file format.
  png,

  /// TGA image file format.
  tga,

  /// WebP image file format
  pvrtc,

  /// Automatically detect image file format.
  autoDetect,
}

/// @nodoc
extension ImageFileFormatExtension on ImageFileFormat {
  int get id {
    switch (this) {
      case ImageFileFormat.bmp:
        return 0;
      case ImageFileFormat.jpeg:
        return 1;
      case ImageFileFormat.gif:
        return 2;
      case ImageFileFormat.png:
        return 3;
      case ImageFileFormat.tga:
        return 4;
      case ImageFileFormat.pvrtc:
        return 5;
      case ImageFileFormat.autoDetect:
        return 6;
    }
  }

  static ImageFileFormat fromId(final int id) {
    switch (id) {
      case 0:
        return ImageFileFormat.bmp;
      case 1:
        return ImageFileFormat.jpeg;
      case 2:
        return ImageFileFormat.gif;
      case 3:
        return ImageFileFormat.png;
      case 4:
        return ImageFileFormat.tga;
      case 5:
        return ImageFileFormat.pvrtc;
      case 6:
        return ImageFileFormat.autoDetect;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
