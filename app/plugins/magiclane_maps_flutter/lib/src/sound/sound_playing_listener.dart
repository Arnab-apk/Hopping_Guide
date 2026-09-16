// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';

/// Specifies the type of media the sound engine is currently playing.
//
/// Provides the currently active media type used by the SDK sound engine.
/// Use [SoundPlayingListener.soundPlayType] to read the current value.
///
/// {@category Sound}
enum SoundPlayType {
  /// There is nothing playing.
  none,

  /// A custom text-to-speech message is playing.
  text,

  /// A sound file is being played.
  file,

  /// A predefined alert file is being played.
  alert,

  /// A navigation sound is being played.
  navigationSound,

  /// A sound identified by a specific ID is being played.
  soundById,
}

/// @nodoc
extension SoundPlayTypeExtension on SoundPlayType {
  int get id {
    switch (this) {
      case SoundPlayType.none:
        return 0;
      case SoundPlayType.text:
        return 1;
      case SoundPlayType.file:
        return 2;
      case SoundPlayType.alert:
        return 3;
      case SoundPlayType.navigationSound:
        return 4;
      case SoundPlayType.soundById:
        return 5;
    }
  }

  static SoundPlayType fromId(int id) {
    switch (id) {
      case 0:
        return SoundPlayType.none;
      case 1:
        return SoundPlayType.text;
      case 2:
        return SoundPlayType.file;
      case 3:
        return SoundPlayType.alert;
      case 4:
        return SoundPlayType.navigationSound;
      case 5:
        return SoundPlayType.soundById;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Listener for events related to sound playback and text-to-speech.
///
/// Register callbacks on this listener to be notified when a sound starts,
/// stops or when system audio interruptions occur. Only a single sound event
/// can be played by the SDK at a time; use the getters [soundPlayType],
/// [soundPlayContent] and [soundPlayFileName] to inspect details about the
/// currently playing item.
///
/// ## Example
///
/// ```dart
/// final listener = SoundPlayingService.soundPlayingListener;
/// listener.registerOnStart(() {
///   print('sound started');
/// });
/// listener.registerOnStop((error) {
///   if (error == GemError.success) print('played successfully');
/// });
/// ```
///
/// {@category Sound}
class SoundPlayingListener extends EventHandler {
  // ignore: unused_element
  SoundPlayingListener._() : id = -1;

  SoundPlayingListener.init(this.id);
  int id;
  void Function(int newVolume)? _onVolumeChangedByKeys;
  void Function()? _onStart;
  void Function(GemError error)? _onStop;
  void Function()? _onInterruptionStarted;
  void Function()? _onInterruptionEnded;

  /// Register a callback invoked when the user changes the volume via
  /// the device hardware keys.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Called with the new volume level (0-10) when the user
  ///   adjusts volume using hardware keys.
  ///
  /// ## See also:
  ///
  /// - [SoundPlayingService.voiceVolume] - The current voice volume level.
  /// - [SoundPlayingService.warningsVolume] - The current warnings volume level.
  void registerOnVolumeChangedByKeys(
    final void Function(int newVolume)? callback,
  ) {
    _onVolumeChangedByKeys = callback;
  }

  /// Register a callback invoked when the SDK starts playing a sound.
  ///
  /// Additional information about the currently started sound is available
  /// via [soundPlayType], [soundPlayContent] and [soundPlayFileName].
  ///
  /// ## Parameters
  ///
  /// - [callback]: Called when playback starts.
  void registerOnStart(final void Function()? callback) {
    _onStart = callback;
  }

  /// Register a callback invoked when playback completes or is stopped.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Called with a [GemError] indicating the result of the
  ///   playback. Common values:
  ///   - [GemError.success]: playback finished successfully.
  void registerOnStop(final void Function(GemError error)? callback) {
    _onStop = callback;
  }

  /// Register a callback invoked when a system audio interruption begins.
  ///
  /// Typical interruptions include phone calls or alarms. The interruption
  /// may pause or stop current playback.
  ///
  /// The SDK automatically mutes the audio during the interruption.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Called when interruption begins.
  ///
  /// ## Also see:
  ///
  /// - [registerOnInterruptionEnded] - Register a callback for when the interruption ends.
  /// - [isInterrupted] - Check if playback is currently interrupted.
  void registerOnInterruptionStarted(final void Function()? callback) {
    _onInterruptionStarted = callback;
  }

  /// Register a callback invoked when a system audio interruption ends.
  ///
  /// Use this to resume UI state or attempt to restart playback if desired.
  ///
  /// The SDK automatically unmutes the audio when the interruption ends.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Called when interruption ends.
  ///
  /// ## See also:
  ///
  /// - [registerOnInterruptionStarted] - Register a callback for when an interruption begins.
  /// - [isInterrupted] - Check if playback is currently interrupted.
  void registerOnInterruptionEnded(final void Function()? callback) {
    _onInterruptionEnded = callback;
  }

  /// Type of the sound currently played by the engine.
  ///
  /// ## Returns
  ///
  /// - A [SoundPlayType] describing the kind of content currently playing.
  SoundPlayType get soundPlayType {
    final OperationResult result = objectMethod(
      id,
      'SoundPlayingListener',
      'getSoundPlayType',
    );
    return SoundPlayTypeExtension.fromId(result['result']);
  }

  dynamic get rawPointer {
    final OperationResult result = objectMethod(
      id,
      'SoundPlayingListenergetRawPointer',
      'getRawPointer',
    );
    return result['result'];
  }

  /// Content associated with the currently playing sound.
  ///
  /// The meaning varies with [soundPlayType]:
  /// - `null` for [SoundPlayType.none], [SoundPlayType.file], or [SoundPlayType.alert].
  /// - TTS payload when [SoundPlayType.text].
  /// - Transcription when [SoundPlayType.navigationSound].
  ///
  /// ## Returns
  ///
  /// - The content string, or `null` if not applicable.
  String? get soundPlayContent {
    final OperationResult result = objectMethod(
      id,
      'SoundPlayingListener',
      'getSoundPlayContent',
    );
    final String stringRes = result['result'];
    if (stringRes.isEmpty) {
      return null;
    }
    return stringRes;
  }

  /// File name of the sound being played when applicable.
  ///
  /// Returns the filename for [SoundPlayType.file] and [SoundPlayType.alert].
  /// For other types the value is `null`.
  ///
  /// ## Returns
  ///
  /// - The file name string, or `null` when not applicable.
  String? get soundPlayFileName {
    final OperationResult result = objectMethod(
      id,
      'SoundPlayingListener',
      'getSoundPlayPath',
    );
    final String stringRes = result['result'];
    if (stringRes.isEmpty) {
      return null;
    }
    return stringRes;
  }

  /// Whether playback is currently interrupted by a system event.
  ///
  /// Typical causes are phone calls or other system audio interruptions.
  ///
  /// ## Returns
  ///
  /// - `true` when interrupted, `false` otherwise.
  ///
  /// ## Also see:
  ///
  /// - [registerOnInterruptionStarted] - Register a callback for when an interruption begins.
  /// - [registerOnInterruptionEnded] - Register a callback for when the interruption ends.
  bool get isInterrupted {
    final OperationResult result = objectMethod(
      id,
      'SoundPlayingListener',
      'isInterrupted',
    );
    return result['result'];
  }

  @override
  void nativeClear() {
    // No native-side cleanup required for this listener.
  }

  @override
  void clearListeners() {
    _onVolumeChangedByKeys = null;
    _onStart = null;
    _onStop = null;
    _onInterruptionStarted = null;
    _onInterruptionEnded = null;
  }

  @override
  void handleEvent(Map<dynamic, dynamic> arguments) {
    final String eventSubtype = arguments['event_subtype'];

    switch (eventSubtype) {
      case 'onVolumeChangedByKeys':
        if (_onVolumeChangedByKeys != null) {
          _onVolumeChangedByKeys!(arguments['newVolume']);
        }
      case 'startEvent':
        if (_onStart != null) {
          _onStart!();
        }
      case 'completeEvent':
        if (_onStop != null) {
          _onStop!(GemErrorExtension.fromCode(arguments['reason']));
        }
      case 'onInterruptionBeginEvent':
        if (_onInterruptionStarted != null) {
          _onInterruptionStarted!();
        }
      case 'onInterruptionEndedEvent':
        if (_onInterruptionEnded != null) {
          _onInterruptionEnded!();
        }
      default:
        gemSdkLogger.log(
          Level.WARNING,
          'Unknown event subtype: $eventSubtype in RouteListener',
        );
    }
  }
}
