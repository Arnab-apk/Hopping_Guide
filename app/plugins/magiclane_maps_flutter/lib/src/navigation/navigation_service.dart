// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:magiclane_maps_flutter/src/core/common/task_handler.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/navigation/navigation_listener.dart';

/// Manage turn-by-turn navigation and simulation on routes.
///
/// Manages real-time navigation sessions using device GPS or simulated position data,
/// delivering turn-by-turn guidance, waypoint notifications, and route recalculations.
/// Supports both live navigation (using [PositionService]) and simulation modes for
/// testing without GPS.
///
/// #### The [NavigationService] provides support for two primary modes:
/// - **Navigation**: Uses real position data from [PositionService]. Requires GPS
///   permissions and active position tracking. Automatically handles route deviations
///   and recalculations.
/// - **Simulation**: Follows route without GPS, using configurable speed multiplier.
///   Ideal for testing and previewing navigation experience.
///
/// #### The usual workflow for navigation or simulation is:
/// 1. Calculate a valid navigable route using [RoutingService].
/// 2. For navigation mode, configure [PositionService] with live or custom data source.
/// 3. Start the navigation or simulation session with [startNavigation] or [startSimulation].
/// 4. Toggle automatic TTS instructions playback using [SoundPlayingService].
/// 5. Optionally, set map camera to follow position with [GemMapController.startFollowingPosition].
///
/// ### Common operations
/// - Start/stop navigation or simulation sessions
/// - Receive instruction updates, waypoint/destination notifications, TTS text
/// - Query current route, instruction, status
/// - Handle route recalculations and better route detection
/// - Set temporary roadblocks or skip waypoints
///
/// ## Example
///
/// ```dart
/// void onNavigationInstructionUpdated(NavigationInstruction instruction,
///     Set<NavigationInstructionUpdateEvents> events) {
///   final instructionText = instruction.nextTurnInstruction;
///   // Update UI with instruction
/// }
///
/// void onDestinationReached(Landmark destination) {
///   print("Arrived at ${destination.name}");
/// }
///
/// void onTextToSpeechInstruction(String textInstruction) {
///   print("TTS Instruction: $textInstruction");
/// }
///
/// // Start navigation
/// TaskHandler? handler = NavigationService.startNavigation(
///   route,
///   onNavigationInstruction: onNavigationInstructionUpdated,
///   onDestinationReached: onDestinationReached,
///   onTextToSpeechInstruction: onTextToSpeechInstruction,
/// );
/// ```
///
/// ## See also:
///
/// - [startNavigation] - Start real-time GPS navigation.
/// - [startSimulation] - Start simulated navigation.
/// - [cancelNavigation] - Stop navigation or simulation.
/// - [NavigationInstruction] - Real-time navigation instruction details.
/// - [RoutingService] - Route calculation for navigation.
/// - [PositionService] - Position data source configuration.
///
/// {@category Navigation}
abstract class NavigationService {
  /// Active navigation session cancellation.
  ///
  /// Stops the currently active navigation or simulation session. If a route
  /// calculation is in progress when this method is called, the calculation will
  /// be cancelled and any registered `onRouteCalculationCompleted` or `onError`
  /// callback will be triggered with [GemError.cancel].
  ///
  /// ## Parameters
  ///
  /// - [taskHandler]: Optional handler for the specific navigation session to cancel.
  ///   If omitted, the currently active session (navigation or simulation) will be cancelled.
  ///
  /// ## See also:
  ///
  /// - [startNavigation] - Start navigation session.
  /// - [startSimulation] - Start simulation session.
  /// - [isNavigationActive] - Check if navigation is active.
  /// - [isSimulationActive] - Check if simulation is active.
  static void cancelNavigation([final TaskHandler? taskHandler]) {
    if (taskHandler != null) {
      taskHandler as TaskHandlerImpl;

      staticMethod('NavigationService', 'stopNavigation', args: taskHandler.id);
    } else {
      staticMethod('NavigationService', 'stopNavigation');
    }
  }

  /// Better route fork point time and distance.
  ///
  /// Returns the estimated time (in seconds) and distance (in meters) from the
  /// current position to the point where a detected better route diverges from
  /// the current navigation route. Only meaningful when a better route has been
  /// detected via the `onBetterRouteDetected` callback.
  ///
  /// ## Parameters
  ///
  /// - [taskHandler]: Optional handler for the navigation session. If omitted,
  ///   the active session is used.
  ///
  /// ## Returns
  ///
  /// - (`TimeDistance`) Time (seconds) and distance (meters) to fork point.
  ///
  /// ## See also:
  ///
  /// - [startNavigation] - Register `onBetterRouteDetected` callback.
  /// - [TimeDistance] - Time/distance data structure.
  static TimeDistance getBetterRouteTimeDistanceToFork({
    final TaskHandler? taskHandler,
  }) {
    final OperationResult result = staticMethod(
      'NavigationService',
      'getBetterRouteTimeDistanceToFork',
      args: taskHandler ?? <dynamic, dynamic>{},
    );

    return TimeDistance.fromJson(result['result']);
  }

