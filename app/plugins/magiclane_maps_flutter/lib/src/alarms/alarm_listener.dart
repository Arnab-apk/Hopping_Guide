// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';
import 'package:meta/meta.dart';

/// Receives notifications for navigation-related alarm events and environmental changes.
///
/// The [AlarmListener] provides callbacks for a comprehensive range of monitoring events including
/// speed limit violations, geographic boundary crossings, landmark and overlay item proximity alerts,
/// tunnel entries and exits, and day/night mode transitions. Multiple alarm listeners can operate
/// simultaneously within different [AlarmService] instances, allowing for concurrent monitoring of various events.
///
/// The listener must be passed to [AlarmService] constructor to receive event notifications.
/// Both the [AlarmListener] and [AlarmService] instances must remain in memory for the duration of the
/// notification period, as removing these objects will prevent callbacks from being triggered.
///
/// ## See also:
///
/// - [AlarmService] - Central service for managing alarm events and notifications.
/// - [LandmarkAlarmsList] - List of landmark alarms being monitored.
/// - [OverlayItemAlarmsList] - List of overlay item alarms being monitored.
///
/// {@category Alarms}
class AlarmListener extends EventHandler {
  /// Creates an alarm listener with optional callbacks for various alarm events.
  ///
  /// The listener must be passed to [AlarmService] constructor to receive event notifications.
  /// Each callback is optional and can be set during construction or later using the corresponding
  /// register methods. Only one callback per event type can be active at a time.
  ///
  /// ## Parameters
  ///
  /// - [onBoundaryCrossed]: Invoked when crossing geographic area boundaries. Arguments:
  ///   - `enteredAreas`: List of area IDs that were entered.
  ///   - `exitedAreas`: List of area IDs that were exited.
  /// - [onMonitoringStateChanged]: Invoked when monitoring state changes. Arguments:
  ///   - `isMonitoringActive`: True if monitoring is active, false otherwise.
  /// - [onTunnelEntered]: Invoked when entering a tunnel.
  /// - [onTunnelLeft]: Invoked when exiting a tunnel.
  /// - [onLandmarkAlarmsUpdated]: Invoked continuously while approaching monitored landmarks within alarm distance.
  /// - [onOverlayItemAlarmsUpdated]: Invoked continuously while approaching monitored overlay items within alarm distance.
  /// - [onLandmarkAlarmsPassedOver]: Invoked once when monitored landmarks are passed.
  /// - [onOverlayItemAlarmsPassedOver]: Invoked once when monitored overlay items are passed.
  /// - [onHighSpeed]: Invoked continuously while exceeding speed limit by configured threshold. Arguments:
  ///   - `limit`: Speed limit in meters per second.
  ///   - `insideCityArea`: True if inside area with lower speed limits (cities, towns, villages).
  /// - [onNormalSpeed]: Invoked once when speed returns to within normal range after high speed. Arguments:
  ///   - `limit`: Speed limit in meters per second.
  ///   - `insideCityArea`: True if inside area with lower speed limits.
  /// - [onSpeedLimit]: Invoked when new speed limit is encountered. Limit is 0 if unknown or no road matched. Arguments:
  ///   - `speed`: Current speed in meters per second.
  ///   - `limit`: Speed limit in meters per second (0 if unknown).
  ///   - `insideCityArea`: True if inside area with lower speed limits.
  /// - [onEnterDayMode]: Invoked when location transitions from night to day based on geography and season.
  /// - [onEnterNightMode]: Invoked when location transitions from day to night based on geography and season.
  ///
  /// ## See also:
  ///
  /// - [AlarmService] - For attaching this listener and configuring alarm behavior.
  factory AlarmListener({
    final void Function(List<String> enteredAreas, List<String> exitedAreas)?
    onBoundaryCrossed,
    final void Function(bool isMonitoringActive)? onMonitoringStateChanged,
    final void Function()? onTunnelEntered,
    final void Function()? onTunnelLeft,
    final void Function()? onLandmarkAlarmsUpdated,
    final void Function()? onOverlayItemAlarmsUpdated,
    final void Function()? onLandmarkAlarmsPassedOver,
    final void Function()? onOverlayItemAlarmsPassedOver,
    final void Function(double limit, bool insideCityArea)? onHighSpeed,
    final void Function(double limit, bool insideCityArea)? onNormalSpeed,
    final void Function(double speed, double limit, bool insideCityArea)?
    onSpeedLimit,
    final void Function()? onEnterDayMode,
    final void Function()? onEnterNightMode,
  }) {
    final AlarmListener listener = AlarmListener._create();

    if (onBoundaryCrossed != null) {
      listener.registerOnBoundaryCrossed(onBoundaryCrossed);
    }
    if (onMonitoringStateChanged != null) {
      listener.registerOnMonitoringStateChanged(onMonitoringStateChanged);
    }
    if (onTunnelEntered != null) {
      listener.registerOnTunnelEntered(onTunnelEntered);
    }
    if (onTunnelLeft != null) {
      listener.registerOnTunnelLeft(onTunnelLeft);
    }
    if (onLandmarkAlarmsUpdated != null) {
      listener.registerOnLandmarkAlarmsUpdated(onLandmarkAlarmsUpdated);
    }
    if (onOverlayItemAlarmsUpdated != null) {
      listener.registerOnOverlayItemAlarmsUpdated(onOverlayItemAlarmsUpdated);
    }
    if (onLandmarkAlarmsPassedOver != null) {
      listener.registerOnLandmarkAlarmsPassedOver(onLandmarkAlarmsPassedOver);
    }
    if (onOverlayItemAlarmsPassedOver != null) {
      listener.registerOnOverlayItemAlarmsPassedOver(
        onOverlayItemAlarmsPassedOver,
      );
    }
    if (onHighSpeed != null) {
      listener.registerOnHighSpeed(onHighSpeed);
    }
    if (onNormalSpeed != null) {
      listener.registerOnNormalSpeed(onNormalSpeed);
    }
    if (onSpeedLimit != null) {
      listener.registerOnSpeedLimit(onSpeedLimit);
    }
    if (onEnterDayMode != null) {
      listener.registerOnEnterDayMode(onEnterDayMode);
    }
    if (onEnterNightMode != null) {
      listener.registerOnEnterNightMode(onEnterNightMode);
    }

    return listener;
  }

