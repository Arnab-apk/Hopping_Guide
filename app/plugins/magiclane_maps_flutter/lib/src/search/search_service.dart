// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/common/task_handler.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/search/search_preferences.dart';

/// Service for searching [Landmark] from map or custom data
///
/// Provides static methods to perform text-based place searches anchored by reference position, geographic area, or route.
/// Results are delivered asynchronously via callback and ordered by relevance to the reference.
///
/// Search operations can be customized using [SearchPreferences] to control matching fuzziness, result limits, data sources, and more.
/// Use [cancelSearch] to terminate in-flight searches.
///
/// ## See also:
///
/// - [SearchPreferences] - Configure search behavior (fuzzy matching, onboard-only, max results, etc.).
/// - [GuidedAddressSearchService] - Perform hierarchical address searches (country → city → street → house number).
/// - [Landmark] - Represents places of interest returned by search operations.
///
/// {@category Search}
abstract class SearchService {
  /// Search for landmarks using text and reference coordinates.
  ///
  /// Performs a text-based search centered around [referenceCoordinates]. Results are ordered by relevance to this position.
  /// Optionally, provide [locationHint] to restrict search to a specific area.
  ///
  /// ## Parameters
  ///
  /// - [textFilter]: Text to filter results (e.g., "Paris").
  /// - [referenceCoordinates]: The reference position for result relevance ordering. Landmarks closer to this position are ranked higher.
  /// - [onComplete]: Callback invoked when the search completes. Provides:
  ///   - `err`: The result status. Possible values:
  ///     - [GemError.success]: Search completed successfully with results.
  ///     - [GemError.reducedResult]: Search completed successfully but only a subset of results was returned.
  ///     - [GemError.invalidInput]: Invalid input (e.g., invalid [referenceCoordinates]).
  ///     - [GemError.cancel]: Search canceled by user.
  ///     - [GemError.noMemory]: Insufficient memory for operation.
  ///     - [GemError.operationTimeout]: Operation timeout on online service (typically > 1 min).
  ///     - [GemError.networkFailed]: Network failure during online search.
  ///   - `results`: List of found landmarks if the error is [GemError.success]. Empty list on error.
  /// - [preferences]: Optional [SearchPreferences] to customize search behavior.
  /// - [locationHint]: Optional area to restrict search.
  ///
  /// ## Returns
  ///
  /// - [TaskHandler?]: TaskHandler for this operation if search could be started; otherwise null.
  ///
  /// ## Example
  ///
  /// ```dart
  /// SearchService.search("Paris", coords, preferences: preferences, (err, results) {
  ///   if (err == GemError.success) {
  ///     print("Found ${results.length} results");
  ///   } else {
  ///     print("Error: $err");
  ///   }
  /// });
  /// ```
  ///
  /// ## See also:
  ///
  /// - [SearchPreferences] - Configure search behavior (fuzzy matching, onboard-only, max results, etc.).
  /// - [Landmark] - Represents places of interest returned by search operations.
  static TaskHandler? search(
    final String textFilter,
    final Coordinates referenceCoordinates,
    final void Function(GemError err, List<Landmark> results) onComplete, {
    SearchPreferences? preferences,
    final GeographicArea? locationHint,
  }) {
    preferences ??= SearchPreferences();

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
      'SearchService',
      'search',
      args: <String, dynamic>{
        'results': results.pointerId,
        'listener': progListener.id,
        'textFilter': textFilter,
        'referenceCoordinates': referenceCoordinates,
        'preferences': preferences.pointerId,
        'locationHint':
            locationHint ??
            RectangleGeographicArea(
              topLeft: Coordinates(),
              bottomRight: Coordinates(),
            ),
      },
    );

    final GemError errorCode = GemErrorExtension.fromCode(
      resultString['result'],
    );

    if (errorCode != GemError.success) {
      onComplete(errorCode, <Landmark>[]);
      return null;
    }

