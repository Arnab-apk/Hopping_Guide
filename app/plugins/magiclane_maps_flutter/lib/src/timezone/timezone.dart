// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Enumerates the type of response from the timezone plugin.
///
/// Status for timezone lookup results.
///
/// Indicates the outcome of a timezone lookup performed by the
/// [TimezoneService]. The status focuses on the quality and validity of the
/// timezone data (for example: whether the input was malformed or the service
/// had to fall back to obsolete data).
///
/// The values cover successful lookups, input errors and situations where the
/// service had to use stale/obsolete data.
///
/// ## See also:
///
/// - [TimezoneResult] — The result object that exposes the status and offsets.
/// - [TimezoneService] — Methods that return a [TimezoneResult].
///
/// {@category Timezone}
enum TimeZoneStatus {
  /// The lookup succeeded and returned up-to-date timezone information.
  success,

  /// The provided geographic coordinates were invalid or out of range.
  invalidCoordinate,

  /// The provided timezone identifier was malformed or not recognized.
  wrongTimezoneId,

  /// The provided timestamp was invalid or could not be parsed.
  wrongTimestamp,

  /// No timezone could be found for the given input.
  timezoneNotFound,

  /// The lookup succeeded, but the service had to use obsolete (outdated)
  /// timezone data. This commonly happens when the offline dataset is not
  /// up-to-date; update the SDK or the offline time zone data when possible.
  successUsingObsoleteData,
}

/// @nodoc
extension TimeZoneStatusExtension on TimeZoneStatus {
  int get id {
    switch (this) {
      case TimeZoneStatus.success:
        return 0;
      case TimeZoneStatus.invalidCoordinate:
        return 1;
      case TimeZoneStatus.wrongTimezoneId:
        return 2;
      case TimeZoneStatus.wrongTimestamp:
        return 3;
      case TimeZoneStatus.timezoneNotFound:
        return 4;
      case TimeZoneStatus.successUsingObsoleteData:
        return 5;
    }
  }

  static TimeZoneStatus fromId(final int id) {
    switch (id) {
      case 0:
        return TimeZoneStatus.success;
      case 1:
        return TimeZoneStatus.invalidCoordinate;
      case 2:
        return TimeZoneStatus.wrongTimezoneId;
      case 3:
        return TimeZoneStatus.wrongTimestamp;
      case 4:
        return TimeZoneStatus.timezoneNotFound;
      case 5:
        return TimeZoneStatus.successUsingObsoleteData;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Result container for timezone lookup operations.
///
/// Holds detailed timezone information returned by [TimezoneService]
/// lookups. Do not construct this class directly; obtain instances using
/// the [TimezoneService] methods which return or populate a [TimezoneResult].
///
/// Important: the [localTime] value is returned as a UTC [DateTime] (that is,
/// `isUtc == true`) but represents the local time in the requested timezone
/// due to limitations of the Dart [DateTime] API.
///
/// {@category Timezone}
class TimezoneResult extends GemAutoreleaseObject {
  // ignore: unused_element
  TimezoneResult._() : super(-1);

  @internal
  TimezoneResult.init(super.pointerId);

  /// Daylight Saving Time (DST) offset for the resolved timezone.
  ///
  /// Returns [Duration.zero] when no DST is applicable for the requested
  /// timestamp and location.
  Duration get dstOffset {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TimezoneResult',
      'dstOffset',
    );
    return Duration(seconds: resultString['result']);
  }

  /// Get the offset including DST.
  ///
  /// Can be negative.
  Duration get offset {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TimezoneResult',
      'offset',
    );
    return Duration(seconds: resultString['result']);
  }

  /// Get the UTC offset without DST.
  ///
  /// Can be negative.
  Duration get utcOffset {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TimezoneResult',
      'utcOffset',
    );
    return Duration(seconds: resultString['result']);
  }

  /// Get the status of the response.
  TimeZoneStatus get status {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TimezoneResult',
      'status',
    );
    return TimeZoneStatusExtension.fromId(resultString['result']);
  }

  /// Get the ID of the timezone.
  ///
  /// It is in the format "Continent/City_Name".
  /// Examples: Europe/Paris, America/New_York, Europe/Moscow.
  String get timezoneId {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TimezoneResult',
      'timezoneId',
    );
    return resultString['result'];
  }

  /// Get the local time.
  ///
  /// The local time is returned as a UTC [DateTime] object but contains the local time at the requested location.
  DateTime get localTime {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TimezoneResult',
      'localTime',
    );
    return DateTime.fromMillisecondsSinceEpoch(
      resultString['result'],
      isUtc: true,
    );
  }

  @internal
  static TimezoneResult create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'TimezoneResult'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final TimezoneResult retVal = TimezoneResult.init(decodedVal['result']);
    return retVal;
  }
}

