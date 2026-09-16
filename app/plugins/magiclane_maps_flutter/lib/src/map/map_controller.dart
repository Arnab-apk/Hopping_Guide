// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:async';
import 'dart:math';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/map_view_listener.dart';
import 'package:meta/meta.dart';

/// Controller for a single [GemMap] instance running on the host platform.
///
/// Obtain an instance from the [GemMap.onMapCreated] callback; do not construct
/// this class directly. The controller exposes
/// camera control, coordinate transforms, highlighting,
/// marker and overlay integration, map capture, and follow-position behavior.
///
/// Typical uses include programmatic camera manipulation, persisting or
/// restoring view state, driving custom overlays, and reacting to interaction
/// events such as touches, gestures, hover selections, and render or resize
/// notifications. Use [preferences] for map configuration and [extensions] for
/// optional feature access.
///
/// ## See also:
///
/// - [GemMap] – Widget that owns the controller lifecycle.
/// - [MapCamera] – Camera controller available via [camera].
/// - [FollowPositionPreferences] – Configure follow-position behavior.
/// - [MapViewPreferences] – Customize rendering and interaction options.
///
/// {@category Maps & 3D Scenes}
class GemMapController extends GemView {
  GemMapController._(super.vid, super.mId) : super.init();
  Timer? _delayedEvent;
  double? _pixelSize;
  bool _isCameraMoving = false;

  MoveCallback? _moveCallback;
  MoveCallback? _touchMoveCallback;
  SwipeCallback? _swipeCallback;
  PinchSwipeCallback? _pinchSwipeCallback;
  PinchCallback? _pinchCallback;
  TouchPinchCallback? _touchPinchCallback;
  TouchCallback? _touchCallback;
  TouchCallback? _touchLongPressCallback;
  TouchCallback? _touchDoubleCallback;
  TouchCallback? _touchTwoCallback;
  TouchCallback? _touchTwoDoubleCallback;

  // Register not exposed as methods are not working
  TouchPointerCallback? _pointerUpCallback;
  TouchPointerCallback? _pointerMoveCallback;
  TouchPointerCallback? _pointerDownCallback;

  FollowPositionStateCallback? _followPositionStateCallback;
  FollowPositionStateCallback? _touchHandlerModifyFollowPosition;
  MapAngleUpdateCallback? _mapAngleUpdateCallback;
  MapViewRenderedCallback? _mapViewRenderedCallback;
  MapViewMoveStateChangedCallback? _mapViewMoveStateChangedCallback;
  ViewportResizedCallback? _viewportResizedCallback;
  RenderMapScaleCallback? _renderMapScaleCallback;
  ShoveCallback? _shoveCallback;

  CursorSelectionCallback<List<Landmark>>? _cursorSelectionCallbackLandmarks;
  CursorSelectionCallback<List<OverlayItem>>?
  _cursorSelectionCallbackOverlayItems;
  CursorSelectionCallback<List<Route>>? _cursorSelectionCallbackRoutes;
  CursorSelectionCallback<List<MarkerMatch>>? _cursorSelectionCallbackMarkers;
  CursorSelectionCallback<List<TrafficEvent>>?
  _cursorSelectionCallbackTrafficEvents;
  CursorSelectionCallback<Path>? _cursorSelectionCallbackPath;
  CursorSelectionCallback<MapSceneObject>?
  _cursorSelectionCallbackMapSceneObject;

  HoveredMapLabelHighlightedLandmarkCallback?
  _hoveredMapLabelHighlightedLandmark;
  HoveredMapLabelHighlightedOverlayItemCallback?
  _hoveredMapLabelHighlightedOverlayItem;
  HoveredMapLabelHighlightedTrafficEventCallback?
  _hoveredMapLabelHighlightedTrafficEvent;

  SetMapStyleCallback? _setMapStyle;

  ///@nodoc
  @internal
  static Future<GemMapController> init(
    final int mapId,
    final GemMapState gemMapState, {
    final double? pixelSize = 1.0,
  }) async {
    final dynamic result = await GemKitPlatform.instance.init(mapId);
    final int viewId = result['viewId'];
    final GemMapController retVal = GemMapController._(viewId, mapId);
    retVal._pixelSize = pixelSize;
    return retVal;
  }

