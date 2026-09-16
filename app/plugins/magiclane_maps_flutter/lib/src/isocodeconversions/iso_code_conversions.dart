// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Represents ISO code variants used by the SDK.
///
/// Use these values to indicate whether a code is the two-letter or three-letter
/// ISO variant. Typical usage is converting between ISO-2 and ISO-3 forms for
/// countries and languages.
///
/// ## See also:
///
/// - [ISOCodeConversions] for helper methods that convert and inspect codes.
///
/// {@category Iso Code Conversions}
enum ISOCodeType {
  /// Represents an invalid or unknown ISO code.
  invalid,

  /// Two-letter ISO variant (ISO-2).
  iso_2,

  /// Three-letter ISO variant (ISO-3).
  iso_3,
}

/// @nodoc
extension ISOCodeTypeExtension on ISOCodeType {
  int get id {
    switch (this) {
      case ISOCodeType.invalid:
        return -1;
      case ISOCodeType.iso_2:
        return 0;
      case ISOCodeType.iso_3:
        return 1;
    }
  }

  static ISOCodeType fromId(final int id) {
    switch (id) {
      case -1:
        return ISOCodeType.invalid;
      case 0:
        return ISOCodeType.iso_2;
      case 1:
        return ISOCodeType.iso_3;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Utility methods for converting and inspecting ISO country and language codes.
///
/// This class provides static helpers to convert between two-letter and
/// three-letter ISO representations (ISO-2 <-> ISO-3) for both countries and
/// languages, and to detect which variant a given code represents.
///
/// ## See also:
///
/// - [ISOCodeType] - Enum representing the ISO code variants.
///
/// {@category Iso Code Conversions}
abstract class ISOCodeConversions {
  /// Converts a **country** ISO code between ISO-2 and ISO-3 formats.
  ///
  /// Converts the provided country [code] to the requested [type]. The input
  /// may be either a two-letter or three-letter code; the method returns the
  /// matching value in the requested format. If the input is not recognized the
  /// result will follow the SDK's standard behavior for unknown codes (for
  /// example an empty string or an unmodified value).
  ///
  /// ## Parameters
  ///
  /// - [code]: The country ISO code to convert. Can be in ISO-2 or ISO-3 form.
  /// - [type]: The target [ISOCodeType] for the converted code.
  ///
  /// ## Returns
  ///
  /// - A [String] containing the converted country ISO code.
  ///
  /// ## Also see:
  ///
  /// - [convertLanguageIso] - For converting language ISO codes.
  static String convertCountryIso(String code, ISOCodeType type) {
    final OperationResult resultString = staticMethod(
      'ISOCodeConversions',
      'convertCountryIso',
      args: <String, dynamic>{'code': code, 'type': type.id},
    );

    final String result = resultString['result'];

    return result;
  }

  /// Converts a **language** ISO code between ISO-2 and ISO-3 formats.
  ///
  /// Converts the provided language [code] to the requested [type]. The
  /// method supports common language code conversions (for example `hu` <->
  /// `hun`).
  ///
  /// ## Parameters
  ///
  /// - [code]: The language ISO code to convert. Can be ISO-2 or ISO-3.
  /// - [type]: The target [ISOCodeType] for the converted code.
  ///
  /// ## Returns
  ///
  /// - A [String] containing the converted language ISO code.
  ///
  /// ## Also see:
  ///
  /// - [convertCountryIso] - for converting country ISO codes.
  static String convertLanguageIso(String code, ISOCodeType type) {
    final OperationResult resultString = staticMethod(
      'ISOCodeConversions',
      'convertLanguageIso',
      args: <String, dynamic>{'code': code, 'type': type.id},
    );

    final String result = resultString['result'];

    return result;
  }

  /// Determines the ISO code variant of the supplied code.
  ///
  /// Analyzes the provided [code] and returns the corresponding [ISOCodeType]
  /// value: [ISOCodeType.iso_2], [ISOCodeType.iso_3], or
  /// [ISOCodeType.invalid] when the code does not match a recognized format.
  ///
  /// ## Parameters
  ///
  /// - [code]: The ISO code to inspect.
  ///
  /// ## Returns
  ///
  /// - The detected [ISOCodeType].
  static ISOCodeType getType(String code) {
    final OperationResult resultString = staticMethod(
      'ISOCodeConversions',
      'getType',
      args: code,
    );

    return ISOCodeTypeExtension.fromId(resultString['result']);
  }
}
