// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:typed_data';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/map/map_camera_types.dart';
import 'package:meta/meta.dart';

/// Low-level control of the map view camera.
///
/// Obtain an instance from a [GemMapController.camera].
/// Do not construct this class directly.
///
/// Primary responsibilities include persisting and restoring camera state via
/// [cameraState], inspecting the live camera [position] and [orientation],
/// applying direct camera transforms or using higher-level helpers such as
/// [setCameraTargetCentered] and [setCameraRelativeToTarget], and computing
/// candidate camera placements with the helper methods.
///
/// Typically, camera manipulation is performed via higher-level methods on
/// [GemMapController] or other high-level classes such as [FollowPositionPreferences]
/// and [MapViewPreferences].
///
/// ## See also:
///
/// - [GemMapController] - Controller for map interactions that provides access to
///  the [MapCamera].
/// - [FollowPositionPreferences] - Modify camera behavior when in follow position mode.
/// - [MapViewPreferences] - Configure map view settings that affect camera behavior.
///
/// {@category Maps & 3D Scenes}
class MapCamera {
  // ignore: unused_element
  MapCamera._() : _pointerId = -1, _mapId = -1;

  @internal
  MapCamera.init(final int id, final int mapId)
    : _pointerId = id,
      _mapId = mapId;
  final int _pointerId;
  final int _mapId;
  int get pointerId => _pointerId;
  int get mapId => _mapId;

