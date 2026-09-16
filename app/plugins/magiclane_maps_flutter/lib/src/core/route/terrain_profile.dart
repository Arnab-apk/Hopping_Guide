// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Terrain information for a calculated route.
///
/// This object provides elevation and surface data for a route. Do not
/// instantiate directly — obtain it from [RouteBase.terrainProfile] after
/// calling [RoutingService.calculateRoute] with [RoutePreferences.buildTerrainProfile]
/// enabled.
///
/// Important: set `RoutePreferences(buildTerrainProfile: BuildTerrainProfile(enable: true))`
/// before calling `calculateRoute` to receive a non-null terrain profile.
///
/// ## Example
///
/// ```dart
/// RoutingService.calculateRoute(
///   landmarks,
///   RoutePreferences(
///     buildTerrainProfile: const BuildTerrainProfile(
///       enable: true,
///     ),
///   ),
///   (err, routes) {
///     if (err == GemError.success) {
///       final route = routes.first;
///       final RouteTerrainProfile? profile = route.terrainProfile;
///       if (profile != null) {
///         final elevation = profile.getElevation(100);
///       }
///     } else {
///       print('Error calculating route: $err');
///     }
///   },
/// );
/// ```
///
/// ## See also:
///
/// - [RouteBase.terrainProfile] - Get the terrain profile for a route
/// - [RoutingService.calculateRoute] - Calculate routes with terrain profiles
/// - [RoutePreferences.buildTerrainProfile] - Enable terrain profiles when calculating routes
///
/// {@category Route}
class RouteTerrainProfile extends GemAutoreleaseObject {
  // ignore: unused_element
  RouteTerrainProfile._() : super(-1);

  @internal
  RouteTerrainProfile.init(super.id);

  /// List of climb sections present in the route.
  ///
  /// Climb sections identify route segments with non-trivial ascent. Each
  /// section includes start/end distances and a [Grade] classification.
  ///
  /// ## Returns
  ///
  /// - A list of [ClimbSection]. Empty when the route contains no
  ///   significant climbs.
  List<ClimbSection> get climbSections {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getClimbSections',
    );

