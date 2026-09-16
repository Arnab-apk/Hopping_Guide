// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';
import 'package:magiclane_maps_flutter/src/map_view_listener.dart';

/// Provides comprehensive map view control and customization for interactive mapping.
///
/// An abstract class implemented by [GemMapController] that enables full control
/// over map visualization and interaction. Supports operations including viewport
/// management, camera positioning (zoom, rotate, tilt), animated transitions,
/// coordinate transformations, and map object selection (landmarks, routes, markers).
///
/// The map appearance is fully customizable through the [preferences] property,
/// allowing control over visible map elements, styling, colors, line widths, and
/// elements display settings.
///
/// Key capabilities include:
/// - Viewport management with physical pixel and ratio-based measurements
/// - [Camera] controls for [zoomLevel], [viewAngle], and [mapAngle]
/// - Coordinate transformations between screen and WGS84 geographic [Coordinates]
/// - Map centering on [Coordinates], [GeographicArea], [Route], and [RouteInstruction]
/// - [GemAnimation] support for smooth transitions
/// - Follow position mode for tracking current location with extensive [FollowPositionPreferences]
/// - Cursor-based selection of landmarks, routes, markers, and other map objects
/// - Highlight activation for visual emphasis of map elements
///
/// ## See also:
///
/// - [GemMapController] - Primary implementation of GemView
/// - [MapViewPreferences] - Customization options for map appearance and behavior
/// - [MapCamera] - Camera position and orientation controls
///
/// {@category Maps & 3D Scenes}
abstract class GemView extends EventHandler implements MapViewListener {
  ///@nodoc
  // ignore: unused_element
  GemView._() : _pointerId = -1, _mapId = -1;

  ///@nodoc
  @internal
  GemView.init(final int id, final int mapId) : _pointerId = id, _mapId = mapId;
  dynamic get pointerId => _pointerId;
  int get mapId => _mapId;

  final dynamic _pointerId;
  final int _mapId;
  Completer<Uint8List>? _captureAsImageCompleter;
  MapViewPreferences? _preferences;
  MapViewExtensions? _extensions;

  int _scaleWidthPrev = -1;
  int _scaleValuePrev = -1;
  String _scaleUnitsPrev = '';

  /// No-op default. Map view subclasses that maintain bridge-side state
  /// (event-handler registrations, in-flight timers) should override this
  /// to perform their teardown, and their [dispose] override should invoke
  /// it before [clearListeners].
  @override
  void nativeClear() {
    // Subclass override expected when bridge-side cleanup is required.
  }

  /// No-op default. Map view subclasses that hold callback fields should
  /// override this to null them, and their [dispose] override should invoke
  /// it after [nativeClear].
  @override
  void clearListeners() {
    // Subclass override expected when callback fields exist.
  }

  /// Releases native resources associated with this view.
  ///
  /// Should not be called directly by API users.
  ///
  ///@nodoc
  @internal
  Future<void> releaseView() async {
    try {
      await GemKitPlatform.instance
          .getChannel(mapId: _mapId)
          .invokeMethod<String>(
            'releaseView',
            jsonEncode(<String, dynamic>{'viewId': _pointerId}),
          );
    } catch (e) {
      //return Future.error(e.toString());
    }
  }

  /// Retrieves the current viewport dimensions in physical pixels.
  ///
  /// Returns a [Rectangle<int>] representing the visible area of the map view,
  /// measured in physical device pixels. The [Rectangle.left] and [Rectangle.top]
  /// fields are always 0, as coordinates are relative to the map view's top-left
  /// corner. The [Rectangle.width] and [Rectangle.height] represent the map view's
  /// dimensions in physical pixels.
  ///
  /// Physical pixels differ from Flutter's logical pixels. To convert to logical
  /// pixels, divide by the device pixel ratio obtained from
  /// [GemMapController.devicePixelSize].
  ///
  /// Use [transformScreenToWgsRect] to convert the viewport to geographic
  /// coordinates ([RectangleGeographicArea]). Use [viewportF] to get viewport
  /// dimensions as ratios relative to the parent screen.
  ///
  /// ## See also:
  ///
  /// - [viewportCenter] - Center point of the viewport
  /// - [viewportF] - Viewport in parent screen ratio
  /// - [transformScreenToWgsRect] - Convert viewport to geographic area
  Rectangle<int> get viewport {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getViewport',
    );

    final Rectangle<int> rect = Rectangle<int>(
      resultString['result']['x'] ?? 0,
      resultString['result']['y'] ?? 0,
      resultString['result']['width'] ?? 0,
      resultString['result']['height'] ?? 0,
    );

