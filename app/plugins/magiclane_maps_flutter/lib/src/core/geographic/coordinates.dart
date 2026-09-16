// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:math';

import 'package:meta/meta.dart';

/// Represents a geographic position in the WGS‑84 coordinate system.
///
/// This value object is used across the SDK wherever a point on the globe is required
/// (for example: [Landmark], [Marker], [OverlayItem]). It stores latitude, longitude and
/// optional altitude.
///
/// {@category Geographic}
class Coordinates {
  /// Creates a [Coordinates] instance with explicit latitude, longitude and optional altitude.
  ///
  /// Use this constructor to create a new coordinates object from raw WGS‑84 values.
  ///
  /// ## Parameters
  ///
  /// - [latitude]: Latitude in degrees. Valid range: -90.0 .. +90.0.
  /// - [longitude]: Longitude in degrees. Valid range: -180.0 .. +180.0.
  /// - [altitude]: Altitude in meters. May be null.
  /// - [sceneobject]: Optional scene object id the coordinates belong to.
  Coordinates({
    this.latitude = 2147483647,
    this.longitude = 2147483647,
    this.altitude = 0,
    this.sceneobject = 0,
  });

  /// Creates a [Coordinates] instance from latitude and longitude.
  ///
  /// ## Parameters
  ///
  /// - [latitude]: Latitude in degrees. Valid range: -90.0 .. +90.0.
  /// - [longitude]: Longitude in degrees. Valid range: -180.0 .. +180.0.
  /// - [altitude]: Optional altitude in meters.
  Coordinates.fromLatLong(this.latitude, this.longitude, [this.altitude = 0]) {
    sceneobject = 0;
  }

  /// Deserializes a [Coordinates] instance from a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  @internal
  factory Coordinates.fromJson(final Map<String, dynamic> json) {
    return Coordinates(
      latitude: json['latitude'], // ?? _maxInt32,
      longitude: json['longitude'], // ?? _maxInt32,
      altitude: json['altitude'],
      sceneobject: json['sceneobject'],
    );
  }

  /// Latitude in degrees.
  ///
  /// Valid range: -90.0 .. +90.0. Positive values are north of the equator,
  /// negative values are south. At the equator the latitude is 0.
  double latitude;

  /// Longitude in degrees.
  ///
  /// Valid range: -180.0 .. +180.0. Positive values are east of the Prime Meridian,
  /// negative values are west. At the Greenwich meridian the longitude is 0.
  double longitude;

  /// Altitude in meters.
  ///
  /// May be null. Values can be negative when below the sea level.
  double? altitude;

  /// Optional parent scene object id.
  int? sceneobject;

  /// Returns a copy of this [Coordinates] instance.
  ///
  /// ## Returns
  ///
  /// - A new [Coordinates] object that duplicates latitude, longitude, altitude and sceneobject.
  Coordinates get copy {
    return Coordinates(
      latitude: latitude,
      longitude: longitude,
      altitude: altitude,
      sceneobject: sceneobject,
    );
  }