    final List<dynamic> listJson = resultString['result'];
    final List<ClimbSection> retList = listJson
        .map(
          (final dynamic categoryJson) => ClimbSection.fromJson(categoryJson),
        )
        .toList();
    return retList;
  }

  /// Elevation (meters) at [distance] meters from the route start.
  ///
  /// ## Parameters
  ///
  /// - [distance]: Distance in meters from the route start.
  ///
  /// ## Returns
  ///
  /// - Elevation in meters at the requested location.
  double getElevation(final int distance) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getElevation',
      args: distance,
    );

    return resultString['result'];
  }

  /// Sampled elevation values for a route interval.
  ///
  /// Returns a tuple of `(samples, resolution)` where `samples` is a list of
  /// elevation values (meters) and `resolution` is the sample spacing in
  /// meters. If parameters are invalid an empty list and `0.0` are returned.
  ///
  /// ## Parameters
  ///
  /// - [countSamples]: Number of samples to collect.
  /// - [distBegin]: Begin distance (meters) along the route.
  /// - [distEnd]: End distance (meters) along the route.
  ///
  /// ## Returns
  ///
  /// - Tuple `(List<double>, double)` representing the list of samples and the sample resolution.
  (List<double>, double) getElevationSamples(
    final int countSamples,
    final int distBegin,
    final int distEnd,
  ) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getElevationSamplesBE',
      args: <String, int>{
        'countSamples': countSamples,
        'distBegin': distBegin,
        'distEnd': distEnd,
      },
    );

    final List<dynamic> listDynamic = resultString['result']['floatlist'];
    final List<double> listFloat = listDynamic.cast<double>();
    final double sample = resultString['result']['sample'];

    return (listFloat, sample);
  }

  /// Sample elevation values for the entire route using [countSamples].
  ///
  /// ## Parameters
  ///
  /// - [countSamples]: Number of samples to collect across the whole route.
  ///
  /// ## Returns
  ///
  /// - Tuple `(List<double>, double)` representing the list of samples and the sample resolution.
  (List<double>, double) getElevationSamplesByCount(final int countSamples) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getElevationSamples',
      args: countSamples,
    );

    final List<dynamic> listDynamic = resultString['result']['floatlist'];
    final List<double> listFloat = listDynamic.cast<double>();
    final double sample = resultString['result']['sample'];

    return (listFloat, sample);
  }

  /// Maximum elevation (meters) along the route.
  ///
  /// ## Returns
  ///
  /// - The maximum elevation in meters.
  ///
  /// ## Also see:
  ///
  /// - [maxElevationDistance] - Distance where maximum elevation occurs
  /// - [minElevation] - Minimum elevation along the route
  double get maxElevation {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getMaxElevation',
    );

    return resultString['result'];
  }

  /// Distance from route start where the route reaches maximum elevation.
  ///
  /// ## Returns
  ///
  /// - Distance in meters from the route start.
  ///
  /// ## Also see:
  ///
  /// - [maxElevation] - Maximum elevation along the route
  /// - [minElevationDistance] - The distance where minimum elevation occurs
  int get maxElevationDistance {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getMaxElevationDistance',
    );

    return resultString['result'];
  }

  /// Minimum elevation (meters) along the route.
  ///
  /// ## Returns
  ///
  /// - The minimum elevation in meters.
  ///
  /// ## Also see:
  ///
  /// - [maxElevation] - Maximum elevation along the route
  /// - [minElevationDistance] - The distance where minimum elevation occurs
  double get minElevation {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getMinElevation',
    );

    return resultString['result'];
  }

  /// Distance from route start where the route reaches minimum elevation.
  ///
  /// ## Returns
  ///
  /// - Distance in meters.
  ///
  /// ## Also see:
  ///
  /// - [maxElevation] - Maximum elevation along the route
  /// - [maxElevationDistance] - Distance where maximum elevation occurs
  int get minElevationDistance {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getMinElevationDistance',
    );

    return resultString['result'];
  }

  /// Road type sections for the route.
  ///
  /// Each section provides the start distance and a [RoadType] describing the
  /// road classification. The section's end is the start of the next section
  /// or the route end.
  ///
  /// ## Returns
  ///
  /// - A list of [RoadTypeSection].
  List<RoadTypeSection> get roadTypeSections {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getRoadTypeSections',
    );

    final List<dynamic> listJson = resultString['result'];
    final List<RoadTypeSection> retList = listJson
        .map(
          (final dynamic categoryJson) =>
              RoadTypeSection.fromJson(categoryJson),
        )
        .toList();
    return retList;
  }

  /// Sections with abrupt elevation changes (steep segments).
  ///
  /// The user provides a list of steep category thresholds (`categs`). Each
  /// returned [SteepSection] references the index into that list.
  ///
  /// ## Parameters
  ///
  /// - [categs]: List of slope thresholds (e.g. `[-16, -10, -7, -4, -1, 1, 4, 7, 10, 16]`).
  ///
  /// ## Returns
  ///
  /// - A list of [SteepSection] describing abrupt elevation changes.
  List<SteepSection> getSteepSections(final List<double> categs) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getSteepSections',
      args: categs,
    );

    final List<dynamic> listJson = resultString['result'];
    final List<SteepSection> retList = listJson
        .map(
          (final dynamic categoryJson) => SteepSection.fromJson(categoryJson),
        )
        .toList();
    return retList;
  }

  /// Surface type sections for the route.
  ///
  /// Each section contains the start distance and the surface [SurfaceType].
  ///
  /// ## Returns
  ///
  /// - A list of [SurfaceSection].
  List<SurfaceSection> get surfaceSections {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getSurfaceSections',
    );

    final List<dynamic> listJson = resultString['result'];
    final List<SurfaceSection> retList = listJson
        .map(
          (final dynamic categoryJson) => SurfaceSection.fromJson(categoryJson),
        )
        .toList();
    return retList;
  }

  /// Total downhill elevation (meters) along the route.
  ///
  /// ## Returns
  ///
  /// - Total descent in meters.
  ///
  /// ## Also see:
  ///
  /// - [totalUp] - Total uphill elevation along the route
  /// - [getTotalUp] - Total uphill elevation between [start] and [end]
  double get totalDown {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getTotalDown',
    );

    return resultString['result'];
  }

  /// Total uphill elevation (meters) along the route.
  ///
  /// ## Returns
  ///
  /// - Total ascent in meters.
  ///
  /// ## Also see:
  ///
  /// - [totalDown] - Total downhill elevation along the route
  /// - [getTotalDown] - Total downhill elevation between [start] and [end]
  double get totalUp {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getTotalUp',
    );

    return resultString['result'];
  }

  /// Total downhill elevation between [start] and [end] (meters).
  ///
  /// ## Parameters
  ///
  /// - [start]: Begin distance (meters) along the route.
  /// - [end]: End distance (meters) along the route.
  ///
  /// ## Returns
  ///
  /// - Total descent in meters for the interval. Returns `0` for invalid
  ///   intervals.
  ///
  /// ## Also see:
  ///
  /// - [getTotalUp] - Total uphill elevation between [start] and [end]
  /// - [totalDown] - Total downhill elevation along the route
  double getTotalDown(int start, int end) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getTotalDownBE',
      args: <String, int>{'first': start, 'second': end},
    );

    double result = resultString['result'];

    if (result.abs() < 0.0001) {
      result = 0;
    }

    return result;
  }

  /// Total uphill elevation between [start] and [end] (meters).
  ///
  /// ## Parameters
  ///
  /// - [start]: Begin distance (meters) along the route.
  /// - [end]: End distance (meters) along the route.
  ///
  /// ## Returns
  ///
  /// - Total ascent in meters for the interval. Returns `0` for invalid
  ///   intervals.
  ///
  /// ## Also see:
  ///
  /// - [getTotalDown] - Total downhill elevation between [start] and [end]
  /// - [totalUp] - Total uphill elevation along the route
  double getTotalUp(int start, int end) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteTerrainProfile',
      'getTotalUpBE',
      args: <String, int>{'first': start, 'second': end},
    );

    double result = resultString['result'];

    if (result.abs() < 0.0001) {
      result = 0;
    }

    return result;
  }
}
