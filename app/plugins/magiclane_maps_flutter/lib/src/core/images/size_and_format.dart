// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:ui';
import 'package:magiclane_maps_flutter/core.dart';

/// Represents the size and file format for an image.
///
/// A simple immutable holder containing a [Size] and an [ImageFileFormat]. Use
/// this when you need to pass both dimensions and the desired image file
/// format to SDK methods that produce or consume images.
///
/// ## See also:
///
/// - [SdkSettings.getImageById] for obtaining image bytes by id.
/// - [SdkSettings.setDefaultWidthHeightImageFormat] to set the SDK default size
///   and format used when images are returned automatically.
///
/// {@category Images}
class SizeAndFormat {
  /// The constructor for the [SizeAndFormat] class
  SizeAndFormat({required this.size, required this.format});

  /// The size of the image
  final Size size;

  /// The format of the image
  final ImageFileFormat format;

  @override
  bool operator ==(covariant SizeAndFormat other) {
    if (identical(this, other)) {
      return true;
    }

    return other.size == size && other.format == format;
  }

  @override
  int get hashCode => size.hashCode ^ format.hashCode;
}
