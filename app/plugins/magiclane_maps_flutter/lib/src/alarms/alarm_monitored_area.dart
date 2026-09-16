// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Represents a monitored geographic area with its identifier.
///
/// Used by [AlarmService.monitoredAreas], [AlarmService.insideAreas] and
/// [AlarmService.outsideAreas] to describe areas being monitored for boundary crossing events.
///
/// ## See also:
///
/// - [AlarmService.monitorArea] - Add a geographic area to monitor.
/// - [GeographicArea] - Defines rectangle, circle or polygon areas.
///
/// {@category Alarms}
class AlarmMonitoredArea {
  /// Creates an [AlarmMonitoredArea] with the specified area and identifier.
  ///
  /// ## Parameters
  ///
  /// - [area]: The [GeographicArea] definition.
  /// - [id]: Unique identifier for the area.
  AlarmMonitoredArea({required this.area, required this.id});

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory AlarmMonitoredArea.fromJson(final Map<String, dynamic> json) {
    return AlarmMonitoredArea(
      area: GeographicArea.fromJson(json['area']),
      id: json['id'],
    );
  }

  /// The [GeographicArea] definition for this monitored area.
  final GeographicArea area;

  /// Unique identifier for this monitored area.
  final String id;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'area': area.toJson(), 'id': id};
  }
}
