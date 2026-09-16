// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:ui' show Color;

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/extensions.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Public transport route segment.
///
/// A contiguous portion of a public-transport route with the same means of transport.
///
/// Segments expose transit-specific metadata such as platform codes, agency information,
/// schedule times and accessibility flags. Use [PTRouteSegment] when inspecting a
/// [PTRoute]'s segments for trip details.
///
/// ## See also:
///
/// - [RouteSegment.toPTRouteSegment] - transform a suitable route segment to a [PTRouteSegment]
/// - [PTRouteInstruction] - instructions contained in a transit segment.
///
/// {@category Route}
class PTRouteSegment extends RouteSegmentBase {
  PTRouteSegment(super.pointerId) : super.init();

  /// Segment display name.
  ///
  /// Human-readable name associated with this segment (for example a station or
  /// line name). Is influenced by the SDK language.
  ///
  /// ## Returns
  ///
  /// - `String`: The segment name.
  String get name {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getName',
    );

    return resultString['result'];
  }

  /// Platform code for boarding/alighting at the stop associated with this segment.
  ///
  /// ## Returns
  ///
  /// - `String`: Platform identifier or empty string if not available.
  String get platformCode {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getPlatformCode',
    );

    return resultString['result'];
  }

  /// Scheduled arrival time for this segment in UTC.
  ///
  /// Returns `null` when the underlying value is not available or out of the
  /// representable [DateTime] range.
  ///
  /// ## Returns
  ///
  /// - [DateTime?]: Arrival time in UTC or `null`.
  DateTime? get arrivalTime {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getArrivalTime',
    );

    final int val = resultString['result'];
    if (val < -8640000000000000 || val > 8640000000000000) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(val, isUtc: true);
  }

  /// Scheduled departure time for this segment in UTC.
  ///
  /// ## Returns
  ///
  /// - [DateTime?]: Departure time in UTC or `null`.
  DateTime? get departureTime {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getDepartureTime',
    );

    final int val = resultString['result'];
    if (val < -8640000000000000 || val > 8640000000000000) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(val, isUtc: true);
  }

  /// Whether this segment supports wheelchair accessibility.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when wheelchair support is available.
  bool get hasWheelchairSupport {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getHasWheelchairSupport',
    );

    return resultString['result'];
  }

  /// Short display name (e.g., route short name or number).
  ///
  /// ## Returns
  ///
  /// - `String`: Short name for display purposes.
  String get shortName {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getShortName',
    );

    return resultString['result'];
  }

  /// URL with more information about this route segment or trip.
  ///
  /// ## Returns
  ///
  /// - `String`: The route URL or an empty string if not available.
  String get routeUrl {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getRouteUrl',
    );

    return resultString['result'];
  }

  /// Name of the transit agency operating this segment.
  ///
  /// ## Returns
  ///
  /// - `String`: Agency name or empty string when unknown.
  String get agencyName {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getAgencyName',
    );

    return resultString['result'];
  }

  /// Contact phone number for the agency operating this segment.
  ///
  /// ## Returns
  ///
  /// - `String`: Phone number or empty string when not provided.
  String get agencyPhone {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getAgencyPhone',
    );

    return resultString['result'];
  }

  /// Agency website URL for fare and operator information.
  ///
  /// ## Returns
  ///
  /// - `String`: Agency URL or empty string when not available.
  String get agencyUrl {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getAgencyUrl',
    );

    return resultString['result'];
  }

  /// URL where fares or tickets can be purchased for this operator.
  ///
  /// ## Returns
  ///
  /// - `String`: Fare URL or empty string when not available.
  String get agencyFareUrl {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getAgencyFareUrl',
    );

    return resultString['result'];
  }

  /// Origin stop/station name for the transit line in this segment.
  ///
  /// ## Returns
  ///
  /// - `String`: Origin name.
  String get lineFrom {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getLineFrom',
    );

    return resultString['result'];
  }

  /// Destination stop/station name for the transit line in this segment.
  ///
  /// ## Returns
  ///
  /// - `String`: Destination name.
  String get lineTowards {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getLineTowards',
    );

    return resultString['result'];
  }

  /// Arrival delay for the segment, in seconds.
  ///
  /// ## Returns
  ///
  /// - `int`: Delay in seconds (positive: late, negative: early).
  int get arrivalDelayInSeconds {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getArrivalDelayInSeconds',
    );

    return resultString['result'];
  }

  /// Departure delay for the segment, in seconds.
  ///
  /// ## Returns
  ///
  /// - `int`: Delay in seconds (positive: late, negative: early).
  int get departureDelayInSeconds {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getDepartureDelayInSeconds',
    );

    return resultString['result'];
  }

  /// Whether bicycles are supported on this segment.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when bicycle support is available.
  bool get hasBicycleSupport {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getHasBicycleSupport',
    );

    return resultString['result'];
  }

  /// Whether passengers must remain on the same vehicle for this segment.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when staying on the same transit is required.
  bool get stayOnSameTransit {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getStayOnSameTransit',
    );

    return resultString['result'];
  }

  /// Transit type for this segment.
  ///
  /// ## Returns
  ///
  /// - [TransitType]: The transit mode (for example [TransitType.bus] or [TransitType.walk]).
  TransitType get transitType {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getTransitType',
    );

    return TransitTypeExtension.fromId(resultString['result']);
  }

  /// Real-time status for this segment (delay, on time, not available).
  ///
  /// ## Returns
  ///
  /// - [RealtimeStatus]: The real-time status indicator.
  RealtimeStatus get realtimeStatus {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getRealtimeStatus',
    );

    return RealtimeStatusExtension.fromId(resultString['result']);
  }

  /// Line block ID of the route segment.
  ///
  /// ## Returns
  ///
  /// - `int`: Line block ID of the route segment.
  int get lineBlockID {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getLineBlockID',
    );

    return resultString['result'];
  }

  /// Line color of the route segment (used for UI badges).
  ///
  /// ## Returns
  ///
  /// - [Color]: Line color of the route segment.
  Color get lineColor {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getLineColor',
    );

    return ColorExtension.fromJson(resultString['result']);
  }

  /// Get line text color of the route segment.
  ///
  /// ## Returns
  ///
  /// - [Color]: Line text color of the route segment.
  Color get lineTextColor {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getLineTextColor',
    );

    return ColorExtension.fromJson(resultString['result']);
  }

  /// Get count of alerts in the route segment.
  ///
  /// ## Returns
  ///
  /// - `int`: Count of alerts in the route segment.
  ///
  /// ## See also:
  ///
  /// - [getAlert] - retrieve alert by index.
  int get countAlerts {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getCountAlerts',
    );

    return resultString['result'];
  }

  /// Get alert by index.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the alert to retrieve.
  ///
  /// ## Returns
  ///
  /// - [PTAlert?]: The alert object, or `null` when the index is out of bounds.
  ///
  /// ## See also:
  ///
  /// - [countAlerts] - get the number of alerts in the route segment.
  PTAlert? getAlert(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'getAlert',
      args: <String, int>{'index': index},
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return PTAlert(resultString['result']);
  }

  /// Is this a significant route segment.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` if the route segment is significant, otherwise `false`.
  bool get isSignificant {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'isSignificant',
    );

    return resultString['result'];
  }

  /// Is this a station-walk segment.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` if the route segment is a station walk, otherwise `false`.
  bool get isStationWalk {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteSegment',
      'isStationWalk',
    );

    return resultString['result'];
  }
}

