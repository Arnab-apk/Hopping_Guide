// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:ui';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Base class for content parameters.
///
/// Provides a common interface for different types of content parameters such as [RoadMapParameters], [VoiceParameters], and [StyleParameters].
///
/// Obtain instances of derived classes through the [ContentStoreItem.contentParameters] getter.
///
/// {@category Content}
abstract class ContentParameters {}

/// Road map [ContentStoreItem] details. This class provides detailed information specific to road map content.
///
/// {@category Content}
class RoadMapParameters extends ContentParameters {
  RoadMapParameters({
    required this.copyright,
    required this.mapDataProvider,
    required this.releaseDate,
    required this.defaultName,
  });

  @internal
  factory RoadMapParameters.fromParameters(List<GemParameter> params) {
    T? findValue<T>(String key) {
      for (final GemParameter param in params) {
        if (param.key == key) {
          return param.value as T?;
        }
      }
      return null;
    }

    DateTime? parseDateTime(String? dateTimeString) {
      if (dateTimeString == null) {
        return null;
      }

      try {
        final List<String> parts = dateTimeString.split('.');
        if (parts.length == 3) {
          final int day = int.parse(parts[0]);
          final int month = int.parse(parts[1]);
          final int year = int.parse(parts[2]);
          return DateTime(year, month, day);
        }
      } catch (e) {
        throw InvalidParameterFormat('Release date');
      }
      return null;
    }

    return RoadMapParameters(
      copyright: findValue<String>('Copyright'),
      mapDataProvider: findValue<String>('MapData provider'),
      releaseDate: parseDateTime(findValue<String?>('Release date')),
      defaultName: findValue<String>('Default name'),
    );
  }
  // Copyright holder
  final String? copyright;
  // Map data provider
  final String? mapDataProvider;
  // Release date
  final DateTime? releaseDate;
  // Default name
  final String? defaultName;
}

/// Voice [ContentStoreItem] details. This class provides detailed information specific to voice content.
///
/// {@category Content}
class VoiceParameters extends ContentParameters {
  VoiceParameters({
    required this.language,
    required this.gender,
    required this.type,
    required this.nativeLanguage,
  });

  @internal
  factory VoiceParameters.fromParameters(List<GemParameter> params) {
    T? findValue<T>(String key) {
      for (final GemParameter param in params) {
        if (param.key == key) {
          return param.value as T?;
        }
      }
      return null;
    }

    VoiceType? parseVoiceType(String? typeString) {
      if (typeString == null) {
        return null;
      }
      switch (typeString.toLowerCase()) {
        case 'human':
          return VoiceType.human;
        case 'computer':
          return VoiceType.computer;
        default:
          throw InvalidParameterFormat('type');
      }
    }

    return VoiceParameters(
      language: findValue<String?>('language'),
      gender: findValue<String?>('gender'),
      type: parseVoiceType(findValue<String?>('type')),
      nativeLanguage: findValue<String?>('native_language'),
    );
  }

  // Language of the voice
  final String? language;
  // Gender of the voice
  final String? gender;
  // Type of the voice
  final VoiceType? type;
  // Native language of the voice
  final String? nativeLanguage;
}

/// Style [ContentStoreItem] details. This class provides detailed information specific to style content.
///
/// {@category Content}
class StyleParameters extends ContentParameters {
  StyleParameters({required this.backgroundColor, required this.purposes});

  @internal
  factory StyleParameters.fromParameters(List<GemParameter> params) {
    T? findValue<T>(String key) {
      for (final GemParameter param in params) {
        if (param.key == key) {
          if (param.value is! T) {
            return null;
          }
          return param.value as T?;
        }
      }
      return null;
    }

    Color parseColorInt(int colorValue) {
      try {
        return Color(colorValue);
      } catch (e) {
        throw InvalidParameterFormat('Background-Color');
      }
    }

    Color parseColorString(String? colorValue) {
      if (colorValue == null) {
        return const Color(0xFFFFFFFF);
      }
      try {
        return Color(int.parse(colorValue));
      } catch (e) {
        throw InvalidParameterFormat('Background-Color');
      }
    }

    final int? colorInt = findValue<int>('Background-Color');
    final String? colorString = findValue<String>('Background-Color');

    final Color? backgroundColor = colorInt != null
        ? parseColorInt(colorInt)
        : (colorString != null ? parseColorString(colorString) : null);

    return StyleParameters(
      backgroundColor: backgroundColor,
      purposes: findValue<String?>('purposes'),
    );
  }
  // Style background color
  final Color? backgroundColor;

  bool get isDark => backgroundColor!.computeLuminance() < 0.5;

  // Style purposes (elevation, satelight, etc.)
  final String? purposes;
}