  ///@nodoc
  @internal
  void registerForEventsHandler() {
    GemKitPlatform.instance.registerEventHandler(pointerId, this);

    GemKitPlatform.instance.filterEvents(pointerId, <String>[
      'mapViewOnTouch',
      'onMove',
      'onTouchMove',
      'onSwipe',
      'onPinchSwipe',
      'onPinch',
      'onTouchPinch',
      'mapViewOnLongDown',
      'onDoubleTouch',
      'onTwoTouches',
      'onTwoDoubleTouches',
      'mapViewFollowPositionEntered',
      'mapViewFollowPositionExited',
      'onEnterTouchHandlerModifyFollowingPosition',
      'onExitTouchHandlerModifyFollowingPosition',
      'onMapAngleUpdate',
      'mapViewResizedEvent',
      'renderMapScale',
      'onShove',
      'onCursorSelectionUpdatedLandmarks',
      'onCursorSelectionUpdatedOverlayItems',
      'onCursorSelectionMarkerMatches',
      'onCursorSelectionUpdatedTrafficEvents',
      'onCursorSelectionUpdatedRoutes',
      'onCursorSelectionPath',
      'onCursorSelectionMapSceneObject',
      'onHoveredMapLabelHighlightedLandmark',
      'onHoveredMapLabelHighlightedOverlayItem',
      'onHoveredMapLabelHighlightedTrafficEvent',
      'onSetMapStyle',
    ], true);
  }

