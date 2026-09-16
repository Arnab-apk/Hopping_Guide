// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:ui' show Color;

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';
import 'package:magiclane_maps_flutter/src/ptstopinfo/pt_crowding_info.dart';
import 'package:meta/meta.dart';

/// Public-facing route information for a stop.
///
/// Contains rider-visible route metadata such as short/long names, route
/// type and color hints. Use this when presenting routes associated with a
/// stop in UI or lists.
///
/// Instances are provided as part of [PTStop.routes] or [PTTrip.route].
///
/// ## Also see:
///
/// - [PTStop.routes] — The routes serving a specific stop.
/// - [PTTrip.route] — The route associated with a specific trip.
/// - [PTRoute] - Route computed between two locations. Do not confuse with this class which
/// provides metadata about public transport routes associated with stops.
///
/// {@category Maps & 3D Scenes}
class PTRouteInfo {
  /// Create a [PTRouteInfo].
  ///
  /// API users do not typically create instances of this class directly.
  ///
  /// ## Parameters
  ///
  /// - [routeId]: (int) Internal route identifier.
  /// - [routeShortName]: (String?) Short route identifier (e.g., "32").
  /// - [routeLongName]: (String?) More descriptive route name.
  /// - [routeType]: (PTRouteType) The route type.
  /// - [routeColor]: (Color?) Optional color associated with the route.
  /// - [routeTextColor]: (Color?) Optional text color to display on route background.
  /// - [heading]: (String?) Optional heading/destination for the route.
  /// - [liveCrowding]: (PTCrowdingInfo?) Optional live crowding summary for the route.
  PTRouteInfo({
    required this.routeId,
    this.routeShortName,
    this.routeLongName,
    required this.routeType,
    this.routeColor,
    this.routeTextColor,
    this.heading,
    this.liveCrowding,
  });

  @internal
  factory PTRouteInfo.build(List<GemParameter> params) {
    final Map<String, dynamic> map = <String, dynamic>{};

    for (final GemParameter el in params) {
      if (el.key == 'live_crowding') {
        map[el.key!] = PTCrowdingInfo.build(el.value.toList());
      } else {
        map[el.key!] = el.value;
      }
    }

    return PTRouteInfo(
      routeId: map['route_id'] as int,
      routeShortName: map['route_short_name'] as String?,
      routeLongName: map['route_long_name'] as String?,
      routeType: map['route_type'] != null
          ? PTRouteTypeExtension.fromId(map['route_type'] as int)
          : PTRouteType.misc,
      routeColor: _parseColor(map['route_color']),
      routeTextColor: _parseColor(map['route_text_color']),
      heading: map['route_heading'] as String?,
      liveCrowding: map['live_crowding'] as PTCrowdingInfo?,
    );
  }

  /// Internal route identifier.
  final int routeId;

  /// Short route identifier (may be null).
  final String? routeShortName;

  /// Descriptive route name (may be null).
  final String? routeLongName;

  /// Route type.
  final PTRouteType routeType;

  /// Optional color associated with the route.
  final Color? routeColor;

  /// Optional text color suitable for use on top of [routeColor].
  final Color? routeTextColor;

  /// Optional heading or destination string.
  final String? heading;

  /// Live crowding summary for the route (may be null).
  ///
  /// Summarizes all the route's fresh vehicle positions — useful when
  /// vehicles can't be matched to specific departures.
  /// [PTCrowdingInfo.vehicles] counts them; the other fields carry the
  /// WORST value over those vehicles, each null when no vehicle supplies
  /// it. Null when the route has no fresh vehicle positions.
  final PTCrowdingInfo? liveCrowding;

  /// Builds a list of [PTRouteInfo] from a list of [GemParameter].
  ///
  /// API users should not call this method directly.
  @internal
  static List<PTRouteInfo> buildStopRoutes(List<GemParameter> params) {
    final List<PTRouteInfo> routes = <PTRouteInfo>[];

    for (final GemParameter el in params) {
      routes.add(PTRouteInfo.build(el.value.toList()));
    }

    return routes;
  }

  // Helper method to parse color from hex string (e.g., "#fa6544")
  static Color? _parseColor(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return null;
    }

    // Remove the leading '#' if it exists
    colorString = colorString.startsWith('#')
        ? colorString.substring(1)
        : colorString;
    try {
      return Color(
        int.parse('0xFF$colorString'),
      ); // Add '0xFF' for full opacity
    } catch (e) {
      gemSdkLogger.warning(
        '[PTRoute][_build] Parsing color $colorString failed. Returning null.',
      );
      return null;
    }
  }
}

/// Enumeration of public transport route types.
///
/// Mirrors common route categories (bus, tram, rail, etc.) used in GTFS-like
/// data models.
///
/// ## Also see:
///
/// - [PTRouteInfo.routeType] — The route type for a specific route.
/// - [PTTrip.route] — The route associated with a specific trip.
/// - [PTStopInfo.tripsByRouteType] — Filter trips by route type.
/// - [RoutePreferences] - Preferences for navigable routes
///
/// {@category Maps & 3D Scenes}
enum PTRouteType {
  /// Bus or trolleybus routes.
  bus,

  /// Underground / metro routes.
  underground,

  /// Railway / intercity rail.
  railway,

  /// Tram / streetcar / light rail.
  tram,

  /// Waterborne transport such as ferries.
  waterTransport,

  /// Miscellaneous or unknown route types.
  misc,
}

/// @nodoc
extension PTRouteTypeExtension on PTRouteType {
  /// Returns the integer id for the [PTRouteType].
  int get id => index;

  static PTRouteType fromId(int value) {
    if (value < 0 || value >= PTRouteType.values.length) {
      throw ArgumentError('Invalid id');
    }
    return PTRouteType.values[value];
  }
}
