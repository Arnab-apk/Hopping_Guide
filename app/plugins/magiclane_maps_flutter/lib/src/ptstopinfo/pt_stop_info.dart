// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:meta/meta.dart';

/// Aggregated public transport data for a selected overlay item.
///
/// Instances are produced by [OverlayItem.getPTStopInfo] and contain the
/// agencies, stops, trips and service alerts associated with the selected
/// public transport overlay item. Use the filtering helpers to query trips
/// by short name, type or agency.
///
/// ## Examples
///
/// ```dart
/// PTStopInfo? ptStopInfo = await overlayItem.getPTStopInfo();
/// ```
///
/// {@category Maps & 3D Scenes}
class PTStopInfo {
  PTStopInfo._();

  /// Build a [PTStopInfo] from the SDK parameter list returned by the engine.
  ///
  /// API users do not typically create instances of this class directly.
  /// Use the [OverlayItem.getPTStopInfo] method instead.
  ///
  /// ## Parameters
  ///
  /// - [paramList]: (SearchableParameterList) Parameter list returned by the SDK describing agencies, stops and trips.
  @internal
  factory PTStopInfo.fromParameters(SearchableParameterList paramList) {
    final PTStopInfo stopInfo = PTStopInfo._();
    stopInfo._build(paramList);
    return stopInfo;
  }

  List<PTAgency> _agencies = <PTAgency>[];
  List<PTStop> _stops = <PTStop>[];
  List<PTTrip> _trips = <PTTrip>[];
  List<PTAlertInfo> _alerts = <PTAlertInfo>[];

  /// Agencies serving the selected PT overlay item.
  List<PTAgency> get agencies => _agencies;

  /// Stops associated with the selected PT overlay item.
  List<PTStop> get stops => _stops;

  /// Trips associated with the selected PT overlay item.
  ///
  /// Contains [PTTrip] objects providing schedule, realtime and accessibility information.
  List<PTTrip> get trips => _trips;

  /// GTFS-RT service alerts associated with the selected PT overlay item.
  ///
  /// Deduplicated list of all alerts referenced by [PTTrip.alerts] and
  /// [PTStop.alerts]; those lists share the same [PTAlertInfo] instances.
  /// Empty when no alerts apply. The order of the alerts is not meaningful.
  List<PTAlertInfo> get alerts => _alerts;

  /// Filter trips by route short name.
  ///
  /// ## Parameters
  ///
  /// - [routeShortName]: (String) Short name to filter trips by.
  ///
  /// ## Returns
  ///
  /// - (`List<PTTrip>`) Trips whose route short name equals [routeShortName].
  List<PTTrip> tripsByRouteShortName(String routeShortName) => _trips
      .where(
        (PTTrip trip) =>
            trip.route.routeShortName != null &&
            trip.route.routeShortName == routeShortName,
      )
      .toList();

  /// Filter trips by [PTRouteType].
  ///
  /// ## Parameters
  ///
  /// - [routeType]: (PTRouteType) Route type to filter by.
  ///
  /// ## Returns
  ///
  /// - (`List<PTTrip>`) Trips matching the specified route type.
  List<PTTrip> tripsByRouteType(PTRouteType routeType) =>
      _trips.where((PTTrip trip) => trip.route.routeType == routeType).toList();

  /// Filter trips by agency.
  ///
  /// ## Parameters
  ///
  /// - [agency]: (PTAgency) Agency to filter by.
  ///
  /// ## Returns
  ///
  /// - (`List<PTTrip>`) Trips operated by the provided [agency]. Returns an empty list if the agency is not present.
  List<PTTrip> tripsByAgency(PTAgency agency) =>
      _trips.where((PTTrip trip) => trip.agency.id == agency.id).toList();

  void _build(SearchableParameterList paramList) {
    final GemParameter agenciesParam = paramList.findParameter('agencies');
    if (agenciesParam.key!.isNotEmpty && agenciesParam.type == ValueType.list) {
      _agencies = PTAgency.buildAgencies(agenciesParam.value.toList());
    }

    final GemParameter alertsParam = paramList.findParameter('alerts');
    if (alertsParam.key!.isNotEmpty && alertsParam.type == ValueType.list) {
      _alerts = PTAlertInfo.buildAlerts(alertsParam.value.toList());
    }

    final GemParameter stopsParam = paramList.findParameter('stops');
    if (stopsParam.key!.isNotEmpty && stopsParam.type == ValueType.list) {
      _stops = PTStop.buildStops(stopsParam.value.toList(), _alerts);
    }

    final GemParameter tripsParam = paramList.findParameter('trips');
    if (tripsParam.key!.isNotEmpty && tripsParam.type == ValueType.list) {
      _trips = PTTrip.buildTrips(tripsParam.value.toList(), _agencies, _alerts);
    }
  }
}
