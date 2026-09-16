// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// # Core Library
///
/// Provides foundational types, utilities, and interfaces for the GEM SDK, including coordinates, error handling, settings, and core data structures.
///
/// This library covers the essential building blocks for working with the SDK, such as coordinates, addresses, alarms, categories, images, language, and error management.
///
/// ## Main features
/// - [AddressInfo], [ContactInfo] – Structures for address and contact details of [Landmark]s.
/// - [AlarmService], [AlarmListener], [AlarmsList] – Alarm and event management for routes and navigation.
/// - [AutoUpdateSettings] – Configuration for automatic content updates.
/// - [Coordinates] – Represents geographic coordinates and related calculations.
/// - [Debug] – Debugging utilities for development and troubleshooting.
/// - [GemError] – Errors returned from SDK operations.
/// - [ExternalInfo] – Wikipedia references and metadata for landmarks.
/// - [GemCameraPlayer] – Interface for controlling GEM camera playback.
/// - [GemKit] – Main SDK initialization and core API access point.
/// - [GenericCategories] – Predefined categories for landmarks and POIs.
/// - [GeographicArea] – Represents defined geographic regions or areas.
/// - [ImageHandler], [GemImage]– Image loading, management, and identification utilities.
/// - [ISOCodeConversions] – Utilities for ISO country and language code conversions.
/// - [Landmark], [LandmarkCategory] – Landmark entity and associated categories. The [Landmark] is the main entity representing a point of interest.
/// Can be used in search, routing and navigation. Map POIs are provided as landmarks. The user can also create custom landmarks and manage them through [LandmarkStore]s
/// - [Language] – Language and localization utilities.
/// - [MapViewRoutesCollection] – Collection of routes for map display.
/// - [OffBoardListener] – Listener for offboard service events.
/// - [Parameter] – Key-value pairs for extra data associated with landmarks.
/// - [Path] – Representation of a path or polyline geometry.
/// - [PersistentRoadblockListener] – Listener for roadblock events affecting navigation.
/// - [PositionQuality] – Describes the quality of positional data (e.g., GPS accuracy).
/// - [Route] – Represents a route and its properties.
/// - [SdkSettings] – SDK configuration.
/// - [SettingsService] – `.ini` file–style settings storage and retrieval.
/// - [SignpostDetails] – Information about road signs on a route.
/// - [SoundPlayingListener], [SoundPlayingService] – Audio playback control and event handling.
/// - [TaskHandler] – Manages asynchronous operations.
/// - [RouteTerrainProfile] – Elevation and terrain data along a route.
/// - [TimeDistanceCoordinate] – Coordinates with associated time and distance data.
/// - [TimezoneService] – Time zone information and conversion utilities.
/// - [TrafficEvent], [RouteTrafficEvent] – Traffic data and events.
/// - [TransferStatistics] – Data transfer and usage statistics for various services.
/// - [TurnDetails] – Information about individual navigation turns.
/// - [LandmarkStore] – Persistent storage and retrieval of landmark data. Used for multiple usecases, such as within alarms or search on custom landmarks.
///
/// ## More details
///
/// - See the [Magic Lane SDK for Flutter Documentation](https://developer.magiclane.com/docs/flutter/guides/category/introduction) for more information.
library;

