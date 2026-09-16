// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:math';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Follow position preferences for camera control during position tracking
///
/// This class should not be instantiated directly.
/// Instead, use the [MapViewPreferences.followPositionPreferences] getter to obtain an instance.
///
/// Controls how the camera behaves while following a tracked position (real or simulated).
///
/// Common tasks include:
/// - Moving the follow-camera focus inside the viewport using [setCameraFocus]
/// - Switching between flat and 3D perspectives with optional animation via [setPerspective]
/// - Adjusting pitch/tilt with [setViewAngle] and zoom (including auto-zoom behavior) with [setZoomLevel]
/// - Choosing the rotation source (sensor heading, compass or a fixed angle) via [setMapRotationMode]
/// - Showing or hiding the accuracy indicator with [setAccuracyCircleVisibility] and customizing its appearance via [MapSceneObject]
/// - Fine‑tuning touch behavior: allowing or preventing manual exit via [touchHandlerExitAllow],
///   making manual adjustments persistent via [touchHandlerModifyPersistent], and setting angle/distance limits
///
/// It exposes read access to current follow-mode settings including [cameraFocus], [perspective], [viewAngle],
/// [zoomLevel], [mapRotationMode], and [accuracyCircleVisibility].
///
/// ## See also:
///
/// - [MapViewPreferences.followPositionPreferences] - Access point for this class
/// - [GemMapController.startFollowingPosition] - Start following the device position
/// - [GemMapController.stopFollowingPosition] - Stop following the device position
/// - [MapSceneObject] - Customize accuracy circle appearance
/// - [MapViewPerspective] - Available perspective modes
/// - [FollowPositionMapRotationMode] - Available rotation modes
///
/// {@category Maps & 3D Scenes}
class FollowPositionPreferences extends GemAutoreleaseObject {
  // ignore: unused_element
  FollowPositionPreferences._() : _mapId = -1, _mapPointerId = -1, super(-1);

  @internal
  FollowPositionPreferences.init(
    super.id,
    final int mapId,
    final int mapPointerId,
  ) : _mapId = mapId,
      _mapPointerId = mapPointerId;
  final int _mapId;
  final int _mapPointerId;

  int get mapId => _mapId;
  int get mapPointerId => _mapPointerId;

  /// Camera focus position in viewport coordinates
  ///
  /// The camera focus determines where the position tracker appears within the viewport during follow mode.
  /// Coordinates range from 0.0 (left/top) to 1.0 (right/bottom). Default is typically center (0.5, 0.5).
  ///
  /// ## Returns
  ///
  /// - A [Point] with x and y coordinates between 0.0 and 1.0 representing the focus position in the viewport
  ///
  /// ## See also:
  ///
  /// - [setCameraFocus] - Modify the camera focus position
  Point<double> get cameraFocus {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'getCameraFocus',
      dependencyId: _mapPointerId,
    );