  /// Current navigation instruction.
  ///
  /// Returns the most recent [NavigationInstruction] for the active navigation
  /// or simulation session, containing turn-by-turn guidance, remaining distance/time,
  /// speed limits, lane information, and signpost details. Returns null if no
  /// navigation session is active or no instruction is available yet.
  ///
  /// ## Parameters
  ///
  /// - [taskHandler]: Optional handler for the navigation session. If omitted,
  ///   the active session is used.
  ///
  /// ## Returns
  ///
  /// - (`NavigationInstruction?`) Current navigation instruction, or null if unavailable.
  ///
  /// ## See also:
  ///
  /// - [NavigationInstruction] - Real-time navigation instruction details.
  /// - [startNavigation] - Start navigation with instruction callbacks.
  /// - [isNavigationActive] - Check if navigation is active.
  static NavigationInstruction? getNavigationInstruction({
    final TaskHandler? taskHandler,
  }) {
    final OperationResult result = staticMethod(
      'NavigationService',
      'getNavigationInstruction',
      args: taskHandler ?? <dynamic, dynamic>{},
    );

    if (result['result'] == -1) {
      return null;
    }

    return NavigationInstruction.init(result['result']);
  }

  /// Current navigation route.
  ///
  /// Returns the [Route] object currently being used for active navigation or
  /// simulation. This is the route passed to [startNavigation] or [startSimulation],
  /// or an updated route if recalculation has occurred (delivered via `onRouteUpdated` callback).
  ///
  /// ## Parameters
  ///
  /// - [taskHandler]: Optional handler for the navigation session. If omitted,
  ///   the active session is used.
  ///
  /// ## Returns
  ///
  /// - (`Route`) Current navigation route if there is an active navigation session, null otherwise.
  ///
  /// ## See also:
  ///
  /// - [startNavigation] - Start navigation with a route.
  /// - [Route] - Route data structure.
  /// - [RoutingService] - Route calculation.
  static Route? getNavigationRoute({final TaskHandler? taskHandler}) {
    final OperationResult result = staticMethod(
      'NavigationService',
      'getNavigationRoute',
      args: taskHandler ?? <dynamic, dynamic>{},
    );

    final GemError err = ApiErrorService.apiError;
    if (err != GemError.success) {
      return null;
    }

    return Route.init(result['result']);
  }

  /// Maximum simulation speed multiplier.
  ///
  /// Returns the upper bound for the `speedMultiplier` parameter in [startSimulation].
  /// Values above this limit will be clamped to this maximum. Use this to provide
  /// UI constraints for simulation speed controls.
  ///
  /// ## Returns
  ///
  /// - (`double`) Maximum allowed speed multiplier for simulation.
  ///
  /// ## See also:
  ///
  /// - [simulationMinSpeedMultiplier] - Minimum allowed multiplier.
  /// - [startSimulation] - Start simulation with speed multiplier.
  static double get simulationMaxSpeedMultiplier {
    final OperationResult result = staticMethod(
      'NavigationService',
      'getSimulationMaxSpeedMultiplier',
    );
    return result['result'];
  }

  /// Minimum simulation speed multiplier.
  ///
  /// Returns the lower bound for the `speedMultiplier` parameter in [startSimulation].
  /// Values below this limit will be clamped to this minimum. Use this to provide
  /// UI constraints for simulation speed controls.
  ///
  /// ## Returns
  ///
  /// - (`double`) Minimum allowed speed multiplier for simulation.
  ///
  /// ## See also:
  ///
  /// - [simulationMaxSpeedMultiplier] - Maximum allowed multiplier.
  /// - [startSimulation] - Start simulation with speed multiplier.
  static double get simulationMinSpeedMultiplier {
    final OperationResult result = staticMethod(
      'NavigationService',
      'getSimulationMinSpeedMultiplier',
    );
    return result['result'];
  }

  /// Navigation session active status.
  ///
  /// Checks whether a real-time GPS navigation session (started with [startNavigation])
  /// is currently active. Returns false for simulation sessions or when no session
  /// is running.
  ///
  /// ## Parameters
  ///
  /// - [taskHandler]: Optional handler for the navigation session. If omitted,
  ///   checks the global active state.
  ///
  /// ## Returns
  ///
  /// - (`bool`) True if navigation is active, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [isSimulationActive] - Check simulation status.
  /// - [isTripActive] - Check navigation or simulation status.
  /// - [startNavigation] - Start navigation session.
  static bool isNavigationActive({final TaskHandler? taskHandler}) {
    final OperationResult result = staticMethod(
      'NavigationService',
      'isNavigationActive',
      args: taskHandler ?? <dynamic, dynamic>{},
    );
    return result['result'];
  }

