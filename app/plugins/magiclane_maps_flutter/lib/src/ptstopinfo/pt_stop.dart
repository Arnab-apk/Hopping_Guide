// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:flutter/foundation.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/ptstopinfo/pt_alert_info.dart';
import 'package:magiclane_maps_flutter/src/ptstopinfo/pt_route_info.dart';

/// Public transport stop metadata.
///
/// Represents a stop (or platform/entrance) with an id, display name and the
/// set of routes that serve it.
///
/// Instances are produced as part of [PTStopInfo.stops].
///
/// {@category Maps & 3D Scenes}
class PTStop {
  /// Create a [PTStop].
  ///
  /// API users do not typically create instances of this class directly.
  ///
  /// ## Parameters
  ///
  /// - [stopId]: (int) Numeric stop identifier.
  /// - [stopName]: (String) Display name of the stop.
  /// - [isStation]: (bool?) True when the stop is a station (may be null).
  /// - [routes]: (`List<PTRouteInfo>`) Routes that serve this stop.
  /// - [alerts]: (`List<PTAlertInfo>`) Service alerts scoped to this stop.
  PTStop({
    required this.stopId,
    required this.stopName,
    this.isStation,
    required this.routes,
    this.alerts = const <PTAlertInfo>[],
  });

  factory PTStop._build(GemParameter param, List<PTAlertInfo> alerts) {
    final Map<String, dynamic> map = <String, dynamic>{};

    final List<GemParameter> stop = (param.value as ParameterList).toList();
    for (final GemParameter el in stop) {
      if (el.key == 'routes') {
        map[el.key!] = PTRouteInfo.buildStopRoutes(el.value.toList());
      } else if (el.key == 'alert_indexes') {
        map[el.key!] = PTAlertInfo.resolveAlertIndexes(
          el.value.toList(),
          alerts,
        );
      } else {
        map[el.key!] = el.value;
      }
    }

    return PTStop(
      stopId: map['stop_id'] as int,
      stopName: map['stop_name'] as String,
      isStation: map['is_station'] != null ? (map['is_station'] == 1) : null,
      routes: map['routes'] as List<PTRouteInfo>,
      alerts: map['alert_indexes'] as List<PTAlertInfo>? ?? <PTAlertInfo>[],
    );
  }

  /// Numeric stop identifier.
  final int stopId;

  /// Stop display name.
  final String stopName;

  /// True when the stop is a station; otherwise null/false.
  final bool? isStation;

  /// Routes serving the stop.
  final List<PTRouteInfo> routes;

  /// GTFS-RT service alerts scoped to this stop (e.g. station closure,
  /// elevator outage).
  ///
  /// Shares [PTAlertInfo] instances with [PTStopInfo.alerts]. Empty when no
  /// alerts apply.
  final List<PTAlertInfo> alerts;

  /// Builds a list of [PTStop] from a list of [GemParameter] and
  /// [PTAlertInfo].
  ///
  /// API users should not call this method directly.
  @internal
  static List<PTStop> buildStops(
    List<GemParameter> paramList,
    List<PTAlertInfo> alerts,
  ) {
    final List<PTStop> stops = <PTStop>[];

    for (final GemParameter param in paramList) {
      stops.add(PTStop._build(param, alerts));
    }

    return stops;
  }
}