/// Public transport alert.
///
/// Represents an alert (for example service disruption) and provides access to
/// localized header, description and URL translations.
///
/// {@category Route}
class PTAlert {
  PTAlert(this.pointerId);
  final int pointerId;

  /// Number of URL translations available for this alert.
  ///
  /// ## Returns
  ///
  /// - `int`: Count of URL translations.
  ///
  /// ## See also:
  ///
  /// - [getUrlTranslation] - get URL translation by index.
  int get countUrlTranslations {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTAlert',
      'getCountUrlTranslations',
    );

    return resultString['result'];
  }

  /// Number of header text translations available for this alert.
  ///
  /// ## Returns
  ///
  /// - `int`: Count of header text translations.
  ///
  /// ## See also:
  ///
  /// - [getHeaderTextTranslation] - get header text translation by index.
  int get countHeaderTextTranslations {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTAlert',
      'getCountHeaderTextTranslations',
    );

    return resultString['result'];
  }

  /// Number of description text translations available for this alert.
  ///
  /// ## Returns
  ///
  /// - `int`: Count of description text translations.
  int get countDescriptionTextTranslations {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTAlert',
      'getCountDescriptionTextTranslations',
    );

    return resultString['result'];
  }

  /// Get URL translation by index.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the translation to retrieve.
  ///
  /// ## Returns
  ///
  /// - [PTTranslation?]: The URL translation or `null` when the index is invalid.
  ///
  /// ## See also:
  ///
  /// - [countUrlTranslations] - get the number of URL translations available.
  PTTranslation? getUrlTranslation(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTAlert',
      'getUrlTranslation',
      args: index,
    );

    if (resultString['result']['isValid'] == false) {
      return null;
    }

    return PTTranslation.fromJson(resultString['result']);
  }

  /// Get header text translation by index.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the translation to retrieve.
  ///
  /// ## Returns
  ///
  /// - [PTTranslation?]: The header translation or `null` when the index is invalid.
  ///
  /// ## See also:
  ///
  /// - [countHeaderTextTranslations] - get the number of header text translations available.
  PTTranslation? getHeaderTextTranslation(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTAlert',
      'getHeaderTextTranslation',
      args: index,
    );

    if (resultString['result']['isValid'] == false) {
      return null;
    }

    return PTTranslation.fromJson(resultString['result']);
  }

  /// Get description text translation by index.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the translation to retrieve.
  ///
  /// ## Returns
  ///
  /// - [PTTranslation?]: The description translation or `null` when the index is invalid.
  PTTranslation? getDescriptionTextTranslation(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTAlert',
      'getDescriptionTextTranslation',
      args: index,
    );

    if (resultString['result']['isValid'] == false) {
      return null;
    }

    return PTTranslation.fromJson(resultString['result']);
  }
}

/// Public transport translation.
///
/// Holds a translated text and its BCP-47 language code. Used by
/// [PTAlert] to provide localized header, description and URL translations.
///
/// ## See also:
///
/// - [PTAlert] - alerts containing translations.
///
/// {@category Route}
class PTTranslation {
  PTTranslation(this.text, this.language);

  /// Create a translation from a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory PTTranslation.fromJson(final Map<String, dynamic> json) {
    return PTTranslation(json['text'], json['language']);
  }

  /// The text message.
  final String text;

  /// The language code of the text message, in BCP-47 format.
  final String language;
}
