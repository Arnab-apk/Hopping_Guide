// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:typed_data';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/routing.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/routing/toll_section.dart';
import 'package:meta/meta.dart';

/// [RouteBase] defines the common API surface for computed routes. It exposes geometry, time/distance metrics,
/// terrain profiles, segments, instructions, traffic and toll information, and helpers to export or sample route data.
///
/// This class is abstract and should not be instantiated directly. Use [RoutingService.calculateRoute] to obtain
/// concrete route instances of type [Route].
///
/// ## See also:
///
/// - [RoutingService.calculateRoute] - compute routes.
/// - [Route] - concrete route implementation.
/// - [RouteSegment] - route segments returned by [segments].
///
/// {@category Route}
abstract class RouteBase extends GemAutoreleaseObject {
  // ignore: unused_element
  RouteBase() : super(-1);

  @internal
  RouteBase.init(super.id);

  /// Export route data in a standard file format.
  ///
  /// Serializes route data into the requested [format] (for example GPX or KML) and returns the resulting
  /// file contents as a UTF-8 string.
  ///
  /// ## Parameters
  ///
  /// - [format]: The [PathFileFormat] describing the desired export format.
  ///
  /// ## Returns
  ///
  /// - A `String` containing the exported route data in the requested format.
  String exportAs(final PathFileFormat format) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'exportAs',
      args: format.index,
    );

    final String encodedResult = resultString['result'];
    final Uint8List resultAsUint8List = base64Decode(encodedResult);
    final String result = utf8.decode(resultAsUint8List);

    return result;
  }

  /// Find the index of the route segment nearest to [coord].
  ///
  /// Performs a proximity query against the route's segments and returns the zero-based index of the closest segment.
  ///
  /// ## Parameters
  ///
  /// - [coord]: The coordinates to test against the route geometry.
  ///
  /// ## Returns
  ///
  /// - The index of the closest route segment, or [GemError.general].code (`-1`) on error.
  int getClosestSegment(final Coordinates coord) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getClosestSegment',
      args: coord,
    );

    return resultString['result'];
  }

  /// Returns the coordinate located at [distance] metres from the route start.
  ///
  /// The returned [Coordinates] correspond to the point on the route track that lies at the specified distance
  /// measured from the departure point.
  ///
  /// ## Parameters
  ///
  /// - [distance]: Distance from the route start in meters.
  ///
  /// ## Returns
  ///
  /// - A [Coordinates] instance at the requested distance along the route if the distance is valid; otherwise returns a
  /// [Coordinates] instance with [Coordinates.isValid] equal to `false`.
  Coordinates getCoordinateOnRoute(final int distance) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getCoordinateOnRoute',
      args: distance,
    );

    return Coordinates.fromJson(resultString['result']);
  }

  /// Returns the route distance (meters) from departure at the given [coords].
  ///
  /// Measures the distance along the route from the departure point to the point closest to [coords].
  ///
  /// ## Parameters
  ///
  /// - [coords]: The geographic coordinates where the distance should be measured.
  /// - [activePart]: If `true`, consider only the active portion of the route; otherwise consider the whole route.
  ///
  /// ## Returns
  ///
  /// - An `int` representing the distance in meters from route start to the point closest to [coords].
  ///   Returns [GemError.general].code (`-1`) on error.
  int getDistanceOnRoute(final Coordinates coords, final bool activePart) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getDistanceOnRoute',
      args: <String, Object>{'coords': coords, 'activePart': activePart},
    );

    return resultString['result'];
  }

  /// Dominant road names along the route.
  ///
  /// A road is considered dominant when it covers a significant portion of the route length.
  ///
  /// ## Returns
  ///
  /// - `List<String>`: a list of dominant road names. If a road has multiple names they will be joined as
  ///   `'name1 / name2 / ...'.`
  List<String> get dominantRoads {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getDominantRoads',
    );

    return (resultString['result'] as List<dynamic>)
        .map((final dynamic e) => e as String)
        .toList();
  }

  /// The geographic bounding rectangle that encloses the route.
  ///
  /// The geographic area is the smallest axis-aligned rectangle that encloses the entire route geometry.
  ///
  /// ## Returns
  ///
  /// - A [RectangleGeographicArea] representing the bounding rectangle of the route.
  RectangleGeographicArea get geographicArea {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getGeographicArea',
    );

    return RectangleGeographicArea.fromJson(resultString['result']);
  }

  /// Whether traveling this route may incur monetary costs (for example tolls).
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when the route or segment includes paid sections, otherwise `false`.
  bool get incursCosts {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getIncursCosts',
    );

    return resultString['result'];
  }

  /// Build a [Path] covering the route between [start] and [end] distances.
  ///
  /// Creates a [Path] object representing the portion of the route between the two distances (in meters) measured
  /// from the route start. Returns `null` if the requested interval cannot be represented.
  ///
  /// ## Parameters
  ///
  /// - [start]: Start distance from route start in meters.
  /// - [end]: End distance from route start in meters.
  ///
  /// ## Returns
  ///
  /// - A [Path] for the requested interval, or `null` if unavailable.
  Path? getPath(final int start, final int end) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getPath',
      args: <String, int>{'start': start, 'end': end},
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return Path.init(resultString['result']);
  }

  /// Polygonal geographic area covering the route.
  ///
  /// ## Returns
  ///
  /// - A [PolygonGeographicArea] containing the polygon points that describe the route area.
  PolygonGeographicArea get polygonGeographicArea {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getPolygonGeographicArea',
    );

    final List<Coordinates> listJson = (resultString['result'] as List<dynamic>)
        .map(
          (final dynamic item) =>
              Coordinates.fromJson(item as Map<String, dynamic>),
        )
        .toList();
    return PolygonGeographicArea(coordinates: listJson);
  }

  /// Preferences used when the route was calculated.
  ///
  /// Modifying the returned [RoutePreferences] instance will have no effect on the existing route.
  /// Use the [RoutingService.calculateRoute] method with modified preferences to compute a new route.
  ///
  /// ## Returns
  ///
  /// - A [RoutePreferences] instance containing the preferences applied to this route calculation.
  RoutePreferences get preferences {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getPreferences',
    );

    return RoutePreferences.init(resultString['result']);
  }

  /// List of segments that make up the route.
  ///
  /// ## Returns
  ///
  /// - `List<RouteSegment>`: each element represents a contiguous segment between two waypoints.
  List<RouteSegment> get segments {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getSegments',
    );

    return RouteSegmentList.init(resultString['result']).toList();
  }

  /// Current status of the route calculation.
  ///
  /// ## Returns
  ///
  /// - A [RouteStatus] describing whether the route is ready, calculating, in error, etc.
  RouteStatus get status {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getStatus',
    );

    return RouteStatusExtension.fromId(resultString['result']);
  }

  /// Short textual summary of the route.
  ///
  /// The summary typically contains key metrics such as total distance and estimated duration.
  /// Is influenced by the current SDK language setting.
  ///
  /// ## Returns
  ///
  /// - `String`: a human-readable route summary.
  String get summary {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getSummary',
    );

    return resultString['result'];
  }

  /// Route terrain elevation profile, if available.
  ///
  /// Returns a [RouteTerrainProfile] describing elevation changes along the route. The terrain profile is only
  /// available when [RoutePreferences.buildTerrainProfile].enable was set to `true` when the route was calculated.
  ///
  /// ## Returns
  ///
  /// - A [RouteTerrainProfile] when available, otherwise `null`.
  RouteTerrainProfile? get terrainProfile {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getTerrainProfile',
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return RouteTerrainProfile.init(resultString['result']);
  }

  /// Returns time and distance metrics for the route or a segment.
  ///
  /// When called on a route, returns aggregated metrics (total distance and estimated travel time). When called on
  /// a segment (via the corresponding API), the segment's metrics are returned.
  ///
  /// ## Parameters
  ///
  /// - [activePart]: If `true`, consider only the active portion of the route; otherwise return metrics for the
  ///   entire route. Defaults to `true`.
  ///
  /// ## Returns
  ///
  /// - A [TimeDistance] object containing distance (meters) and time (seconds) information.
  TimeDistance getTimeDistance({final bool activePart = true}) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getTimeDistance',
      args: activePart,
    );

    return TimeDistance.fromJson(resultString['result']);
  }

  /// Build a timestamped list of coordinates sampled along the route.
  ///
  /// Samples coordinates at regular intervals between [start] and [end]. The sampling interval is determined by
  /// [step] and [stepType] (distance or time).
  ///
  /// ## Parameters
  ///
  /// - [start]: Start distance from route start in meters.
  /// - [end]: End distance from route start in meters.
  /// - [step]: Step size (units determined by [stepType]).
  /// - [stepType]: Unit used for [step] — see [StepType].
  ///
  /// ## Returns
  ///
  /// - A `List<TimeDistanceCoordinate>` containing sampled coordinates with associated time/distance metadata.
  List<TimeDistanceCoordinate> getTimeDistanceCoordinates({
    required final int start,
    required final int end,
    required final int step,
    required final StepType stepType,
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getTimeDistanceCoordinates',
      args: <String, Object>{
        'start': start,
        'end': end,
        'step': step,
        'stepType': stepType == StepType.distance,
      },
    );

    final List<dynamic> timeDistanceJson = resultString['result'];

    return timeDistanceJson
        .map((final dynamic e) => TimeDistanceCoordinate.fromJson(e))
        .toList();
  }

  /// Find the time-distance coordinate nearest to a reference [coordinates].
  ///
  /// Returns a [TimeDistanceCoordinate] describing the closest sampled point on the route to the provided
  /// reference coordinates. Useful for snapping user locations to the route or for measurements.
  ///
  /// ## Parameters
  ///
  /// - [coordinates]: The reference coordinate to find the nearest route sample to.
  ///
  /// ## Returns
  ///
  /// - A [TimeDistanceCoordinate] for the nearest point on the route.
  TimeDistanceCoordinate getTimeDistanceCoordinateOnRoute(
    final Coordinates coordinates,
  ) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getTimeDistanceCoordinateOnRoute',
      args: coordinates.toJson(),
    );

    final Map<String, dynamic> timeDistanceJson =
        resultString['result'] as Map<String, dynamic>;

    return TimeDistanceCoordinate.fromJson(timeDistanceJson);
  }

  /// Traffic events that affect this route (delays, closures, etc.).
  ///
  /// ## Returns
  ///
  /// - `List<RouteTrafficEvent>`: a list of traffic events impacting the route.
  List<RouteTrafficEvent> get trafficEvents {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getTrafficEventsOptimized',
    );

    return (resultString['result'] as List<dynamic>)
        .map((final dynamic e) => RouteTrafficEvent.init(e))
        .toList();
  }

  /// Retrieve the route's waypoints.
  ///
  /// Waypoints are returned in order: departure, intermediate waypoints, destination. When a route is being
  /// navigated the returned waypoints may be the remaining ones to visit.
  ///
  /// ## Parameters
  ///
  /// - [options]: Controls which waypoint set to return — see [GetWaypointsOptions]. Defaults to
  ///   [GetWaypointsOptions.remainingInitial].
  ///
  /// ## Returns
  ///
  /// - A `List<Landmark>` containing the route waypoints.
  List<Landmark> getWaypoints({
    final GetWaypointsOptions options = GetWaypointsOptions.remainingInitial,
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getWaypoints',
      args: options.id,
    );

    return LandmarkList.init(resultString['result']).toList();
  }

  /// Produce a new waypoint list inserting [landmark] into the remaining route waypoints.
  ///
  /// ## Parameters
  ///
  /// - [landmark]: The via waypoint to insert into the remaining route waypoints.
  ///
  /// ## Returns
  ///
  /// - `List<Landmark>`: a new list of waypoints including the inserted via waypoint placed in the correct position.
  ///   When the route is being navigated the returned list contains the remaining waypoints.
  List<Landmark> getWaypointsVia(final Landmark landmark) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getWaypointsVia',
      args: <String, dynamic>{'landmark': landmark.pointerId},
    );

    return LandmarkList.init(resultString['result']).toList();
  }

  /// Whether the route includes ferry connections.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when one or more ferry connections are part of the route.
  bool get hasFerryConnections {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'hasFerryConnections',
    );

    return resultString['result'];
  }

  /// Whether the route contains toll roads.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when the route includes toll-road segments.
  bool get hasTollRoads {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'hasTollRoads',
    );

    return resultString['result'];
  }

  /// Geographic area of the route represented as a tiles collection.
  ///
  /// ## Returns
  ///
  /// - [TilesCollectionGeographicArea] describing the tile coverage for the route.
  TilesCollectionGeographicArea get tilesGeographicArea {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getTilesGeographicArea',
    );

    return TilesCollectionGeographicArea.init(resultString['result']);
  }

  /// Attach a [RouteListener] to receive route-related events.
  ///
  /// ## Parameters
  ///
  /// - [routeListener]: Listener to receive events for this route. Pass `null` to remove the listener.
  set routeListener(final RouteListener? routeListener) {
    objectMethod(
      pointerId,
      'RouteBase',
      'setRouteListener',
      args: routeListener == null ? 0 : routeListener.id,
    );

    if (routeListener != null) {
      GemKitPlatform.instance.registerEventHandler(
        routeListener.id,
        routeListener,
      );
    }
  }

  /// Remove any previously attached [RouteListener].
  ///
  /// After calling this method no route-related events will be delivered for this route.
  void clearRouteListener() {
    objectMethod(pointerId, 'RouteBase', 'clearRouteListener');
  }

  /// Returns the currently attached [RouteListener], if any.
  ///
  /// ## Returns
  ///
  /// - The [RouteListener] attached to this route, or `null` when no listener is set.
  RouteListener? get routeListener {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getRouteListener',
    );

    if (resultString['result'] == -1) {
      return null;
    }

    final EventHandler? foundHandler = GemKitPlatform.instance.getEventHandler(
      resultString['result'],
    );
    if (foundHandler == null || foundHandler is! RouteListener) {
      return null;
    }

    return foundHandler;
  }

  /// A list of tolled sections that occur along the route.
  ///
  /// Each [TollSection] describes the start/end distances (in metres from route start), the cost and the currency (if available).
  ///
  /// ## Returns
  ///
  /// - A `List<TollSection>` containing toll sections; when no tolls are present the list will be empty.
  List<TollSection> get tollSections {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getTollSections',
    );

    final List<dynamic> tollSectionsJson = resultString['result'];

    return tollSectionsJson
        .map((final dynamic e) => TollSection.fromJson(e))
        .toList();
  }

  /// A list of restricted sections that occur along the route.
  ///
  /// Each [RestrictionSection] describes the start/end distances (in metres
  /// from route start) and a bitmask of [RouteRestrictionType] values
  /// describing the applicable restrictions (for example access restricted,
  /// transport mode restricted, vehicle attribute over limit, etc.).
  ///
  /// ## Returns
  ///
  /// - A `List<RestrictionSection>` containing restriction sections; empty
  ///   when the route has no restrictions.
  ///
  /// ## See also:
  ///
  /// - [RouteRestrictionType] - The kinds of restrictions that can apply.
  /// - [RouteSegmentBase.restrictionSections] - Restriction sections per segment.
  List<RestrictionSection> get restrictionSections {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBase',
      'getRestrictionSections',
    );

    final List<dynamic> restrictionSectionsJson = resultString['result'];

    return restrictionSectionsJson
        .map((final dynamic e) => RestrictionSection.fromJson(e))
        .toList();
  }
}