  @internal
  AlarmListener.init(this.id);

  void Function(List<String> enteredAreas, List<String> exitedAreas)?
  _onBoundaryCrossedCallback;
  void Function(bool isMonitoringActive)? _onMonitoringStateChangedCallback;
  void Function()? _onTunnelEnteredCallback;
  void Function()? _onTunnelLeftCallback;
  void Function()? _onLandmarkAlarmsUpdatedCallback;
  void Function()? _onOverlayItemAlarmsUpdatedCallback;
  void Function()? _onLandmarkAlarmsPassedOverCallback;
  void Function()? _onOverlayItemAlarmsPassedOverCallback;
  void Function(double limit, bool insideCityArea)? _onHighSpeedCallback;
  void Function(double limit, bool insideCityArea)? _onNormalSpeedCallback;
  void Function(double speed, double limit, bool insideCityArea)?
  _onSpeedLimitCallback;
  void Function()? _onEnterDayModeCallback;
  void Function()? _onEnterNightModeCallback;

  dynamic id;

  /// Registers a callback invoked when crossing geographic area boundaries.
  ///
  /// The callback is triggered when entering or exiting monitored geographic areas added via
  /// [AlarmService.monitorArea]. It is not called initially if the user starts from inside a
  /// boundary—only when the boundary is actually crossed. Pass null to unregister the callback.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when boundaries are crossed. Arguments:
  ///   - `enteredAreas`: List of area IDs that were entered.
  ///   - `exitedAreas`: List of area IDs that were exited.
  ///
  /// ## See also:
  ///
  /// - [AlarmService.monitorArea] - For adding geographic areas to monitor.
  /// - [AlarmService.monitoredAreas] - For retrieving list of monitored areas.
  void registerOnBoundaryCrossed(
    final void Function(List<String> enteredAreas, List<String> exitedAreas)?
    callback,
  ) {
    _onBoundaryCrossedCallback = callback;
  }

