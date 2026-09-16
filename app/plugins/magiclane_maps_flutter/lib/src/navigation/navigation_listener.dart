// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/navigation.dart';
import 'package:magiclane_maps_flutter/routing.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';
import 'package:meta/meta.dart';

/// Listener for navigation events.
///
/// Used internally by the SDK to handle navigation-related events.
/// Consumers typically do not need to interact with this class directly.
///
/// Use the [NavigationService] to register for navigation events.
///
/// @nodoc
@internal
class NavigationListener extends EventHandler {
  @internal
  NavigationListener.init(this.id);
  dynamic id;

  void Function()? _onNavigationStarted;
  void Function(
    NavigationInstruction instruction,
    Set<NavigationInstructionUpdateEvents> events,
  )?
  _onNavigationInstructionUpdated;
  void Function(
    NavigationInstruction instruction,
    NavigationInstructionUpdateInfo updateInfo,
  )?
  _onNavigationInstructionUpdatedOptimized;
  void Function(Landmark waypoint)? _onWaypointReached;
  void Function(Landmark destination)? _onDestinationReached;
  void Function(GemError error)? _onNavigationError;
  void Function(Route route)? _onRouteUpdated;
  void Function(String ttsInstruction)? _onNavigationSound;
  void Function(NavigationStatus status)? _onNotifyStatusChange;
  void Function(Route route, int travelTime, int delay, int timeGain)?
  _onBetterRouteDetected;
  void Function(GemError reason)? _onBetterRouteRejected;
  void Function()? _onBetterRouteInvalidated;
  void Function()? _onSkipNextIntermediateDestinationDetected;
  void Function()? _onTurnAround;
  void Function(
    Set<RouteRestrictionType> exitRestrictions,
    Set<RouteRestrictionType> enterRestrictions,
  )?
  _onRestrictionsUpdated;
  void Function()? _onRouteCalculationStarted;
  void Function(GemError error)? _onRouteCalculationCompleted;

  void registerAll({
    required final void Function()? onNavigationStarted,
    required final void Function(
      NavigationInstruction instruction,
      Set<NavigationInstructionUpdateEvents> events,
    )?
    onNavigationInstructionUpdated,
    required final void Function(
      NavigationInstruction instruction,
      NavigationInstructionUpdateInfo updateInfo,
    )?
    onNavigationInstructionUpdatedOptimized,
    required final void Function(Landmark waypoint)? onWaypointReached,
    required final void Function(Landmark destination)? onDestinationReached,
    required final void Function(GemError error)? onNavigationError,
    required final void Function(Route route)? onRouteUpdated,
    required final void Function(String ttsInstruction)? onNavigationSound,
    required final void Function(NavigationStatus status)? onNotifyStatusChange,
    required final void Function(
      Route route,
      int travelTime,
      int delay,
      int timeGain,
    )?
    onBetterRouteDetected,
    required final void Function(GemError reason)? onBetterRouteRejected,
    required final void Function()? onBetterRouteInvalidated,
    required final void Function()? onSkipNextIntermediateDestinationDetected,
    required final void Function()? onTurnAround,
    required final void Function(
      Set<RouteRestrictionType> exitRestrictions,
      Set<RouteRestrictionType> enterRestrictions,
    )?
    onRestrictionsUpdated,
    required final void Function()? onRouteCalculationStarted,
    required final void Function(GemError error)? onRouteCalculationCompleted,
  }) {
    _onNavigationStarted = onNavigationStarted;
    _onNavigationInstructionUpdated = onNavigationInstructionUpdated;
    _onNavigationInstructionUpdatedOptimized =
        onNavigationInstructionUpdatedOptimized;
    _onWaypointReached = onWaypointReached;
    _onDestinationReached = onDestinationReached;
    _onNavigationError = onNavigationError;
    _onRouteUpdated = onRouteUpdated;
    _onNavigationSound = onNavigationSound;
    _onNotifyStatusChange = onNotifyStatusChange;
    _onBetterRouteDetected = onBetterRouteDetected;
    _onBetterRouteRejected = onBetterRouteRejected;
    _onBetterRouteInvalidated = onBetterRouteInvalidated;
    _onSkipNextIntermediateDestinationDetected =
        onSkipNextIntermediateDestinationDetected;
    _onTurnAround = onTurnAround;
    _onRestrictionsUpdated = onRestrictionsUpdated;
    _onRouteCalculationStarted = onRouteCalculationStarted;
    _onRouteCalculationCompleted = onRouteCalculationCompleted;
  }

  @override
  void nativeClear() {
    // No native-side cleanup required for this listener.
  }

