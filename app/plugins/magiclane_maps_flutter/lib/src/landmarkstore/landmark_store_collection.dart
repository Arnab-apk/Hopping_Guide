// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/landmark_store.dart';
import 'package:magiclane_maps_flutter/src/core/common/gem_error.dart';
import 'package:magiclane_maps_flutter/src/core/landmark/landmark_category.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Collection of landmark stores and their enabled categories.
///
/// [LandmarkStoreCollection] represents a set of landmark stores and the category ids
/// that are enabled for each store. It is not intended to be created directly; obtain
/// an instance via [MapViewPreferences.lmks]. Typical uses include toggling visible
/// categories for map UI, checking if a store or store/category pair is present, and
/// iterating or clearing the collection.
///
/// ## See also:
///
/// - [MapViewPreferences.lmks] — obtain the active collection for a map view.
/// - [LandmarkStore] — store model used by the collection.
///
/// {@category Landmark Store}
class LandmarkStoreCollection extends GemAutoreleaseObject {
  // ignore: unused_element
  LandmarkStoreCollection._() : _mapPointerId = -1, super(-1);

  @internal
  LandmarkStoreCollection.init(super.id, final int mapPointerId)
    : _mapPointerId = mapPointerId;
  final int _mapPointerId;

  int get mapPointerId => _mapPointerId;