  /// Simulation session active status.
  ///
  /// Checks whether a simulated navigation session (started with [startSimulation])
  /// is currently active. Returns false for real navigation sessions or when no
  /// session is running.
  ///
  /// ## Parameters
  ///
  /// - [taskHandler]: Optional handler for the simulation session. If omitted,
  ///   checks the global active state.
  ///
  /// ## Returns
  ///
  /// - (`bool`) True if simulation is active, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [isNavigationActive] - Check navigation status.
  /// - [isTripActive] - Check navigation or simulation status.
  /// - [startSimulation] - Start simulation session.
  static bool isSimulationActive({final TaskHandler? taskHandler}) {
    final OperationResult result = staticMethod(
      'NavigationService',
      'isSimulationActive',
      args: taskHandler ?? <dynamic, dynamic>{},
    );
    return result['result'];
  }

  /// Active trip status (navigation or simulation).
  ///
  /// Checks whether any trip session (navigation or simulation) is currently active.
  /// Returns true if either [startNavigation] or [startSimulation] has been called
  /// and the session is still running.
  ///
  /// ## Parameters
  ///
  /// - [taskHandler]: Optional handler for the trip session. If omitted,
  ///   checks the global active state.
  ///
  /// ## Returns
  ///
  /// - (`bool`) True if navigation or simulation is active, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [isNavigationActive] - Check navigation-only status.
  /// - [isSimulationActive] - Check simulation-only status.
  static bool isTripActive({final TaskHandler? taskHandler}) {
    final OperationResult result = staticMethod(
      'NavigationService',
      'isTripActive',
      args: taskHandler ?? <dynamic, dynamic>{},
    );
    return result['result'];
  }

  /// Temporary route roadblock configuration.
  ///
  /// Sets a virtual roadblock on the current navigation route, forcing route
  /// recalculation to avoid the blocked section. The roadblock extends for the
  /// specified length starting from a given distance along the route. Useful
  /// for simulating traffic incidents or testing route recalculation behavior.
  ///
  /// ## Parameters
  ///
  /// - [length]: Roadblock length in meters.
  /// - [startDistance]: Distance from route start where the roadblock begins,
  ///   in meters. Defaults to -1, meaning the current navigation position.
  /// - [taskHandler]: Optional handler for the navigation session. If omitted,
  ///   applies to the active session.
  ///
  /// ## See also:
  ///
  /// - [startNavigation] - Register `onRouteUpdated` to receive recalculated route.
  /// - [TrafficService] - Manage persistent traffic roadblocks.
  static void setNavigationRoadBlock(
    final int length, {
    final int startDistance = -1,
    final TaskHandler? taskHandler,
  }) {
    taskHandler as TaskHandlerImpl?;

    staticMethod(
      'NavigationService',
      'setNavigationRoadBlock',
      args: <String, dynamic>{
        'length': length,
        'startDistance': startDistance,
        'navigationListener': taskHandler?.id ?? 0,
      },
    );
  }

