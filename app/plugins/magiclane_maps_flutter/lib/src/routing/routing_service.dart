// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/common/task_handler.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/routing/ev_car_model.dart';
import 'package:magiclane_maps_flutter/src/routing/routing_preferences.dart';

/// Static service for asynchronous route calculation and navigation planning.
///
/// Provides methods to calculate routes between waypoints using configurable
/// preferences, supporting multiple transport modes (car, pedestrian, bicycle,
/// public transit, truck), route types (fastest, shortest, economic), and
/// various routing constraints (avoid tolls, ferries, traffic, etc.). All
/// route calculations execute asynchronously with callback-based result
/// delivery and comprehensive error reporting.
///
/// ## Example
///
/// ```dart
/// TaskHandler? taskHandler = RoutingService.calculateRoute(
///   [departureLandmark, destinationLandmark],
///   routePreferences,
///   (err, routes) {
///     if (err == GemError.success) {
///       // Do something with the calculated routes
///     } else {
///       print('Error: $err');
///     }
///   },
/// );
/// ```
///
/// ## See also:
///
/// - [RoutePreferences] - Configuration options for route calculation.
/// - [Route] - Calculated route with instructions and time/distance data.
/// - [Landmark] - Waypoint representation for route waypoints.
/// - [NavigationService] - Service for turn-by-turn navigation on routes.
/// - [MapViewRoutesCollection] - Displaying routes on a map view.
///
/// {@category Routing}
abstract class RoutingService {
  /// Calculates routes between specified waypoints asynchronously.
  ///
  /// Initiates an asynchronous route calculation using the provided waypoints
  /// and preferences. The method returns immediately with a [TaskHandler] to
  /// monitor or cancel the operation. Results or errors are delivered through
  /// the [onComplete] callback.
  ///
  /// Requires at least 2 waypoints for path result types, or 1 waypoint for
  /// range result types (see [RouteResultType] for details). The calculation can
  /// be done offline, depending on the passed [routePreferences] and the availability
  /// of downloaded map data.
  ///
  /// Returns `null` immediately only when the calculation cannot be initiated
  /// (invalid configuration detected synchronously). All other errors are
  /// delivered asynchronously through [onComplete].
  ///
  /// ## Parameters
  ///
  /// - [waypoints]: List of [Landmark] objects defining route start, end, and
  ///   optional intermediate points. Must contain at least 2 waypoints for
  ///   standard routes, or 1 waypoint for range calculations.
  /// - [routePreferences]: Configuration object specifying transport mode,
  ///   route type, vehicle profile, restrictions, and calculation options.
  /// - [onComplete]: Callback invoked when calculation completes or fails.
  ///   Called with:
  ///   - [GemError.success] and non-empty `routes` list upon successful calculation.
  ///   - [GemError.notSupported] and empty `routes` if preferences contain
  ///     unsupported configuration (e.g., invalid transport mode combination).
  ///   - [GemError.invalidInput] and empty `routes` if input is invalid
  ///     (e.g., fewer than 2 waypoints for path result, or fewer than 1 for range result).
  ///   - [GemError.cancel] and empty `routes` if calculation was cancelled via
  ///     [cancelRoute] before completion.
  ///   - [GemError.waypointAccess] and empty `routes` if no route could be
  ///     found with given preferences (e.g., destination unreachable, no roads nearby).
  ///   - [GemError.connectionRequired] and empty `routes` if online calculation
  ///     is disabled ([RoutePreferences.allowOnlineCalculation] = false) and
  ///     offline map data is insufficient for calculation.
  ///   - [GemError.expired] and empty `routes` if offline map data is too old
  ///     and no longer supported by online routing service.
  ///   - [GemError.routeTooLong] and empty `routes` if online calculation
  ///     exceeded server timeout (typically >1 minute, depending on server load).
  ///   - [GemError.invalidated] and empty `routes` if offline map data changed
  ///     (downloaded, erased, or updated) during calculation.
  ///   - [GemError.noMemory] and empty `routes` if routing engine failed to
  ///     allocate necessary memory for calculation.
  ///
  /// ## Returns
  ///
  /// - [TaskHandler] if calculation was successfully initiated (use with
  ///   [cancelRoute], [isCalculationRunning], [getRouteStatus]).
  /// - `null` if calculation could not be initiated due to invalid configuration
  ///   detected immediately (error delivered via [onComplete]).
  ///
  /// ## Example
  ///
  /// ```dart
  /// TaskHandler? taskHandler = RoutingService.calculateRoute(
  ///   [departureLandmark, destinationLandmark],
  ///   routePreferences,
  ///   (err, routes) {
  ///     if (err == GemError.success) {
  ///       // Do something with the calculated routes
  ///     } else {
  ///       print('Error: $err');
  ///     }
  ///   }
  /// );
  /// ```
  ///
  /// ## See also:
  ///
  /// - [RoutePreferences] - Configuration options for route calculation.
  /// - [cancelRoute] - Cancels an ongoing calculation.
  /// - [Route] - Calculated route with instructions and time/distance data.
  /// - [NavigationService] - Service for turn-by-turn navigation on routes.
  static TaskHandler? calculateRoute(
    final List<Landmark> waypoints,
    final RoutePreferences routePreferences,
    final void Function(GemError err, List<Route> routes) onComplete,
  ) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);
    final RouteList results = RouteList();

    final LandmarkList waypointsList = LandmarkList.fromList(waypoints);

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);

      if (err == GemError.success.code) {
        // On web the native RouteList result can come back empty/misshaped in
        // some browsers (WASM-runtime dependent), which would otherwise crash
        // the whole app when the list is cast. Guard the read and degrade to a
        // general failure instead of throwing out of this callback.
        List<Route> routes;
        try {
          routes = results.toList();
        } catch (_) {
          onComplete(GemError.general, <Route>[]);
          return;
        }
        onComplete(GemErrorExtension.fromCode(err), routes);
      } else {
        onComplete(GemErrorExtension.fromCode(err), <Route>[]);
      }
    });

    final OperationResult result = staticMethod(
      'RoutingService',
      'calculateRoute',
      args: <String, dynamic>{
        'results': results.pointerId,
        'listener': progListener.id,
        'waypoints': waypointsList.pointerId,
        'routePreferences': routePreferences.pointerId,
      },
    );

    final GemError errorCode = GemErrorExtension.fromCode(result['result']);

    if (errorCode != GemError.success) {
      onComplete(errorCode, <Route>[]);
      return null;
    }

    return TaskHandlerImpl(progListener.id);
  }

  /// Cancels an ongoing route calculation.
  ///
  /// Requests cancellation of the route calculation associated with the given
  /// [TaskHandler]. The [calculateRoute] callback will be invoked with
  /// [GemError.cancel] after cancellation completes. Safe to call multiple
  /// times on the same handler (subsequent calls have no effect).
  ///
  /// Has no effect if the calculation has already completed (either successfully
  /// or with an error) or if the handler is invalid. Does not cancel navigation
  /// started on a previously calculated route—use [NavigationService.cancelNavigation]
  /// for that purpose.
  ///
  /// ## Parameters
  ///
  /// - [taskHandler]: The [TaskHandler] returned by [calculateRoute] identifying
  ///   the calculation to cancel.
  ///
  /// ## See also:
  ///
  /// - [calculateRoute] - Initiates route calculation that returns the handler.
  /// - [isCalculationRunning] - Checks if cancellation is still needed.
  /// - [NavigationService.cancelNavigation] - Cancels active navigation.
  static void cancelRoute(final TaskHandler taskHandler) {
    taskHandler as TaskHandlerImpl;

    staticMethod('RoutingService', 'cancelRoute', args: taskHandler.id);
  }

  /// Sets a user-defined road block to trigger route recalculation.
  ///
  /// Marks a road section from a [RouteInstructionBase] as blocked, causing
  /// active navigation to recalculate the route avoiding that zone. The
  /// block persists until [resetRouteRoadBlocks] is called. Useful for
  /// manually handling traffic incidents, construction, or road closures not
  /// yet reflected in map data.
  ///
  /// Only affects active navigation sessions—road blocks set before navigation
  /// starts are ignored. Multiple road blocks can be set cumulatively; call
  /// [resetRouteRoadBlocks] to clear all at once.
  ///
  /// ## Parameters
  ///
  /// - [instruction]: The [RouteInstructionBase] identifying the road segment
  ///   to block (typically from [RouteSegment.instructions]).
  ///
  /// ## Returns
  ///
  /// - [GemError.success] if the road block was set successfully.
  /// - Other [GemError] values indicate failure (e.g., invalid instruction).
  ///
  /// ## See also:
  ///
  /// - [resetRouteRoadBlocks] - Clears all user-defined road blocks.
  /// - [RouteInstructionBase] - Base class for route turn-by-turn instructions.
  /// - [TrafficService] - Service providing management of persistent road blocks.
  /// - [NavigationService] - Service managing active navigation sessions.
  static GemError setRouteRoadBlock(final RouteInstructionBase instruction) {
    final OperationResult result = staticMethod(
      'RoutingService',
      'setRouteRoadBlock',
      args: instruction.pointerId,
    );

    return GemErrorExtension.fromCode(result['result']);
  }

  /// Clears all user-defined road blocks.
  ///
  /// Removes all road blocks previously set via [setRouteRoadBlock], allowing
  /// future route calculations and recalculations to use those road sections
  /// normally. Safe to call even if no road blocks are currently set (no-op).
  ///
  /// Affects all subsequent route calculations and recalculations, but does
  /// not force an immediate recalculation of active navigation routes—the new
  /// routing behavior applies on the next scheduled or triggered recalculation.
  ///
  /// ## See also:
  ///
  /// - [setRouteRoadBlock] - Sets a road block on a specific section.
  /// - [TrafficService] - Service providing management of persistent road blocks.
  static void resetRouteRoadBlocks() {
    staticMethod('RoutingService', 'resetRouteRoadBlocks');
  }

  /// Checks if a route calculation is still in progress.
  ///
  /// Queries whether the calculation identified by the given [TaskHandler] is
  /// currently running. Returns false if the calculation has completed (either
  /// successfully or with an error), was cancelled, or if the handler is invalid.
  ///
  /// Useful for UI state management (e.g., showing/hiding progress indicators)
  /// or deciding whether cancellation is necessary. Check this before calling
  /// [cancelRoute] to avoid unnecessary operations.
  ///
  /// ## Parameters
  ///
  /// - [taskHandler]: The [TaskHandler] returned by [calculateRoute] to check.
  ///
  /// ## Returns
  ///
  /// - `true` if the calculation is currently in progress.
  /// - `false` if the calculation has finished, was cancelled, or handler is invalid.
  ///
  /// ## See also:
  ///
  /// - [getRouteStatus] - Retrieves detailed calculation status.
  /// - [cancelRoute] - Cancels the calculation if still running.
  static bool isCalculationRunning(final TaskHandler taskHandler) {
    taskHandler as TaskHandlerImpl;

    final OperationResult result = staticMethod(
      'RoutingService',
      'isCalculationRunning',
      args: taskHandler.id,
    );
    return result['result'];
  }

  /// Retrieves the current status of a route calculation.
  ///
  /// Queries the detailed status of the calculation identified by the given
  /// [TaskHandler]. Returns a [RouteStatus] enum indicating whether the
  /// calculation is pending, calculating, ready (completed successfully), or
  /// failed/cancelled.
  ///
  /// More detailed than [isCalculationRunning], which only returns a boolean.
  /// Use this when you need to distinguish between different completion states
  /// (success vs. error) or track calculation progress in the UI.
  ///
  /// ## Parameters
  ///
  /// - [taskHandler]: The [TaskHandler] returned by [calculateRoute] to query.
  ///
  /// ## Returns
  ///
  /// - [RouteStatus] indicating current calculation state (e.g., calculating,
  ///   ready, cancelled, failed).
  ///
  /// ## See also:
  ///
  /// - [RouteStatus] - Enum defining all possible route calculation states.
  /// - [isCalculationRunning] - Boolean check for active calculation.
  static RouteStatus getRouteStatus(final TaskHandler taskHandler) {
    taskHandler as TaskHandlerImpl;

    final OperationResult result = staticMethod(
      'RoutingService',
      'getRouteStatus',
      args: taskHandler.id,
    );
    return RouteStatusExtension.fromId(result['result']);
  }

  /// Retrieves network transfer statistics for online route calculations.
  ///
  /// Returns a [TransferStatistics] object containing counters and metrics
  /// about network usage performed by the traffic service. This information
  /// can be used for diagnostics or to display usage to end users.
  ///
  /// ## Returns
  ///
  /// - [TransferStatistics] object containing cumulative bytes sent and received
  ///   for online route calculations.
  ///
  /// ## See also:
  ///
  /// - [TransferStatistics] - Object holding sent/received byte counts.
  /// - [RoutePreferences.allowOnlineCalculation] - Controls online routing usage.
  static TransferStatistics get transferStatistics {
    final OperationResult resultString = staticMethod(
      'RoutingService',
      'getTransferStatistics',
    );

    return TransferStatistics.init(resultString['result']);
  }

  /// Returns the list of available EV car models.
  ///
  /// The returned list contains [EVCarModel] instances with vehicle
  /// specifications (battery capacity, range, efficiency, etc.) that can
  /// be used to configure EV routing profiles.
  ///
  /// ## Returns
  ///
  /// - A list of [EVCarModel] containing all available EV car models.
  static List<EVCarModel> getEVCarModels() {
    final OperationResult resultString = staticMethod(
      'RoutingService',
      'getEVCarModels',
    );

    final EVCarModelList list = EVCarModelList.init(resultString['result']);
    return list.toList();
  }
}