    return TaskHandlerImpl(progListener.id);
  }

  /// Search using address and geographic area as discriminants.
  ///
  /// Performs a text-based search centered around [referenceCoordinates]. Results are ordered by relevance to this position.
  /// Optionally, provide [locationHint] to restrict search to a specific area.
  ///
  /// ## Parameters
  ///
  /// - [addressInfo]: The searched address info.
  /// - [referenceCoordinates]: The reference position for result relevance ordering. Landmarks closer to this position are ranked higher.
  /// - [onComplete]: Callback invoked when the search completes. Provides:
  ///   - `err`: The result status. Possible values:
  ///     - [GemError.success]: Search completed successfully with results.
  ///     - [GemError.reducedResult]: Search completed successfully but only a subset of results was returned.
  ///     - [GemError.invalidInput]: Invalid input (e.g., invalid [referenceCoordinates]).
  ///     - [GemError.cancel]: Search canceled by user.
  ///     - [GemError.noMemory]: Insufficient memory for operation.
  ///     - [GemError.operationTimeout]: Operation timeout on online service (typically > 1 min).
  ///     - [GemError.networkFailed]: Network failure during online search.
  ///   - `results`: List of found landmarks if the error is [GemError.success]. Empty list on error.
  /// - [preferences]: Optional [SearchPreferences] to customize search behavior.
  /// - [locationHint]: Optional area to restrict search.
  ///
  /// ## Returns
  ///
  /// - [TaskHandler?]: TaskHandler for this operation if search could be started; otherwise null.
  ///
  /// ## Example
  ///
  /// ```dart
  /// SearchService.searchAddress(addressInfo, coords, preferences: preferences, (err, results) {
  ///   if (err == GemError.success) {
  ///     print("Found ${results.length} results");
  ///   } else {
  ///     print("Error: $err");
  ///   }
  /// });
  /// ```
  ///
  /// ## See also:
  ///
  /// - [SearchPreferences] - Configure search behavior (fuzzy matching, onboard-only, max results, etc.).
  /// - [Landmark] - Represents places of interest returned by search operations.
  static TaskHandler? searchAddress(
    final AddressInfo addressInfo,
    final Coordinates referenceCoordinates,
    final void Function(GemError err, List<Landmark> results) onComplete, {
    SearchPreferences? preferences,
    final GeographicArea? locationHint,
  }) {
    preferences ??= SearchPreferences();

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
      'SearchService',
      'searchAddress',
      args: <String, dynamic>{
        'results': results.pointerId,
        'listener': progListener.id,
        'addressInfo': addressInfo.toJson(),
        'referenceCoordinates': referenceCoordinates,
        'preferences': preferences.pointerId,
        'locationHint':
            locationHint ??
            RectangleGeographicArea(
              topLeft: Coordinates(),
              bottomRight: Coordinates(),
            ),
      },
    );

    final GemError errorCode = GemErrorExtension.fromCode(
      resultString['result'],
    );

    if (errorCode != GemError.success) {
      onComplete(errorCode, <Landmark>[]);
      return null;
    }

    return TaskHandlerImpl(progListener.id);
  }

  /// Populate details for landmarks from upper zoom levels.
  ///
  /// Retrieves full details for landmarks selected from higher zoom levels of the map retrived via
  /// operations such as [GemMapController.cursorSelectionLandmarks].
  /// Landmarks from text search already include all the details
  /// Does not work with user-created landmarks.
  ///
  /// ## Parameters
  ///
  /// - [results]: List of [Landmark] objects for which to retrieve details.
  /// - [onComplete]: Callback invoked when the operation completes. Provides:
  ///   - `err`: The result status. Possible values:
  ///     - [GemError.success]: Details populated successfully.
  ///     - [GemError.upToDate]: Landmarks already have details.
  ///     - [GemError.invalidated]: Landmark is invalid (e.g., user-created).
  ///
  /// ## Returns
  ///
  /// - [TaskHandler?]: TaskHandler for this operation if it could be started; otherwise null.
  ///
  /// ## See also:
  ///
  /// - [GemMapController.cursorSelectionLandmarks] - Retrieve landmarks from map cursor selection.
  static TaskHandler? searchLandmarkDetails(
    final List<Landmark> results,
    final void Function(GemError err) onComplete,
  ) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);

      if (err == GemError.success.code || err == GemError.reducedResult.code) {
        onComplete(GemErrorExtension.fromCode(err));
      } else {
        onComplete(GemErrorExtension.fromCode(err));
      }
    });

    final LandmarkList resultsList = LandmarkList();
    results.forEach(resultsList.add);

    final OperationResult resultString = staticMethod(
      'SearchService',
      'searchLandmarkDetails',
      args: <String, dynamic>{
        'results': resultsList.pointerId,
        'listener': progListener.id,
      },
    );

    final GemError errorCode = GemErrorExtension.fromCode(
      resultString['result'],
    );

    if (errorCode != GemError.success) {
      onComplete(errorCode);
      return null;
    }

    return TaskHandlerImpl(progListener.id);
  }

  /// Cancel an active search operation.
  ///
  /// ## Parameters
  ///
  /// - [taskHandler]: The [TaskHandler] returned by a search method, identifying the operation to cancel.
  static void cancelSearch(final TaskHandler taskHandler) {
    taskHandler as TaskHandlerImpl;
    staticMethod('SearchService', 'cancelSearch', args: taskHandler.id);
  }

  /// Search for landmarks along a route.
  ///
  /// Finds landmarks along the specified [route], optionally filtered by [textFilter].
  ///
  /// ## Parameters
  ///
  /// - [route]: The route to search along.
  /// - [onComplete]: Callback invoked when the search completes. Provides:
  ///   - `err`: The result status. Possible values:
  ///     - [GemError.success]: Search completed successfully with results.
  ///     - [GemError.reducedResult]: Search completed successfully but only a subset of results was returned.
  ///     - [GemError.invalidInput]: Invalid input.
  ///     - [GemError.cancel]: Search canceled by user.
  ///     - [GemError.noMemory]: Insufficient memory for operation.
  ///     - [GemError.operationTimeout]: Operation timeout on online service (typically > 1 min).
  ///     - [GemError.networkFailed]: Network failure during online search.
  ///   - `results`: List of found landmarks (empty on error).
  /// - [textFilter]: Optional text filter to narrow results.
  /// - [preferences]: Optional [SearchPreferences] to customize search behavior.
  ///
  /// ## Returns
  ///
  /// - [TaskHandler?]: TaskHandler for this operation if search could be started; otherwise null.
  ///
  /// ## See also:
  ///
  /// - [Route] - Represents the route along which to search for landmarks.
  /// - [SearchPreferences] - Configure search behavior (fuzzy matching, onboard-only,
  /// max results, etc.).
  static TaskHandler? searchAlongRoute(
    final Route route,
    final void Function(GemError err, List<Landmark> results) onComplete, {
    final String? textFilter,
    SearchPreferences? preferences,
  }) {
    preferences ??= SearchPreferences();

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
      'SearchService',
      'searchAlongRoute',
      args: <String, dynamic>{
        'results': results.pointerId,
        'listener': progListener.id,
        'route': route.pointerId,
        if (textFilter != null) 'textFilter': textFilter,
        'preferences': preferences.pointerId,
      },
    );

    final GemError errorCode = GemErrorExtension.fromCode(
      resultString['result'],
    );

    if (errorCode != GemError.success) {
      onComplete(errorCode, <Landmark>[]);
      return null;
    }

    return TaskHandlerImpl(progListener.id);
  }

  /// Search for landmarks within a geographic area.
  ///
  /// Retrieves landmarks within [area], ordered by relevance to [referenceCoordinates].
  ///
  /// ## Parameters
  ///
  /// - [area]: The geographic area to search within.
  /// - [referenceCoordinates]: The reference position for result relevance ordering.
  /// - [onComplete]: Callback invoked when the search completes. Provides:
  ///   - `err`: The result status. Possible values:
  ///     - [GemError.success]: Search completed successfully with results.
  ///     - [GemError.reducedResult]: Search completed successfully but only a subset of results was returned.
  ///     - [GemError.cancel]: Search canceled by user.
  ///     - [GemError.noMemory]: Insufficient memory for operation.
  ///     - [GemError.operationTimeout]: Operation timeout on online service (typically > 1 min).
  ///     - [GemError.networkFailed]: Network failure during online search.
  ///   - `results`: List of found landmarks (empty on error).
  /// - [textFilter]: Optional text filter to narrow results. Defaults to empty string.
  /// - [preferences]: Optional [SearchPreferences] to customize search behavior.
  ///
  /// ## Returns
  ///
  /// - [TaskHandler?]: TaskHandler for this operation if search could be started; otherwise null.
  ///
  /// ## See also:
  ///
  /// - [GeographicArea] - Defines the geographic area for the search.
  static TaskHandler? searchInArea(
    final GeographicArea area,
    final Coordinates referenceCoordinates,
    final void Function(GemError err, List<Landmark> results) onComplete, {
    final String textFilter = '',
    SearchPreferences? preferences,
  }) {
    preferences ??= SearchPreferences();

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
      'SearchService',
      'searchInArea',
      args: <String, dynamic>{
        'results': results.pointerId,
        'listener': progListener.id,
        'textFilter': textFilter,
        'referenceCoordinates': referenceCoordinates,
        'preferences': preferences.pointerId,
        'area': area,
      },
    );

    final GemError errorCode = GemErrorExtension.fromCode(
      resultString['result'],
    );

    if (errorCode != GemError.success) {
      onComplete(errorCode, <Landmark>[]);
      return null;
    }

    return TaskHandlerImpl(progListener.id);
  }

  /// Search for landmarks around a position.
  ///
  /// Finds landmarks in the closest proximity to [position], optionally filtered by [textFilter]. If no text filter is provided,
  /// all landmarks near the position are returned (limited by preferences).
  ///
  /// ## Parameters
  ///
  /// - [position]: The geographic position to search around.
  /// - [onComplete]: Callback invoked when the search completes. Provides:
  ///   - `err`: The result status. Possible values:
  ///     - [GemError.success]: Search completed successfully with results.
  ///     - [GemError.reducedResult]: Search completed successfully but only a subset of results was returned.
  ///     - [GemError.invalidInput]: Invalid input (e.g., invalid [position]).
  ///     - [GemError.cancel]: Search canceled by user.
  ///     - [GemError.noMemory]: Insufficient memory for operation.
  ///     - [GemError.operationTimeout]: Operation timeout on online service (typically > 1 min).
  ///     - [GemError.networkFailed]: Network failure during online search.
  ///   - `results`: List of found landmarks (empty on error).
  /// - [textFilter]: Optional text filter to narrow results.
  /// - [preferences]: Optional [SearchPreferences] to customize search behavior.
  ///
  /// ## Returns
  ///
  /// - [TaskHandler?]: TaskHandler for this operation if search could be started; otherwise null.
  static TaskHandler? searchAroundPosition(
    final Coordinates position,
    final void Function(GemError err, List<Landmark> results) onComplete, {
    final String? textFilter,
    SearchPreferences? preferences,
  }) {
    preferences ??= SearchPreferences();

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
      'SearchService',
      'searchAroundPosition',
      args: <String, dynamic>{
        'results': results.pointerId,
        'listener': progListener.id,
        'position': position,
        if (textFilter != null) 'textFilter': textFilter,
        'preferences': preferences.pointerId,
      },
    );

    final GemError errorCode = GemErrorExtension.fromCode(
      resultString['result'],
    );

    if (errorCode != GemError.success) {
      onComplete(errorCode, <Landmark>[]);
      return null;
    }

    return TaskHandlerImpl(progListener.id);
  }

  /// Transfer statistics for search operations.
  ///
  /// Returns a [TransferStatistics] object containing counters and metrics
  /// about network usage performed by the traffic service. This information
  /// can be used for diagnostics or to display usage to end users.
  ///
  /// ## Returns
  ///
  /// - [TransferStatistics]: Statistics describing data transfer for search operations.
  static TransferStatistics get transferStatistics {
    final OperationResult resultString = staticMethod(
      'SearchService',
      'getTransferStatistics',
    );

    return TransferStatistics.init(resultString['result']);
  }
}
