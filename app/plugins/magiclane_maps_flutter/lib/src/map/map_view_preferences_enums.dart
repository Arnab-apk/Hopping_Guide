// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Map details quality levels
///
/// ## Also see:
///
/// - [MapViewPreferences.mapDetailsQualityLevel] - Get or set the current quality level via preferences.
///
/// {@category Maps & 3D Scenes}
enum MapDetailsQualityLevel {
  /// Low quality details
  low,

  /// Medium quality details
  medium,

  /// High quality details (default)
  high,
}

/// @nodoc
extension MapDetailsQualityLevelExtension on MapDetailsQualityLevel {
  int get id {
    switch (this) {
      case MapDetailsQualityLevel.low:
        return 0;
      case MapDetailsQualityLevel.medium:
        return 1;
      case MapDetailsQualityLevel.high:
        return 2;
    }
  }

  static MapDetailsQualityLevel fromId(final int id) {
    switch (id) {
      case 0:
        return MapDetailsQualityLevel.low;
      case 1:
        return MapDetailsQualityLevel.medium;
      case 2:
        return MapDetailsQualityLevel.high;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Touch gestures list
///
/// ## Also see:
///
/// - [MapViewPreferences.enableTouchGestures] - Enable or disable specific gestures.
///
/// {@category Maps & 3D Scenes}
enum TouchGestures {
  /// Single pointer touch event (down and up with negligible move) - not used - could be used for selection.
  onTouch,

  /// Single pointer long touch event - put a marker on the map.
  onLongDown,

  /// Single pointer double touch event - zoom in.
  onDoubleTouch,

  /// Two pointers single touch event - zoom out.
  onTwoPointersTouch,

  /// Two pointers double touch event - autocenter the globe.
  onTwoPointersDoubleTouch,

  /// Single pointer move event - pan.
  onMove,

  /// Single pointer touch event followed immediately by a vertical move/pan event = single pointer zoom in/out.
  onTouchMove,

  /// Single pointer linear swipe event - move/pan with pointer moving when lifted, in the dXInPix, dYInPix direction.
  onSwipe,

  /// Two pointer zooming swipe event - one or both pointers moving when lifted during pinch zoom, causing motion to continue for a while.
  onPinchSwipe,

  /// Two pointers pinch (pointers moving toward or away from each other) event - can include zoom and shove (2-pointer pan) but no rotate.
  onPinch,

  /// Two pointers rotate event - can include zoom and shove (distance between 2 pointers remains constant while line connecting them moves or rotates).
  onRotate,

  /// Two pointers shove event(2-pointer pan - pointers moving in the same direction the same distance) - can include rotate and zoom.
  onShove,

  /// Two pointers touch event followed immediately by a pinch event - not used.
  onTouchPinch,

  /// Two pointers touch event followed immediately by a rotate event - not used.
  onTouchRotate,

  /// Two pointers touch event followed immediately by a shove event - not used.
  onTouchShove,

  /// Two pointer rotating swipe event - one or both pointers moving when lifted during pinch rotate, causing motion to continue for a while.
  onRotatingSwipe,

  /// Allow internal event processing - if disabled, only send notifications to external listeners (UI)
  internalProcessing,
}

/// @nodoc
extension TouchGesturesExtension on TouchGestures {
  int get id {
    switch (this) {
      case TouchGestures.onTouch:
        return 256;
      case TouchGestures.onLongDown:
        return 512;
      case TouchGestures.onDoubleTouch:
        return 1024;
      case TouchGestures.onTwoPointersTouch:
        return 2048;
      case TouchGestures.onTwoPointersDoubleTouch:
        return 4096;
      case TouchGestures.onMove:
        return 8192;
      case TouchGestures.onTouchMove:
        return 16384;
      case TouchGestures.onSwipe:
        return 32768;
      case TouchGestures.onPinchSwipe:
        return 65536;
      case TouchGestures.onPinch:
        return 131072;
      case TouchGestures.onRotate:
        return 262144;
      case TouchGestures.onShove:
        return 524288;
      case TouchGestures.onTouchPinch:
        return 1048576;
      case TouchGestures.onTouchRotate:
        return 2097152;
      case TouchGestures.onTouchShove:
        return 4194304;
      case TouchGestures.onRotatingSwipe:
        return 8388608;
      case TouchGestures.internalProcessing:
        return 2147483648;
    }
  }

  static TouchGestures fromId(final int id) {
    switch (id) {
      case 256:
        return TouchGestures.onTouch;
      case 512:
        return TouchGestures.onLongDown;
      case 1024:
        return TouchGestures.onDoubleTouch;
      case 2048:
        return TouchGestures.onTwoPointersTouch;
      case 4096:
        return TouchGestures.onTwoPointersDoubleTouch;
      case 8192:
        return TouchGestures.onMove;
      case 16384:
        return TouchGestures.onTouchMove;
      case 32768:
        return TouchGestures.onSwipe;
      case 65536:
        return TouchGestures.onPinchSwipe;
      case 131072:
        return TouchGestures.onPinch;
      case 262144:
        return TouchGestures.onRotate;
      case 524288:
        return TouchGestures.onShove;
      case 1048576:
        return TouchGestures.onTouchPinch;
      case 2097152:
        return TouchGestures.onTouchRotate;
      case 4194304:
        return TouchGestures.onTouchShove;
      case 8388608:
        return TouchGestures.onRotatingSwipe;
      case 2147483648:
        return TouchGestures.internalProcessing;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Buildings visibility modes
///
/// {@category Maps & 3D Scenes}
enum BuildingsVisibility {
  /// Use default visibility settings
  defaultVisibility,

  /// Hide
  hide,

  /// Show 2D (flat)
  twoDimensional,

  /// Show 3D
  threeDimensional,
}

/// @nodoc
extension BuildingsVisibilityExtension on BuildingsVisibility {
  int get id {
    switch (this) {
      case BuildingsVisibility.defaultVisibility:
        return 0;
      case BuildingsVisibility.hide:
        return 1;
      case BuildingsVisibility.twoDimensional:
        return 2;
      case BuildingsVisibility.threeDimensional:
        return 3;
    }
  }

  static BuildingsVisibility fromId(final int id) {
    switch (id) {
      case 0:
        return BuildingsVisibility.defaultVisibility;
      case 1:
        return BuildingsVisibility.hide;
      case 2:
        return BuildingsVisibility.twoDimensional;
      case 3:
        return BuildingsVisibility.threeDimensional;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