    return rect;
  }

  /// Calculates the center point of the current viewport.
  ///
  /// Returns a [Point<int>] representing the center coordinates of the visible
  /// map area in physical pixels. Coordinates are relative to the map view's
  /// top-left corner. This is calculated from the current [viewport] by taking
  /// the midpoint of its width and height.
  ///
  /// Useful for determining the default screen position when centering map
  /// operations or for UI element placement relative to the viewport center.
  ///
  /// ## See also:
  ///
  /// - [viewport] - Current viewport rectangle
  /// - [cursorScreenPosition] - Current cursor position (defaults to center)
  Point<int> get viewportCenter {
    final Rectangle<int> rc = viewport;
    return Point<int>(
      rc.left + (rc.width / 2).round(),
      rc.top + (rc.height / 2).round(),
    );
  }

  /// Retrieves the current viewport dimensions as ratios relative to the parent screen.
  ///
  /// Returns a [Rectangle<double>] where values are expressed as ratios (0.0 to 1.0)
  /// relative to the parent screen dimensions. Unlike [viewport] which returns
  /// physical pixel measurements, this provides proportional measurements useful
  /// for responsive layouts and relative positioning.
  ///
  /// For example, a [Rectangle<double>] with width 0.5 and height 0.5 indicates
  /// the map view occupies half the parent screen's width and height.
  ///
  /// ## See also:
  ///
  /// - [viewport] - Viewport in physical pixels
  /// - [viewportCenter] - Center point in physical pixels
  Rectangle<double> get viewportF {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getViewportF',
    );

    final Rectangle<double> rect = Rectangle<double>(
      resultString['result']['x'] ?? 0,
      resultString['result']['y'] ?? 0,
      resultString['result']['width'] ?? 0,
      resultString['result']['height'] ?? 0,
    );

    return rect;
  }

  /// Resets the cursor to its default position at the viewport center.
  ///
  /// Sets the cursor screen position to the center of the current [viewport],
  /// clearing any previous cursor placement. This restores the default state
  /// where map centering operations target the viewport center.
  ///
  /// This asynchronous method must be awaited to ensure the cursor update
  /// completes before subsequent operations.
  ///
  /// ## See also:
  ///
  /// - [setCursorScreenPosition] - Set cursor to a specific position
  /// - [viewportCenter] - Current viewport center coordinates
  /// - [cursorScreenPosition] - Current cursor position
  Future<void> resetMapSelection() async {
    await setCursorScreenPosition(
      Point<int>((viewport.width / 2).round(), (viewport.height / 2).round()),
    );
  }

  /// React to view events and call the listener functions.
  @override
  void handleEvent(final Map<dynamic, dynamic> arguments) {
    final String eventType = arguments['eventType'];

    if (eventType == 'mapViewResizedEvent') {
      final Rectangle<int> viewport = Rectangle<int>(
        arguments['rectLeft'],
        arguments['rectTop'],
        arguments['rectWidth'],
        arguments['rectHeight'],
      );
      onViewportResized(viewport);
    } else if (eventType == 'mapViewOnTouch') {
      final int ptx = arguments['point']['ptX'];
      final int pty = arguments['point']['ptY'];
      onTouch(Point<int>(ptx, pty));
    } else if (eventType == 'mapViewFollowPositionEntered') {
      onFollowPositionState(FollowPositionState.entered);
    } else if (eventType == 'mapViewFollowPositionExited') {
      onFollowPositionState(FollowPositionState.exited);
    } else if (eventType == 'onEnterTouchHandlerModifyFollowingPosition') {
      onTouchHandlerModifyFollowPosition(FollowPositionState.entered);
    } else if (eventType == 'onExitTouchHandlerModifyFollowingPosition') {
      onTouchHandlerModifyFollowPosition(FollowPositionState.exited);
    } else if (eventType == 'onPointerUp') {
      final int ptx = arguments['ptX'];
      final int pty = arguments['ptY'];
      onPointerUp(arguments['pointerId'], Point<int>(ptx, pty));
    } else if (eventType == 'onPointerDown') {
      final int ptx = arguments['ptX'];
      final int pty = arguments['ptY'];
      onPointerDown(arguments['pointerId'], Point<int>(ptx, pty));
    } else if (eventType == 'onPointerMove') {
      final int ptx = arguments['ptX'];
      final int pty = arguments['ptY'];
      onPointerMove(arguments['pointerId'], Point<int>(ptx, pty));
    } else if (eventType == 'onMove') {
      final int ptx = arguments['startPoint']['ptX'];
      final int pty = arguments['startPoint']['ptY'];
      final int ptendx = arguments['endPoint']['ptX'];
      final int ptendy = arguments['endPoint']['ptY'];
      onMove(Point<int>(ptx, pty), Point<int>(ptendx, ptendy));
    } else if (eventType == 'onTouchMove') {
      final int ptx = arguments['startPoint']['ptX'];
      final int pty = arguments['startPoint']['ptY'];
      final int ptendx = arguments['endPoint']['ptX'];
      final int ptendy = arguments['endPoint']['ptY'];
      onTouchMove(Point<int>(ptx, pty), Point<int>(ptendx, ptendy));
    } else if (eventType == 'onSwipe') {
      final int distX = arguments['distX'];
      final int distY = arguments['distY'];
      final double speed = arguments['speed'];
      onSwipe(distX, distY, speed);
    } else if (eventType == 'onPinchSwipe') {
      final int centerPosInPixX = arguments['centerPosInPixX'];
      final int centerPosInPixY = arguments['centerPosInPixY'];
      final double zoomSpeed = arguments['zoomSpeed'];
      final double rotateSpeed = arguments['rotateSpeed'];
      onPinchSwipe(
        Point<int>(centerPosInPixX, centerPosInPixY),
        zoomSpeed,
        rotateSpeed,
      );
    } else if (eventType == 'onPinch') {
      final int start1X = arguments['start1X'];
      final int start1Y = arguments['start1Y'];
      final int start2X = arguments['start2X'];
      final int start2Y = arguments['start2Y'];
      final int end1X = arguments['end1X'];
      final int end1Y = arguments['end1Y'];
      final int end2X = arguments['end2X'];
      final int end2Y = arguments['end2Y'];
      final int centerX = arguments['centerX'];
      final int centerY = arguments['centerY'];
      onPinch(
        Point<int>(start1X, start1Y),
        Point<int>(start2X, start2Y),
        Point<int>(end1X, end1Y),
        Point<int>(end2X, end2Y),
        Point<int>(centerX, centerY),
      );
    } else if (eventType == 'onTouchPinch') {
      final int start1X = arguments['start1X'];
      final int start1Y = arguments['start1Y'];
      final int start2X = arguments['start2X'];
      final int start2Y = arguments['start2Y'];
      final int end1X = arguments['end1X'];
      final int end1Y = arguments['end1Y'];
      final int end2X = arguments['end2X'];
      final int end2Y = arguments['end2Y'];
      onTouchPinch(
        Point<int>(start1X, start1Y),
        Point<int>(start2X, start2Y),
        Point<int>(end1X, end1Y),
        Point<int>(end2X, end2Y),
      );
    } else if (eventType == 'mapViewOnLongDown') {
      final int ptx = arguments['ptX'];
      final int pty = arguments['ptY'];
      onLongPress(Point<int>(ptx, pty));
    } else if (eventType == 'onDoubleTouch') {
      final int ptx = arguments['ptX'];
      final int pty = arguments['ptY'];
      onDoubleTouch(Point<int>(ptx, pty));
    } else if (eventType == 'onTwoTouches') {
      final int ptx = arguments['ptX'];
      final int pty = arguments['ptY'];
      onTwoTouches(Point<int>(ptx, pty));
    } else if (eventType == 'onTwoDoubleTouches') {
      final int ptx = arguments['ptX'];
      final int pty = arguments['ptY'];
      onTwoDoubleTouches(Point<int>(ptx, pty));
    } else if (eventType == 'onMapAngleUpdate') {
      final double angle = arguments['angle'];
      onMapAngleUpdate(angle);
    } else if (eventType == 'onMarkerRender') {
      onMarkerRender(arguments);
    } else if (eventType == 'onViewRendered') {
      onViewRendered(arguments);
    } else if (eventType == 'onShove') {
      final double pointersAngleDeg = arguments['pointersAngleDeg'];
      final int initialX = arguments['initialX'];
      final int initialY = arguments['initialY'];
      final int startX = arguments['startX'];
      final int startY = arguments['startY'];
      final int endX = arguments['endX'];
      final int endY = arguments['endY'];

      onShove(
        pointersAngleDeg,
        Point<int>(initialX, initialY),
        Point<int>(startX, startY),
        Point<int>(endX, endY),
      );
    } else if (arguments['eventType'] == 'onMapCaptured') {
      _captureAsImageCompleter!.complete(
        Uint8List.fromList(base64Decode(arguments['buffer'])),
      );
      _captureAsImageCompleter = null;
    } else if (arguments['eventType'] == 'renderMapScale') {
      final int scaleWidth = arguments['scaleWidth'];
      final String scaleValueStr = arguments['scaleValue'];
      final int? scaleValue = int.tryParse(scaleValueStr);
      if (scaleValue == null) {
        return;
      }
      final String scaleUnits = arguments['scaleUnits'];

      if (_scaleWidthPrev == scaleWidth &&
          _scaleValuePrev == scaleValue &&
          _scaleUnitsPrev == scaleUnits) {
        return;
      }
      onRenderMapScale(scaleWidth, scaleValue, scaleUnits);
      _scaleWidthPrev = scaleWidth;
      _scaleValuePrev = scaleValue;
      _scaleUnitsPrev = scaleUnits;
    } else if (eventType == 'onCursorSelectionUpdatedLandmarks') {
      final int objectId = arguments['list'];
      final LandmarkList gemList = LandmarkList.init(objectId);
      final List<Landmark> list = gemList.toList();
      onCursorSelectionUpdatedLandmarks(list);
    } else if (eventType == 'onCursorSelectionUpdatedOverlayItems') {
      final int objectId = arguments['list'];
      final OverlayItemList gemList = OverlayItemList.init(objectId);
      final List<OverlayItem> list = gemList.toList();
      onCursorSelectionUpdatedOverlayItems(list);
    } else if (eventType == 'onCursorSelectionUpdatedTrafficEvents') {
      final int objectId = arguments['list'];
      final TrafficEventList gemList = TrafficEventList.init(objectId);
      final List<TrafficEvent> list = gemList.toList();
      onCursorSelectionUpdatedTrafficEvents(list);
    } else if (eventType == 'onCursorSelectionUpdatedRoutes') {
      final int objectId = arguments['list'];
      final RouteList gemList = RouteList.init(objectId);
      final List<Route> list = gemList.toList();
      onCursorSelectionUpdatedRoutes(list);
    } else if (eventType == 'onCursorSelectionMarkerMatches') {
      final int objectId = arguments['list'];
      final MarkerMatchList gemList = MarkerMatchList.init(objectId);
      final List<MarkerMatch> list = gemList.toList();
      onCursorSelectionUpdatedMarkers(list);
    } else if (eventType == 'onCursorSelectionPath') {
      final int objectId = arguments['list'];
      final Path path = Path.init(objectId);
      onCursorSelectionUpdatedPath(path);
    } else if (eventType == 'onCursorSelectionMapSceneObject') {
      onCursorSelectionUpdatedMapSceneObject(
        MapSceneObject.getDefPositionTracker(),
      );
    } else if (eventType == 'onHoveredMapLabelHighlightedLandmark') {
      final int objectId = arguments['obj'];
      final Landmark obj = Landmark.init(objectId);
      onHoveredMapLabelHighlightedLandmark(obj);
    } else if (eventType == 'onHoveredMapLabelHighlightedOverlayItem') {
      final int objectId = arguments['obj'];
      final OverlayItem obj = OverlayItem.init(objectId);
      onHoveredMapLabelHighlightedOverlayItem(obj);
    } else if (eventType == 'onHoveredMapLabelHighlightedTrafficEvent') {
      final int objectId = arguments['obj'];
      final TrafficEvent obj = TrafficEvent.init(objectId);
      onHoveredMapLabelHighlightedTrafficEvent(obj);
    } else if (eventType == 'onSetMapStyle') {
      final int id = arguments['id'];
      final String stylePath = arguments['stylePath'];
      final bool viaApi = arguments['viaApi'];
      onSetMapStyle(id, stylePath, viaApi);
    } else {
      gemSdkLogger.log(
        Level.WARNING,
        'Unknown event subtype: $eventType in GemView',
      );
    }
  }

  /// Retrieves the current map camera for advanced positioning and orientation control.
  ///
  /// Returns a [MapCamera] object that provides fine-grained control over the
  /// camera's 3D position (x, y, z coordinates) and orientation (quaternion).
  /// The camera determines the viewing perspective of the map, including the
  /// observer's location in 3D space and the direction they are looking.
  ///
  /// Use the returned [MapCamera] to:
  /// - Get or set the camera's absolute position and orientation
  /// - Store and restore specific camera states
  /// - Generate positions relative to geographic targets
  /// - Perform complex camera movements not available through standard centering methods
  ///
  /// For simple operations like centering on coordinates or adjusting zoom level,
  /// consider using the dedicated centering methods instead.
  ///
  /// ## See also:
  ///
  /// - [MapCamera] - Camera position and orientation controls
  /// - [centerOnCoordinates] - Center map on coordinates with zoom and angles
  /// - [centerOnArea] - Center map on a geographic area
  MapCamera get camera {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getCamera',
    );

    return MapCamera.init(resultString['result'], _mapId);
  }

  /// Sets the map camera to a specific position and orientation.
  ///
  /// Replaces the current camera with the provided [MapCamera] object,
  /// immediately updating the map view's position and orientation. This allows
  /// for precise 3D camera control that may not be achievable through standard
  /// centering and zoom methods.
  ///
  /// ## Parameters
  ///
  /// - [camera]: The [MapCamera] object containing the desired position and orientation
  ///
  /// ## See also:
  ///
  /// - [MapCamera] - Camera position and orientation controls
  /// - [camera] - Getter to retrieve the current camera
  set camera(MapCamera camera) {
    objectMethod(_pointerId, 'MapView', 'setCamera', args: camera.pointerId);
  }

  /// Terminates the current map animation.
  ///
  /// Immediately stops any ongoing animated transition triggered by centering
  /// methods ([centerOnCoordinates], [centerOnArea], etc.) with animation enabled.
  /// By default, the map instantly completes the animation, jumping to the target
  /// destination. Set [jumpToDestination] to `false` to stop at the current
  /// intermediate position instead.
  ///
  /// Use [isAnimationInProgress] to check if an animation is active before
  /// calling this method.
  ///
  /// ## Parameters
  ///
  /// - [jumpToDestination]: If `true`, completes the animation instantly by jumping to the target. If `false`, stops at the current position. Defaults to `true`
  ///
  /// ## See also:
  ///
  /// - [isAnimationInProgress] - Check if animation is active
  /// - [centerOnCoordinates] - Center with optional animation
  /// - [centerOnArea] - Center area with optional animation
  void skipAnimation({final bool jumpToDestination = true}) {
    objectMethod(
      _pointerId,
      'MapView',
      'skipAnimation',
      args: jumpToDestination,
    );
  }

  /// Checks whether a map animation is currently in progress.
  ///
  /// Returns `true` if the map view is performing an animated transition, such
  /// as those triggered by [centerOnCoordinates], [centerOnArea], or other
  /// centering methods with animation enabled. Returns `false` when no animation
  /// is active.
  ///
  /// Use [skipAnimation] to immediately complete the current animation or
  /// [isCameraMoving] to check if the camera is moving for any reason (including
  /// non-animated movements).
  ///
  /// ## See also:
  ///
  /// - [skipAnimation] - Terminate the current animation instantly
  /// - [isCameraMoving] - Check if camera is moving (animated or not)
  bool get isAnimationInProgress {
    final OperationResult val = objectMethod(
      _pointerId,
      'MapView',
      'isAnimationInProgress',
    );

    return val['result'];
  }

  /// Centers the map view on specified WGS84 geographic coordinates.
  ///
  /// Positions the map so the specified [coords] appear at the target screen
  /// location with optional zoom level, rotation, and viewing angle adjustments.
  /// If no screen position is specified, the coordinates center at the current
  /// cursor position (defaulting to viewport center).
  ///
  /// The operation can be animated using the [animation] parameter for smooth
  /// transitions. Use [skipAnimation] to immediately complete any ongoing animation.
  ///
  /// ## Parameters
  ///
  /// - [coords]: The WGS84 coordinates (latitude, longitude, optional altitude) to center on
  /// - [zoomLevel]: Zoom level (higher values = more zoomed in). Use `-1` for automatic selection based on context. Defaults to `-1`
  /// - [screenPosition]: Target screen position in physical pixels where the coordinates should project, relative to the map view's top-left corner. If `null`, uses the current cursor position. Defaults to `null`
  /// - [animation]: Animation settings for the centering operation. If `null`, centering occurs instantly. Defaults to `null`
  /// - [mapAngle]: Map rotation angle in degrees (0-360), where 0 represents north-up alignment. If `null`, rotation remains unchanged. Defaults to `null`
  /// - [viewAngle]: Camera pitch angle in degrees (0-90), where 0 is top-down view and 90 is horizon view. If `null`, pitch remains unchanged. Defaults to `null`
  /// - [slippyZoomLevel]: Tile-based zoom level for specific tile system compatibility. Use `-1.0` for automatic selection. Defaults to `-1.0`
  ///
  /// ## See also:
  ///
  /// - [centerOnArea] - Center on a geographic area rectangle
  /// - [centerOnAreaRect] - Center area within a specific screen rectangle
  /// - [skipAnimation] - Stop ongoing animations
  /// - [transformWgsToScreen] - Convert geographic to screen coordinates
  void centerOnCoordinates(
    final Coordinates coords, {
    final int zoomLevel = -1,
    final Point<int>? screenPosition,
    final GemAnimation? animation,
    double? mapAngle,
    double? viewAngle,
    final double slippyZoomLevel = -1.0,
  }) {
    if (viewAngle != null && (viewAngle - viewAngle.toInt() == 0)) {
      viewAngle -= 0.0000000001;
    }
    if (mapAngle != null && (mapAngle - mapAngle.toInt() == 0)) {
      mapAngle -= 0.0000000001;
    }
    objectMethod(
      _pointerId,
      'MapView',
      'centerOnCoordinates',
      args: <String, Object>{
        'coords': coords,
        'zoomLevel': zoomLevel,
        'slippyZoomLevel': slippyZoomLevel,
        if (screenPosition != null) 'xy': XyType<int>.fromPoint(screenPosition),
        if (animation != null) 'animation': animation,
        if (mapAngle != null) 'mapAngle': mapAngle,
        if (viewAngle != null) 'viewAngle': viewAngle,
      },
    );
  }

  /// Centers the map view on a specified geographic area rectangle.
  ///
  /// Positions the map to display the entire [GeographicArea] defined
  /// by top-left and bottom-right coordinates. The zoom level automatically adjusts
  /// to fit the area unless explicitly specified. The area centers at the target
  /// screen position or cursor location.
  ///
  /// Use [centerOnAreaRect] for finer control over which screen region displays
  /// the area, particularly useful for adding padding or positioning the area
  /// within a specific viewport region.
  ///
  /// ## Parameters
  ///
  /// - [area]: The geographic area to center on.
  /// - [zoomLevel]: Zoom level for the centered view. A greater zoom level means closer to the ground. Use `-1` for automatic selection to fit the entire area. Defaults to `-1`
  /// - [screenPosition]: Target screen position in physical pixels where the area center should project, relative to the map view's top-left corner. If `null`, uses the current cursor position. Defaults to `null`
  /// - [animation]: Animation settings for the centering operation. If `null`, centering occurs instantly. Defaults to `null`
  ///
  /// ## See also:
  ///
  /// - [centerOnCoordinates] - Center on a single coordinate point
  /// - [centerOnAreaRect] - Center area within a specific screen rectangle
  /// - [transformScreenToWgsRect] - Convert screen rectangle to geographic area
  void centerOnArea(
    final GeographicArea area, {
    final int zoomLevel = -1,
    final Point<int>? screenPosition,
    final GemAnimation? animation,
  }) {
    objectMethod(
      _pointerId,
      'MapView',
      'centerOnArea',
      args: <String, Object?>{
        'area': area,
        'zoomLevel': zoomLevel,
        if (screenPosition != null) 'xy': XyType<int>.fromPoint(screenPosition),
        if (animation != null) 'animation': animation,
      },
    );
  }

  /// Centers a geographic area within a specified screen rectangle region.
  ///
  /// Positions the map to display the [GeographicArea] within the bounds
  /// of a target screen rectangle [viewRc]. This allows precise control over which
  /// portion of the screen displays the geographic area, useful for implementing
  /// padding around routes or landmarks, or positioning content to avoid overlap with
  /// UI elements put on top.
  ///
  /// The zoom level automatically adjusts to fit the area within the specified
  /// rectangle unless explicitly set. Smaller [viewRc] dimensions result in more
  /// zoomed-out views to fit the area.
  ///
  /// For centering with padding, calculate [viewRc] by adjusting viewport bounds:
  /// subtract padding from each side using coordinate transformations. Make sure the
  /// [viewRc] is measured in physical pixels relative to the map view's top-left corner.
  /// Convert logical pixels to physical pixels using the device pixel ratio from
  /// [GemMapController.devicePixelSize].
  ///
  /// ## Parameters
  ///
  /// - [area]: The geographic area to center
  /// - [viewRc]: Target screen rectangle in physical pixels where the area should be displayed, relative to the map view's top-left corner. The area will be scaled to fit within this rectangle
  /// - [zoomLevel]: Zoom level for the centered view. Use `-1` for automatic selection to fit the area within [viewRc]. Defaults to `-1`
  /// - [animation]: Animation settings for the centering operation. If `null`, centering occurs instantly. Defaults to `null`
  ///
  /// ## See also:
  ///
  /// - [centerOnArea] - Center area at a single screen point
  /// - [centerOnCoordinates] - Center on coordinate point
  /// - [getOptimalRoutesCenterViewport] - Calculate optimal viewport for routes
  /// - [getOptimalHighlightCenterViewport] - Calculate optimal viewport for highlights
  void centerOnAreaRect(
    final GeographicArea area, {
    required final Rectangle<int> viewRc,
    final int zoomLevel = -1,
    final GemAnimation? animation,
  }) {
    objectMethod(
      _pointerId,
      'MapView',
      'centerOnAreaRect',
      args: <String, Object?>{
        'area': area,
        'zoomLevel': zoomLevel,
        'viewRc': RectType<int>.fromRectangle(viewRc),
        if (animation != null) 'animation': animation,
      },
    );
  }

  /// Retrieves the cursor's current position in screen coordinates.
  ///
  /// Returns a [Point<int>] representing the cursor's position in physical pixels,
  /// measured relative to the map view's top-left corner (parent screen coordinates).
  /// By default, the cursor is positioned at the center of the viewport ([viewportCenter]).
  ///
  /// The cursor position determines the reference point for map selection operations.
  /// When calling selection methods like [cursorSelectionLandmarks],
  /// [cursorSelectionRoutes], or [cursorSelectionMarkers], the SDK identifies
  /// map elements at the cursor's location. Update the cursor position using
  /// [setCursorScreenPosition] before performing selections.
  ///
  /// The cursor position also affects centering operations. When [centerOnCoordinates]
  /// or similar methods are called without a `screenPosition` parameter, the map
  /// centers the target coordinates at the cursor's current position.
  ///
  /// ## See also:
  ///
  /// - [cursorWgsPosition] - Cursor position in WGS84 geographic coordinates
  /// - [setCursorScreenPosition] - Update cursor position for selection
  /// - [resetMapSelection] - Reset cursor to viewport center
  /// - [viewportCenter] - Default cursor position
  Point<int> get cursorScreenPosition {
    final OperationResult val = objectMethod(
      _pointerId,
      'MapView',
      'getCursorScreenPosition',
    );
    final XyType<int> retVal = XyType<int>.fromJson(val['result']);
    return retVal.point;
  }

  /// Retrieves the cursor's current position in WGS84 geographic coordinates.
  ///
  /// Returns [Coordinates] representing the cursor's location as latitude, longitude,
  /// and optionally altitude in the WGS84 coordinate system. This represents the
  /// geographic location on Earth corresponding to the cursor's screen position.
  ///
  /// If the applied map style includes elevation data and terrain topography is
  /// loaded, the returned coordinates include altitude information. Check terrain
  /// support using the [hasTerrainTopography] getter.
  ///
  /// Use [cursorScreenPosition] to get the cursor's position in physical pixels
  /// instead of geographic coordinates.
  ///
  /// ## See also:
  ///
  /// - [cursorScreenPosition] - Cursor position in physical screen pixels
  /// - [transformScreenToWgs] - Convert any screen point to WGS coordinates
  /// - [setCursorScreenPosition] - Update cursor position
  Coordinates get cursorWgsPosition {
    final OperationResult val = objectMethod(
      _pointerId,
      'MapView',
      'getCursorWgsPosition',
    );
    return Coordinates.fromJson(val['result']);
  }

  /// Deactivates follow position mode, stopping position tracking.
  ///
  /// Stops the camera from automatically tracking and following the device's
  /// real or simulated position. After calling this method, the map view remains
  /// stationary at its current position until manually moved or a new centering
  /// operation is initiated.
  ///
  /// Set [restoreCameraMode] to `true` to additionally reset the camera to its
  /// default zoom level and view angle used in follow position mode, providing
  /// a consistent viewing state.
  ///
  /// ## Parameters
  ///
  /// - [restoreCameraMode]: If `true`, resets zoom level and view angle to follow position defaults. If `false`, maintains current camera settings. Defaults to `false`
  ///
  /// ## See also:
  ///
  /// - [isFollowingPosition] - Check if follow mode is active
  /// - [getIsFollowingPosition] - Check follow status with animation control
  /// - [restoreFollowingPosition] - Restore to default auto-zoom follow mode
  void stopFollowingPosition({bool restoreCameraMode = false}) {
    objectMethod(
      _pointerId,
      'MapView',
      'stopFollowingPosition',
      args: restoreCameraMode,
    );
  }

  /// Checks if the camera is actively following the current position.
  ///
  /// Returns `true` when the map is in follow position mode, tracking the device's
  /// real or simulated position. Returns `false` when position tracking is inactive.
  ///
  /// This getter considers the camera to be following only when it is actively
  /// tracking the position, excluding animation phases ("flying" to position).
  /// Use [getIsFollowingPosition] with the `alsoFlyToPosition` parameter for more
  /// control over this distinction.
  ///
  /// Follow position mode is activated using [startFollowingPosition] and can be stopped
  /// with [stopFollowingPosition].
  ///
  /// ## See also:
  ///
  /// - [getIsFollowingPosition] - Check follow status with animation control
  /// - [stopFollowingPosition] - Deactivate follow position mode
  /// - [isFollowingPositionTouchHandlerModified] - Check if user adjusted follow mode
  /// - [isDefaultFollowingPosition] - Check if in default auto-zoom follow mode
  bool get isFollowingPosition {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'isFollowingPosition',
      args: true,
    );

    return resultString['result'];
  }

  /// Checks if the camera is following the current position with optional animation consideration.
  ///
  /// Determines whether the map is in follow position mode, with configurable
  /// handling of animation phases. Unlike [isFollowingPosition] which excludes
  /// animation phases, this method allows control over whether the "flying to
  /// position" animation is considered as part of follow position mode.
  ///
  /// Set [alsoFlyToPosition] to `true` to include animation phases, or `false`
  /// to only return `true` when actively tracking without animation.
  ///
  /// ## Parameters
  ///
  /// - [alsoFlyToPosition]: If `true`, considers the map in follow position mode even during animation to position. If `false`, only returns `true` when actively tracking without ongoing animation
  ///
  /// ## Returns
  ///
  /// - `true` if the map is currently following the current position (based on [alsoFlyToPosition] setting), `false` otherwise
  ///
  /// ## See also:
  ///
  /// - [isFollowingPosition] - Simple check excluding animation phases
  /// - [stopFollowingPosition] - Deactivate follow position mode
  /// - [restoreFollowingPosition] - Restore to default auto-zoom follow mode
  bool getIsFollowingPosition(bool alsoFlyToPosition) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'isFollowingPosition',
      args: alsoFlyToPosition,
    );

    return resultString['result'];
  }

  /// Checks if follow position mode has been manually adjusted by user input.
  ///
  /// Returns `true` when the camera is following the current position from a
  /// fixed relative position that has been modified by user gestures (such as
  /// dragging or pinching during follow mode). Returns `false` if follow position
  /// mode is either inactive or remains in its default auto-zoom configuration.
  ///
  /// Use this to distinguish between default automatic following and user-customized
  /// following behavior. After manual adjustment, the camera maintains a fixed
  /// relative position to the tracked location rather than automatically adjusting
  /// zoom and angle.
  ///
  /// ## Returns
  ///
  /// - `true` if follow position mode is active and has been manually adjusted by the user, `false` if in default state or inactive
  ///
  /// ## See also:
  ///
  /// - [isDefaultFollowingPosition] - Check if in default auto-zoom follow mode
  /// - [restoreFollowingPosition] - Restore to default follow mode from adjusted state
  /// - [isFollowingPosition] - Check if follow mode is active
  bool get isFollowingPositionTouchHandlerModified {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'isFollowingPositionTouchHandlerModified',
    );

    return resultString['result'];
  }

  /// Checks if follow position mode is active in its default auto-zoom configuration.
  ///
  /// Returns `true` when the camera is following the current position with the
  /// default automatic zoom and angle adjustments. Returns `false` if follow
  /// position mode is inactive or has been manually adjusted by user input to
  /// maintain a fixed relative camera position.
  ///
  /// This is the most restrictive follow position check, requiring both active
  /// tracking and default configuration. Use [isFollowingPosition] to check
  /// for any active follow mode regardless of configuration.
  ///
  /// ## Returns
  ///
  /// - `true` if in default auto-zoom follow position mode, `false` if manually adjusted or inactive
  ///
  /// ## See also:
  ///
  /// - [isFollowingPosition] - Check if follow mode is active (any configuration)
  /// - [isFollowingPositionTouchHandlerModified] - Check if user has adjusted follow mode
  /// - [restoreFollowingPosition] - Restore to default auto-zoom follow mode
  bool get isDefaultFollowingPosition {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'isDefaultFollowingPosition',
    );

    return resultString['result'];
  }

  /// Updates the cursor's screen position for map selection.
  ///
  /// Sets the cursor to the specified screen coordinates, enabling selection of
  /// map elements (landmarks, routes, markers, overlayitems, paths, streets, traffic events) at
  /// that location. After setting the cursor position, use selection methods like
  /// [cursorSelectionLandmarks], [cursorSelectionRoutes], [cursorSelectionMarkers],
  /// [cursorSelectionOverlayItems], [cursorSelectionPath], [cursorSelectionStreets],
  /// or [cursorSelectionTrafficEvents] to retrieve selected elements.
  ///
  /// This asynchronous method must be awaited before querying selections to ensure
  /// the cursor update completes. Failing to await may result in empty selection
  /// lists or selections from the previous cursor position.
  ///
  /// The cursor position also influences centering operations when no explicit
  /// screen position is provided to methods like [centerOnCoordinates].
  ///
  /// ## Parameters
  ///
  /// - [screenPosition]: The target cursor position in physical pixels, relative to the map view's top-left corner
  ///
  /// ## See also:
  ///
  /// - [cursorScreenPosition] - Get current cursor position
  /// - [cursorSelectionLandmarks] - Get landmarks at cursor position
  /// - [cursorSelectionRoutes] - Get routes at cursor position
  /// - [resetMapSelection] - Reset cursor to viewport center
  Future<void> setCursorScreenPosition(final Point<int> screenPosition) async {
    // This method needs to be async
    await GemKitPlatform.instance
        .getChannel(mapId: mapId)
        .invokeMethod<String>(
          'callObjectMethod',
          jsonEncode(<String, dynamic>{
            'id': _pointerId,
            'class': 'MapView',
            'method': 'setCursorScreenPosition',
            'args': XyType<int>(x: screenPosition.x, y: screenPosition.y),
          }),
        );
  }

  /// Converts screen coordinates to WGS84 geographic coordinates.
  ///
  /// Transforms a screen position in physical pixels to its corresponding geographic
  /// location on Earth (latitude, longitude, and optionally altitude). Screen
  /// coordinates are measured from the map view's top-left corner.
  ///
  /// If the applied map style includes elevation data and terrain topography is
  /// loaded, the returned [Coordinates] include altitude information above sea
  /// level. Check terrain support using the [hasTerrainTopography] getter.
  ///
  /// ## Parameters
  ///
  /// - [screenCoordinates]: Screen position in physical pixels, relative to the map view's top-left corner
  ///
  /// ## Returns
  ///
  /// - WGS84 coordinates (latitude, longitude, optional altitude) corresponding to the screen position
  ///
  /// ## See also:
  ///
  /// - [transformWgsToScreen] - Convert geographic coordinates to screen coordinates
  /// - [transformScreenToWgsRect] - Convert screen rectangle to geographic area
  /// - [cursorWgsPosition] - Get cursor position in geographic coordinates
  Coordinates transformScreenToWgs(final Point<int> screenCoordinates) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'transformScreenToWgs',
      args: XyType<int>.fromPoint(screenCoordinates),
    );

    final Coordinates coords = Coordinates.fromJson(resultString['result']);
    if (coords.altitude != null &&
        coords.altitude! > -0.0001 &&
        coords.altitude! < 0.0001) {
      coords.altitude = 0;
    }

    return coords;
  }

  /// Converts a screen rectangle to a geographic area.
  ///
  /// Transforms a rectangular region in screen coordinates (physical pixels) to
  /// its corresponding [RectangleGeographicArea] defined by WGS84 coordinates.
  /// If no rectangle is specified, transforms the entire [viewport] to geographic
  /// coordinates.
  ///
  /// The input rectangle is automatically clipped to the viewport bounds. Useful
  /// for determining what geographic region is visible in a specific screen area,
  /// such as the visible map extent or a custom UI region.
  ///
  /// ## Parameters
  ///
  /// - [screenRect]: Screen rectangle in physical pixels to convert. If `null`, uses the entire [viewport]. The rectangle is clipped against viewport bounds. Defaults to `null`
  ///
  /// ## Returns
  ///
  /// - [RectangleGeographicArea] with top-left and bottom-right WGS84 coordinates corresponding to the screen rectangle
  ///
  /// ## See also:
  ///
  /// - [transformScreenToWgs] - Convert single screen point to coordinates
  /// - [transformWgsToScreen] - Convert geographic coordinates to screen position
  /// - [viewport] - Current viewport rectangle
  RectangleGeographicArea transformScreenToWgsRect({
    Rectangle<int>? screenRect,
  }) {
    screenRect ??= const Rectangle<int>(0, 0, 0, 0);
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'transformScreenToWgsRect',
      args: RectType<int>.fromRectangle(screenRect),
    );

    return RectangleGeographicArea.fromJson(resultString['result']);
  }

  /// Converts WGS84 geographic coordinates to screen coordinates.
  ///
  /// Transforms a geographic location (latitude, longitude, altitude) to its
  /// corresponding screen position in physical pixels. The screen position is
  /// measured from the map view's top-left corner.
  ///
  /// This transformation depends on the current camera state, including position,
  /// zoom level, map angle, and view angle. The same geographic coordinates will
  /// project to different screen positions as the camera moves or rotates.
  ///
  /// ## Parameters
  ///
  /// - [coords]: WGS84 geographic coordinates to convert
  ///
  /// ## Returns
  ///
  /// - Screen position in physical pixels, relative to the map view's top-left corner
  ///
  /// ## See also:
  ///
  /// - [transformScreenToWgs] - Convert screen coordinates to geographic coordinates
  /// - [transformWgsListToScreen] - Convert multiple coordinates at once
  /// - [transformScreenToWgsRect] - Convert screen rectangle to geographic area
  Point<int> transformWgsToScreen(final Coordinates coords) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'transformWgsToScreen',
      args: coords,
    );

    return XyType<int>.fromJson(resultString['result']).point;
  }

  /// Checks if a map scene object is visible within a specified viewport rectangle.
  ///
  /// Determines whether the given [MapSceneObject] appears within the bounds
  /// of the specified screen rectangle. This performs a geometric bounds check
  /// only and does not consider the object's visibility settings or whether it
  /// is actually rendered on screen.
  ///
  /// If no rectangle is provided, checks visibility against the entire screen.
  /// If no scene object is provided, uses the default position tracker.
  ///
  /// ## Parameters
  ///
  /// - [mapSceneObject]: The map scene object to test for visibility. If `null`, uses the default position tracker. Defaults to `null`
  /// - [rect]: Viewport rectangle in physical pixels for visibility testing, relative to the map view's top-left corner. If `null`, uses the entire screen. Defaults to `null`
  ///
  /// ## Returns
  ///
  /// - `true` if the scene object's bounds intersect with the specified viewport, `false` otherwise
  ///
  /// ## See also:
  ///
  /// - [MapSceneObject] - Map scene objects that can be tested for visibility
  /// - [viewport] - Current viewport rectangle
  bool checkObjectVisibility({
    MapSceneObject? mapSceneObject,
    Rectangle<int>? rect,
  }) {
    rect ??= const Rectangle<int>(0, 0, 0, 0);
    mapSceneObject ??= MapSceneObject.getDefPositionTracker();

    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'checkObjectVisibility',
      args: <String, dynamic>{
        'obj': mapSceneObject.pointerId,
        'rc': RectType<int>.fromRectangle(rect),
      },
    );

    return resultString['result'];
  }

  /// Checks whether the map camera is currently moving.
  ///
  /// Returns `true` if the camera is in motion, regardless of the cause (animated
  /// transitions, user gestures, follow position mode, or programmatic movement).
  /// Returns `false` when the camera is stationary.
  ///
  /// This differs from [isAnimationInProgress] which only detects programmatically
  /// triggered animations. Use this method to determine if the view is stable
  /// before performing operations that require a stationary camera.
  ///
  /// ## See also:
  ///
  /// - [isAnimationInProgress] - Check only for programmatic animations
  /// - [skipAnimation] - Stop animated transitions
  bool get isCameraMoving {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'isCameraMoving',
    );

    return resultString['result'];
  }

  /// Converts multiple WGS84 geographic coordinates to screen coordinates in batch.
  ///
  /// Transforms a list of geographic locations (latitude, longitude, altitude)
  /// to their corresponding screen positions in physical pixels. This is more
  /// efficient than calling [transformWgsToScreen] repeatedly for multiple
  /// coordinates.
  ///
  /// Screen coordinates are measured from the map view's top-left corner. The
  /// transformation depends on the current camera state, including position,
  /// zoom level, map angle, and view angle.
  ///
  /// ## Parameters
  ///
  /// - [coords]: List of WGS84 geographic coordinates to convert
  ///
  /// ## Returns
  ///
  /// - List of screen positions in physical pixels, in the same order as the input coordinates
  ///
  /// ## See also:
  ///
  /// - [transformWgsToScreen] - Convert single coordinate to screen position
  /// - [transformScreenToWgs] - Convert screen position to geographic coordinates
  List<Point<int>> transformWgsListToScreen(final List<Coordinates> coords) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'transformWgsListToScreen',
      args: coords,
    );

    final List<dynamic> listJson = resultString['result'];
    final List<Point<int>> retList = listJson
        .map(
          (final dynamic categoryJson) =>
              XyType<int>.fromJson(categoryJson).point,
        )
        .toList();
    return retList;
  }

  /// Retrieves the map view's customization preferences.
  ///
  /// Returns a [MapViewPreferences] object that provides comprehensive control
  /// over map appearance and behavior. Through this object, you can customize
  /// visible map elements, styling, colors, line widths, landmark display
  /// settings, and many other visual aspects of the map view.
  ///
  /// Allows the display of various elements such as [Landmark], [Route],
  /// [Marker], [OverlayItem], [Path] via the specialized collections and settings.
  ///
  /// Changes made to the preferences object immediately affect the map view's
  /// rendering and behavior.
  ///
  /// ## See also:
  ///
  /// - [MapViewPreferences] - Comprehensive map customization settings
  MapViewPreferences get preferences {
    if (_preferences == null) {
      final OperationResult resultString = objectMethod(
        _pointerId,
        'MapView',
        'preferences',
      );

      _preferences = MapViewPreferences.init(
        resultString['result'],
        _mapId,
        _pointerId,
      );
      return _preferences!;
    }
    return _preferences!;
  }

  /// Aligns the map to north-up orientation.
  ///
  /// Rotates the map so that north points directly upward (0 degrees [mapAngle]).
  /// The operation can be animated for a smooth transition or applied instantly.
  ///
  /// ## Parameters
  ///
  /// - [animation]: Animation settings for the rotation operation. If `null`, alignment occurs instantly. Defaults to `null`
  ///
  /// ## See also:
  ///
  /// - [centerOnCoordinates] - Center map with custom rotation angle
  void alignNorthUp({final GemAnimation? animation}) {
    objectMethod(_pointerId, 'MapView', 'alignNorthUp', args: animation);
  }

  /// Retrieves the maximum configured zoom level for the map view.
  ///
  /// Returns the upper limit for zoom operations. Higher zoom levels represent
  /// closer views of the map (more zoomed in). Attempts to zoom beyond this
  /// level will be clamped to this maximum value.
  ///
  /// ## See also:
  ///
  /// - [minZoomLevel] - Get the minimum zoom level
  /// - [setZoomLevel] - Set the current zoom level
  /// - [maxSlippyZoomLevel] - Get maximum slippy tile zoom level
  int get maxZoomLevel {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getMaxZoomLevel',
    );

    return resultString['result'];
  }

  /// Sets the maximum zoom level allowed for the map view.
  ///
  /// Configures the upper limit for zoom operations. Higher zoom levels represent
  /// closer views of the map. This setting affects all zoom operations including
  /// [setZoomLevel], [centerOnCoordinates], and user gesture-based zooming.
  ///
  /// ## Parameters
  ///
  /// - [zoomLevel]: The maximum zoom level to configure
  ///
  /// ## See also:
  ///
  /// - [maxZoomLevel] - Get the current maximum zoom level
  /// - [minZoomLevel] - Configure the minimum zoom level
  set maxZoomLevel(final int zoomLevel) {
    objectMethod(_pointerId, 'MapView', 'setMaxZoomLevel', args: zoomLevel);
  }

  /// Retrieves the minimum configured zoom level for the map view.
  ///
  /// Returns the lower limit for zoom operations. Higher zoom levels represent
  /// closer views of the map, so the minimum zoom level represents the furthest
  /// (most zoomed out) view allowed. Attempts to zoom below this level will be
  /// clamped to this minimum value.
  ///
  /// ## See also:
  ///
  /// - [maxZoomLevel] - Get the maximum zoom level
  /// - [setZoomLevel] - Set the current zoom level
  int get minZoomLevel {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getMinZoomLevel',
    );

    return resultString['result'];
  }

  /// Sets the minimum zoom level allowed for the map view.
  ///
  /// Configures the lower limit for zoom operations. This represents the furthest
  /// (most zoomed out) view the user or application can achieve. This setting
  /// affects all zoom operations including [setZoomLevel], [centerOnCoordinates],
  /// and user gesture-based zooming.
  ///
  /// ## Parameters
  ///
  /// - [zoomLevel]: The minimum zoom level to configure
  ///
  /// ## See also:
  ///
  /// - [minZoomLevel] - Get the current minimum zoom level
  /// - [maxZoomLevel] - Configure the maximum zoom level
  set minZoomLevel(final int zoomLevel) {
    objectMethod(_pointerId, 'MapView', 'setMinZoomLevel', args: zoomLevel);
  }

  /// Retrieves the maximum slippy tile zoom level for the map view.
  ///
  /// Returns the upper limit for slippy tile-based zoom operations. The slippy
  /// zoom level follows the standard web map tile system where each level
  /// represents a tile level.
  ///
  /// ## See also:
  ///
  /// - [setSlippyZoomLevel] - Set the slippy tile zoom level
  /// - [slippyZoomLevel] - Get the current slippy tile zoom level
  /// - [maxZoomLevel] - Get maximum standard zoom level
  double get maxSlippyZoomLevel {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getMaxSlippyZoomLevel',
    );

    return resultString['result'];
  }

  /// Sets the map zoom level centered on a specified screen position.
  ///
  /// Changes the zoom level while keeping the specified screen position fixed,
  /// meaning the geographic location at that screen point remains at the same
  /// screen coordinates after zooming. The zoom level must be between [minZoomLevel]
  /// and [maxZoomLevel].
  ///
  /// If no screen position is provided, the zoom centers on the current cursor
  /// position (which defaults to viewport center). The operation can be animated
  /// by specifying a duration.
  ///
  /// ## Parameters
  ///
  /// - [zoomLevel]: Target zoom level, must be between [minZoomLevel] and [maxZoomLevel]
  /// - [duration]: Animation duration in milliseconds. Use `0` for instant zoom. Defaults to `0`
  /// - [screenPosition]: Screen coordinates in physical pixels that should remain fixed during zoom, relative to the map view's top-left corner. If `null`, uses the current cursor position. Defaults to `null`
  ///
  /// ## Returns
  ///
  /// - On success: the previous zoom level. On error: error code (< 0)
  ///
  /// ## See also:
  ///
  /// - [zoomLevel] - Get the current zoom level
  /// - [canZoom] - Check if zoom to level is possible
  /// - [setSlippyZoomLevel] - Set zoom using slippy tile level
  int setZoomLevel(
    final int zoomLevel, {
    final int duration = 0,
    final Point<int>? screenPosition,
  }) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'setZoomLevel',
      args: <String, Object>{
        'zoomLevel': zoomLevel,
        'duration': duration,
        if (screenPosition != null) 'xy': XyType<int>.fromPoint(screenPosition),
      },
    );

    return resultString['result'];
  }

  /// Checks if zooming to a specified level is possible.
  ///
  /// Determines whether the map can be zoomed to the given [zoomLevel]
  /// from its current state. This considers factors such as the current zoom
  /// level, map constraints, and any active animations or gestures.
  ///
  /// If a [screenPosition] is provided, checks if zooming while keeping that
  /// screen point fixed is feasible. If no position is given, the check assumes
  /// zooming centered on the current cursor position.
  ///
  /// ## Parameters
  ///
  /// - [zoomLevel]: Target zoom level to check
  /// - [screenPosition]: Screen coordinates in physical pixels to remain fixed
  /// during zoom, relative to the map view's top-left corner. If `null`, uses the current cursor position. Defaults to `null`
  ///
  /// ## Returns
  ///
  /// - `true` if zooming to the specified level is possible, `false` otherwise
  ///
  /// ## See also:
  ///
  /// - [setZoomLevel] - Set the zoom level
  /// - [zoomLevel] - Get the current zoom level
  bool canZoom(int zoomLevel, {Point<int>? screenPosition}) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'canZoom',
      args: <String, Object>{
        'zoomLevel': zoomLevel,
        if (screenPosition != null) 'xy': XyType<int>.fromPoint(screenPosition),
      },
    );

    return resultString['result'];
  }

  /// Sets the map zoom level using slippy tile-based zoom scale.
  ///
  /// Changes the zoom level based on the standard web map tile system (slippy
  /// tiles) where each level represents a doubling of map resolution. The zoom
  /// level must be between 0 and [maxSlippyZoomLevel].
  ///
  /// The reference point for zooming depends on the current state: when follow
  /// position mode is active, uses the tracked position; otherwise uses the
  /// specified screen position or screen center if none is provided.
  ///
  /// ## Parameters
  ///
  /// - [zoomLevel]: Target slippy tile zoom level, must be between 0 and [maxSlippyZoomLevel]
  /// - [duration]: Animation duration in milliseconds. Use `0` for instant zoom. Defaults to `0`
  /// - [screenPosition]: Screen coordinates in physical pixels that should remain fixed during zoom,
  /// relative to the map view's top-left corner. If `null`, uses screen center (or tracked position if follow mode is active). Defaults to `null`
  ///
  /// ## Returns
  ///
  /// - The previous slippy zoom level
  ///
  /// ## See also:
  ///
  /// - [slippyZoomLevel] - Get the current slippy tile zoom level
  /// - [setZoomLevel] - Set zoom using standard zoom level
  /// - [maxSlippyZoomLevel] - Get maximum slippy tile zoom level
  double setSlippyZoomLevel(
    final double zoomLevel, {
    final int duration = 0,
    final Point<int>? screenPosition,
  }) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'setSlippyZoomLevel',
      args: <String, Object>{
        'zoomLevel': zoomLevel,
        'duration': duration,
        if (screenPosition != null) 'xy': XyType<int>.fromPoint(screenPosition),
      },
    );

    return resultString['result'];
  }

  /// Retrieves the current zoom level of the map view.
  ///
  /// Returns the active zoom level, which determines how close the view is to
  /// the map surface. Higher values represent closer (more zoomed in) views.
  /// The value is always between [minZoomLevel] and [maxZoomLevel].
  ///
  /// ## See also:
  ///
  /// - [setZoomLevel] - Change the zoom level
  /// - [slippyZoomLevel] - Get the slippy tile zoom level
  int get zoomLevel {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getZoomLevel',
    );

    return resultString['result'];
  }

  /// Retrieves the current slippy tile zoom level of the map view.
  ///
  /// Returns the active zoom level in the slippy tile system, which follows
  /// the standard web map tile convention.
  ///
  /// ## See also:
  ///
  /// - [setSlippyZoomLevel] - Change the slippy tile zoom level
  /// - [zoomLevel] - Get the standard zoom level
  /// - [maxSlippyZoomLevel] - Get maximum slippy tile zoom level
  double get slippyZoomLevel {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getSlippyZoomLevel',
    );

    return resultString['result'];
  }

  /// Restores follow position mode to its default auto-zoom configuration.
  ///
  /// Transitions from a manually adjusted follow position mode (where the camera
  /// maintains a fixed relative position set by user gestures) back to the default
  /// auto-zoom mode. In default mode, the camera automatically adjusts zoom and
  /// angle to provide optimal visibility while tracking position.
  ///
  /// This is only effective when follow position mode is active and has been
  /// manually adjusted by user input. Use [isFollowingPositionTouchHandlerModified]
  /// to check if follow mode has been adjusted.
  ///
  /// It triggers a [GemMapController.registerOnTouchHandlerModifyFollowPosition]
  /// callback with [FollowPositionState.exited] invocation if registered.
  ///
  /// ## Parameters
  ///
  /// - [animation]: Animation settings for the transition. If `null`, restoration occurs instantly. Defaults to `null`
  ///
  /// ## See also:
  ///
  /// - [isFollowingPositionTouchHandlerModified] - Check if follow mode is adjusted
  /// - [isDefaultFollowingPosition] - Check if in default follow mode
  /// - [stopFollowingPosition] - Deactivate follow position mode entirely
  void restoreFollowingPosition({final GemAnimation? animation}) {
    objectMethod(
      _pointerId,
      'MapView',
      'restoreFollowingPosition',
      args: (animation != null) ? animation : <String, dynamic>{},
    );
  }

  /// Deactivates highlighting for a specific highlight collection.
  ///
  /// Removes the visual emphasis from a previously activated highlight collection,
  /// returning the highlighted elements to their normal rendering. If no highlight
  /// ID is specified, deactivates the default highlight collection (ID 0).
  ///
  /// To deactivate all highlights at once, use [deactivateAllHighlights] instead.
  ///
  /// ## Parameters
  ///
  /// - [highlightId]: The ID of the highlight collection to deactivate. If `null`, deactivates the default collection (ID 0). Defaults to `null`
  ///
  /// ## See also:
  ///
  /// - [activateHighlight] - Activate highlighting for landmarks
  /// - [deactivateAllHighlights] - Deactivate all highlight collections
  /// - [getHighlight] - Retrieve highlighted landmarks
  void deactivateHighlight({final int? highlightId}) {
    objectMethod(
      _pointerId,
      'MapView',
      'deactivateHighlight',
      args: (highlightId != null) ? highlightId : <String, dynamic>{},
    );
  }

  /// Deactivates all highlight collections simultaneously.
  ///
  /// Removes visual emphasis from all previously activated highlight collections,
  /// returning all highlighted elements to their normal rendering. This is more
  /// efficient than calling [deactivateHighlight] repeatedly for multiple collections.
  ///
  /// ## See also:
  ///
  /// - [deactivateHighlight] - Deactivate a specific highlight collection
  /// - [activateHighlight] - Activate highlighting for landmarks
  void deactivateAllHighlights() {
    objectMethod(_pointerId, 'MapView', 'deactivateAllHighlights');
  }

  /// Retrieves the geographic bounds of a highlighted collection.
  ///
  /// Returns a [RectangleGeographicArea] representing the minimum bounding box
  /// that contains all elements in the specified highlight collection. This is
  /// useful for centering the map on highlighted content or calculating optimal
  /// view areas.
  ///
  /// Returns `null` if the specified highlight collection doesn't exist or
  /// contains no elements.
  ///
  /// ## Parameters
  ///
  /// - [highlightId]: The ID of the highlight collection whose area to retrieve. Defaults to `0`
  ///
  /// ## Returns
  ///
  /// - [RectangleGeographicArea] with the bounds of the highlighted elements, or `null` if the collection doesn't exist
  ///
  /// ## See also:
  ///
  /// - [activateHighlight] - Activate highlighting for landmarks
  /// - [getOptimalHighlightCenterViewport] - Calculate optimal viewport for highlights
  RectangleGeographicArea? getHighlightArea({final int highlightId = 0}) {
    try {
      final OperationResult resultString = objectMethod(
        _pointerId,
        'MapView',
        'getHighlightArea',
        args: highlightId,
      );

      return RectangleGeographicArea.fromJson(resultString['result']);
    } catch (e) {
      return null;
    }
  }

  /// Activates highlighting for a collection of landmarks with custom rendering.
  ///
  /// Visually emphasizes the specified landmarks on the map using customizable
  /// rendering settings. Highlighted landmarks stand out from normal map content,
  /// useful for search results, route waypoints, or points of interest.
  ///
  /// Each highlight collection is identified by a unique ID. If a collection with
  /// the specified ID already exists, it will be replaced. Multiple collections
  /// can coexist and are rendered in ascending order by highlight ID.
  ///
  /// ## Parameters
  ///
  /// - [landmarks]: The list of landmarks to highlight on the map
  /// - [renderSettings]: Customizes the visual appearance of highlighted landmarks (colors, sizes, icons). If `null`, uses default rendering. Defaults to `null`
  /// - [highlightId]: Unique identifier for this highlight collection. If a collection with this ID exists, it will be replaced. Defaults to `0`
  ///
  /// ## See also:
  ///
  /// - [deactivateHighlight] - Remove highlighting from a collection
  /// - [getHighlight] - Retrieve highlighted landmarks
  /// - [getHighlightArea] - Get geographic bounds of highlighted collection
  /// - [HighlightRenderSettings] - Customize highlight appearance
  void activateHighlight(
    final List<Landmark> landmarks, {
    HighlightRenderSettings? renderSettings,
    final int highlightId = 0,
  }) {
    renderSettings ??= HighlightRenderSettings();
    final LandmarkList landmarkList = LandmarkList.fromList(landmarks);

    objectMethod(
      _pointerId,
      'MapView',
      'activateHighlight',
      args: <String, dynamic>{
        'landmarks': landmarkList.pointerId,
        'renderSettings': renderSettings.toJson(),
        'highlightId': highlightId,
      },
    );
  }

  /// Retrieves the landmarks in a highlighted collection.
  ///
  /// Returns the list of landmarks that were activated for the specified highlight
  /// collection. This only returns landmarks if the collection was activated with
  /// [HighlightRenderSettings] containing [HighlightOptions.showLandmark]. Otherwise,
  /// the result will be an empty list.
  ///
  /// ## Parameters
  ///
  /// - [highlightId]: The ID of the highlight collection whose landmarks to retrieve
  ///
  /// ## Returns
  ///
  /// - List of [Landmark] objects in the specified highlight collection, or an empty list if the collection doesn't exist or wasn't configured to show landmarks
  ///
  /// ## See also:
  ///
  /// - [activateHighlight] - Activate highlighting for landmarks
  /// - [getHighlightArea] - Get geographic bounds of highlighted collection
  /// - [HighlightRenderSettings] - Configure highlight rendering options
  List<Landmark> getHighlight(int highlightId) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getHighlight',
      args: highlightId,
    );

    final LandmarkList landmarkList = LandmarkList.init(resultString['result']);

    return landmarkList.toList();
  }

  /// Activates highlighting for a collection of overlay items with custom rendering.
  ///
  /// Visually emphasizes the specified overlay items on the map using customizable rendering settings.
  /// This is useful for highlighting user-added content, selected items, or interactive elements.
  ///
  /// Each highlight collection is identified by a unique ID. If a collection with
  /// the specified ID already exists, it will be replaced. Multiple collections
  /// can coexist and are rendered in ascending order by highlight ID.
  ///
  /// ## Parameters
  ///
  /// - [overlayItems]: The list of overlay items to highlight on the map
  /// - [renderSettings]: Customizes the visual appearance of highlighted overlay items. If `null`, uses default rendering. Defaults to `null`
  /// - [highlightId]: Unique identifier for this highlight collection. If a collection with this ID exists, it will be replaced. Defaults to `0`
  ///
  /// ## See also:
  ///
  /// - [activateHighlight] - Activate highlighting for landmarks
  /// - [deactivateHighlight] - Remove highlighting from a collection
  /// - [HighlightRenderSettings] - Customize highlight appearance
  void activateHighlightOverlayItems(
    final List<OverlayItem> overlayItems, {
    final HighlightRenderSettings? renderSettings,
    final int highlightId = 0,
  }) {
    final OverlayItemList landmarkList = OverlayItemList.fromList(overlayItems);

    objectMethod(
      _pointerId,
      'MapView',
      'activateHighlightOverlayItems',
      args: <String, dynamic>{
        'landmarks': landmarkList.pointerId,
        if (renderSettings != null) 'renderSettings': renderSettings.toJson(),
        'highlightId': highlightId,
      },
    );
  }

  /// Centers the map view on an entire route with automatic zoom adjustment.
  ///
  /// Positions the map to display the complete route path, automatically selecting
  /// the optimal zoom level to fit the entire route within the specified screen
  /// rectangle or the full viewport if no rectangle is provided.
  ///
  /// This is useful for providing an overview of a calculated route before
  /// navigation or for displaying route alternatives.
  ///
  /// ## Parameters
  ///
  /// - [route]: The [Route] object to center on and display
  /// - [screenRect]: Target screen rectangle in physical pixels where the route should fit, relative to the map view's top-left corner.
  /// If `null`, uses the entire viewport. Defaults to `null`. Useful for fitting within UI elements or adding margins
  /// - [animation]: Animation settings for the centering operation. If `null`, centering occurs instantly. Defaults to `null`
  ///
  /// ## See also:
  ///
  /// - [centerOnRoutes] - Center on multiple routes simultaneously
  /// - [centerOnRoutePart] - Center on a specific segment of a route
  /// - [centerOnRouteInstruction] - Center on a specific route instruction
  void centerOnRoute(
    final Route route, {
    final Rectangle<int>? screenRect,
    final GemAnimation? animation,
  }) {
    objectMethod(
      _pointerId,
      'MapView',
      'centerOnRoute',
      args: <String, dynamic>{
        'route': route.pointerId,
        if (screenRect != null) 'rc': RectType<int>.fromRectangle(screenRect),
        if (animation != null) 'animation': animation,
      },
    );
  }

  /// Centers the map view on a specific segment of a route with automatic zoom.
  ///
  /// Positions the map to display a portion of a route defined by start and end
  /// distances along the route path. The zoom level automatically adjusts to fit
  /// the specified segment within the target screen rectangle.
  ///
  /// This is useful for focusing on specific parts of a route, such as upcoming
  /// segments during navigation or highlighting problematic sections.
  ///
  /// ## Parameters
  ///
  /// - [route]: The [Route] object containing the segment to display
  /// - [startDist]: Start distance in meters from the beginning of the route
  /// - [endDist]: End distance in meters from the beginning of the route
  /// - [screenRect]: Target screen rectangle in physical pixels where the route segment should fit, relative to the map view's top-left corner.
  /// If `null`, uses the entire viewport. Defaults to `null`. Useful for fitting within UI elements or adding margins
  /// - [animation]: Animation settings for the centering operation. If `null`, centering occurs instantly. Defaults to `null`
  ///
  /// ## See also:
  ///
  /// - [centerOnRoute] - Center on an entire route
  /// - [centerOnRouteInstruction] - Center on a specific route instruction
  void centerOnRoutePart(
    final Route route,
    final int startDist,
    final int endDist, {
    final Rectangle<int>? screenRect,
    final GemAnimation? animation,
  }) {
    objectMethod(
      _pointerId,
      'MapView',
      'centerOnRoutePart',
      args: <String, dynamic>{
        'route': route.pointerId,
        'startDist': startDist,
        'endDist': endDist,
        if (screenRect != null)
          'viewRc': RectType<int>.fromRectangle(screenRect),
        if (animation != null) 'animation': animation,
      },
    );
  }

  /// Centers the map on a specific route instruction with visual indicator.
  ///
  /// Positions the map to focus on a particular routing instruction (turn, exit,
  /// etc.) with a visible turn arrow displayed on the map. The instruction remains
  /// highlighted until cleared with [clearRouteInstruction].
  ///
  /// This is particularly useful during turn-by-turn navigation to show upcoming
  /// maneuvers or for reviewing specific instructions in a route.
  ///
  /// ## Parameters
  ///
  /// - [routeInstruction]: The [RouteInstruction] to center on and highlight
  /// - [zoomLevel]: Target zoom level. Use `-1` for automatic selection based on instruction context. Defaults to `-1`
  /// - [screenPosition]: Screen coordinates in physical pixels where the instruction should be centered, relative to the map view's top-left corner. Defaults to `Point<int>(0, 0)`
  /// - [viewAngle]: Camera pitch angle in degrees (0-90), where 0 is top-down view and 90 is horizon view. If `null`, maintains current pitch. Defaults to `null`.
  /// Useful for emphasizing the instruction with a specific perspective
  /// - [animation]: Animation settings for the centering operation. If `null`, centering occurs instantly. Defaults to `null`
  ///
  /// ## See also:
  ///
  /// - [clearRouteInstruction] - Remove the instruction highlight
  /// - [centerOnRoute] - Center on an entire route
  /// - [centerOnRoutePart] - Center on a route segment
  void centerOnRouteInstruction(
    final RouteInstruction routeInstruction, {
    final double zoomLevel = -1,
    final Point<int> screenPosition = const Point<int>(0, 0),
    final double? viewAngle,
    final GemAnimation? animation,
  }) {
    objectMethod(
      _pointerId,
      'MapView',
      'centerOnRouteInstruction',
      args: <String, Object>{
        'instruction': routeInstruction.pointerId,
        'zoomLevel': zoomLevel,
        'xy': XyType<int>.fromPoint(screenPosition),
        if (viewAngle != null) 'viewAngle': viewAngle,
        if (animation != null) 'animation': animation,
      },
    );
  }

  /// Removes the route instruction highlight created by [centerOnRouteInstruction].
  ///
  /// Clears the visual turn arrow indicator that was displayed when centering on
  /// a route instruction. The map view and camera position remain unchanged, only
  /// the instruction highlight is removed.
  ///
  /// ## See also:
  ///
  /// - [centerOnRouteInstruction] - Center and highlight a route instruction
  void clearRouteInstruction() {
    objectMethod(_pointerId, 'MapView', 'clearRouteInstruction');
  }

  /// Centers the map on a traffic event along a route.
  ///
  /// Positions the map to focus on a specific traffic event (accident, congestion,
  /// road closure, etc.) that affects a route. The zoom level can be automatic or
  /// manually specified to provide appropriate detail level.
  ///
  /// This is useful for reviewing traffic conditions that may impact navigation
  /// or for investigating delays along a route.
  ///
  /// ## Parameters
  ///
  /// - [routeTrafficEvent]: The [RouteTrafficEvent] to center on and display
  /// - [zoomLevel]: Target zoom level. Use `-1` for automatic selection based on event context. Defaults to `-1`
  /// - [rectangle]: Target screen rectangle in physical pixels where the event should fit, relative to the map view's top-left corner.
  /// Defaults to `Rectangle<int>(0, 0, 0, 0)` (uses entire viewport). Useful for fitting within UI elements or adding margins
  /// - [viewAngle]: Camera pitch angle in degrees (0-90), where 0 is top-down view and 90 is horizon view. If `null`, maintains current pitch. Defaults to `null`
  /// - [animation]: Animation settings for the centering operation. If `null`, centering occurs instantly. Defaults to `null`
  ///
  /// ## See also:
  ///
  /// - [centerOnRoute] - Center on an entire route
  /// - [centerOnRouteInstruction] - Center on a route instruction
  void centerOnRouteTrafficEvent(
    RouteTrafficEvent routeTrafficEvent, {
    final double zoomLevel = -1,
    final Rectangle<int> rectangle = const Rectangle<int>(0, 0, 0, 0),
    final double? viewAngle,
    final GemAnimation? animation,
  }) {
    objectMethod(
      _pointerId,
      'MapView',
      'centerOnRouteTrafficEvent',
      args: <String, Object>{
        'traffic': routeTrafficEvent.pointerId,
        'zoomLevel': zoomLevel,
        'rc': RectType<int>.fromRectangle(rectangle),
        if (viewAngle != null) 'viewAngle': viewAngle,
        if (animation != null) 'animation': animation,
      },
    );
  }

  /// Centers the map on multiple routes simultaneously with automatic zoom.
  ///
  /// Positions the map to display all specified routes, automatically selecting
  /// the optimal zoom level to fit all route paths within the target screen
  /// rectangle. If no routes are provided, centers on the visible routes from
  /// [MapViewRoutesCollection].
  ///
  /// The display mode controls whether the full route paths are shown or only
  /// specific segments, useful for comparing route alternatives or showing
  /// multiple navigation options. If [RouteDisplayMode.full] (default) is used,
  /// the entire paths of all routes are considered for centering. If [RouteDisplayMode.branches]
  /// is used, only the differing segments between routes are considered.
  ///
  /// ## Parameters
  ///
  /// - [routes]: List of [Route] objects to center on and display. If `null`, uses visible routes from [MapViewRoutesCollection]. Defaults to `null`
  /// - [displayMode]: Controls how routes are displayed (full paths, partial segments, etc.). Defaults to [RouteDisplayMode.full]
  /// - [screenRect]: Target screen rectangle in physical pixels where routes should fit, relative to the map view's top-left corner.
  /// If `null`, uses the entire viewport. Defaults to `null`. Useful for fitting within UI elements or adding margins
  /// - [animation]: Animation settings for the centering operation. If `null`, centering occurs instantly. Defaults to `null`
  ///
  /// ## See also:
  ///
  /// - [centerOnRoute] - Center on a single route
  /// - [centerOnRoutePart] - Center on a route segment
  /// - [getOptimalRoutesCenterViewport] - Calculate optimal viewport for routes
  void centerOnRoutes({
    final List<Route>? routes,
    final RouteDisplayMode displayMode = RouteDisplayMode.full,
    final Rectangle<int>? screenRect,
    final GemAnimation? animation,
  }) {
    objectMethod(
      _pointerId,
      'MapView',
      'centerOnRoutes',
      args: <String, dynamic>{
        'routesList': (routes != null)
            ? RouteList.fromList(routes).pointerId
            : -1,
        'displayMode': displayMode.id,
        if (screenRect != null)
          'viewRc': RectType<int>.fromRectangle(screenRect),
        if (animation != null) 'animation': animation,
      },
    );
  }

  /// Sets the view clipping rectangle using parent screen ratio coordinates.
  ///
  /// Dimensions expressed as ratios (0.0 to 1.0) relative to the parent
  /// screen size.
  ///
  /// To reset clipping to the full view area, call `setClippingArea(viewportF)`.
  ///
  /// ## Parameters
  ///
  /// - [area]: Clipping rectangle with coordinates as ratios of parent screen dimensions (0.0 to 1.0). For example, 0.5 represents half the screen's width or height
  ///
  /// ## See also:
  ///
  /// - [viewportF] - Current viewport in parent screen ratio
  @Deprecated(
    'Will be removed in future versions. Change the GemView widget size instead.',
  )
  void setClippingArea(final Rectangle<double> area) {
    objectMethod(
      _pointerId,
      'MapView',
      'setClippingArea',
      args: RectType<double>.fromRectangle(area),
    );
  }

  /// Calculates the optimal viewport for displaying multiple routes.
  ///
  /// Returns an adjusted viewport rectangle that ensures all specified routes
  /// will be visible when used with [centerOnAreaRect]. The calculation accounts
  /// for route paths and automatically determines the best viewport dimensions
  /// to fit all routes within the specified screen rectangle.
  ///
  /// This is useful for pre-calculating viewport dimensions before centering,
  /// particularly when implementing custom padding or UI constraints.
  ///
  /// ## Parameters
  ///
  /// - [routes]: List of [Route] objects whose combined extent should be calculated
  /// - [screenRect]: Target screen rectangle in physical pixels where routes should fit, relative to the map view's top-left corner.
  /// If `null`, uses the entire [viewport]. Defaults to `null`. Useful for fitting within UI elements or adding margins
  ///
  /// ## Returns
  ///
  /// - Optimal viewport [Rectangle<int>] in physical pixels that will fit all routes, relative to the map view's top-left corner
  ///
  /// ## See also:
  ///
  /// - [centerOnRoutes] - Center on multiple routes
  /// - [centerOnAreaRect] - Center area within viewport rectangle
  /// - [getOptimalHighlightCenterViewport] - Calculate optimal viewport for highlights
  Rectangle<int> getOptimalRoutesCenterViewport(
    final List<Route> routes, {
    final Rectangle<int>? screenRect,
  }) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getOptimalRoutesCenterViewport',
      args: <String, dynamic>{
        'routesList': RouteList.fromList(routes).pointerId,
        if (screenRect != null)
          'viewRc': RectType<int>.fromRectangle(screenRect),
      },
    );

    final Rectangle<int> rect = Rectangle<int>(
      resultString['result']['x'] ?? 0,
      resultString['result']['y'] ?? 0,
      resultString['result']['width'] ?? 0,
      resultString['result']['height'] ?? 0,
    );

    return rect;
  }

  /// Determines which segment of a route is visible within a screen rectangle.
  ///
  /// Returns the portion of a route that intersects with the specified screen
  /// rectangle, expressed as start and end distances along the route path. This
  /// is useful for identifying which parts of a route are currently visible to
  /// the user or within a specific viewport region.
  ///
  /// If no rectangle is provided, uses the entire screen to determine visibility.
  ///
  /// ## Parameters
  ///
  /// - [route]: The [Route] to analyze for visible segments
  /// - [screenRect]: Clipping rectangle in physical pixels to test for route visibility, relative to the map view's top-left corner.
  /// If `null`, uses the entire screen. Defaults to `null`. Useful for checking visibility within UI elements or specific areas
  ///
  /// ## Returns
  ///
  /// - Record of `(startDistance, endDistance)` in meters from the route beginning, representing the visible route segment
  ///
  /// ## See also:
  ///
  /// - [centerOnRoutePart] - Center on a specific route segment
  /// - [centerOnRoute] - Center on an entire route
  (int, int) getVisibleRouteInterval(
    final Route route, {
    final Rectangle<int>? screenRect,
  }) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getVisibleRouteInterval',
      args: <String, dynamic>{
        'route': route.pointerId,
        if (screenRect != null)
          'clipRect': RectType<int>.fromRectangle(screenRect),
      },
    );

    return (resultString['result']['first'], resultString['result']['second']);
  }

  /// Calculates the optimal viewport for displaying all highlighted elements.
  ///
  /// Returns an adjusted viewport rectangle that ensures all currently highlighted
  /// elements will be visible when used with [centerOnAreaRect]. The calculation
  /// accounts for all active highlights and automatically determines
  /// the best viewport dimensions to fit all highlighted content.
  ///
  /// This is useful for centering on highlighted landmarks with custom padding or UI constraints.
  ///
  /// ## Parameters
  ///
  /// - [screenRect]: Target screen rectangle in physical pixels where highlights should fit, relative to the map view's top-left corner.
  /// If `null` or empty, uses the entire [viewport]. Defaults to `null`. Useful for fitting within UI elements or adding margins
  ///
  /// ## Returns
  ///
  /// - Optimal viewport [Rectangle<int>] in physical pixels that will fit all highlighted elements, relative to the map view's top-left corner
  ///
  /// ## See also:
  ///
  /// - [activateHighlight] - Activate highlighting for landmarks
  /// - [centerOnAreaRect] - Center area within viewport rectangle
  /// - [getOptimalRoutesCenterViewport] - Calculate optimal viewport for routes
  Rectangle<int> getOptimalHighlightCenterViewport({
    Rectangle<int>? screenRect,
  }) {
    screenRect ??= const Rectangle<int>(0, 0, 0, 0);

    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getOptimalHighlightCenterViewport',
      args: RectType<int>.fromRectangle(screenRect),
    );

    final Rectangle<int> rect = Rectangle<int>(
      resultString['result']['x'] ?? 0,
      resultString['result']['y'] ?? 0,
      resultString['result']['width'] ?? 0,
      resultString['result']['height'] ?? 0,
    );

    return rect;
  }

  /// Centers the map on all routes currently visible in the [MapViewRoutesCollection].
  ///
  /// Positions the map to display all routes that are currently marked as visible,
  /// automatically selecting the optimal zoom level to fit all visible route paths
  /// within the target screen rectangle. This is useful for showing all active
  /// routes without needing to specify each route explicitly.
  ///
  /// ## Parameters
  ///
  /// - [displayMode]: Controls how routes are displayed (full paths, partial segments, etc.). If `null`, uses default display mode. Defaults to `null`
  /// - [screenRect]: Target screen rectangle in physical pixels where routes should fit, relative to the map view's top-left corner.
  /// If `null`, uses the entire viewport. Defaults to `null`. Useful for fitting within UI elements or adding margins
  /// - [animation]: Animation settings for the centering operation. If `null`, centering occurs instantly. Defaults to `null`
  ///
  /// ## See also:
  ///
  /// - [centerOnRoutes] - Center on a specific list of routes
  /// - [centerOnRoute] - Center on a single route
  void centerOnMapRoutes({
    final RouteDisplayMode? displayMode,
    final Rectangle<int>? screenRect,
    final GemAnimation? animation,
  }) {
    objectMethod(
      _pointerId,
      'MapView',
      'centerOnRoutes',
      args: <String, Object>{
        'routesList': -1,
        if (displayMode != null) 'displayMode': displayMode.id,
        if (screenRect != null)
          'viewRc': RectType<int>.fromRectangle(screenRect),
        if (animation != null) 'animation': animation,
      },
    );
  }

  /// Retrieve the list of routes under the cursor location.
  ///
  /// Use [setCursorScreenPosition] to set the cursor location.
  ///
  /// ## Returns
  ///
  /// - A list of [Route] objects under the cursor. If no routes are found, the list will be empty.
  ///
  /// ## See also:
  ///
  /// - [setCursorScreenPosition] - Set the cursor location for selection
  /// - [GemMapController.registerOnCursorSelectionUpdatedRoutes] - Listen for cursor selection changes
  List<Route> cursorSelectionRoutes() {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'cursorSelectionRoutes',
    );

    return RouteList.init(resultString['result']).toList();
  }

  /// Retrieve the list of landmarks under the cursor location.
  ///
  /// Use [setCursorScreenPosition] to set the cursor location.
  ///
  /// ## Returns
  ///
  /// - A list of [Landmark] objects under the cursor. If no landmarks are found, the list will be empty.
  ///
  /// ## See also:
  ///
  /// - [setCursorScreenPosition] - Set the cursor location for selection
  /// - [GemMapController.registerOnCursorSelectionUpdatedLandmarks] - Listen for cursor selection changes
  List<Landmark> cursorSelectionLandmarks() {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'cursorSelectionLandmarks',
    );

    return LandmarkList.init(resultString['result']).toList();
  }

  /// Retrieve the list of streets under the cursor location.
  ///
  /// Use [setCursorScreenPosition] to set the cursor location.
  ///
  /// ## Returns
  ///
  /// - A list of [Landmark] objects corresponding to streets under the cursor. If no streets are found, the list will be empty.
  ///
  /// ## See also:
  ///
  /// - [setCursorScreenPosition] - Set the cursor location for selection
  /// - [GemMapController.registerOnCursorSelectionUpdatedLandmarks] - Listen for cursor selection changes
  List<Landmark> cursorSelectionStreets() {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'cursorSelectionStreets',
    );

    return LandmarkList.init(resultString['result']).toList();
  }

  /// Retrieve the list of overlay items under the cursor location.
  ///
  /// Use [setCursorScreenPosition] to set the cursor location.
  ///
  /// ## Returns
  ///
  /// - A list of OverlayItem objects under the cursor. If no overlay items are found, the list will be empty.
  ///
  /// ## See also:
  ///
  /// - [setCursorScreenPosition] - Set the cursor location for selection
  /// - [GemMapController.registerOnCursorSelectionUpdatedOverlayItems] - Listen for cursor selection changes
  List<OverlayItem> cursorSelectionOverlayItems() {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'cursorSelectionOverlayItems',
    );

    return OverlayItemList.init(resultString['result']).toList();
  }

  /// Retrieves overlay items of a specific type under the cursor location.
  ///
  /// Returns only the overlay items that match the specified overlay ID type
  /// from all overlay items at the cursor position. Use [setCursorScreenPosition]
  /// to set the cursor location before calling this method.
  ///
  /// ## Parameters
  ///
  /// - [overlayId]: The overlay ID type to filter by, determining which overlay items to include
  ///
  /// ## Returns
  ///
  /// - List of [OverlayItem] objects matching the specified type under the cursor, or an empty list if none found
  ///
  /// ## See also:
  ///
  /// - [cursorSelectionOverlayItems] - Get all overlay items under cursor
  /// - [setCursorScreenPosition] - Set cursor position for selection
  List<OverlayItem> cursorSelectionOverlayItemsByType(
    CommonOverlayId overlayId,
  ) {
    return cursorSelectionOverlayItems().where((final OverlayItem item) {
      return item.isOfType(overlayId);
    }).toList();
  }

  /// Retrieves a reference to a list of markers under the current cursor location.
  ///
  /// Use [setCursorScreenPosition] to set the cursor location.
  ///
  /// ## Returns
  ///
  /// A list of [MarkerMatch] objects under the cursor. If no markers are found, the list will be empty.
  ///
  /// ## See also:
  ///
  /// - [setCursorScreenPosition] - Set the cursor location for selection
  /// - [GemMapController.registerOnCursorSelectionUpdatedMarkers] - Listen for cursor selection changes
  List<MarkerMatch> cursorSelectionMarkers() {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'cursorSelectionMarkers',
    );

    return MarkerMatchList.init(resultString['result']).toList();
  }

  /// Retrieve the path under the cursor location.
  ///
  /// Use [setCursorScreenPosition] to set the cursor location.
  ///
  /// ## Returns
  ///
  /// - A [Path] object under the cursor. If no path is found returns null.
  ///
  /// ## See also:
  ///
  /// - [setCursorScreenPosition] - Set the cursor location for selection
  /// - [GemMapController.registerOnCursorSelectionUpdatedPath] - Listen for cursor selection changes
  Path? cursorSelectionPath() {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'cursorSelectionPath',
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return Path.init(resultString['result']);
  }

  /// Retrieve the list of traffic events under the cursor location.
  ///
  /// Traffic events can include incidents like accidents, roadworks, or traffic jams. This method is useful for applications
  /// that provide real-time traffic information and require user interaction with traffic events.
  ///
  /// Use [setCursorScreenPosition] to set the cursor location.
  ///
  /// ## Returns
  ///
  /// - A [Path] object under the cursor. If no path is found returns null.
  ///
  /// ## See also:
  ///
  /// - [setCursorScreenPosition] - Set the cursor location for selection
  /// - [GemMapController.registerOnCursorSelectionUpdatedTrafficEvents] - Listen for cursor selection changes
  List<TrafficEvent> cursorSelectionTrafficEvents() {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'cursorSelectionTrafficEvents',
    );

    return TrafficEventList.init(resultString['result']).toList();
  }

  /// Retrieves the scene object under the current cursor selection
  ///
  /// Scene objects can include 3D models, custom drawings, or other complex visual elements added to the map. This
  /// method determines which scene object, if any, is under the cursor, facilitating interactions like selection or manipulation.
  ///
  /// ## Returns
  ///
  /// - The [MapSceneObject] under the cursor. If no scene object is found, this will return null.
  ///
  /// ## See also:
  ///
  /// - [setCursorScreenPosition] - Set the cursor location for selection
  /// - [GemMapController.registerOnCursorSelectionUpdatedMapSceneObject] - Listen for cursor selection changes
  MapSceneObject? cursorSelectionMapSceneObject() {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'cursorSelectionSceneObject',
    );

    if (resultString['result'] == -1) {
      return null;
    }
    return MapSceneObject.init(resultString['result'], _mapId);
  }

  /// Activates follow position mode to track the current location.
  ///
  /// Enables automatic camera tracking of the device's real or simulated position.
  /// The map continuously updates to keep the current position visible, with
  /// optional animation to the starting position. This mode disables the cursor
  /// if enabled and requires automatic map rendering.
  ///
  /// Uses the positions provided by the [PositionService]. Ensure that the position
  /// service is started and providing updates before activating follow mode or start
  /// simulation on a route via the [NavigationService].
  ///
  /// Use the [stopFollowingPosition] method to exit follow mode and configure options
  /// with [FollowPositionPreferences] if needed. See [MapSceneObject.getDefPositionTracker]
  /// for customizing the navigation arrow appearance.
  ///
  /// ## Parameters
  ///
  /// - [animation]: Animation settings for transitioning to follow mode. If `null`, starts instantly. Defaults to `null`
  /// - [zoomLevel]: Target zoom level when follow mode starts. Use `-1` for automatic selection. Defaults to `-1`
  /// - [viewAngle]: Camera pitch angle in degrees (0-90), where 0 is top-down view and 90 is horizon view. If `null`, uses default angle. Defaults to `null`
  /// - [positionObj]: Custom [MapSceneObject] for the navigation arrow. If `null`, uses the SDK's default arrow. Defaults to `null`
  ///
  /// ## See also:
  ///
  /// - [stopFollowingPosition] - Deactivate follow position mode
  /// - [isFollowingPosition] - Check if follow mode is active
  /// - [restoreFollowingPosition] - Restore to default auto-zoom follow mode
  void startFollowingPosition({
    final GemAnimation? animation,
    final int zoomLevel = -1,
    final double? viewAngle,
    final MapSceneObject? positionObj,
  }) {
    final bool hasViewAngle = viewAngle != null;

    objectMethod(
      _pointerId,
      'MapView',
      'startFollowingPosition',
      args: <String, Object>{
        if (animation != null) 'animation': animation,
        'zoomLevel': zoomLevel,
        'viewAngle': hasViewAngle ? viewAngle : -1,
        if (positionObj != null) 'positionObj': positionObj,
      },
    );
  }

  /// Enables interactive marker drawing mode using touch gestures.
  ///
  /// Activates a special mode where users can draw markers on the map through
  /// touch gestures. While this mode is active, standard map panning and zooming
  /// gestures are disabled to prevent interference with marker drawing.
  ///
  /// Use [disableDrawMarkersMode] to exit this mode and retrieve the drawn markers
  /// as landmarks.
  ///
  /// ## Parameters
  ///
  /// - [renderSettings]: Customizes the visual appearance of drawn markers. If `null`, uses default rendering. Defaults to `null`
  ///
  /// ## See also:
  ///
  /// - [disableDrawMarkersMode] - Exit drawing mode and retrieve drawn markers
  void enableDrawMarkersMode({MarkerCollectionRenderSettings? renderSettings}) {
    renderSettings ??= MarkerCollectionRenderSettings();

    objectMethod(
      _pointerId,
      'MapView',
      'enabledrawmarkersmode',
      args: renderSettings.toJson(),
    );
  }

  /// Disables marker drawing mode and retrieves the drawn landmarks.
  ///
  /// Exits the interactive marker drawing mode, re-enabling standard map gestures
  /// (panning and zooming). Returns all markers that were drawn by the user during
  /// the drawing session as a list of [Landmark] objects.
  ///
  /// ## Returns
  ///
  /// - List of [Landmark] objects representing markers drawn during the drawing session, or an empty list if no markers were drawn
  ///
  /// ## See also:
  ///
  /// - [enableDrawMarkersMode] - Enter interactive marker drawing mode
  List<Landmark> disableDrawMarkersMode() {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'disabledrawmarkersmode',
    );

    return LandmarkList.init(resultString['result']).toList();
  }

  /// Retrieves nearby landmarks at specified geographic coordinates.
  ///
  /// Performs fast synchronous reverse geocoding to find landmarks near the
  /// specified coordinates. This is useful for identifying addresses, points of
  /// interest, cities, or roads at or near a given location without performing
  /// a full asynchronous search.
  ///
  /// Supported landmark store types include [LandmarkStoreType.mapAddress],
  /// [LandmarkStoreType.mapPoi], [LandmarkStoreType.mapCity], and
  /// [LandmarkStoreType.mapRoads].
  ///
  /// ## Parameters
  ///
  /// - [coords]: The reference [Coordinates] for the search center point
  /// - [lmkStoreTypesIds]: List of landmark store type IDs to search (see [LandmarkStoreType]).
  /// If empty, searches all supported landmark stores. Defaults to empty list
  /// - [radius]: Search radius in meters around the coordinates. If `0`, uses an optimal default radius. Defaults to `0`
  ///
  /// ## Returns
  ///
  /// - List of [Landmark] objects representing the nearest locations to the coordinates, sorted by proximity, or an empty list if none found
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreType] - Available landmark store types
  /// - [cursorSelectionLandmarks] - Get landmarks at cursor position
  /// - [SearchService] - Perform asynchronous landmark searches
  List<Landmark> getNearestLocations(
    Coordinates coords, {
    List<int> lmkStoreTypesIds = const <int>[],
    int radius = 0,
  }) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getNearestLocations',
      args: <String, Object>{
        'coords': coords,
        'intList': lmkStoreTypesIds.isNotEmpty
            ? lmkStoreTypesIds
            : <dynamic, dynamic>{},
        'radius': radius,
      },
    );

    return LandmarkList.init(resultString['result']).toList();
  }

  /// Imports a GeoJSON data buffer as a [MarkerCollection] list.
  ///
  /// Does not add the markers to the map, only imports the GeoJSON to a [MarkerCollection] list.
  /// The returned marker collections can then be customized and added to the map
  /// via the [MapViewMarkerCollections.add] method via the [MapViewPreferences.markers] provided
  /// by [preferences].
  ///
  /// ## Parameters
  ///
  /// - [buffer] The GeoJSON data buffer to be added as a marker collection.
  /// - [name] The name of the marker collection.
  ///
  /// ## Returns
  ///
  /// - The created marker collections
  List<MarkerCollection> addGeoJsonAsMarkerCollection(
    final String buffer,
    final String name,
  ) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'addGeoJsonAsMarkerCollection',
      args: <String, String>{'name': name, 'databuffer': buffer},
    );
    final List<MarkerCollection> pRet = List<MarkerCollection>.empty(
      growable: true,
    );

    for (final int markerCollectionId in resultString['result']) {
      pRet.add(MarkerCollection.init(markerCollectionId, 0));
    }
    return pRet;
  }

  Future<Uint8List> _captureAsImage() async {
    try {
      if (_captureAsImageCompleter != null) {
        return _captureAsImageCompleter!.future; // Return the existing future
      }
      _captureAsImageCompleter = Completer<Uint8List>();
      objectMethod(
        _pointerId,
        'MapView',
        'captureAsImage',
        args: RectType<int>(x: -1, y: -1, width: -1, height: -1),
      );
      return _captureAsImageCompleter!.future;
    } catch (e) {
      _captureAsImageCompleter = null;
      rethrow;
    }
  }

  Future<Uint8List?> _captureAsImageAsync() async {
    final Uint8List? resultVal = await GemKitPlatform.instance
        .getChannel(mapId: mapId)
        .invokeMethod('captureScreenshot');
    return resultVal;
  }

  /// Make a screen region capture of the current map in JPEG format.
  ///
  /// No cursor or on-screen information is included on iOS.
  /// On Android it includes the cursor and any on-screen information. The image will be
  /// transparent if the [GemMapController] is not rendered on the screen.
  ///
  /// ## Returns
  ///
  /// - An image of the map shown on the screen.
  Future<Uint8List?> captureImage() async {
    if (GemKitPlatform.instance.androidVersion > -1) {
      return _captureAsImageAsync();
    } else {
      return _captureAsImage();
    }
  }

  /// Current map view scale expressed as meters per millimeter on screen.
  ///
  /// Provides the scale factor that indicates how many meters in the real world
  /// are represented by one millimeter on the rendered map at the current camera
  /// position, zoom and view angle. This value is useful for drawing scale bars,
  /// estimating distances from screen measurements, or adapting UI elements
  /// based on map scale. The value changes when the camera, zoom or view angle
  /// is modified.
  ///
  /// ## Returns
  ///
  /// - Scale in meters corresponding to 1 millimeter on the rendered map (double).
  ///
  /// ## See also:
  ///
  /// - [GemMapController.registerOnRenderMapScale] - Listen for scale changes
  /// - [viewport] - Viewport dimensions in physical pixels.
  double get scale {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getScale',
    );

    return resultString['result'];
  }

  /// Map rotation angle in degrees.
  ///
  /// Returns the current map heading as a value in the range 0.0–360.0 where 0
  /// represents north-up orientation.
  ///
  /// ## Returns
  ///
  /// - Current map angle in degrees (`double`).
  ///
  /// ## See also:
  ///
  /// - [GemMapController.registerOnMapAngleUpdate] - Listen for map angle changes
  double get mapAngle {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getHeadingInDegrees',
    );

    return resultString['result'];
  }

  /// Returns the camera's pitch (view angle) in degrees.
  ///
  /// The view angle is the camera's pitch relative to the ground plane. A value
  /// of 0.0 represents a direct top-down view and 90.0 represents a horizon
  /// view. This angle affects how geographic features are projected to screen
  /// coordinates and can influence scale and visibility calculations.
  ///
  /// ## Returns
  ///
  /// - Current view angle in degrees as a `double` (range: 0.0–90.0).
  double get viewAngle {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getPitchInDegrees',
    );

    return resultString['result'];
  }

  /// Check if map view contains terrain topography information
  ///
  /// If true, [transformScreenToWgs] function returns coordinates with terrain altitude set
  ///
  /// The map view has terrain topography if the map style includes the terrain elevation layer and data is available on queried location
  /// Data is not available is the current zoom level is set to low.
  ///
  /// ## Returns
  ///
  /// - True if map view contains terrain topography, false otherwise
  bool get hasTerrainTopography {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'hasTerrainTopography',
    );

    return resultString['result'];
  }

  /// Retrieves the altitude at specified geographic coordinates.
  ///
  /// Returns the terrain elevation at the given coordinates when the applied map
  /// style includes elevation data and terrain topography is loaded. Use
  /// [hasTerrainTopography] to check if altitude retrieval is available.
  ///
  /// If terrain topography is not available, returns `0`.
  ///
  /// ## Parameters
  ///
  /// - [coordinates]: The WGS84 geographic coordinates to query for altitude
  ///
  /// ## Returns
  ///
  /// - Altitude in meters above sea level if terrain data is available, otherwise `0`
  ///
  /// ## See also:
  ///
  /// - [hasTerrainTopography] - Check if terrain elevation data is available
  /// - [transformScreenToWgs] - Get coordinates with altitude from screen position
  double getAltitude(Coordinates coordinates) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getAltitude',
      args: coordinates,
    );

    return resultString['result'];
  }

  /// Retrieves the map view extensions for additional functionality.
  ///
  /// Returns a [MapViewExtensions] object that provides access to extended map
  /// view capabilities and specialized features not available through the core
  /// [GemView] interface. This includes advanced rendering options, specialized
  /// overlays, and experimental features.
  ///
  /// ## See also:
  ///
  /// - [MapViewExtensions] - Extended map view capabilities
  MapViewExtensions get extensions {
    if (_extensions == null) {
      final OperationResult resultString = objectMethod(
        _pointerId,
        'MapView',
        'extensions',
      );

      _extensions = MapViewExtensions.init(
        resultString['result'],
        _mapId,
        _pointerId,
      );
    }
    return _extensions!;
  }

  /// Highlights a map label at the specified screen coordinates.
  ///
  /// Detects and highlights any map label (street name, landmark name, etc.) at
  /// the given screen position. This is useful for implementing hover effects or
  /// tooltips when the user interacts with map labels.
  ///
  /// To disable the hover highlight, call this method with screen position `(0, 0)`.
  ///
  /// Recommended implementation pattern:
  /// 1. Call with `selectMapObject = false` to check if a label is hovered (for
  ///    cursor shape updates or preliminary checks)
  /// 2. If the cursor is stationary for a reasonable period (e.g., 500ms), call
  ///    again with `selectMapObject = true` to retrieve full map object data
  ///
  /// ## Parameters
  ///
  /// - [screenPosition]: The screen coordinates in physical pixels to check for hovered labels, relative to the map view's top-left corner
  /// - [selectMapObject]: If `true` and a label is hovered, map objects attached to the label are returned via [GemMapController.registerOnHoveredMapLabelHighlightedLandmark]. If `false`, no callback is issued. Defaults to `false`
  ///
  /// ## Returns
  ///
  /// - [GemError.success] if a label was successfully highlighted
  /// - [GemError.notFound] if no label was found at the screen position
  /// - [GemError.activation] if the map is invalid or not initialized
  /// - [GemError.noMemory] if memory allocation failed for the highlighted object
  /// - [GemError.inUse] if another highlighting operation is in progress
  /// - Other [GemError] codes for additional error conditions
  ///
  /// ## See also:
  ///
  /// - [setCursorScreenPosition] - Set cursor position for map selection
  GemError highlightHoveredMapLabel(
    final Point<int> screenPosition, {
    final bool selectMapObject = false,
  }) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'highlightHoveredMapLabel',
      args: <String, Object>{
        'pt': XyType<int>.fromPoint(screenPosition),
        'selectMapObjects': selectMapObject,
      },
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Retrieves data transfer statistics for a specific online service.
  ///
  /// Returns a [TransferStatistics] object containing counters and metrics
  /// about network usage performed by the traffic service. This information
  /// can be used for diagnostics or to display usage to end users.
  ///
  /// ## Parameters
  ///
  /// - [type]: The [ViewOnlineServiceType] to retrieve statistics for
  ///
  /// ## Returns
  ///
  /// - [TransferStatistics] object containing data transfer metrics for the specified service
  ///
  /// ## See also:
  ///
  /// - [ViewOnlineServiceType] - Available online service types
  /// - [TransferStatistics] - Transfer statistics data structure
  TransferStatistics getTransferStatistics(ViewOnlineServiceType type) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getTransferStatistics',
      args: type.id,
    );

    return TransferStatistics.init(resultString['result']);
  }

  /// Checks if map rendering is currently enabled.
  ///
  /// Returns `true` if the map view is actively rendering, or `false` if rendering
  /// has been disabled. Disabling rendering can optimize performance when the map
  /// view is not visible to the user.
  ///
  /// ## See also:
  ///
  /// - [isRenderEnabled] setter - Enable or disable map rendering
  bool get isRenderEnabled {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapView',
      'getRenderingRule',
    );

    return resultString['result'] != 0;
  }

  /// Enables or disables map rendering for performance optimization.
  ///
  /// Controls whether the map view actively renders frames. Disabling rendering
  /// when the map is not visible can significantly improve performance and reduce
  /// resource consumption. Rendering is enabled by default.
  ///
  /// ## Parameters
  ///
  /// - [value]: `true` to enable rendering, `false` to disable it
  ///
  /// ## See also:
  ///
  /// - [isRenderEnabled] getter - Check current rendering state
  set isRenderEnabled(bool value) {
    int rule = 0;
    if (GemKitPlatform.instance.androidVersion > -1) {
      rule = value ? 2 : 0;
      unawaited(
        GemKitPlatform.instance
            .getChannel(mapId: mapId)
            .invokeMethod('pauseResumeSurface', value),
      );
      objectMethod(_pointerId, 'MapView', 'setRenderingRule', args: rule);
    } else {
      rule = value ? 1 : 0;
      objectMethod(_pointerId, 'MapView', 'setRenderingRule', args: rule);
    }
  }

  /// Retrieves the closest address landmark to the given coordinates within a specified radius.
  ///
  /// ## Parameters
  ///
  /// - [coords]: The geographic coordinates to search around.
  /// - [radius]: The radius in meters within which to search for the closest address.
  /// - [onlyCity]: Specifies whether to only search for addresses within cities.
  ///
  /// ## Returns
  ///
  /// - The closest [Landmark] representing the address if found, otherwise `null`.
  Future<Landmark?> getClosestAddressLandmark({
    required Coordinates coords,
    required int radius,
    required bool onlyCity,
  }) async {
    final String? resultString = await GemKitPlatform.instance
        .getChannel(mapId: mapId)
        .invokeMethod<String>(
          'callObjectMethod',
          jsonEncode(<String, dynamic>{
            'id': _pointerId,
            'class': 'MapView',
            'method': 'getClosestAddress',
            'args': <String, dynamic>{
              'c': coords,
              'radius': radius,
              'onlyCity': onlyCity,
            },
          }),
        );

    if (resultString == null) {
      return null;
    }

    final int id = jsonDecode(resultString)['result'];
    if (id == -1) {
      return null;
    } else {
      return Landmark.init(id);
    }
  }

  /// Handle a touch event delivered to the map view.
  ///
  /// Sends a single pointer touch event (down/move/up/cancel) to the map view
  /// for processing. The call is non-blocking; the event is dispatched for
  /// handling and this method returns immediately. Use this to forward raw
  /// pointer events received by the embedding application so the map can
  /// respond to user interaction.
  ///
  /// The API user usually does not need to call this method directly, as the
  /// [GemMapController] automatically forwards touch events.
  ///
  /// ## Parameters
  ///
  /// - [pointerIndex]: The pointer index of the touch event (multi-touch index).
  /// - [touchType]: The type of the touch event:
  ///   - `0` = down
  ///   - `1` = move
  ///   - `2` = up
  ///   - `3` = cancel
  /// - [x]: The x coordinate of the touch event in physical pixels, relative to the map view's top-left corner.
  /// - [y]: The y coordinate of the touch event in physical pixels, relative to the map view's top-left corner.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] as the event was sent for processing.
  GemError handleTouchEvent(
    final int pointerIndex,
    final int touchType,
    final int x,
    final int y,
  ) {
    unawaited(
      GemKitPlatform.instance
          .getChannel(mapId: mapId)
          .invokeMethod<void>('handleTouchEvent', <String, int>{
            'id': _pointerId,
            'x': x,
            'y': y,
            'touchType': touchType,
            'pointerIndex': pointerIndex,
          }),
    );
    return GemError.success;
  }

  /// Sets the properties of the watermark logo.
  ///
  /// Configures the on-screen position, size and opacity used when the
  /// watermark logo is rendered.
  ///
  /// ## Parameters
  ///
  /// - [pos]: The watermark position on the screen. Defaults to [WatermarkPosition.bottomRight].
  /// - [sizeMM]: The watermark size in millimeters. Minimum value is `15` mm. Defaults to `15`.
  /// - [alpha]: The watermark opacity in the `[0, 1]` range. Minimum effective value is `0.3`. Defaults to `0.5`.
  ///
  /// ## See also:
  ///
  /// - [watermarkLogoVisibility] - Toggle the watermark logo visibility.
  void setWatermarkLogoProperties({
    final WatermarkPosition pos = WatermarkPosition.bottomRight,
    final double sizeMM = 15.0,
    final double alpha = 0.5,
  }) {
    objectMethod(
      _pointerId,
      'MapView',
      'setWatermarkLogoProperties',
      args: <String, Object>{'pos': pos.id, 'sizeMM': sizeMM, 'alpha': alpha},
    );
  }

  /// Sets the visibility of the watermark logo.
  ///
  /// The watermark logo can not be hidden when running as an SDK application
  /// — only commercial/licensed apps may toggle the logo off.
  ///
  /// ## Parameters
  ///
  /// - [visible]: `true` to show the watermark logo, `false` to hide it.
  ///
  /// ## See also:
  ///
  /// - [setWatermarkLogoProperties] - Adjust watermark logo size, position and opacity.
  set watermarkLogoVisibility(final bool visible) {
    objectMethod(
      _pointerId,
      'MapView',
      'setWatermarkLogoVisibility',
      args: visible,
    );
  }
}

