// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/landmarkstore/landmark_store_collection.dart';
import 'package:meta/meta.dart';

/// Preferences for search operations from [SearchService].
///
/// Configures how search APIs behave: matching fuzziness, whether addresses or POIs are included,
/// limits on result volume, and whether searches should use onboard (offline) data only. Use this
/// object to prepare parameters before calling search APIs.
///
/// ## See also:
///
/// - [SearchService]: Entry points for performing search operations.
/// - [GuidedAddressSearchPreferences]: Preferences specific to guided address searches via [GuidedAddressSearchService].
///
/// {@category Search}
class SearchPreferences extends GemAutoreleaseObject {
  /// Create a [SearchPreferences] instance with the selected options.
  ///
  /// More detailed configuration can be done via the individual property setters,
  ///
  /// ## Parameters
  ///
  /// - [allowFuzzyResults]: Allow fuzzy (approximate) search matches. Default: true.
  /// - [estimateMissingHouseNumbers]: Enable estimation of house numbers missing from map data. Default: true.
  /// - [exactMatch]: Require exact token matches. Default: false.
  /// - [maxMatches]: Maximum number of results to return. Default: 40.
  /// - [searchAddresses]: Include addresses (and roads) in search results. Default: true.
  /// - [searchMapPOIs]: Include map POIs in search results. Default: true.
  /// - [searchOnlyOnboard]: Restrict searches to onboard (offline) data. Default: false.
  /// - [thresholdDistance]: Maximum distance (in meters) from the reference used to filter results. Default: 2147483647.
  /// - [easyAccessOnlyResults]: Restrict results to locations with easy access. Default: false.
  factory SearchPreferences({
    final bool allowFuzzyResults = true,
    final bool estimateMissingHouseNumbers = true,
    final bool exactMatch = false,
    final int maxMatches = 40,
    final bool searchAddresses = true,
    final bool searchMapPOIs = true,
    final bool searchOnlyOnboard = false,
    final int thresholdDistance = 2147483647,
    final bool easyAccessOnlyResults = false,
  }) {
    final SearchPreferences result = SearchPreferences._create();
    result.allowFuzzyResults = allowFuzzyResults;
    result.estimateMissingHouseNumbers = estimateMissingHouseNumbers;
    result.exactMatch = exactMatch;
    result.maxMatches = maxMatches;
    result.searchAddresses = searchAddresses;
    result.searchMapPOIs = searchMapPOIs;
    result.searchOnlyOnboard = searchOnlyOnboard;
    result.thresholdDistance = thresholdDistance;
    result.easyAccessOnlyResults = easyAccessOnlyResults;
    return result;
  }

  @internal
  SearchPreferences.init(super.id);

  /// Whether fuzzy search results are allowed.
  ///
  /// When true, the search engine may return approximate matches for queries. Default is true.
  ///
  /// ## Returns
  ///
  /// - True if fuzzy results are allowed, false otherwise.
  bool get allowFuzzyResults {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SearchPreferences',
      'getallowfuzzyresults',
    );

