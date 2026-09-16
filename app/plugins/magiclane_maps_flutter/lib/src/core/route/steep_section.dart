// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Steep section indicating an abrupt elevation change category.
///
/// Each section references the index in the user-provided steep category
/// thresholds passed to [RouteTerrainProfile.getSteepSections]. Sections are
/// ordered from route start to end.
///
/// The end of a section is the start of the next section or the route end.
///
/// ## Also see:
///
/// - [RouteTerrainProfile.getSteepSections] - Compute steep sections for a route
///
/// {@category Route}
class SteepSection {
  /// Creates a steep section.
  ///
  /// Usually the API user does not create instances directly.
  ///
  /// ## Parameters
  ///
  /// - [startDistanceM]: Distance in meters where the section starts.
  /// - [categ]: Index into the user-provided steep categories list.
  SteepSection({required this.startDistanceM, required this.categ});

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory SteepSection.fromJson(final Map<String, dynamic> json) {
    return SteepSection(
      startDistanceM: json['startDistanceM'],
      categ: json['categ'],
    );
  }

  /// Distance in meters where the section starts.
  ///
  /// The end of the section is the start of the next section or the route end.
  int startDistanceM;

  /// Index into the user-provided steep categories list (see
  /// [RouteTerrainProfile.getSteepSections]).
  int categ;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['startDistanceM'] = startDistanceM;
    json['categ'] = categ;
    return json;
  }

  @override
  bool operator ==(covariant final SteepSection other) {
    if (identical(this, other)) {
      return true;
    }

    return other.startDistanceM == startDistanceM && other.categ == categ;
  }

  @override
  int get hashCode {
    return startDistanceM.hashCode ^ categ.hashCode;
  }
}
