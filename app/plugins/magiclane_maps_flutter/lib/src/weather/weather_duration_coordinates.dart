// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Coordinates with time offset for weather forecast requests.
///
/// Combines geographic coordinates with a duration offset to specify
/// when in the future the weather forecast is requested.
///
/// ## Also see:
///
/// - [WeatherService.getForecast] — Retrieves weather forecast for specified coordinates and durations.
///
/// {@category Weather}
class WeatherDurationCoordinates {
  /// Creates a [WeatherDurationCoordinates] instance.
  ///
  /// ## Parameters
  ///
  /// - [coordinates]: Geographic location for the forecast.
  /// - [duration]: Time offset into the future from the current time.
  WeatherDurationCoordinates({
    required this.coordinates,
    required this.duration,
  });

  /// Geographic coordinates for the forecast location.
  ///
  /// ## Returns
  ///
  /// - [Coordinates]: The location where weather forecast is requested.
  final Coordinates coordinates;

  /// Time offset into the future for the forecast.
  ///
  /// ## Returns
  ///
  /// - [Duration]: Time delay between the current time and the requested forecast time.
  final Duration duration;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['coords'] = coordinates;
    // Internally uses the same structure as TimeDistanceCoordinate.toJson()
    json['distance'] = 0;
    json['stamp'] = duration.inSeconds;
    return json;
  }
}
