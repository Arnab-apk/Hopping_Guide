// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/src/core/private/event_driven_progress_listener.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Animation descriptor used for camera and map transitions.
///
/// A lightweight object that describes how map or camera transitions should be animated.
/// It carries the animation type, duration (in milliseconds), and an optional completion callback
/// that is invoked when the underlying native animation finishes.
///
/// It is passed to methods that perform camera movement or view changes (for example
/// [GemMapController.alignNorthUp], [GemView.centerOnRoutePart] or
/// [FollowPositionPreferences.setPerspective]) to control visual transitions
///
/// ## See also:
///
/// - [GemMapController] - Controller for map interactions that uses [GemAnimation]
/// for map transitions.
///
/// {@category Maps & 3D Scenes}
class GemAnimation {
  /// Construct a new [GemAnimation].
  ///
  /// Creates an animation descriptor and registers an internal progress listener
  /// that will invoke [onCompleted] when the native animation finishes. This constructor
  /// is suitable for passing directly to SDK methods that accept an animation object.
  ///
  /// ## Parameters
  ///
  /// - [type]: The animation type. Defaults to [AnimationType.none].
  /// - [duration]: Animation duration in milliseconds. A value of `0` uses
  ///   the SDK's default duration.
  /// - [onCompleted]: Optional callback invoked after the native animation completes.
  GemAnimation({
    this.type = AnimationType.none,
    this.duration = 0,
    this.onCompleted,
  }) {
    _progressListener = EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(
      _progressListener.id,
      _progressListener,
    );

    _progressListener.registerOnCompleteWithData((_, _, _) {
      if (onCompleted != null) {
        onCompleted!();
      }
    });
  }

  /// Construct a [GemAnimation] that represents no animation.
  GemAnimation.none() : this(type: AnimationType.none);

  /// Construct a [GemAnimation] configured for a linear animation.
  ///
  /// ## Parameters
  ///
  /// - [duration]: Optional [Duration]. When null, the SDK default duration is used.
  /// - [onCompleted]: Optional completion callback executed when the animation finishes.
  GemAnimation.linear({Duration? duration, void Function()? onCompleted})
    : this(
        type: AnimationType.linear,
        duration: duration == null ? 0 : duration.inMilliseconds,
        onCompleted: onCompleted,
      );

  GemAnimation._(
    this.type,
    this.duration,
    final EventDrivenProgressListener progressListener,
  ) : _progressListener = progressListener;

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory GemAnimation.fromJson(final Map<String, dynamic> json) {
    return GemAnimation._(
      json['type'],
      json['duration'],
      EventDrivenProgressListener.init(json['progress']),
    );
  }

  /// The animation visual style.
  ///
  /// Use [AnimationType.none] when no visible animation is desired, or another specific
  /// value for different transition styles.
  AnimationType type;

  /// Animation duration in milliseconds (0 means use SDK default / no explicit duration).
  int duration;

  /// Optional callback invoked when the native animation completes.
  ///
  /// The callback is registered with an internal [EventDrivenProgressListener] and
  /// will be executed on the registered completion event.
  void Function()? onCompleted;

  late EventDrivenProgressListener _progressListener;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['type'] = type.id;
    json['progress'] = _progressListener.id;
    json['duration'] = duration;

    return json;
  }
}

/// Describes how a map-related transition should be animated.
///
/// The available animation types are:
/// - [none]: Apply the change immediately with no interpolation. Use this when
///   you want an instantaneous update.
/// - [linear]: Interpolate values at a constant rate from the start to the end
///   value over the provided duration. This produces uniform, predictable
///   motion and does not apply easing.
///
/// {@category Maps & 3D Scenes}
enum AnimationType {
  /// No animation
  none,

  /// Linear animation
  linear,
}

/// @nodoc
extension AnimationTypeExtension on AnimationType {
  int get id {
    switch (this) {
      case AnimationType.none:
        return 0;
      case AnimationType.linear:
        return 1;
    }
  }

  static AnimationType fromId(final int id) {
    switch (id) {
      case 0:
        return AnimationType.none;
      case 1:
        return AnimationType.linear;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
