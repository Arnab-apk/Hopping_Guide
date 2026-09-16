// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';

/// Listener for user-defined persistent roadblock events.
///
/// Provides callbacks for notifications when user-created persistent
/// roadblocks become active or expire. Persistent roadblocks are traffic
/// events created by the user (path- or area-based) that remain managed by
/// the [TrafficService]. Register an instance of this listener with
/// [TrafficService.persistentRoadblockListener] to start receiving events from
/// the native platform.
///
/// ## Example
///
/// ```dart
/// final listener = PersistentRoadblockListener(
///   onRoadblocksActivated: (events) {
///     print('Activated: ${events.length} events');
///   },
///   onRoadblocksExpired: (events) {
///     print('Expired: ${events.length} events');
///   },
/// );
///
/// TrafficService.persistentRoadblockListener = listener;
/// ```
///
/// ## See also:
///
/// - [TrafficService] - Manage persistent roadblocks and register this
///   listener via [TrafficService.persistentRoadblockListener].
/// - [TrafficEvent] - Represents a traffic event (roadblock) delivered to the
///   listener callbacks.
///
/// {@category Traffic & Roadblocks}
class PersistentRoadblockListener extends EventHandler {
  /// Creates a [PersistentRoadblockListener].
  ///
  /// Construct a listener with optional callbacks that will be invoked when
  /// user persistent roadblocks are activated or expired. After creating the
  /// listener you must register it with the SDK via
  /// [TrafficService.persistentRoadblockListener] setter to receive events.
  ///
  /// ## Parameters
  ///
  /// - [onRoadblocksExpired]: Optional callback invoked when one or more
  ///   persistent roadblocks have expired (their `endTime` passed).
  /// - [onRoadblocksActivated]: Optional callback invoked when one or more
  ///   persistent roadblocks are activated (their `startTime` has passed).
  ///
  /// ## See also:
  ///
  /// - [TrafficService.persistentRoadblockListener] - Register this listener
  ///   to receive persistent roadblock events.
  factory PersistentRoadblockListener({
    final void Function(List<TrafficEvent> eventList)? onRoadblocksExpired,
    final void Function(List<TrafficEvent> eventList)? onRoadblocksActivated,
  }) {
    final PersistentRoadblockListener listener =
        PersistentRoadblockListener._create();

    if (onRoadblocksExpired != null) {
      listener._onRoadblocksExpired = onRoadblocksExpired;
    }
    if (onRoadblocksActivated != null) {
      listener._onRoadblocksActivated = onRoadblocksActivated;
    }

    return listener;
  }

  PersistentRoadblockListener.init(this.id);
  void Function(List<TrafficEvent> eventList)? _onRoadblocksExpired;
  void Function(List<TrafficEvent> eventList)? _onRoadblocksActivated;

  dynamic id;

  static PersistentRoadblockListener _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'PersistentRoadblockListener',
        'args': <dynamic, dynamic>{},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return PersistentRoadblockListener.init(decodedVal['result']);
  }

  /// Notification called when some user roadblocks are expired.
  /// Register a callback to be invoked when user persistent roadblocks
  /// expire (their [TrafficEvent.endTime] moved from the future into the past).
  ///
  /// ## Parameters
  ///
  /// - [onRoadblocksExpired]: Callback invoked with a `List<TrafficEvent>`
  ///   containing the expired events. The list is ordered but callers should
  ///   not assume a particular order.
  void registerOnRoadblocksExpired(
    final void Function(List<TrafficEvent> eventList)? onRoadblocksExpired,
  ) {
    _onRoadblocksExpired = onRoadblocksExpired;
  }

  /// Notification called when some user roadblocks are activated.
  /// Register a callback to be invoked when user persistent roadblocks are
  /// activated (their [TrafficEvent.startTime] moved from the future into the past).
  ///
  /// ## Parameters
  ///
  /// - [onRoadblocksActivated]: Callback invoked with a `List<TrafficEvent>`
  ///   containing the activated events.
  void registerOnRoadblocksActivated(
    final void Function(List<TrafficEvent> eventList)? onRoadblocksActivated,
  ) {
    _onRoadblocksActivated = onRoadblocksActivated;
  }

  @override
  void nativeClear() {
    // No native-side cleanup required for this listener.
  }

  @override
  void clearListeners() {
    _onRoadblocksExpired = null;
    _onRoadblocksActivated = null;
  }

  @override
  void handleEvent(final Map<dynamic, dynamic> arguments) {
    final String eventSubtype = arguments['event_subtype'];

    switch (eventSubtype) {
      case 'onRoadblocksExpired':
        if (_onRoadblocksExpired != null) {
          final TrafficEventList events = TrafficEventList.init(
            arguments['eventList'],
          );
          _onRoadblocksExpired!(events.toList());
          events.dispose();
        }

      case 'onRoadblocksActivated':
        if (_onRoadblocksActivated != null) {
          final TrafficEventList events = TrafficEventList.init(
            arguments['eventList'],
          );
          _onRoadblocksActivated!(events.toList());
          events.dispose();
        }

      default:
        gemSdkLogger.log(
          Level.WARNING,
          'Unknown event subtype: $eventSubtype in PersistentRoadblockListener',
        );
    }
  }
}
