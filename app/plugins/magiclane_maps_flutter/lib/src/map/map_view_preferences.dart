// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/routing.dart';
import 'package:magiclane_maps_flutter/src/contentstore/content_store_item.dart';
import 'package:magiclane_maps_flutter/src/core/common/gem_error.dart';
import 'package:magiclane_maps_flutter/src/core/private/types.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/landmarkstore/landmark_store_collection.dart';
import 'package:magiclane_maps_flutter/src/map/map_view_path_collection.dart';
import 'package:meta/meta.dart';

/// Map view preferences.
///
/// This class exposes view-level preferences and collections for a [GemMap]. Use
/// [GemView.preferences] to obtain an instance rather than constructing this
/// class directly.
///
/// The preferences control what is displayed on the map and how the view
/// behaves. Examples include enabling/disabling touch gestures, configuring
/// camera behavior (perspective and view angles), changing map style, toggling
/// rendering options (FPS display, fast browsing), managing cursor mode, and
/// controlling visibility for traffic, buildings and labels.
///
/// The class also provides access to collections used by the view:
/// - [lmks] — landmark store settings ([LandmarkStoreCollection]).
/// - [markers] — visible marker collections ([MapViewMarkerCollections]).
/// - [paths] — visible path collections ([MapViewPathCollection]).
/// - [routes] — visible route collections ([MapViewRoutesCollection]).
///
/// {@category Maps & 3D Scenes}
class MapViewPreferences {
  MapViewPreferences() : _pointerId = -1, _mapId = -1, _mapPointerId = -1;

  @internal
  MapViewPreferences.init(
    final int id,
    final int mapId,
    final dynamic mapPointerId,
  ) : _pointerId = id,
      _mapId = mapId,
      _mapPointerId = mapPointerId;
  final dynamic _pointerId;
  final int _mapId;
  final dynamic _mapPointerId;
  dynamic get pointerId => _pointerId;
  int get mapId => _mapId;

  MapViewRoutesCollection? _routes;
  MapViewPathCollection? _paths;
  LandmarkStoreCollection? _lmks;
  MapViewMarkerCollections? _markers;
  FollowPositionPreferences? _followPositionPreferences;

