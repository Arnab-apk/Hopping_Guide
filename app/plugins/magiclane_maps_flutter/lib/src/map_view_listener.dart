// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';

/// Listener interface for map view events.
///
/// The API users should not interact with this interface directly.
/// Instead, use the [GemMapController] class which internally implements
/// this interface.
///
/// API users can register callbacks via [GemMapController] methods to
/// receive map view events. The methods of this interface are invoked
/// by native code to notify about various map interactions and state changes and
/// should be treated as internal implementation details.
///
/// {@category Maps & 3D Scenes}
abstract class MapViewListener {
  /// Called when the map viewport changes size.
  ///
  /// ## Parameters
  ///
  /// - [viewport]: Updated viewport bounds.
  @internal
  void onViewportResized(final Rectangle<int> viewport);

  /// Called when a single-pointer touch down event occurs.
  ///
  /// A touch event is fired when a pointer goes down and up within the SDK
  /// gesture thresholds for time and travel distance.
  ///
  /// ## Parameters
  ///
  /// - [pos]: Touch position in view pixels.
  @internal
  void onTouch(final Point<int> pos);

  /// Called when a pointer is released.
  ///
  /// ## Parameters
  ///
  /// - [pointerId]: Pointer identifier supplied by the platform.
  /// - [pos]: Pointer location in view coordinates.
  @internal
  void onPointerUp(final int pointerId, final Point<int> pos);

  /// Called when a pointer touches down on the view.
  ///
  /// ## Parameters
  ///
  /// - [pointerId]: Pointer identifier supplied by the platform.
  /// - [pos]: Pointer location in view coordinates.
  @internal
  void onPointerDown(final int pointerId, final Point<int> pos);

  /// Called when a pointer moves across the view.
  ///
  /// ## Parameters
  ///
  /// - [pointerId]: Pointer identifier supplied by the platform.
  /// - [pos]: Pointer location in view coordinates.
  @internal
  void onPointerMove(final int pointerId, final Point<int> pos);

  /// Called when the follow-position state changes.
  ///
  /// Invoked when the map enters or exits follow mode.
  ///
  /// ## Parameters
  ///
  /// - [followPositionState]: Current follow-position state.
  @internal
  void onFollowPositionState(final FollowPositionState followPositionState);

  /// Called when follow-position mode is manually adjusted by touch.
  ///
  /// Invoked when the camera enters or exits a manually adjusted follow state.
  ///
  /// ## Parameters
  ///
  /// - [followPositionState]: Current follow-position state.
  @internal
  void onTouchHandlerModifyFollowPosition(
    final FollowPositionState followPositionState,
  );

  /// Called when a single-pointer move (drag) gesture occurs.
  ///
  /// A move event is emitted for drag gestures formed by pointer down → move →
  /// pointer up.
  ///
  /// ## Parameters
  ///
  /// - [startPos]: Drag start location.
  /// - [endPos]: Drag end location.
  @internal
  void onMove(final Point<int> startPos, final Point<int> endPos);

  /// Called when a touch-move gesture occurs after tap-and-hold.
  ///
  /// Touch-move mode is triggered by a tap immediately followed by another
  /// pointer down in the same area, then a move.
  ///
  /// ## Parameters
  ///
  /// - [startPos]: Drag start location.
  /// - [endPos]: Drag end location.
  @internal
  void onTouchMove(final Point<int> startPos, final Point<int> endPos);

  /// Called when a single-pointer swipe (fling) gesture occurs.
  ///
  /// Swipe events consist of a pointer down, rapid move, and release.
  ///
  /// ## Parameters
  ///
  /// - [distX]: Horizontal delta in pixels.
  /// - [distY]: Vertical delta in pixels.
  /// - [speedMmPerSec]: Swipe speed in millimetres per second.
  @internal
  void onSwipe(final int distX, final int distY, final double speedMmPerSec);