  /// Registers a callback invoked when the alarm monitoring state changes.
  ///
  /// The callback is triggered when the alarm service transitions between active and inactive
  /// monitoring states. Pass null to unregister the callback.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when monitoring state changes. Arguments:
  ///   - `isMonitoringActive`: True if monitoring is active, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [AlarmService] - For managing the alarm monitoring service.
  void registerOnMonitoringStateChanged(
    final void Function(bool isMonitoringActive)? callback,
  ) {
    _onMonitoringStateChangedCallback = callback;
  }

  /// Registers a callback invoked when entering a tunnel.
  ///
  /// The callback is triggered when the user's position enters a tunnel during navigation or
  /// simulation. Pass null to unregister the callback.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when entering a tunnel.
  ///
  /// ## See also:
  ///
  /// - [registerOnTunnelLeft] - For detecting tunnel exit events.
  void registerOnTunnelEntered(final void Function()? callback) {
    _onTunnelEnteredCallback = callback;
  }

  /// Registers a callback invoked when exiting a tunnel.
  ///
  /// The callback is triggered when the user's position exits a tunnel during navigation or
  /// simulation. Pass null to unregister the callback.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when exiting a tunnel.
  ///
  /// ## See also:
  ///
  /// - [registerOnTunnelEntered] - For detecting tunnel entry events.
  void registerOnTunnelLeft(final void Function()? callback) {
    _onTunnelLeftCallback = callback;
  }

  /// Registers a callback invoked continuously when approaching monitored landmarks.
  ///
  /// The callback is triggered repeatedly while the user is within the alarm distance of monitored
  /// landmarks, until the landmarks are intercepted. Use [AlarmService.landmarkAlarms] to retrieve
  /// the list of approaching landmarks with their distances. Pass null to unregister the callback.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when landmark alarms are updated.
  ///
  /// ## See also:
  ///
  /// - [AlarmService.landmarkAlarms] - For retrieving approaching landmark list.
  /// - [registerOnLandmarkAlarmsPassedOver] - For detecting when landmarks are passed.
  /// - [AlarmService.landmarks] - For configuring which landmarks to monitor.
  void registerOnLandmarkAlarmsUpdated(final void Function()? callback) {
    _onLandmarkAlarmsUpdatedCallback = callback;
  }

  /// Registers a callback invoked continuously when approaching monitored overlay items.
  ///
  /// The callback is triggered repeatedly while the user is within the alarm distance of monitored
  /// overlay items (such as safety cameras, social reports), until the items are intercepted. Use
  /// [AlarmService.overlayItemAlarms] to retrieve the list of approaching items. Pass null to
  /// unregister the callback.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when overlay item alarms are updated.
  ///
  /// ## See also:
  ///
  /// - [AlarmService.overlayItemAlarms] - For retrieving approaching overlay item list.
  /// - [registerOnOverlayItemAlarmsPassedOver] - For detecting when items are passed.
  /// - [AlarmService.overlays] - For configuring which overlays to monitor.
  void registerOnOverlayItemAlarmsUpdated(final void Function()? callback) {
    _onOverlayItemAlarmsUpdatedCallback = callback;
  }

  /// Registers a callback invoked once when monitored landmarks are passed.
  ///
  /// The callback is triggered once when landmarks are intercepted (passed over). Use
  /// [AlarmService.landmarkAlarmsPassedOver] to retrieve the list of passed landmarks. Items in
  /// this list do not have a predefined sort order. Pass null to unregister the callback.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when landmark alarms are passed over.
  ///
  /// ## See also:
  ///
  /// - [AlarmService.landmarkAlarmsPassedOver] - For retrieving passed landmark list.
  /// - [registerOnLandmarkAlarmsUpdated] - For detecting when landmarks are approaching.
  void registerOnLandmarkAlarmsPassedOver(final void Function()? callback) {
    _onLandmarkAlarmsPassedOverCallback = callback;
  }

