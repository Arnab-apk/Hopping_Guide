// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Predefined string constants for weather parameter types.
///
/// Provides standard identifiers for [Parameter.type] and [Conditions.type].
/// Not all parameters are applicable to every forecast type.
///
/// {@category Weather}
abstract class PredefinedParameterTypeValues {
  /// Air quality index parameter.
  ///
  /// ## Returns
  ///
  /// - String: 'AirQuality'
  ///
  /// ## Example
  ///
  /// - [Parameter.value] = 8
  /// - [Parameter.unit] = ''
  static const String airQuality = 'AirQuality';

  /// Dew point temperature parameter.
  ///
  /// ## Returns
  ///
  /// - String: 'DewPoint'
  ///
  /// ## Example
  ///
  /// - [Parameter.value] = 10
  /// - [Parameter.unit] = '°C'
  static const String dewPoint = 'DewPoint';

  /// Apparent temperature parameter.
  ///
  /// ## Returns
  ///
  /// - String: 'FeelsLike'
  ///
  /// ## Example
  ///
  /// - [Parameter.value] = 10
  /// - [Parameter.unit] = '°C'
  static const String feelsLike = 'FeelsLike';

  /// Relative humidity parameter.
  ///
  /// ## Returns
  ///
  /// - String: 'Humidity'
  ///
  /// ## Example
  ///
  /// - [Parameter.value] = 50
  /// - [Parameter.unit] = '%'
  static const String humidity = 'Humidity';

  /// Atmospheric pressure parameter.
  ///
  /// ## Returns
  ///
  /// - String: 'Pressure'
  ///
  /// ## Example
  ///
  /// - [Parameter.value] = 51010
  /// - [Parameter.unit] = 'mb'
  static const String pressure = 'Pressure';

  /// Sunrise time parameter.
  ///
  /// ## Returns
  ///
  /// - String: 'Sunrise'
  ///
  /// ## Example
  ///
  /// - [Parameter.value] = 1699027963 (UNIX timestamp - seconds since 1 Jan 1970 UTC)
  /// - [Parameter.unit] = ''
  static const String sunRise = 'Sunrise';

  /// Sunset time parameter.
  ///
  /// ## Returns
  ///
  /// - String: 'Sunset'
  ///
  /// ## Example
  ///
  /// - [Parameter.value] = 1699027963 (UNIX timestamp - seconds since 1 Jan 1970 UTC)
  /// - [Parameter.unit] = ''
  static const String sunSet = 'Sunset';

  /// Current temperature parameter.
  ///
  /// ## Returns
  ///
  /// - String: 'Temperature'
  ///
  /// ## Example
  ///
  /// - [Parameter.value] = 14
  /// - [Parameter.unit] = '°C'
  static const String temperature = 'Temperature';

  /// UV radiation index parameter.
  ///
  /// ## Returns
  ///
  /// - String: 'UV'
  ///
  /// ## Example
  ///
  /// - [Parameter.value] = 8
  /// - [Parameter.unit] = ''
  static const String uv = 'UV';

  /// Visibility distance parameter.
  ///
  /// ## Returns
  ///
  /// - String: 'Visibility'
  ///
  /// ## Example
  ///
  /// - [Parameter.value] = 10
  /// - [Parameter.unit] = 'km'
  static const String visibility = 'Visibility';

  /// Wind direction parameter.
  ///
  /// ## Returns
  ///
  /// - String: 'WindDirection'
  ///
  /// ## Example
  ///
  /// - [Parameter.value] = 0 (0 = North, 90 = East, 180 = South, 270 = West)
  /// - [Parameter.unit] = '°'
  static const String windDirection = 'WindDirection';

  /// Wind speed parameter.
  ///
  /// ## Returns
  ///
  /// - String: 'WindSpeed'
  ///
  /// ## Example
  ///
  /// - [Parameter.value] = 15
  /// - [Parameter.unit] = 'km/h'
  static const String windSpeed = 'WindSpeed';

  /// Low temperature parameter.
  ///
  /// ## Returns
  ///
  /// - String: 'TemperatureLow'
  ///
  /// ## Example
  ///
  /// - [Parameter.value] = -5
  /// - [Parameter.unit] = '°C'
  static const String temperatureLow = 'TemperatureLow';

  /// High temperature parameter.
  ///
  /// ## Returns
  ///
  /// - String: 'TemperatureHigh'
  ///
  /// ## Example
  ///
  /// - [Parameter.value] = 25
  /// - [Parameter.unit] = '°C'
  static const String temperatureHigh = 'TemperatureHigh';
}