export 'src/activation/activation_service.dart';
export 'src/activation/gate_keeper_service.dart';
export 'src/alarms/alarm_listener.dart';
export 'src/alarms/alarm_monitored_area.dart';
export 'src/alarms/alarm_service.dart';
export 'src/alarms/alarms_list.dart';
export 'src/contentstore/content_parameters.dart';
export 'src/core/common/auto_update_settings.dart';
export 'src/core/common/exceptions.dart';
export 'src/core/common/gem_error.dart';
export 'src/core/common/gem_kit.dart';
export 'src/core/common/parameters.dart';
export 'src/core/common/progress_listener.dart';
export 'src/core/common/road_info.dart';
export 'src/core/common/task_handler.dart' show TaskHandler;
export 'src/core/common/time_distance.dart';
export 'src/core/common/transfer_statistics.dart';
export 'src/core/common/turn_details.dart';
export 'src/core/common/version.dart';
export 'src/core/geographic/circle_geographic_area.dart';
export 'src/core/geographic/coordinates.dart';
export 'src/core/geographic/geographic_area.dart';
export 'src/core/geographic/path.dart';
export 'src/core/geographic/polygon_geographic_area.dart';
export 'src/core/geographic/rectangle_geographic_area.dart';
export 'src/core/geographic/tiles_collection_geographic_area.dart';
export 'src/core/images/abstract_geometry.dart';
export 'src/core/images/abstract_geometry_item.dart';
export 'src/core/images/gem_image.dart';
export 'src/core/images/image_handler.dart';
export 'src/core/images/image_ids.dart';
export 'src/core/images/image_render_settings.dart';
export 'src/core/images/images.dart';
export 'src/core/images/renderable_img.dart';
export 'src/core/images/size_and_format.dart';
export 'src/core/landmark/address_info.dart';
export 'src/core/landmark/contact_info.dart';
export 'src/core/landmark/entrance_locations.dart';
export 'src/core/landmark/external_info.dart';
export 'src/core/landmark/external_info_service.dart';
export 'src/core/landmark/extra_info.dart';
export 'src/core/landmark/generic_categories.dart';
export 'src/core/landmark/landmark.dart';
export 'src/core/landmark/landmark_category.dart';
export 'src/core/locale/language.dart';
export 'src/core/locale/voice.dart';
export 'src/core/private/event_driven_progress_listener.dart';
export 'src/core/private/types.dart';
export 'src/core/route/climb_section.dart';
export 'src/core/route/ot_route.dart';
export 'src/core/route/pt_route.dart';
export 'src/core/route/pt_route_enums.dart';
export 'src/core/route/pt_route_instruction.dart';
export 'src/core/route/pt_route_segment.dart';
export 'src/core/route/restriction_section.dart';
export 'src/core/route/road_type_section.dart';
export 'src/core/route/route.dart';
export 'src/core/route/route_base.dart';
export 'src/core/route/route_instruction_base.dart';
export 'src/core/route/route_segment_base.dart';
export 'src/core/route/signpost_details.dart';
export 'src/core/route/signpost_enums.dart';
export 'src/core/route/signpost_item.dart';
export 'src/core/route/steep_section.dart';
export 'src/core/route/surface_section.dart';
export 'src/core/route/terrain_profile.dart';
export 'src/core/route/time_distance_coordinates.dart';
export 'src/core/traffic/persistent_roadblock_listener.dart';
export 'src/core/traffic/route_traffic_event.dart';
export 'src/core/traffic/traffic_enums.dart';
export 'src/core/traffic/traffic_event.dart';
export 'src/core/traffic/traffic_parameters.dart';
export 'src/core/traffic/traffic_preferences.dart';
export 'src/core/traffic/traffic_service.dart';
export 'src/core/traffic/user_roadblock_path_preview_coordinate.dart';
export 'src/isocodeconversions/iso_code_conversions.dart';
export 'src/landmarkstore/landmark_store.dart';
export 'src/localizationservice/localization_service.dart';
export 'src/localizationservice/localization_string_ids.dart';
export 'src/position/position_quality.dart';
export 'src/sense/gem_camera_player.dart';
export 'src/settings/debug.dart';
export 'src/settings/debug_enums.dart';
export 'src/settings/mount_info.dart';
export 'src/settings/network_provider.dart';
export 'src/settings/offboard_listener.dart';
export 'src/settings/sdk_capability.dart';
export 'src/settings/sdk_settings.dart';
export 'src/settings/sdk_settings_enums.dart';
export 'src/settings/settings_service.dart';
export 'src/sound/sound_playing_listener.dart';
export 'src/sound/sound_playing_preferences.dart';
export 'src/sound/sound_playing_service.dart';
export 'src/sound/sound_session_request_preferences.dart';
export 'src/timezone/timezone.dart';