  /// Real-time GPS navigation session.
  ///
  /// Starts turn-by-turn navigation using position data from [PositionService].
  /// Provides comprehensive event callbacks for instruction updates, waypoint arrivals,
  /// route recalculations, better route detection, and error handling. Navigation
  /// continues until destination is reached, cancelled, or an error occurs.
  ///
  /// ## Prerequisites
  ///
  /// - Valid navigable route calculated via [RoutingService].
  /// - [PositionService] configured with live GPS or custom data source.
  /// - Appropriate GPS permissions granted (for live GPS).
  ///
  /// ## Parameters
  ///
  /// - [route]: Route to navigate. Obtain via [RoutingService.calculateRoute].
  /// - [onNavigationInstruction]: Callback for instruction updates. Arguments:
  ///   - `instruction`: Updated navigation instruction.
  ///   - `events`: Set of events triggering the update (turn updated, lane info updated, etc.).
  ///   Cannot be combined with [onNavigationInstructionOptimized].
  /// - [onNavigationInstructionOptimized]: Optimized callback for instruction updates. Arguments:
  ///   - `instruction`: Updated navigation instruction.
  ///   - `updateInfo`: Detailed update info containing the set of changed fields, a new-route flag,
  ///     and the triggering events. Use [NavigationInstructionUpdateInfo.differences] to redraw
  ///     only affected UI components. Cannot be combined with [onNavigationInstruction].
  /// - [onNavigationStarted]: Callback when navigation begins (first valid position received).
  /// - [onTextToSpeechInstruction]: Callback for TTS text. Arguments:
  ///   - `textInstruction`: Text to be spoken by TTS engine. See [SoundPlayingService] to enable TTS.
  /// - [onWaypointReached]: Callback when intermediate waypoint reached. Arguments:
  ///   - `landmark`: Reached waypoint landmark.
  /// - [onDestinationReached]: Callback when final destination reached. Arguments:
  ///   - `landmark`: Destination landmark.
  /// - [onRouteUpdated]: Callback when route recalculated. Arguments:
  ///   - `route`: New route after recalculation.
  /// - [onBetterRouteDetected]: Callback when better route found (requires [RoutePreferences.avoidTraffic]). Arguments:
  ///   - `route`: Better route.
  ///   - `travelTime`: Better route travel time (seconds).
  ///   - `delay`: Traffic delay on better route (seconds).
  ///   - `timeGain`: Time saved vs. current route (seconds). `-1` if original route has roadblocks.
  /// - [onBetterRouteRejected]: Callback when better route check fails. Arguments:
  ///   - `reason`: Rejection error code.
  /// - [onBetterRouteInvalidated]: Callback when previously detected better route becomes invalid.
  /// - [onSkipNextIntermediateDestinationDetected]: Callback when user appears to be skipping next waypoint.
  ///   Might be the time to call [skipNextIntermediateDestination].
  /// - [onTurnAround]: Callback when recalculated route requires opposite direction travel.
  /// - [onRestrictionsUpdated]: Callback when route restrictions change (e.g. the user enters or
  ///   exits a restricted part of the route). Arguments:
  ///   - `exitRestrictions`: Set of [RouteRestrictionType] values that were just exited.
  ///   - `enterRestrictions`: Set of [RouteRestrictionType] values that were just entered.
  /// - [onError]: Callback for navigation errors. Arguments:
  ///   - `error`: Error code. Possible values:
  ///     - [GemError.success]: Completed successfully.
  ///     - [GemError.cancel]: Cancelled by user.
  ///     - [GemError.waypointAccess]: Waypoint unreachable with current preferences.
  ///     - [GemError.connectionRequired]: Online calculation needed but offline-only mode set.
  ///     - [GemError.expired]: Map data version no longer supported by online service.
  ///     - [GemError.routeTooLong]: Online routing timeout.
  ///     - [GemError.invalidated]: Map data changed during calculation.
  ///     - [GemError.noMemory]: Insufficient memory for route calculation.
  /// - [onNotifyStatusChange]: Callback for navigation status changes. Arguments:
  ///   - `status`: New status (running, waiting for GPS, waiting for route, etc.).
  /// - [onRouteCalculationStarted]: Callback when route (re)calculation begins.
  /// - [onRouteCalculationCompleted]: Callback when route (re)calculation finishes. Arguments:
  ///   - `error`: Error code if calculation failed, [GemError.success] otherwise.
  ///
  /// ## Returns
  ///
  /// - (`TaskHandler?`) Handler for the navigation session, or null if initialization failed
  ///   (geographic search failure). Use with [cancelNavigation] to stop navigation.
  ///
  /// ## See also:
  ///
  /// - [startSimulation] - Start simulated navigation without GPS.
  /// - [cancelNavigation] - Stop navigation session.
  /// - [NavigationInstruction] - Real-time turn-by-turn instruction details.
  /// - [NavigationInstructionUpdateInfo] - Optimized update info with field-level differences.
  /// - [RoutingService.calculateRoute] - Route calculation.
  /// - [PositionService] - Position data source configuration.
  /// - [SoundPlayingService] - Text-to-speech configuration.
  static TaskHandler? startNavigation(
    final Route route, {
    final void Function(
      NavigationInstruction instruction,
      Set<NavigationInstructionUpdateEvents> events,
    )?
    onNavigationInstruction,
    final void Function(
      NavigationInstruction instruction,
      NavigationInstructionUpdateInfo updateInfo,
    )?
    onNavigationInstructionOptimized,
    final void Function()? onNavigationStarted,
    final void Function(String textInstruction)? onTextToSpeechInstruction,
    final void Function(Landmark landmark)? onWaypointReached,
    final void Function(Landmark landmark)? onDestinationReached,
    final void Function(Route route)? onRouteUpdated,
    final void Function(Route route, int travelTime, int delay, int timeGain)?
    onBetterRouteDetected,
    final void Function(GemError reason)? onBetterRouteRejected,
    final void Function()? onBetterRouteInvalidated,
    final void Function()? onSkipNextIntermediateDestinationDetected,
    final void Function()? onTurnAround,
    final void Function(
      Set<RouteRestrictionType> exitRestrictions,
      Set<RouteRestrictionType> enterRestrictions,
    )?
    onRestrictionsUpdated,
    final void Function(GemError error)? onError,
    final void Function(NavigationStatus status)? onNotifyStatusChange,
    final void Function()? onRouteCalculationStarted,
    final void Function(GemError error)? onRouteCalculationCompleted,
  }) {
    if (onNavigationInstruction != null &&
        onNavigationInstructionOptimized != null) {
      throw ArgumentError(
        'Cannot provide both onNavigationInstruction and onNavigationInstructionOptimized callbacks.',
      );
    }

    final OperationResult result = staticMethod(
      'NavigationService',
      'startNavigation',
      args: <String, dynamic>{
        'route': route.pointerId,
        'simulation': false,
        'useOptimizedInstructionCallback':
            onNavigationInstructionOptimized != null,
      },
    );

    final int gemApiError = result['gemApiError'];

    if (GemErrorExtension.isErrorCode(gemApiError)) {
      final GemError errorCode = GemErrorExtension.fromCode(gemApiError);
      onError?.call(errorCode);
      return null;
    }

    final int listenerId = result['result'];

    final NavigationListener listener = NavigationListener.init(listenerId);

    listener.registerAll(
      onNavigationStarted: onNavigationStarted,
      onNavigationInstructionUpdated:
          (
            final NavigationInstruction instruction,
            final Set<NavigationInstructionUpdateEvents> events,
          ) {
            onNavigationInstruction?.call(instruction, events);
          },
      onNavigationInstructionUpdatedOptimized: onNavigationInstructionOptimized,
      onWaypointReached: onWaypointReached,
      onDestinationReached: (final Landmark destination) {
        onDestinationReached?.call(destination);
      },
      onNavigationError: (final GemError error) {
        GemKitPlatform.instance.unregisterEventHandler(listener.id);
        onError?.call(error);
      },
      onRouteUpdated: onRouteUpdated,
      onNavigationSound: onTextToSpeechInstruction,
      onNotifyStatusChange: onNotifyStatusChange,
      onBetterRouteDetected: onBetterRouteDetected,
      onBetterRouteRejected: onBetterRouteRejected,
      onBetterRouteInvalidated: onBetterRouteInvalidated,
      onSkipNextIntermediateDestinationDetected:
          onSkipNextIntermediateDestinationDetected,
      onTurnAround: onTurnAround,
      onRestrictionsUpdated: onRestrictionsUpdated,
      onRouteCalculationStarted: onRouteCalculationStarted,
      onRouteCalculationCompleted: onRouteCalculationCompleted,
    );

    GemKitPlatform.instance.registerEventHandler(listener.id, listener);
    return TaskHandlerImpl(listener.id);
  }