  /// Adds all categories from [lms] into this collection.
  ///
  /// ## Parameters
  ///
  /// - [lms]: The source [LandmarkStore] whose categories will be added.
  ///
  /// ## Returns
  ///
  /// - [GemError]: [GemError.success] on success; [GemError.notFound] when the
  ///   store cannot be found.
  GemError add(final LandmarkStore lms) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'addAllStoreCategories',
      args: lms.id,
      dependencyId: _mapPointerId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Adds all categories from the store identified by [storeId] into this collection.
  ///
  /// ## Parameters
  ///
  /// - [storeId]: Identifier of the source store.
  ///
  /// ## Returns
  ///
  /// - [GemError]: [GemError.success] on success; [GemError.notFound] when the
  ///   specified store cannot be found.
  GemError addAllStoreCategories(final int storeId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'addAllStoreCategories',
      args: storeId,
      dependencyId: _mapPointerId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Adds a single category id to the specified store entry in the collection.
  ///
  /// ## Parameters
  ///
  /// - [storeId]: The target store id.
  /// - [categoryId]: The category id to add.
  ///
  /// ## Returns
  ///
  /// - [GemError]: [GemError.success] on success; [GemError.notFound] when the
  ///   store or category id could not be found.
  GemError addStoreCategoryId(final int storeId, final int categoryId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'addStoreCategoryId',
      args: <String, int>{'storeId': storeId, 'categoryId': categoryId},
      dependencyId: _mapPointerId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Adds multiple categories to the specified store in a single operation.
  ///
  /// ## Parameters
  ///
  /// - [storeId]: The target store id.
  /// - [categories]: List of [LandmarkCategory] objects to add.
  ///
  /// ## Returns
  ///
  /// - [GemError]: [GemError.success] on success; [GemError.notFound] when the
  ///   store or one of the category ids cannot be found.
  GemError addStoreCategoryList(
    final int storeId,
    final List<LandmarkCategory> categories,
  ) {
    final LandmarkCategoryList categoryList = LandmarkCategoryList();
    categories.forEach(categoryList.add);

    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'addStoreCategoryList',
      args: <String, dynamic>{
        'storeId': storeId,
        'categories': categoryList.pointerId,
      },
      dependencyId: _mapPointerId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Removes all stores and category entries from this collection.
  void clear() {
    objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'clear',
      dependencyId: _mapPointerId,
    );
  }

  /// Returns whether the given [storeId] and [categoryId] pair exists in the collection.
  ///
  /// ## Parameters
  ///
  /// - [storeId]: The store id to check.
  /// - [categoryId]: The category id to check.
  ///
  /// ## Returns
  ///
  /// - [bool]: `true` when the pair is present; otherwise `false`.
  bool contains(final int storeId, final int categoryId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'contains',
      args: <String, int>{'storeId': storeId, 'categoryId': categoryId},
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Returns whether the provided [lms] has any enabled category in this collection.
  ///
  /// ## Parameters
  ///
  /// - [lms]: The [LandmarkStore] to query.
  ///
  /// ## Returns
  ///
  /// - [bool]: `true` if [lms] has at least one category in the collection.
  bool containsLandmarkStore(final LandmarkStore lms) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'containsLandmarkStore',
      args: lms.pointerId,
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Returns whether the store identified by [storeId] has any enabled category.
  ///
  /// ## Parameters
  ///
  /// - [storeId]: The store id to check.
  ///
  /// ## Returns
  ///
  /// - [bool]: `true` if the store has at least one category in the collection.
  bool containsStoreId(final int storeId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'containsStoreId',
      args: storeId,
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Returns the number of category ids enabled for [storeId].
  ///
  /// ## Parameters
  ///
  /// - [storeId]: The store id to query.
  ///
  /// ## Returns
  ///
  /// - [int]: The number of enabled categories for the store on success.
  /// - `GemError.notFound.code`: When the store id is not present in the collection.
  int getCategoryCount(final int storeId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'getCategoryCount',
      args: storeId,
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Returns the category id at position [indexCategory] for the store [storeId].
  ///
  /// ## Parameters
  ///
  /// - [storeId]: The store id to query.
  /// - [indexCategory]: Zero-based index of the category to retrieve.
  ///
  /// ## Returns
  ///
  /// - [int]: The category id on success.
  /// - `GemError.notFound.code`: When the store id is not present in the collection.
  /// - `GemError.outOfRange.code`: When [indexCategory] is out of range.
  int getStoreCategoryId(final int storeId, final int indexCategory) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'getStoreCategoryId',
      args: <String, int>{'storeId': storeId, 'indexCategory': indexCategory},
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Returns the store id at the given zero-based [index] in the collection.
  ///
  /// ## Parameters
  ///
  /// - [index]: The index to query; it must be less than [size].
  ///
  /// ## Returns
  ///
  /// - [int]: Store id on success (> 0).
  /// - `GemError.outOfRange.code`: When [index] is out of range.
  int getStoreIdAt(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'getStoreIdAt',
      args: index,
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Removes all category ids associated with the given [lms] from the collection.
  ///
  /// ## Parameters
  ///
  /// - [lms]: The [LandmarkStore] whose categories should be removed.
  ///
  /// ## Returns
  ///
  /// - [GemError]: [GemError.success] on success; [GemError.notFound] when the
  ///   store is not in the collection.
  GemError remove(final LandmarkStore lms) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'remove',
      args: lms.pointerId,
      dependencyId: _mapPointerId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Removes all categories associated with the store identified by [storeId].
  ///
  /// ## Parameters
  ///
  /// - [storeId]: The store id whose categories should be removed.
  ///
  /// ## Returns
  ///
  /// - [GemError]: [GemError.success] on success; [GemError.notFound] when
  ///   the store id is not in the collection.
  GemError removeAllStoreCategories(final int storeId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'removeAllStoreCategories',
      args: storeId,
      dependencyId: _mapPointerId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Removes [categoryId] from the store identified by [storeId].
  ///
  /// ## Parameters
  ///
  /// - [storeId]: The store id to update.
  /// - [categoryId]: The category id to remove.
  ///
  /// ## Returns
  ///
  /// - [GemError]: [GemError.success] on success; [GemError.notFound] when the
  ///   store or category id cannot be found or is not in the collection.
  GemError removeStoreCategoryId(final int storeId, final int categoryId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'removeStoreCategoryId',
      args: <String, int>{'storeId': storeId, 'categoryId': categoryId},
      dependencyId: _mapPointerId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Returns the number of stores in the collection.
  ///
  /// ## Returns
  ///
  /// - [int]: Count of stores contained in this collection.
  int get size {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStoreCollection',
      'size',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }
}
