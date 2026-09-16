// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// A read-only collection of available overlay datasets.
///
/// Instances are returned by [OverlayService] and provide methods to inspect the
/// overlays available for the current map style (for example to populate UI lists).
/// This class is not intended to be instantiated directly.
///
/// ## See also:
///
/// - [OverlayService.getAvailableOverlays] - Method to retrieve available overlays.
/// - [OverlayInfo] - Information about a single overlay dataset.
///
/// {@category Overlays}
class OverlayCollection extends GemAutoreleaseObject {
  // ignore: unused_element
  OverlayCollection._() : super(-1);

  @internal
  OverlayCollection.init(super.id);

  /// The number of overlays contained in this collection.
  ///
  /// ## Returns
  ///
  /// - The number of overlay datasets as an [int].
  int get size {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayCollection',
      'size',
    );
    return resultString['result'];
  }

  /// Retrieve the overlay at the given index.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the overlay to retrieve.
  ///
  /// ## Returns
  ///
  /// - The corresponding [OverlayInfo], or null if the index is out of bounds.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final collection = OverlayService.getAvailableOverlays().$1;
  /// final info = collection.getOverlayAt(0);
  /// if (info != null) print(info.name);
  /// ```
  OverlayInfo? getOverlayAt(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayCollection',
      'getOverlayAt',
      args: index,
    );
    final int id = resultString['result'];

    if (id == -1) {
      return null;
    }

    return OverlayInfo.init(id);
  }

  /// Find an overlay by its UID.
  ///
  /// ## Parameters
  ///
  /// - [overlayUid]: Unique identifier of the overlay dataset.
  ///
  /// ## Returns
  ///
  /// - The matching [OverlayInfo], or null when not found.
  ///
  /// ## Also see:
  ///
  /// - [CommonOverlayId] - Predefined common overlay identifiers.
  OverlayInfo? getOverlayByUId(final int overlayUid) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayCollection',
      'getOverlayByUid',
      args: overlayUid,
    );
    final int id = resultString['result'];

    if (id == -1) {
      return null;
    }

    return OverlayInfo.init(id);
  }

  /// Check whether a given [OverlayInfo] UID is present in the collection.
  ///
  /// ## Parameters
  ///
  /// - [overlayId]: The overlay UID to check for.
  ///
  /// ## Returns
  ///
  /// - True when the overlay is present, false otherwise.
  ///
  /// ## Also see:
  ///
  /// - [containsCategory] - Check for a specific [OverlayCategory] within an [OverlayInfo].
  /// - [OverlayInfo.uid] - Retrieve the unique identifier of an overlay.
  bool contains(final int overlayId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayCollection',
      'contains',
      args: overlayId,
    );
    return resultString['result'];
  }

  /// Check whether a specific [OverlayCategory] from an [OverlayInfo] is present in the collection.
  ///
  /// ## Parameters
  ///
  /// - [overlayId]: The parent overlay UID.
  /// - [categoryId]: The category identifier within that overlay.
  ///
  /// ## Returns
  ///
  /// - True when the overlay/category pair is present, false otherwise.
  ///
  /// ## Also see:
  ///
  /// - [contains] - Check for an [OverlayInfo] by its UID.
  /// - [OverlayCategory.uid] - Retrieve the unique identifier of a category.
  /// - [OverlayCategory.uid] - Information about an overlay category.
  /// - [OverlayInfo.getCategory] - Retrieve a category by its identifier.
  bool containsCategory(final int overlayId, final int categoryId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayCollection',
      'containsCategory',
      args: <String, int>{'overlayId': overlayId, 'categoryId': categoryId},
    );
    return resultString['result'];
  }

  /// The complete list of [OverlayInfo] entities available in this collection.
  ///
  /// ## Returns
  ///
  /// - A [List] of [OverlayInfo] objects describing each available overlay.
  List<OverlayInfo> get overlayInfos {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayCollection',
      'getOverlays',
    );

    final List<dynamic> res = resultString['result'];
    return res.map((final dynamic e) => OverlayInfo.init(e)).toList();
  }
}

/// Mutable overlay collection with modification operations.
///
/// Extends [OverlayCollection] with methods that add or remove overlays or
/// categories.
///
/// Instances are typically returned by higher-level services such as
/// [AlarmService]. Do not instantiate directly.
///
/// {@category Maps & 3D Scenes}
class OverlayMutableCollection extends OverlayCollection {
  // ignore: unused_element
  OverlayMutableCollection._() : super._();

  @internal
  OverlayMutableCollection.init(super.id) : super.init();

  /// Add an overlay dataset to the collection.
  ///
  /// If the overlay provides categories, they are added as well.
  ///
  /// ## Parameters
  ///
  /// - [overlayId]: The unique identifier of the overlay to add.
  ///
  /// ## See also:
  ///
  /// - [OverlayInfo.uid] - Retrieve the unique identifier of an overlay.
  /// - [contains] - Check for a specific [OverlayInfo] within the collection.
  void add(final int overlayId) {
    objectMethod(pointerId, 'OverlayMutableCollection', 'add', args: overlayId);
  }

  /// Add a single category (by id) from an online overlay to the collection.
  ///
  /// ## Parameters
  ///
  /// - [overlayId]: The parent overlay UID.
  /// - [categoryId]: The category identifier inside the overlay.
  ///
  /// ## See also:
  ///
  /// - [OverlayInfo.uid] - Retrieve the unique identifier of an overlay.
  /// - [OverlayCategory.uid] - Retrieve the unique identifier of a category.
  /// - [containsCategory] - Check for a specific [OverlayCategory] within an [OverlayInfo].
  void addCategory({
    required final int overlayId,
    required final int categoryId,
  }) {
    objectMethod(
      pointerId,
      'OverlayMutableCollection',
      'addCategory',
      args: <String, int>{'overlayId': overlayId, 'categoryId': categoryId},
    );
  }

  /// Remove all overlays from the collection.
  void clear() {
    objectMethod(pointerId, 'OverlayMutableCollection', 'clear');
  }

  /// Remove an overlay from the collection.
  ///
  /// ## Parameters
  ///
  /// - [overlayId]: The overlay UID to remove.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] when removal succeeded.
  /// - [GemError.notFound] when the overlay was not present.
  ///
  /// ## See also:
  ///
  /// - [OverlayInfo.uid] - Retrieve the unique identifier of an overlay.
  /// - [contains] - Check for a specific [OverlayInfo] within the collection.
  /// - [removeCategory] - Remove a category (by id) from an overlay in the collection.
  GemError remove(final int overlayId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayMutableCollection',
      'remove',
      args: overlayId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Remove a category (by id) from an overlay in the collection.
  ///
  /// ## Parameters
  ///
  /// - [overlayId]: Parent overlay UID.
  /// - [categoryId]: Category identifier to remove.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] when the category was removed.
  /// - [GemError.notFound] when the overlay or category was not present.
  ///
  /// ## See also:
  ///
  /// - [OverlayInfo.uid] - Retrieve the unique identifier of an overlay.
  /// - [OverlayCategory.uid] - Retrieve the unique identifier of a category.
  /// - [containsCategory] - Check for a specific [OverlayCategory] within an [OverlayInfo].
  /// - [remove] - Remove an overlay with all categories from the collection.
  GemError removeCategory({
    required final int overlayId,
    required final int categoryId,
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayMutableCollection',
      'removeCategory',
      args: <String, int>{'overlayId': overlayId, 'categoryId': categoryId},
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }
}
