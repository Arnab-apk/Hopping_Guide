// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Preferences controlling how the SDK plays sounds and TTS.
///
/// Use this object to configure per-severity sound settings (volume,
/// maximum playback time, audio stream type and focus delay).
///
/// Modificatios to an instance of this class are not applied automatically.
/// To apply changes, call [SoundPlayingService.setSoundPlayingPreferences].
///
/// # Also see:
///
/// - [SoundPlayingService.setSoundPlayingPreferences] - Set the preferences
/// - [SoundPlayingService.getSoundPlayingPreferences] - Get the current preferences
///
/// {@category Sound}
/// {@category Snapshot Types}
class SoundPlayingPreferences {
  /// Create sound playing preferences.
  ///
  /// ## Parameters
  ///
  /// - [volume]: Playback volume (0..10).
  /// - [maxPlayingTime]: Maximum play time. Range: 0..255 seconds. Use
  ///   [Duration.zero] for no limit.
  /// - [audioStreamType]: Which audio stream to use (see [AudioStreamType]).
  /// - [delay]: Delay granting audio focus (useful for Bluetooth-as-phone-call
  ///   output).
  SoundPlayingPreferences({
    required this.volume,
    required this.maxPlayingTime,
    required this.audioStreamType,
    required this.delay,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  factory SoundPlayingPreferences.fromMap(Map<String, dynamic> map) {
    return SoundPlayingPreferences(
      volume: map['volume'],
      maxPlayingTime: Duration(seconds: map['maxPlayingTime']),
      audioStreamType: AudioStreamTypeExtension.fromId(map['audioStreamType']),
      delay: Duration(milliseconds: map['delay']),
    );
  }

  /// The playback volume (0..10).
  ///
  /// Default: 5
  int volume;

  /// Maximum playback time.
  ///
  /// Range: 0..255 seconds. Use [Duration.zero] for no limit.
  Duration maxPlayingTime;

  /// The audio stream used for playback.
  AudioStreamType audioStreamType;

  /// Delay before requesting audio focus when using certain outputs.
  Duration delay;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'volume': volume,
      'maxPlayingTime': maxPlayingTime.inSeconds,
      'audioStreamType': audioStreamType.id,
      'delay': delay.inMilliseconds,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is SoundPlayingPreferences &&
        other.volume == volume &&
        other.maxPlayingTime.inSeconds == maxPlayingTime.inSeconds &&
        other.audioStreamType == audioStreamType &&
        other.delay.inMilliseconds == delay.inMilliseconds;
  }

  @override
  int get hashCode {
    return volume.hashCode ^
        maxPlayingTime.inSeconds.hashCode ^
        audioStreamType.hashCode ^
        delay.inMilliseconds.hashCode;
  }
}

/// Audio stream type used for playback.
///
/// Select which platform audio stream category should be used when
/// requesting audio focus.
///
/// {@category Sound}
enum AudioStreamType {
  /// Identify the audio stream for music.
  music,

  /// Identify the audio stream for voice calls.
  voiceCall,
}

/// @nodoc
extension AudioStreamTypeExtension on AudioStreamType {
  int get id {
    switch (this) {
      case AudioStreamType.music:
        return 3;
      case AudioStreamType.voiceCall:
        return 0;
    }
  }

  static AudioStreamType fromId(int id) {
    switch (id) {
      case 3:
        return AudioStreamType.music;
      case 0:
        return AudioStreamType.voiceCall;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
