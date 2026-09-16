// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Over-track (OT) route representation.
///
/// Provides access to a route that is backed by a detailed track ([Path]) rather
/// than only a set of turn-by-turn segments. An [OTRoute] exposes route-level
/// properties and helpers built on top of [RouteBase], and specifically
/// provides access to the underlying track as a [Path] when available.
///
/// This class is primarily returned by converting a generic [Route] to an
/// [OTRoute] using [Route.toOTRoute].
///
/// ## Example
///
///```dart
/// // Covert the Path to a list of Landmarks that can be used for routing.
/// List<Landmark> landmarkList = path.toLandmarkList();
///
/// // Define the route preferences.
/// final routePreferences = RoutePreferences();
///
/// RoutingService.calculateRoute(landmarkList, routePreferences,
///     (err, routes) {
///   if (err == GemError.success) {
///     Route route = routes.first;
///     OTRoute? otRoute = route.toOTRoute();
///   } else {
///     showSnackbar("Error calculating route: $err");
///   }
/// });
/// ```
///
/// ## See also:
///
/// - [Route] - The generic route type that can be converted to an [OTRoute].
/// - [Path] - Represents the geometric track exposed by an [OTRoute].
/// - [Route.toOTRoute] - Convert a [Route] instance to an [OTRoute].
///
/// {@category Route}
class OTRoute extends RouteBase {
  @internal
  OTRoute.init(super.id) : super.init();

  /// The path representing the detailed track of this route, if available.
  ///
  /// Returns the [Path] object that contains the ordered list of coordinates
  /// which make up the route's track.
  ///
  /// ## Returns
  ///
  /// - The [Path] representing the track of this route when available.
  /// - `null` when the track is unavailable or the underlying platform call
  ///   indicates an error (native result == -1).
  Path? get track {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OTRoute',
      'getTrack',
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return Path.init(resultString['result']);
  }
}
