// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/routing.dart';
import 'package:meta/meta.dart';

/// Provides additional, read-only parameters that describe a traffic event.
//
/// Typical information includes estimated speed impact, expected delay,
/// severity level, and a short descriptive label or reason for the event.
///
/// Obtain an instance via [TrafficEvent.getPreviewData]. The method may
/// return null when no preview data is available for a given event.
///
/// {@category Traffic & Roadblocks}
class TrafficParameters {
  /// Creates a new TrafficParameters instance.
  ///
  /// The API user typically does not create instances directly.
  ///
  /// ## Parameters
  ///
  /// - [id]: Unique identifier
  /// - [iconId]: Icon identifier
  /// - [alertc]: Alert count
  /// - [delay]: Delay in seconds
  /// - [description]: Description
  /// - [startStamp]: Start timestamp
  /// - [endStamp]: End timestamp
  /// - [from]: From location
  /// - [to]: To location
  /// - [transportMode]: Transport mode
  TrafficParameters({
    required this.id,
    required this.iconId,
    required this.alertc,
    required this.delay,
    required this.description,
    required this.startStamp,
    required this.endStamp,
    required this.from,
    required this.to,
    required this.transportMode,
  });

  @internal
  factory TrafficParameters.fromParameters(List<GemParameter> params) {
    T? findValue<T>(String key) {
      for (final GemParameter param in params) {
        if (param.key == key) {
          if (param.value is! T) {
            return null;
          }
          return param.value as T?;
        }
      }
      return null;
    }

    T findValueWithDefault<T>(String key, T defaultValue) {
      final T? value = findValue<T>(key);
      return value ?? defaultValue;
    }

    DateTime parseDateTimeString(String dateTimeString) {
      if (dateTimeString.isEmpty) {
        return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      }
      try {
        return DateTime.parse(dateTimeString);
      } catch (e) {
        return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      }
    }

    DateTime parseDateTimeInt(int timestamp) {
      if (timestamp <= 0) {
        return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
      }
      return DateTime.fromMillisecondsSinceEpoch(timestamp, isUtc: true);
    }

    final dynamic startStampValue =
        findValue<int>('start_stamp') ?? findValue<String>('start_stamp');
    final dynamic endStampValue =
        findValue<int>('end_stamp') ?? findValue<String>('end_stamp');

    final DateTime startStamp = startStampValue is int
        ? parseDateTimeInt(startStampValue)
        : parseDateTimeString(startStampValue as String? ?? '');

    final DateTime endStamp = endStampValue is int
        ? parseDateTimeInt(endStampValue)
        : parseDateTimeString(endStampValue as String? ?? '');

    return TrafficParameters(
      id: findValueWithDefault<String>('id', ''),
      iconId: findValueWithDefault<int>('iconId', 0),
      alertc: findValueWithDefault<int>('alertc', 0),
      delay: findValueWithDefault<int>('delay', 0),
      description: findValueWithDefault<String>('description', ''),
      startStamp: startStamp,
      endStamp: endStamp,
      from: findValueWithDefault<String>('from', ''),
      to: findValueWithDefault<String>('to', ''),
      transportMode: RouteTransportModeExtension.fromId(
        findValueWithDefault<int>('transportMode', 0),
      ),
    );
  }

  /// Identificator for the traffic event
  ///
  /// It is the `id` parameter passed to the [TrafficService] add methods in case
  /// of user-created roadblocks. For SDK provided traffic events, it is empty string.
  final String id;

  /// Icon id
  final int iconId;

  /// Alert-C identifier describing the type and severity of the traffic event.
  ///
  /// The value corresponds to an Alert-C incident code as defined in ISO 14819
  /// (Traffic and Travel Information – TTI).
  final int alertc;

  /// Delay in seconds caused by the traffic event
  ///
  /// May be -1 if delay is unknown.
  final int delay;

  /// Traffic event description
  ///
  /// For SDK provided traffic events, it typically contains a short label such as
  /// "Roadblock".
  final String description;

  /// Start timestamp when the traffic event becomes active
  ///
  /// For user-created roadblocks, it is the `startTime` parameter passed to the [TrafficService] add methods.
  final DateTime startStamp;

  /// End timestamp when the traffic event ends
  ///
  /// For user-created roadblocks, it is the `endTime` parameter passed to the [TrafficService] add methods.
  final DateTime endStamp;

  /// The location where the traffic event starts
  ///
  /// It is usually an address formatted as a string containing the street and possibly
  /// additional information such as house number.
  final String from;

  /// The location where the traffic event ends
  ///
  /// It is usually an address formatted as a string containing the street and possibly
  /// additional information such as house number.
  final String to;

  /// The transport mode for which the traffic event is relevant
  ///
  /// For user-created roadblocks, it is the `transportMode` parameter passed to the [TrafficService] add methods.
  /// SDK provided traffic events typically have [RouteTransportMode.car] as transport mode.
  final RouteTransportMode transportMode;
}
