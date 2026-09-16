// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';

/// Represents a social report category with hierarchical subcategories.
///
/// Extends [OverlayCategory] with social report-specific metadata including
/// country codes, parameter definitions, and nested subcategory hierarchies.
///
/// Category IDs ([uid]) are stable identifiers used in [SocialOverlay.report].
/// The [parameters] field defines allowed custom parameters for reports.
///
/// Should be obtained via [SocialReportsOverlayInfo] methods. Do not
/// instantiate directly.
///
/// ## See also:
///
/// - [SocialOverlay.report] - Requires category ID from this hierarchy.
/// - [SocialReportsOverlayInfo] - Provides category querying methods.
///
/// {@category Overlays}
class SocialReportsOverlayCategory extends OverlayCategory {
  /// Creates a [SocialReportsOverlayCategory] instance.
  ///
  /// API users should not instantiate directly.
  /// Use the methods provided by [SocialReportsOverlayInfo] instead.
  ///
  /// ## Parameters
  ///
  /// - [img] is the category icon.
  /// - [name] is the category name.
  /// - [overlayuid] is the parent overlay ID.
  /// - [uid] is the category ID.
  /// - [overlaySubcategories] is the list of subcategories.
  /// - [country] is the ISO 3166-1 alpha-3 country code.
  /// - [parameters] is the report category parameters.
  SocialReportsOverlayCategory({
    required super.img,
    required super.name,
    required super.overlayuid,
    required super.uid,
    required this.overlaySubcategories,
    required this.country,
    required this.parameters,
  }) : super(subcategories: overlaySubcategories);

  factory SocialReportsOverlayCategory.fromJson(
    final Map<String, dynamic> json,
  ) {
    return SocialReportsOverlayCategory(
      img: Img.init(json['img']),
      name: json['name'],
      overlayuid: json['overlayuid'],
      overlaySubcategories: json['subcategories'] != null
          ? (json['subcategories'] as List<dynamic>)
                .map(
                  (final dynamic item) => SocialReportsOverlayCategory.fromJson(
                    item as Map<String, dynamic>,
                  ),
                )
                .toList()
          : <SocialReportsOverlayCategory>[],
      uid: json['uid'],
      country: json['country'],
      parameters: SearchableParameterList.init(json['parameters']),
    );
  }

  /// Category ISO 3166-1 alpha-3 country code representation.
  ///
  /// ## Also see:
  ///
  /// - [MapDetails] - Provides country information.
  /// - [ISOCodeConversions] - Utilities for converting between different ISO country code formats.
  String country;

  /// Report category parameters.
  ///
  /// Defines configuration for report submission including
  /// parameter keys, types, currency, validity, and text-to-speech.
  ///
  /// Used for customizing report data in [SocialOverlay.report] or
  /// [SocialOverlay.updateReport].
  SearchableParameterList parameters;

  /// The subcategories of this category.
  ///
  /// Contains nested [SocialReportsOverlayCategory] objects
  /// representing subcategories under this main category.
  List<SocialReportsOverlayCategory> overlaySubcategories;
}
