// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';
import 'package:meta/meta.dart';

/// Listener for events related to a computed route.
///
/// Receives asynchronous notifications produced by the routing/navigation
/// runtime for a specific [Route] instance. Typical events include updates to
/// route-related traffic, confirmation that traffic events along the route
/// were checked, and debug notifications when the route's recorded track is
/// trimmed during navigation.
///
/// Create a [RouteListener] with the factory constructor and attach it to a
/// route via [Route.routeListener] to receive events for that route.
///
/// ## Example
///
/// ```dart
/// final RouteListener routeListener = RouteListener(
///   onRouteTrafficEventsUpdated: (delayDiff) {
///     print('Traffic delay difference: $delayDiff s');
///   },
///   onTrafficEventsAlongRouteChecked: () {
///     print('Traffic events along route checked');
///   },
///   onRouteTrackTrimmed: () {
///     print('Route track trimmed');
///   },
/// );
///
/// route.routeListener = routeListener;
/// ```
///
/// ## See also:
///
/// - [RouteBase.routeListener] — Attach or remove the [RouteListener] to a [Route].
/// - [NavigationService] — Higher-level navigation helpers that emit related events.
///
/// {@category Route}
class RouteListener extends EventHandler {
  /// Creates a [RouteListener].
  ///
  /// Factory constructor that optionally accepts initial callbacks for the
  /// most common route events. Callbacks can be changed later via the
  /// `registerOn*` methods.
  ///
  /// ## Parameters
  ///
  /// - [onRouteTrafficEventsUpdated]: Optional callback invoked when traffic
  ///   events affecting the route are updated. The callback receives an
  ///   integer argument that represents the difference in delay (seconds)
  ///   between the new and previous delay for the remaining travel distance.
  /// - [onTrafficEventsAlongRouteChecked]: Optional callback invoked when the
  ///   SDK verifies traffic events along the route. No arguments are provided.
  /// - [onRouteTrackTrimmed]: Optional callback invoked when the SDK trims
  ///   the recorded navigation track for this route (primarily for diagnostics).
  factory RouteListener({
    final void Function(int delayDiff)? onRouteTrafficEventsUpdated,
    final void Function()? onTrafficEventsAlongRouteChecked,
    final void Function()? onRouteTrackTrimmed,
  }) {
    final RouteListener listener = RouteListener._create();

    if (onRouteTrafficEventsUpdated != null) {
      listener._onRouteTrafficEventsUpdated = onRouteTrafficEventsUpdated;
    }
    if (onTrafficEventsAlongRouteChecked != null) {
      listener._onTrafficEventsAlongRouteChecked =
          onTrafficEventsAlongRouteChecked;
    }
    if (onRouteTrackTrimmed != null) {
      listener._onRouteTrackTrimmed = onRouteTrackTrimmed;
    }

    return listener;
  }

  @internal
  RouteListener.init(this.id);

  void Function(int delayDiff)? _onRouteTrafficEventsUpdated;
  void Function()? _onTrafficEventsAlongRouteChecked;
  void Function()? _onRouteTrackTrimmed;

  dynamic id;

  static RouteListener _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'RouteListener',
        'args': <dynamic, dynamic>{},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return RouteListener.init(decodedVal['result']);
  }

  /// Registers a callback invoked when traffic events affecting the route
  /// are updated.
  ///
  /// Use this to be notified when traffic conditions change and affect
  /// the estimated travel time along the route.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with an integer argument representing
  ///  the difference in delay (seconds) between the new and previous delay.
  ///  Pass `null` to remove the callback.
  void registerOnRouteTrafficEventsUpdated(
    final void Function(int delayDiff)? callback,
  ) {
    _onRouteTrafficEventsUpdated = callback;
  }

  /// Registers a callback invoked when traffic events along the route have
  /// been checked by the SDK.
  ///
  /// Use this to be notified when the traffic verification completes.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with no arguments when traffic events have
  ///   been checked. Pass `null` to remove the callback.
  void registerOnTrafficEventsAlongRouteChecked(
    final void Function()? callback,
  ) {
    _onTrafficEventsAlongRouteChecked = callback;
  }

  /// Registers a callback invoked when the route's recorded track is trimmed.
  ///
  /// This event is primarily provided for debugging and diagnostics during
  /// navigation and receives no arguments.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with no arguments when the route track
  ///   has been trimmed. Pass `null` to remove the callback.
  void registerOnRouteTrackTrimmed(final void Function()? callback) {
    _onRouteTrackTrimmed = callback;
  }

  @override
  void nativeClear() {
    // No native-side cleanup required for this listener.
  }

  @override
  void clearListeners() {
    _onRouteTrafficEventsUpdated = null;
    _onTrafficEventsAlongRouteChecked = null;
    _onRouteTrackTrimmed = null;
  }

  @override
  void handleEvent(final Map<dynamic, dynamic> arguments) {
    final String eventSubtype = arguments['event_subtype'];

    switch (eventSubtype) {
      case 'onRouteTrafficEventsUpdated':
        if (_onRouteTrafficEventsUpdated != null) {
          _onRouteTrafficEventsUpdated!(arguments['delayDiff']);
        }

      case 'onTrafficEventsAlongRouteChecked':
        if (_onTrafficEventsAlongRouteChecked != null) {
          _onTrafficEventsAlongRouteChecked!();
        }

      case 'onRouteTrackTrimmed':
        if (_onRouteTrackTrimmed != null) {
          _onRouteTrackTrimmed!();
        }

      default:
        gemSdkLogger.log(
          Level.WARNING,
          'Unknown event subtype: $eventSubtype in RouteListener',
        );
    }
  }
}