/// Timezone service helpers.
///
/// Use the static methods on this class to resolve timezone information for a
/// given geographic coordinate or a named IANA timezone identifier. The API
/// exposes both asynchronous (online) methods which query a remote service
/// for the most up-to-date information and synchronous (offline) methods that
/// use builtin timezone data.
///
/// Notes:
/// - Always pass the [time] parameter as a UTC [DateTime].
///   The service computes offsets for that instant in time.
/// - The synchronous (`*Sync`) methods are faster and work without network
///   access, but the offline timezone dataset may be outdated. When a sync
///   lookup succeeds but uses stale data, the returned [TimezoneResult.status]
///   will be [TimeZoneStatus.successUsingObsoleteData].
///
/// ## See also:
///
/// - [TimezoneResult] - The result object that exposes the status and offsets.
/// - [TimeZoneStatus] - Possible status values for timezone lookups.
/// - [ApiErrorService] — retrieve the last SDK error code when a method
///   returns `null` or fails to start.
///
/// {@category Timezone}
abstract class TimezoneService {
  /// Asynchronously retrieves timezone information for a coordinate and an UTC
  /// timestamp.
  ///
  /// Performs an online lookup and returns progress via a [ProgressListener].
  /// The supplied [onComplete] callback is invoked once the operation finishes.
  ///
  /// ## Parameters
  ///
  /// - [coords]: Geographic coordinates (latitude/longitude) to resolve.
  /// - [time]: Instant to resolve (must be provided as a UTC [DateTime]).
  /// - [onComplete]: Function called when the operation completes. The function is called with:
  ///   - [GemError.success] for `error` and a non-null [TimezoneResult] for `result` when the operation completed successfully.
  ///   - [GemError.internalAbort] for `error` and `null` for `result` when a parsing failure or server-side error occurred.
  ///
  /// ## Returns
  ///
  /// - A [ProgressListener] if the asynchronous operation was started; `null`
  ///   if the operation could not be started. When `null` the specific
  ///   failure can be inspected via [ApiErrorService.apiError].
  ///
  /// ## Example
  ///
  /// ```dart
  /// TimezoneService.getTimezoneInfoFromCoordinates(
  ///   coords: Coordinates.fromLatLong(55.626, 37.457),
  ///   time: DateTime.utc(2025, 7, 1, 6, 0),
  ///   onComplete: (err, result) {
  ///     if (err == GemError.success) {
  ///       print(result!.timezoneId);
  ///     } else {
  ///       print('Error: $err');
  ///     }
  ///   },
  /// );
  /// ```
  ///
  /// ## See also:
  ///
  /// - [TimezoneResult] - The result object that exposes the status and offsets.
  /// - [getTimezoneInfoFromCoordinatesSync] - Synchronous version of this method.
  static ProgressListener? getTimezoneInfoFromCoordinates({
    required final Coordinates coords,
    required final DateTime time,
    final void Function(GemError error, TimezoneResult? result)? onComplete,
  }) {
    final TimezoneResult result = TimezoneResult.create();
    final EventDrivenProgressListener listener = EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    listener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
      if (err == 0) {
        onComplete?.call(GemErrorExtension.fromCode(err), result);
      } else {
        onComplete?.call(GemErrorExtension.fromCode(err), null);
      }
    });
    final OperationResult resultString = staticMethod(
      'TimezoneService',
      'getTimezoneInfoCoords',
      args: <String, dynamic>{
        'timezoneResult': result.pointerId,
        'coords': coords,
        'time': time.millisecondsSinceEpoch,
        'progressListener': listener.id,
      },
    );
    final GemError errCode = GemErrorExtension.fromCode(resultString['result']);
    if (errCode != GemError.success) {
      onComplete?.call(errCode, null);
      return null;
    }
    return listener;
  }

  /// Asynchronously retrieves timezone information for an IANA timezone id and
  /// an UTC timestamp.
  ///
  /// ## Parameters
  ///
  /// - [timezoneId]: IANA timezone identifier in the form `Continent/City`
  ///   (examples: `Europe/Paris`, `America/New_York`).
  /// - [time]: Instant to resolve (must be provided as a UTC [DateTime]).
  /// - [onComplete]: Function called when the operation completes. The function is called with:
  ///   - [GemError.success] for `error` and a non-null [TimezoneResult] for `result` when the operation completed successfully.
  ///   - [GemError.internalAbort] for `error` and `null` for `result` when a parsing failure or server-side error occurred.
  ///
  /// ## Returns
  ///
  /// - A [ProgressListener] if the asynchronous operation was started; `null`
  ///   if the operation could not be started. When `null` the specific
  ///   failure can be inspected via [ApiErrorService.apiError].
  ///
  /// ## Example
  ///
  /// ```dart
  /// TimezoneService.getTimezoneInfoFromTimezoneId(
  ///   timezoneId: 'Europe/Moscow',
  ///   time: DateTime.utc(2025, 7, 1, 6, 0),
  ///   onComplete: (err, result) {
  ///     if (err == GemError.success) {
  ///       print(result!.timezoneId);
  ///     } else {
  ///       print('Error: $err');
  ///     }
  ///   },
  /// );
  /// ```
  ///
  /// ## See also:
  ///
  /// - [TimezoneResult] - The result object that exposes the status and offsets.
  /// - [getTimezoneInfoFromTimezoneIdSync] - Synchronous version of this method.
  static ProgressListener? getTimezoneInfoFromTimezoneId({
    required final String timezoneId,
    required final DateTime time,
    final void Function(GemError error, TimezoneResult? result)? onComplete,
  }) {
    final TimezoneResult result = TimezoneResult.create();
    final EventDrivenProgressListener listener = EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    listener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
      if (err == 0) {
        onComplete?.call(GemErrorExtension.fromCode(err), result);
      } else {
        onComplete?.call(GemErrorExtension.fromCode(err), null);
      }
    });
    final OperationResult resultString = staticMethod(
      'TimezoneService',
      'getTimezoneInfoTimezoneId',
      args: <String, dynamic>{
        'timezoneResult': result.pointerId,
        'timezoneId': timezoneId,
        'time': time.millisecondsSinceEpoch,
        'progressListener': listener.id,
      },
    );
    final GemError errCode = GemErrorExtension.fromCode(resultString['result']);
    if (errCode != GemError.success) {
      onComplete?.call(errCode, null);
      return null;
    }
    return listener;
  }

  /// Synchronously retrieves timezone information for a coordinate and an UTC
  /// timestamp using local/offline data.
  ///
  /// This lookup does not perform a network request. It is fast and suitable
  /// for offline scenarios but may return stale information. When the method
  /// returns `null` the specific error can be obtained immediately by calling
  /// [ApiErrorService.apiError].
  ///
  /// ## Parameters
  ///
  /// - [coords]: Geographic coordinates to resolve.
  /// - [time]: Instant to resolve (must be provided as a UTC [DateTime]).
  ///
  /// ## Returns
  ///
  /// - A [TimezoneResult] when successful, otherwise `null`.
  static TimezoneResult? getTimezoneInfoFromCoordinatesSync({
    required final Coordinates coords,
    required final DateTime time,
  }) {
    final TimezoneResult result = TimezoneResult.create();

    final OperationResult resultString = staticMethod(
      'TimezoneService',
      'getTimezoneInfoCoordsSync',
      args: <String, dynamic>{
        'timezoneResult': result.pointerId,
        'coords': coords,
        'time': time.millisecondsSinceEpoch,
      },
    );

    if (resultString['result'] != 0) {
      return null;
    }

    return result;
  }

  @Deprecated('Use getTimezoneInfoFromTimezoneIdSync instead')
  static TimezoneResult? getTimezoneInfoTimezoneIdSync({
    required final String timezoneId,
    required final DateTime time,
  }) {
    return getTimezoneInfoFromTimezoneIdSync(
      timezoneId: timezoneId,
      time: time,
    );
  }

  /// Synchronously retrieves timezone information for an IANA timezone id and
  /// an UTC timestamp using local/offline data.
  ///
  /// This lookup does not perform a network request. It is fast and suitable
  /// for offline scenarios but may return stale information. When the method
  /// returns `null` the specific error can be obtained immediately by calling
  /// [ApiErrorService.apiError].
  ///
  ///
  /// ## Parameters
  ///
  /// - [timezoneId]: IANA timezone identifier to resolve.
  /// - [time]: Instant to resolve (must be provided as a UTC [DateTime]).
  ///
  /// ## Returns
  ///
  /// - A [TimezoneResult] when successful, otherwise `null`.
  static TimezoneResult? getTimezoneInfoFromTimezoneIdSync({
    required final String timezoneId,
    required final DateTime time,
  }) {
    final TimezoneResult result = TimezoneResult.create();

    final OperationResult resultString = staticMethod(
      'TimezoneService',
      'getTimezoneInfoTimezoneIdSync',
      args: <String, dynamic>{
        'timezoneResult': result.pointerId,
        'timezoneId': timezoneId,
        'time': time.millisecondsSinceEpoch,
      },
    );

    if (resultString['result'] != 0) {
      return null;
    }

    return result;
  }
}