/// Routing service status values describing route computation state.
///
/// Use [RouteStatus] to inspect whether a route calculation is pending, successful, or failed.
///
/// {@category Route}
enum RouteStatus {
  /// The routing service has not been initialized.
  uninitialized,

  /// A route calculation is in progress.
  calculating,

  /// Waiting for internet connection to complete routing.
  waitingInternetConnection,

  /// Route calculation finished successfully and result is available.
  ready,

  /// An error occurred during route calculation.
  error,
}

/// @nodoc
extension RouteStatusExtension on RouteStatus {
  int get id {
    switch (this) {
      case RouteStatus.uninitialized:
        return 0;
      case RouteStatus.calculating:
        return 1;
      case RouteStatus.waitingInternetConnection:
        return 2;
      case RouteStatus.ready:
        return 3;
      case RouteStatus.error:
        return 4;
    }
  }

  static RouteStatus fromId(final int id) {
    switch (id) {
      case 0:
        return RouteStatus.uninitialized;
      case 1:
        return RouteStatus.calculating;
      case 2:
        return RouteStatus.waitingInternetConnection;
      case 3:
        return RouteStatus.ready;
      case 4:
        return RouteStatus.error;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Unit used for sampling steps in time-distance coordinate generation.
///
/// {@category Route}
enum StepType {
  /// Step measured in distance (meters).
  distance,

  /// Step measured in time (seconds).
  time,
}

/// Options selecting which set of waypoints to return from [RouteBase.getWaypoints].
///
/// {@category Route}
enum GetWaypointsOptions {
  /// The initial waypoint set produced by the route calculation.
  initial,

  /// Remaining waypoints derived from the initial calculation. When navigating a route intermediate waypoints
  /// that have been passed are removed.
  remainingInitial,

  /// Remaining waypoints including user and service added entries (used by special routing modes such as EV).
  remaining,
}

/// @nodoc
extension GetWaypointsOptionsExtension on GetWaypointsOptions {
  int get id {
    switch (this) {
      case GetWaypointsOptions.initial:
        return 0;
      case GetWaypointsOptions.remainingInitial:
        return 1;
      case GetWaypointsOptions.remaining:
        return 2;
    }
  }

  static GetWaypointsOptions fromId(final int id) {
    switch (id) {
      case 0:
        return GetWaypointsOptions.initial;
      case 1:
        return GetWaypointsOptions.remainingInitial;
      case 2:
        return GetWaypointsOptions.remaining;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
