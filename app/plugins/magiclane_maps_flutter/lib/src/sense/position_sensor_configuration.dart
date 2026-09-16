// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Sensor configuration base class
///
/// {@category Sensor Data Source}
class SensorConfiguration {
  SensorConfiguration();

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory SensorConfiguration.fromJson(final Map<String, String> json) {
    final SensorConfiguration config = SensorConfiguration();
    config._config.addAll(json);
    return config;
  }
  final Map<String, String> _config = <String, String>{};

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, String> toJson() {
    return _config;
  }

  /// The sensor frequency
  int? get sensorFrequency {
    final String? number = _config[DSPrefKeys.sensorFrequency];

    if (number == null) {
      return null;
    }

    return int.tryParse(number);
  }

  /// The sensor frequency
  set sensorFrequency(final int? value) {
    if (value != null) {
      _config[DSPrefKeys.sensorFrequency] = value.toString();
    } else {
      _config.remove(DSPrefKeys.sensorFrequency);
    }
  }

  /// The timestamp
  int? get timestamp {
    final String? number = _config[DSPrefKeys.timestamp];

    if (number == null) {
      return null;
    }

    return int.tryParse(number);
  }

  /// The timestamp
  set timestamp(final int? value) {
    if (value != null) {
      _config[DSPrefKeys.timestamp] = value.toString();
    } else {
      _config.remove(DSPrefKeys.timestamp);
    }
  }
}

/// Configuration class for position sensor
///
/// {@category Sensor Data Source}
class PositionSensorConfiguration extends SensorConfiguration {
  PositionSensorConfiguration();

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory PositionSensorConfiguration.fromJson(final Map<String, String> json) {
    final PositionSensorConfiguration config = PositionSensorConfiguration();
    config._config.addAll(json);
    return config;
  }

  /// The position distance filter
  double? get positionDistanceFilter {
    final String? number = _config[DSPrefKeysPosition.positionDistanceFilter];

    if (number == null) {
      return null;
    }

    return double.tryParse(number);
  }

  /// The position distance filter
  set positionDistanceFilter(final double? value) {
    if (value != null) {
      _config[DSPrefKeysPosition.positionDistanceFilter] = value.toString();
    } else {
      _config.remove(DSPrefKeysPosition.positionDistanceFilter);
    }
  }

  /// The position heading angle
  int? get positionHeadingAngle {
    final String? number =
        _config[DSPrefKeysPosition.positionHeadingAngleFilter];

    if (number == null) {
      return null;
    }

    return int.tryParse(number);
  }

  /// The position heading angle
  set positionHeadingAngle(final int? value) {
    if (value != null) {
      _config[DSPrefKeysPosition.positionHeadingAngleFilter] = value.toString();
    } else {
      _config.remove(DSPrefKeysPosition.positionHeadingAngleFilter);
    }
  }

  /// The position accuracy
  PositionAccuracy? get positionAccuracy {
    return PositionAccuracyExtension.fromString(
      _config[DSPrefKeysPosition.positionAccuracy],
    );
  }

  /// The position accuracy
  set positionAccuracy(final PositionAccuracy? value) {
    if (value != null) {
      _config[DSPrefKeysPosition.positionAccuracy] = value.serialize();
    } else {
      _config.remove(DSPrefKeysPosition.positionAccuracy);
    }
  }

  /// The position activity
  PositionActivity? get positionActivity {
    return PositionActivityExtension.fromString(
      _config[DSPrefKeysPosition.positionActivity],
    );
  }

  /// The position activity
  set positionActivity(final PositionActivity? value) {
    if (value != null) {
      _config[DSPrefKeysPosition.positionActivity] = value.serialize();
    } else {
      _config.remove(DSPrefKeysPosition.positionActivity);
    }
  }

  /// Allows background location updates
  bool? get allowsBackgroundLocationUpdates {
    final String? response =
        _config[DSPrefKeysPosition.allowsBackgroundLocationUpdates];

    if (response == null) {
      return null;
    }

    if (response == '1') {
      return true;
    } else {
      return false;
    }
  }

