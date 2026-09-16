// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Timestamped geographic coordinate with associated relative distance.
///
/// Represents a WGS coordinate plus a distance (meters) from an origin and a
/// timestamp (milliseconds since epoch). Useful when working with route
/// samples, time-distance traces, and navigation telemetry.
///
/// The API user typically does not create instances directly.
/// Rather, instances are provided by the SDK in various methods.
///
/// ## Also see:
///
/// - [RouteBase.getTimeDistanceCoordinates] - Get time-distance coordinates on a route between two distances
/// - [RouteBase.getTimeDistanceCoordinateOnRoute] - Get a time-distance coordinate at a specific distance on a route
///
/// {@category Route}
class TimeDistanceCoordinate {
  /// Creates a new time-distance-coordinate object.
  ///
  /// The API user typically does not create instances directly.
  ///
  /// ## Parameters
  ///
  /// - [coords]: WGS coordinates (latitude/longitude, optional altitude).
  /// - [distance]: Relative distance in meters from an origin point. Defaults to `0`.
  /// - [stamp]: Timestamp in milliseconds since epoch. Defaults to `0`.
  TimeDistanceCoordinate({
    required this.coords,
    this.distance = 0,
    this.stamp = 0,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory TimeDistanceCoordinate.fromJson(final Map<String, dynamic> json) {
    return TimeDistanceCoordinate(
      coords: Coordinates.fromJson(json['coords']),
      distance: json['distance'],
      stamp: json['stamp'],
    );
  }

  /// WGS coordinates.
  Coordinates coords;

  /// Relative distance in meters.
  int distance;

  /// Timestamp in milliseconds since epoch (UTC).
  int stamp;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['coords'] = coords.toJson();
    json['distance'] = distance;
    json['stamp'] = stamp;
    return json;
  }

  @override
  bool operator ==(covariant final TimeDistanceCoordinate other) {
    if (identical(this, other)) {
      return true;
    }

    return other.coords == coords &&
        other.distance == distance &&
        other.stamp == stamp;
  }

  @override
  int get hashCode {
    return coords.hashCode ^ distance.hashCode ^ stamp.hashCode;
  }
}