  /// Simulated navigation session.
  ///
  /// Starts turn-by-turn navigation using simulated position data based on the [Route].
  /// Provides comprehensive event callbacks for instruction updates, waypoint arrivals,
  /// route recalculations, better route detection, and error handling. Simulation
  /// continues until destination is reached, cancelled, or an error occurs.
  ///
  /// ## Prerequisites
  ///
  /// - Valid navigable route calculated via [RoutingService].
  /// - No GPS permissions required since position is simulated.
  ///
  /// ## Parameters
  ///
  /// - [route]: Route to navigate. Obtain via [RoutingService.calculateRoute].
  /// - [onNavigationInstruction]: Callback for instruction updates. Arguments:
  ///   - `instruction`: Updated navigation instruction.
  ///   - `events`: Set of events triggering the update (turn updated, lane info updated, etc.).
  ///   Cannot be combined with [onNavigationInstructionOptimized].
  /// - [onNavigationInstructionOptimized]: Optimized callback for instruction updates. Arguments:
  ///   - `instruction`: Updated navigation instruction.
  ///   - `updateInfo`: Detailed update info containing the set of changed fields, a new-route flag,
  ///     and the triggering events. Use [NavigationInstructionUpdateInfo.differences] to redraw
  ///     only affected UI components. Cannot be combined with [onNavigationInstruction].
  /// - [onNavigationStarted]: Callback when navigation begins (first valid position received).
  /// - [onTextToSpeechInstruction]: Callback for TTS text. Arguments:
  ///   - `textInstruction`: Text to be spoken by TTS engine. See [SoundPlayingService] to enable TTS.
  /// - [onWaypointReached]: Callback when intermediate waypoint reached. Arguments:
  ///   - `landmark`: Reached waypoint landmark.
  /// - [onDestinationReached]: Callback when final destination reached. Arguments:
  ///   - `landmark`: Destination landmark.
  /// - [onRouteUpdated]: Callback when route recalculated. Arguments:
  ///   - `route`: New route after recalculation.
  /// - [onBetterRouteDetected]: Callback when better route found (requires [RoutePreferences.avoidTraffic]). Arguments:
  ///   - `route`: Better route.
  ///   - `travelTime`: Better route travel time (seconds).
  ///   - `delay`: Traffic delay on better route (seconds).
  ///   - `timeGain`: Time saved vs. current route (seconds). `-1` if original route has roadblocks.
  /// - [onBetterRouteRejected]: Callback when better route check fails. Arguments:
  ///   - `reason`: Rejection error code.
  /// - [onBetterRouteInvalidated]: Callback when previously detected better route becomes invalid.
  /// - [onSkipNextIntermediateDestinationDetected]: Callback when user appears to be skipping next waypoint.
  ///   Might be the time to call [skipNextIntermediateDestination].
  /// - [onTurnAround]: Callback when recalculated route requires opposite direction travel.
  /// - [onRestrictionsUpdated]: Callback when route restrictions change (e.g. the user enters or
  ///   exits a restricted part of the route). Arguments:
  ///   - `exitRestrictions`: Set of [RouteRestrictionType] values that were just exited.
  ///   - `enterRestrictions`: Set of [RouteRestrictionType] values that were just entered.
  /// - [onError]: Callback for navigation errors. Arguments:
  ///   - `error`: Error code. Possible values:
  ///     - [GemError.success]: Completed successfully.
  ///     - [GemError.cancel]: Cancelled by user.
  ///     - [GemError.waypointAccess]: Waypoint unreachable with current preferences.
  ///     - [GemError.connectionRequired]: Online calculation needed but offline-only mode set.
  ///     - [GemError.expired]: Map data version no longer supported by online service.
  ///     - [GemError.routeTooLong]: Online routing timeout.
  ///     - [GemError.invalidated]: Map data changed during calculation.
  ///     - [GemError.noMemory]: Insufficient memory for route calculation.
  /// - [onNotifyStatusChange]: Callback for navigation status changes. Arguments:
  ///   - `status`: New status (running, waiting for GPS, waiting for route, etc.).
  /// - [onRouteCalculationStarted]: Callback when route (re)calculation begins.
  /// - [onRouteCalculationCompleted]: Callback when route (re)calculation finishes. Arguments:
  ///   - `error`: Error code if calculation failed, [GemError.success] otherwise.
  /// - [speedMultiplier]: Simulation speed multiplier. Defaults to `1.0` (real-time speed).
  ///
  /// ## Returns
  ///
  /// - (`TaskHandler?`) Handler for the navigation session, or null if initialization failed
  ///   (geographic search failure). Use with [cancelNavigation] to stop navigation.
  ///
  /// ## See also:
  ///
  /// - [startNavigation] - Start real-time GPS navigation.
  /// - [cancelNavigation] - Stop navigation session.
  /// - [NavigationInstruction] - Real-time turn-by-turn instruction details.
  /// - [NavigationInstructionUpdateInfo] - Optimized update info with field-level differences.
  /// - [RoutingService.calculateRoute] - Route calculation.
  /// - [PositionService] - Position data source configuration.
  /// - [SoundPlayingService] - Text-to-speech configuration.
  static TaskHandler? startSimulation(
    final Route route, {
    final void Function(
      NavigationInstruction instruction,
      Set<NavigationInstructionUpdateEvents> events,
    )?
    onNavigationInstruction,
    final void Function(
      NavigationInstruction instruction,
      NavigationInstructionUpdateInfo updateInfo,
    )?
    onNavigationInstructionOptimized,
    final void Function()? onNavigationStarted,
    final void Function(String textInstruction)? onTextToSpeechInstruction,
    final void Function(Landmark landmark)? onWaypointReached,
    final void Function(Landmark landmark)? onDestinationReached,
    final void Function(Route route)? onRouteUpdated,
    final void Function(Route route, int travelTime, int delay, int timeGain)?
    onBetterRouteDetected,
    final void Function(GemError reason)? onBetterRouteRejected,
    final void Function()? onBetterRouteInvalidated,
    final void Function()? onSkipNextIntermediateDestinationDetected,
    final void Function()? onTurnAround,
    final void Function(
      Set<RouteRestrictionType> exitRestrictions,
      Set<RouteRestrictionType> enterRestrictions,
    )?
    onRestrictionsUpdated,
    final void Function(GemError error)? onError,
    final void Function(NavigationStatus status)? onNotifyStatusChange,
    final void Function()? onRouteCalculationStarted,
    final void Function(GemError error)? onRouteCalculationCompleted,
    final double speedMultiplier = 1.0,
  }) {
    if (onNavigationInstruction != null &&
        onNavigationInstructionOptimized != null) {
      throw ArgumentError(
        'Cannot provide both onNavigationInstruction and onNavigationInstructionOptimized callbacks.',
      );
    }

    final OperationResult result = staticMethod(
      'NavigationService',
      'startNavigation',
      args: <String, dynamic>{
        'route': route.pointerId,
        'simulation': true,
        'speedMultiplier': speedMultiplier,
        'useOptimizedInstructionCallback':
            onNavigationInstructionOptimized != null,
      },
    );

    final int gemApiError = result['gemApiError'];

    if (GemErrorExtension.isErrorCode(gemApiError)) {
      final GemError errorCode = GemErrorExtension.fromCode(gemApiError);
      onError?.call(errorCode);
      return null;
    }

    final int listenerId = result['result'];

    final NavigationListener listener = NavigationListener.init(listenerId);
    listener.registerAll(
      onNavigationStarted: onNavigationStarted,
      onNavigationInstructionUpdated:
          (
            final NavigationInstruction instruction,
            final Set<NavigationInstructionUpdateEvents> events,
          ) {
            onNavigationInstruction?.call(instruction, events);
          },
      onNavigationInstructionUpdatedOptimized: onNavigationInstructionOptimized,
      onWaypointReached: onWaypointReached,
      onDestinationReached: (final Landmark destination) {
        onDestinationReached?.call(destination);
      },
      onNavigationError: (final GemError error) {
        GemKitPlatform.instance.unregisterEventHandler(listener.id);
        onError?.call(error);
      },
      onRouteUpdated: onRouteUpdated,
      onNavigationSound: onTextToSpeechInstruction,
      onNotifyStatusChange: onNotifyStatusChange,
      onBetterRouteDetected: onBetterRouteDetected,
      onBetterRouteRejected: onBetterRouteRejected,
      onBetterRouteInvalidated: onBetterRouteInvalidated,
      onSkipNextIntermediateDestinationDetected:
          onSkipNextIntermediateDestinationDetected,
      onTurnAround: onTurnAround,
      onRestrictionsUpdated: onRestrictionsUpdated,
      onRouteCalculationStarted: onRouteCalculationStarted,
      onRouteCalculationCompleted: onRouteCalculationCompleted,
    );

    GemKitPlatform.instance.registerEventHandler(listener.id, listener);
    return TaskHandlerImpl(listener.id);
  }

