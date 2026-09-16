// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/src/core/landmark/generic_categories_ids.dart';
import 'package:magiclane_maps_flutter/src/core/landmark/landmark_category.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Utilities for working with generic categories used to group landmarks and
/// points of interest (POIs).
///
/// [GenericCategories] exposes convenience helpers to enumerate the built-in
/// generic categories, to resolve a generic category or POI category to a
/// [LandmarkCategory], and to inspect the landmark store id used by the SDK.
///
/// ## See also:
///
/// - [GenericCategoriesId] — predefined enum of built-in generic categories.
/// - [LandmarkCategory] — the rich category object returned by these helpers.
///
/// {@category Landmarks}
abstract class GenericCategories {
  /// Returns all known generic categories.
  ///
  /// This getter returns a `List<LandmarkCategory>` containing the generic
  /// categories available in the SDK. On platform errors or when no
  /// categories are available an empty list is returned.
  ///
  /// ## Returns
  ///
  /// - `List<LandmarkCategory>`: the list of generic categories; empty when
  ///   none are available.
  static List<LandmarkCategory> get categories {
    final OperationResult resultString = staticMethod(
      'GenericCategories',
      'getCategories',
    );

    if (resultString['result'] == -1) {
      return <LandmarkCategory>[];
    }

    return LandmarkCategoryList.init(resultString['result']).toList();
  }

  /// Returns scalar metadata for all generic categories in a single call.
  ///
  /// Lightweight alternative to [categories] that returns only the scalar
  /// fields of each category and holds no native handles. Useful when the
  /// category image is not needed; resolve images lazily via [getCategory]
  /// when required.
  ///
  /// Each entry contains the keys `id` (`int`), `name` (`String`) and
  /// `landmarkStoreId` (`int`). The `name` is localized to the current SDK
  /// UI language.
  ///
  /// ## Returns
  ///
  /// - `List<Map<String, dynamic>>`: metadata for the generic categories;
  ///   empty when none are available.
  static List<Map<String, dynamic>> get categoriesMetadata {
    final OperationResult resultString = staticMethod(
      'GenericCategories',
      'getCategoriesMetadata',
    );

    final List<dynamic>? results = resultString['result'] as List<dynamic>?;
    if (results == null) {
      return <Map<String, dynamic>>[];
    }

    return results
        .map(
          (final dynamic item) =>
              Map<String, dynamic>.from(item as Map<dynamic, dynamic>),
        )
        .toList();
  }

  /// Returns the generic category for [id].
  ///
  /// The [id] may be one of the built-in values exposed by
  /// [GenericCategoriesId] (use [GenericCategoriesIdExtension.id] to obtain
  /// the numeric id) or a custom category id
  ///
  /// ## Parameters
  ///
  /// - [id]: Integer identifier of the generic category to resolve or the
  ///  custom category id.
  ///
  /// ## Returns
  ///
  /// - `LandmarkCategory?`: The resolved category when found, otherwise `null`.
  static LandmarkCategory? getCategory(final int id) {
    final OperationResult resultString = staticMethod(
      'GenericCategories',
      'getCategory',
      args: id,
    );

    if (resultString['result'] == -1) {
      return null;
    }
    return LandmarkCategory.init(resultString['result']);
  }

  /// Maps a POI category id to its parent generic category.
  ///
  /// Use this method when you have a POI category identifier (for example
  /// obtained from [GenericCategories.getPoiCategories] or landmark search
  /// results) and need its corresponding generic category.
  ///
  /// ## Parameters
  ///
  /// - [poiCategory]: The POI category id to map.
  ///
  /// ## Returns
  ///
  /// - `LandmarkCategory?`: The parent generic category, or `null` if none was found.
  static LandmarkCategory? getGenericCategory(final int poiCategory) {
    final OperationResult resultString = staticMethod(
      'GenericCategories',
      'getGenericCategory',
      args: poiCategory,
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return LandmarkCategory.init(resultString['result']);
  }

  /// The landmark store id associated with generic categories.
  ///
  /// The SDK exposes a dedicated landmark store that contains the generic
  /// categories. This getter returns the integer store id used by that store.
  ///
  /// Cannot be used to get the associated [LandmarkStore] instance.
  ///
  /// ## Returns
  ///
  /// - `int`: The landmark store identifier.
  static int get landmarkStoreId {
    final OperationResult resultString = staticMethod(
      'GenericCategories',
      'getLandmarkStoreId',
    );

    return resultString['result'];
  }

  /// Returns POI categories that belong to [genericCategory].
  ///
  /// The returned list contains [LandmarkCategory] entries that represent the
  /// POI subcategories for the supplied generic category id. If the category
  /// id is invalid or no POI categories are available an empty list is
  /// returned.
  ///
  /// ## Parameters
  ///
  /// - [genericCategory]: Numeric id of the generic category (see [GenericCategoriesId]).
  ///
  /// ## Returns
  ///
  /// - `List<LandmarkCategory>`: POI categories for the generic category, or
  ///   an empty list when none are available.
  static List<LandmarkCategory> getPoiCategories(final int genericCategory) {
    final OperationResult resultString = staticMethod(
      'GenericCategories',
      'getPoiCategories',
      args: genericCategory,
    );

    if (resultString['result'] == -1) {
      return <LandmarkCategory>[];
    }

    return LandmarkCategoryList.init(resultString['result']).toList();
  }
}