  /// Registers a callback invoked once when monitored overlay items are passed.
  ///
  /// The callback is triggered once when overlay items are intercepted (passed over). Use
  /// [AlarmService.overlayItemAlarmsPassedOver] to retrieve the list of passed items. Items in
  /// this list do not have a predefined sort order. Pass null to unregister the callback.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when overlay item alarms are passed over.
  ///
  /// ## See also:
  ///
  /// - [AlarmService.overlayItemAlarmsPassedOver] - For retrieving passed item list.
  /// - [registerOnOverlayItemAlarmsUpdated] - For detecting when items are approaching.
  void registerOnOverlayItemAlarmsPassedOver(final void Function()? callback) {
    _onOverlayItemAlarmsPassedOverCallback = callback;
  }

  /// Registers a callback invoked continuously when exceeding the speed limit.
  ///
  /// The callback is triggered repeatedly while the vehicle exceeds the speed limit by the threshold
  /// configured via [AlarmService.setOverSpeedThreshold]. Different thresholds can be set for areas
  /// inside and outside cities. Pass null to unregister the callback.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when high speed is detected. Arguments:
  ///   - `limit`: Speed limit in meters per second for the current road section.
  ///   - `insideCityArea`: True if inside area with lower speed limits (cities, towns, villages).
  ///
  /// ## See also:
  ///
  /// - [AlarmService.setOverSpeedThreshold] - For configuring speed threshold.
  /// - [registerOnNormalSpeed] - For detecting when speed returns to normal.
  /// - [registerOnSpeedLimit] - For detecting speed limit changes.
  void registerOnHighSpeed(
    final void Function(double limit, bool insideCityArea)? callback,
  ) {
    _onHighSpeedCallback = callback;
  }

  /// Registers a callback invoked once when speed returns to normal range.
  ///
  /// The callback is triggered once when the vehicle slows down from exceeding the speed limit to
  /// within the normal speed range (below limit plus threshold). Pass null to unregister the callback.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when normal speed is restored. Arguments:
  ///   - `limit`: Speed limit in meters per second for the current road section.
  ///   - `insideCityArea`: True if inside area with lower speed limits (cities, towns, villages).
  ///
  /// ## See also:
  ///
  /// - [registerOnHighSpeed] - For detecting when speed limit is exceeded.
  /// - [AlarmService.setOverSpeedThreshold] - For configuring speed threshold.
  void registerOnNormalSpeed(
    final void Function(double limit, bool insideCityArea)? callback,
  ) {
    _onNormalSpeedCallback = callback;
  }

  /// Registers a callback invoked when a new speed limit is encountered.
  ///
  /// The callback is triggered once when the current road section has a different speed limit than
  /// the previous road section. The limit parameter will be 0 if the speed limit is unknown, the
  /// road has no speed limit, or if the matched position is not on a road. Pass null to unregister
  /// the callback.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when speed limit changes. Arguments:
  ///   - `speed`: Current speed in meters per second.
  ///   - `limit`: Speed limit in meters per second (0 if unknown or no road matched).
  ///   - `insideCityArea`: True if inside area with lower speed limits (cities, towns, villages).
  ///
  /// ## See also:
  ///
  /// - [registerOnHighSpeed] - For detecting speed limit violations.
  /// - [registerOnNormalSpeed] - For detecting when speed returns to normal.
  void registerOnSpeedLimit(
    final void Function(double speed, double limit, bool insideCityArea)?
    callback,
  ) {
    _onSpeedLimitCallback = callback;
  }

  /// Registers a callback invoked when transitioning from night to day mode.
  ///
  /// The callback is triggered when the user's location transitions from night to day, based on the
  /// geographic region and corresponding seasonal changes. Pass null to unregister the callback.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when entering day mode.
  ///
  /// ## See also:
  ///
  /// - [registerOnEnterNightMode] - For detecting night mode transitions.
  void registerOnEnterDayMode(final void Function()? callback) {
    _onEnterDayModeCallback = callback;
  }