  /// Navigation configuration parameters.
  ///
  /// Returns the current navigation engine configuration parameters as a [ParameterList].
  /// These parameters control various aspects of navigation behavior and can be queried
  /// for diagnostic or configuration purposes.
  ///
  /// ## Returns
  ///
  /// - (`ParameterList`) Navigation configuration parameters.
  ///
  /// ## See also:
  ///
  /// - [getIntermediateWaypointDropParameters] - Waypoint drop configuration.
  static ParameterList getNavigationParameters() {
    final OperationResult result = staticMethod(
      'NavigationService',
      'getNavigationParameters',
    );

    return ParameterList.init(result['result']);
  }

  /// Intermediate waypoint drop parameters.
  ///
  /// ## Returns
  ///
  /// - (`ParameterList`) Parameter list containing:
  ///   - `waypoint_drop_radius`: Radius (meters) within which a waypoint may be
  ///     considered for dropping.
  ///   - `waypoint_drop_distance_threshold`: Multiplier factor for calculating next
  ///     drop attempt distance based on previous attempt distance.
  ///   - `waypoint_drop_min_distance_m`: Minimum distance (meters) at which a waypoint
  ///     may be targeted for a drop attempt.
  ///
  /// ## See also:
  ///
  /// - [getNavigationParameters] - General navigation parameters.
  /// - [skipNextIntermediateDestination] - Manually skip intermediate waypoint.
  static ParameterList getIntermediateWaypointDropParameters() {
    final OperationResult result = staticMethod(
      'NavigationService',
      'getIntermediateWaypointDropParameters',
    );

    return ParameterList.init(result['result']);
  }

