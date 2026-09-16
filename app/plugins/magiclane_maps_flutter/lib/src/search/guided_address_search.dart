// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:magiclane_maps_flutter/src/core/common/task_handler.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Service for guided, hierarchical address searches.
///
/// Provides static entry points to perform level-aware address queries (from country down to house number or crossings),
/// search for countries, retrieve country-level landmarks to use as parents, and cancel in-flight searches.
/// Results are delivered asynchronously via callback functions.
///
/// The address hierarchy is country-dependent; use [getNextAddressDetailLevel] to obtain the next searchable levels for a given [Landmark].
///
/// {@category Places}
abstract class GuidedAddressSearchService {
  static GuidedAddressSearchPreferences? _prefs;

  /// Search for address items under a specified parent landmark.
  ///
  /// The search starts at [parent] and returns items matching [filter] at the requested [detailLevel]. If [parent] is the default
  /// landmark, only [AddressDetailLevel.country] can be searched. The search will return results according to the session
  /// preferences (for example, maximum matches and fuzzy matching).
  ///
  /// This function should be used to progressively drill down the address hierarchy by using results from one search
  /// as the parent for the next level.
  ///
  /// ## Parameters
  ///
  /// - [filter]: The text filter to apply. If empty, all items at the requested level are returned (subject to preferences limits).
  /// - [parent]: The landmark to use as the starting point for the search.
  /// - [detailLevel]: The detail level to search for (see [AddressDetailLevel]). Use [getNextAddressDetailLevel] to determine valid levels for a given parent.
  /// - [onComplete]: Callback invoked when the search completes. It provides:
  ///   - `err`: The resulting [GemError] code for the operation.
  ///   - `landmarks`: List of matching landmarks (empty on failure).
  ///
  /// ## Returns
  ///
  /// - [TaskHandler?]: The associated [TaskHandler] if the search could be started; otherwise null.
  ///
  /// ## Also see:
  ///
  /// - [getNextAddressDetailLevel] - Determine valid next detail levels for a given parent landmark.
  /// - [GuidedAddressSearchPreferences] - Configure preferences for guided address searches.
  /// - [getCountryLevelItem] - Obtain country-level landmarks by ISO code.
  static TaskHandler? search(
    final String filter,
    final Landmark parent,
    final AddressDetailLevel detailLevel,
    final void Function(GemError err, List<Landmark> landmarks) onComplete,
  ) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);
    final LandmarkList results = LandmarkList();

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);

      if (err == GemError.success.code || err == GemError.reducedResult.code) {
        onComplete(GemErrorExtension.fromCode(err), results.toList());
      } else {
        onComplete(GemErrorExtension.fromCode(err), <Landmark>[]);
      }
    });

    final OperationResult resultString = staticMethod(
      'GuidedAddressSearchService',
      'search',
      args: <String, dynamic>{
        'results': results.pointerId,
        'parent': parent.pointerId,
        'filter': filter,
        'detailToSearch': detailLevel.id,
        'progress': progListener.id,
      },
    );

    final int errorCode = resultString['result'];

    if (errorCode != GemError.success.code) {
      onComplete(GemErrorExtension.fromCode(errorCode), <Landmark>[]);
      return null;
    }

    return TaskHandlerImpl(progListener.id);
  }

  /// Search for countries by name.
  ///
  /// Performs a top-level address search restricted to country-level results. Useful to obtain a country-level [Landmark]
  /// that can be used as a parent for further hierarchical searches in [search].
  ///
  /// ## Parameters
  ///
  /// - [filter]: Filter string applied to country names. If empty, returns all countries (subject to engine limits).
  /// - [onComplete]: Callback invoked when the search completes. It provides:
  ///   - `err`: The resulting [GemError] code for the operation.
  ///   - `landmarks`: List of matching landmarks (empty on failure).
  ///
  /// ## Returns
  ///
  /// - [TaskHandler?]: Associated TaskHandler if the search can be started; otherwise null.
  ///
  /// ## Also see:
  ///
  /// - [getNextAddressDetailLevel] - Determine valid next detail levels for a given parent landmark.
  /// - [getCountryLevelItem] - Get country-level landmarks by ISO code.
  static TaskHandler? searchCountries(
    final String filter,
    final void Function(GemError err, List<Landmark> landmarks) onComplete,
  ) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);
    final LandmarkList results = LandmarkList();
    final Landmark emptyParent = Landmark();

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);

      if (err == GemError.success.code || err == GemError.reducedResult.code) {
        onComplete(GemErrorExtension.fromCode(err), results.toList());
      } else {
        onComplete(GemErrorExtension.fromCode(err), <Landmark>[]);
      }
    });

    final OperationResult resultString = staticMethod(
      'GuidedAddressSearchService',
      'search',
      args: <String, dynamic>{
        'results': results.pointerId,
        'parent': emptyParent.pointerId,
        'filter': filter,
        'detailToSearch': AddressDetailLevel.country.id,
        'progress': progListener.id,
      },
    );

    final int errorCode = resultString['result'];

    if (errorCode != GemError.success.code) {
      onComplete(GemErrorExtension.fromCode(errorCode), <Landmark>[]);
      return null;
    }

    return TaskHandlerImpl(progListener.id);
  }

  /// Cancel an active address search.
  ///
  /// ## Parameters
  ///
  /// - [taskHandler]: The [TaskHandler] returned by [search] or [searchCountries] identifying the operation to cancel.
  ///
  /// ## Also see:
  ///
  /// - [search] - Perform hierarchical address searches.
  /// - [searchCountries] - Search for countries by name.
  static void cancelSearch(final TaskHandler taskHandler) {
    taskHandler as TaskHandlerImpl;

    staticMethod(
      'GuidedAddressSearchService',
      'cancelSearch',
      args: taskHandler.id,
    );
  }

  /// Get the address detail level associated with a [Landmark].
  ///
  /// Returns the detail level for the provided [landmark]. If the landmark was not obtained from a previous
  /// call to [GuidedAddressSearchService.search], [AddressDetailLevel.noDetail] is returned.
  ///
  /// ## Parameters
  ///
  /// - [landmark]: The landmark to inspect.
  ///
  /// ## Returns
  ///
  /// - [AddressDetailLevel]: The address detail level for the landmark.
  ///
  /// ## Also see:
  ///
  /// - [getNextAddressDetailLevel] - Determine valid next detail levels for a given parent landmark.
  /// - [search] - Perform hierarchical address searches.
  static AddressDetailLevel getAddressDetailLevel(final Landmark landmark) {
    final OperationResult resultString = staticMethod(
      'GuidedAddressSearchService',
      'getAddressDetailLevel',
      args: landmark.pointerId,
    );

    return AddressDetailLevelExtension.fromId(resultString['result']);
  }

  /// Get the country-level [Landmark] for a given ISO country code.
  ///
  /// This returns a country-level landmark that can be used as the parent for subsequent guided searches. Returns null
  /// when the provided [countryIsoCode] is invalid or no matching country is found.
  ///
  /// ## Parameters
  ///
  /// - [countryIsoCode]: ISO country code (for example, 'US' or 'ESP').
  ///
  /// ## Returns
  ///
  /// - [Landmark?]: Country-level landmark if found; otherwise null.
  ///
  /// ## Also see:
  ///
  /// - [searchCountries] - Search for countries by name.
  /// - [MapDetails] - Obtain information related to countries.
  static Landmark? getCountryLevelItem(final String countryIsoCode) {
    final OperationResult resultString = staticMethod(
      'GuidedAddressSearchService',
      'getCountryLevelItem',
      args: countryIsoCode,
    );

    final Landmark result = Landmark.init(resultString['result']);

    if (result.name.isEmpty) {
      return null;
    }
    return result;
  }

  /// Get next possible address detail levels for a [Landmark].
  ///
  /// The set of next searchable detail levels is country-dependent. For example, a street may expose
  /// [AddressDetailLevel.crossing] and [AddressDetailLevel.houseNumber] in some countries but [AddressDetailLevel.streetSection]
  /// in others. It is usually passed to [search] to specify the next level to search.
  ///
  /// ## Parameters
  ///
  /// - [landmark]: The landmark for which to determine the next searchable detail levels. If the landmark is the default
  ///   landmark, the returned list will contain only [AddressDetailLevel.country].
  ///
  /// ## Returns
  ///
  /// - [List<AddressDetailLevel>]: List of next possible detail levels (may be empty).
  ///
  /// ## Also see:
  ///
  /// - [getAddressDetailLevel] - Get the detail level for a given landmark.
  /// - [search] - Perform hierarchical address searches.
  static List<AddressDetailLevel> getNextAddressDetailLevel(
    final Landmark landmark,
  ) {
    final OperationResult resultString = staticMethod(
      'GuidedAddressSearchService',
      'getNextAddressDetailLevel',
      args: landmark.pointerId,
    );

    final List<int> retList = resultString['result'].whereType<int>().toList();
    return retList
        .map((final int id) => AddressDetailLevelExtension.fromId(id))
        .toList();
  }

  /// Access session preferences for guided address search.
  ///
  /// ## Returns
  ///
  /// - [GuidedAddressSearchPreferences]: Preferences object for the current session.
  static GuidedAddressSearchPreferences get preferences {
    if (_prefs == null) {
      _retrievePreferences();
    } else {
      final bool isObjectAlive = GemKitPlatform.instance.isObjectAlive(
        _prefs!.pointerId,
      );
      if (!isObjectAlive) {
        _retrievePreferences();
      }
    }
    return _prefs!;
  }

  static void _retrievePreferences() {
    final OperationResult resultString = staticMethod(
      'GuidedAddressSearchService',
      'preferences',
    );

    _prefs = GuidedAddressSearchPreferences.init(resultString['result']);
  }

  /// Transfer statistics for guided address search operations.
  ///
  /// Returns a [TransferStatistics] object containing counters and metrics
  /// about network usage performed by the traffic service. This information
  /// can be used for diagnostics or to display usage to end users.
  ///
  /// ## Returns
  ///
  /// - [TransferStatistics]: Statistics describing data transfer for address searches.
  static TransferStatistics get transferStatistics {
    final OperationResult resultString = staticMethod(
      'GuidedAddressSearchService',
      'getTransferStatistics',
    );

    return TransferStatistics.init(resultString['result']);
  }
}

