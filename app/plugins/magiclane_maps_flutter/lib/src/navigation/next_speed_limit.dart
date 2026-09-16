// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:meta/meta.dart';

/// Speed limit variation data.
///
/// Encapsulates information about upcoming speed limit changes during navigation,
/// including the geographic coordinates where the change occurs, the distance to
/// the change, and the new speed limit value.
///
/// ## Properties
///
/// - `coords`: Geographic coordinates where the speed limit change begins.
/// - `distance`: Distance (in meters) from current position to the speed limit change.
/// - `speed`: New speed limit value (in current unit system).
/// - `status`: Availability status of the speed limit data (computed property).
///
/// ## Usage
///
/// This class is returned by [NavigationInstruction.getNextSpeedLimitVariation]
/// and should not be instantiated directly. Use the `status` property to determine
/// how to interpret the data.
///
/// - [NavigationInstruction.getNextSpeedLimitVariation] - Retrieves speed limit changes.
/// - [NextSpeedLimitStatus] - Status enumeration for speed limit availability.
///
/// {@category Navigation}
class NextSpeedLimit {
  /// Creates a NextSpeedLimit instance.
  ///
  /// API consumers should not call this constructor directly.
  ///
  /// ## Parameters
  ///
  /// - `coords`: Coordinates where the next speed limit begins.
  /// - `distance`: Distance (in meters) to the next speed limit change.
  /// - `speed`: Next speed limit value.
  NextSpeedLimit({
    required this.coords,
    required this.distance,
    required this.speed,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory NextSpeedLimit.fromJson(final Map<String, dynamic> json) {
    return NextSpeedLimit(
      coords: Coordinates.fromJson(json['coords']),
      distance: json['distance'],
      speed: json['speed'],
    );
  }

  /// Coordinates where the next speed limit begins
  Coordinates coords;

  /// Distance where the next speed limit begins
  ///
  /// Measured in meters
  int distance;

  /// Next speed limit value
  ///
  /// Is 0 if no speed limit info is available
  /// or if there is no speed change within the given distance
  double speed;

  /// The status of the availability of the next speed limit
  ///
  /// Determines how to interpret the other properties
  NextSpeedLimitStatus get status {
    if (speed == 0 && distance == 0) {
      return NextSpeedLimitStatus.noSpeedChange;
    }
    if (speed == 0 && distance != 0) {
      return NextSpeedLimitStatus.noData;
    }
    return NextSpeedLimitStatus.withSpeedChange;
  }

  @override
  bool operator ==(covariant final NextSpeedLimit other) {
    return coords == other.coords &&
        distance == other.distance &&
        speed == other.speed;
  }

  @override
  int get hashCode => coords.hashCode ^ distance.hashCode ^ speed.hashCode;
}