  @override
  void clearListeners() {
    _onNavigationStarted = null;
    _onNavigationInstructionUpdated = null;
    _onNavigationInstructionUpdatedOptimized = null;
    _onWaypointReached = null;
    _onDestinationReached = null;
    _onNavigationError = null;
    _onRouteUpdated = null;
    _onNavigationSound = null;
    _onNotifyStatusChange = null;
    _onBetterRouteDetected = null;
    _onBetterRouteRejected = null;
    _onBetterRouteInvalidated = null;
    _onSkipNextIntermediateDestinationDetected = null;
    _onTurnAround = null;
    _onRestrictionsUpdated = null;
    _onRouteCalculationStarted = null;
    _onRouteCalculationCompleted = null;
  }

  @override
  void handleEvent(final Map<dynamic, dynamic> arguments) {
    final String eventType = arguments['eventType'];

    switch (eventType) {
      case 'navStarted':
        if (_onNavigationStarted != null) {
          _onNavigationStarted!();
        }
      case 'navInstructionUpdated':
        final NavigationInstruction instruction = NavigationInstruction.init(
          arguments['instruction'],
        );
        if (arguments.containsKey('updateInfo') &&
            _onNavigationInstructionUpdatedOptimized != null) {
          final NavigationInstructionUpdateInfo updateInfo =
              NavigationInstructionUpdateInfo.fromJson(
                arguments['updateInfo'] as Map<dynamic, dynamic>,
              );
          _onNavigationInstructionUpdatedOptimized!(instruction, updateInfo);
        } else if (_onNavigationInstructionUpdated != null) {
          final int eventsInt = arguments['events'];
          final Set<NavigationInstructionUpdateEvents> events =
              <NavigationInstructionUpdateEvents>{};

          for (final NavigationInstructionUpdateEvents event
              in NavigationInstructionUpdateEvents.values) {
            if (event.id & eventsInt != 0) {
              events.add(event);
            }
          }

          _onNavigationInstructionUpdated!(instruction, events);
        }
      case 'navigationDstEvent':
        if (_onDestinationReached != null) {
          _onDestinationReached!(Landmark.init(arguments['landmark']));
        }
      case 'navigationWptEvent':
        if (_onWaypointReached != null) {
          _onWaypointReached!(Landmark.init(arguments['landmark']));
        }
      case 'navigationErrorEvent':
        if (_onNavigationError != null) {
          _onNavigationError!(GemErrorExtension.fromCode(arguments['errCode']));
        }
      case 'onRouteUpdated':
        if (_onRouteUpdated != null) {
          final Route route = Route.init(arguments['route']);
          _onRouteUpdated!(route);
        }
      case 'navSound':
        if (_onNavigationSound != null) {
          _onNavigationSound!(arguments['ttsString']);
        }
      case 'navStatusChange':
        if (_onNotifyStatusChange != null) {
          _onNotifyStatusChange!(
            NavigationStatusExtension.fromId(arguments['status']),
          );
        }
      case 'onBetterRouteDetected':
        if (_onBetterRouteDetected != null) {
          final Route route = Route.init(arguments['route']);
          _onBetterRouteDetected!(
            route,
            arguments['travelTime'],
            arguments['delay'],
            arguments['timeGain'],
          );
        }
      case 'onBetterRouteRejected':
        if (_onBetterRouteRejected != null) {
          _onBetterRouteRejected!(
            GemErrorExtension.fromCode(arguments['reason']),
          );
        }
      case 'onBetterRouteInvalidated':
        if (_onBetterRouteInvalidated != null) {
          _onBetterRouteInvalidated!();
        }
      case 'onSkipNextIntermediateDestinationDetected':
        if (_onSkipNextIntermediateDestinationDetected != null) {
          _onSkipNextIntermediateDestinationDetected!();
        }
      case 'onTurnAround':
        if (_onTurnAround != null) {
          _onTurnAround!();
        }
      case 'onRestrictionsUpdated':
        if (_onRestrictionsUpdated != null) {
          final int exitMask = arguments['exitRestrictions'] ?? 0;
          final int enterMask = arguments['enterRestrictions'] ?? 0;
          final Set<RouteRestrictionType> exit = <RouteRestrictionType>{};
          final Set<RouteRestrictionType> enter = <RouteRestrictionType>{};
          for (final RouteRestrictionType value
              in RouteRestrictionType.values) {
            if (exitMask & value.id != 0) {
              exit.add(value);
            }
            if (enterMask & value.id != 0) {
              enter.add(value);
            }
          }
          _onRestrictionsUpdated!(exit, enter);
        }
      case 'startEvent':
        if (_onRouteCalculationStarted != null) {
          _onRouteCalculationStarted!();
        }
      case 'completeEvent':
        if (_onRouteCalculationCompleted != null) {
          final int errCode = arguments['errCode'];
          _onRouteCalculationCompleted!(GemErrorExtension.fromCode(errCode));
        }
      default:
        gemSdkLogger.log(
          Level.WARNING,
          'Unknown event subtype: $eventType in NavigationListener',
        );
    }
  }
}
