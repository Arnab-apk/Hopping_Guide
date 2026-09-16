// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';

/// Preferences used when requesting an audio session from the platform.
///
/// This object controls how the SDK requests audio focus (category,
/// preferred output, delay before granting focus and exclusivity).
///
/// Modificatios to an instance of this class are not applied automatically.
/// To apply changes, call [SoundPlayingService.soundSessionRequestPreferences].
///
/// ## Also see:
///
/// - [SoundPlayingService.soundSessionRequestPreferences] - Get or set the preferences
///
/// {@category Sound}
/// {@category Snapshot Types}
class SoundSessionRequestPreferences {
  /// Create sound session request preferences.
  ///
  /// ## Parameters
  ///
  /// - [audioCategory]: The audio category used for the session request.
  /// - [audioOutput]: Preferred audio output for the session.
  /// - [delay]: Delay before granting audio focus.
  /// - [exclusive]: Whether the session should be exclusive.
  SoundSessionRequestPreferences({
    required this.audioCategory,
    required this.audioOutput,
    required this.delay,
    required this.exclusive,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  factory SoundSessionRequestPreferences.fromMap(Map<String, dynamic> map) {
    return SoundSessionRequestPreferences(
      audioCategory: AudioCategoryExtension.fromId(map['audioCategory'] as int),
      audioOutput: AudioOutputExtension.fromId(map['audioOutput'] as int),
      delay: Duration(milliseconds: map['delayMs'] as int),
      exclusive: map['exclusive'] as bool,
    );
  }

  /// The audio category used for the session request.
  ///
  /// See [AudioCategory] for common categories such as playback or
  /// recording.
  final AudioCategory audioCategory;

  /// Preferred audio output for the session.
  ///
  /// Changing the audio output may require special permissions on
  /// Android when using Bluetooth as phone call. See [AudioOutput.bluetoothAsPhoneCall]
  /// for more information.
  final AudioOutput audioOutput;

  /// Delay before granting audio focus.
  final Duration delay;

  /// Whether the session should be exclusive.
  ///
  /// When `true` other audio output should be silenced during the session.
  final bool exclusive;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'audioCategory': audioCategory.id,
      'audioOutput': audioOutput.id,
      'delayMs': delay.inMilliseconds,
      'exclusive': exclusive,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is SoundSessionRequestPreferences &&
        other.audioCategory == audioCategory &&
        other.audioOutput == audioOutput &&
        other.delay.inMilliseconds == delay.inMilliseconds &&
        other.exclusive == exclusive;
  }

  @override
  int get hashCode {
    return audioCategory.hashCode ^
        audioOutput.hashCode ^
        delay.inMilliseconds.hashCode ^
        exclusive.hashCode;
  }
}

/// Audio category type used when requesting an audio session.
///
/// {@category Sound}
enum AudioCategory {
  /// Category used for media playback.
  playback,

  /// Category used for recording audio input.
  recording,

  /// Category used for simultaneous playback and recording.
  playbackAndRecording,
}

/// @nodoc
extension AudioCategoryExtension on AudioCategory {
  int get id {
    switch (this) {
      case AudioCategory.playback:
        return 0;
      case AudioCategory.recording:
        return 1;
      case AudioCategory.playbackAndRecording:
        return 2;
    }
  }

  static AudioCategory fromId(int id) {
    switch (id) {
      case 0:
        return AudioCategory.playback;
      case 1:
        return AudioCategory.recording;
      case 2:
        return AudioCategory.playbackAndRecording;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
