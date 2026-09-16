// SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/src/routing/routing_enums.dart';
import 'package:meta/meta.dart';

/// Represents a restricted portion of a route.
///
/// A [RestrictionSection] models a contiguous part of a route to which one or
/// more [RouteRestrictionType] flags apply (for example a private road, a
/// section that violates the vehicle's height/weight profile, or a stretch
/// that conflicts with user avoid preferences).
///
/// Distances are measured in meters from the start of the route. The set of
/// applicable restrictions is exposed as [restrictions], a strongly-typed
/// `Set<RouteRestrictionType>`.
///
/// Obtain restriction sections from a computed route via
/// [RouteBase.restrictionSections] or from a specific segment via
/// [RouteSegmentBase.restrictionSections].
///
/// API users should not create instances of this class directly.
///
/// ## See also:
///
/// - [RouteBase.restrictionSections] - Retrieve restriction sections for a route.
/// - [RouteSegmentBase.restrictionSections] - Retrieve restriction sections for a segment.
/// - [RouteRestrictionType] - Enumeration of restriction kinds.
/// - [NavigationInstruction.currentRestrictions] - Set of restrictions active
///   at the current position during navigation.
/// - [TurnDetails.restrictions] - Set of restrictions associated with a turn.
///
/// {@category Route}
class RestrictionSection {
  /// Creates a [RestrictionSection].
  ///
  /// Constructs a restriction section describing the restricted portion
  /// between two distances measured from the route start.
  ///
  /// API users should not create instances of this class directly.
  ///
  /// ## Parameters
  ///
  /// - [startDistanceM]: Distance in meters from the route start where the
  ///   restriction section begins. Defaults to `0`.
  /// - [endDistanceM]: Distance in meters from the route start where the
  ///   restriction section ends. Defaults to `0`.
  /// - [restrictions]: Set of [RouteRestrictionType] values describing the
  ///   restrictions applied to this section. Defaults to an empty set.
  RestrictionSection({
    this.startDistanceM = 0,
    this.endDistanceM = 0,
    final Set<RouteRestrictionType>? restrictions,
  }) : restrictions = restrictions ?? <RouteRestrictionType>{};

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory RestrictionSection.fromJson(final Map<String, dynamic> json) {
    final int mask = json['restrictions'] ?? 0;
    final Set<RouteRestrictionType> restrictions = <RouteRestrictionType>{};
    for (final RouteRestrictionType value in RouteRestrictionType.values) {
      if (mask & value.id != 0) {
        restrictions.add(value);
      }
    }

    return RestrictionSection(
      startDistanceM: json['startDistanceM'],
      endDistanceM: json['endDistanceM'],
      restrictions: restrictions,
    );
  }

  /// Distance (meters) from the route start where this restriction section begins.
  ///
  /// ## See also:
  ///
  /// - [RouteBase.getCoordinateOnRoute] - Get coordinates along the route at specific distances.
  /// - [endDistanceM] - Distance where the restriction section ends.
  int startDistanceM;

  /// Distance (meters) from the route start where this restriction section ends.
  ///
  /// ## See also:
  ///
  /// - [RouteBase.getCoordinateOnRoute] - Get coordinates along the route at specific distances.
  /// - [startDistanceM] - Distance where the restriction section begins.
  int endDistanceM;

  /// The [RouteRestrictionType] values applied to this section.
  Set<RouteRestrictionType> restrictions;

  @override
  bool operator ==(covariant final RestrictionSection other) {
    if (identical(this, other)) {
      return true;
    }

    return other.startDistanceM == startDistanceM &&
        other.endDistanceM == endDistanceM &&
        other.restrictions.length == restrictions.length &&
        other.restrictions.containsAll(restrictions);
  }

  @override
  int get hashCode {
    int restrictionsHash = 0;
    for (final RouteRestrictionType r in restrictions) {
      restrictionsHash ^= r.hashCode;
    }
    return startDistanceM.hashCode ^ endDistanceM.hashCode ^ restrictionsHash;
  }
}
