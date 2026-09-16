// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:typed_data';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Information about a single overlay dataset.
///
/// Contains metadata for an overlay (UID, name, image) and provides access to the
/// overlay's category hierarchy. Instances are provided by [OverlayService] and
/// should not be created directly by consumers.
///
/// ## See also:
///
/// - [OverlayService] - Methods to discover and manage overlays.
/// - [OverlayItem.overlayInfo] - Retrieve the overlay info for an item.
/// - [CommonOverlayId] - Predefined common overlay identifiers.
///
/// {@category Overlays}
class OverlayInfo extends GemAutoreleaseObject {
  // ignore: unused_element
  OverlayInfo._() : super(-1);

  @internal
  OverlayInfo.init(super.id);

  /// Get the categories that belong to this overlay.
  ///
  /// The returned list contains the top-level categories; each [OverlayCategory]
  /// may contain nested subcategories.
  ///
  /// ## Returns
  ///
  /// - A list of [OverlayCategory]. The list is empty when there are no categories.
  List<OverlayCategory> get categories {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayInfo',
      'categories',
    );

    final List<OverlayCategory> overlayCategories =
        (resultString['result'] as List<dynamic>)
            .map<OverlayCategory>(
              (final dynamic item) => OverlayCategory.fromJson(item),
            )
            .toList();
    return overlayCategories;
  }

  /// Retrieve a category by its identifier.
  ///
  /// ## Parameters
  ///
  /// - [categId]: The category identifier to look up.
  ///
  /// ## Returns
  ///
  /// - The matching [OverlayCategory], or null if the category was not found.
  OverlayCategory? getCategory(final int categId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayInfo',
      'getCategory',
      args: categId,
    );

    if (resultString['result']['uid'] == 0) {
      return null;
    }
    return OverlayCategory.fromJson(resultString['result']);
  }

  /// Get the overlay image as raw bytes.
  ///
  /// ## Returns
  ///
  /// - The image bytes if available, otherwise null.
  Uint8List? get image {
    return img.getRenderableImageBytes();
  }

  /// Get the image as a [Img].
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [image] when you only need raw image bytes.
  ///
  /// ## Returns
  ///
  /// - An [Img] instance representing the overlay icon.
  Img get img {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayInfo',
      'getImg',
    );

    return Img.init(resultString['result']);
  }

  /// Get the overlay display name.
  ///
  /// Depends on the current language setting.
  ///
  /// ## Returns
  ///
  /// - The overlay name as a [String].
  String get name {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayInfo',
      'name',
    );

    return resultString['result'];
  }

  /// Get the unique identifier for this overlay dataset.
  ///
  /// ## Returns
  ///
  /// - The [OverlayInfo] UID as an integer.
  int get uid {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayInfo',
      'uid',
    );

    return resultString['result'];
  }

  /// Check whether a category contains nested subcategories.
  ///
  /// ## Parameters
  ///
  /// - [categId]: ID of the [OverlayCategory] to inspect.
  ///
  /// ## Returns
  ///
  /// - True if the category has subcategories, false otherwise.
  bool hasCategories(final int categId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayInfo',
      'hasCategories',
      args: categId,
    );

    return resultString['result'];
  }
}