  /// Next intermediate waypoint skip.
  ///
  /// Manually removes the next intermediate destination from the active navigation
  /// route and triggers route recalculation to the following waypoint or final
  /// destination. The updated route is delivered via the `onRouteUpdated` callback.
  /// Useful when the user decides to skip a planned stop.
  ///
  /// ## Parameters
  ///
  /// - [taskHandler]: Optional handler for the navigation session. If omitted,
  ///   applies to the active session.
  ///
  /// ## Returns
  ///
  /// - (`GemError`) Result code:
  ///   - [GemError.success]: Waypoint skipped successfully.
  ///   - [GemError.notFound]: No intermediate waypoints remaining on route.
  ///
  /// ## See also:
  ///
  /// - [startNavigation] - Register `onRouteUpdated` to receive recalculated route. Also see
  /// `onSkipNextIntermediateDestinationDetected` callback to detect user skipping behavior.
  /// - [getIntermediateWaypointDropParameters] - Automatic waypoint drop configuration.
  static GemError skipNextIntermediateDestination({
    final TaskHandler? taskHandler,
  }) {
    final OperationResult result = staticMethod(
      'NavigationService',
      'skipNextIntermediateDestination',
      args: taskHandler ?? <dynamic, dynamic>{},
    );

    return GemErrorExtension.fromCode(result['result']);
  }

