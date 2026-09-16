// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// # Search
///
/// Provides APIs for address, category, and guided search.
///
/// This library covers the main interfaces and classes for address search, category search, guided address search, and search preferences.
///
/// ## Main features
/// - [AddressInfo] – Structure for address information.
/// - [GenericCategories], [GenericCategoriesId] – Predefined category data and identifiers for search.
/// - [GuidedAddressSearchService] – Guided search for addresses.
/// - [SearchPreferences] – Preferences for search operations.
/// - [SearchService] – Main class for performing search queries.
///
/// ## More details
///
/// - See the [Search documentation](https://developer.magiclane.com/docs/flutter/guides/category/search) for more information.
library;

export 'src/core/landmark/address_info.dart';
export 'src/core/landmark/generic_categories.dart';
export 'src/core/landmark/generic_categories_ids.dart';
export 'src/search/guided_address_search.dart';
export 'src/search/guided_address_search_preferences.dart';
export 'src/search/search_preferences.dart';
export 'src/search/search_service.dart';
