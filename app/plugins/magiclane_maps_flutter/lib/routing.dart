// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// # Routing
///
/// Provides APIs for route calculation, management, and related overlays.
///
/// This library covers the main interfaces and classes for route creation, preferences, listeners, terrain profiles, and social overlays.
///
/// ## Main features
/// - [MapViewRoutesCollection] – Collection of routes for map display.
/// - [Route] – Main class for representing a route. Specialized classes are available for special types of routes.
/// - [RouteBookmarks] – Bookmark management for route information, allowing the user to persist route data.
/// - [RouteListener] – Listener interface for route events.
/// - [RouteTerrainProfile] – Terrain profile data for routes.
/// - [RoutePreferences] – Preferences for route calculation.
/// - [RoutingService] – Main class for route calculation and management.
/// - [SocialOverlay], [SocialReportListener] – Social overlays and reporting for routes.
///
/// ## More details
///
/// - See the [Routing documentation](https://developer.magiclane.com/docs/flutter/guides/category/routing) for more information.
/// {@canonicalFor map_view_routes_collection.MapViewRoutesCollection}
/// {@canonicalFor map_view_routes_collection.MapViewRoute}
library;

export 'src/core/route/ot_route.dart';
export 'src/core/route/pt_route.dart';
export 'src/core/route/pt_route_enums.dart';
export 'src/core/route/pt_route_instruction.dart';
export 'src/core/route/pt_route_segment.dart';
export 'src/core/route/route.dart';
export 'src/core/route/route_bookmarks.dart';
export 'src/core/route/route_listener.dart';
export 'src/core/route/terrain_profile.dart';
export 'src/map/map_view_routes_collection.dart';
export 'src/overlays/social_overlay.dart';
export 'src/overlays/social_overlay_parameters.dart';
export 'src/overlays/social_report_listener.dart';
export 'src/overlays/social_reports_overlay_category.dart';
export 'src/overlays/social_reports_overlay_info.dart';
export 'src/routing/build_terrain_profile.dart';
export 'src/routing/departure_heading.dart';
export 'src/routing/ev_car_model.dart';
export 'src/routing/round_trip_parameters.dart';
export 'src/routing/routing_enums.dart';
export 'src/routing/routing_preferences.dart';
export 'src/routing/routing_service.dart';
export 'src/routing/vehicle_profile.dart';