  /// Called when a two-pointer pinch-swipe gesture occurs.
  ///
  /// A pinch-swipe occurs when two pointers touch, then move quickly to zoom or
  /// rotate while lifting.
  ///
  /// ## Parameters
  ///
  /// - [centerPosInPix]: Gesture center in pixels.
  /// - [zoomingSpeedInMMPerSec]: Zoom velocity in millimetres per second.
  /// - [rotatingSpeedInMMPerSec]: Rotation velocity in millimetres per second.
  @internal
  void onPinchSwipe(
    final Point<int> centerPosInPix,
    final double zoomingSpeedInMMPerSec,
    final double rotatingSpeedInMMPerSec,
  );

  /// Called when a continuous two-pointer pinch gesture occurs.
  ///
  /// A pinch is formed by two pointers moving while remaining in contact with
  /// the screen.
  ///
  /// ## Parameters
  ///
  /// - [start1]: Initial position of the first pointer.
  /// - [start2]: Initial position of the second pointer.
  /// - [end1]: Current position of the first pointer.
  /// - [end2]: Current position of the second pointer.
  /// - [center]: Computed gesture center.
  @internal
  void onPinch(
    final Point<int> start1,
    final Point<int> start2,
    final Point<int> end1,
    final Point<int> end2,
    final Point<int> center,
  );

  /// Called when a touch-initiated pinch gesture occurs.
  ///
  /// Touch-pinch mode starts with a single tap immediately followed by two
  /// pointers landing near the original touch.
  ///
  /// ## Parameters
  ///
  /// - [start1]: Initial position of the first pointer.
  /// - [start2]: Initial position of the second pointer.
  /// - [end1]: Current position of the first pointer.
  /// - [end2]: Current position of the second pointer.
  @internal
  void onTouchPinch(
    final Point<int> start1,
    final Point<int> start2,
    final Point<int> end1,
    final Point<int> end2,
  );

  /// Called when a long-press gesture is detected.
  ///
  /// The gesture fires when a pointer remains down past the long-press
  /// threshold with minimal movement.
  ///
  /// ## Parameters
  ///
  /// - [pos]: Touch position in view pixels.
  @internal
  void onLongPress(final Point<int> pos);

  /// Called when a double-touch (double-tap) gesture occurs.
  ///
  /// The gesture is detected when two taps occur within the configured time
  /// and distance thresholds.
  ///
  /// ## Parameters
  ///
  /// - [pos]: Touch position in view pixels.
  @internal
  void onDoubleTouch(final Point<int> pos);

  /// Called when a simultaneous two-pointer touch gesture occurs.
  ///
  /// Two-touch events occur when two pointers land and lift within the gesture
  /// thresholds.
  ///
  /// ## Parameters
  ///
  /// - [pos]: Midpoint between the two touch points.
  @internal
  void onTwoTouches(final Point<int> pos);

  /// Called when a two-pointer double-touch gesture occurs.
  ///
  /// The event fires when two consecutive two-touch gestures occur within the
  /// configured timing thresholds.
  ///
  /// ## Parameters
  ///
  /// - [pos]: Midpoint of the touch positions.
  @internal
  void onTwoDoubleTouches(final Point<int> pos);

  /// Called when the map angle (bearing) changes.
  ///
  /// Invoked when the map bearing changes, either from user rotation or GPS
  /// updates while tracking.
  ///
  /// ## Parameters
  ///
  /// - [angle]: Map bearing in degrees (0–360).
  @internal
  void onMapAngleUpdate(final double angle);

  /// Called when marker rendering is required.
  ///
  /// ## Parameters
  ///
  /// - [data]: Marker rendering payload supplied by native code.
  @internal
  void onMarkerRender(final dynamic data);

  /// Called when a map frame finishes rendering.
  ///
  /// Native code invokes this callback after each frame finishes rendering.
  ///
  /// ## Parameters
  ///
  /// - [data]: Render payload including camera status, visible geographic
  ///   bounds, and marker information.
  @internal
  void onViewRendered(final dynamic data);