  /// Registers a callback for single-pointer touch down events.
  ///
  /// A touch event is fired when a pointer goes down and up within the SDK
  /// gesture thresholds for time and travel distance.
  ///
  /// ## Parameters
  /// - [touchCallback]: (`TouchCallback?`) Invoked with the touch position.
  ///   Pass `null` to stop receiving notifications.
  void registerOnTouch(final TouchCallback? touchCallback) {
    _touchCallback = touchCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'mapViewOnTouch',
      touchCallback == null,
    );
  }

  /// Registers a callback for single-pointer move gestures.
  ///
  /// A move event is emitted for drag gestures formed by pointer down → move →
  /// pointer up.
  ///
  /// ## Parameters
  /// - [moveCallback]: (`MoveCallback?`) Receives the start and end positions.
  ///   Pass `null` to cancel registration.
  void registerOnMove(final MoveCallback? moveCallback) {
    _moveCallback = moveCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onMove',
      moveCallback == null,
    );
  }

  /// Registers a callback for touch-move gestures after tap-and-hold.
  ///
  /// Touch-move mode is triggered by a tap immediately followed by another
  /// pointer down in the same area, then a move.
  ///
  /// ## Parameters
  /// - [touchMoveCallback]: (`MoveCallback?`) Receives the drag start and end
  ///   positions. Pass `null` to stop listening.
  void registerOnTouchMove(final MoveCallback? touchMoveCallback) {
    _touchMoveCallback = touchMoveCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onTouchMove',
      touchMoveCallback == null,
    );
  }

  /// Registers a callback for single-pointer swipe (fling) gestures.
  ///
  /// Swipe events consist of a pointer down, rapid move, and release.
  ///
  /// ## Parameters
  /// - [swipeCallback]: (`SwipeCallback?`) Receives delta distances and speed
  ///   information. Pass `null` to unregister.
  void registerOnSwipe(final SwipeCallback? swipeCallback) {
    _swipeCallback = swipeCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onSwipe',
      swipeCallback == null,
    );
  }

  /// Registers a callback for two-pointer pinch-swipe gestures.
  ///
  /// A pinch-swipe occurs when two pointers touch, then move quickly to zoom or
  /// rotate while lifting.
  ///
  /// ## Parameters
  /// - [pinchSwipeCallback]: (`PinchSwipeCallback?`) Receives the gesture
  ///   center and zoom/rotation speeds. Pass `null` to unsubscribe.
  void registerOnPinchSwipe(final PinchSwipeCallback? pinchSwipeCallback) {
    _pinchSwipeCallback = pinchSwipeCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onPinchSwipe',
      pinchSwipeCallback == null,
    );
  }

  /// Registers a callback for continuous two-pointer pinch gestures.
  ///
  /// A pinch is formed by two pointers moving while remaining in contact with
  /// the screen.
  ///
  /// ## Parameters
  /// - [pinchCallback]: (`PinchCallback?`) Receives start/end positions and the
  ///   computed center. Pass `null` to stop receiving pinches.
  void registerOnPinch(final PinchCallback? pinchCallback) {
    _pinchCallback = pinchCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onPinch',
      pinchCallback == null,
    );
  }

  /// Registers a callback for touch-initiated pinch gestures.
  ///
  /// Touch-pinch mode starts with a single tap immediately followed by two
  /// pointers landing near the original touch.
  ///
  /// ## Parameters
  /// - [touchPinchCallback]: (`TouchPinchCallback?`) Receives pointer
  ///   trajectories. Pass `null` to unregister.
  void registerOnTouchPinch(final TouchPinchCallback? touchPinchCallback) {
    _touchPinchCallback = touchPinchCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onTouchPinch',
      touchPinchCallback == null,
    );
  }

  /// Registers a callback for long-press gestures.
  ///
  /// The gesture fires when a pointer remains down past the long-press
  /// threshold with minimal movement.
  ///
  /// ## Parameters
  /// - [touchCallback]: (`TouchCallback?`) Invoked with the touch position.
  ///   Pass `null` to unregister.
  void registerOnLongPress(final TouchCallback? touchCallback) {
    _touchLongPressCallback = touchCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'mapViewOnLongDown',
      touchCallback == null,
    );
  }

  /// Registers a callback for double-touch (double-tap) gestures.
  ///
  /// The gesture is detected when two taps occur within the configured time
  /// and distance thresholds.
  ///
  /// ## Parameters
  /// - [doubleTouchCallback]: (`TouchCallback?`) Invoked with the touch
  ///   position. Pass `null` to unregister.
  void registerOnDoubleTouch(final TouchCallback? doubleTouchCallback) {
    _touchDoubleCallback = doubleTouchCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onDoubleTouch',
      doubleTouchCallback == null,
    );
  }

  /// Registers a callback for simultaneous two-pointer touch gestures.
  ///
  /// Two-touch events occur when two pointers land and lift within the gesture
  /// thresholds.
  ///
  /// ## Parameters
  /// - [twoTouchCallback]: (`TouchCallback?`) Receives the midpoint between the
  ///   two touch points. Pass `null` to stop listening.
  void registerOnTwoTouches(final TouchCallback? twoTouchCallback) {
    _touchTwoCallback = twoTouchCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onTwoTouches',
      twoTouchCallback == null,
    );
  }

  /// Registers a callback for two-pointer double-touch gestures.
  ///
  /// The event fires when two consecutive two-touch gestures occur within the
  /// configured timing thresholds.
  ///
  /// ## Parameters
  /// - [twoDoubleTouchCallback]: (`TouchCallback?`) Receives the midpoint of
  ///   the touch positions. Pass `null` to unsubscribe.
  void registerOnTwoDoubleTouches(final TouchCallback? twoDoubleTouchCallback) {
    _touchTwoDoubleCallback = twoDoubleTouchCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onTwoDoubleTouches',
      twoDoubleTouchCallback == null,
    );
  }

  /// Registers for follow-position state changes.
  ///
  /// The callback is invoked when the map enters or exits follow mode.
  ///
  /// ## Parameters
  /// - [followPositionStateUpdatedCallback]: (`FollowPositionStateCallback?`)
  ///   Receives the current follow state. Pass `null` to unregister.
  void registerOnFollowPositionState(
    final FollowPositionStateCallback? followPositionStateUpdatedCallback,
  ) {
    _followPositionStateCallback = followPositionStateUpdatedCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'mapViewFollowPositionEntered',
      followPositionStateUpdatedCallback == null,
    );
    GemKitPlatform.instance.filterEvent(
      pointerId,
      'mapViewFollowPositionExited',
      followPositionStateUpdatedCallback == null,
    );
  }

  /// Registers for manual follow-position modifications triggered by touch.
  ///
  /// The callback is invoked when the camera enters or exits a manually
  /// adjusted follow state.
  ///
  /// ## Parameters
  /// - [touchHandlerModifyFollowPositionCallback]:
  ///   (`FollowPositionStateCallback?`) Receives the follow state updates. Pass
  ///   `null` to unregister.
  ///
  /// ## Also see:
  ///
  /// - [FollowPositionPreferences] - Configure touch handler behavior in follow
  ///  position mode.
  void registerOnTouchHandlerModifyFollowPosition(
    final FollowPositionStateCallback? touchHandlerModifyFollowPositionCallback,
  ) {
    _touchHandlerModifyFollowPosition =
        touchHandlerModifyFollowPositionCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onEnterTouchHandlerModifyFollowingPosition',
      touchHandlerModifyFollowPositionCallback == null,
    );
    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onExitTouchHandlerModifyFollowingPosition',
      touchHandlerModifyFollowPositionCallback == null,
    );
  }

  /// Registers for map angle updates.
  ///
  /// The callback is invoked when the map bearing changes, either from user
  /// rotation or GPS updates while tracking.
  ///
  /// ## Parameters
  /// - [mapAngleUpdatedCallback]: (`MapAngleUpdateCallback?`) Receives the map
  ///   angle in degrees (0–360). Pass `null` to unregister.
  void registerOnMapAngleUpdate(
    final MapAngleUpdateCallback? mapAngleUpdatedCallback,
  ) {
    _mapAngleUpdateCallback = mapAngleUpdatedCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onMapAngleUpdate',
      mapAngleUpdatedCallback == null,
    );
  }

  /// Registers for map move start/stop events.
  ///
  /// Invoked whenever native code detects that the camera started or stopped
  /// moving.
  ///
  /// ## Parameters
  /// - [onMapViewMoveStateChangedCallback]:
  ///   (`MapViewMoveStateChangedCallback?`) Receives the movement flag and the
  ///   visible geographic area. Pass `null` to unregister.
  void registerOnMapViewMoveStateChanged(
    final MapViewMoveStateChangedCallback? onMapViewMoveStateChangedCallback,
  ) {
    _mapViewMoveStateChangedCallback = onMapViewMoveStateChangedCallback;
  }

  /// Registers for map render completion notifications.
  ///
  /// Native code invokes this callback after each frame finishes rendering.
  ///
  /// ## Parameters
  /// - [onMapViewRenderedCallback]: (`MapViewRenderedCallback?`) Receives
  ///   render metadata. Pass `null` to unregister.
  void registerOnViewRendered(
    final MapViewRenderedCallback? onMapViewRenderedCallback,
  ) {
    _mapViewRenderedCallback = onMapViewRenderedCallback;
  }

  /// Registers for viewport resize notifications.
  ///
  /// The callback is triggered when the native map canvas changes size.
  ///
  /// ## Parameters
  /// - [viewportResizedCallback]: (`ViewportResizedCallback?`) Receives the new
  ///   viewport rectangle. Pass `null` to unsubscribe.
  void registerOnViewportResized(
    final ViewportResizedCallback? viewportResizedCallback,
  ) {
    _viewportResizedCallback = viewportResizedCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'mapViewResizedEvent',
      viewportResizedCallback == null,
    );
  }

  /// Registers for map scale rendering callbacks.
  ///
  /// Requires [MapViewPreferences.showMapScale] to be `true`. Adjust scale
  /// positioning using [MapViewPreferences.mapScalePosition].
  ///
  /// ## Parameters
  /// - [scaleCallback]: (`RenderMapScaleCallback?`) Receives scale width,
  ///   value, and units. Pass `null` to unregister.
  void registerOnRenderMapScale(final RenderMapScaleCallback? scaleCallback) {
    _renderMapScaleCallback = scaleCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'renderMapScale',
      scaleCallback == null,
    );
  }

  /// Registers for two-pointer shove gestures.
  ///
  /// A shove occurs when two pointers move while keeping their spacing and
  /// relative angle within thresholds.
  ///
  /// ## Parameters
  /// - [shoveCallback]: (`ShoveCallback?`) Receives the pointer angle and
  ///   midpoint trajectory. Pass `null` to unregister.
  void registerOnShove(final ShoveCallback? shoveCallback) {
    _shoveCallback = shoveCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onShove',
      shoveCallback == null,
    );
  }

  /// Registers for cursor-hover landmark selections.
  ///
  /// Invoked when the native view detects that the cursor hovers over one or
  /// more landmarks.
  ///
  /// ## Parameters
  /// - [cursorSelectionLandmarksCallback]:
  ///   (`CursorSelectionCallback<List<Landmark>>?`) Receives the selected
  ///   landmarks. Pass `null` to unregister.
  ///
  /// ## Also see:
  ///
  /// - [setCursorScreenPosition] - Move the cursor programmatically to a
  ///  desired screen position.
  void registerOnCursorSelectionUpdatedLandmarks(
    final CursorSelectionCallback<List<Landmark>>?
    cursorSelectionLandmarksCallback,
  ) {
    _cursorSelectionCallbackLandmarks = cursorSelectionLandmarksCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onCursorSelectionUpdatedLandmarks',
      cursorSelectionLandmarksCallback == null,
    );
  }

  /// Registers for cursor-hover overlay item selections.
  ///
  /// Triggered when the cursor hovers over overlay items such as traffic
  /// events.
  ///
  /// ## Parameters
  /// - [cursorSelectionOverlayItemsCallback]:
  ///   (`CursorSelectionCallback<List<OverlayItem>>?`) Receives the selected
  ///   overlay items. Pass `null` to unregister.
  ///
  /// ## Also see:
  ///
  /// - [setCursorScreenPosition] - Move the cursor programmatically to a
  ///  desired screen position.
  void registerOnCursorSelectionUpdatedOverlayItems(
    final CursorSelectionCallback<List<OverlayItem>>?
    cursorSelectionOverlayItemsCallback,
  ) {
    _cursorSelectionCallbackOverlayItems = cursorSelectionOverlayItemsCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onCursorSelectionUpdatedOverlayItems',
      cursorSelectionOverlayItemsCallback == null,
    );
  }

  /// Registers for cursor-hover marker selections.
  ///
  /// Called when the cursor hovers over markers rendered on the map.
  ///
  /// ## Parameters
  /// - [cursorSelectionMarkersCallback]:
  ///   (`CursorSelectionCallback<List<MarkerMatch>>?`) Receives marker match
  ///   information. Pass `null` to unregister.
  ///
  /// ## Also see:
  ///
  /// - [setCursorScreenPosition] - Move the cursor programmatically to a
  ///  desired screen position.
  void registerOnCursorSelectionUpdatedMarkers(
    final CursorSelectionCallback<List<MarkerMatch>>?
    cursorSelectionMarkersCallback,
  ) {
    _cursorSelectionCallbackMarkers = cursorSelectionMarkersCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onCursorSelectionMarkerMatches',
      cursorSelectionMarkersCallback == null,
    );
  }

  /// Registers for cursor-hover traffic event selections.
  ///
  /// Called when the cursor hovers over traffic events.
  ///
  /// ## Parameters
  /// - [cursorSelectionRouteTrafficCallback]:
  ///   (`CursorSelectionCallback<List<TrafficEvent>>?`) Receives the selected
  ///   traffic events. Pass `null` to unsubscribe.
  ///
  /// ## Also see:
  ///
  /// - [setCursorScreenPosition] - Move the cursor programmatically to a
  ///  desired screen position.
  void registerOnCursorSelectionUpdatedTrafficEvents(
    final CursorSelectionCallback<List<TrafficEvent>>?
    cursorSelectionRouteTrafficCallback,
  ) {
    _cursorSelectionCallbackTrafficEvents = cursorSelectionRouteTrafficCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onCursorSelectionUpdatedTrafficEvents',
      cursorSelectionRouteTrafficCallback == null,
    );
  }

  /// Registers for cursor-hover route selections.
  ///
  /// Triggered when the cursor hovers over route polylines.
  ///
  /// ## Parameters
  /// - [cursorSelectionRoutesCallback]:
  ///   (`CursorSelectionCallback<List<Route>>?`) Receives the selected routes.
  ///   Pass `null` to unregister.
  ///
  /// ## Also see:
  ///
  /// - [setCursorScreenPosition] - Move the cursor programmatically to a
  ///  desired screen position.
  void registerOnCursorSelectionUpdatedRoutes(
    final CursorSelectionCallback<List<Route>>? cursorSelectionRoutesCallback,
  ) {
    _cursorSelectionCallbackRoutes = cursorSelectionRoutesCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onCursorSelectionUpdatedRoutes',
      cursorSelectionRoutesCallback == null,
    );
  }

  /// Registers for cursor-hover path selections.
  ///
  /// Invoked when the cursor hovers over a vector path.
  ///
  /// ## Parameters
  /// - [cursorSelectionPathCallback]: (`CursorSelectionCallback<Path>?`)
  ///   Receives the selected path. Pass `null` to unregister.
  ///
  /// ## Also see:
  ///
  /// - [setCursorScreenPosition] - Move the cursor programmatically to a
  ///  desired screen position.
  void registerOnCursorSelectionUpdatedPath(
    final CursorSelectionCallback<Path>? cursorSelectionPathCallback,
  ) {
    _cursorSelectionCallbackPath = cursorSelectionPathCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onCursorSelectionPath',
      cursorSelectionPathCallback == null,
    );
  }

  /// Registers for cursor-hover map scene object selections.
  ///
  /// Called when hovering over scene objects such as 3D models.
  ///
  /// ## Parameters
  /// - [cursorSelectionMapSceneObjectCallback]:
  ///   (`CursorSelectionCallback<MapSceneObject>?`) Receives the selected scene
  ///   object. Pass `null` to unregister.
  ///
  /// ## Also see:
  ///
  /// - [setCursorScreenPosition] - Move the cursor programmatically to a
  ///  desired screen position.
  void registerOnCursorSelectionUpdatedMapSceneObject(
    final CursorSelectionCallback<MapSceneObject>?
    cursorSelectionMapSceneObjectCallback,
  ) {
    _cursorSelectionCallbackMapSceneObject =
        cursorSelectionMapSceneObjectCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onCursorSelectionMapSceneObject',
      cursorSelectionMapSceneObjectCallback == null,
    );
  }

  /// Registers for hovered map label landmark highlights.
  ///
  /// Hover notifications are produced after calling
  /// [GemMapController.highlightHoveredMapLabel].
  ///
  /// ## Parameters
  /// - [hoveredMapLabelHighlightedLandmarkCallback]:
  ///   (`HoveredMapLabelHighlightedLandmarkCallback?`) Receives the highlighted
  ///   landmark. Pass `null` to unregister.
  ///
  /// ## Also see:
  ///
  /// - [setCursorScreenPosition] - Move the cursor programmatically to a
  ///  desired screen position.
  void registerOnHoveredMapLabelHighlightedLandmark(
    final HoveredMapLabelHighlightedLandmarkCallback?
    hoveredMapLabelHighlightedLandmarkCallback,
  ) {
    _hoveredMapLabelHighlightedLandmark =
        hoveredMapLabelHighlightedLandmarkCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onHoveredMapLabelHighlightedLandmark',
      hoveredMapLabelHighlightedLandmarkCallback == null,
    );
  }

  /// Registers for hovered map label overlay item highlights.
  ///
  /// Hover notifications are produced after calling
  /// [GemMapController.highlightHoveredMapLabel].
  ///
  /// ## Parameters
  /// - [hoveredMapLabelHighlightedOverlayItemCallback]:
  ///   (`HoveredMapLabelHighlightedOverlayItemCallback?`) Receives the
  ///   highlighted overlay item. Pass `null` to unregister.
  ///
  /// ## Also see:
  ///
  /// - [setCursorScreenPosition] - Move the cursor programmatically to a
  ///  desired screen position.
  void registerOnHoveredMapLabelHighlightedOverlayItem(
    final HoveredMapLabelHighlightedOverlayItemCallback?
    hoveredMapLabelHighlightedOverlayItemCallback,
  ) {
    _hoveredMapLabelHighlightedOverlayItem =
        hoveredMapLabelHighlightedOverlayItemCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onHoveredMapLabelHighlightedOverlayItem',
      hoveredMapLabelHighlightedOverlayItemCallback == null,
    );
  }

  /// Registers for hovered map label traffic event highlights.
  ///
  /// Hover notifications are produced after calling
  /// [GemMapController.highlightHoveredMapLabel].
  ///
  /// ## Parameters
  /// - [hoveredMapLabelHighlightedTrafficEventCallback]:
  ///   (`HoveredMapLabelHighlightedTrafficEventCallback?`) Receives the
  ///   highlighted traffic event. Pass `null` to unregister.
  ///
  /// ## Also see:
  ///
  /// - [setCursorScreenPosition] - Move the cursor programmatically to a
  ///  desired screen position.
  void registerOnHoveredMapLabelHighlightedTrafficEvent(
    final HoveredMapLabelHighlightedTrafficEventCallback?
    hoveredMapLabelHighlightedTrafficEventCallback,
  ) {
    _hoveredMapLabelHighlightedTrafficEvent =
        hoveredMapLabelHighlightedTrafficEventCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onHoveredMapLabelHighlightedTrafficEvent',
      hoveredMapLabelHighlightedTrafficEventCallback == null,
    );
  }

  /// Registers for map style change notifications.
  ///
  /// Fired when the map style is updated, either through the API or by native
  /// defaults.
  ///
  /// ## Parameters
  /// - [setMapStyleCallback]: (`SetMapStyleCallback?`) Receives content store
  ///   identifiers and style path metadata. Pass `null` to unregister.
  ///
  /// ## Also see:
  ///
  /// - [MapViewPreferences.setMapStyle] - Configure the map style.
  void registerOnSetMapStyle(final SetMapStyleCallback? setMapStyleCallback) {
    _setMapStyle = setMapStyleCallback;

    GemKitPlatform.instance.filterEvent(
      pointerId,
      'onSetMapStyle',
      setMapStyleCallback == null,
    );
  }

  @override
  void onViewportResized(final Rectangle<int> viewportIn) {
    _viewportResizedCallback?.call(viewportIn);
  }

  @override
  void onTouch(final Point<int> pos) {
    _touchCallback?.call(pos);
  }

  @override
  void onLongPress(final Point<int> pos) {
    _touchLongPressCallback?.call(pos);
  }

  @override
  void onPointerUp(final int pointerId, final Point<num> pos) {
    _pointerUpCallback?.call(pointerId, pos);
  }

  @override
  void onPointerMove(final int pointerId, final Point<num> pos) {
    _pointerMoveCallback?.call(pointerId, pos);
  }

  @override
  void onPointerDown(final int pointerId, final Point<num> pos) {
    _pointerDownCallback?.call(pointerId, pos);
  }

  @override
  void onMove(final Point<num> startPoint, final Point<num> endPoint) {
    _moveCallback?.call(startPoint, endPoint);
  }

  @override
  void onPinch(
    final Point<int> start1,
    final Point<int> start2,
    final Point<int> end1,
    final Point<int> end2,
    final Point<int> center,
  ) {
    _pinchCallback?.call(start1, start2, end1, end2, center);
  }

  @override
  void onPinchSwipe(
    final Point<int> centerPosInPix,
    final double zoomingSpeedInMMPerSec,
    final double rotatingSpeedInMMPerSec,
  ) {
    _pinchSwipeCallback?.call(
      centerPosInPix,
      zoomingSpeedInMMPerSec,
      rotatingSpeedInMMPerSec,
    );
  }

  @override
  void onSwipe(final int distX, final int distY, final double speedMmPerSec) {
    _swipeCallback?.call(distX, distY, speedMmPerSec);
  }

  @override
  void onTouchMove(final Point<int> startPos, final Point<int> endPos) {
    _touchMoveCallback?.call(startPos, endPos);
  }

  @override
  void onTouchPinch(
    final Point<int> start1,
    final Point<int> start2,
    final Point<int> end1,
    final Point<int> end2,
  ) {
    _touchPinchCallback?.call(start1, start2, end1, end2);
  }

  @override
  void onFollowPositionState(final FollowPositionState followPositionState) {
    _followPositionStateCallback?.call(followPositionState);
  }

  @override
  void onTouchHandlerModifyFollowPosition(
    final FollowPositionState followPositionState,
  ) {
    _touchHandlerModifyFollowPosition?.call(followPositionState);
  }

  @override
  void onMapAngleUpdate(final double angle) {
    _mapAngleUpdateCallback?.call(angle);
  }

  @override
  void onMarkerRender(final dynamic data) {
    preferences.markers.onMarkerRender(this, data);
  }

  @override
  void onRenderMapScale(
    final int scaleWidth,
    final int scaleValue,
    final String scaleUnits,
  ) {
    _renderMapScaleCallback?.call(scaleWidth, scaleValue, scaleUnits);
  }

  @override
  void onViewRendered(final dynamic data) {
    // if (data['markersIds']!.length > 0) {

    if (_mapViewMoveStateChangedCallback != null) {
      final bool cameraIsMoving = data['cameraStatus'] != 0;
      final Coordinates topLeft = Coordinates.fromLatLong(
        data['leftTopX'],
        data['leftTopY'],
      );
      final Coordinates rightBottom = Coordinates.fromLatLong(
        data['rightBottomX'],
        data['rightBottomY'],
      );

      //bool viewDataTransitionStatus = data['viewDataTransitionStatus'];
      final RectangleGeographicArea pArea = RectangleGeographicArea(
        topLeft: topLeft,
        bottomRight: rightBottom,
      );
      if (_isCameraMoving != cameraIsMoving) {
        //if(viewDataTransitionStatus == false) {
        _isCameraMoving = cameraIsMoving;
        if (_mapViewMoveStateChangedCallback != null) {
          if (_delayedEvent != null) {
            _delayedEvent!.cancel();
          }
          _delayedEvent = Timer(const Duration(milliseconds: 100), () {
            _mapViewMoveStateChangedCallback!(cameraIsMoving, pArea);
          });
        }
        //}
      }
    }
    preferences.markers.onViewRendered(data);
    if (_mapViewRenderedCallback != null) {
      _mapViewRenderedCallback!(MapViewRenderInfo.fromJson(data));
    }
    // }
  }

  @override
  void onShove(
    final double pointersAngleDeg,
    final Point<int> initial,
    final Point<int> start,
    final Point<int> end,
  ) {
    _shoveCallback?.call(pointersAngleDeg, initial, start, end);
  }

  @override
  void onCursorSelectionUpdatedLandmarks(final List<Landmark> landmarks) {
    _cursorSelectionCallbackLandmarks?.call(landmarks);
  }

  @override
  void onCursorSelectionUpdatedMarkers(final List<MarkerMatch> markerMatches) {
    _cursorSelectionCallbackMarkers?.call(markerMatches);
  }

  @override
  void onCursorSelectionUpdatedOverlayItems(
    final List<OverlayItem> overlayItems,
  ) {
    _cursorSelectionCallbackOverlayItems?.call(overlayItems);
  }

  @override
  void onCursorSelectionUpdatedPath(final Path path) {
    _cursorSelectionCallbackPath?.call(path);
  }

  @override
  void onCursorSelectionUpdatedRoutes(final List<Route> routes) {
    _cursorSelectionCallbackRoutes?.call(routes);
  }

  @override
  void onCursorSelectionUpdatedTrafficEvents(
    final List<TrafficEvent> trafficEvents,
  ) {
    _cursorSelectionCallbackTrafficEvents?.call(trafficEvents);
  }

  @override
  void onCursorSelectionUpdatedMapSceneObject(
    final MapSceneObject mapSceneObject,
  ) {
    _cursorSelectionCallbackMapSceneObject?.call(mapSceneObject);
  }

  @override
  void onHoveredMapLabelHighlightedLandmark(final Landmark object) {
    _hoveredMapLabelHighlightedLandmark?.call(object);
  }

  @override
  void onHoveredMapLabelHighlightedOverlayItem(final OverlayItem object) {
    _hoveredMapLabelHighlightedOverlayItem?.call(object);
  }

  @override
  void onHoveredMapLabelHighlightedTrafficEvent(final TrafficEvent object) {
    _hoveredMapLabelHighlightedTrafficEvent?.call(object);
  }

  @override
  void onDoubleTouch(final Point<int> pos) {
    _touchDoubleCallback?.call(pos);
  }

  @override
  void onTwoDoubleTouches(final Point<int> pos) {
    _touchTwoDoubleCallback?.call(pos);
  }

  @override
  void onTwoTouches(final Point<int> pos) {
    _touchTwoCallback?.call(pos);
  }

  @override
  void onSetMapStyle(final int id, final String stylePath, final bool viaApi) {
    _setMapStyle?.call(id, stylePath, viaApi);
  }

  /// The number of device pixels represented by each logical Flutter pixel.
  double get devicePixelSize => _pixelSize!;

  /// Cancels the debounce timer used to coalesce
  /// [_mapViewMoveStateChangedCallback] notifications and detaches this
  /// controller from the event-handler dispatcher so further events from the
  /// native side are dropped.
  ///
  /// Called by [dispose] before [clearListeners] so the event source is
  /// stopped before local references are severed.
  @override
  void nativeClear() {
    _delayedEvent?.cancel();
    _delayedEvent = null;
    GemKitPlatform.instance.unregisterEventHandler(pointerId);
  }

  /// Nulls every registered callback field on this controller so the captured
  /// closures (and the widget/controller graphs they reference) become
  /// eligible for garbage collection.
  ///
  /// Called by [dispose] after [nativeClear].
  @override
  void clearListeners() {
    _moveCallback = null;
    _touchMoveCallback = null;
    _swipeCallback = null;
    _pinchSwipeCallback = null;
    _pinchCallback = null;
    _touchPinchCallback = null;
    _touchCallback = null;
    _touchLongPressCallback = null;
    _touchDoubleCallback = null;
    _touchTwoCallback = null;
    _touchTwoDoubleCallback = null;
    _pointerUpCallback = null;
    _pointerMoveCallback = null;
    _pointerDownCallback = null;
    _followPositionStateCallback = null;
    _touchHandlerModifyFollowPosition = null;
    _mapAngleUpdateCallback = null;
    _mapViewRenderedCallback = null;
    _mapViewMoveStateChangedCallback = null;
    _viewportResizedCallback = null;
    _renderMapScaleCallback = null;
    _shoveCallback = null;
    _cursorSelectionCallbackLandmarks = null;
    _cursorSelectionCallbackOverlayItems = null;
    _cursorSelectionCallbackRoutes = null;
    _cursorSelectionCallbackMarkers = null;
    _cursorSelectionCallbackTrafficEvents = null;
    _cursorSelectionCallbackPath = null;
    _cursorSelectionCallbackMapSceneObject = null;
    _hoveredMapLabelHighlightedLandmark = null;
    _hoveredMapLabelHighlightedOverlayItem = null;
    _hoveredMapLabelHighlightedTrafficEvent = null;
    _setMapStyle = null;
  }

  /// Releases native resources associated with this controller.
  ///
  /// Typically invoked by [GemMap] lifecycle management.
  ///
  /// After calling this method, the controller instance should be
  /// considered invalid. Do not call any other methods on this instance after
  /// calling [dispose].
  /// Also avoid using instances linked to this controller, such as
  /// [MapViewPreferences], [FollowPositionPreferences] and collections.
  ///
  /// Teardown order:
  /// 1. [nativeClear] — cancel the debounce timer and unregister this
  ///    controller from the event-handler dispatcher so straggler events
  ///    arriving in the window between this and step 2 are dropped at the
  ///    Dart-side dispatch boundary.
  /// 2. [clearListeners] — null all callback fields so closures captured by
  ///    the user (typically referencing widgets/controllers) become
  ///    GC-eligible.
  /// 3. [releaseView] — release the native view object.
  ///
  /// Steps 1 and 2 are deliberately not delegated to the inherited
  /// `EventHandler.dispose` template, so that the awaited [releaseView] call
  /// runs in a single coherent body.
  @override
  Future<void> dispose() async {
    nativeClear();
    clearListeners();
    await releaseView();
  }
}