  /// Serializes this [Coordinates] instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['latitude'] = latitude;
    json['longitude'] = longitude;
    if (altitude != null) {
      json['altitude'] = altitude;
    }
    if (sceneobject != null) {
      json['sceneobject'] = sceneobject;
    }
    return json;
  }

  /// Calculates the azimuth (bearing) from this coordinate to [target].
  ///
  /// The azimuth is computed according to the ellipsoid model of WGS84 and
  /// returned in degrees. If the points are effectively identical or invalid, the method returns 0.0.
  ///
  /// ## Parameters
  ///
  /// - [target]: The destination [Coordinates] to which the azimuth is calculated.
  ///
  /// ## Returns
  ///
  /// - Azimuth in degrees from this coordinate to [target].
  double azimuth(Coordinates target) {
    double result = 0.0;

    double lat1 = latitude;
    double lon1 = longitude;
    double lat2 = target.latitude;
    double lon2 = target.longitude;

    final int intLat1 = (0.5 + lat1 * 360000.0).toInt();
    final int intLon1 = (0.5 + lon1 * 360000.0).toInt();
    final int intLat2 = (0.5 + lat2 * 360000.0).toInt();
    final int intLon2 = (0.5 + lon2 * 360000.0).toInt();

    double degToRad(double deg) => deg * pi / 180.0;
    double radToDeg(double rad) => rad * 180.0 / pi;

    if (intLat1 != intLat2 || intLon1 != intLon2) {
      if (intLon1 != intLon2) {
        lat1 = degToRad(lat1);
        lon1 = degToRad(lon1);
        lat2 = degToRad(lat2);
        lon2 = degToRad(lon2);

        final double diff = lon2 - lon1;
        final double cosLat2 = cos(lat2);
        final double c = acos(
          sin(lat2) * sin(lat1) + cosLat2 * cos(lat1) * cos(diff),
        );
        result = radToDeg(asin(cosLat2 * sin(diff) / sin(c)));

        if (intLat2 > intLat1 && intLon2 > intLon1) {
        } else if ((intLat2 < intLat1 && intLon2 < intLon1) ||
            (intLat2 < intLat1 && intLon2 > intLon1)) {
          result = 180.0 - result;
        } else if (intLat2 > intLat1 && intLon2 < intLon1) {
          result += 360.0;
        }
      } else if (intLat1 > intLat2) {
        result = 180.0;
      }
    }
    return result;
  }

  /// Calculates the distance in meters between this coordinate and [other].
  ///
  /// The distance is computed using the Haversine (great-circle) formula. If
  /// both points contain non-null altitude values and [ignoreAltitude] is false,
  /// the vertical difference is included using Pythagorean combination.
  ///
  /// ## Parameters
  ///
  /// - [other]: The other [Coordinates] to measure distance to.
  /// - [ignoreAltitude]: When false (default) and both coordinates have altitude
  ///   values, include altitude difference in the final distance calculation.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final coordinates1 = Coordinates(latitude: 48.858844, longitude: 2.294351);
  /// final coordinates2 = Coordinates(latitude: 48.854520, longitude: 2.299751);
  ///
  /// double distance = coordinates1.distance(coordinates2);
  /// ```
  ///
  /// ## Returns
  ///
  /// - Distance in meters between this coordinate and [other].
  double distance(final Coordinates other, {bool ignoreAltitude = false}) {
    const double earthRadius = 6371000; // Earth's radius in meters

    double toRadians(final double value) {
      return value * pi / 180; // Convert degrees to radians
    }

    final double deltaLatitude = toRadians(other.latitude - latitude);
    final double deltaLongitude = toRadians(other.longitude - longitude);

    final double a =
        sin(deltaLatitude / 2) * sin(deltaLatitude / 2) +
        cos(toRadians(latitude)) *
            cos(toRadians(other.latitude)) *
            sin(deltaLongitude / 2) *
            sin(deltaLongitude / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    double altitudeDifference = 0;
    if (!ignoreAltitude && other.altitude != null && altitude != null) {
      altitudeDifference = other.altitude! - altitude!;
    }

    final double distance = sqrt(
      (c * c * earthRadius * earthRadius) +
          (altitudeDifference * altitudeDifference),
    );

    return distance;
  }

  /// Indicates whether the coordinate contains valid latitude and longitude values.
  ///
  /// ## Returns
  ///
  /// - `true` when latitude and longitude are not the internal sentinel values
  ///   used to represent uninitialized coordinates; otherwise `false`.
  bool get isValid {
    return (latitude.toInt() != _maxInt32 && longitude.toInt() != _maxInt32) &&
        (latitude != -99999 && longitude != -99999);
  }

  /// Returns a new [Coordinates] translated by the specified offsets in meters.
  ///
  /// The offsets are applied in meters for latitude and longitude. The method
  /// converts the meter offsets to degrees based on the current latitude.
  ///
  /// ## Parameters
  ///
  /// - [metersLatitude]: Latitude offset in meters.
  /// - [metersLongitude]: Longitude offset in meters.
  ///
  /// ## Returns
  ///
  /// - A new [Coordinates] instance translated by the provided offsets.
  Coordinates copyWithMetersOffset({
    required final int metersLatitude,
    required final int metersLongitude,
  }) {
    const double earthRadius = 6371000; // Earth's radius in meters
    final double latitudeInDegrees = metersLatitude / earthRadius * (180 / pi);
    final double longitudeInDegrees =
        metersLongitude / (earthRadius * cos(latitude * pi / 180)) * (180 / pi);

    return Coordinates(
      latitude: latitude + latitudeInDegrees,
      longitude: longitude + longitudeInDegrees,
      altitude: altitude,
      sceneobject: sceneobject,
    );
  }

  /// Resets this instance to the internal default (uninitialized) values.
  ///
  /// After calling this method latitude and longitude will be set to the internal
  /// sentinel value and altitude/sceneobject to 0.
  void reset() {
    latitude = longitude = 2147483647;
    altitude = 0;
    sceneobject = 0;
  }

  @override
  bool operator ==(covariant final Coordinates other) {
    if (identical(this, other)) {
      return true;
    }

    return other.latitude == latitude &&
        other.longitude == longitude &&
        other.altitude == altitude;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^ longitude.hashCode ^ altitude.hashCode;
  }

  @override
  String toString() {
    return 'Coordinates(lat: $latitude, long: $longitude, alt: $altitude, so: $sceneobject)';
  }

  static const int _maxInt32 = (1 << 31) - 1;
}
