// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:meta/meta.dart';

/// A scheduled public transport trip instance.
///
/// Represents a single scheduled run of a route
/// with times, delays, cancellation and accessibility metadata.
///
/// ## Also see:
///
/// - [PTStopInfo.trips] — The list of trips for a stop info.
/// - [PTTrip.route] — The route associated with a specific trip.
///
/// {@category Maps & 3D Scenes}
class PTTrip {
  /// Create a [PTTrip].
  ///
  /// API users do not typically create instances of this class directly.
  ///
  /// ## Parameters
  ///
  /// - [route]: (PTRouteInfo) The associated public route.
  /// - [agency]: (PTAgency) The operating agency.
  /// - [tripIndex]: (int) Internal trip index.
  /// - [tripDate]: (DateTime?) Trip date (UTC flag, local value).
  /// - [hasRealtime]: (bool) Whether realtime data is available.
  /// - [departureTime]: (DateTime?) Departure time (UTC flag, local value).
  /// - [isCancelled]: (bool?) Cancellation flag.
  /// - [delayMinutes]: (int?) Delay in minutes when realtime data applies.
  /// - [stopTimes]: (`List<PTStopTime>`) Stop times for the trip.
  /// - [stopIndex]: (int) Index of the current stop in the stopTimes list.
  /// - [stopPlatformCode]: (String?) Platform code for the stop.
  /// - [isWheelchairAccessible]: (bool) Wheelchair accessibility flag.
  /// - [isBikeAllowed]: (bool) Bike allowance flag.
  /// - [alerts]: (`List<PTAlertInfo>`) Service alerts applicable to the trip.
  /// - [vehicle]: (PTCrowdingInfo?) Live crowding of the vehicle running the trip.
  /// - [departureOccupancyStatus]: (PTOccupancyStatus?) Predicted occupancy after departing the stop.
  PTTrip({
    required this.route,
    required this.agency,
    required this.tripIndex,
    required this.tripDate,
    required this.hasRealtime,
    required this.departureTime,
    this.isCancelled,
    this.delayMinutes,
    required this.stopTimes,
    required this.stopIndex,
    this.stopPlatformCode,
    required this.isWheelchairAccessible,
    required this.isBikeAllowed,
    this.alerts = const <PTAlertInfo>[],
    this.vehicle,
    this.departureOccupancyStatus,
  });

  factory PTTrip._build(
    GemParameter param,
    List<PTAgency> agencies,
    List<PTAlertInfo> alerts,
  ) {
    final Map<String, dynamic> map = <String, dynamic>{};

    final List<GemParameter> trip = (param.value as ParameterList).toList();
    for (final GemParameter el in trip) {
      if (el.key == 'stop_times') {
        map[el.key!] = PTStopTime.buildStopTimes(el.value.toList());
      } else if (el.key == 'alert_indexes') {
        map[el.key!] = PTAlertInfo.resolveAlertIndexes(
          el.value.toList(),
          alerts,
        );
      } else if (el.key == 'vehicle') {
        map[el.key!] = PTCrowdingInfo.build(el.value.toList());
      } else {
        map[el.key!] = el.value;
      }
    }

    final PTRouteInfo ptRoute = PTRouteInfo.build(param.value.toList());

    final int agencyId = map['agency_id'] as int;

    final PTAgency ptAgency = agencies.firstWhere(
      (PTAgency agency) => agency.id == agencyId,
      orElse: () => PTAgency(id: agencyId, name: 'Unknown Agency'),
    );

    final PTTrip myTrip = PTTrip(
      route: ptRoute,
      agency: ptAgency,
      tripIndex: map['trip_index'] as int,
      tripDate: map['trip_date'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['trip_date'] as int) * 1000,
              isUtc: true,
            )
          : null,
      departureTime: map['departure_time'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (map['departure_time'] as int) * 1000,
              isUtc: true,
            )
          : null,
      hasRealtime: map['has_realtime'] != null && map['has_realtime'] == 1,
      isCancelled: map['is_cancelled'] != null
          ? (map['is_cancelled'] == 1)
          : null,
      delayMinutes: map['delay_minutes'] as int?,
      stopTimes: map['stop_times'] as List<PTStopTime>,
      stopIndex: map['stop_index'] as int,
      stopPlatformCode: map['stop_platform_code'] != null
          ? map['stop_platform_code'] as String
          : null,
      isWheelchairAccessible: map['is_wheelchair_accessible'] == 1,
      isBikeAllowed: map['bikes_allowed'] == 1,
      alerts: map['alert_indexes'] as List<PTAlertInfo>? ?? <PTAlertInfo>[],
      vehicle: map['vehicle'] as PTCrowdingInfo?,
      departureOccupancyStatus: map['departure_occupancy_status'] != null
          ? PTOccupancyStatusExtension.fromId(
              map['departure_occupancy_status'] as int,
            )
          : null,
    );