  /// Registers a callback invoked when transitioning from day to night mode.
  ///
  /// The callback is triggered when the user's location transitions from day to night, based on the
  /// geographic region and corresponding seasonal changes. Pass null to unregister the callback.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when entering night mode.
  ///
  /// ## See also:
  ///
  /// - [registerOnEnterDayMode] - For detecting day mode transitions.
  void registerOnEnterNightMode(final void Function()? callback) {
    _onEnterNightModeCallback = callback;
  }

  static AlarmListener _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'AlarmListener',
        'args': <String, dynamic>{},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return AlarmListener.init(decodedVal['result']);
  }

  @override
  void nativeClear() {
    // No native-side cleanup required for this listener.
  }

  @override
  void clearListeners() {
    _onBoundaryCrossedCallback = null;
    _onMonitoringStateChangedCallback = null;
    _onTunnelEnteredCallback = null;
    _onTunnelLeftCallback = null;
    _onLandmarkAlarmsUpdatedCallback = null;
    _onOverlayItemAlarmsUpdatedCallback = null;
    _onLandmarkAlarmsPassedOverCallback = null;
    _onOverlayItemAlarmsPassedOverCallback = null;
    _onHighSpeedCallback = null;
    _onNormalSpeedCallback = null;
    _onSpeedLimitCallback = null;
    _onEnterDayModeCallback = null;
    _onEnterNightModeCallback = null;
  }

  @override
  void handleEvent(final Map<dynamic, dynamic> arguments) {
    final String eventSubtype = arguments['event_subtype'];

    switch (eventSubtype) {
      case 'onBoundaryCrossed':
        if (_onBoundaryCrossedCallback != null) {
          final List<String> enteredAreas =
              (arguments['enteredAreas'] as List<dynamic>).cast<String>();
          final List<String> exitedAreas =
              (arguments['exitedAreas'] as List<dynamic>).cast<String>();

          _onBoundaryCrossedCallback!(enteredAreas, exitedAreas);
        }

      case 'onMonitoringStateChanged':
        if (_onMonitoringStateChangedCallback != null) {
          _onMonitoringStateChangedCallback!(arguments['isMonitoringActive']);
        }

      case 'onTunnelEntered':
        if (_onTunnelEnteredCallback != null) {
          _onTunnelEnteredCallback!();
        }

      case 'onTunnelLeft':
        if (_onTunnelLeftCallback != null) {
          _onTunnelLeftCallback!();
        }

      case 'onLandmarkAlarmsUpdated':
        if (_onLandmarkAlarmsUpdatedCallback != null) {
          _onLandmarkAlarmsUpdatedCallback!();
        }

      case 'onOverlayItemAlarmsUpdated':
        if (_onOverlayItemAlarmsUpdatedCallback != null) {
          _onOverlayItemAlarmsUpdatedCallback!();
        }

      case 'onLandmarkAlarmsPassedOver':
        if (_onLandmarkAlarmsPassedOverCallback != null) {
          _onLandmarkAlarmsPassedOverCallback!();
        }

      case 'onOverlayItemAlarmsPassedOver':
        if (_onOverlayItemAlarmsPassedOverCallback != null) {
          _onOverlayItemAlarmsPassedOverCallback!();
        }

      case 'onHighSpeed':
        if (_onHighSpeedCallback != null) {
          _onHighSpeedCallback!(
            arguments['limit'],
            arguments['insideCityArea'],
          );
        }

      case 'onNormalSpeed':
        if (_onNormalSpeedCallback != null) {
          _onNormalSpeedCallback!(
            arguments['limit'],
            arguments['insideCityArea'],
          );
        }

      case 'onSpeedLimit':
        if (_onSpeedLimitCallback != null) {
          _onSpeedLimitCallback!(
            arguments['speed'],
            arguments['limit'],
            arguments['insideCityArea'],
          );
        }

      case 'onEnterDayMode':
        if (_onEnterDayModeCallback != null) {
          _onEnterDayModeCallback!();
        }

      case 'onEnterNightMode':
        if (_onEnterNightModeCallback != null) {
          _onEnterNightModeCallback!();
        }

      default:
        gemSdkLogger.log(
          Level.WARNING,
          'Unknown event subtype: $eventSubtype in AlarmListener',
        );
    }
  }
}