  /// Saves the current state of the camera into a binary format.
  ///
  /// Can be restored later using [cameraState] setter.
  /// Used for persisting camera state.
  ///
  /// ## Returns
  ///
  /// - (Uint8List) The binary representation of the camera's current state.
  Uint8List get cameraState {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapCamera',
      'saveCameraState',
    );
    return base64Decode(resultString['result']);
  }

  /// Retrieves the current orientation of the camera.
  ///
  /// ## Returns
  ///
  /// - (Point4d) The current (x, y, z, w) orientation of the camera.
  ///
  /// ## Also see:
  ///
  /// - [position] for retrieving the camera's 3D position.
  /// - [generatePositionAndOrientation] for computing candidate camera placements.
  Point4d get orientation {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapCamera',
      'getOrientation',
    );
    return Point4d.fromJson(resultString['result']);
  }

  /// Retrieves the current position of the camera.
  ///
  /// ## Returns
  ///
  /// - (Point3d) The current (x, y, z) position of the camera.
  ///
  /// ## Also see:
  ///
  /// - [orientation] for retrieving the camera's orientation.
  /// - [generatePositionAndOrientation] for computing candidate camera placements.
  Point3d get position {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapCamera',
      'getPosition',
    );
    return Point3d.fromJson(resultString['result']);
  }

  /// Restores a previously saved camera state.
  ///
  /// ## Parameters
  ///
  /// - [state]: (Uint8List) Binary blob previously produced by
  ///   [cameraState].
  set cameraState(final Uint8List state) {
    objectMethod(
      _pointerId,
      'MapCamera',
      'restoreCameraState',
      args: base64Encode(state),
    );
  }

  /// Set camera orientation using a quaternion.
  ///
  /// ## Parameters
  ///
  /// - [orient]: (Point4d) Quaternion expressed as (x, y, z, w).
  set orientation(final Point4d orient) {
    objectMethod(_pointerId, 'MapCamera', 'setOrientation', args: orient);
  }

  /// Set the camera's 3D position directly.
  ///
  /// ## Parameters
  ///
  /// - [pos]: (Point3d) Desired camera position in the SDK's 3D space.
  set position(final Point3d pos) {
    objectMethod(_pointerId, 'MapCamera', 'setPosition', args: pos);
  }

  /// Position the camera using geographic coordinates (lon/lat/alt).
  ///
  /// The camera will be oriented toward the focused sphere center with
  /// north-up by default.
  ///
  /// ## Parameters
  ///
  /// - [pos]: (Coordinates) Longitude, latitude (degrees) and altitude
  ///   (meters) for the camera focal point.
  set cameraPosition(final Coordinates pos) {
    objectMethod(_pointerId, 'MapCamera', 'setCameraPosition', args: pos);
  }

  /// Set the camera orientation using heading/pitch/roll (degrees).
  ///
  /// Heading uses the convention: 0 = North, 90 = East, 180 = South, 270 = West.
  ///
  /// ## Parameters
  ///
  /// - [pos]: (Point3d) (heading, pitch, roll) in degrees.
  set cameraOrientation(final Point3d pos) {
    objectMethod(_pointerId, 'MapCamera', 'setCameraOrientation', args: pos);
  }

  /// Set the camera to look at a geographic target (sphere coordinate system).
  ///
  /// Places the camera centered on `coords` at the distance / heading / pitch
  /// described by `pos`. Roll is kept at 0 to preserve a level horizon.
  ///
  /// ## Parameters
  ///
  /// - [coords]: (Coordinates) Target geographic coordinate (lon/lat/alt).
  /// - [pos]: (Point3d) Tuple describing heading (deg), pitch (deg) and
  ///   distance (meters) from the target.
  ///
  /// ## See also:
  ///
  /// - [generatePositionAndOrientationTargetCentered] for computing candidate
  ///   camera values without mutating the live camera.
  void setCameraTargetCentered(final Coordinates coords, final Point3d pos) {
    objectMethod(
      _pointerId,
      'MapCamera',
      'setCameraTargetCentered',
      args: <String, Object>{'coordinates': coords, 'tuple3D': pos},
    );
  }

  /// Set the camera relative to a target that has its own orientation.
  ///
  /// This configures the camera with respect to a target that includes a
  /// heading/pitch/roll. The camera is positioned at the requested distance
  /// and oriented relative to the target's coordinate frame.
  ///
  /// ## Parameters
  ///
  /// - [targetCoords]: (Coordinates) Target geographic coordinate.
  /// - [targetHeadingPitchRollDeg]: (Point3d) Target orientation (deg).
  /// - [cameraHeadingPitchDegDistanceMeters]: (Point3d) Camera heading/pitch
  ///   (deg) and distance (meters) from the target.
  ///
  /// ## See also:
  ///
  /// - [generatePositionAndOrientationRelativeToCenteredTarget] - Computes candidate
  ///  camera values without mutating the live camera.
  void setCameraRelativeToCenteredTarget(
    final Coordinates targetCoords,
    final Point3d targetHeadingPitchRollDeg,
    final Point3d cameraHeadingPitchDegDistanceMeters,
  ) {
    objectMethod(
      _pointerId,
      'MapCamera',
      'setCameraRelativeToCenteredTarget',
      args: <String, Object>{
        'coordinates': targetCoords,
        'tuple3D1': targetHeadingPitchRollDeg,
        'tuple3D2': cameraHeadingPitchDegDistanceMeters,
      },
    );
  }

  /// Set the camera relative to a target and allow arbitrary camera orientation.
  ///
  /// This variant allows specifying an explicit camera heading/pitch/roll in
  /// addition to the camera's distance from the target.
  ///
  /// ## Parameters
  ///
  /// - [targetCoords]: (Coordinates) Target geographic coordinate.
  /// - [targetHeadingPitchRollDeg]: (Point3d) Target orientation (deg).
  /// - [cameraHeadingPitchDegDistanceMeters]: (Point3d) Camera heading/pitch
  ///   (deg) and distance (m).
  /// - [cameraHeadingPitchRollDeg]: (Point3d) Camera heading/pitch/roll (deg)
  ///   to orient the camera arbitrarily relative to the target.
  ///
  /// ## See also:
  ///
  /// - [generatePositionAndOrientationRelativeToTarget] - Computes candidate
  ///   camera values without mutating the live camera.
  void setCameraRelativeToTarget(
    final Coordinates targetCoords,
    final Point3d targetHeadingPitchRollDeg,
    final Point3d cameraHeadingPitchDegDistanceMeters,
    final Point3d cameraHeadingPitchRollDeg,
  ) {
    objectMethod(
      _pointerId,
      'MapCamera',
      'setCameraRelativeToTarget',
      args: <String, Object>{
        'coordinates': targetCoords,
        'tuple3D1': targetHeadingPitchRollDeg,
        'tuple3D2': cameraHeadingPitchDegDistanceMeters,
        'tuple3D3': cameraHeadingPitchRollDeg,
      },
    );
  }

  /// Compute a candidate camera position and orientation for `targetCoords`.
  ///
  /// This helper does not change the live camera. Use the returned
  /// `PositionOrientation` to apply the values later via [position]/[orientation]
  /// or a controller helper.
  ///
  /// ## Parameters
  ///
  /// - [targetCoords]: (Coordinates) Target geographic coordinate (lon/lat/alt).
  ///
  /// ## Returns
  ///
  /// - (GemError, PositionOrientation) tuple. On success `GemError.success`
  ///   and a `PositionOrientation` with `position` (Point3d) and
  ///   `orientation` (Point4d) are returned.
  ///
  /// ## See also:
  ///
  /// - [cameraPosition] and [cameraOrientation] for applying the computed values.
  (GemError, PositionOrientation) generatePositionAndOrientation(
    final Coordinates targetCoords,
  ) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapCamera',
      'generatePositionAndOrientation',
      args: targetCoords,
    );

    return (
      GemErrorExtension.fromCode(resultString['result']['errorCode']),
      PositionOrientation(
        position: Point3d.fromJson(resultString['result']['tuple3D']),
        orientation: Point4d.fromJson(resultString['result']['tuple4D']),
      ),
    );
  }

  /// Compute a candidate camera position and orientation using explicit
  /// heading/pitch/roll (HPR).
  ///
  /// ## Parameters
  ///
  /// - [targetCoords]: (Coordinates) Target geographic coordinate.
  /// - [headingPitchRollDeg]: (Point3d) Heading, pitch and roll in degrees.
  ///
  /// ## Returns
  /// - (GemError, PositionOrientation) tuple as described by
  ///   [generatePositionAndOrientation].
  ///
  /// ## See also:
  ///
  /// - [cameraPosition] and [cameraOrientation] for applying the computed values.
  (GemError, PositionOrientation) generatePositionAndOrientationHPR(
    final Coordinates targetCoords,
    final Point3d headingPitchRollDeg,
  ) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapCamera',
      'generatePositionAndOrientation',
      args: <String, Object>{
        'coordinates': targetCoords,
        'tuple3D': headingPitchRollDeg,
      },
    );

    return (
      GemErrorExtension.fromCode(resultString['result']['errorCode']),
      PositionOrientation(
        position: Point3d.fromJson(resultString['result']['tuple3D']),
        orientation: Point4d.fromJson(resultString['result']['tuple4D']),
      ),
    );
  }

  /// Compute a camera placement centered on and oriented toward `targetCoords`.
  ///
  /// ## Parameters
  ///
  /// - [targetCoords]: (Coordinates) Target geographic coordinate.
  /// - [cameraHeadingPitchDegDistanceMeters]: (Point3d) Camera heading/pitch
  ///   (deg) and distance (meters) from the target.
  ///
  /// ## Returns
  /// - (GemError, PositionOrientation) tuple as described by
  ///   [generatePositionAndOrientation].
  ///
  /// ## See also:
  ///
  /// - [cameraPosition] and [cameraOrientation] for applying the computed values.
  (GemError, PositionOrientation) generatePositionAndOrientationTargetCentered(
    final Coordinates targetCoords,
    final Point3d cameraHeadingPitchDegDistanceMeters,
  ) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapCamera',
      'generatePositionAndOrientationTargetCentered',
      args: <String, Object>{
        'coordinates': targetCoords,
        'tuple3D': cameraHeadingPitchDegDistanceMeters,
      },
    );

    return (
      GemErrorExtension.fromCode(resultString['result']['errorCode']),
      PositionOrientation(
        position: Point3d.fromJson(resultString['result']['tuple3D']),
        orientation: Point4d.fromJson(resultString['result']['tuple4D']),
      ),
    );
  }

  /// Compute camera placement relative to a target that has its own orientation.
  ///
  /// ## Parameters
  ///
  /// - [targetCoords]: (Coordinates) Target geographic coordinate.
  /// - [targetHeadingPitchRollDeg]: (Point3d) Target heading/pitch/roll (deg).
  /// - [cameraHeadingPitchDegDistanceMeters]: (Point3d) Camera heading/pitch
  ///   (deg) and distance (m) from the target.
  ///
  /// ## Returns
  /// - (GemError, PositionOrientation) tuple as described by
  ///   [generatePositionAndOrientation].
  ///
  /// ## See also:
  ///
  /// - [cameraPosition] and [cameraOrientation] for applying the computed values.
  (GemError, PositionOrientation)
  generatePositionAndOrientationRelativeToCenteredTarget(
    final Coordinates targetCoords,
    final Point3d targetHeadingPitchRollDeg,
    final Point3d cameraHeadingPitchDegDistanceMeters,
  ) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapCamera',
      'generatePositionAndOrientationRelativeToCenteredTarget',
      args: <String, Object>{
        'coordinates': targetCoords,
        'tuple3D1': targetHeadingPitchRollDeg,
        'tuple3D2': cameraHeadingPitchDegDistanceMeters,
      },
    );

    return (
      GemErrorExtension.fromCode(resultString['result']['errorCode']),
      PositionOrientation(
        position: Point3d.fromJson(resultString['result']['tuple3D']),
        orientation: Point4d.fromJson(resultString['result']['tuple4D']),
      ),
    );
  }

  /// Compute a camera placement relative to a target, allowing arbitrary
  /// camera orientation.
  ///
  /// ## Parameters
  /// - [targetCoords]: ([Coordinates]) Target geographic coordinate.
  /// - [targetHeadingPitchRollDeg]: ([Point3d]) Target heading/pitch/roll (deg).
  /// - [cameraHeadingPitchDegDistanceMeters]: ([Point3d]) Camera heading/pitch
  ///   (deg) and distance (m).
  /// - [cameraHeadingPitchRollDeg]: ([Point3d]) Camera heading/pitch/roll (deg)
  ///   to orient the camera arbitrarily relative to the target.
  ///
  /// ## Returns
  /// - `(GemError, PositionOrientation)` tuple as described by
  ///   [generatePositionAndOrientation].
  ///
  /// ## See also:
  ///
  /// - [cameraPosition] and [cameraOrientation] for applying the computed values.
  (GemError, PositionOrientation)
  generatePositionAndOrientationRelativeToTarget(
    final Coordinates targetCoords,
    final Point3d targetHeadingPitchRollDeg,
    final Point3d cameraHeadingPitchDegDistanceMeters,
    final Point3d cameraHeadingPitchRollDeg,
  ) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapCamera',
      'generatePositionAndOrientationRelativeToTarget',
      args: <String, Object>{
        'coordinates': targetCoords,
        'tuple3D1': targetHeadingPitchRollDeg,
        'tuple3D2': cameraHeadingPitchDegDistanceMeters,
        'tuple3D3': cameraHeadingPitchRollDeg,
      },
    );

    return (
      GemErrorExtension.fromCode(resultString['result']['errorCode']),
      PositionOrientation(
        position: Point3d.fromJson(resultString['result']['tuple3D']),
        orientation: Point4d.fromJson(resultString['result']['tuple4D']),
      ),
    );
  }
}