  /// Called when the map scale should be rendered.
  ///
  /// ## Parameters
  ///
  /// - [scaleWidth]: Scale bar width in pixels.
  /// - [scaleValue]: Numeric value represented by the scale bar.
  /// - [scaleUnits]: Units for the scale (for example, `m`).
  @internal
  void onRenderMapScale(
    final int scaleWidth,
    final int scaleValue,
    final String scaleUnits,
  );

  /// Called when a two-pointer shove gesture occurs.
  ///
  /// A shove occurs when two pointers move while keeping their spacing and
  /// relative angle within thresholds.
  ///
  /// ## Parameters
  ///
  /// - [pointersAngleDeg]: Angle between pointers in degrees.
  /// - [initial]: Midpoint at initial touch down.
  /// - [start]: Midpoint at previous update.
  /// - [end]: Midpoint at current update.
  @internal
  void onShove(
    final double pointersAngleDeg,
    final Point<int> initial,
    final Point<int> start,
    final Point<int> end,
  );

  /// Called when cursor-hover landmark selections are detected.
  ///
  /// Invoked when the native view detects that the cursor hovers over one or
  /// more landmarks.
  ///
  /// ## Parameters
  ///
  /// - [landmarks]: Selected landmarks.
  @internal
  void onCursorSelectionUpdatedLandmarks(final List<Landmark> landmarks);

  /// Called when cursor-hover overlay item selections are detected.
  ///
  /// Triggered when the cursor hovers over overlay items such as traffic
  /// events.
  ///
  /// ## Parameters
  ///
  /// - [overlayItems]: Selected overlay items.
  @internal
  void onCursorSelectionUpdatedOverlayItems(
    final List<OverlayItem> overlayItems,
  );

  /// Called when cursor-hover traffic event selections are detected.
  ///
  /// ## Parameters
  ///
  /// - [trafficEvents]: Selected traffic events.
  @internal
  void onCursorSelectionUpdatedTrafficEvents(
    final List<TrafficEvent> trafficEvents,
  );

  /// Called when cursor-hover route selections are detected.
  ///
  /// Triggered when the cursor hovers over route polylines.
  ///
  /// ## Parameters
  ///
  /// - [routes]: Selected routes.
  @internal
  void onCursorSelectionUpdatedRoutes(final List<Route> routes);

  /// Called when cursor-hover marker selections are detected.
  ///
  /// ## Parameters
  ///
  /// - [markerMatches]: Marker match information.
  @internal
  void onCursorSelectionUpdatedMarkers(final List<MarkerMatch> markerMatches);

  /// Called when cursor-hover path selections are detected.
  ///
  /// Invoked when the cursor hovers over a vector path.
  ///
  /// ## Parameters
  ///
  /// - [path]: Selected path.
  @internal
  void onCursorSelectionUpdatedPath(final Path path);

  /// Called when cursor-hover map scene object selections are detected.
  ///
  /// Called when hovering over scene objects such as 3D models.
  ///
  /// ## Parameters
  ///
  /// - [mapSceneObject]: Selected scene object.
  @internal
  void onCursorSelectionUpdatedMapSceneObject(
    final MapSceneObject mapSceneObject,
  );

  /// Called when a hovered map label landmark is highlighted.
  ///
  /// ## Parameters
  ///
  /// - [object]: Highlighted landmark.
  @internal
  void onHoveredMapLabelHighlightedLandmark(final Landmark object);

  /// Called when a hovered map label overlay item is highlighted.
  ///
  /// ## Parameters
  ///
  /// - [object]: Highlighted overlay item.
  @internal
  void onHoveredMapLabelHighlightedOverlayItem(final OverlayItem object);

  /// Called when a hovered map label traffic event is highlighted.
  ///
  /// ## Parameters
  ///
  /// - [object]: Highlighted traffic event.
  @internal
  void onHoveredMapLabelHighlightedTrafficEvent(final TrafficEvent object);

