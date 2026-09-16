// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Alert severity levels used for sound-related settings.
///
/// Severity controls which preferences apply when playing alerts.
///
/// {@category Sound}
enum AlertSeverity {
  /// Informational alerts (lowest priority).
  information,

  /// Warning alerts (higher priority).
  warning,
}

/// @nodoc
extension AlertSeverityExtension on AlertSeverity {
  int get id {
    switch (this) {
      case AlertSeverity.information:
        return 0;
      case AlertSeverity.warning:
        return 2;
    }
  }

  static AlertSeverity fromId(int id) {
    switch (id) {
      case 0:
        return AlertSeverity.information;
      case 2:
        return AlertSeverity.warning;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// High-level static API for playing sounds and TTS through the SDK.
///
/// This class exposes only static members and acts as a thin bridge to the
/// native sound engine. Use [SoundPlayingListener] to observe playback
/// lifecycle events, and [SoundPlayingPreferences] to configure per-severity
/// playback settings.
///
/// {@category Sound}
abstract class SoundPlayingService {
  /// Play the given text using TTS.
  ///
  /// ## Parameters
  ///
  /// - [text]: The text to be synthesized and played.
  /// - [severity]: Optional severity used to select preferences (defaults to
  ///   [AlertSeverity.information]).

  static Future<void> playText(
    String text, {
    AlertSeverity severity = AlertSeverity.information,
  }) async {
    if (GemKitPlatform.instance.androidVersion > -1) {
      await GemKitPlatform.instance
          .getChannel(mapId: -1)
          .invokeMethod<String>(
            'callObjectMethod',
            jsonEncode(<String, dynamic>{
              'id': 0,
              'class': 'SoundService',
              'method': 'playText',
              'args': <String, dynamic>{'text': text, 'severity': severity.id},
            }),
          );
    } else {
      staticMethod(
        'SoundService',
        'playText',
        args: <String, dynamic>{'text': text, 'severity': severity.id},
      );
    }
  }

  /// Play a pre-recorded sound by id.
  ///
  /// ## Parameters
  ///
  /// - [soundId]: Platform-specific identifier for the sound to play.
  static void playSound(dynamic soundId) {
    staticMethod('SoundService', 'playSound', args: soundId);
  }

  /// Set the warnings volume (0..10).
  ///
  /// If a system interruption is active (e.g., a phone call), the volume
  /// change may be deferred until the interruption ends.
  ///
  /// ## Parameters
  ///
  /// - [volume]: Integer volume in range 0..10.
  ///
  /// ## Also see:
  ///
  /// - [voiceVolume] - Get or set the voice (TTS) volume.
  static set warningsVolume(int volume) {
    staticMethod('SoundService', 'setWarningsVolume', args: volume);
  }

  /// Returns the current warnings volume.
  ///
  /// ## Returns
  ///
  /// - Integer volume in the range 0..10.
  ///
  /// ## Also see:
  ///
  /// - [voiceVolume] - Get or set the voice (TTS) volume.
  static int get warningsVolume {
    final OperationResult result = staticMethod(
      'SoundService',
      'getWarningsVolume',
    );

    return result['result'];
  }

  /// Set the voice (TTS) volume (0..10).
  ///
  /// If a system interruption is active (e.g., a phone call), the volume
  /// change may be deferred until the interruption ends.
  ///
  /// ## Parameters
  ///
  /// - [volume]: Integer volume in range 0..10.
  ///
  /// ## Also see:
  ///
  /// - [warningsVolume] - Get or set the warnings volume.
  static set voiceVolume(int volume) {
    staticMethod('SoundService', 'setVoiceVolume', args: volume);
  }

  /// Returns the current voice (TTS) volume.
  ///
  /// ## Returns
  ///
  /// - Integer volume in the range 0..10.
  ///
  /// ## Also see:
  ///
  /// - [warningsVolume] - Get or set the warnings volume.
  static int get voiceVolume {
    final OperationResult result = staticMethod(
      'SoundService',
      'getVoiceVolume',
    );
    return result['result'];
  }

  /// Enable or disable automatic playback of TTS instructions.
  ///
  /// ## Parameters
  ///
  /// - [canPlaySound]: `true` to enable automatic playback, `false` to
  ///   disable it.
  ///
  /// ## Also see:
  ///
  /// - [NavigationService] - Service resposbible for navigation instructions.
  /// - [cancelNavigationSoundsPlaying] - Cancel currently playing navigation sounds.
  static set canPlaySounds(bool canPlaySound) {
    staticMethod('SoundService', 'setCanPlaySounds', args: canPlaySound);
  }

  /// Returns whether automatic playback of TTS instructions is enabled.
  ///
  /// ## Returns
  ///
  /// - `true` when automatic playback is enabled, `false` otherwise.
  ///
  /// ## Also see:
  ///
  /// - [NavigationService] - Service resposbible for navigation instructions.
  static bool get canPlaySounds {
    final OperationResult result = staticMethod(
      'SoundService',
      'canPlaySounds',
    );
    return result['result'];
  }

  /// Cancel currently playing navigation sounds.
  ///
  /// Use this to immediately stop navigation-related audio playback.
  static void cancelNavigationSoundsPlaying() {
    staticMethod('SoundService', 'cancelNavigationSoundsPlaying');
  }

  /// Select the audio output type.
  ///
  /// Changing the audio output may require special permissions on
  /// Android when using Bluetooth as phone call. See [AudioOutput.bluetoothAsPhoneCall]
  /// for more information.
  ///
  /// ## Parameters
  ///
  /// - [audioOutput]: Desired audio output (see [AudioOutput]).
  static set audioOutput(AudioOutput audioOutput) {
    staticMethod('SoundService', 'setAudioOutput', args: audioOutput.id);
  }

  /// Returns the currently selected audio output type.
  ///
  /// ## Returns
  ///
  /// - The active [AudioOutput] value.
  static AudioOutput get audioOutput {
    final OperationResult result = staticMethod(
      'SoundService',
      'getAudioOutput',
    );
    return AudioOutputExtension.fromId(result['result']);
  }

  /// Set call timing delay in milliseconds.
  ///
  /// Only relevant when audio is played as a Bluetooth phone call.
  ///
  /// ## Parameters
  ///
  /// - [delay]: Delay in milliseconds.
  static set callTimingDelay(int delay) {
    staticMethod('SoundService', 'setCallTimingDelay', args: delay);
  }

  /// Returns the current call timing delay (milliseconds).
  ///
  /// ## Returns
  ///
  /// - The delay in milliseconds.
  static int get callTimingDelay {
    final OperationResult result = staticMethod(
      'SoundService',
      'getCallTimingDelay',
    );
    return result['result'];
  }

  /// Apply sound playback preferences for the given [severity].
  ///
  /// Only fields present in the provided [SoundPlayingPreferences] instance
  /// are applied. To change preferences, modify an instance returned by
  /// [getSoundPlayingPreferences] and call this method to persist the change.
  ///
  /// This method does not take into account any ongoing system interruptions.
  ///
  /// ## Parameters
  ///
  /// - [soundPlayingPreferences]: Preferences to apply.
  /// - [severity]: Target alert severity (defaults to
  ///   [AlertSeverity.information]).
  static void setSoundPlayingPreferences(
    SoundPlayingPreferences soundPlayingPreferences, {
    AlertSeverity severity = AlertSeverity.information,
  }) {
    staticMethod(
      'SoundService',
      'setSoundPlayingPreferences',
      args: <String, Object>{
        'severity': severity.id,
        'preferences': soundPlayingPreferences.toMap(),
      },
    );
  }

  /// Retrieve sound playback preferences for the given [severity].
  ///
  /// The returned instance is a copy; call [setSoundPlayingPreferences] to
  /// persist modifications.
  ///
  /// ## Parameters
  ///
  /// - [severity]: Alert severity to retrieve preferences for.
  ///
  /// ## Returns
  ///
  /// - A [SoundPlayingPreferences] instance for the requested severity.
  static SoundPlayingPreferences getSoundPlayingPreferences({
    AlertSeverity severity = AlertSeverity.information,
  }) {
    final OperationResult result = staticMethod(
      'SoundService',
      'getSoundPlayingPreferences',
      args: severity.id,
    );
    return SoundPlayingPreferences.fromMap(result['result']);
  }

  /// Apply sound session request preferences used when requesting audio
  /// focus from the platform.
  ///
  /// ## Parameters
  ///
  /// - [preferences]: The preferences to apply.
  static set soundSessionRequestPreferences(
    SoundSessionRequestPreferences preferences,
  ) {
    staticMethod(
      'SoundService',
      'setSoundSessionRequestPreferences',
      args: preferences.toMap(),
    );
  }

  /// Return the currently configured sound session request preferences.
  ///
  /// The returned instance is a copy; set [soundSessionRequestPreferences]
  /// to persist changes.
  ///
  /// ## Returns
  ///
  /// - A [SoundSessionRequestPreferences] instance.
  static SoundSessionRequestPreferences get soundSessionRequestPreferences {
    final OperationResult result = staticMethod(
      'SoundService',
      'getSoundSessionRequestPreferences',
    );
    return SoundSessionRequestPreferences.fromMap(result['result']);
  }

  /// Get the native audio output sample rate (Android only).
  ///
  /// On iOS this returns `0`.
  ///
  /// ## Returns
  ///
  /// - The native sample rate, or `0` when not supported.
  static Future<int> get nativeOutputSampleRate async {
    if (GemKitPlatform.instance.androidVersion > -1) {
      final dynamic resultString = await GemKitPlatform.instance
          .getChannel(mapId: -1)
          .invokeMethod<String>(
            'callObjectMethod',
            jsonEncode(<String, dynamic>{
              'id': 0,
              'class': 'SoundService',
              'method': 'getNativeOutputSampleRate',
              'args': <String, dynamic>{},
            }),
          );
      final dynamic result = jsonDecode(resultString!);
      return result['result'];
    } else {
      final OperationResult result = staticMethod(
        'SoundService',
        'getNativeOutputSampleRate',
      );
      return result['result'];
    }
  }

  /// Get the audio low-latency output frame size (Android only).
  ///
  /// On iOS this returns `0`.
  ///
  /// ## Returns
  ///
  /// - The frame size in samples, or `0` when not supported.
  static Future<int> get audioLowLatencyOutputFrameSize async {
    if (GemKitPlatform.instance.androidVersion > -1) {
      final dynamic resultString = await GemKitPlatform.instance
          .getChannel(mapId: -1)
          .invokeMethod<String>(
            'callObjectMethod',
            jsonEncode(<String, dynamic>{
              'id': 0,
              'class': 'SoundService',
              'method': 'getAudioLowLatencyOutputFrameSize',
              'args': <String, dynamic>{},
            }),
          );
      final dynamic result = jsonDecode(resultString!);
      return result['result'];
    } else {
      final OperationResult result = staticMethod(
        'SoundService',
        'getAudioLowLatencyOutputFrameSize',
      );
      return result['result'];
    }
  }

  /// Obtain the singleton [SoundPlayingListener] used to observe playback
  /// events.
  ///
  /// The listener is created once and registered with the platform. Use
  /// [SoundPlayingListener.registerOnStart] and [SoundPlayingListener.registerOnStop] to receive
  /// playback events.
  ///
  /// ## Returns
  ///
  /// - The singleton [SoundPlayingListener] instance.
  static SoundPlayingListener get soundPlayingListener {
    if (_cachedListener != null) {
      return _cachedListener!;
    }

    final OperationResult result = staticMethod(
      'SoundService',
      'getSoundPlayingListener',
    );
    _cachedListener = SoundPlayingListener.init(result['result']);
    GemKitPlatform.instance.registerEventHandler(
      _cachedListener!.id,
      _cachedListener!,
    );

    return _cachedListener!;
  }

  static SoundPlayingListener? _cachedListener;

  /// Return the [Language] currently being used in the system as the default TTS language.
  ///
  /// ## Returns
  ///
  /// - The default TTS [Language].
  ///
  /// ## Also see:
  ///
  /// - [SdkSettings.voice] - The currently applied voice settings.
  @experimental
  static Language get ttsDefaultLanguage {
    final OperationResult result = staticMethod(
      'SoundService',
      'getPlayerDefaultLanguage',
      args: 0,
    );
    return Language.fromJson(result['result']);
  }

  /// The API user should not call this method.
  ///
  /// @nodoc
  @internal
  static void reset() {
    _cachedListener = null;
  }
}

/// Audio output type.
///
/// The audio output for sound playback.
///
/// {@category Sound}
enum AudioOutput {
  /// Output on speaker if device is NOT connected to Bluetooth A2DP.
  ///
  /// Output on Bluetooth A2DP if device is connected to Bluetooth A2DP.
  automatic,

  /// Output on Bluetooth as phone call.
  ///
  /// Requires special permissions on Android:
  /// ```xml
  ///   <uses-permission android:name="android.permission.BLUETOOTH" />
  ///   <uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />
  ///   <uses-permission android:name="android.permission.READ_PHONE_STATE" />
  ///   <uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
  /// ```
  ///
  /// Request the permissions at runtime as needed using a package such as
  /// `permission_handler`.
  bluetoothAsPhoneCall,

  /// Output only on speaker.
  speaker,
}

/// @nodoc
extension AudioOutputExtension on AudioOutput {
  int get id {
    switch (this) {
      case AudioOutput.automatic:
        return 0;
      case AudioOutput.bluetoothAsPhoneCall:
        return 1;
      case AudioOutput.speaker:
        return 2;
    }
  }

  static AudioOutput fromId(int id) {
    switch (id) {
      case 0:
        return AudioOutput.automatic;
      case 1:
        return AudioOutput.bluetoothAsPhoneCall;
      case 2:
        return AudioOutput.speaker;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
