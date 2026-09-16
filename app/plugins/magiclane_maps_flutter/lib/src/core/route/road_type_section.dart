// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Road classification for a route section.
///
/// Use these values when iterating [RoadTypeSection] entries returned by
/// [RouteTerrainProfile.roadTypeSections].
///
/// ## Also see:
///
/// - [RoadTypeSection] - Road type section describing a route segment
///
/// {@category Route}
enum RoadType {
  /// Motorways
  motorways,

  /// State road
  stateRoad,

  /// Road
  road,

  /// Street
  street,

  /// Cycleway
  cycleway,

  /// Path
  path,

  /// Single track
  singleTrack,
}

/// @nodoc
extension RoadTypeExtension on RoadType {
  int get id {
    switch (this) {
      case RoadType.motorways:
        return 0;
      case RoadType.stateRoad:
        return 1;
      case RoadType.road:
        return 2;
      case RoadType.street:
        return 3;
      case RoadType.cycleway:
        return 4;
      case RoadType.path:
        return 5;
      case RoadType.singleTrack:
        return 6;
    }
  }

  static RoadType fromId(final int id) {
    switch (id) {
      case 0:
        return RoadType.motorways;
      case 1:
        return RoadType.stateRoad;
      case 2:
        return RoadType.road;
      case 3:
        return RoadType.street;
      case 4:
        return RoadType.cycleway;
      case 5:
        return RoadType.path;
      case 6:
        return RoadType.singleTrack;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Road type section describing the classification of the road for a segment.
///
/// Sections are ordered from route start to end. Use
/// [RouteTerrainProfile.roadTypeSections] to obtain these entries.
///
/// The end of a section is the start of the next section or the route end.
///
/// ## Also see:
///
/// - [RouteTerrainProfile.roadTypeSections] - Road type sections for a route
/// - [RoadType] - Road classification values
///
/// {@category Route}
class RoadTypeSection {
  /// Creates a road type section.
  ///
  /// Usually the API user does not create instances directly.
  ///
  /// ## Parameters
  ///
  /// - [startDistanceM]: Distance in meters where the section starts.
  /// - [type]: The [RoadType] for this section.
  RoadTypeSection({required this.startDistanceM, required this.type});

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory RoadTypeSection.fromJson(final Map<String, dynamic> json) {
    return RoadTypeSection(
      startDistanceM: json['startDistanceM'],
      type: RoadTypeExtension.fromId(json['type']),
    );
  }

  /// Distance in meters where the section starts.
  ///
  /// The end of the section is the start of the next section or the route end.
  int startDistanceM;

  /// The road type for this section.
  RoadType type;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['startDistanceM'] = startDistanceM;
    json['type'] = type.id;
    return json;
  }

  @override
  bool operator ==(covariant final RoadTypeSection other) {
    if (identical(this, other)) {
      return true;
    }

    return other.startDistanceM == startDistanceM && other.type == type;
  }

  @override
  int get hashCode {
    return startDistanceM.hashCode ^ type.hashCode;
  }
}