  /// Allows background location updates
  set allowsBackgroundLocationUpdates(final bool? value) {
    if (value != null) {
      _config[DSPrefKeysPosition.allowsBackgroundLocationUpdates] = value
          ? '1'
          : '0';
    } else {
      _config.remove(DSPrefKeysPosition.allowsBackgroundLocationUpdates);
    }
  }

  /// Automatically pauses updates
  bool? get pausesLocationUpdatesAutomatically {
    final String? response =
        _config[DSPrefKeysPosition.pausesLocationUpdatesAutomatically];

    if (response == null) {
      return null;
    }

    if (response == '1') {
      return true;
    } else {
      return false;
    }
  }

  /// Automatically pauses updates
  set pausesLocationUpdatesAutomatically(final bool? value) {
    if (value != null) {
      _config[DSPrefKeysPosition.pausesLocationUpdatesAutomatically] = value
          ? '1'
          : '0';
    } else {
      _config.remove(DSPrefKeysPosition.pausesLocationUpdatesAutomatically);
    }
  }

  /// Improved position default transport mode
  ImprovedPositionDefTransportMode? get improvedPositionDefineTransportMode {
    return ImprovedPositionDefTransportModeExtension.fromString(
      _config[DSPrefKeysPosition.improvedPositionDefTransportMode],
    );
  }

  /// Improved position default transport mode
  set improvedPositionDefineTransportMode(
    final ImprovedPositionDefTransportMode? value,
  ) {
    if (value != null) {
      _config[DSPrefKeysPosition.improvedPositionDefTransportMode] = value
          .serialize();
    } else {
      _config.remove(DSPrefKeysPosition.improvedPositionDefTransportMode);
    }
  }

  /// Improved position update frequency
  int? get improvedPositionUpdateFrequency {
    final String? number =
        _config[DSPrefKeysPosition.improvedPositionUpdateFreq];

    if (number == null) {
      return null;
    }

    return int.tryParse(number);
  }

  /// Improved position update frequency
  set improvedPositionUpdateFrequency(final int? value) {
    if (value != null) {
      _config[DSPrefKeysPosition.improvedPositionUpdateFreq] = value.toString();
    } else {
      _config.remove(DSPrefKeysPosition.improvedPositionUpdateFreq);
    }
  }

  /// Improved position max snap to map link threshold for vehicle
  int? get improvedPositionSnapToMapLinkThresholdVehicle {
    final String? number =
        _config[DSPrefKeysPosition
            .improvedPositionSnapToMapLinkThresholdVehicle];

    if (number == null) {
      return null;
    }

    return int.tryParse(number);
  }

  /// Improved position max snap to map link threshold for vehicle
  set improvedPositionSnapToMapLinkThresholdVehicle(final int? value) {
    if (value != null) {
      _config[DSPrefKeysPosition
          .improvedPositionSnapToMapLinkThresholdVehicle] = value
          .toString();
    } else {
      _config.remove(
        DSPrefKeysPosition.improvedPositionSnapToMapLinkThresholdVehicle,
      );
    }
  }

  /// Improved position max snap to map link threshold for bike
  int? get improvedPositionSnapToMapLinkThresholdBike {
    final String? number =
        _config[DSPrefKeysPosition.improvedPositionSnapToMapLinkThresholdBike];

    if (number == null) {
      return null;
    }

    return int.tryParse(number);
  }

  /// Improved position max snap to map link threshold for bike
  set improvedPositionSnapToMapLinkThresholdBike(final int? value) {
    if (value != null) {
      _config[DSPrefKeysPosition.improvedPositionSnapToMapLinkThresholdBike] =
          value.toString();
    } else {
      _config.remove(
        DSPrefKeysPosition.improvedPositionSnapToMapLinkThresholdBike,
      );
    }
  }

  /// Prefer route snap for improved position
  bool? get improvedPositionPreferRouteSnap {
    final String? response =
        _config[DSPrefKeysPosition.improvedPosPreferRouteSnap];

    if (response == null) {
      return null;
    }

    if (response == '1') {
      return true;
    } else {
      return false;
    }
  }