  /// Navigation data source accessor.
  ///
  /// Returns the [DataSource] instance associated with the active navigation session.
  /// This data source provides position updates during navigation. Useful for
  /// inspecting or configuring the position data source used by navigation.
  ///
  /// ## Parameters
  ///
  /// - [navigationListener]: Handler for the navigation session.
  ///
  /// ## Returns
  ///
  /// - (`DataSource`) Navigation position data source.
  ///
  /// ## See also:
  ///
  /// - [PositionService] - Position data source configuration.
  /// - [startNavigation] - Start navigation with position data.
  static DataSource getDataSource(TaskHandler navigationListener) {
    final OperationResult result = staticMethod(
      'NavigationService',
      'getDataSource',
      args: (navigationListener as TaskHandlerImpl).id,
    );

    return DataSource.init(result['result']);
  }

  /// TTS instruction update request.
  ///
  /// Requests the navigation service to immediately generate and deliver an updated
  /// text-to-speech instruction to the `onTextToSpeechInstruction` callback. Use
  /// this to manually trigger TTS updates outside the normal instruction update cycle.
  ///
  /// ## Parameters
  ///
  /// - [navigationListener]: Handler for the navigation session.
  ///
  /// ## See also:
  ///
  /// - [startNavigation] - Register `onTextToSpeechInstruction` callback.
  static void updateNavigationSound(TaskHandler navigationListener) {
    staticMethod(
      'NavigationService',
      'updateNavigationSound',
      args: (navigationListener as TaskHandlerImpl).id,
    );
  }

  /// Navigation transfer statistics.
  ///
  /// Returns a [TransferStatistics] object containing counters and metrics
  /// about network usage performed by the traffic service. This information
  /// can be used for diagnostics or to display usage to end users.
  ///
  /// ## Returns
  ///
  /// - (`TransferStatistics`) Transfer statistics object.
  ///
  /// ## See also:
  ///
  /// - [startNavigation] - Navigation with online features.
  static TransferStatistics get transferStatistics {
    final OperationResult resultString = staticMethod(
      'NavigationService',
      'getTransferStatistics',
    );

    return TransferStatistics.init(resultString['result']);
  }
}

/// Navigation instruction update event types.
///
/// Identifies the specific reason(s) why a [NavigationInstruction] update was
/// triggered, enabling efficient UI updates by redrawing only affected components.
/// Multiple events can occur simultaneously, delivered as a set to the
/// `onNavigationInstruction` callback.
///
/// ## See also:
///
/// - [NavigationService.startNavigation] - Receive events via `onNavigationInstruction`.
/// - [NavigationInstruction] - Instruction data structure.
///
/// {@category Navigation}
enum NavigationInstructionUpdateEvents {
  /// Next route turn updated.
  nextTurnUpdated,

  /// Turn image updated.
  nextTurnImageUpdated,

  /// Lane image updated.
  laneInfoUpdated,

  /// Route restrictions updated.
  ///
  /// Delivered when the user enters or exits a part of the route with
  /// restrictions, or when the active set of restrictions otherwise changes.
  /// See [NavigationInstruction.currentRestrictions] for the current bitmask
  /// of [RouteRestrictionType] values.
  restrictionsUpdated,
}

/// @nodoc
extension NavigationInstructionUpdateEventsExtension
    on NavigationInstructionUpdateEvents {
  int get id {
    switch (this) {
      case NavigationInstructionUpdateEvents.nextTurnUpdated:
        return 1;
      case NavigationInstructionUpdateEvents.nextTurnImageUpdated:
        return 2;
      case NavigationInstructionUpdateEvents.laneInfoUpdated:
        return 4;
      case NavigationInstructionUpdateEvents.restrictionsUpdated:
        return 8;
    }
  }

  static NavigationInstructionUpdateEvents fromId(final int id) {
    switch (id) {
      case 1:
        return NavigationInstructionUpdateEvents.nextTurnUpdated;
      case 2:
        return NavigationInstructionUpdateEvents.nextTurnImageUpdated;
      case 4:
        return NavigationInstructionUpdateEvents.laneInfoUpdated;
      case 8:
        return NavigationInstructionUpdateEvents.restrictionsUpdated;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
