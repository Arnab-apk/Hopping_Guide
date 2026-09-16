// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Script variant types.
///
/// {@category Locale}
enum ScriptVariant {
  /// Native script
  native,

  /// Transcription variant
  transcription,

  /// Transliteration variant
  transliteration,
}

/// @nodoc
extension ScriptVariantExtension on ScriptVariant {
  int get id {
    switch (this) {
      case ScriptVariant.native:
        return 0;
      case ScriptVariant.transcription:
        return 256;
      case ScriptVariant.transliteration:
        return 512;
    }
  }

  static ScriptVariant fromId(final int id) {
    switch (id) {
      case 0:
        return ScriptVariant.native;
      case 256:
        return ScriptVariant.transcription;
      case 512:
        return ScriptVariant.transliteration;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Complete language specification used throughout the SDK.
///
/// [Language] encapsulates a language's display name and the standard codes used
/// by the SDK (ISO 639-3 language code, ISO 3166-1 region code, ISO 15924 script
/// code) together with rendering hints such as [ScriptVariant] and a flag for
/// right-to-left scripts.
///
/// ## See also:
///
/// - [SdkSettings.getBestLanguageMatch] — Find the best available language match.
/// - [SdkSettings.languageList] — List of supported languages provided by the SDK.
/// - [ISOCodeConversions.convertLanguageIso] — Helper to convert language ISO codes.
/// - [SdkSettings.language] — The currently selected language.
/// - [Voice] - Represents a voice containing language and other voice settings.
///
/// {@category Locale}
class Language {
  /// Creates a [Language] instance.
  ///
  /// For finding a language supported by the SDK prefer [SdkSettings.getBestLanguageMatch].
  /// It is not recommended to create language instances manually.
  ///
  /// ## Parameters
  ///
  /// - [name]: Human readable language name (for example `English`).
  /// - [languagecode]: ISO 639-3 three-letter language code (for example `eng`).
  /// - [regioncode]: Optional ISO 3166-1 three-letter region code (for example `USA`).
  /// - [scriptcode]: Optional ISO 15924 four-letter script code (for example `Latn`).
  /// - [scriptvariant]: Requested script variant to use when rendering language-specific text.
  /// - [isRightToLeft]: Whether the language is written right-to-left.
  Language({
    this.name = '',
    this.languagecode = '',
    this.regioncode = '',
    this.scriptcode = '',
    this.scriptvariant = ScriptVariant.native,
    this.isRightToLeft = false,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory Language.fromJson(final Map<String, dynamic> json) {
    return Language(
      name: json['name'] ?? '',
      languagecode: json['languagecode'] ?? '',
      regioncode: json['regioncode'] ?? '',
      scriptcode: json['scriptcode'] ?? '',
      scriptvariant: ScriptVariantExtension.fromId(
        json['scriptvariant'] ?? ScriptVariant.native.id,
      ),
      isRightToLeft: json['righttoleft'] ?? false,
    );
  }

  /// Language name.
  String name;

  /// ISO 639-3 three-letter language code.
  String languagecode;

  /// ISO 3166-1 three-letter region code.
  String regioncode;

  /// ISO 15924 four-letter script code.
  String scriptcode;

  /// Script variant.
  ScriptVariant scriptvariant;

  /// True if and only if the text is right to left.
  bool isRightToLeft;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['name'] = name;
    json['languagecode'] = languagecode;
    json['regioncode'] = regioncode;
    json['scriptcode'] = scriptcode;
    json['scriptvariant'] = scriptvariant.id;
    json['righttoleft'] = isRightToLeft;
    return json;
  }

  @override
  bool operator ==(covariant final Language other) {
    if (identical(this, other)) {
      return true;
    }

    return other.name == name &&
        other.languagecode == languagecode &&
        other.regioncode == regioncode &&
        other.scriptcode == scriptcode &&
        other.isRightToLeft == isRightToLeft;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        languagecode.hashCode ^
        regioncode.hashCode ^
        scriptcode.hashCode ^
        isRightToLeft.hashCode;
  }
}
