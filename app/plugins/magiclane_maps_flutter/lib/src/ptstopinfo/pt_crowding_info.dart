// SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Live vehicle crowding data derived from GTFS-RT vehicle positions.
///
/// Appears in two places:
///
/// - [PTTrip.vehicle] — the measured values reported by the vehicle running
///   exactly that trip instance; [vehicles] is always null there.
/// - [PTRouteInfo.liveCrowding] — a summary over all the route's fresh
///   vehicle positions: [vehicles] counts them and the other fields carry
///   the WORST value over those vehicles (occupancy considers the
///   [PTOccupancyStatus.empty]..[PTOccupancyStatus.notAcceptingPassengers]
///   crowding scale only).
///
/// **WARNING:** Every field is optional, always — feeds and older realtime
/// producers supply arbitrary subsets, so any combination of fields may be
/// null.
///
/// ## Also see:
///
/// - [PTTrip.vehicle] — Live crowding for a specific departure.
/// - [PTTrip.departureOccupancyStatus] — Predicted occupancy for a departure.
/// - [PTRouteInfo.liveCrowding] — Live crowding summary for a route.
///
/// {@category Maps & 3D Scenes}
class PTCrowdingInfo {
  /// Create a [PTCrowdingInfo].
  ///
  /// API users do not typically create instances of this class directly.
  /// Get instances from [PTTrip.vehicle] or [PTRouteInfo.liveCrowding].
  ///
  /// ## Parameters
  ///
  /// - [vehicles]: (int?) Number of fresh vehicle positions on the route.
  /// - [congestionLevel]: (PTCongestionLevel?) Congestion level of the traffic the vehicle(s) travel in.
  /// - [occupancyStatus]: (PTOccupancyStatus?) Occupancy status of the vehicle(s).
  /// - [occupancyPercentage]: (int?) Occupancy as a percentage of capacity.
  PTCrowdingInfo({
    this.vehicles,
    this.congestionLevel,
    this.occupancyStatus,
    this.occupancyPercentage,
  });

  /// Builds a [PTCrowdingInfo] from a list of [GemParameter].
  ///
  /// API users should not call this method directly.
  @internal
  factory PTCrowdingInfo.build(List<GemParameter> params) {
    final Map<String, dynamic> map = <String, dynamic>{};

    for (final GemParameter el in params) {
      map[el.key!] = el.value;
    }

    return PTCrowdingInfo(
      vehicles: map['vehicles'] as int?,
      congestionLevel: map['congestion_level'] != null
          ? PTCongestionLevelExtension.fromId(map['congestion_level'] as int)
          : null,
      occupancyStatus: map['occupancy_status'] != null
          ? PTOccupancyStatusExtension.fromId(map['occupancy_status'] as int)
          : null,
      occupancyPercentage: map['occupancy_percentage'] as int?,
    );
  }

  /// Number of fresh vehicle positions on the route.
  ///
  /// Only provided by [PTRouteInfo.liveCrowding]; always null for
  /// [PTTrip.vehicle].
  final int? vehicles;

  /// Congestion level of the traffic the vehicle(s) travel in (may be null).
  final PTCongestionLevel? congestionLevel;

  /// Occupancy status of the vehicle(s) (may be null).
  ///
  /// Values above [PTOccupancyStatus.notAcceptingPassengers] mean there is
  /// no usable crowding data. The scale is NOT strictly linear — display the
  /// producer's state, don't interpolate.
  final PTOccupancyStatus? occupancyStatus;

  /// Occupancy as a percentage of the vehicle capacity (may be null).
  ///
  /// May exceed 100 per the GTFS-RT specification.
  final int? occupancyPercentage;
}

/// Congestion level of the traffic a vehicle travels in
/// (GTFS-RT `CongestionLevel` enum).
///
/// Values outside the GTFS-RT enum are mapped to [unknown]. The server never
/// emits [unknown] itself — the field is omitted instead.
///
/// ## Also see:
///
/// - [PTCrowdingInfo.congestionLevel] — The congestion level for specific crowding data.
///
/// {@category Maps & 3D Scenes}
enum PTCongestionLevel {
  /// Unknown congestion level.
  unknown,

  /// Running smoothly.
  runningSmoothly,

  /// Stop and go.
  stopAndGo,

  /// Congestion.
  congestion,

  /// Severe congestion.
  severeCongestion,
}

/// @nodoc
extension PTCongestionLevelExtension on PTCongestionLevel {
  /// Returns the GTFS-RT `CongestionLevel` value for the [PTCongestionLevel].
  int get id => index;

  /// Returns the [PTCongestionLevel] for the GTFS-RT `CongestionLevel` [value].
  ///
  /// Out of range values are mapped to [PTCongestionLevel.unknown].
  static PTCongestionLevel fromId(int value) {
    if (value < 0 || value >= PTCongestionLevel.values.length) {
      return PTCongestionLevel.unknown;
    }
    return PTCongestionLevel.values[value];
  }
}

/// Occupancy status of a vehicle (GTFS-RT `OccupancyStatus` enum).
///
/// Values above [notAcceptingPassengers] mean there is no usable crowding
/// data. The scale is NOT strictly linear — display the producer's state,
/// don't interpolate.
///
/// Values outside the GTFS-RT enum are mapped to [noDataAvailable].
///
/// ## Also see:
///
/// - [PTCrowdingInfo.occupancyStatus] — The occupancy status for specific crowding data.
/// - [PTTrip.departureOccupancyStatus] — The predicted occupancy for a departure.
///
/// {@category Maps & 3D Scenes}
enum PTOccupancyStatus {
  /// Empty.
  empty,

  /// Many seats available.
  manySeatsAvailable,

  /// Few seats available.
  fewSeatsAvailable,

  /// Standing room only.
  standingRoomOnly,

  /// Crushed standing room only.
  crushedStandingRoomOnly,

  /// Full.
  full,

  /// Not accepting passengers.
  notAcceptingPassengers,

  /// No usable crowding data.
  noDataAvailable,

  /// Not boardable (no usable crowding data).
  notBoardable,
}

/// @nodoc
extension PTOccupancyStatusExtension on PTOccupancyStatus {
  /// Returns the GTFS-RT `OccupancyStatus` value for the [PTOccupancyStatus].
  int get id => index;

  /// Returns the [PTOccupancyStatus] for the GTFS-RT `OccupancyStatus` [value].
  ///
  /// Out of range values are mapped to [PTOccupancyStatus.noDataAvailable].
  static PTOccupancyStatus fromId(int value) {
    if (value < 0 || value >= PTOccupancyStatus.values.length) {
      return PTOccupancyStatus.noDataAvailable;
    }
    return PTOccupancyStatus.values[value];
  }
}
