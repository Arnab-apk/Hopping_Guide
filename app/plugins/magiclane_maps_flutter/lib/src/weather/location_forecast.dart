// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:flutter/foundation.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/weather/conditions.dart';

/// Weather forecast for a specific geographic location.
///
/// Contains the forecast update time, coordinates, and a list of conditions
/// representing weather data for the location.
///
/// Is obtained via [WeatherService] methods.
///
/// {@category Weather}
class LocationForecast {
  /// Creates a [LocationForecast] instance.
  ///
  /// The API users typically do not create [LocationForecast] instances directly.
  ///
  /// ## Parameters
  ///
  /// - [updated]: UTC datetime when the forecast was last updated.
  /// - [coord]: Geographic coordinates for this forecast.
  /// - [forecast]: List of weather conditions for the location.
  LocationForecast({
    required this.updated,
    required this.coord,
    required this.forecast,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory LocationForecast.fromJson(final Map<String, dynamic> json) {
    return LocationForecast(
      updated: DateTime.fromMillisecondsSinceEpoch(
        json['updated'],
        isUtc: true,
      ),
      coord: Coordinates.fromJson(json['coord']),
      forecast: (json['forecast'] as List<dynamic>)
          .map(
            (final dynamic categoryJson) => Conditions.fromJson(categoryJson),
          )
          .toList(),
    );
  }

  /// UTC datetime when the forecast was last updated.
  ///
  /// ## Returns
  ///
  /// - [DateTime]: Timestamp of the last forecast update.
  DateTime updated;

  /// Geographic coordinates for this forecast.
  ///
  /// ## Returns
  ///
  /// - [Coordinates]: Location where this forecast applies.
  Coordinates coord;

  /// Weather conditions for the forecast period.
  ///
  /// ## Returns
  ///
  /// - List<[Conditions]>: List of weather conditions over time.
  List<Conditions> forecast;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['updated'] = updated.millisecondsSinceEpoch;
    json['coord'] = coord;
    json['forecast'] = forecast;
    return json;
  }
}
