// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// A computed navigable route.
///
/// Represents a complete route result produced by the routing engine. A [Route] bundles geometry, metrics, metadata and
/// child objects (segments, instructions, traffic events, toll sections, etc.) used for rendering, analysis and navigation.
///
/// Routes are not instantiated directly — use [RoutingService.calculateRoute] to obtain route instances. Routes can be
/// displayed using a [MapViewRoutesCollection] from a [GemMapController] and used for turn-by-turn navigation with
/// [NavigationService].
///
/// ## See also:
///
/// - [RoutingService.calculateRoute] - Compute routes from [List<Landmark>]
/// - [MapViewRoutesCollection] - Display routes on the map.
/// - [NavigationService] - Navigate along the computed route.
/// - [AlarmService] - Get notified of route events.
///
/// {@category Route}
class Route extends RouteBase {
  // ignore: unused_element
  Route._();

  @internal
  Route.init(super.id) : super.init();

  /// Checks whether this route is equal to [route].
  ///
  /// Compares this route's internal representation with another [Route] instance.
  ///
  /// ## Parameters
  ///
  /// - [route]: The [Route] object to compare against.
  ///
  /// ## Returns
  ///
  /// - `true` if the two routes are equal, otherwise `false`.
  bool equals(final Route route) {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'Route',
      'equals',
      args: route.pointerId,
    );

    return resultString['result'];
  }

  /// Whether this route is designated for Electric Vehicles (EV).
  ///
  /// Returns `true` when the route contains EV-specific data or has been computed as an EV route.
  ///
  /// ## Returns
  ///
  /// - `true` if the route is an EV route, otherwise `false`.
  bool get isEVRoute {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'Route',
      'isEVRoute',
    );

    return resultString['result'];
  }

  /// Whether this route is an Over-Track (OT) route.
  ///
  /// Over-Track routes are based on a predefined path (for example, GPX-derived or user-drawn tracks) and may
  /// include limited or no routing segments/instructions depending on the source.
  ///
  /// ## Returns
  ///
  /// - `true` if the route is an OT route, otherwise `false`.
  ///
  /// ## Also see:
  ///
  /// - [toOTRoute] - Convert this route to an [OTRoute] when applicable.
  bool get isOTRoute {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'Route',
      'isOTRoute',
    );

    return resultString['result'];
  }

  /// Whether this route is a Public Transport (PT) route.
  ///
  /// PT routes contain segments and instructions specific to public transport (pedestrian legs, transit legs, tickets,
  /// frequency information, etc.).
  ///
  /// ## Returns
  ///
  /// - `true` if the route is a PT route, otherwise `false`.
  ///
  /// ## Also see:
  ///
  /// - [toPTRoute] - Convert this route to a [PTRoute] when applicable.
  bool get isPTRoute {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'Route',
      'isPTRoute',
    );

    return resultString['result'];
  }

  /// Extra metadata attached to the route.
  ///
  /// Returns a searchable list of custom parameters attached to this route instance. This can be used to persist
  /// auxiliary information produced by the routing engine or by the application.
  ///
  /// ## Returns
  ///
  /// - A [SearchableParameterList] containing the route's extra information.
  SearchableParameterList get extraInfo {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'Route',
      'getExtraInfo',
    );

    return SearchableParameterList.init(resultString['result']);
  }

  /// Sets extra metadata for this route.
  ///
  /// Associates a [SearchableParameterList] with this route for later retrieval via [extraInfo].
  ///
  /// ## Parameters
  ///
  /// - [value]: A [SearchableParameterList] containing extra information to attach to the route.
  set extraInfo(final SearchableParameterList value) {
    objectMethod(
      super.pointerId,
      'Route',
      'setExtraInfo',
      args: value.pointerId,
    );
  }

  /// Converts this route to an [OTRoute] when applicable.
  ///
  /// If this [Route] represents an over-track route, returns an [OTRoute] instance that exposes OT-specific APIs.
  /// Otherwise returns `null`.
  ///
  /// ## Returns
  ///
  /// - An [OTRoute] when this route is an OT route, or `null` if it is not.
  ///
  /// ## Also see:
  ///
  /// - [isOTRoute] - Check whether this route is an OT route.
  OTRoute? toOTRoute() {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'Route',
      'toOTRoute',
    );

    if (resultString['result'] == -1) {
      return null;
    }
    return OTRoute.init(resultString['result']);
  }

  /// Converts this route to a [PTRoute] when applicable.
  ///
  /// Returns a [PTRoute] exposing public-transport-specific functionality when this route is a PT route. Returns
  /// `null` otherwise.
  ///
  /// ## Returns
  ///
  /// - A [PTRoute] when this route is a public transport route, or `null` if it is not.
  ///
  /// ## Also see:
  ///
  /// - [isPTRoute] - Check whether this route is a PT route.
  PTRoute? toPTRoute() {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'Route',
      'toPTRoute',
    );

    if (resultString['result'] == -1) {
      return null;
    }
    return PTRoute.init(resultString['result']);
  }
}

