// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/sense.dart';

/// Represents the source of position data.
///
/// This enum categorizes the various methods by which geographical position
/// information can be obtained, ranging from basic GPS sensors to advanced
/// sensor fusion and map matching techniques.
///
/// ## See also:
///
/// - [GemPosition.provider]: Provider for raw position data
/// - [GemImprovedPosition]: Enhanced position with map matching capabilities
///
/// {@category Position}
enum Provider {
  /// The position provider is unknown.
  unknown,

  /// The position is obtained from a GPS sensor.
  gps,

  /// The position is obtained from a network-based source.
  network,

  /// The position is improved using inertial sensors for better accuracy.
  sensorFusion,

  /// The position is matched with a map for better accuracy.
  mapMatching,

  /// The position data comes from a simulation environment.
  simulation,
}

/// @nodoc
extension ProviderExtension on Provider {
  int get id {
    switch (this) {
      case Provider.unknown:
        return 0;
      case Provider.gps:
        return 1;
      case Provider.network:
        return 2;
      case Provider.sensorFusion:
        return 3;
      case Provider.mapMatching:
        return 4;
      case Provider.simulation:
        return 5;
    }
  }

  static Provider fromId(final int id) {
    switch (id) {
      case 0:
        return Provider.unknown;
      case 1:
        return Provider.gps;
      case 2:
        return Provider.network;
      case 3:
        return Provider.sensorFusion;
      case 4:
        return Provider.mapMatching;
      case 5:
        return Provider.simulation;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Represents raw GPS sensor data including geographical coordinates and movement information.
///
/// The `GemPosition` class provides unprocessed position data from device sensors,
/// containing basic information about location, speed, altitude, and movement direction.
///
/// For enhanced position data with road-specific information, use [GemImprovedPosition]
/// which extends this class with map-matched data including speed limits, road modifiers,
/// and terrain information.
///
/// ## See also:
///
/// - [GemImprovedPosition]: Enhanced position with map-matched data
/// - [PositionService]: Service for accessing position data
/// - [SenseDataFactory.producePosition]: Factory method for creating position instances
/// - [Coordinates]: Simple geographical coordinate representation
///
/// {@category Position}
abstract class GemPosition extends SenseData {
  /// UTC timestamp when the position data was collected by satellite.
  ///
  /// This represents the actual time when the GPS satellite recorded the position,
  /// which may differ from the device's acquisition time. Timestamps should increase
  /// monotonically for subsequent positions; data with timestamps from the past
  /// will be discarded by the positioning system.
  ///
  /// ## Returns
  ///
  /// - [DateTime]: UTC timestamp of satellite position recording
  DateTime get satelliteTime;

  /// Source type that provided this position data.
  ///
  /// Indicates how the position was obtained, such as GPS sensors, network
  /// triangulation, or enhanced methods like sensor fusion and map matching.
  ///
  /// ## Returns
  ///
  /// - [Provider]: Enum value representing the position data source
  Provider get provider;

  /// Geographical latitude coordinate in decimal degrees.
  ///
  /// Represents the north-south position on Earth's surface using the WGS84
  /// coordinate system. Positive values indicate northern hemisphere locations,
  /// negative values indicate southern hemisphere.
  ///
  /// Valid range is -90.0 to +90.0 degrees. Values outside this range indicate
  /// invalid position data that should not be processed.
  ///
  /// ## Returns
  ///
  /// - [double]: Latitude in degrees (-90.0 to +90.0)
  double get latitude;

  /// Geographical longitude coordinate in decimal degrees.
  ///
  /// Represents the east-west position on Earth's surface using the WGS84
  /// coordinate system. Positive values indicate eastern hemisphere locations,
  /// negative values indicate western hemisphere.
  ///
  /// Valid range is -180.0 to +180.0 degrees. Values outside this range indicate
  /// invalid position data that should not be processed.
  ///
  /// ## Returns
  ///
  /// - [double]: Longitude in degrees (-180.0 to +180.0)
  double get longitude;

  /// Height above mean sea level in meters.
  ///
  /// Altitude can be positive (above sea level) or negative (below sea level).
  ///
  /// ## Returns
  ///
  /// - [double]: Altitude in meters (can be negative)
  double get altitude;

  /// Current travel speed in meters per second.
  ///
  /// Speed represents forward movement velocity and is always non-negative.
  /// If the vehicle is moving in reverse, the course should change by 180 degrees
  /// but speed remains positive. A negative value (-1 by default) indicates
  /// no speed information is available.
  ///
  /// ## Returns
  ///
  /// - [double]: Speed in m/s (non-negative, or -1 if unavailable)
  double get speed;

  /// Accuracy estimate for the speed measurement in meters per second.
  ///
  /// Indicates the precision of the speed data. Typical accuracy for consumer
  /// GPS devices is approximately 2 m/s under good conditions with steady speed
  /// and high position accuracy. Valid speed accuracy values are always positive.
  ///
  /// Not available on web: the browser Geolocation API does not report a speed
  /// accuracy, so this always returns -1 there.
  ///
  /// ## Returns
  ///
  /// - [double]: Speed accuracy in m/s (positive, or -1 if unavailable)
  double get speedAccuracy;

  /// Direction of movement in degrees relative to true north.
  ///
  /// Course represents true heading (not magnetic heading) using standard
  /// compass directions: 0° = true north, 90° = east, 180° = south, 270° = west.
  /// A negative value (-1 by default) indicates no course information is available.
  ///
  /// ## Returns
  ///
  /// - [double]: Course in degrees (0-360, or -1 if unavailable)
  double get course;

  /// Accuracy estimate for the course measurement in degrees.
  ///
  /// Indicates the precision of the heading data. Typical accuracy for consumer
  /// GPS devices is approximately 25 degrees at high speeds. Valid course
  /// accuracy values are always positive.
  ///
  /// Not available on web: the browser Geolocation API does not report a course
  /// accuracy, so this always returns -1 there.
  ///
  /// ## Returns
  ///
  /// - [double]: Course accuracy in degrees (positive, or -1 if unavailable)
  double get courseAccuracy;

  /// Horizontal position accuracy in meters.
  ///
  /// Represents the radius of uncertainty for the geographical position.
  /// Typical accuracy for consumer GPS devices ranges from 5-20 meters under
  /// normal conditions. Valid accuracy values are always positive.
  ///
  /// ## Returns
  ///
  /// - [double]: Horizontal accuracy in meters (positive)
  double get accuracyH;

  /// Vertical position accuracy in meters.
  ///
  /// Represents the uncertainty in altitude measurement. GPS altitude accuracy
  /// is typically less precise than horizontal accuracy. Valid accuracy values
  /// are always positive.
  ///
  /// ## Returns
  ///
  /// - [double]: Vertical accuracy in meters (positive)
  double get accuracyV;

  /// Quality assessment of the position data reliability.
  ///
  /// Provides an overall evaluation of whether the position data can be trusted
  /// for navigation and location-based services.
  ///
  /// ## Returns
  ///
  /// - [PositionQuality] : Enum value indicating position data quality
  PositionQuality get fixQuality;

  /// Indicates whether valid geographical coordinates are available.
  ///
  /// Coordinates are considered valid when both latitude and longitude values
  /// fall within their respective valid ranges (-90 to +90 for latitude,
  /// -180 to +180 for longitude).
  ///
  /// ## Returns
  ///
  /// - `true`: Valid latitude and longitude coordinates are available
  /// - `false`: Coordinates are missing or invalid
  bool get hasCoordinates;

  /// Indicates whether altitude data is available and valid.
  ///
  /// GPS altitude measurements may not always be available or reliable,
  /// particularly in poor signal conditions or with older GPS receivers.
  ///
  /// ## Returns
  ///
  /// - `true`: Valid altitude measurement is available
  /// - `false`: Altitude data is missing or unreliable
  bool get hasAltitude;

  /// Indicates whether speed data is available and valid.
  ///
  /// Speed calculations require sufficient GPS accuracy and may not be
  /// available when stationary or in poor signal conditions.
  ///
  /// ## Returns
  ///
  /// - `true`: Valid speed measurement is available
  /// - `false`: Speed data is missing or unreliable
  bool get hasSpeed;

  /// Indicates whether speed accuracy data is available and valid.
  ///
  /// Speed accuracy estimates help determine the reliability of speed
  /// measurements, particularly important for precise navigation applications.
  ///
  /// Always `false` on web, as the browser Geolocation API does not report a
  /// speed accuracy.
  ///
  /// ## Returns
  ///
  /// - `true`: Valid speed accuracy estimate is available
  /// - `false`: Speed accuracy data is missing
  bool get hasSpeedAccuracy;

  /// Indicates whether course (heading) data is available and valid.
  ///
  /// Course calculations require movement and sufficient GPS accuracy.
  /// Course data may not be available when stationary or moving very slowly.
  ///
  /// ## Returns
  ///
  /// - `true`: Valid course/heading measurement is available
  /// - `false`: Course data is missing or unreliable
  bool get hasCourse;

  /// Indicates whether course accuracy data is available and valid.
  ///
  /// Course accuracy estimates help determine the reliability of heading
  /// measurements, important for navigation and orientation applications.
  ///
  /// Always `false` on web, as the browser Geolocation API does not report a
  /// course accuracy.
  ///
  /// ## Returns
  ///
  /// - `true`: Valid course accuracy estimate is available
  /// - `false`: Course accuracy data is missing
  bool get hasCourseAccuracy;

  /// Indicates whether horizontal position accuracy data is available and valid.
  ///
  /// Horizontal accuracy estimates help determine the reliability of latitude
  /// and longitude measurements, essential for location-based services.
  ///
  /// ## Returns
  ///
  /// - `true`: Valid horizontal accuracy estimate is available
  /// - `false`: Horizontal accuracy data is missing
  bool get hasHorizontalAccuracy;

  /// Indicates whether vertical position accuracy data is available and valid.
  ///
  /// Vertical accuracy estimates help determine the reliability of altitude
  /// measurements, useful for elevation-aware applications.
  ///
  /// ## Returns
  ///
  /// - `true`: Valid vertical accuracy estimate is available
  /// - `false`: Vertical accuracy data is missing
  bool get hasVerticalAccuracy;

  /// Geographical coordinates constructed from position data.
  ///
  /// Creates a [Coordinates] object containing the current [latitude], [longitude],
  /// and [altitude] values. This provides a convenient way to access position
  /// data in a format compatible with other modules of the SDK.
  ///
  /// ## Returns
  ///
  /// - [Coordinates]: Object containing latitude, longitude, and altitude
  ///
  /// ## See also:
  ///
  /// - [Coordinates]: Core geographic coordinate representation
  /// - [hasCoordinates]: Check if coordinate data is valid
  Coordinates get coordinates =>
      Coordinates(latitude: latitude, longitude: longitude, altitude: altitude);
}

/// Enhanced position data with map-matched information and road-specific details.
///
/// [GemImprovedPosition] extends [GemPosition] to provide map-matched position data
/// that has been aligned with digital map information. This process corrects GPS
/// inaccuracies by snapping positions to the nearest logical road location and
/// provides additional context such as speed limits, road characteristics, and
/// terrain information.
///
/// Map matching significantly improves position accuracy and enables advanced
/// features like speed limit warnings, road surface information, and precise
/// navigation guidance.
///
/// ## See also:
///
/// - [GemPosition]: Base position class with raw sensor data
/// - [PositionService.addImprovedPositionListener]: Register for enhanced position updates
/// - [SenseDataFactory.producePosition]: Factory method for creating position instances
///
/// {@category Position}
abstract class GemImprovedPosition extends GemPosition {
  /// Set of road characteristics and modifiers for the current position.
  ///
  /// Provides detailed information about the road segment where the position
  /// is located, including structural features and traffic characteristics.
  /// This data is only available when the position has been successfully
  /// map-matched to road network data.
  ///
  /// ## Returns
  ///
  /// - [Set<RoadModifier>]: Set of road modifiers applicable to the current road segment
  ///
  /// ## See also:
  ///
  /// - [hasRoadLocalization]: Check if road data is available
  Set<RoadModifier> get roadModifiers;

  /// Posted speed limit for the current road segment in meters per second.
  ///
  /// Returns the legal speed limit for the road where the position is located.
  /// Speed limit data comes from map information and may not be available for
  /// all road segments. A value of 0 indicates no speed limit data is available
  /// for the current location.
  ///
  /// Note: Speed limit may be 0 even for map-matched positions if data is
  /// unavailable for the specific road segment or if the position is not
  /// on a mapped road.
  ///
  /// ## Returns
  ///
  /// - [double]: Speed limit in m/s (0 if unavailable)
  ///
  /// ## See also:
  ///
  /// - [speed]: Current vehicle speed for comparison
  /// - [AlarmService]: Service for speed limit warnings
  double get speedLimit;

  /// Indicates whether road localization data is available.
  ///
  /// Road localization occurs when the position has been successfully
  /// map-matched to the road network, enabling access to road-specific
  /// information such as modifiers, speed limits, and road characteristics.
  ///
  /// ## Returns
  ///
  /// - `true`: Position is map-matched with road data available
  /// - `false`: No road localization data available
  ///
  /// ## See also:
  ///
  /// - [roadModifiers]: Access road characteristics when available
  bool get hasRoadLocalization;

  /// Indicates whether terrain elevation and slope data is available.
  ///
  /// Terrain data provides map-based altitude and slope information that
  /// may be more accurate than GPS-derived altitude, particularly in areas
  /// with detailed topographic data.
  ///
  /// ## Returns
  ///
  /// - `true`: Terrain altitude and slope data available
  /// - `false`: No terrain data available
  ///
  /// ## See also:
  ///
  /// - [terrainAltitude]: Map-based altitude measurement
  /// - [terrainSlope]: Current road gradient
  bool get hasTerrainData;

  /// Map-based altitude measurement in meters.
  ///
  /// Provides altitude data derived from digital elevation models and map
  /// data rather than GPS sensors. This value may be more accurate than
  /// GPS altitude, particularly in urban areas or where high-quality
  /// topographic data is available.
  ///
  /// The terrain altitude can be positive (above sea level) or negative
  /// (below sea level) and may differ from the GPS-derived [altitude].
  ///
  /// ## Returns
  ///
  /// - [double]: Terrain altitude in meters (can be negative)
  ///
  /// ## See also:
  ///
  /// - [altitude]: GPS-derived altitude for comparison
  /// - [hasTerrainData]: Check if terrain data is available
  double get terrainAltitude;

  /// Current road gradient in degrees.
  ///
  /// Represents the slope of the road surface at the current position.
  /// Positive values indicate upward slope (ascent), negative values
  /// indicate downward slope (descent), and zero indicates level terrain.
  ///
  /// ## Returns
  ///
  /// - [double]: Slope in degrees (positive for ascent, negative for descent)
  ///
  /// ## See also:
  ///
  /// - [hasTerrainData]: Check if terrain data is available
  /// - [terrainAltitude]: Map-based altitude measurement
  double get terrainSlope;

  /// Detailed address information for the current position.
  ///
  /// Provides comprehensive address details including street names, city,
  /// postal codes, and administrative boundaries. The address is determined
  /// through reverse geocoding of the map-matched position.
  ///
  /// ## Returns
  ///
  /// - [AddressInfo]: Complete address details object
  ///
  /// ## See also:
  ///
  /// - [AddressInfo]: Address information class
  /// - [AddressField]: Available address components
  AddressInfo get address;

  /// Detailed road information with naming and classification.
  ///
  /// Provides a prioritized list of road information including road names,
  /// route numbers, and shield/marker classifications. The list is ordered
  /// by ascending priority, with the most important road information last.
  ///
  /// This information is essential for navigation displays, route guidance,
  /// and road signage representation in user interfaces.
  ///
  /// ## Returns
  ///
  /// - [List<RoadInfo>]: Ordered list of road information (ascending priority)
  ///
  /// ## See also:
  ///
  /// - [RoadInfo]: Road information structure
  /// - [RoadShieldType]: Road classification and shield types
  List<RoadInfo> get roadInfo;
}
