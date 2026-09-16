// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Surface section describing surface type changes along the route.
///
/// Sections are ordered from route start to end. Use
/// [RouteTerrainProfile.surfaceSections] to obtain the list.
///
/// The end of a section is the start of the next section or the route end.
///
/// ## Also see:
///
/// - [RouteTerrainProfile.surfaceSections] - Surface sections for a route
/// - [SurfaceType] - Surface material/type values
///
/// {@category Route}
class SurfaceSection {
  /// Creates a surface section.
  ///
  /// Usually the API user does not create instances directly.
  ///
  /// ## Parameters
  ///
  /// - [startDistanceM]: Distance in meters where the section starts.
  /// - [type]: The [SurfaceType] for this section.
  SurfaceSection({required this.startDistanceM, required this.type});

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory SurfaceSection.fromJson(final Map<String, dynamic> json) {
    return SurfaceSection(
      startDistanceM: json['startDistanceM'],
      type: SurfaceTypeExtension.fromId(json['type']),
    );
  }

  /// Distance in meters where the section starts.
  ///
  /// The end of the section is the start of the next section or the route end.
  int startDistanceM;

  /// The type of surface for this section.
  SurfaceType type;

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
  bool operator ==(covariant final SurfaceSection other) {
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

/// Surface material/type for a route segment.
///
/// Use these values when inspecting [SurfaceSection] entries returned by
/// [RouteTerrainProfile.surfaceSections].
///
/// ## Also see:
///
/// - [SurfaceSection] - Surface section describing a route segment
///
/// {@category Route}
enum SurfaceType {
  /// Asphalt surface (typical roads).
  asphalt,

  /// Paved (but not standard asphalt) — e.g., concrete or block paving.
  paved,

  /// Unpaved surfaces (gravel, dirt, etc.).
  unpaved,

  /// Unknown or unclassified surface.
  unknown,
}

/// @nodoc
extension SurfaceTypeExtension on SurfaceType {
  int get id {
    switch (this) {
      case SurfaceType.asphalt:
        return 0;
      case SurfaceType.paved:
        return 1;
      case SurfaceType.unpaved:
        return 2;
      case SurfaceType.unknown:
        return 3;
    }
  }

  static SurfaceType fromId(final int id) {
    switch (id) {
      case 0:
        return SurfaceType.asphalt;
      case 1:
        return SurfaceType.paved;
      case 2:
        return SurfaceType.unpaved;
      case 3:
        return SurfaceType.unknown;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