/// Route display modes used for centering and viewport calculations.
///
/// Controls how one or more routes are considered when computing optimal
/// viewports or centering the map. Choose a mode to either include the full
/// geometry of routes or focus on differing/branched segments between routes.
///
/// ## See also:
///
/// - [GemView.centerOnRoute] - Center map on a single route.
/// - [GemView.centerOnRoutes] - Center map on multiple routes.
/// - [GemView.getOptimalRoutesCenterViewport] - Compute optimal viewport for routes.
///
/// {@category Maps & 3D Scenes}
enum RouteDisplayMode {
  /// Full route display
  full,

  /// Zoom to the branched part of the route
  branches,
}

/// @nodoc
extension RouteDisplayModeExtension on RouteDisplayMode {
  int get id {
    switch (this) {
      case RouteDisplayMode.full:
        return 0;
      case RouteDisplayMode.branches:
        return 1;
    }
  }

  static RouteDisplayMode fromId(final int id) {
    switch (id) {
      case 0:
        return RouteDisplayMode.full;
      case 1:
        return RouteDisplayMode.branches;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Represents the follow position state for the map view.
///
/// Indicates how the map should track the user or device position (for example,
/// whether the map recenters or rotates to follow position updates). This state
/// is typically observed to update UI or to restore previous follow behavior
/// after user interaction.
///
/// ## See also:
///
/// - [GemMapController.registerOnFollowPositionState] - Listen for follow position state changes.
/// - [GemMapController.registerOnTouchHandlerModifyFollowPosition] - Handle user interactions affecting follow position.
///
/// {@category Maps & 3D Scenes}
enum FollowPositionState {
  /// Enter following position
  entered,

  /// Exit following position
  ///
  /// Triggered when the [GemView.restoreFollowingPosition] method is called.
  exited,
}

/// Watermark logo placement on the map view.
///
/// Controls where the watermark logo is anchored on the rendered map. The
/// chosen position is used together with [GemView.setWatermarkLogoProperties].
///
/// ## See also:
///
/// - [GemView.setWatermarkLogoProperties] - Configure the watermark logo.
/// - [GemView.watermarkLogoVisibility] - Show or hide the watermark logo.
///
/// {@category Maps & 3D Scenes}
enum WatermarkPosition {
  /// Watermark on the left side of the screen.
  left,

  /// Watermark on the right side of the screen.
  right,

  /// Watermark on the top side of the screen.
  top,

  /// Watermark on the bottom side of the screen.
  bottom,

  /// Watermark in the center of the screen.
  center,

  /// Watermark on the top left corner of the screen.
  topLeft,

  /// Watermark on the top right corner of the screen.
  topRight,

  /// Watermark on the bottom left corner of the screen.
  bottomLeft,

  /// Watermark on the bottom right corner of the screen.
  bottomRight,
}

/// @nodoc
extension WatermarkPositionExtension on WatermarkPosition {
  int get id {
    switch (this) {
      case WatermarkPosition.left:
        return 0;
      case WatermarkPosition.right:
        return 1;
      case WatermarkPosition.top:
        return 2;
      case WatermarkPosition.bottom:
        return 3;
      case WatermarkPosition.center:
        return 4;
      case WatermarkPosition.topLeft:
        return 5;
      case WatermarkPosition.topRight:
        return 6;
      case WatermarkPosition.bottomLeft:
        return 7;
      case WatermarkPosition.bottomRight:
        return 8;
    }
  }

  static WatermarkPosition fromId(final int id) {
    switch (id) {
      case 0:
        return WatermarkPosition.left;
      case 1:
        return WatermarkPosition.right;
      case 2:
        return WatermarkPosition.top;
      case 3:
        return WatermarkPosition.bottom;
      case 4:
        return WatermarkPosition.center;
      case 5:
        return WatermarkPosition.topLeft;
      case 6:
        return WatermarkPosition.topRight;
      case 7:
        return WatermarkPosition.bottomLeft;
      case 8:
        return WatermarkPosition.bottomRight;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