    return myTrip;
  }

  /// The route associated with the trip.
  PTRouteInfo route;

  /// The agency operating the trip.
  PTAgency agency;

  /// Internal trip index.
  final int tripIndex;

  /// Trip date (UTC flag, local value).
  ///
  /// **WARNING:** Returned as a `DateTime` with UTC flag but representing
  /// local time; use [TimezoneService] to convert if needeed.
  final DateTime? tripDate;

  /// Departure time (UTC flag, local value).
  ///
  /// **WARNING:** Returned as a `DateTime` with UTC flag but representing
  /// local time; use [TimezoneService] to convert if needeed.
  DateTime? departureTime;

  /// Whether realtime information is available.
  bool hasRealtime;

  /// Optional cancellation flag.
  bool? isCancelled;

  /// Delay in minutes (may be null).
  int? delayMinutes;

  /// The list of stop times for this trip.
  List<PTStopTime> stopTimes;

  /// Index of the current/selected stop within [stopTimes].
  int stopIndex;

  /// Platform code for the stop (may be null).
  String? stopPlatformCode;

  /// Wheelchair accessibility flag.
  bool isWheelchairAccessible;

  /// Indicates whether bikes are allowed on the trip.
  bool isBikeAllowed;

  /// GTFS-RT service alerts applicable to this trip.
  ///
  /// Shares [PTAlertInfo] instances with [PTStopInfo.alerts]. Empty when no
  /// alerts apply.
  ///
  /// A [PTAlertEffect.noService] alert overlaps with [isCancelled] —
  /// [isCancelled] remains the authoritative cancellation flag; the alert
  /// supplies the user-facing reason.
  final List<PTAlertInfo> alerts;

  /// Live crowding of the vehicle running this trip (may be null).
  ///
  /// Present when a fresh vehicle position reports exactly this trip
  /// instance — usually only for the currently running vehicle; upcoming
  /// departures typically have none. [PTCrowdingInfo.vehicles] is always
  /// null here.
  ///
  /// When both this and [departureOccupancyStatus] are present, the values
  /// here are measured (live) — prefer them for the current vehicle and
  /// [departureOccupancyStatus] for upcoming departures.
  PTCrowdingInfo? vehicle;

  /// Predicted occupancy after departing this stop (may be null).
  ///
  /// When both this and [vehicle] are present, [PTCrowdingInfo.occupancyStatus]
  /// is measured (live) and this value is predicted — prefer the live value
  /// for the current vehicle, this one for upcoming departures.
  PTOccupancyStatus? departureOccupancyStatus;

  /// Builds a list of [PTTrip] from a list of [GemParameter], [PTAgency]
  /// and [PTAlertInfo].
  ///
  /// API users should not call this method directly.
  @internal
  static List<PTTrip> buildTrips(
    List<GemParameter> paramList,
    List<PTAgency> agencies,
    List<PTAlertInfo> alerts,
  ) {
    final List<PTTrip> trips = <PTTrip>[];

    for (final GemParameter param in paramList) {
      trips.add(PTTrip._build(param, agencies, alerts));
    }

    return trips;
  }
}
