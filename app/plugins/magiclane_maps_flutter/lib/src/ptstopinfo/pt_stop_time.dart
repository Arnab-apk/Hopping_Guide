// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Stop-time information for a single stop within a trip.
///
/// Contains local-time departure, delay and realtime availability flags.
/// NOTE: departure times are returned as [DateTime] objects with UTC flag
/// but encoded as local time; convert using [TimezoneService] when needed.
///
/// ## See also:
///
/// - [PTTrip.stopTimes] — The list of stop times for a trip.
/// - [TimezoneService] — For converting local times to different time zones.
///
/// {@category Maps & 3D Scenes}
class PTStopTime {
  /// Create a [PTStopTime].
  ///
  /// API users do not typically create instances of this class directly.
  ///
  /// ## Parameters
  ///
  /// - [stopName]: (String) Name of the stop.
  /// - [coordinates]: (Coordinates) WGS84 coordinates for the stop.
  /// - [hasRealtime]: (bool) True if realtime data is available.
  /// - [delay]: (int) Delay in seconds.
  /// - [departureTime]: (DateTime?) Optional departure time (UTC flag, local value).
  /// - [stopDetails]: (int) Bitmask with stop details.
  /// - [isBefore]: (bool) True when the stop time is before current time.
  PTStopTime({
    required this.stopName,
    required this.coordinates,
    required this.hasRealtime,
    required this.delay,
    required this.departureTime,
    required int stopDetails,
    required this.isBefore,
  }) : _stopDetails = stopDetails;

  factory PTStopTime._build(GemParameter param) {
    final Map<String, dynamic> map = <String, dynamic>{};

    final List<GemParameter> stopTime = (param.value as ParameterList).toList();
    for (final GemParameter el in stopTime) {
      map[el.key!] = el.value;
    }

    return PTStopTime(
      stopName: map['stop_name'] as String,
      coordinates: Coordinates(
        latitude: map['lat'] as double,
        longitude: map['lon'] as double,
      ),
      hasRealtime: map['has_realtime'] != null && map['has_realtime'] == 1,
      delay: map['delay'] as int,
      departureTime: map['departure_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['departure_time'] as int) * 1000,
              isUtc: true,
            )
          : null,
      stopDetails: map['stop_details'] as int,
      isBefore: map['is_before'] as int == 1,
    );
  }

  /// Stop display name.
  String stopName;

  /// WGS84 coordinates for this stop.
  Coordinates coordinates;

  /// Whether realtime information is available.
  bool hasRealtime;

  /// Delay in seconds (may be zero).
  int delay;

  /// Optional departure time.
  ///
  /// **WARNING:** Returned as a `DateTime` with UTC flag but representing
  /// local time; use [TimezoneService] to convert if needed.
  DateTime? departureTime;

  int _stopDetails;

  /// True when this stop time is before the current time.
  bool isBefore;

  /// True when wheelchair access is available for this stop.
  bool get isWheelchairFriendly => (_stopDetails & 0x11) == 1;

  /// Builds a list of [PTStopTime] from a list of [GemParameter].
  ///
  /// API users should not call this method directly.
  @internal
  static List<PTStopTime> buildStopTimes(List<GemParameter> param) {
    final List<PTStopTime> stopTimes = <PTStopTime>[];

    for (final GemParameter el in param) {
      stopTimes.add(PTStopTime._build(el));
    }

    return stopTimes;
  }
}
