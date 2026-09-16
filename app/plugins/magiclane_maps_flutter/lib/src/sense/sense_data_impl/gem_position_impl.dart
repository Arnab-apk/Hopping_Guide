import 'package:flutter/foundation.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/position.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/sense_data_impl.dart';

/// @nodoc
class GemPositionImpl extends SenseDataImpl implements GemPosition {
  GemPositionImpl({
    required super.type,
    required super.acquisitionTime,
    required this.satelliteTime,
    required this.provider,
    required this.fixQuality,
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.speed,
    required this.speedAccuracy,
    required this.course,
    required this.courseAccuracy,
    required this.accuracyH,
    required this.accuracyV,
    required this.hasCoordinates,
    required this.hasAltitude,
    required this.hasSpeed,
    required this.hasSpeedAccuracy,
    required this.hasCourse,
    required this.hasCourseAccuracy,
    required this.hasHorizontalAccuracy,
    required this.hasVerticalAccuracy,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory GemPositionImpl.fromJson(final Map<String, dynamic> json) {
    return GemPositionImpl(
      type: DataTypeExtension.fromId(json['senseDataType']),
      acquisitionTime: DateTime.fromMillisecondsSinceEpoch(
        json['acquisitionTimestamp'],
        isUtc: true,
      ),
      satelliteTime: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'],
        isUtc: true,
      ),
      provider: ProviderExtension.fromId(json['provider']),
      fixQuality: PositionQualityExtension.fromId(json['fix']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      altitude: json['alt'],
      speed: json['speed'],
      speedAccuracy: json['speedAccuracy'],
      course: json['course'],
      courseAccuracy: json['courseAccuracy'],
      accuracyH: json['accuracyH'],
      accuracyV: json['accuracyV'],
      hasCoordinates: json['hasCoordinates'],
      hasAltitude: json['hasAltitude'],
      hasSpeed: json['hasSpeed'],
      hasSpeedAccuracy: json['hasSpeedAccuracy'],
      hasCourse: json['hasCourse'],
      hasCourseAccuracy: json['hasCourseAccuracy'],
      hasHorizontalAccuracy: json['hasHorizontalAccuracy'],
      hasVerticalAccuracy: json['hasVerticalAccuracy'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['senseDataType'] = type.id;
    json['acquisitionTimestamp'] = acquisitionTime.millisecondsSinceEpoch;

    json['timestamp'] = satelliteTime.millisecondsSinceEpoch;
    json['provider'] = provider.id;
    json['fix'] = fixQuality.id;
    json['latitude'] = latitude;
    json['longitude'] = longitude;
    json['alt'] = altitude;
    json['speed'] = speed;
    json['speedAccuracy'] = speedAccuracy;
    json['course'] = course;
    json['courseAccuracy'] = courseAccuracy;
    json['accuracyH'] = accuracyH;
    json['accuracyV'] = accuracyV;
    json['hasCoordinates'] = hasCoordinates;
    json['hasAltitude'] = hasAltitude;
    json['hasSpeed'] = hasSpeed;
    json['hasSpeedAccuracy'] = hasSpeedAccuracy;
    json['hasCourse'] = hasCourse;
    json['hasCourseAccuracy'] = hasCourseAccuracy;
    json['hasHorizontalAccuracy'] = hasHorizontalAccuracy;
    json['hasVerticalAccuracy'] = hasVerticalAccuracy;

    return json;
  }

  @override
  double accuracyH;

  @override
  double accuracyV;

  @override
  double altitude;

  @override
  double course;

  @override
  double courseAccuracy;

  @override
  bool hasAltitude;

  @override
  bool hasCoordinates;

  @override
  bool hasCourse;

  @override
  bool hasCourseAccuracy;

  @override
  bool hasHorizontalAccuracy;

  @override
  bool hasSpeed;

  @override
  bool hasSpeedAccuracy;

  @override
  bool hasVerticalAccuracy;

  @override
  double latitude;

  @override
  double longitude;

  @override
  Provider provider;

  @override
  PositionQuality fixQuality;

  @override
  DateTime satelliteTime;

  @override
  double speed;

  @override
  double speedAccuracy;

  @override
  Coordinates get coordinates =>
      Coordinates(latitude: latitude, longitude: longitude, altitude: altitude);

  @override
  bool operator ==(covariant final GemPosition other) {
    return latitude == other.latitude &&
        longitude == other.longitude &&
        altitude == other.altitude &&
        speed == other.speed &&
        speedAccuracy == other.speedAccuracy &&
        course == other.course &&
        courseAccuracy == other.courseAccuracy &&
        accuracyH == other.accuracyH &&
        accuracyV == other.accuracyV &&
        hasCoordinates == other.hasCoordinates &&
        hasAltitude == other.hasAltitude &&
        hasSpeed == other.hasSpeed &&
        hasSpeedAccuracy == other.hasSpeedAccuracy &&
        hasCourse == other.hasCourse &&
        hasCourseAccuracy == other.hasCourseAccuracy &&
        hasHorizontalAccuracy == other.hasHorizontalAccuracy &&
        hasVerticalAccuracy == other.hasVerticalAccuracy &&
        provider == other.provider &&
        fixQuality == other.fixQuality &&
        satelliteTime.millisecondsSinceEpoch ==
            other.satelliteTime.millisecondsSinceEpoch &&
        acquisitionTime.millisecondsSinceEpoch ==
            other.acquisitionTime.millisecondsSinceEpoch;
  }

  @override
  int get hashCode {
    return latitude.hashCode ^
        longitude.hashCode ^
        altitude.hashCode ^
        speed.hashCode ^
        speedAccuracy.hashCode ^
        course.hashCode ^
        courseAccuracy.hashCode ^
        accuracyH.hashCode ^
        accuracyV.hashCode ^
        hasCoordinates.hashCode ^
        hasAltitude.hashCode ^
        hasSpeed.hashCode ^
        hasSpeedAccuracy.hashCode ^
        hasCourse.hashCode ^
        hasCourseAccuracy.hashCode ^
        hasHorizontalAccuracy.hashCode ^
        hasVerticalAccuracy.hashCode ^
        provider.hashCode ^
        fixQuality.hashCode ^
        satelliteTime.millisecondsSinceEpoch.hashCode ^
        acquisitionTime.millisecondsSinceEpoch.hashCode;
  }
}

/// @nodoc
class GemImprovedPositionImpl extends GemPositionImpl
    implements GemImprovedPosition {
  GemImprovedPositionImpl({
    required super.type,
    required super.acquisitionTime,
    required super.satelliteTime,
    required super.provider,
    required super.fixQuality,
    required super.latitude,
    required super.longitude,
    required super.altitude,
    required super.speed,
    required super.speedAccuracy,
    required super.course,
    required super.courseAccuracy,
    required super.accuracyH,
    required super.accuracyV,
    required super.hasCoordinates,
    required super.hasAltitude,
    required super.hasSpeed,
    required super.hasSpeedAccuracy,
    required super.hasCourse,
    required super.hasCourseAccuracy,
    required super.hasHorizontalAccuracy,
    required super.hasVerticalAccuracy,
    required this.address,
    required this.roadModifiers,
    required this.speedLimit,
    required this.roadInfo,
    required this.hasRoadLocalization,
    required this.hasTerrainData,
    required this.terrainAltitude,
    required this.terrainSlope,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory GemImprovedPositionImpl.fromJson(final Map<String, dynamic> json) {
    final int packedRoadModifier = json['roadModifier'];
    final Set<RoadModifier> roadModifiersSet = <RoadModifier>{};
    for (final RoadModifier modifier in RoadModifier.values) {
      if (modifier.id & packedRoadModifier != 0) {
        roadModifiersSet.add(modifier);
      }
    }

    final List<dynamic> roadInfoJson = json['roadInfo'];
    final List<RoadInfo> roadInfoList = roadInfoJson
        .map((dynamic infoJson) => RoadInfo.fromJson(infoJson))
        .toList();

    return GemImprovedPositionImpl(
      type: DataTypeExtension.fromId(json['senseDataType']),
      acquisitionTime: DateTime.fromMillisecondsSinceEpoch(
        json['acquisitionTimestamp'],
        isUtc: true,
      ),
      satelliteTime: DateTime.fromMillisecondsSinceEpoch(
        json['timestamp'],
        isUtc: true,
      ),
      provider: ProviderExtension.fromId(json['provider']),
      fixQuality: PositionQualityExtension.fromId(json['fix']),
      latitude: json['latitude'],
      longitude: json['longitude'],
      altitude: json['alt'],
      speed: json['speed'],
      speedAccuracy: json['speedAccuracy'],
      course: json['course'],
      courseAccuracy: json['courseAccuracy'],
      accuracyH: json['accuracyH'],
      accuracyV: json['accuracyV'],
      hasCoordinates: json['hasCoordinates'],
      hasAltitude: json['hasAltitude'],
      hasSpeed: json['hasSpeed'],
      hasSpeedAccuracy: json['hasSpeedAccuracy'],
      hasCourse: json['hasCourse'],
      hasCourseAccuracy: json['hasCourseAccuracy'],
      hasHorizontalAccuracy: json['hasHorizontalAccuracy'],
      hasVerticalAccuracy: json['hasVerticalAccuracy'],
      address: AddressInfo.fromJson(json['addr']),
      roadModifiers: roadModifiersSet,
      speedLimit: json['roadSpeedLimit'],
      roadInfo: roadInfoList,
      hasRoadLocalization: json['hasRoadLocalization'],
      hasTerrainData: json['hasTerrainData'],
      terrainAltitude: json['terrainAltitude'],
      terrainSlope: json['terrainSlope'],
    );
  }
  @override
  AddressInfo address;

  @override
  bool hasRoadLocalization;

  @override
  bool hasTerrainData;

  @override
  Set<RoadModifier> roadModifiers;

  @override
  double speedLimit;

  @override
  List<RoadInfo> roadInfo;

  @override
  double terrainAltitude;

  @override
  double terrainSlope;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['senseDataType'] = type.id;
    json['acquisitionTimestamp'] = acquisitionTime.millisecondsSinceEpoch;
    json['timestamp'] = satelliteTime.millisecondsSinceEpoch;
    json['provider'] = provider.id;
    json['fix'] = fixQuality.id;
    json['latitude'] = latitude;
    json['longitude'] = longitude;
    json['alt'] = altitude;
    json['speed'] = speed;
    json['speedAccuracy'] = speedAccuracy;
    json['course'] = course;
    json['courseAccuracy'] = courseAccuracy;
    json['accuracyH'] = accuracyH;
    json['accuracyV'] = accuracyV;
    json['hasCoordinates'] = hasCoordinates;
    json['hasAltitude'] = hasAltitude;
    json['hasSpeed'] = hasSpeed;
    json['hasSpeedAccuracy'] = hasSpeedAccuracy;
    json['hasCourse'] = hasCourse;
    json['hasCourseAccuracy'] = hasCourseAccuracy;
    json['hasHorizontalAccuracy'] = hasHorizontalAccuracy;
    json['hasVerticalAccuracy'] = hasVerticalAccuracy;
    json['addr'] = address.toJson();
    json['roadModifier'] = roadModifiers
        .map((final RoadModifier modifier) => modifier.id)
        .reduce((final int a, final int b) => a | b);
    json['roadSpeedLimit'] = speedLimit;
    json['roadInfo'] = roadInfo
        .map((final RoadInfo info) => info.toJson())
        .toList();
    json['hasRoadLocalization'] = hasRoadLocalization;
    json['hasTerrainData'] = hasTerrainData;
    json['terrainAltitude'] = terrainAltitude;
    json['terrainSlope'] = terrainSlope;

    return json;
  }

  @override
  bool operator ==(covariant final GemImprovedPositionImpl other) {
    return super == other &&
        roadModifiers.containsAll(other.roadModifiers) &&
        other.roadModifiers.containsAll(roadModifiers) &&
        speedLimit == other.speedLimit &&
        hasRoadLocalization == other.hasRoadLocalization &&
        hasTerrainData == other.hasTerrainData &&
        terrainAltitude == other.terrainAltitude &&
        terrainSlope == other.terrainSlope &&
        latitude == other.latitude &&
        longitude == other.longitude &&
        altitude == other.altitude &&
        speed == other.speed &&
        speedAccuracy == other.speedAccuracy &&
        course == other.course &&
        courseAccuracy == other.courseAccuracy &&
        accuracyH == other.accuracyH &&
        accuracyV == other.accuracyV &&
        hasCoordinates == other.hasCoordinates &&
        hasAltitude == other.hasAltitude &&
        hasSpeed == other.hasSpeed &&
        hasSpeedAccuracy == other.hasSpeedAccuracy &&
        hasCourse == other.hasCourse &&
        hasCourseAccuracy == other.hasCourseAccuracy &&
        hasHorizontalAccuracy == other.hasHorizontalAccuracy &&
        hasVerticalAccuracy == other.hasVerticalAccuracy &&
        address == other.address &&
        provider == other.provider &&
        fixQuality == other.fixQuality &&
        satelliteTime.millisecondsSinceEpoch ==
            other.satelliteTime.millisecondsSinceEpoch &&
        acquisitionTime.millisecondsSinceEpoch ==
            other.acquisitionTime.millisecondsSinceEpoch;
  }

  @override
  int get hashCode {
    return super.hashCode ^
        roadModifiers.toString().hashCode ^
        speedLimit.hashCode ^
        hasRoadLocalization.hashCode ^
        hasTerrainData.hashCode ^
        terrainAltitude.hashCode ^
        terrainSlope.hashCode ^
        latitude.hashCode ^
        longitude.hashCode ^
        altitude.hashCode ^
        speed.hashCode ^
        speedAccuracy.hashCode ^
        course.hashCode ^
        courseAccuracy.hashCode ^
        accuracyH.hashCode ^
        accuracyV.hashCode ^
        hasCoordinates.hashCode ^
        hasAltitude.hashCode ^
        hasSpeed.hashCode ^
        hasSpeedAccuracy.hashCode ^
        hasCourse.hashCode ^
        hasCourseAccuracy.hashCode ^
        hasHorizontalAccuracy.hashCode ^
        hasVerticalAccuracy.hashCode ^
        address.hashCode ^
        provider.hashCode ^
        fixQuality.hashCode ^
        satelliteTime.hashCode ^
        acquisitionTime.hashCode;
  }
}
