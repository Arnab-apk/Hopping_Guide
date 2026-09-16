// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Voice information object.
///
/// Provides metadata about a voice asset: its name, language and file
/// location. Returned voices can be used with TTS and playback APIs.
///
/// It is usually obtained via [SdkSettings.voice] after setting
/// the desired voice using [SdkSettings.setVoiceByPath] or
/// [SdkSettings.setTTSVoiceByLanguage].
///
/// ## Also see:
///
/// - [Language] - Information about the language associated.
/// - [SdkSettings.voice] - Get the currently selected voice.
/// - [SdkSettings.setVoiceByPath] - Set the TTS voice by file path.
/// - [SdkSettings.setTTSVoiceByLanguage] - Set the TTS voice by language.
///
/// {@category Locale}
class Voice extends GemAutoreleaseObject {
  // ignore: unused_element
  Voice._() : super(-1);

  @internal
  Voice.init(super.id);

  /// Returns the human-readable name of the voice.
  ///
  /// ## Returns
  ///
  /// - [String]: voice display name.
  String get name {
    final OperationResult result = objectMethod(pointerId, 'Voice', 'getName');
    return result['result'];
  }

  /// Returns the [Language] associated with this voice.
  ///
  /// ## Returns
  ///
  /// - [Language]: the voice language metadata.
  Language get language {
    final OperationResult result = objectMethod(
      pointerId,
      'Voice',
      'getLanguage',
    );
    return Language.fromJson(result['result']);
  }

  /// Returns the absolute file path for the voice asset on the device.
  ///
  /// ## Returns
  ///
  /// - [String]: full path to the voice file.
  String get fileName {
    final OperationResult result = objectMethod(
      pointerId,
      'Voice',
      'getFileName',
    );
    return result['result'];
  }

  /// Returns the voice type ([VoiceType]) indicating human or computer voice.
  ///
  /// ## Returns
  ///
  /// - [VoiceType]: voice classification.
  VoiceType get type {
    final OperationResult result = objectMethod(pointerId, 'Voice', 'getType');
    return VoiceTypeExtension.fromId(result['result']);
  }

  /// Returns the internal identifier for this voice.
  ///
  /// ## Returns
  ///
  /// - [int]: voice id
  int get id {
    final OperationResult result = objectMethod(pointerId, 'Voice', 'getId');
    return result['result'];
  }
}

/// Enumerates available voice types for TTS and voice playback.
///
/// Also see:
///
/// - [Voice] - Voice information object.
/// - [ContentStore] - Management of content including voices.
///
/// {@category Locale}
enum VoiceType {
  /// Human (recorded) voice.
  human,

  /// Computer (TTS) voice.
  computer,
}

/// @nodoc
extension VoiceTypeExtension on VoiceType {
  int get id {
    switch (this) {
      case VoiceType.human:
        return 0;
      case VoiceType.computer:
        return 1;
    }
  }

  static VoiceType fromId(int id) {
    switch (id) {
      case 0:
        return VoiceType.human;
      case 1:
        return VoiceType.computer;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
