// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:math';
import 'dart:ui' show Color;

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/extensions.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Represents a 3D scene object that can be manipulated on the map.
///
/// A map scene object typically represents a 3D model used for position
/// tracking or decorative objects. Do not instantiate directly; obtain an
/// instance via [getDefPositionTracker] or other factory methods provided by
/// the SDK.
///
/// ## See also:
///
/// - [getDefPositionTracker] — Obtain the default position tracker object.
///
/// {@category Maps & 3D Scenes}
class MapSceneObject {
  // ignore: unused_element
  MapSceneObject._() : _pointerId = -1, _mapId = -1;

  @internal
  MapSceneObject.init(final int id, final int mapId)
    : _pointerId = id,
      _mapId = mapId;
  final int _pointerId;
  final int _mapId;

  int get pointerId => _pointerId;
  int get mapId => _mapId;

  /// Customizes the SDK's default position tracking object.
  ///
  /// Provide binary object data (for example a glTF or texture) and the
  /// corresponding [SceneObjectFileFormat] to replace the default position
  /// tracker visual. To apply a flat texture only, pass data with
  /// [SceneObjectFileFormat.tex].
  ///
  /// ## Parameters
  ///
  /// - [buffer]: (`List<int>`) Binary data for the scene object or texture.
  ///   Pass an empty list to restore the SDK's default resource.
  /// - [format]: (`SceneObjectFileFormat`) The file format of the provided
  ///   buffer.
  ///
  /// ## Returns
  ///
  /// - ([GemError]) Error status indicating success or the reason for
  ///   failure.
  static GemError customizeDefPositionTracker(
    final List<int> buffer,
    final SceneObjectFileFormat format,
  ) {
    final OperationResult resultString = staticMethod(
      'MapSceneObject',
      'customizeDefPositionTracker',
      args: <String, Object>{'buffer': buffer, 'format': format.id},
    );

    final int gemApiError = resultString['gemApiError'];

    return GemErrorExtension.fromCode(gemApiError);
  }

  /// Returns the SDK's default position tracker object.
  ///
  /// The SDK creates a default position tracker after it receives the first
  /// location update. The returned instance is managed by the SDK and will
  /// update automatically from the active [PositionService] data source.
  ///
  /// ## Returns
  ///
  /// - ([MapSceneObject]) The default position tracker instance.
  ///
  /// ## See also:
  ///
  /// - [customizeDefPositionTracker] — Customize the default position tracker visual.
  /// - [PositionService] — Manage device position updates.
  static MapSceneObject getDefPositionTracker() {
    final OperationResult resultString = staticMethod(
      'MapSceneObject',
      'getDefPositionTracker',
    );

    return MapSceneObject.init(resultString['result'], 0);
  }

  /// Sets the color of the SDK position tracker accuracy circle.
  ///
  /// The color is provided as a [Color]. Values with transparency will be
  /// rendered accordingly.
  ///
  /// ## Parameters
  ///
  /// - [color]: (`Color`) Desired color for the accuracy circle.
  ///
  /// ## Returns
  ///
  /// - ([GemError]) Error status indicating success or failure.
  ///
  /// ## See also:
  ///
  /// - [resetDefPositionTrackerAccuracyCircleColor] — Reset to the default color.
  static GemError setDefPositionTrackerAccuracyCircleColor(final Color color) {
    final OperationResult resultString = staticMethod(
      'MapSceneObject',
      'setDefPositionTrackerAccuracyCircleColor',
      args: <String, int>{
        'a': (color.a * 255).toInt(),
        'r': (color.r * 255).toInt(),
        'g': (color.g * 255).toInt(),
        'b': (color.b * 255).toInt(),
      },
    );

    final int gemApiError = resultString['gemApiError'];
    return GemErrorExtension.fromCode(gemApiError);
  }

  /// Resets the default position tracker accuracy circle to the SDK default color.
  ///
  /// ## Returns
  ///
  /// - ([GemError]) Error status indicating success or failure.
  ///
  /// ## See also:
  ///
  /// - [setDefPositionTrackerAccuracyCircleColor] — Set a custom color.
  static GemError resetDefPositionTrackerAccuracyCircleColor() {
    return setDefPositionTrackerAccuracyCircleColor(
      const Color.fromARGB(255, 51, 153, 255),
    );
  }

  /// Returns the current color used for the position tracker accuracy circle.
  ///
  /// ## Returns
  ///
  /// - ([Color]) The currently configured accuracy circle color.
  ///
  /// ## See also:
  ///
  /// - [setDefPositionTrackerAccuracyCircleColor] — Set a custom color.
  @Deprecated('Use defPositionTrackerAccuracyCircleColor getter instead.')
  static Color getDefPositionTrackerAccuracyCircleColor() {
    final OperationResult resultString = staticMethod(
      'MapSceneObject',
      'getDefPositionTrackerAccuracyCircleColor',
    );

    final dynamic result = resultString['result'];
    return ColorExtension.fromJson(result);
  }