/// Address level of detail.
///
/// Defines the granularity of address components in a hierarchical address structure.
/// Used to specify the level to search for in guided address searches and to identify
/// the level of a returned [Landmark].
///
/// ## See also:
///
/// - [GuidedAddressSearchService.search] - Perform hierarchical address searches.
/// - [GuidedAddressSearchService.getAddressDetailLevel] - Get the detail level for a given landmark.
/// - [GuidedAddressSearchService.getNextAddressDetailLevel] - Get the next possible address detail levels for a given landmark.
///
/// {@category Search}
enum AddressDetailLevel {
  /// No address details available.
  noDetail,

  /// Country.
  country,

  /// State or province.
  state,

  /// County, which is an intermediate entity between a state and a city.
  county,

  /// Municipal district.
  district,

  /// Town or city.
  city,

  /// Settlement.
  settlement,

  /// Zip or postal code.
  postalCode,

  /// Street/road name.
  street,

  /// Street section subdivision.
  streetSection,

  /// Street lane subdivision.
  streetLane,

  /// Street alley subdivision.
  streetAlley,

  /// Address field denoting house number.
  houseNumber,

  /// Address field denoting a street in a crossing.
  crossing,
}

/// @nodoc
extension AddressDetailLevelExtension on AddressDetailLevel {
  int get id {
    switch (this) {
      case AddressDetailLevel.noDetail:
        return 0;
      case AddressDetailLevel.country:
        return 1;
      case AddressDetailLevel.state:
        return 2;
      case AddressDetailLevel.county:
        return 3;
      case AddressDetailLevel.district:
        return 4;
      case AddressDetailLevel.city:
        return 5;
      case AddressDetailLevel.settlement:
        return 6;
      case AddressDetailLevel.postalCode:
        return 7;
      case AddressDetailLevel.street:
        return 8;
      case AddressDetailLevel.streetSection:
        return 9;
      case AddressDetailLevel.streetLane:
        return 10;
      case AddressDetailLevel.streetAlley:
        return 11;
      case AddressDetailLevel.houseNumber:
        return 12;
      case AddressDetailLevel.crossing:
        return 13;
    }
  }

  static AddressDetailLevel fromId(final int id) {
    switch (id) {
      case 0:
        return AddressDetailLevel.noDetail;
      case 1:
        return AddressDetailLevel.country;
      case 2:
        return AddressDetailLevel.state;
      case 3:
        return AddressDetailLevel.county;
      case 4:
        return AddressDetailLevel.district;
      case 5:
        return AddressDetailLevel.city;
      case 6:
        return AddressDetailLevel.settlement;
      case 7:
        return AddressDetailLevel.postalCode;
      case 8:
        return AddressDetailLevel.street;
      case 9:
        return AddressDetailLevel.streetSection;
      case 10:
        return AddressDetailLevel.streetLane;
      case 11:
        return AddressDetailLevel.streetAlley;
      case 12:
        return AddressDetailLevel.houseNumber;
      case 13:
        return AddressDetailLevel.crossing;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