  /// Called when the map style changes.
  ///
  /// Fired when the map style is updated, either through the API or by native
  /// defaults.
  ///
  /// ## Parameters
  ///
  /// - [id]: Content store identifier for the applied style.
  /// - [stylePath]: Local or logical path of the style resource.
  /// - [viaApi]: `true` if the style originated from an explicit API call.
  @internal
  void onSetMapStyle(final int id, final String stylePath, final bool viaApi);
}

/// Signature for callbacks that receive single-pointer touch positions.
///
/// ## Parameters
/// - [pos]: (`Point<int>`) Touch position in view pixels.
///
/// {@category Maps & 3D Scenes}
typedef TouchCallback = void Function(Point<int> pos);

/// Signature for callbacks that receive pointer state updates.
///
/// ## Parameters
/// - [pointerId]: (`int`) Pointer identifier assigned by the platform.
/// - [pos]: (`Point<num>`) Pointer position in view coordinates.
///
/// {@category Maps & 3D Scenes}
typedef TouchPointerCallback = void Function(int pointerId, Point<num> pos);

/// Signature for callbacks that receive drag start and end positions.
///
/// ## Parameters
/// - [start]: (`Point<num>`) Drag starting position.
/// - [end]: (`Point<num>`) Drag ending position.
///
/// {@category Maps & 3D Scenes}
typedef MoveCallback = void Function(Point<num> start, Point<num> end);

/// Signature for callbacks that observe follow-position state updates.
///
/// ## Parameters
/// - [state]: (`FollowPositionState`) Current follow-position state.
///
/// {@category Maps & 3D Scenes}
typedef FollowPositionStateCallback = void Function(FollowPositionState state);

/// Signature for callbacks that receive map angle changes.
///
/// ## Parameters
/// - [value]: (`double`) Map bearing in degrees (0–360).
///
/// {@category Maps & 3D Scenes}
typedef MapAngleUpdateCallback = void Function(double value);

/// Signature for callbacks that observe map move state transitions.
///
/// ## Parameters
/// - [isCameraMoving]: (`bool`) `true` when the camera is moving.
/// - [area]: (`RectangleGeographicArea`) Geographic area currently visible.
///
/// {@category Maps & 3D Scenes}
typedef MapViewMoveStateChangedCallback =
    void Function(bool isCameraMoving, RectangleGeographicArea area);

/// Signature for callbacks that observe map render completions.
///
/// ## Parameters
/// - [data]: (`MapViewRenderInfo`) Render metadata.
///
/// {@category Maps & 3D Scenes}
typedef MapViewRenderedCallback = void Function(MapViewRenderInfo data);

/// Signature for callbacks invoked when the map viewport changes size.
///
/// ## Parameters
/// - [viewport]: (`Rectangle<int>`) Updated viewport bounds.
///
/// {@category Maps & 3D Scenes}
typedef ViewportResizedCallback = void Function(Rectangle<int> viewport);

/// Signature for callbacks that render map scale overlays.
///
/// ## Parameters
/// - [scaleWidth]: (`int`) Scale bar width in pixels.
/// - [scaleValue]: (`int`) Value represented by the scale bar.
/// - [scaleUnits]: (`String`) Units of measurement.
///
/// {@category Maps & 3D Scenes}
typedef RenderMapScaleCallback =
    void Function(int scaleWidth, int scaleValue, String scaleUnits);

/// Signature for callbacks that handle two-pointer shove gestures.
///
/// ## Parameters
/// - [pointersAngleDeg]: (`double`) Angle between pointers in degrees.
/// - [initial]: (`Point<num>`) Midpoint at initial touch-down.
/// - [start]: (`Point<num>`) Midpoint at the previous update.
/// - [end]: (`Point<num>`) Midpoint at the current update.
///
/// {@category Maps & 3D Scenes}
typedef ShoveCallback =
    void Function(
      double pointersAngleDeg,
      Point<num> initial,
      Point<num> start,
      Point<num> end,
    );

