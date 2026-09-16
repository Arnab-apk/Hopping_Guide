// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Represents a traffic event affecting a computed [Route].
///
/// Encapsulates information about a specific traffic condition or incident (for
/// example, congestion, roadworks, or closures) that impacts a route.
///
/// Requires that the route was computed with traffic data enabled. Use the
/// [RouteBase.trafficEvents] getter to obtain the list of events for a given
/// route.
///
/// ## See also:
///
/// - [TrafficEvent] - Base class for traffic events.
/// - [RouteBase.trafficEvents] - Getter that returns the traffic events for a route.
///
/// {@category Traffic & Roadblocks}
class RouteTrafficEvent extends TrafficEvent {
  // ignore: unused_element
  RouteTrafficEvent._();

  @internal
  RouteTrafficEvent.init(super.id) : super.init();

  /// Distance (in meters) from the event position on the current route to the destination.
  ///
  /// This value is route-specific and therefore only available for events
  /// that are part of a computed [Route].
  ///
  /// When no route context is available the SDK returns `0`.
  ///
  /// ## Returns
  ///
  /// - [int]: distance in meters to destination, or `0` when unavailable.
  int get distanceToDestination {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTrafficEvent',
      'getDistanceToDestination',
    );

    return resultString['result'];
  }

  /// Start coordinate of the traffic event on the route.
  ///
  /// ## Returns
  ///
  /// - [Coordinates]: the route-relative start coordinate for this event.
  ///
  /// ## Also see:
  ///
  /// - [to] — end coordinate of the traffic event on the route.
  Coordinates get from {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTrafficEvent',
      'getFrom',
    );

    return Coordinates.fromJson(resultString['result']);
  }

  /// End coordinate of the traffic event on the route.
  ///
  /// ## Returns
  ///
  /// - [Coordinates]: the route-relative end coordinate for this event.
  ///
  /// ## Also see:
  ///
  /// - [from] — start coordinate of the traffic event on the route.
  Coordinates get to {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTrafficEvent',
      'getTo',
    );

    return Coordinates.fromJson(resultString['result']);
  }

  /// Start point represented as a [Landmark] and a cached-data flag.
  ///
  /// The tuple contains:
  /// - `[Landmark]`: the landmark representing the start point (may be
  ///   partially populated if no local cache exists).
  /// - `[bool]`: `true` when the landmark has local cached data (description
  ///   and address), `false` when details must be fetched from the server.
  ///
  /// Use the [asyncUpdateToFromData] method to fetch full details
  /// from the server when needed. Is required for this method to work.
  ///
  /// ## Returns
  ///
  /// - `(Landmark, bool)` representing the start point as a landmark and a cached-data flag.
  ///
  /// ## Also see:
  ///
  /// - [asyncUpdateToFromData] — Fetch full landmark details from server.
  /// - [toLandmark] — End landmark of the traffic event on the route.
  /// - [from] - Start coordinate of the traffic event on the route.
  (Landmark, bool) get fromLandmark {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTrafficEvent',
      'getFromLandmark',
    );

    return (
      Landmark.init(resultString['result']['first']),
      resultString['result']['second'],
    );
  }

  /// End point represented as a [Landmark] and a cached-data flag.
  ///
  /// The tuple contains:
  /// - `[Landmark]`: the landmark representing the end point (may be
  ///   partially populated if no local cache exists).
  /// - `[bool]`: `true` when the landmark has local cached data (description
  ///   and address), `false` when details must be fetched from the server.
  ///
  /// Use the [asyncUpdateToFromData] method to fetch full details
  /// from the server when needed. Is required for this method to work.
  ///
  /// ## Returns
  ///
  /// - `(Landmark, bool)`: `(landmark, hasLocalData)`.
  ///
  /// ## See also:
  ///
  /// - [asyncUpdateToFromData] — Fetch full landmark details from server.
  /// - [fromLandmark] — Start landmark of the traffic event on the route.
  /// - [to] - End coordinate of the traffic event on the route.
  (Landmark, bool) get toLandmark {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTrafficEvent',
      'getToLandmark',
    );

    return (
      Landmark.init(resultString['result']['first']),
      resultString['result']['second'],
    );
  }

  /// Asynchronously fetch and update full [fromLandmark] and [toLandmark] details from the server.
  ///
  /// When a landmark returned by [fromLandmark]/[toLandmark] does not contain
  /// detailed address or description information, call this method to fetch
  /// the missing data.
  ///
  /// The provided [onComplete] callback receives a
  /// [GemError] indicating success or the failure reason.
  ///
  /// ## Parameters
  ///
  /// - [onComplete]: callback invoked with a [GemError] when the operation
  ///   finishes. Typical values:
  ///   - [GemError.success] — data updated successfully.
  ///   - [GemError.invalidInput] — operation not available for this event
  ///     or an update already completed.
  ///   - [GemError.inUse] — an update is already in progress.
  ///   - Other [GemError] values — various failure modes.
  ///
  /// ## Example
  ///
  /// ```dart
  /// routeEvent.asyncUpdateToFromData((GemError err) {
  ///   if (err == GemError.success) {
  ///     final (Landmark updatedStart, bool cacheStart) =
  ///         routeEvent.fromLandmark;
  ///     final (Landmark updatedEnd, bool cacheEnd) = routeEvent.toLandmark;
  ///     print('Updated start landmark: $updatedStart');
  ///   } else {
  ///     print('Failed to update landmarks: $err');
  ///   }
  /// });
  /// ```
  ///
  /// ## See also:
  ///
  /// - [fromLandmark] — Start landmark of the traffic event on the route.
  /// - [toLandmark] — End landmark of the traffic event on the route.
  /// - [cancelUpdate] — Cancel a pending update request.
  void asyncUpdateToFromData(final void Function(GemError err) onComplete) {
    final EventDrivenProgressListener listener = EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    listener.registerOnCompleteWithData((final int err, final _, final _) {
      onComplete(GemErrorExtension.fromCode(err));
    });

    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTrafficEvent',
      'asyncUpdateToFromData',
      args: listener.id,
    );

    final int error = resultString['gemApiError'];
    if (error != 0) {
      onComplete(GemErrorExtension.fromCode(error));
    }
  }

  /// Cancel a pending [asyncUpdateToFromData] request.
  ///
  /// This cancels the in-flight network request associated with the
  /// asynchronous landmark update.
  ///
  /// ## See also:
  ///
  /// - [asyncUpdateToFromData] — Fetch full landmark details from server.
  void cancelUpdate() {
    objectMethod(pointerId, 'RouteTrafficEvent', 'cancelUpdate');
  }
}