  /// Returns the current color used for the position tracker accuracy circle.
  ///
  /// ## Returns
  ///
  /// - ([Color]) The currently configured accuracy circle color.
  ///
  /// ## See also:
  ///
  /// - [setDefPositionTrackerAccuracyCircleColor] — Set a custom color.
  static Color get defPositionTrackerAccuracyCircleColor {
    final OperationResult resultString = staticMethod(
      'MapSceneObject',
      'getDefPositionTrackerAccuracyCircleColor',
    );

    final dynamic result = resultString['result'];
    return ColorExtension.fromJson(result);
  }

  /// Returns the object's coordinates in the main object coordinate system.
  ///
  /// ## Returns
  ///
  /// - ([Coordinates]) The object's coordinates.
  ///
  /// ## Also see:
  ///
  /// - [PositionService] — Manage device position.
  Coordinates get coordinates {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapSceneObject',
      'getCoordinates',
    );

    return Coordinates.fromJson(resultString['result']);
  }

  /// Returns the object's orientation as a quaternion.
  ///
  /// ## Returns
  ///
  /// - ([Point4d]) The object's orientation.
  Point4d get orientation {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapSceneObject',
      'getOrientation',
    );

    return Point4d.fromJson(resultString['result']);
  }

  /// Sets the object's visibility.
  ///
  /// ## Parameters
  ///
  /// - [vis]: (`bool`) Desired visibility state.
  set visibility(final bool vis) {
    objectMethod(_pointerId, 'MapSceneObject', 'setVisibility', args: vis);
  }

  /// Returns whether the object is visible.
  ///
  /// ## Returns
  ///
  /// - (`bool`) The object's visibility state.
  bool get visibility {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapSceneObject',
      'getVisibility',
    );

    return resultString['result'];
  }

  /// Returns the object's scale factor.
  ///
  /// ## Returns
  ///
  /// - ([double]) The object's scale.
  double get scale {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapSceneObject',
      'getScaleFactor',
    );

    return resultString['result'];
  }

  /// Sets the object's scale factor.
  ///
  /// ## Parameters
  ///
  /// - [scale]: (`double`) Desired scale factor.
  ///
  /// ## Also see:
  ///
  /// - [maxScale] — Get the object's maximum allowed scale.
  set scale(final double scale) {
    objectMethod(_pointerId, 'MapSceneObject', 'setScaleFactor', args: scale);
  }

  /// Returns the maximum allowed scale factor for the object.
  ///
  /// ## Returns
  ///
  /// - ([double]) The object's maximum scale.
  double get maxScale {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapSceneObject',
      'getMaxScaleFactor',
    );

    return resultString['result'];
  }

  /// Returns the screen rectangle occupied by this object in the given map view.
  ///
  /// If the object is not currently rendered or the information is not
  /// available, the method returns `null`.
  ///
  /// ## Parameters
  ///
  /// - [object]: (`GemMapController`) The map controller for the target map
  ///   view.
  ///
  /// ## Returns
  ///
  /// - (`Rectangle<int>?`) The screen rectangle in pixels, or `null` if not
  ///   available.
  ///
  /// ## See also:
  ///
  /// - [position] - Get the object's coordinates.
  Rectangle<int>? getScreenRect(final GemMapController object) {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'MapSceneObject',
      'getScreenRect',
      args: object.pointerId,
    );

    final int gemApiError = resultString['gemApiError'];

    if (gemApiError != 0) {
      return null;
    }

    final Rectangle<int> rect = Rectangle<int>(
      resultString['result']['x'] ?? 0,
      resultString['result']['y'] ?? 0,
      resultString['result']['width'] ?? 0,
      resultString['result']['height'] ?? 0,
    );

    return rect;
  }
}

/// Formats supported for scene object and texture data.
///
/// Use this enum to indicate the file format when supplying binary scene
/// object data to methods such as [MapSceneObject.customizeDefPositionTracker].
///
/// {@category Maps & 3D Scenes}
enum SceneObjectFileFormat {
  /// Wavefront `.obj` model format.
  obj,

  /// Wavefront `.mtl` material library format.
  mat,

  /// Texture image data used for flat textures.
  tex,

  /// glTF model format.
  gltf,
}

/// @nodoc
extension SceneObjectFileFormatExtension on SceneObjectFileFormat {
  int get id {
    switch (this) {
      case SceneObjectFileFormat.obj:
        return 0;
      case SceneObjectFileFormat.mat:
        return 1;
      case SceneObjectFileFormat.tex:
        return 2;
      case SceneObjectFileFormat.gltf:
        return 3;
    }
  }

  static SceneObjectFileFormat fromId(final int id) {
    switch (id) {
      case 0:
        return SceneObjectFileFormat.obj;
      case 1:
        return SceneObjectFileFormat.mat;
      case 2:
        return SceneObjectFileFormat.tex;
      case 3:
        return SceneObjectFileFormat.gltf;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
