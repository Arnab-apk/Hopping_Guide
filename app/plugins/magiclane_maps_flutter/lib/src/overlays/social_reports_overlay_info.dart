// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/routing.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Provides access to social report category hierarchy and metadata.
///
/// Contains methods for querying available report categories and their
/// subcategories. Each category includes configuration for allowed parameters,
/// coordinate-based reporting permissions, and country-specific customizations.
///
/// Obtain instances via [SocialOverlay.reportsOverlayInfo] getter. Do not
/// instantiate directly.
///
/// ## See also:
///
/// - [SocialOverlay.reportsOverlayInfo] - Provides singleton access.
/// - [SocialReportsOverlayCategory] - Individual category with subcategories.
///
/// {@category Overlays}
class SocialReportsOverlayInfo extends OverlayInfo {
  @internal
  SocialReportsOverlayInfo.init(super.id) : super.init();

  /// Retrieves all top-level social report categories for a country.
  ///
  /// Returns the complete list of main categories (Police Car, Fixed Camera,
  /// Traffic, Crash, Road Hazard, Weather Hazard, Road Closure) available for
  /// the specified country. Each category contains subcategories and configuration.
  ///
  /// ## Parameters
  ///
  /// - [country]: ISO country code (e.g., "US", "GB"). Use empty string for
  ///   generic/worldwide categories.
  ///
  /// ## Returns
  ///
  /// List of [SocialReportsOverlayCategory] objects representing main categories.
  ///
  /// ## See also:
  ///
  /// - [getSocialReportsCategory] - Retrieves specific category by ID.
  /// - [MapDetails] - Provides country information.
  List<SocialReportsOverlayCategory> getSocialReportsCategories({
    final String country = '',
  }) {
    final OperationResult operationResult = objectMethod(
      pointerId,
      'SocialReportsOverlayInfo',
      'getSocialReportsCategories',
      args: country,
    );

    final List<dynamic> list = operationResult['result'];
    return list
        .map(
          (final dynamic categoryJson) =>
              SocialReportsOverlayCategory.fromJson(categoryJson),
        )
        .toList();
  }

  /// Retrieves a specific social report category or subcategory by ID.
  ///
  /// Looks up category using the unique [categId] identifier. Supports both
  /// main categories (e.g., Traffic 768) and subcategories (e.g., Heavy Traffic
  /// 771). Returns `null` if category not found for the specified country.
  ///
  /// ## Parameters
  ///
  /// - [categId]: Unique category or subcategory identifier. See
  ///   [SocialReportsOverlayCategory] for standard IDs.
  /// - [country]: ISO country code (e.g., "US", "GB"). Use empty string for
  ///   generic/worldwide categories.
  ///
  /// ## Returns
  ///
  /// [OverlayCategory] if found, otherwise `null`.
  ///
  /// ## See also:
  ///
  /// - [getSocialReportsCategories] - Retrieves all main categories.
  /// - null if the category is not found.
  /// - [MapDetails] - Provides country information.
  SocialReportsOverlayCategory? getSocialReportsCategory(
    final int categId, {
    final String country = '',
  }) {
    final OperationResult result = objectMethod(
      pointerId,
      'SocialReportsOverlayInfo',
      'getSocialReportsCategory',
      args: <String, dynamic>{'categId': categId, 'country': country},
    );
    if (result['result']['uid'] == 0) {
      return null;
    }
    return SocialReportsOverlayCategory.fromJson(result['result']);
  }
}
