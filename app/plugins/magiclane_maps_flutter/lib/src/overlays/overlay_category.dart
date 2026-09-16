// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:typed_data';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Represents a single category within an overlay.
///
/// A category is a node in an overlay's hierarchical classification. It contains a
/// display label, an icon, a stable identifier and a reference to its parent overlay.
/// Categories may contain nested subcategories which form the overlay's hierarchy.
///
/// ## See also:
///
/// - [OverlayInfo]: Parent overlay information that exposes categories for a dataset.
///
/// {@category Overlays}
class OverlayCategory {
  /// Create a new [OverlayCategory] instance.
  ///
  /// This constructor is used when an overlay category is decoded from a JSON
  /// structure returned by the platform layer.
  ///
  /// ## Parameters
  ///
  /// - [name]: The category display name.
  /// - [overlayuid]: ID of the parent overlay dataset.
  /// - [subcategories]: Nested child categories.
  /// - [uid]: Stable category identifier.
  /// - [img]: Icon data for the category.
  OverlayCategory({
    required this.name,
    required this.overlayuid,
    required this.subcategories,
    required this.uid,
    required this.img,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory OverlayCategory.fromJson(final Map<String, dynamic> json) {
    return OverlayCategory(
      img: Img.init(json['img']),
      name: json['name'],
      overlayuid: json['overlayuid'],
      subcategories: json['subcategories'] != null
          ? (json['subcategories'] as List<dynamic>)
                .map((final dynamic item) => OverlayCategory.fromJson(item))
                .toList()
          : <OverlayCategory>[],
      uid: json['uid'],
    );
  }

  /// The category icon as raw bytes suitable for rendering.
  Uint8List? get image => img.getRenderableImageBytes();

  /// The category display name.
  String name;

  /// The parent [OverlayInfo] UID.
  int overlayuid;

  /// Nested subcategories of this category.
  List<OverlayCategory> subcategories;

  /// True when this category contains one or more subcategories.
  bool get hasSubcategories => subcategories.isNotEmpty;

  /// Stable [OverlayCategory] identifier.
  int uid;

  /// The category icon as an [Img] wrapper.
  Img img;
}
