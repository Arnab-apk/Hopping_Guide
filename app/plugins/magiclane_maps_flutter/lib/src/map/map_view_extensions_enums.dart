// SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Navigation route update rate.
///
/// Controls how frequently the navigation route is recomputed and re-rendered
/// while a route is active. Higher rates produce smoother visual updates at the
/// cost of additional CPU and battery usage.
///
/// ## Also see:
///
/// - [MapViewExtensions.navigationRouteUpdateRate] - Get or set the navigation route update rate.
///
/// {@category Maps & 3D Scenes}
enum RouteUpdateRate {
  /// Update only when needed (lowest CPU/battery cost).
  low,

  /// Update every N meters and M seconds (balanced).
  normal,

  /// Update every frame (smoothest, highest cost).
  high,
}

/// @nodoc
extension RouteUpdateRateExtension on RouteUpdateRate {
  int get id {
    switch (this) {
      case RouteUpdateRate.low:
        return 0;
      case RouteUpdateRate.normal:
        return 1;
      case RouteUpdateRate.high:
        return 2;
    }
  }

  static RouteUpdateRate fromId(final int id) {
    switch (id) {
      case 0:
        return RouteUpdateRate.low;
      case 1:
        return RouteUpdateRate.normal;
      case 2:
        return RouteUpdateRate.high;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