  /// Enable or disable specific touch gestures for the map view.
  ///
  /// Touch gestures control how users interact with the map through touch input.
  /// You can selectively enable or disable individual gesture types such as
  /// pinch-to-zoom, rotation, panning, and double-tap. This is useful for
  /// creating custom interaction modes or restricting certain gestures in
  /// specific application states.
  ///
  /// ## Parameters
  ///
  /// - [gestures]: (List\<TouchGestures>) List of gesture types to enable or disable.
  /// - [enable]: (bool) True to enable the specified gestures, false to disable them.
  ///
  /// ## See also:
  ///
  /// - [TouchGestures] - Available gesture types.
  /// - [isTouchGestureEnabled] - Check if a specific gesture is enabled.
  /// - [touchGesturesStates] - Get the bitfield of all enabled gestures.
  void enableTouchGestures(
    final List<TouchGestures> gestures,
    final bool enable,
  ) {
    final int gesturesValue = gestures.fold(
      0,
      (final int previousValue, final TouchGestures gesture) =>
          previousValue | gesture.id,
    );
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'enableTouchGestures',
      args: <String, Object>{'gestures': gesturesValue, 'enable': enable},
      dependencyId: _mapPointerId,
    );
  }

  /// Get follow position preferences.
  ///
  /// Follow position preferences control camera behavior when the map is in
  /// follow position mode (tracking the user's GPS location). Use this to
  /// configure camera focus, angles, zoom levels, and animation settings during
  /// position tracking.
  ///
  /// ## Returns
  ///
  /// - (FollowPositionPreferences) The current [FollowPositionPreferences] instance for this view.
  ///
  /// ## See also:
  ///
  /// - [FollowPositionPreferences] - Configure follow position behavior.
  /// - [GemMapController.startFollowingPosition] - Enter follow position mode.
  /// - [GemMapController.stopFollowingPosition] - Exit follow position mode.
  /// - [PositionService] - Manage GPS position updates.
  FollowPositionPreferences get followPositionPreferences {
    if (_followPositionPreferences == null) {
      final OperationResult resultString = objectMethod(
        _pointerId,
        'MapViewPreferences',
        'followPositionPreferences',
        dependencyId: _mapPointerId,
      );

      _followPositionPreferences = FollowPositionPreferences.init(
        resultString['result'],
        _mapId,
        _mapPointerId,
      );
    }
    return _followPositionPreferences!;
  }

  /// Get buildings visibility option.
  ///
  /// Controls how buildings are rendered on the map. Options include hiding
  /// buildings entirely, showing them as flat 2D shapes, or rendering them as
  /// 3D models. 3D building effects are most pronounced when the camera is
  /// tilted and zoomed in.
  ///
  /// ## Returns
  ///
  /// - [BuildingsVisibility]: The current buildings visibility mode.
  ///
  /// ## See also:
  ///
  /// - [buildingsVisibility] - Change buildings visibility.
  /// - [BuildingsVisibility] - Available visibility modes.
  /// - [setViewAngle] - Tilt the camera to see 3D buildings better.
  BuildingsVisibility get buildingsVisibility {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getBuildingsVisibility',
      dependencyId: _mapPointerId,
    );

    return BuildingsVisibilityExtension.fromId(resultString['result']);
  }

  /// Get frames-per-second draw state.
  ///
  /// ## Returns
  ///
  /// True if frames-per-second drawing is enabled, false otherwise.
  bool get drawFPS {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getDrawFPS',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Set fast browsing status.
  ///
  /// Fast browsing mode optimizes map rendering for smooth navigation during
  /// rapid map movements (panning, zooming). When enabled, the SDK may reduce
  /// detail level temporarily to maintain high frame rates, then restore full
  /// detail when movement stops.
  ///
  /// ## Parameters
  ///
  /// - [enable]: (bool) True to enable fast browsing, false to disable.
  set isFastBrowsingEnabled(bool enable) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'enableFastBrowsingMode',
      args: enable,
      dependencyId: _mapPointerId,
    );
  }

  /// Get fast browsing status.
  ///
  /// Fast browsing mode optimizes rendering during map movement for smoother
  /// performance. Check this property to determine whether fast browsing is
  /// currently active.
  ///
  /// ## Returns
  ///
  /// - (bool) True if fast browsing is enabled, false otherwise.
  bool get isFastBrowsingEnabled {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'isFastBrowsingEnabled',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Get the map view focus viewport.
  ///
  /// The focus viewport is the portion of the view that contains the maximum
  /// map details. Coordinates are relative to the view's parent screen. The
  /// default value is the entire view viewport.
  ///
  /// ## Returns
  ///
  /// The focus viewport as a [Rectangle<int>].
  Rectangle<int> get focusViewport {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getFocusViewport',
      dependencyId: _mapPointerId,
    );

    final Rectangle<int> rect = Rectangle<int>(
      resultString['result']['x'] ?? 0,
      resultString['result']['y'] ?? 0,
      resultString['result']['width'] ?? 0,
      resultString['result']['height'] ?? 0,
    );

    return rect;
  }

  /// Get the map details quality level.
  ///
  /// The quality level controls the amount of detail rendered on the map,
  /// including label density, texture quality, and geometry complexity. Higher
  /// quality levels provide more visual detail but may impact performance on
  /// lower-end devices.
  ///
  /// ## Returns
  ///
  /// - (MapDetailsQualityLevel) The current quality level (low, medium, or high).
  ///
  /// ## See also:
  ///
  /// - [MapDetailsQualityLevel] - Available quality options.
  MapDetailsQualityLevel get mapDetailsQualityLevel {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getMapDetailsQualityLevel',
      dependencyId: _mapPointerId,
    );

    return MapDetailsQualityLevelExtension.fromId(resultString['result']);
  }

  /// Get the current view style content id.
  ///
  /// Each map style in the content store has a unique identifier. Use this to
  /// determine which style is currently applied to the map. Returns 0 if no
  /// style is set.
  ///
  /// ## Returns
  ///
  /// - (int) The current view style content id, or 0 if no style is set.
  ///
  /// ## See also:
  ///
  /// - [ContentStoreItem.id] - Content store item identifiers.
  /// - [setMapStyleById] - Set map style by ID.
  /// - [mapStylePath] - Get the current style path.
  int get mapStyleId {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getMapStyleId',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Get the current map view style path.
  ///
  /// Returns the file path or logical path of the currently applied map style.
  /// This can be used to identify which style asset is active.
  ///
  /// ## Returns
  ///
  /// - (String) The current map view style path.
  ///
  /// ## See also:
  ///
  /// - [setMapStyleByPath] - Set map style by path.
  /// - [mapStyleId] - Get the current style ID.
  /// - [ContentStoreItem.fileName] - Content store file paths.
  String get mapStylePath {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getMapStylePath',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Get the map view perspective.
  ///
  /// The perspective determines how the 3D scene is projected onto the 2D
  /// screen. Different perspectives affect how distances and angles appear,
  /// which can be useful for specific visualization needs.
  ///
  /// ## Returns
  ///
  /// (MapViewPerspective) The current perspective mode for this view.
  ///
  /// ## See also:
  ///
  /// - [setMapViewPerspective] - Change the map perspective.
  /// - [MapViewPerspective] - Available perspective modes.
  MapViewPerspective get mapViewPerspective {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getMapViewPerspective',
      dependencyId: _mapPointerId,
    );

    return MapViewPerspectiveExtension.fromId(resultString['result']);
  }

  /// Get the maximum viewing angle in degrees.
  ///
  /// The maximum view angle corresponds to the camera looking toward the
  /// horizon. Must be between 0 and 90 degrees, where 0 represents a top-down view.
  ///
  /// ## Returns
  ///
  /// The maximum view angle in degrees as a [double].
  double get maxViewAngle {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getMaxViewAngle',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Get the minimum viewing angle in degrees.
  ///
  /// The minimum view angle corresponds to the camera looking directly downward.
  /// Must be between 0 and 90 degrees, where 0 represents a top-down view.
  ///
  /// ## Returns
  ///
  /// The minimum view angle in degrees as a [double].
  double get minViewAngle {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getMinViewAngle',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Get the map labels fading state.
  ///
  /// ## Returns
  ///
  /// True if map labels are in fading state, false otherwise.
  bool get mapLabelsFading {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getMapLabelsFading',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Set the map labels fading effect.
  ///
  /// ## Parameters
  ///
  /// - [enable]: True to enable fading, false to disable.
  set mapLabelsFading(bool enable) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setMapLabelsFading',
      args: enable,
      dependencyId: _mapPointerId,
    );
  }

  /// Set map labels continuous rendering.
  ///
  /// ## Parameters
  ///
  /// - [enable]: True to enable continuous rendering, false to disable.
  set mapLabelsContinuousRendering(bool enable) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setMapLabelsContinuousRendering',
      args: enable,
      dependencyId: _mapPointerId,
    );
  }

  /// Get the map labels continuous rendering flag.
  ///
  /// ## Returns
  ///
  /// True if map labels continuous rendering is enabled, false otherwise.
  bool get mapLabelsContinuousRendering {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getMapLabelsContinuousRendering',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Enable or disable fast loading.
  ///
  /// ## Parameters
  ///
  /// - [disable]: (bool) True to disable fast loading, false to enable it.
  set disableFastLoading(bool disable) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setDisableFastLoading',
      args: disable,
      dependencyId: _mapPointerId,
    );
  }

  /// Check whether fast loading is disabled.
  ///
  /// ## Returns
  ///
  /// - True if fast loading is disabled, false otherwise.
  bool get disableFastLoading {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'disableFastLoading',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Set the elevation alpha factor.
  ///
  /// ## Parameters
  ///
  /// - [alphaFactor]: (double) A value between 0.0 and 1.0 controlling opacity.
  set elevationAlphaFactor(double alphaFactor) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setElevationAlphaFactor',
      args: alphaFactor,
      dependencyId: _mapPointerId,
    );
  }

  /// Get the elevation alpha factor.
  ///
  /// ## Returns
  ///
  /// - (double) The elevation alpha factor (0.0 to 1.0).
  double get elevationAlphaFactor {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getElevationAlphaFactor',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Get the North-fixed flag value.
  ///
  /// ## Returns
  ///
  /// True if the view is aligned to North, false otherwise.
  bool get northFixedFlag {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getNorthFixedFlag',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Get the map's angle in degrees.
  ///
  /// The angle is between 0 and 360 degrees, where 0 represents north-up alignment.
  ///
  /// ## Returns
  ///
  /// The map angle in degrees as a [double].
  ///
  /// ## See also:
  ///
  /// - [tiltAngle] - The tilt angle complementary to view angle.
  /// - [viewAngle] - The camera's pitch angle.
  double get mapAngle {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getRotationAngle',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Get the tilt angle in degrees.
  ///
  /// The tilt angle equals 90 - [viewAngle]. A value of 90 represents a top-down view.
  ///
  /// ## Returns
  ///
  /// The tilt angle in degrees as a [double].
  ///
  /// ## See also:
  ///
  /// - [mapAngle] - The map's rotation angle.
  /// - [viewAngle] - The camera's pitch angle.
  double get tiltAngle {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getTiltAngle',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Get enabled touch gestures bitfield.
  ///
  /// ## Returns
  ///
  /// An int bitfield representing enabled [TouchGestures].
  ///
  /// ## See also:
  ///
  /// - [enableTouchGestures] - Enable or disable specific gestures.
  /// - [isTouchGestureEnabled] - Check if a specific gesture is enabled.
  int get touchGesturesStates {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getTouchGesturesStates',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Get traffic visibility.
  ///
  /// Returns whether the traffic layer is currently visible on the map. By
  /// default, traffic is visible if the current map style includes a traffic
  /// layer.
  ///
  /// ## Returns
  ///
  /// - (bool) True if traffic is visible, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [setTrafficVisibility] - Change traffic visibility.
  bool get trafficVisibility {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getTrafficVisibility',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Get the camera's pitch angle in degrees.
  ///
  /// The value is between 0 and 90 degrees, where 0 represents a top-down view.
  ///
  /// ## Returns
  ///
  /// The view angle in degrees as a [double].
  ///
  /// ## See also:
  ///
  /// - [mapAngle] - The map's rotation angle.
  /// - [tiltAngle] - The tilt angle complementary to view angle.
  double get viewAngle {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getViewAngle',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Check if the cursor is enabled.
  ///
  /// When the cursor is enabled, map selection can be activated by calling
  /// [GemMapController.setCursorScreenPosition]. The cursor is a crosshair that
  /// appears at the specified screen position. Note that both [enableCursor]
  /// and [enableCursorRender] must be true for the cursor to be visible on
  /// screen. The cursor is automatically disabled when entering follow position
  /// mode.
  ///
  /// ## Returns
  ///
  /// - (bool) True if the cursor is enabled, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [enableCursor] setter - Enable or disable cursor mode.
  /// - [cursorRenderEnabled] - Check if cursor rendering is enabled.
  /// - `setCursorScreenPosition` setter - Set the cursor position.
  /// - [GemMapController.setCursorScreenPosition] - Move the cursor.
  bool get cursorEnabled {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'isCursorEnabled',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Check if cursor rendering is enabled.
  ///
  /// Controls whether the cursor is actually drawn on screen. Both this
  /// property and [cursorEnabled] must be true for the cursor crosshair to
  /// appear. Separating these allows you to enable cursor functionality without
  /// necessarily displaying the visual indicator.
  ///
  /// ## Returns
  ///
  /// - (bool) True if cursor rendering is enabled, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [enableCursorRender] setter - Enable or disable cursor rendering.
  /// - [cursorEnabled] - Check if cursor mode is enabled.
  bool get cursorRenderEnabled {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'isCursorRenderEnabled',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Check whether a [MapSceneObject] is visible in the current view.
  ///
  /// ## Parameters
  ///
  /// - [obj]: The [MapSceneObject] to query.
  ///
  /// ## Returns
  ///
  /// True if [obj] is visible in the current view, false otherwise.
  ///
  /// ## Also see:
  ///
  /// - [MapSceneObject] - Objects that can be added to the map scene.
  /// - [MapSceneObject.getDefPositionTracker] - Position tracking for scene objects.
  bool isMapSceneObjectVisible(final MapSceneObject obj) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'isMapSceneObjectVisible',
      args: obj.pointerId,
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Check whether a touch gesture is enabled.
  ///
  /// ## Parameters
  ///
  /// - [gesture]: The [TouchGestures] value to check.
  ///
  /// ## Returns
  ///
  /// True if the specified touch gesture is enabled, false otherwise.
  ///
  /// ## Also see:
  ///
  /// - [TouchGestures] - Available gesture types.
  /// - [enableTouchGestures] - Enable or disable specific gestures.
  /// - [touchGesturesStates] - Get the bitfield of all enabled gestures.
  bool isTouchGestureEnabled(final TouchGestures gesture) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'isTouchGestureEnabled',
      args: gesture.id,
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Get access to the settings for visible landmark stores.
  ///
  /// Landmark stores contain map features like points of interest (POIs),
  /// buildings, and other geographic features. Use this collection to control
  /// which landmark stores are visible and configure their display properties.
  ///
  /// ## Returns
  ///
  /// - (LandmarkStoreCollection) The landmark store collection for the view.
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreCollection] - Configure visible landmark stores.
  /// - [markers] - Marker collections.
  LandmarkStoreCollection get lmks {
    if (_lmks == null) {
      final OperationResult resultString = objectMethod(
        _pointerId,
        'MapViewPreferences',
        'lmks',
        dependencyId: _mapPointerId,
      );

      _lmks = LandmarkStoreCollection.init(
        resultString['result'],
        _mapPointerId,
      );
    }
    return _lmks!;
  }

  /// Get access to the collections of visible markers.
  ///
  /// Markers are custom icons or images displayed at specific map locations.
  /// Use this collection to add, remove, and configure markers.
  ///
  /// ## Returns
  ///
  /// - (MapViewMarkerCollections) The marker collections for the view.
  ///
  /// ## See also:
  ///
  /// - [MapViewMarkerCollections] - Manage visible markers.
  /// - [lmks] - Landmark store collections.
  /// - [paths] - Path collections.
  MapViewMarkerCollections get markers {
    if (_markers == null) {
      final OperationResult resultString = objectMethod(
        _pointerId,
        'MapViewPreferences',
        'markers',
        dependencyId: _mapPointerId,
      );

      _markers = MapViewMarkerCollections.init(
        resultString['result'],
        _mapId,
        _mapPointerId,
      );
    }
    return _markers!;
  }

  /// Get access to the collection of visible paths.
  ///
  /// Paths are vector polylines drawn on the map, useful for showing custom
  /// trails, boundaries, or other line-based elements. Use this collection to
  /// add and configure path overlays.
  ///
  /// ## Returns
  ///
  /// - (MapViewPathCollection) The path collection for the view.
  ///
  /// ## See also:
  ///
  /// - [MapViewPathCollection] - Manage visible paths.
  /// - [routes] - Route collections.
  /// - [markers] - Marker collections.
  MapViewPathCollection get paths {
    if (_paths == null) {
      final OperationResult resultString = objectMethod(
        _pointerId,
        'MapViewPreferences',
        'paths',
        dependencyId: _mapPointerId,
      );

      _paths = MapViewPathCollection.init(
        resultString['result'],
        _mapId,
        _mapPointerId,
      );
    }
    return _paths!;
  }

  /// Get access to the collection of visible routes.
  ///
  /// Routes represent calculated navigation paths displayed on the map. Use
  /// this collection to show, hide, and style route overlays, including
  /// highlighting alternative routes and displaying traffic information along
  /// routes.
  ///
  /// ## Returns
  ///
  /// - (MapViewRoutesCollection) The routes collection for the view.
  ///
  /// ## See also:
  ///
  /// - [MapViewRoutesCollection] - Manage visible routes.
  /// - [paths] - Path collections for custom polylines.
  MapViewRoutesCollection get routes {
    if (_routes == null) {
      final OperationResult resultString = objectMethod(
        _pointerId,
        'MapViewPreferences',
        'routes',
        dependencyId: _mapPointerId,
      );

      _routes = MapViewRoutesCollection.init(
        resultString['result'],
        _mapPointerId,
      );
    }
    return _routes!;
  }

  /// Set buildings visibility to the specified option.
  ///
  /// Controls how buildings are rendered on the map. Use
  /// [BuildingsVisibility.threeDimensional] for 3D building models or
  /// [BuildingsVisibility.twoDimensional] for flat representations. 3D building
  /// effects are most pronounced with a tilted camera (use [setViewAngle]) and
  /// when zoomed in to street level.
  ///
  /// ## Parameters
  ///
  /// - [option]: (BuildingsVisibility) The buildings visibility mode to apply.
  ///
  /// ## See also:
  ///
  /// - [buildingsVisibility] getter - Get current visibility mode.
  /// - [setViewAngle] - Tilt the camera to see 3D buildings.
  set buildingsVisibility(final BuildingsVisibility option) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setBuildingsVisibility',
      args: option.id,
      dependencyId: _mapPointerId,
    );
  }

  /// Set the car model by file path.
  ///
  /// Configures a custom 3D car model for display during navigation or position
  /// tracking mode. The model file should be in a supported 3D format (check
  /// SDK documentation for supported formats).
  ///
  /// ## Parameters
  ///
  /// - [filePath]: (String) The path to the car model file.
  ///
  /// ## See also:
  ///
  /// - [followPositionPreferences] - Configure follow position behavior.
  set carModelByPath(final String filePath) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setCarModelByPath',
      args: filePath,
      dependencyId: _mapPointerId,
    );
  }

  /// Enable or disable frames-per-second drawing.
  ///
  /// Displays a real-time FPS (frames per second) counter at the specified
  /// screen position. This is useful for performance debugging and optimization.
  /// The FPS counter shows how smoothly the map is rendering.
  ///
  /// ## Parameters
  ///
  /// - [isEnabled]: (bool) True to enable FPS drawing, false to disable.
  /// - [pos]: (Point\<int>) The screen position where the FPS counter will be drawn.
  void setDrawFPS(final bool isEnabled, final Point<int> pos) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setDrawFPS',
      args: <String, Object>{
        'bEnable': isEnabled,
        'pos': XyType<int>.fromPoint(pos),
      },
      dependencyId: _mapPointerId,
    );
  }

  /// Set the map view focus viewport.
  ///
  /// The focus viewport defines the screen region where the SDK should
  /// prioritize rendering maximum map detail. Coordinates are relative to the
  /// view's parent screen. This is useful when part of your UI overlays the
  /// map—set the focus viewport to the visible area to ensure optimal detail
  /// there. If [view] is an empty viewport, the focus resets to the whole view.
  ///
  /// ## Parameters
  ///
  /// - [view]: (Rectangle\<int>) The focus viewport rectangle.
  ///
  /// ## See also:
  ///
  /// - [focusViewport] getter - Get the current focus viewport.
  set focusViewport(final Rectangle<int> view) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setFocusViewport',
      args: RectType<int>.fromRectangle(view),
      dependencyId: _mapPointerId,
    );
  }

  /// Set the map details quality level.
  ///
  /// Adjusts the overall rendering quality of the map. Higher quality levels
  /// display more labels, finer textures, and more detailed geometry, but may
  /// reduce performance on lower-end devices. Use [MapDetailsQualityLevel.low]
  /// for better performance or [MapDetailsQualityLevel.high] for maximum detail.
  ///
  /// ## Parameters
  ///
  /// - [level]: (MapDetailsQualityLevel) The quality level to apply.
  ///
  /// ## See also:
  ///
  /// - [mapDetailsQualityLevel] getter - Get current quality level.
  set mapDetailsQualityLevel(final MapDetailsQualityLevel level) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setMapDetailsQualityLevel',
      args: level.id,
      dependencyId: _mapPointerId,
    );
  }

  /// Set visibility of a [MapSceneObject] in the current view.
  ///
  /// ## Parameters
  ///
  /// - [obj]: The [MapSceneObject] to modify.
  /// - [visible]: True to show the object, false to hide it.
  ///
  /// ## Also see:
  ///
  /// - [MapSceneObject] - Objects that can be added to the map scene.
  /// - [MapSceneObject.getDefPositionTracker] - Position tracking for scene objects.
  void setMapSceneObjectVisibility(
    final MapSceneObject obj,
    final bool visible,
  ) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setMapSceneObjectVisibility',
      args: <String, Object>{'obj': obj, 'visible': visible},
      dependencyId: _mapPointerId,
    );
  }

  /// Set map view style by content.
  ///
  /// Applies a map style from a content store item. Map styles control the
  /// visual appearance of the map including colors, fonts, icon sets, and
  /// layer visibility. Optionally enable smooth transitions to animate between
  /// the old and new styles.
  ///
  /// ## Parameters
  ///
  /// - [style]: (ContentStoreItem) Style content to apply.
  /// - [smoothTransition]: (bool) When true, animates the transition between styles.
  ///
  /// ## See also:
  ///
  /// - [setMapStyleById] - Set style by content ID.
  /// - [setMapStyleByPath] - Set style by file path.
  /// - [setMapStyleByBuffer] - Set style from memory buffer.
  void setMapStyle(
    final ContentStoreItem style, {
    final bool smoothTransition = false,
  }) {
    setMapStyleById(style.id, smoothTransition: smoothTransition);
  }

  /// Set map view style by content id.
  ///
  /// Applies a map style using its content store identifier. This is useful
  /// when you know the style ID but don't have a [ContentStoreItem] object.
  /// Optionally enable smooth transitions to animate between styles.
  ///
  /// ## Parameters
  ///
  /// - [id]: (int) Content id (see [ContentStoreItem.id]).
  /// - [smoothTransition]: (bool) When true, animates the transition between styles.
  ///
  /// ## See also:
  ///
  /// - [setMapStyle] - Set style using ContentStoreItem.
  /// - [setMapStyleByPath] - Set style by file path.
  /// - [mapStyleId] - Get current style ID.
  void setMapStyleById(final int id, {final bool smoothTransition = false}) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setMapStyleById',
      args: <String, Object>{'id': id, 'smoothTransition': smoothTransition},
      dependencyId: _mapPointerId,
    );
  }

  /// Set map view style by content path.
  ///
  /// Applies a map style from a file path. The path can point to a `.style`
  /// file in your app's assets or a custom style file. Optionally enable smooth
  /// transitions to animate between the old and new styles.
  ///
  /// ## Parameters
  ///
  /// - [path]: (String) Content path (see [ContentStoreItem.fileName]).
  /// - [smoothTransition]: (bool) When true, animates the transition between styles.
  ///
  /// ## Example
  ///
  /// ```dart
  /// controller.preferences.setMapStyleByPath(
  ///   'assets/map_styles/dark_theme.style',
  ///   smoothTransition: true,
  /// );
  /// ```
  ///
  /// ## See also:
  ///
  /// - [setMapStyleById] - Set style by ID.
  /// - [setMapStyleByBuffer] - Set style from memory.
  /// - [mapStylePath] - Get current style path.
  void setMapStyleByPath(
    final String path, {
    final bool smoothTransition = false,
  }) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setMapStyleByPath',
      args: <String, Object>{
        'path': path,
        'smoothTransition': smoothTransition,
      },
      dependencyId: _mapPointerId,
    );
  }

  /// Set map view style by content buffer.
  ///
  /// Applies a map style loaded into memory as a byte buffer. This is useful
  /// for dynamically generated styles or styles loaded from network sources.
  /// Optionally enable smooth transitions to animate between styles.
  ///
  /// ## Parameters
  ///
  /// - [buffer]: (Uint8List) Content buffer containing the style data.
  /// - [smoothTransition]: (bool) When true, animates the transition between styles.
  ///
  /// ## See also:
  ///
  /// - [setMapStyleByPath] - Set style from file path.
  /// - [setMapStyleById] - Set style by ID.
  void setMapStyleByBuffer(
    final Uint8List buffer, {
    final bool smoothTransition = false,
  }) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setMapStyleByBuffer',
      args: <String, Object>{
        'content': buffer,
        'smoothTransition': smoothTransition,
      },
      dependencyId: _mapPointerId,
    );
  }

  /// Set the map view perspective.
  ///
  /// Changes the projection used to render the 3D scene onto the 2D screen.
  /// Different perspectives affect how distances and angles appear, which can
  /// be useful for specific visualization needs. Optionally animate the
  /// perspective change.
  ///
  /// ## Parameters
  ///
  /// - [perspective]: (MapViewPerspective) The perspective mode to use.
  /// - [animation]: (GemAnimation?) Optional animation for the perspective change.
  ///
  /// ## See also:
  ///
  /// - [mapViewPerspective] - Get current perspective.
  /// - [MapViewPerspective] - Available perspective modes.
  void setMapViewPerspective(
    final MapViewPerspective perspective, {
    final GemAnimation? animation,
  }) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setMapViewPerspective',
      args: <String, Object>{
        'perspective': perspective.id,
        if (animation != null) 'animation': animation,
      },
      dependencyId: _mapPointerId,
    );
  }

  /// Set the North-fixed flag value.
  ///
  /// ## Parameters
  ///
  /// - [isNorthFixed]: True to lock the view to North, false otherwise.
  set northFixedFlag(final bool isNorthFixed) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setNorthFixedFlag',
      args: isNorthFixed,
      dependencyId: _mapPointerId,
    );
  }

  /// Set the map's angle in degrees.
  ///
  /// ## Parameters
  ///
  /// - [angle]: Angle in degrees (0..360) where 0 represents north.
  ///
  /// ## See also:
  ///
  /// - [tiltAngle] - The tilt angle complementary to view angle.
  /// - [viewAngle] - The camera's pitch angle.
  void setMapAngle(final double angle) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setRotationAngle',
      args: angle,
      dependencyId: _mapPointerId,
    );
  }

  /// Set the map's angle in degrees.
  ///
  /// This is a convenience setter that calls [setMapAngle] with the provided value.
  /// The angle must be between 0 and 360 degrees, where 0 represents north-up alignment.
  ///
  /// ## Parameters
  ///
  /// - [angle]: The map angle in degrees (0..360).
  ///
  /// ## See also:
  ///
  /// - [setMapAngle] - Set the map angle
  set mapAngle(final double angle) {
    setMapAngle(angle);
  }

  /// Set the tilt angle in degrees.
  ///
  /// The tilt angle equals 90 - [viewAngle].
  ///
  /// ## Parameters
  ///
  /// - [tiltAngle]: The tilt angle in degrees.
  ///
  /// ## See also:
  ///
  /// - [mapAngle] - The map's rotation angle.
  /// - [viewAngle] - The camera's pitch angle.
  void setTiltAngle(final double tiltAngle) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setTiltAngle',
      args: tiltAngle,
      dependencyId: _mapPointerId,
    );
  }

  /// Set the tilt angle in degrees.
  ///
  /// This is a convenience setter that calls [setTiltAngle] with the provided value.
  ///
  /// The tilt angle equals 90 - [viewAngle].
  ///
  /// ## Parameters
  ///
  /// - [tiltAngle]: The tilt angle in degrees.
  ///
  /// ## See also:
  ///
  /// - [mapAngle] - The map's rotation angle.
  set tiltAngle(final double tiltAngle) => setTiltAngle(tiltAngle);

  /// Set the camera's pitch angle in degrees.
  ///
  /// The value must be between 0 and 90 degrees, where 0 represents a top-down view.
  /// Does the opposite of [tiltAngle] since the two angles are complementary (tiltAngle = 90 - viewAngle).
  ///
  /// ## Parameters
  ///
  /// - [viewAngle]: The view angle in degrees (0..90).
  /// - [animated]: True to animate the change, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [mapAngle] - The map's rotation angle.
  /// - [tiltAngle] - The tilt angle complementary to view angle.
  /// - [viewAngle] getter - Get the current view angle.
  void setViewAngle(final double viewAngle, {final bool animated = false}) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setViewAngle',
      args: <String, Object>{'value': viewAngle, 'animated': animated},
      dependencyId: _mapPointerId,
    );
  }

  /// Set the camera's pitch angle in degrees.
  ///
  /// This is a convenience setter that calls [setViewAngle] with the provided value and no animation.
  /// The view angle must be between 0 and 90 degrees, where 0 represents a top-down view.
  ///
  /// ## Parameters
  ///
  /// - [viewAngle]: The view angle in degrees (0..90).
  ///
  /// ## See also:
  ///
  /// - [setViewAngle] - Set the view angle with optional animation.
  set viewAngle(final double viewAngle) => setViewAngle(viewAngle);

  /// Enable or disable cursor mode.
  ///
  /// When the cursor is enabled, map selection can be activated by calling
  /// [GemMapController.setCursorScreenPosition]. The cursor allows programmatic
  /// selection of map features. Note that both this property and
  /// [enableCursorRender] must be true for the cursor crosshair to be visible
  /// on screen. The cursor is automatically disabled by
  /// [GemMapController.startFollowingPosition].
  ///
  /// ## Parameters
  ///
  /// - [isEnabled]: (bool) True to enable the cursor, false to disable it.
  ///
  /// ## See also:
  ///
  /// - [enableCursorRender] - Control cursor visibility.
  /// - [cursorEnabled] - Check cursor state.
  /// - [GemMapController.setCursorScreenPosition] - Position the cursor.
  set enableCursor(final bool isEnabled) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'enableCursor',
      args: isEnabled,
      dependencyId: _mapPointerId,
    );
  }

  /// Set enabled touch gestures via bitfield.
  ///
  /// ## Parameters
  ///
  /// - [enabledTouchGesturesBitfield]: Packed [TouchGestures] bitfield.
  ///
  /// ## See also:
  ///
  /// - [TouchGestures] - Available gesture types.
  set touchGesturesStates(final int enabledTouchGesturesBitfield) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setTouchGesturesStates',
      args: enabledTouchGesturesBitfield,
      dependencyId: _mapPointerId,
    );
  }

  /// Set traffic visibility.
  ///
  /// ## Parameters
  ///
  /// - [isVisible]: True to show traffic, false to hide it.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] if the operation is successful.
  /// - [GemError.notFound] if the current map style doesn't contain a traffic layer.
  GemError setTrafficVisibility(final bool isVisible) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setTrafficVisibility',
      args: isVisible,
      dependencyId: _mapPointerId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Enable or disable cursor rendering.
  ///
  /// Controls whether the cursor crosshair is actually drawn on screen. Both
  /// this property and [enableCursor] must be true for the cursor to appear.
  /// Separating cursor functionality from rendering allows you to enable cursor
  /// selection without necessarily showing the visual indicator.
  ///
  /// ## Parameters
  ///
  /// - [value]: (bool) True to enable cursor rendering, false to disable.
  ///
  /// ## See also:
  ///
  /// - [enableCursor] - Enable cursor functionality.
  /// - [cursorRenderEnabled] - Check rendering state.
  set enableCursorRender(final bool value) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'enableCursorRender',
      args: value,
      dependencyId: _mapPointerId,
    );
  }

  /// Check whether the map scale is shown.
  ///
  /// ## Returns
  ///
  /// True if the map scale is shown, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [areMapScalesDrawnByUser] - Check rendering mode.
  /// - [mapScalePosition] - Get the scale position.
  bool get showMapScale {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'isMapScaleShown',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Show or hide the map scale.
  ///
  /// Controls whether the map scale bar is displayed on the map. The scale bar
  /// shows the correspondence between screen distance and real-world distance
  /// at the current zoom level. When [areMapScalesDrawnByUser] is false (the
  /// default), the SDK automatically draws the scale. When true, you must
  /// provide rendering instructions via [GemMapController.registerOnRenderMapScale].
  ///
  /// ## Parameters
  ///
  /// - [value]: (bool) True to show the map scale, false to hide it.
  ///
  /// ## See also:
  ///
  /// - [showMapScale] getter - Check current visibility.
  /// - [areMapScalesDrawnByUser] - Control SDK vs. custom rendering.
  /// - [mapScalePosition] - Position the scale on screen.
  /// - [GemMapController.registerOnRenderMapScale] - Custom scale rendering.
  set showMapScale(final bool value) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'showMapScale',
      args: value,
      dependencyId: _mapPointerId,
    );
  }

  /// Configure whether map scales are drawn by the user or the SDK.
  ///
  /// Only applicable when [showMapScale] is true. When false (the default),
  /// the SDK automatically renders the scale bar. When true, you must provide
  /// custom rendering instructions via [GemMapController.registerOnRenderMapScale].
  /// This setting applies globally to all map views in the application.
  ///
  /// ## Parameters
  ///
  /// - [value]: (bool) True for custom user-drawn scales, false for SDK rendering.
  ///
  /// ## See also:
  ///
  /// - [areMapScalesDrawnByUser] getter - Check current mode.
  /// - [showMapScale] - Show or hide the scale.
  /// - [GemMapController.registerOnRenderMapScale] - Callback for custom rendering.
  set areMapScalesDrawnByUser(final bool value) {
    staticMethod('MapView', 'setAreMapScalesDrawnByUser', args: value);
  }

  /// Get whether map scales are drawn by the user or SDK.
  ///
  /// ## Returns
  ///
  /// True if scales are drawn by the user, false if drawn by the SDK.
  ///
  /// ## See also:
  ///
  /// - [GemMapController.registerOnRenderMapScale] - Callback for custom rendering.
  bool get areMapScalesDrawnByUser {
    final OperationResult resultString = staticMethod(
      'MapView',
      'getAreMapScalesDrawnByUser',
    );

    return resultString['result'];
  }

  /// Set the map position for the scale overlay.
  ///
  /// ## Parameters
  ///
  /// - [value]: The map position as a [Rectangle<int>].
  set mapScalePosition(final Rectangle<int> value) {
    objectMethod(
      _pointerId,
      'MapViewPreferences',
      'setMapScalePosition',
      args: RectType<int>.fromRectangle(value),
      dependencyId: _mapPointerId,
    );
  }

  /// Get the map scale position.
  ///
  /// ## Returns
  ///
  /// The map scale position as a [Rectangle<int>].
  Rectangle<int> get mapScalePosition {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapViewPreferences',
      'getMapScalePosition',
      dependencyId: _mapPointerId,
    );

    final Rectangle<int> rect = Rectangle<int>(
      resultString['result']['x'] ?? 0,
      resultString['result']['y'] ?? 0,
      resultString['result']['width'] ?? 0,
      resultString['result']['height'] ?? 0,
    );

    return rect;
  }

  /// Releases native resources associated with this preferences instance.
  void dispose() {
    GemKitPlatform.instance.callDeleteObject(
      jsonEncode(<String, dynamic>{
        'class': 'MapViewPreferences',
        'id': _pointerId,
      }),
    );
  }
}