/// A single portion of a computed route between two consecutive waypoints.
///
/// A [RouteSegment] exposes endpoints (waypoints), geometry, time/distance metrics, geographic bounds and a list of
/// [RouteInstruction] objects that describe the step-by-step guidance for that segment. Segments are produced by the
/// routing engine and should be obtained from a parent [Route] via [Route.segments].
///
/// Segments may include toll sections, flags and geographic metadata useful for rendering or measurement.
///
/// When a segment represents a public transport section, a segment is the portion of the route traveled using a specific
/// public transport vehicle or pedestrian. See the [toPTRouteSegment] method to convert to a [PTRouteSegment] providing
/// PT-specific properties.
///
/// When a segment represents other specialized transport modes, a segment is the portion of the route traveled between two
/// waypoints.
///
/// ## See also:
///
/// - [RouteBase.segments] - Get the segments of a route.
/// - [RouteInstruction] - A single route instruction inside a segment.
///
/// {@category Route}
class RouteSegment extends RouteSegmentBase {
  @internal
  RouteSegment.init(super.id) : super.init();

  /// Converts this segment into a [PTRouteSegment] when it represents a public-transport segment.
  ///
  /// Returns a [PTRouteSegment] exposing PT-specific properties when this segment can be interpreted as a public
  /// transport segment, otherwise returns `null`.
  ///
  /// ## Returns
  ///
  /// - A [PTRouteSegment] if conversion is possible, or `null`.
  PTRouteSegment? toPTRouteSegment() {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'RouteSegment',
      'toPTRouteSegment',
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return PTRouteSegment(resultString['result']);
  }
}

/// A single route step inside a route segment.
///
/// [RouteInstruction] models one maneuver or guidance step (for example: turn, exit, follow road). It contains localized text,
/// optional signpost information, turn images, realistic intersection imagery, and time/distance metrics (remaining and traveled).
/// Instances are produced by the routing engine and obtained from [RouteSegment.instructions].
///
/// Use route instructions to build UI lists, previews or to center a map on specific steps. For real-time turn-by-turn
/// navigation see [NavigationInstruction], which is produced when navigation is active.
///
/// ## See also:
///
/// - [RouteSegment.instructions] - Get the instructions of a route segment.
/// - [NavigationInstruction] - Get real-time navigation steps.
///
/// {@category Route}
class RouteInstruction extends RouteInstructionBase {
  @internal
  RouteInstruction.init(super.id) : super.init();

  /// Convert to a [PTRouteInstruction] from this one.
  ///
  /// ## Returns
  ///
  /// - [PTRouteInstruction] when conversion is possible, or `null`.
  PTRouteInstruction? toPTRouteInstruction() {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'RouteInstruction',
      'toPTRouteInstruction',
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return PTRouteInstruction.init(resultString['result']);
  }
}