  /// Prefer route snap for improved position
  set improvedPositionPreferRouteSnap(final bool? value) {
    if (value != null) {
      _config[DSPrefKeysPosition.improvedPosPreferRouteSnap] = value
          ? '1'
          : '0';
    } else {
      _config.remove(DSPrefKeysPosition.improvedPosPreferRouteSnap);
    }
  }

  /// Allow sending re-routing events.
  bool? get allowReroutingEvent {
    final String? response = _config[DSPrefKeysPosition.allowReroutingEvent];

    if (response == null) {
      return null;
    }

    if (response == '1') {
      return true;
    } else {
      return false;
    }
  }

  /// Allow sending re-routing events.
  set allowReroutingEvent(final bool? value) {
    if (value != null) {
      _config[DSPrefKeysPosition.allowReroutingEvent] = value ? '1' : '0';
    } else {
      _config.remove(DSPrefKeysPosition.allowReroutingEvent);
    }
  }
}

/// Keys for DataSource sensors configuration.
///
/// {@category Sensor Data Source}
abstract class DSPrefKeys {
  /// Invalid value
  static const String invalidValue = '-1';

  /// Invalid value as an integer.
  static const int invalidValueInt = -1;

  /// Sensor frequency key.
  static const String sensorFrequency = 'frequency';

  /// Timestamp key.
  static const String timestamp = 'timestamp';

  /// Value when no data is available.
  static const String valueWhenNoData = 'valWhenNoData';
}

/// Keys for DataSource position sensors configuration.
///
/// {@category Sensor Data Source}
abstract class DSPrefKeysPosition {
  /// Position distance filter key.
  static const String positionDistanceFilter = 'pos_distance';

  /// Position heading angle filter key.
  static const String positionHeadingAngleFilter = 'pos_heading_angle';

  /// Position accuracy key.
  static const String positionAccuracy = 'pos_accuracy';

  /// Position activity key.
  static const String positionActivity = 'pos_activity';

  /// Allows background location updates key.
  static const String allowsBackgroundLocationUpdates =
      'allowsBackgroundLocationUpdates';

  /// Pauses location updates automatically key.
  static const String pausesLocationUpdatesAutomatically =
      'pausesLocationUpdatesAutomatically';

  /// Improved position update frequency key.
  /// Higher frequency provides smoother positions but increases CPU and battery usage.
  static const String improvedPositionUpdateFreq = 'improvedPositionUpdateFreq';

  /// Improved position default transport mode key.
  /// Values: "car", "truck", "bike/bicycle", "pedestrian", "auto".
  /// Default transport mode roads are preferred by the improved position engine.
  /// If set to auto, the default transport mode is automatically detected.
  static const String improvedPositionDefTransportMode =
      'improvedPositionDefTransportMode';

  /// Threshold for snapping to map link data (vehicle).
  /// Default 50 meters.
  /// If position is close to a map link at a smaller distance than this value, the improved position will automatically snap to the map link.
  /// 0 means never snap to map data.
  static const String improvedPositionSnapToMapLinkThresholdVehicle =
      'snapToMapLinkThreshold_Vehicle';

  /// Threshold for snapping to map link data (bike).
  /// Default 50 meters.
  /// If position is close to a map link at a smaller distance than this value, the improved position will automatically snap to the map link.
  /// 0 means never snap to map data.
  static const String improvedPositionSnapToMapLinkThresholdBike =
      'snapToMapLinkThreshold_Bike';

  /// Whether to snap to the route (instead of the most probable link).
  /// If `true`, the arrow will always snap to the route (if the route exists, and the distance is within the "snapToMapLinkThreshold").
  /// If `false`, it will snap to the most probable map link, which is not necessarily the route link.
  /// This is only for display; does not affect the matching and guidance algorithm.
  static const String improvedPosPreferRouteSnap = 'preferRouteSnap';

  /// Allow sending re-routing events.
  /// Default is 1
  /// If 1, the route attached to the data source will receive "leaving route" events and will automatically update
  /// If 0, the route attached to the data source will not receive "leaving route" events and will not automatically update
  static const String allowReroutingEvent = 'allowReroutingEvent';
}

