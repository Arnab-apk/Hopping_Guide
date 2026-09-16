// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Preferences regarding building terrain profile
///
/// These preferences influence whether terrain profile data is calculated.
/// Terrain profile data includes elevation changes along the route, which can
/// be useful for activities like biking or hiking.
///
/// These settings are required for the [Route.terrainProfile] to be populated in the route response.
///
/// ## See also:
///
/// - [RoutePreferences] - Holds the overall routing preferences including transport mode and profiles.
/// - [Route.terrainProfile] - Contains the terrain profile data for a route.
/// - [RouteTerrainProfile] - Represents the terrain profile data along a route.
///
/// {@category Routing}
class BuildTerrainProfile {
  const BuildTerrainProfile({this.enable = false, this.minVariation = -1});

  /// Creates an instance from a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  factory BuildTerrainProfile.fromJson(final Map<String, dynamic> json) {
    return BuildTerrainProfile(
      enable: json['b'],
      minVariation: json['minVariation'],
    );
  }

  /// Enable / disable terrain profile build.
  ///
  /// The terrain profile will be built only if this is set to true.
  ///
  /// Default is false.
  final bool enable;

  /// The minimum elevation variation to be registered for total up / total down statistics.
  ///
  /// A value < 0 lets the SDK to choose a proper value.
  /// Default is 0.
  final double minVariation;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['b'] = enable;
    json['minVariation'] = minVariation;
    return json;
  }

  @override
  bool operator ==(covariant final BuildTerrainProfile other) {
    return other.enable == enable && other.minVariation == minVariation;
  }

  @override
  int get hashCode => enable.hashCode ^ minVariation.hashCode;
}
