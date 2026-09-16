// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:flutter/foundation.dart';

/// Flexible key/value storage used for landmark auxiliary metadata.
///
/// The [ExtraInfo] class parses and exposes simple key/value pairs. Changes made to the
/// returned object are not automatically persisted on a [Landmark]; assign the modified
/// instance back to `landmark.extraInfo` to update the landmark.
///
/// {@category Landmarks}
/// {@category Snapshot Types}
class ExtraInfo {
  ExtraInfo() : _data = <dynamic, dynamic>{};
  ExtraInfo.fromList(final List<dynamic> input) : _data = _parseInput(input);
  final Map<dynamic, dynamic> _data;
  static Map<dynamic, dynamic> _parseInput(final List<dynamic> input) {
    final Map<dynamic, dynamic> parsedData = <dynamic, dynamic>{};
    int index = 0;

    for (final dynamic line in input) {
      final dynamic parts = line.split('=');
      if (parts.length == 2) {
        final dynamic key = parts[0].trim();
        final dynamic value = parts[1].trim();
        parsedData[key] = value;
      } else if (parts.length == 1) {
        final dynamic value = parts[0].trim();
        final String key = index.toString();
        parsedData[key] = value;
        index++;
      }
    }

    return parsedData;
  }

  /// Retrieves the value associated with [key], parsed to an appropriate type.
  ///
  /// ## Parameters
  ///
  /// - [key]: The key to lookup (integer or string).
  ///
  /// ## Returns
  ///
  /// - `null` if the key does not exist or the value is null.
  /// - `bool` when the stored string is "true" or "false".
  /// - `int` when the value can be parsed as an integer.
  /// - `double` when the value can be parsed as a floating point number.
  /// - `String` when the value cannot be parsed to another primitive type.
  dynamic getByKey(final dynamic key) {
    if (!_data.containsKey(key)) {
      return null;
    }
    final dynamic value = _data[key];
    if (value != null) {
      if (value == 'true' || value == 'false') {
        return value == 'true';
      }
      try {
        return int.parse(value);
      } catch (e) {
        // Not an int, try parsing as double
        try {
          return double.parse(value);
        } catch (e) {
          // Not a double, return the original string value
          return value;
        }
      }
    }
    return null;
  }

  /// Serializes the extra info into the SDK input format (list of strings).
  ///
  /// Integer keys are serialized as single values; non-integer keys are serialized as
  /// `key = value` pairs.
  ///
  /// ## Returns
  ///
  /// - [List<String>]: The serialized representation suitable for passing to SDK methods.
  List<String> toInputFormat() {
    final List<String> output = <String>[];
    _data.forEach((final dynamic key, final dynamic value) {
      if (key is int) {
        // If the key is an integer, it means the original input was a single value
        output.add(value);
      } else {
        // If the key is not an integer, it means the original input was a key-value pair
        output.add('$key = $value');
      }
    });
    return output;
  }

  /// Adds or updates a key/value entry in this extra info object.
  ///
  /// ## Parameters
  ///
  /// - [key]: The key to set (integer or string).
  /// - [value]: The value to assign.
  void add(final dynamic key, final dynamic value) {
    _data[key] = value;
  }

  /// Removes an entry by key from the extra info map.
  ///
  /// ## Parameters
  ///
  /// - [key]: The key to remove.
  void remove(final dynamic key) {
    _data.remove(key);
  }

  @override
  bool operator ==(covariant final ExtraInfo other) {
    if (identical(this, other)) {
      return true;
    }

    return mapEquals(_data, other._data);
  }

  @override
  int get hashCode {
    int hash = 0;
    for (final MapEntry<dynamic, dynamic> entry in _data.entries) {
      final dynamic value = entry.value;
      final dynamic key = entry.key;
      hash = hash ^ value.hashCode ^ key.hashCode;
    }

    return hash;
  }
}

/// Predefined keys used in the landmark [ExtraInfo] map.
///
/// These string constants are used to store and retrieve well-known auxiliary values
/// (for example contour boxes, wiki information or population) from a landmark's
/// [ExtraInfo].
///
/// {@category Landmarks}
abstract class PredefinedExtraInfoKey {
  /// Full contour landmark bounding box
  static const String gmContourBox = 'gm_display_box';

  /// Landmark relevant contour partial bounding box
  static const String gmRelevantContourBox = 'gm_display_box_relevant';

  /// Search result link position side
  static const String gmSearchResultSidePosition = 'gm_search_result_side';

  /// Search result distance relative to search position reference
  static const String gmSearchResultDistance = 'gm_search_result_dist';

  /// Search result detailed type
  static const String gmSearchResultType = 'gm_search_result_type';

  /// Wiki info
  static const String wikiInfo = 'gm_wiki_info';

  /// Wiki native name
  static const String gmWikiNativeName = 'gm_wiki_native_name';

  /// Wiki English name
  static const String gmWikiEngName = 'gm_wiki_eng_name';

  /// Population
  static const String gmPopulation = 'gm_population';

  /// External provider
  static const String gmExtProvider = 'gm_ext_provider';
}
