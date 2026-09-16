// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:typed_data';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Weather conditions for a specific timestamp.
///
/// Contains weather information including type, description, parameters,
/// and visual representation for a particular moment in time.
///
/// Get a list of [Conditions] via [LocationForecast.forecast].
///
/// {@category Weather}
class Conditions {
  /// Creates a [Conditions] instance.
  ///
  /// The API users typically do not create [Conditions] instances directly.
  ///
  /// ## Parameters
  ///
  /// - [type]: Condition type identifier (see [PredefinedParameterTypeValues]).
  /// - [stamp]: UTC datetime when the condition applies.
  /// - [description]: Condition description translated to current SDK language.
  /// - [daylight]: Daylight state for this condition.
  /// - [params]: List of weather parameters for this condition.
  /// - [img]: Image representation of the condition.
  Conditions({
    required this.type,
    required this.stamp,
    required this.description,
    required this.daylight,
    required this.params,
    required this.img,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory Conditions.fromJson(final Map<String, dynamic> json) {
    return Conditions(
      type: json['type'],
      stamp: DateTime.fromMillisecondsSinceEpoch(json['stamp'], isUtc: true),
      description: json['description'],
      daylight: DaylightExtension.fromId(json['daylight']),
      params: (json['params'] as List<dynamic>)
          .map((final dynamic categoryJson) => Parameter.fromJson(categoryJson))
          .toList(),
      img: Img.init(json['img']),
    );
  }

  /// Condition type identifier.
  ///
  /// See [PredefinedParameterTypeValues] for common values.
  ///
  /// ## Returns
  ///
  /// - String: Type identifier for this condition.
  String type;

  /// UTC datetime when the condition applies.
  ///
  /// ## Returns
  ///
  /// - [DateTime]: Timestamp for this weather condition.
  DateTime stamp;

  /// Image representation as raw bytes.
  ///
  /// ## Returns
  ///
  /// - [Uint8List]: Byte array containing the condition image data.
  Uint8List get image => img.getRenderableImageBytes()!;

  /// Condition description translated to current SDK language.
  ///
  /// ## Returns
  ///
  /// - String: Localized description of the weather condition.
  String description;

  /// Daylight state for this condition.
  ///
  /// ## Returns
  ///
  /// - [Daylight]: Whether the condition occurs during day, night, or unknown.
  Daylight daylight;

  /// Weather parameters for this condition.
  ///
  /// ## Returns
  ///
  /// - List<[Parameter]>: List of measurements like temperature, humidity, etc.
  List<Parameter> params;

  /// Image object for the condition.
  ///
  /// ## Returns
  ///
  /// - [Img]: Image representation of the weather condition.
  Img img;
}

/// Weather parameter data.
///
/// Contains weather-related measurements such as temperature, humidity, wind speed, etc.
/// Provided by [Conditions.params] to represent specific weather attributes.
///
/// {@category Weather}
class Parameter {
  /// Creates a [Parameter] instance.
  ///
  /// The API users typically do not create [Parameter] instances directly.
  ///
  /// ## Parameters
  ///
  /// - [type]: Parameter type identifier (see [PredefinedParameterTypeValues]).
  /// - [value]: Numeric value of the parameter.
  /// - [name]: Parameter name translated to current SDK language.
  /// - [unit]: Unit of measurement for the parameter value.
  Parameter({
    required this.type,
    required this.value,
    required this.name,
    required this.unit,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory Parameter.fromJson(final Map<String, dynamic> json) {
    return Parameter(
      type: json['type'],
      value: json['value'],
      name: json['name'],
      unit: json['unit'],
    );
  }

  /// Parameter type identifier.
  ///
  /// See [PredefinedParameterTypeValues] for common values.
  ///
  /// ## Returns
  ///
  /// - String: Type identifier for this parameter.
  String type;

  /// Numeric value of the parameter.
  ///
  /// ## Returns
  ///
  /// - double: The parameter measurement value.
  double value;

  /// Parameter name translated to current SDK language.
  ///
  /// ## Returns
  ///
  /// - String: Localized name of the parameter.
  String name;

  /// Unit of measurement for the parameter value.
  ///
  /// ## Returns
  ///
  /// - String: The measurement unit (e.g., "°C", "%", "km/h").
  String unit;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is Parameter &&
        other.type == type &&
        other.value == value &&
        other.name == name &&
        other.unit == unit;
  }

  @override
  int get hashCode {
    return Object.hash(type, value, name, unit);
  }
}

/// Represents the state of daylight conditions.
///
/// {@category Weather}
enum Daylight {
  /// Unknown daylight state.
  notAvailable,

  /// Daytime condition.
  day,

  /// Nighttime condition.
  night,
}

/// @nodoc
extension DaylightExtension on Daylight {
  int get id {
    switch (this) {
      case Daylight.notAvailable:
        return 0;
      case Daylight.day:
        return 1;
      case Daylight.night:
        return 2;
    }
  }

  static Daylight fromId(final int id) {
    switch (id) {
      case 0:
        return Daylight.notAvailable;
      case 1:
        return Daylight.day;
      case 2:
        return Daylight.night;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
