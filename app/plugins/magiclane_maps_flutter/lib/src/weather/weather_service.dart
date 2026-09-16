// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/weather.dart';

/// Provides methods for retrieving weather forecasts.
///
/// This service enables fetching current weather conditions, hourly forecasts,
/// and daily forecasts for specified geographic locations.
///
/// {@category Weather}
abstract class WeatherService {
  /// Retrieves current weather for specified coordinates.
  ///
  /// ## Parameters
  ///
  /// - [coords]: List of coordinates for which to fetch current weather.
  /// - [onComplete]: Callback invoked when the operation completes. The callback is called with:
  ///   - [GemError.success] and non-empty [LocationForecast] list on success.
  ///   - [GemError.invalidInput] and empty list if the coordinates list is empty.
  ///   - [GemError.resourceMissing] and empty list if internal engine resource is missing.
  ///   - [GemError.outOfRange] and empty list if number of coordinates exceeds [maxCoordinatesPerRequest].
  ///   - Other [GemError] values and empty list on other errors.
  ///
  /// ## Returns
  ///
  /// - [ProgressListener]: Progress listener for tracking the operation.
  ///
  /// ## Also see:
  ///
  /// - [maxCoordinatesPerRequest] — Maximum number of coordinates allowed per request.
  static ProgressListener getCurrent({
    required final List<Coordinates> coords,
    final void Function(
      GemError error,
      List<LocationForecast> locationForecasts,
    )?
    onComplete,
  }) {
    final LocationForecastList result = LocationForecastList();
    final EventDrivenProgressListener listener = EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    listener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
      if (err == 0) {
        onComplete?.call(GemErrorExtension.fromCode(err), result.json);

        result.dispose();
      } else {
        onComplete?.call(GemErrorExtension.fromCode(err), <LocationForecast>[]);
      }
    });
    final OperationResult resultOperation = staticMethod(
      'Weather',
      'getCurrent',
      args: <String, dynamic>{
        'coords': coords,
        'result': result.id,
        'listener': listener.id,
      },
    );
    final GemError errCode = GemErrorExtension.fromCode(
      resultOperation['result'],
    );
    if (errCode != GemError.success) {
      onComplete?.call(errCode, <LocationForecast>[]);
    }
    return listener;
  }

  /// Retrieves weather forecast for coordinates at specified future times.
  ///
  /// The duration in each [WeatherDurationCoordinates] specifies the time offset
  /// into the future for which the forecast is requested.
  ///
  /// ## Parameters
  ///
  /// - [coords]: List of coordinates with duration offsets for forecast requests.
  /// - [onComplete]: Callback invoked when the operation completes. The callback is called with:
  ///   - [GemError.success] and non-empty [LocationForecast] list on success.
  ///   - [GemError.invalidInput] and empty list if the coordinates list is empty.
  ///   - [GemError.resourceMissing] and empty list if internal engine resource is missing.
  ///   - [GemError.outOfRange] and empty list if number of coordinates exceeds [maxCoordinatesPerRequest].
  ///   - Other [GemError] values and empty list on other errors.
  ///
  /// ## Returns
  ///
  /// - [ProgressListener]: Progress listener for tracking the operation.
  ///
  /// ## Also see:
  ///
  /// - [maxCoordinatesPerRequest] — Maximum number of coordinates allowed per request.
  static ProgressListener getForecast({
    required final List<WeatherDurationCoordinates> coords,
    void Function(GemError, List<LocationForecast> locationForecasts)?
    onComplete,
  }) {
    for (final WeatherDurationCoordinates coord in coords) {
      if (coord.coordinates.latitude.abs() > 90 ||
          coord.coordinates.longitude.abs() > 180) {
        onComplete?.call(GemError.invalidInput, <LocationForecast>[]);

        return EventDrivenProgressListener();
      }
    }

    final LocationForecastList result = LocationForecastList();
    final EventDrivenProgressListener listener = EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    listener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
      if (err == 0) {
        onComplete?.call(GemErrorExtension.fromCode(err), result.json);
        result.dispose();
      } else {
        onComplete?.call(GemErrorExtension.fromCode(err), <LocationForecast>[]);
      }
    });
    final OperationResult resultString = staticMethod(
      'Weather',
      'getForecast',
      args: <String, dynamic>{
        'coords': coords,
        'result': result.id,
        'listener': listener.id,
      },
    );
    final GemError errCode = GemErrorExtension.fromCode(resultString['result']);
    if (errCode != GemError.success) {
      onComplete?.call(errCode, <LocationForecast>[]);
    }
    return listener;
  }

  /// Retrieves hourly weather forecast for specified coordinates.
  ///
  /// ## Parameters
  ///
  /// - [hours]: Number of hours for which forecast is requested (must be ≤ [maxHoursForHourlyForecast]).
  /// - [coords]: List of coordinates for which to fetch hourly forecast.
  /// - [onComplete]: Callback invoked when the operation completes. The callback is called with:
  ///   - [GemError.success] and non-empty [LocationForecast] list on success.
  ///   - [GemError.invalidInput] and empty list if coordinates list is empty or hours is negative.
  ///   - [GemError.resourceMissing] and empty list if internal engine resource is missing.
  ///   - [GemError.outOfRange] and empty list if number of coordinates or hours exceeds maximum allowed.
  ///   - Other [GemError] values and empty list on other errors.
  ///
  /// ## Returns
  ///
  /// - [ProgressListener]: Progress listener for tracking the operation.
  ///
  /// ## Also see:
  ///
  /// - [maxHoursForHourlyForecast] — Maximum hours allowed per hourly forecast request.
  static ProgressListener getHourlyForecast({
    required final int hours,
    required final List<Coordinates> coords,
    final void Function(
      GemError error,
      List<LocationForecast> locationForecasts,
    )?
    onComplete,
  }) {
    final LocationForecastList result = LocationForecastList();
    final EventDrivenProgressListener listener = EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    listener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
      if (err == 0) {
        onComplete?.call(GemErrorExtension.fromCode(err), result.json);

        result.dispose();
      } else {
        onComplete?.call(GemErrorExtension.fromCode(err), <LocationForecast>[]);
      }
    });
    final OperationResult resultString = staticMethod(
      'Weather',
      'getHourlyForecast',
      args: <String, dynamic>{
        'hours': hours,
        'coords': coords,
        'result': result.id,
        'listener': listener.id,
      },
    );
    final GemError errCode = GemErrorExtension.fromCode(resultString['result']);
    if (errCode != GemError.success) {
      onComplete?.call(errCode, <LocationForecast>[]);
    }
    return listener;
  }

  /// Retrieves daily weather forecast for specified coordinates.
  ///
  /// ## Parameters
  ///
  /// - [days]: Number of days for which forecast is requested (must be ≤ [maxDayForDailyForecast]).
  /// - [coords]: List of coordinates for which to fetch daily forecast.
  /// - [onComplete]: Callback invoked when the operation completes. The callback is called with:
  ///   - [GemError.success] and non-empty [LocationForecast] list on success.
  ///   - [GemError.invalidInput] and empty list if coordinates list is empty or days is negative.
  ///   - [GemError.resourceMissing] and empty list if internal engine resource is missing.
  ///   - [GemError.outOfRange] and empty list if number of coordinates or days exceeds maximum allowed.
  ///   - Other [GemError] values and empty list on other errors.
  ///
  /// ## Returns
  ///
  /// - [ProgressListener]: Progress listener for tracking the operation.
  ///
  /// ## Also see:
  ///
  /// - [maxDayForDailyForecast] — Maximum days allowed per daily forecast request.
  static ProgressListener getDailyForecast({
    required final int days,
    required final List<Coordinates> coords,
    final void Function(
      GemError error,
      List<LocationForecast> locationForecasts,
    )?
    onComplete,
  }) {
    final LocationForecastList result = LocationForecastList();
    final EventDrivenProgressListener listener = EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    listener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
      if (err == 0) {
        onComplete?.call(GemErrorExtension.fromCode(err), result.json);

        result.dispose();
      } else {
        onComplete?.call(GemErrorExtension.fromCode(err), <LocationForecast>[]);
      }
    });
    final OperationResult resultString = staticMethod(
      'Weather',
      'getDailyForecast',
      args: <String, dynamic>{
        'days': days,
        'coords': coords,
        'result': result.id,
        'listener': listener.id,
      },
    );
    final GemError errCode = GemErrorExtension.fromCode(resultString['result']);
    if (errCode != GemError.success) {
      onComplete?.call(errCode, <LocationForecast>[]);
    }
    return listener;
  }

  /// Cancels an ongoing asynchronous weather operation.
  ///
  /// ## Parameters
  ///
  /// - [listener]: Progress listener associated with the operation to cancel.
  static void cancel(final ProgressListener listener) {
    staticMethod(
      'Weather',
      'cancel',
      args: <String, dynamic>{'listener': listener.id},
    );
  }

  /// Gets the maximum number of coordinates allowed per request.
  ///
  /// ## Returns
  ///
  /// - int: Maximum number of coordinates for a single weather request.
  static int get maxCoordinatesPerRequest {
    final OperationResult retString = staticMethod(
      'Weather',
      'getMaxCoordinatesPerRequest',
    );
    return retString['result'];
  }

  /// Gets the maximum number of days allowed per daily forecast request.
  ///
  /// ## Returns
  ///
  /// - int: Maximum number of days for [getDailyForecast].
  static int get maxDayForDailyForecast {
    final OperationResult retString = staticMethod(
      'Weather',
      'getMaxDayForDailyForecast',
    );

    return retString['result'];
  }

  /// Gets the maximum number of hours allowed per hourly forecast request.
  ///
  /// ## Returns
  ///
  /// - int: Maximum number of hours for [getHourlyForecast].
  static int get maxHoursForHourlyForecast {
    final OperationResult retString = staticMethod(
      'Weather',
      'getMaxHoursForHourlyForecast',
    );
    return retString['result'];
  }

  /// Gets transfer statistics for weather service operations.
  ///
  /// Returns a [TransferStatistics] object containing counters and metrics
  /// about network usage performed by the traffic service. This information
  /// can be used for diagnostics or to display usage to end users.
  ///
  /// ## Returns
  ///
  /// - [TransferStatistics]: Statistics about data transferred during weather operations.
  static TransferStatistics get transferStatistics {
    final OperationResult resultString = staticMethod(
      'Weather',
      'getTransferStatistics',
    );

    return TransferStatistics.init(resultString['result']);
  }
}
