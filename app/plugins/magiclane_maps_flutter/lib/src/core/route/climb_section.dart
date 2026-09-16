// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Climb section describing an ascending segment of the route.
///
/// A climb section contains the start/end distances (meters), the average
/// slope and a [Grade] classification. These objects are returned by
/// [RouteTerrainProfile.climbSections].
///
/// ## Example
///
/// ```dart
/// for (final ClimbSection c in profile.climbSections) {
///   print('Climb ${c.grade} from ${c.startDistanceM} to ${c.endDistanceM}');
/// }
/// ```
///
/// ## Also see:
///
/// - [RouteTerrainProfile.climbSections] - List of climb sections for a route
/// - [Grade] - Climb difficulty categories
///
/// {@category Route}
class ClimbSection {
  /// Creates a climb section.
  ///
  /// Usually the API user does not create instances directly.
  ///
  /// ## Parameters
  ///
  /// - [startDistanceM]: Distance in meters where this section starts.
  /// - [endDistanceM]: Distance in meters where this section ends.
  /// - [slope]: Average slope for the section (percent or fraction as used by the SDK).
  /// - [grade]: The difficulty [Grade] for this section.
  ClimbSection({
    required this.startDistanceM,
    required this.endDistanceM,
    required this.slope,
    required this.grade,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory ClimbSection.fromJson(final Map<String, dynamic> json) {
    return ClimbSection(
      startDistanceM: json['startDistanceM'],
      endDistanceM: json['endDistanceM'],
      slope: json['slope'],
      grade: GradeExtension.fromId(json['grade']),
    );
  }

  /// Distance in meters where this section starts.
  int startDistanceM;

  /// Distance in meters where this section ends.
  int endDistanceM;

  /// Average slope for the section (percent or fraction as used by the SDK).
  double slope;

  /// The difficulty grade for this climb section.
  Grade grade;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['startDistanceM'] = startDistanceM;
    json['endDistanceM'] = endDistanceM;
    json['slope'] = slope;
    json['grade'] = grade.id;
    return json;
  }

  @override
  bool operator ==(covariant final ClimbSection other) {
    if (identical(this, other)) {
      return true;
    }

    return other.startDistanceM == startDistanceM &&
        other.endDistanceM == endDistanceM &&
        other.slope == slope &&
        other.grade == grade;
  }

  @override
  int get hashCode {
    return startDistanceM.hashCode ^
        endDistanceM.hashCode ^
        slope.hashCode ^
        grade.hashCode;
  }
}

/// Climb difficulty categories (UCI-based).
///
/// These grades classify climb difficulty from most to least difficult.
///
/// ## Values
/// - [gradeHC]: Hors catégorie — the most difficult climbs.
/// - [grade1]: Category 1.
/// - [grade2]: Category 2.
/// - [grade3]: Category 3.
/// - [grade4]: Category 4 — least difficult in this scale.
///
/// Returned by [ClimbSection.grade].
///
/// ## Also see:
///
/// - [ClimbSection] - Climb section describing an ascending segment of the route
///
/// {@category Route}
enum Grade {
  /// Hors catégorie (most difficult)
  gradeHC,

  /// Category 1
  grade1,

  /// Category 2
  grade2,

  /// Category 3
  grade3,

  /// Category 4 (least difficult)
  grade4,
}

/// @nodoc
extension GradeExtension on Grade {
  int get id {
    switch (this) {
      case Grade.gradeHC:
        return 0;
      case Grade.grade1:
        return 1;
      case Grade.grade2:
        return 2;
      case Grade.grade3:
        return 3;
      case Grade.grade4:
        return 4;
    }
  }

  static Grade fromId(final int id) {
    switch (id) {
      case 0:
        return Grade.gradeHC;
      case 1:
        return Grade.grade1;
      case 2:
        return Grade.grade2;
      case 3:
        return Grade.grade3;
      case 4:
        return Grade.grade4;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
