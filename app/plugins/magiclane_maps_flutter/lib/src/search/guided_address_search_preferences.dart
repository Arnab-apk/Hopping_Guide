// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Preferences for guided address searches.
///
/// Provides tuning for matching behavior, result volume, and search scope for hierarchical address queries.
/// Use the [GuidedAddressSearchService.preferences] getter to obtain an instance; this class should not be constructed directly.
/// Changes made to the preferences instance affect all subsequent guided address searches.
///
/// The preferences control aspects such as fuzzy matching, automatic level skipping, whether to use onboard data only,
/// and the maximum number of results returned.
///
/// ## See also:
///
/// - [GuidedAddressSearchService]: Service entry points for performing address searches.
/// - [SearchPreferences] - General search preferences for other search operations provided by the [SearchService].
///
/// {@category Search}
class GuidedAddressSearchPreferences extends GemAutoreleaseObject {
  // ignore: unused_element
  GuidedAddressSearchPreferences._() : super(-1);

  @internal
  GuidedAddressSearchPreferences.init(super.id);

  /// Whether fuzzy search results are allowed.
  ///
  /// Default is true.
  ///
  /// When true, the search engine may return fuzzy (approximate) matches.
  bool get allowFuzzyResults {
    final OperationResult resultString = objectMethod(
      pointerId,
      'GuidedAddressSearchPreferences',
      'getAllowFuzzyResults',
    );

    return resultString['result'];
  }

  /// Enable or disable fuzzy search results.
  ///
  /// Default is true.
  ///
  /// ## Parameters
  ///
  /// - [bAllow]: True to allow fuzzy search results.
  set allowFuzzyResults(final bool bAllow) {
    objectMethod(
      pointerId,
      'GuidedAddressSearchPreferences',
      'setAllowFuzzyResults',
      args: bAllow,
    );
  }

  /// Whether automatic level skipping is enabled.
  ///
  /// When enabled, the engine will automatically skip an intermediate level if there is only one result at the current
  /// level and only one possible next level to search.
  bool get automaticLevelSkip {
    final OperationResult resultString = objectMethod(
      pointerId,
      'GuidedAddressSearchPreferences',
      'getAutomaticLevelSkip',
    );

    return resultString['result'];
  }

  /// Enable or disable automatic level skipping.
  ///
  /// ## Parameters
  ///
  /// - [enableAutomaticLevelSkip]: True to enable automatic skipping of intermediate levels when appropriate.
  set automaticLevelSkip(final bool enableAutomaticLevelSkip) {
    objectMethod(
      pointerId,
      'GuidedAddressSearchPreferences',
      'setAutomaticLevelSkip',
      args: enableAutomaticLevelSkip,
    );
  }

  /// Maximum number of matches returned by address searches.
  ///
  /// Default is 40.
  int get maximumMatches {
    final OperationResult resultString = objectMethod(
      pointerId,
      'GuidedAddressSearchPreferences',
      'getMaximumMatches',
    );

    return resultString['result'];
  }

  /// Set the maximum number of matches to return.
  ///
  /// Default is 40.
  ///
  /// ## Parameters
  ///
  /// - [matches]: Maximum number of matches to return.
  set maximumMatches(final int matches) {
    objectMethod(
      pointerId,
      'GuidedAddressSearchPreferences',
      'setMaximumMatches',
      args: matches,
    );
  }

  /// Set whether the search should use onboard data only.
  ///
  /// If true, the search is performed using only local (onboard) data.
  ///
  /// Default is false.
  ///
  /// ## Parameters
  ///
  /// - [searchOnlyOnboard]: True to restrict searches to onboard data only.
  set searchOnlyOnboard(final bool searchOnlyOnboard) {
    objectMethod(
      pointerId,
      'GuidedAddressSearchPreferences',
      'setSearchOnlyOnboard',
      args: searchOnlyOnboard,
    );
  }

  /// Whether the search is restricted to onboard data only.
  ///
  /// Default is false.
  ///
  /// When true, only local data will be used for searches.
  bool get searchOnlyOnboard {
    final OperationResult resultString = objectMethod(
      pointerId,
      'GuidedAddressSearchPreferences',
      'getSearchOnlyOnboard',
    );

    return resultString['result'];
  }

  /// Reset all preferences to their defaults.
  void reset() {
    objectMethod(pointerId, 'GuidedAddressSearchPreferences', 'reset');
  }
}