/// Default transport mode for improved position
///
/// {@category Sensor Data Source}
enum ImprovedPositionDefTransportMode {
  /// Automatic
  auto,

  /// Car
  car,

  /// Pedestrian
  pedestrian,

  /// Bike
  bike,

  /// Truck
  truck,
}

/// @nodoc
extension ImprovedPositionDefTransportModeExtension
    on ImprovedPositionDefTransportMode {
  String serialize() {
    switch (this) {
      case ImprovedPositionDefTransportMode.auto:
        return 'auto';
      case ImprovedPositionDefTransportMode.car:
        return 'car';
      case ImprovedPositionDefTransportMode.pedestrian:
        return 'pedestrian';
      case ImprovedPositionDefTransportMode.bike:
        return 'bike';
      case ImprovedPositionDefTransportMode.truck:
        return 'truck';
    }
  }

  static ImprovedPositionDefTransportMode? fromString(final String? accuracy) {
    if (accuracy == null) {
      return null;
    }
    switch (accuracy.toLowerCase()) {
      case 'car':
        return ImprovedPositionDefTransportMode.car;
      case 'truck':
        return ImprovedPositionDefTransportMode.truck;
      case 'bike':
        return ImprovedPositionDefTransportMode.bike;
      case 'pedestrian':
        return ImprovedPositionDefTransportMode.pedestrian;
      case 'auto':
        return ImprovedPositionDefTransportMode.auto;
      default:
        return null;
    }
  }
}

/// The position accuracy
///
/// {@category Sensor Data Source}
enum PositionAccuracy {
  /// Unknown accuracy
  unknown,

  /// Every second
  everySecond,

  /// Only when moving
  whenMoving,

  /// Nearest 10 meters
  nearestTenMeters,

  /// Nearest 1000 meters
  hundredMeters,

  /// Nearest kilometer
  kilometer,
}

/// @nodoc
extension PositionAccuracyExtension on PositionAccuracy {
  String serialize() {
    switch (this) {
      case PositionAccuracy.unknown:
        return '0';
      case PositionAccuracy.everySecond:
        return '1';
      case PositionAccuracy.whenMoving:
        return '2';
      case PositionAccuracy.nearestTenMeters:
        return '3';
      case PositionAccuracy.hundredMeters:
        return '4';
      case PositionAccuracy.kilometer:
        return '5';
    }
  }

  static PositionAccuracy? fromString(final String? accuracy) {
    if (accuracy == null) {
      return null;
    }
    switch (accuracy) {
      case '0':
        return PositionAccuracy.unknown;
      case '1':
        return PositionAccuracy.everySecond;
      case '2':
        return PositionAccuracy.whenMoving;
      case '3':
        return PositionAccuracy.nearestTenMeters;
      case '4':
        return PositionAccuracy.hundredMeters;
      case '5':
        return PositionAccuracy.kilometer;
      default:
        return null;
    }
  }
}

/// The position activity
///
/// {@category Sensor Data Source}
enum PositionActivity {
  /// Unknown activity
  unknown,

  /// Other activity
  other,

  /// Automotive activity
  automotive,

  /// Pedestrian activity
  pedestrian,

  /// Other navigation activity
  otherNavigation,
}

/// @nodoc
extension PositionActivityExtension on PositionActivity {
  String serialize() {
    switch (this) {
      case PositionActivity.unknown:
        return '0';
      case PositionActivity.other:
        return '1';
      case PositionActivity.automotive:
        return '2';
      case PositionActivity.pedestrian:
        return '3';
      case PositionActivity.otherNavigation:
        return '4';
    }
  }

  static PositionActivity? fromString(final String? activity) {
    if (activity == null) {
      return null;
    }
    switch (activity) {
      case '0':
        return PositionActivity.unknown;
      case '1':
        return PositionActivity.other;
      case '2':
        return PositionActivity.automotive;
      case '3':
        return PositionActivity.pedestrian;
      case '4':
        return PositionActivity.otherNavigation;
      default:
        return null;
    }
  }
}
