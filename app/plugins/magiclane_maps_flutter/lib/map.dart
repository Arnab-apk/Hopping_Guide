// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// # Maps & 3D Scene
///
/// Provides APIs for map rendering, camera control, overlays, markers, and 3D scene management.
///
/// This library covers the main interfaces and classes for displaying, interacting with, and customizing maps and 3D scenes, including camera, overlays, markers, and rendering events.
///
/// ## Main features
/// - [GemMap] – Core map interface for map operations and queries.
/// - [MapCamera] – Camera control for map view manipulation.
/// - [GemMapController] – Controller for programmatic map interaction.
/// - [FollowPositionPreferences] – Preferences for the camera when following the user.
/// - [MapDetails] – Provides map metadata and details.
/// - [MapDownloaderService] – Service for downloading map tiles intended for display. Do not confuse with [ContentStore] features.
/// - [MapSceneObject] – 3D object scene management and configuration for position tracker.
/// - [MapViewExtensions], [MapViewPreferences], [MapViewRenderInfo] – Classes related to map rendering and preferences.
/// - [Marker], [Overlay], [PTStopInfo] – Overlay and marker management for map annotation.
///
/// ## More details
///
/// - See the [Maps](https://developer.magiclane.com/docs/flutter/guides/category/maps) for more information.
library;

export 'src/gem_kit_view.dart';
export 'src/map/follow_position_preferences.dart';
export 'src/map/follow_position_preferences_enums.dart';
export 'src/map/gem_animation.dart';
export 'src/map/gem_map.dart';
export 'src/map/map_camera.dart';
export 'src/map/map_camera_types.dart';
export 'src/map/map_controller.dart';
export 'src/map/map_details.dart';
export 'src/map/map_details_enums.dart';
export 'src/map/map_downloader_service.dart';
export 'src/map/map_scene.dart';
export 'src/map/map_view_extensions.dart';
export 'src/map/map_view_extensions_enums.dart';
export 'src/map/map_view_marker_collections.dart';
export 'src/map/map_view_preferences.dart';
export 'src/map/map_view_preferences_enums.dart';
export 'src/map/map_view_render_info.dart';
export 'src/map/render_settings/highlight_render_settings.dart';
export 'src/map/render_settings/marker_render_settings.dart';
export 'src/map/render_settings/render_settings.dart';
export 'src/map/render_settings/route_render_settings.dart';
export 'src/markers/marker.dart';
export 'src/markers/marker_collection.dart';
export 'src/markers/marker_match.dart';
export 'src/markers/marker_sketches.dart';
export 'src/markers/marker_utils.dart';
export 'src/overlays/overlay_category.dart';
export 'src/overlays/overlay_collection.dart';
export 'src/overlays/overlay_enums.dart';
export 'src/overlays/overlay_info.dart';
export 'src/overlays/overlay_item.dart';
export 'src/overlays/overlay_item_parameters.dart';
export 'src/overlays/overlay_service.dart';
export 'src/ptstopinfo/pt_agency.dart';
export 'src/ptstopinfo/pt_alert_info.dart';
export 'src/ptstopinfo/pt_crowding_info.dart';
export 'src/ptstopinfo/pt_route_info.dart';
export 'src/ptstopinfo/pt_stop.dart';
export 'src/ptstopinfo/pt_stop_info.dart';
export 'src/ptstopinfo/pt_stop_time.dart';
export 'src/ptstopinfo/pt_trip.dart';
