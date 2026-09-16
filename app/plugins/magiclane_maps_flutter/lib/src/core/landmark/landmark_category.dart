// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Represents a landmark category used to classify landmarks and POIs.
///
/// A [LandmarkCategory] defines a logical grouping for landmarks. Each category has a
/// unique numeric identifier, a localized display name, and an optional image.
/// Categories can be generic (built-in) or custom and may belong to a parent [LandmarkStore].
///
/// A single landmark can belong to multiple categories simultaneously. Use the
/// [GenericCategories] class to access SDK-provided default categories and their POI
/// subcategories.
///
/// ## See also:
/// - [GenericCategories] — access predefined generic categories and POI subcategories.
/// - [GenericCategoriesId] — built-in generic category identifiers.
/// - [LandmarkStore] — store-level grouping of categories and landmarks.
///
/// {@category Landmarks}
class LandmarkCategory extends GemAutoreleaseObject {
  /// Creates a new [LandmarkCategory].
  factory LandmarkCategory({final String name = ''}) {
    return LandmarkCategory._create()..name = name;
  }

  factory LandmarkCategory._create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'LandmarkCategory'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return LandmarkCategory.init(decodedVal['result']);
  }

  @internal
  LandmarkCategory.init(super.id);

  /// Returns the numeric identifier for this category.
  ///
  /// The id is the value used by store APIs and search filters.
  ///
  /// ## Returns
  ///
  /// - [int]: The category id.
  int get id {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkCategory',
      'getId',
    );

    return resultString['result'];
  }

  /// Retrieves the category image as raw bytes.
  ///
  /// If the category has no associated image this returns null.
  ///
  /// ## Parameters
  ///
  /// - [size]: Optional preferred image size. When omitted the original size is returned.
  /// - [format]: Optional desired [ImageFileFormat]. If omitted the platform default is used.
  ///
  /// ## Returns
  ///
  /// - [Uint8List?]: Raw image bytes, or null when no image is available.
  ///
  /// ## See also:
  ///
  /// - [img] - Retrieves the category image wrapped in an [Img] helper object.
  Uint8List? getImage({final Size? size, final ImageFileFormat? format}) {
    return GemKitPlatform.instance.callGetImage(
      pointerId,
      'LandmarkCategory',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
    );
  }

  /// Get the image as a [Img].
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getImage] when you only need raw image bytes.
  ///
  /// ## Returns
  ///
  /// - [Img]: The image wrapper instance.
  Img get img {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkCategory',
      'getImg',
    );

    return Img.init(resultString['result']);
  }

  /// Assigns an [Img] as the category image.
  ///
  /// ## Parameters
  ///
  /// - [img]: The [Img] instance to set as the category icon.
  set img(final Img img) {
    objectMethod(pointerId, 'LandmarkCategory', 'setImg', args: img.pointerId);
  }

  /// Returns the localized display name for this category.
  ///
  /// The name is typically localized according to the SDK language settings for
  /// built-in categories. For custom categories the name is the value assigned by the
  /// creator.
  ///
  /// ## Returns
  ///
  /// - [String]: The category name.
  String get name {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkCategory',
      'getName',
    );

    return resultString['result'];
  }

  /// Sets the display name for this category.
  ///
  /// ## Parameters
  ///
  /// - [name]: The localized or user-defined name to assign to the category.
  set name(final String name) {
    objectMethod(pointerId, 'LandmarkCategory', 'setName', args: name);
  }

  /// Returns the parent landmark store identifier when this is a store-scoped category.
  ///
  /// For categories that are not associated with a specific [LandmarkStore] the SDK
  /// returns the `GemError.notFound.code` value.
  ///
  /// ## Returns
  ///
  /// - [int]: The parent landmark store id, or the `GemError.notFound.code` sentinel
  ///   when no parent store is present.
  ///
  /// ## See also:
  ///
  /// - [LandmarkStore] — Represents a collection of landmarks and categories.
  /// - [LandmarkStoreService.getLandmarkStoreById] — Retrieves the [LandmarkStore] by its ID.
  int get landmarkStoreId {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkCategory',
      'getLandmarkStoreId',
    );

    return resultString['result'];
  }
}