    return resultString['result'];
  }

  /// Enable or disable fuzzy search results.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to allow fuzzy results, false to require stricter matching.
  set allowFuzzyResults(final bool value) {
    objectMethod(
      pointerId,
      'SearchPreferences',
      'setallowfuzzyresults',
      args: value,
    );
  }

  /// Whether estimation of missing house numbers is enabled.
  ///
  /// When true, the search engine will attempt to infer house numbers not present in map data. Default is true.
  ///
  /// ## Returns
  ///
  /// - True if estimation is enabled, false otherwise.
  bool get estimateMissingHouseNumbers {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SearchPreferences',
      'getestimatemissinghousenumbers',
    );

    return resultString['result'];
  }

  /// Enable or disable estimation of missing house numbers.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to enable estimation, false to disable.
  set estimateMissingHouseNumbers(final bool value) {
    objectMethod(
      pointerId,
      'SearchPreferences',
      'setestimatemissinghousenumbers',
      args: value,
    );
  }

  /// Whether exact-match mode is enabled.
  ///
  /// When true, only exact matches are returned. Default is false.
  ///
  /// ## Returns
  ///
  /// - True if exact match is used, false otherwise.
  bool get exactMatch {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SearchPreferences',
      'getexactmatch',
    );

    return resultString['result'];
  }

  /// Enable or disable exact-match behavior.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to require exact matches, false to allow fuzzy or partial matches.
  set exactMatch(final bool value) {
    objectMethod(pointerId, 'SearchPreferences', 'setexactmatch', args: value);
  }

  /// Maximum number of matches returned by search operations.
  ///
  /// Default is 40.
  ///
  /// ## Returns
  ///
  /// - The maximum number of matches.
  int get maxMatches {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SearchPreferences',
      'getmaxmatches',
    );

    return resultString['result'];
  }

  /// Set the maximum number of matches to return.
  ///
  /// ## Parameters
  ///
  /// - [value]: Maximum number of matches.
  set maxMatches(final int value) {
    objectMethod(pointerId, 'SearchPreferences', 'setmaxmatches', args: value);
  }

  /// Whether searching through addresses (including roads) is enabled.
  ///
  /// Default is true.
  ///
  /// ## Returns
  ///
  /// - True if address searches are enabled, false otherwise.
  bool get searchAddresses {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SearchPreferences',
      'getsearchaddresses',
    );

    return resultString['result'];
  }

  /// Enable or disable searching through addresses.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to include addresses in search results, false to exclude them.
  set searchAddresses(final bool value) {
    objectMethod(
      pointerId,
      'SearchPreferences',
      'setsearchaddresses',
      args: value,
    );
  }

  /// Whether searching map POIs is enabled.
  ///
  /// Default is true.
  ///
  /// ## Returns
  ///
  /// - True if POI searches are enabled, false otherwise.
  bool get searchMapPOIs {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SearchPreferences',
      'getsearchmappois',
    );

    return resultString['result'];
  }

  /// Enable or disable searching through map POIs.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to include POIs in search results, false to exclude them.
  set searchMapPOIs(final bool value) {
    objectMethod(
      pointerId,
      'SearchPreferences',
      'setsearchmappois',
      args: value,
    );
  }

  /// Whether searches are restricted to onboard (offline) data.
  ///
  /// When true, only local data will be used for searches. Default is false.
  ///
  /// ## Returns
  ///
  /// - True if searches are restricted to onboard data, false otherwise.
  bool get searchOnlyOnboard {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SearchPreferences',
      'getsearchonlyonboard',
    );

    return resultString['result'];
  }

  /// Enable or disable onboard-only searches.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to force searches to use onboard data only, false to allow online lookups.
  set searchOnlyOnboard(final bool value) {
    objectMethod(
      pointerId,
      'SearchPreferences',
      'setsearchonlyonboard',
      args: value,
    );
  }

  /// Threshold distance (in meters) applied to search operations.
  ///
  /// Used to limit results by distance when searching around a point or along a route. Default is the maximum int value.
  ///
  /// ## Returns
  ///
  /// - The threshold distance in meters.
  int get thresholdDistance {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SearchPreferences',
      'getthresholddistance',
    );

    return resultString['result'];
  }

  /// Set the threshold distance used by search operations.
  ///
  /// This controls the maximum distance for reverse geocoding and route-based searches.
  ///
  /// ## Parameters
  ///
  /// - [value]: Threshold distance in meters.
  set thresholdDistance(final int value) {
    objectMethod(
      pointerId,
      'SearchPreferences',
      'setthresholddistance',
      args: value,
    );
  }

  /// Whether the easy-access filter for results is enabled.
  ///
  /// When true, search results are restricted to locations deemed easily accessible. Default is false.
  ///
  /// ## Returns
  ///
  /// - True if the easy-access filter is enabled, false otherwise.
  bool get easyAccessOnlyResults {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SearchPreferences',
      'geteasyaccessonlyresults',
    );

    return resultString['result'];
  }

  /// Enable or disable the easy-access results filter.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to restrict results to easily accessible locations, false to disable the filter.
  set easyAccessOnlyResults(final bool value) {
    objectMethod(
      pointerId,
      'SearchPreferences',
      'seteasyaccessonlyresults',
      args: value,
    );
  }

  /// Collection of landmark stores used as search targets.
  ///
  /// Provides access to the set of landmark stores considered during search operations.
  /// Can be customized to add specific [LandmarkStore] instances, allowing the search to work
  /// on custom datasets.
  ///
  /// ## Returns
  ///
  /// - [LandmarkStoreCollection]: The collection of landmark stores.
  LandmarkStoreCollection get landmarks {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SearchPreferences',
      'landmarks',
    );

    return LandmarkStoreCollection.init(resultString['result'], -1);
  }

  /// Mutable collection of overlays considered during search.
  ///
  /// Provides access to the set of overlays that are included in search operations.
  /// Can be customized to add specific [OverlayInfo] instances, allowing the search to work
  /// on custom datasets.
  ///
  /// Requires the existence of a [GemMap] instance to function correctly with a style
  /// containing overlays applied.
  ///
  /// ## Returns
  ///
  /// - [OverlayMutableCollection]: The overlays collection.
  OverlayMutableCollection get overlays {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SearchPreferences',
      'overlays',
    );

    return OverlayMutableCollection.init(resultString['result']);
  }

  static SearchPreferences _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'SearchPreferences'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return SearchPreferences.init(decodedVal['result']);
  }
}