    return XyType<double>.fromJson(resultString['result']).point;
  }

  /// Current map view perspective during follow position mode
  ///
  /// The perspective determines whether the map is displayed in 2D (flat, top-down view) or 3D (perspective view with tilt).
  /// Use [setPerspective] to switch between perspectives with optional animation.
  ///
  /// ## Returns
  ///
  /// - The current [MapViewPerspective] (either [MapViewPerspective.twoDimensional] or [MapViewPerspective.threeDimensional])
  MapViewPerspective get perspective {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'getPerspective',
      dependencyId: _mapPointerId,
    );

    return MapViewPerspectiveExtension.fromId(resultString['result']);
  }

  /// Time interval before starting turn presentation during navigation
  ///
  /// This setting controls how many seconds before an upcoming turn the map camera should start presenting
  /// the turn animation. Set via the [timeBeforeTurnPresentation] setter.
  ///
  /// ## Returns
  ///
  /// - The time interval in seconds (-1 means SDK default is used)
  int get timeBeforeTurnPresentation {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'getTimeBeforeTurnPresentation',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Whether user gestures can exit follow position mode
  ///
  /// When true (default), user interactions like panning or tilting the map will exit follow position mode.
  /// When false, the follow mode can only be exited programmatically via [GemMapController.stopFollowingPosition].
  ///
  /// ## Returns
  ///
  /// - True if user gestures can exit follow position, false otherwise (default: true)
  bool get touchHandlerExitAllow {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'getTouchHandlerExitAllow',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Whether manual follow position adjustments persist across sessions
  ///
  /// When true, user adjustments to the camera (angle, distance, etc.) made during follow mode via touch gestures
  /// will be remembered and applied to subsequent follow position sessions. When false (default), each new
  /// follow session starts with default settings.
  ///
  /// ## Returns
  ///
  /// - True if manual adjustments persist across sessions, false otherwise (default: false)
  bool get touchHandlerModifyPersistent {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'getTouchHandlerModifyPersistent',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Horizontal angle adjustment limits for user gestures during follow mode
  ///
  /// Defines the minimum and maximum horizontal rotation angles users can apply via touch gestures while in follow mode.
  /// An empty range (0.0, 0.0) forbids horizontal angle adjustment entirely.
  ///
  /// ## Returns
  ///
  /// - A tuple (min, max) of angle limits in degrees. Default is (0.0, 0.0) meaning adjustment is forbidden
  ///
  /// ## See also:
  ///
  /// - [touchHandlerModifyVerticalAngleLimits] - The vertical angle limits counterpart
  /// - [touchHandlerModifyDistanceLimits] - The distance limits counterpart
  (double, double) get touchHandlerModifyHorizontalAngleLimits {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'getTouchHandlerModifyHorizontalAngleLimits',
      dependencyId: _mapPointerId,
    );

    final Map<String, dynamic> result =
        resultString['result'] as Map<String, dynamic>;
    final double first = result['first'];
    final double second = result['second'];

    return (first, second);
  }

  /// Vertical angle (pitch) adjustment limits for user gestures during follow mode
  ///
  /// Defines the minimum and maximum pitch angles users can apply via touch gestures while in follow mode.
  /// An empty range (0.0, 0.0) forbids vertical angle adjustment entirely.
  ///
  /// ## Returns
  ///
  /// - A tuple (min, max) of pitch angle limits in degrees. Default is (0.0, 0.0) meaning adjustment is forbidden
  ///
  /// ## See also:
  ///
  /// - [touchHandlerModifyHorizontalAngleLimits] - The horizontal angle limits counterpart
  /// - [touchHandlerModifyDistanceLimits] - The distance limits counterpart
  (double, double) get touchHandlerModifyVerticalAngleLimits {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'getTouchHandlerModifyVerticalAngleLimits',
      dependencyId: _mapPointerId,
    );

    final Map<String, dynamic> result =
        resultString['result'] as Map<String, dynamic>;
    final double first = result['first'];
    final double second = result['second'];

    return (first, second);
  }

  /// Distance adjustment limits for camera zoom via user gestures during follow mode
  ///
  /// Defines the minimum and maximum camera distances to the tracked position that users can apply via pinch/zoom gestures
  /// while in follow mode. An empty range (0.0, 0.0) forbids distance adjustment entirely.
  ///
  /// ## Returns
  ///
  /// - A tuple (min, max) of distance limits in meters. Default is (50.0, infinity) meaning no maximum limit
  (double, double) get touchHandlerModifyDistanceLimits {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'getTouchHandlerModifyDistanceLimits',
      dependencyId: _mapPointerId,
    );

    final Map<String, dynamic> result =
        resultString['result'] as Map<String, dynamic>;
    final double first = result['first'];
    final double second = result['second'];

    return (first, second);
  }

  /// Camera pitch angle during follow position mode
  ///
  /// The pitch angle controls the camera's vertical tilt. A value of 0 represents a direct top-down view,
  /// while 90 represents a horizontal view at ground level. Use [setViewAngle] to modify this value.
  ///
  /// ## Returns
  ///
  /// - The camera pitch angle in degrees (range: 0-90, where 0 is top-down)
  double get viewAngle {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'getViewAngle',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Current zoom level during follow position mode
  ///
  /// The zoom level determines how close the camera is to the terrain. Higher values provide more detail.
  /// A value of -1 indicates that auto-zooming is enabled, where the SDK automatically adjusts zoom based on context.
  ///
  /// ## Returns
  ///
  /// - The current zoom level (0 to max zoom), or -1 if auto-zooming is enabled
  ///
  /// ## Also see:
  ///
  /// - [GemMapController.zoomLevel] - Set the zoom level outside of follow position mode
  int get zoomLevel {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'getZoomLevel',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Whether the position accuracy circle is currently visible
  ///
  /// The accuracy circle visually represents the GPS accuracy radius around the tracked position.
  /// Its appearance can be customized using [MapSceneObject] methods.
  ///
  /// ## Returns
  ///
  /// - True if the accuracy circle is visible, false otherwise
  ///
  /// ## See also:
  ///
  /// - [setAccuracyCircleVisibility] - Show or hide the accuracy circle
  /// - [MapSceneObject] - Customize accuracy circle appearance
  bool get accuracyCircleVisibility {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'isAccuracyCircleVisible',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Whether the position tracker icon rotates with the map view
  ///
  /// When true, the position tracking object (typically an arrow or icon) will rotate its orientation to match
  /// the map's rotation. This setting is configured via [setMapRotationMode] with the `objectFollowMap` parameter.
  ///
  /// ## Returns
  ///
  /// - True if the tracker icon rotation follows map rotation, false if it maintains independent orientation
  ///
  /// ## See also:
  ///
  /// - [setMapRotationMode] - Configure map rotation behavior during follow position
  bool get isTrackObjectFollowingMapRotation {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'isTrackObjectFollowingMapRotation',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Show or hide the position accuracy circle
  ///
  /// The accuracy circle provides a visual representation of GPS accuracy around the tracked position.
  /// The circle's color and appearance can be customized using [MapSceneObject] methods.
  ///
  /// ## Parameters
  ///
  /// - [isVisible]: True to show the accuracy circle, false to hide it
  ///
  /// ## Returns
  ///
  /// - [GemError.success] - Circle visibility updated successfully
  /// - [GemError.notFound] - Map object does not exist
  GemError setAccuracyCircleVisibility(final bool isVisible) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'setAccuracyCircleVisibility',
      args: isVisible,
      dependencyId: _mapPointerId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Set the camera focus position within the viewport during follow mode
  ///
  /// Determines where the position tracker appears in the viewport. For example, use Point(0.5, 0.7) to place
  /// the tracker at the horizontal center and 70% down from the top, leaving more space to view the route ahead.
  ///
  /// Changes take effect when [GemMapController.startFollowingPosition] is called.
  ///
  /// ## Parameters
  ///
  /// - [pos] - The camera focus point with x and y coordinates between 0.0 (left/top) and 1.0 (right/bottom)
  ///
  /// ## Returns
  ///
  /// - [GemError.success] - Camera focus updated successfully
  /// - [GemError.invalidInput] - Invalid coordinates (must be between 0.0 and 1.0)
  ///
  /// ## See also:
  ///
  /// - [cameraFocus] - Current camera focus position
  GemError setCameraFocus(final Point<double> pos) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'setCameraFocus',
      args: XyType<double>.fromPoint(pos),
      dependencyId: _mapPointerId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Configure how the map rotates during follow position mode
  ///
  /// Controls whether the map rotates based on device heading, compass sensor, or a fixed angle.
  /// The position tracker icon's rotation can optionally follow the map rotation.
  ///
  /// When [objectFollowMap] is true, all views using the same tracking object will see the rotation update.
  ///
  /// ## Parameters
  ///
  /// - [mode] : The rotation mode. Use [FollowPositionMapRotationMode.positionHeading] to rotate by device heading,
  ///   [FollowPositionMapRotationMode.compass] to rotate by compass sensor, or [FollowPositionMapRotationMode.fixed]
  ///   to use a fixed angle.
  /// - [mapAngle] : The fixed map rotation angle in degrees (0-360) used when [mode] is
  ///   [FollowPositionMapRotationMode.fixed]. 0 degrees represents north-up. Ignored for other modes. Default: 0
  /// - [objectFollowMap] : If true, the position tracker icon rotates with the map view rotation.
  ///   If false, the tracker maintains independent orientation. Default: true
  ///
  /// ## See also:
  ///
  /// - [isTrackObjectFollowingMapRotation] - Whether the tracker icon follows map rotation
  /// - [mapRotationMode] - Current map rotation mode and fixed angle
  void setMapRotationMode(
    final FollowPositionMapRotationMode mode, {
    final double mapAngle = 0,
    final bool objectFollowMap = true,
  }) {
    objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'setMapRotationMode',
      args: <String, Object>{
        'mode': mode.id,
        'angle': mapAngle,
        'objectFollowMap': objectFollowMap,
      },
      dependencyId: _mapPointerId,
    );
  }

  /// Current map rotation mode and fixed angle during follow position
  ///
  /// Returns the rotation mode (device heading, compass, or fixed) along with the fixed rotation angle.
  /// The angle is only relevant when mode is [FollowPositionMapRotationMode.fixed].
  ///
  /// ## Returns
  ///
  /// - A tuple containing the [FollowPositionMapRotationMode] and the fixed rotation angle in degrees (0-360)
  ///
  /// ## See also:
  ///
  /// - [setMapRotationMode] - Configure map rotation behavior during follow position
  (FollowPositionMapRotationMode, double) get mapRotationMode {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'getMapRotationMode',
      dependencyId: _mapPointerId,
    );

    return (
      FollowPositionMapRotationMode.values[((resultString['result']['first'])
              as double)
          .toInt()],
      resultString['result']['second'],
    );
  }

  /// Switch between 2D and 3D map perspectives during follow position mode
  ///
  /// Toggles between a flat, top-down view ([MapViewPerspective.twoDimensional]) and a perspective view
  /// with tilt ([MapViewPerspective.threeDimensional]). Optionally animates the transition.
  ///
  /// ## Parameters
  ///
  /// - [perspective]: The desired map perspective: [MapViewPerspective.twoDimensional] for flat view
  ///   or [MapViewPerspective.threeDimensional] for perspective view
  /// - [animation]: Optional animation for the perspective change. If null, the change is instant. Default: null
  ///
  /// ## Also see:
  ///
  /// - [perspective] - Current map perspective
  /// - [viewAngle] - Camera pitch angle relevant in 3D perspective
  void setPerspective(
    final MapViewPerspective perspective, {
    final GemAnimation? animation,
  }) {
    objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'setPerspective',
      args: <String, Object>{
        'perspective': perspective.id,
        if (animation != null) 'animation': animation,
      },
      dependencyId: _mapPointerId,
    );
  }

  /// Configure turn presentation timing during navigation
  ///
  /// Sets how many seconds before an upcoming turn the map camera should start presenting the turn animation.
  ///
  /// ## Parameters
  ///
  /// - [val]: Time interval in seconds before starting turn presentation. Use -1 to apply SDK default value
  set timeBeforeTurnPresentation(final int val) {
    objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'setTimeBeforeTurnPresentation',
      args: val,
      dependencyId: _mapPointerId,
    );
  }

  /// Control whether user gestures can exit follow position mode
  ///
  /// When enabled (default), user interactions like panning or tilting exit follow mode.
  /// When disabled, follow mode can only be exited programmatically.
  ///
  /// ## Parameters
  ///
  /// - [allowExit]: True to allow user gestures to exit follow mode, false to require programmatic exit. Default: true
  set touchHandlerExitAllow(final bool allowExit) {
    objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'setTouchHandlerExitAllow',
      args: allowExit,
      dependencyId: _mapPointerId,
    );
  }

  /// Control whether manual camera adjustments persist across follow sessions
  ///
  /// When enabled, user adjustments to camera angle, distance, etc. during follow mode are remembered
  /// and applied to subsequent follow sessions. When disabled (default), each session starts fresh.
  ///
  /// ## Parameters
  ///
  /// - [isPersistent]: True to remember adjustments across sessions, false to reset each time. Default: false
  set touchHandlerModifyPersistent(final bool isPersistent) {
    objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'setTouchHandlerModifyPersistent',
      args: isPersistent,
      dependencyId: _mapPointerId,
    );
  }

  /// Set horizontal rotation angle limits for user gestures during follow mode
  ///
  /// Defines the range of horizontal rotation angles users can apply via touch gestures.
  /// Use (0.0, 0.0) to disable horizontal angle adjustment.
  ///
  /// ## Parameters
  ///
  /// - [angles]: Tuple (min, max) of angle limits in degrees. Use (0.0, 0.0) to forbid adjustment. Default: (0.0, 0.0)
  set touchHandlerModifyHorizontalAngleLimits(final (double, double) angles) {
    objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'setTouchHandlerModifyHorizontalAngleLimits',
      args: Pair<double, double>(angles.$1, angles.$2).toJson(),
      dependencyId: _mapPointerId,
    );
  }

  /// Set vertical pitch angle limits for user gestures during follow mode
  ///
  /// Defines the range of pitch (tilt) angles users can apply via touch gestures.
  /// Use (0.0, 0.0) to disable vertical angle adjustment.
  ///
  /// ## Parameters
  ///
  /// - [angles]: Tuple (min, max) of pitch angle limits in degrees. Use (0.0, 0.0) to forbid adjustment. Default: (0.0, 0.0)
  set touchHandlerModifyVerticalAngleLimits(final (double, double) angles) {
    objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'setTouchHandlerModifyVerticalAngleLimits',
      args: Pair<double, double>(angles.$1, angles.$2).toJson(),
      dependencyId: _mapPointerId,
    );
  }

  /// Set camera distance limits for zoom gestures during follow mode
  ///
  /// Defines the range of camera distances (zoom levels) users can apply via pinch/zoom gestures.
  /// Use (0.0, 0.0) to disable distance adjustment.
  ///
  /// ## Parameters
  ///
  /// - [distanceLimits]: Tuple (min, max) of distance limits in meters. Must be in range [0, infinity).
  ///   Use (0.0, 0.0) to forbid adjustment. Default: (50.0, infinity)
  set touchHandlerModifyDistanceLimits(final (double, double) distanceLimits) {
    objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'setTouchHandlerModifyDistanceLimits',
      args: Pair<double, double>(distanceLimits.$1, distanceLimits.$2).toJson(),
      dependencyId: _mapPointerId,
    );
  }

  /// Set the camera pitch angle during follow position mode
  ///
  /// Adjusts the vertical tilt of the camera. A value of 0 provides a direct top-down view, while 90 provides
  /// a horizontal view at ground level. Optionally animate the transition.
  ///
  /// ## Parameters
  ///
  /// - [viewAngle]: The desired camera pitch angle in degrees (range: 0-90, where 0 is top-down)
  /// - [animated]: If true, animate the angle change. If false, change instantly. Default: false
  void setViewAngle(final double viewAngle, {final bool animated = false}) {
    objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'setViewAngle',
      args: <String, Object>{'value': viewAngle, 'animated': animated},
      dependencyId: _mapPointerId,
    );
  }

  /// Set the zoom level during follow position mode
  ///
  /// Adjusts how close the camera is to the terrain. Higher values provide more detail.
  /// Use -1 to enable auto-zoom, where the SDK automatically adjusts zoom based on context.
  ///
  /// ## Parameters
  ///
  /// - [zoomLevel]: The desired zoom level (0 to max zoom level), or -1 to enable auto-zoom
  /// - [duration]: Animation duration in milliseconds. Use 0 for instant change. Default: 0
  ///
  /// ## Returns
  ///
  /// - The previous zoom level before this change
  int setZoomLevel(final int zoomLevel, {final int duration = 0}) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'FollowPositionPreferences',
      'setZoomLevel',
      args: <String, int>{'zoomLevel': zoomLevel, 'duration': duration},
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }
}
