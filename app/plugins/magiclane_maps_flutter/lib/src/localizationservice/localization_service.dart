// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Localization service to retrieve localized strings.
///
/// This class provides methods to get localized strings based on string IDs.
/// The returned strings are localized according to the current [SdkSettings.language]
/// setting.
///
/// Usually it is used by the Magic Lane products but the ids from [LocalizationStringIds] might be valuable
/// for all API users.
///
/// ## Also see:
///
/// - [TtsLocalizationService] - Text-to-speech specific localization, localized according to the current
/// [SdkSettings.voice] setting.
/// - [Language] - Language representation used in localization.
/// - [SdkSettings.language] - Current language setting for localization.
/// - [LocalizationStringIds] - Predefined string IDs for localization.
///
/// {@category Localization Service}
class LocalizationService {
  LocalizationService._();

  /// Retrieves a localized string for the given [stringId].
  ///
  /// If [useDefaultString] is true and the string ID is not found in the current language,
  /// the default string (in english) will be returned instead of an empty string.
  /// If the string ID does not exist, an empty string is returned.
  ///
  /// The localization is based on the current [SdkSettings.language] setting.
  ///
  /// ## Parameters
  ///
  /// - `stringId`: The ID of the string to retrieve.
  /// - `useDefaultString`: Whether to return the default string if the ID is not found.
  ///
  /// ## Returns
  ///
  /// The localized string corresponding to the given [stringId].
  ///
  /// ## Also see:
  ///
  /// - [getStrings] - Retrieve multiple localized strings at once.
  /// - [SdkSettings.language] - Current language setting for localization.
  static String getString(final int stringId, {bool useDefaultString = false}) {
    final OperationResult resultString = staticMethod(
      'Localization',
      'getString',
      args: <String, Object>{
        'stringId': stringId,
        'useDefaultString': useDefaultString,
      },
    );

    return resultString['result'];
  }

  /// Retrieves multiple localized strings for the given list of `stringIds`.
  ///
  /// If [useDefaultString] is true and a string ID is not found in the
  /// current language, the default string (in english) will be returned instead of an empty string.
  /// If a string ID does not exist, an empty string is returned for that ID.
  ///
  /// The localization is based on the current [SdkSettings.language] setting.
  ///
  /// ## Parameters
  ///
  /// - `stringIds`: A list of string IDs to retrieve.
  /// - `useDefaultString`: Whether to return the default string if an ID is not
  ///   found.
  ///
  /// ## Returns
  ///
  /// A list of localized strings corresponding to the given `stringIds`.
  ///
  /// ## Also see:
  ///
  /// - [getString] - Retrieve a single localized string.
  /// - [SdkSettings.language] - Current language setting for localization.
  /// Retrieves a localized TTS string for the given [stringId].
  ///
  /// If [useDefaultString] is true and the string ID is not found for the
  /// currently selected TTS voice/language, the default string (English) will
  /// be returned instead of an empty string. If the string ID does not exist,
  /// an empty string is returned.
  ///
  /// ## Parameters
  ///
  /// - `stringId`: The ID of the string to retrieve.
  /// - `useDefaultString`: Whether to return the default string if the ID is not found.
  ///
  /// ## Returns
  ///
  /// The localized string corresponding to the given [stringId], suitable for TTS.
  ///
  /// ## Also see:
  ///
  /// - [getStrings] - Retrieve multiple localized TTS strings.
  /// - [SdkSettings.voice] - Current voice/language setting used by TTS.
  static List<String> getStrings(
    final List<int> stringIds, {
    bool useDefaultString = false,
  }) {
    final OperationResult resultString = staticMethod(
      'Localization',
      'getStrings',
      args: <String, Object>{
        'stringIds': stringIds,
        'useDefaultString': useDefaultString,
      },
    );

    return List<String>.from(resultString['result']);
  }

