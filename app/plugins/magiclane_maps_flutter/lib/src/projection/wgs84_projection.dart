// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// WGS84 geographic projection representation.
///
/// Represents geographic coordinates (latitude/longitude) in the
/// WGS84 reference frame.
///
/// ## Also see:
///
/// - [Coordinates] — Geographic coordinate representation used throughout the SDK.
///
/// {@category Projections}
class WGS84Projection extends Projection {
  /// Creates a new [WGS84Projection] from [Coordinates].
  ///
  /// ## Parameters
  ///
  /// - [coordinates]: (Coordinates) Geographic coordinates to wrap.
  factory WGS84Projection(Coordinates coordinates) {
    return WGS84Projection._create(coordinates);
  }

  /// Creates a [WGS84Projection] from latitude and longitude.
  ///
  /// ## Parameters
  ///
  /// - [latitude]: (double) Latitude in degrees.
  /// - [longitude]: (double) Longitude in degrees.
  factory WGS84Projection.fromLatLong({
    required double latitude,
    required double longitude,
  }) {
    return WGS84Projection._create(
      Coordinates(latitude: latitude, longitude: longitude),
    );
  }
  WGS84Projection.init(super.id) : super.init();

  static WGS84Projection _create(Coordinates coordinates) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'Projection_WGS84',
        'args': <String, dynamic>{'coordinates': coordinates},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final WGS84Projection retVal = WGS84Projection.init(decodedVal['result']);
    return retVal;
  }

  /// Returns the coordinates for the WGS84Projection.
  ///
  /// ## Returns
  ///
  /// - The coordinates as a [Coordinates] object, or null if the coordinates are not set.
  Coordinates get coordinates {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_WGS84',
      'getCoordinates',
    );

    return Coordinates.fromJson(resultString['result']);
  }

  /// Sets the coordinates for the WGS84Projection.
  ///
  /// ## Parameters
  ///
  /// - [coordinates]: The coordinates to set for the projection.
  set coordinates(Coordinates coordinates) {
    objectMethod(
      pointerId,
      'Projection_WGS84',
      'set',
      args: coordinates.toJson(),
    );
  }
}