/// Generic signature for callbacks receiving cursor selection payloads.
///
/// ## Parameters
/// - [selectedItem]: (`T`) Item highlighted under the cursor.
///
/// {@category Maps & 3D Scenes}
typedef CursorSelectionCallback<T> = void Function(T selectedItem);

/// Signature for callbacks that process swipe gestures.
///
/// ## Parameters
/// - [distX]: (`int`) Horizontal delta in pixels.
/// - [distY]: (`int`) Vertical delta in pixels.
/// - [speedMMPerSec]: (`double`) Swipe speed in millimetres per second.
///
/// {@category Maps & 3D Scenes}
typedef SwipeCallback =
    void Function(int distX, int distY, double speedMMPerSec);

/// Signature for callbacks that process pinch-swipe gestures.
///
/// ## Parameters
/// - [centerPosInPix]: (`Point<int>`) Gesture center in pixels.
/// - [zoomingSpeedInMMPerSec]: (`double`) Zoom velocity in millimetres per
///   second.
/// - [rotatingSpeedInMMPerSec]: (`double`) Rotation velocity in millimetres per
///   second.
///
/// {@category Maps & 3D Scenes}
typedef PinchSwipeCallback =
    void Function(
      Point<int> centerPosInPix,
      double zoomingSpeedInMMPerSec,
      double rotatingSpeedInMMPerSec,
    );

/// Signature for callbacks that process pinch gestures.
///
/// ## Parameters
/// - [start1]: (`Point<int>`) Initial position of the first pointer.
/// - [start2]: (`Point<int>`) Initial position of the second pointer.
/// - [end1]: (`Point<int>`) Current position of the first pointer.
/// - [end2]: (`Point<int>`) Current position of the second pointer.
/// - [center]: (`Point<int>`) Computed gesture center.
///
/// {@category Maps & 3D Scenes}
typedef PinchCallback =
    void Function(
      Point<int> start1,
      Point<int> start2,
      Point<int> end1,
      Point<int> end2,
      Point<int> center,
    );

/// Signature for callbacks that process touch-initiated pinch gestures.
///
/// ## Parameters
/// - [start1]: (`Point<int>`) Initial position of the first pointer.
/// - [start2]: (`Point<int>`) Initial position of the second pointer.
/// - [end1]: (`Point<int>`) Current position of the first pointer.
/// - [end2]: (`Point<int>`) Current position of the second pointer.
///
/// {@category Maps & 3D Scenes}1
typedef TouchPinchCallback =
    void Function(
      Point<int> start1,
      Point<int> start2,
      Point<int> end1,
      Point<int> end2,
    );

/// Signature for callbacks notified when a landmark label is highlighted.
///
/// ## Parameters
/// - [object]: (`Landmark`) Highlighted landmark.
///
/// {@category Maps & 3D Scenes}
typedef HoveredMapLabelHighlightedLandmarkCallback =
    void Function(Landmark object);

/// Signature for callbacks notified when an overlay item label is highlighted.
///
/// ## Parameters
/// - [object]: (`OverlayItem`) Highlighted overlay item.
///
/// {@category Maps & 3D Scenes}
typedef HoveredMapLabelHighlightedOverlayItemCallback =
    void Function(OverlayItem object);

/// Signature for callbacks notified when a traffic event label is highlighted.
///
/// ## Parameters
/// - [object]: (`TrafficEvent`) Highlighted traffic event.
///
/// {@category Maps & 3D Scenes}
typedef HoveredMapLabelHighlightedTrafficEventCallback =
    void Function(TrafficEvent object);

/// Signature for callbacks invoked when the map style changes.
///
/// ## Parameters
/// - [id]: (`int`) Content store identifier for the applied style.
/// - [stylePath]: (`String`) Local or logical path of the style resource.
/// - [viaApi]: (`bool`) `true` if the style change was triggered via the API.
///
/// {@category Maps & 3D Scenes}
typedef SetMapStyleCallback =
    void Function(int id, String stylePath, bool viaApi);