  /// Retrieves the native name of the given [language].
  ///
  /// The native name is the name of the language in that language itself.
  ///
  /// ## Parameters
  ///
  /// - [language]: The [Language] for which to retrieve the native name.
  ///
  /// ## Returns
  ///
  /// The native name of the specified [language].
  ///
  /// ## Also see:
  ///
  /// - [Language.name] - The name of the language.
  static String getLanguageNativeName(final Language language) {
    final OperationResult resultString = staticMethod(
      'Localization',
      'getLanguageNativeName',
      args: language,
    );

    return resultString['result'];
  }
}

/// Localization service to retrieve localized strings.
///
/// This class provides methods to get localized strings based on string IDs.
/// The returned strings are localized according to the current [SdkSettings.language]
/// setting.
///
/// Usually it is used by the Magic Lane products but the ids from [LocalizationStringIds] might be valuable
/// for all API users.
///
/// ## Also see:
///
/// - [TtsLocalizationService] - Text-to-speech specific localization, localized according to the current
/// [SdkSettings.voice] setting.
/// - [Language] - Language representation used in localization.
/// - [SdkSettings.language] - Current language setting for localization.
/// - [LocalizationStringIds] - Predefined string IDs for localization.
///
/// {@category Localization Service}
class TtsLocalizationService {
  TtsLocalizationService._();

  /// Text-to-speech localization service used to retrieve localized strings
  /// for voice synthesis.
  ///
  /// Methods on this class return strings localized according to the current
  /// [SdkSettings.voice] language/voice settings. These strings are intended
  /// for text-to-speech output and may differ from UI strings where a voice-
  /// specific variant exists.
  ///
  /// ## Also see:
  ///
  /// - [LocalizationService] - UI-oriented localization utilities.
  /// - [Language] - Language representation used in localization.
  /// - [SdkSettings.voice] - Current voice/language setting used by TTS.
  ///
  /// {@category Core}
  static String getString(final int stringId, {bool useDefaultString = false}) {
    final OperationResult resultString = staticMethod(
      'TTSLocalization',
      'getString',
      args: <String, Object>{
        'stringId': stringId,
        'useDefaultString': useDefaultString,
      },
    );

    return resultString['result'];
  }

  /// Retrieves multiple localized strings for the given list of [stringIds].
  ///
  /// If [useDefaultString] is true and a string ID is not available for the
  /// currently selected TTS voice/language, the default string (English) will
  /// be returned instead of an empty string. If a string ID does not exist,
  /// an empty string is returned for that ID.
  ///
  /// ## Parameters
  ///
  /// - `stringIds`: A list of string IDs to retrieve.
  /// - `useDefaultString`: Whether to return the default string if an ID is
  ///   not found for the current voice/language.
  ///
  /// ## Returns
  ///
  /// A list of localized strings corresponding to the given [stringIds].
  ///
  /// ## Also see:
  ///
  /// - [getString] - Retrieve a single localized TTS string.
  /// - [SdkSettings.voice] - Current voice/language setting used by TTS.
  static List<String> getStrings(
    final List<int> stringIds, {
    bool useDefaultString = false,
  }) {
    final OperationResult resultString = staticMethod(
      'TTSLocalization',
      'getStrings',
      args: <String, Object>{
        'stringIds': stringIds,
        'useDefaultString': useDefaultString,
      },
    );

    return List<String>.from(resultString['result']);
  }

  /// Retrieves the native name of the given [language].
  ///
  /// The native name is the language's name in that language itself and can be
  /// used to present language choices to users in their own language.
  ///
  /// ## Parameters
  ///
  /// - [language]: The [Language] for which to retrieve the native name.
  ///
  /// ## Returns
  ///
  /// The native name of the specified [language].
  ///
  /// ## Also see:
  ///
  /// - [Language.name] - The generic name of the language.
  static String getLanguageNativeName(final Language language) {
    final OperationResult resultString = staticMethod(
      'TTSLocalization',
      'getLanguageNativeName',
      args: language,
    );

    return resultString['result'];
  }
}
