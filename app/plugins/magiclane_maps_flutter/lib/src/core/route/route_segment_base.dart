// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/routing/toll_section.dart';
import 'package:meta/meta.dart';

/// A contiguous portion of a computed route between two waypoints.
///
/// [RouteSegmentBase] exposes geometry, metrics (time/distance), geographic bounds and a list of
/// [RouteInstruction] objects for the segment.
///
/// It is an abstract base implemented by concrete segment
/// classes such as [RouteSegment] and [PTRouteSegment]. Obtain segment instances via [RouteBase.segments].
///
/// ## See also:
///
/// - [RouteBase.segments] - Obtain segments from a route.
/// - [RouteInstruction] - Instructions within a segment.
///
/// {@category Route}
abstract class RouteSegmentBase extends GemAutoreleaseObject {
  // ignore: unused_element
  RouteSegmentBase._() : super(-1);

  @internal
  RouteSegmentBase.init(super.id);

  /// List containing the segment's start, end and any intermediate waypoints.
  ///
  /// ## Returns
  ///
  /// - `List<Landmark>`: waypoints that define the segment (start, end and intermediates).
  List<Landmark> get waypoints {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteSegmentBase',
      'getWaypoints',
    );

    return LandmarkList.init(resultString['result']).toList();
  }

  /// Duration and distance metrics for this segment.
  ///
  /// ## Returns
  ///
  /// - [TimeDistance]: total distance (meters) and estimated travel time (seconds) for the segment.
  TimeDistance get timeDistance {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteSegmentBase',
      'getTimeDistance',
    );

    return TimeDistance.fromJson(resultString['result']);
  }

  /// Geographic bounding rectangle that encloses this segment.
  ///
  /// The geographic area is the smallest axis-aligned rectangle that encloses the segment geometry.
  ///
  /// ## Returns
  ///
  /// - [RectangleGeographicArea]: bounding rectangle for the segment.
  RectangleGeographicArea get geographicArea {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteSegmentBase',
      'getGeographicArea',
    );

    return RectangleGeographicArea.fromJson(resultString['result']);
  }

  /// Whether traveling this segment may incur monetary costs (for example tolls).
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when the segment includes paid sections; otherwise `false`.
  bool get incursCosts {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteSegmentBase',
      'getIncursCosts',
    );

    return resultString['result'];
  }

  /// Short textual summary of the segment (distance/time snippet).
  ///
  /// Is influenced by the current SDK language setting.
  ///
  /// ## Returns
  ///
  /// - `String`: human-readable summary for this segment.
  String get summary {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteSegmentBase',
      'getSummary',
    );

    return resultString['result'];
  }

  /// Turn-by-turn instructions for this segment.
  ///
  /// Used for display on UI. Not intended for real-time navigation, for which use [NavigationInstruction].
  ///
  /// ## Returns
  ///
  /// - `List<RouteInstruction>`: instructions ordered along the segment for guidance and UI display.
  ///
  /// ## See also:
  ///
  /// - [NavigationInstruction] - for real-time navigation instructions.
  List<RouteInstruction> get instructions {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteSegmentBase',
      'getInstructions',
    );

    return RouteInstructionList.init(resultString['result']).toList();
  }

  /// Whether this segment is of the same travel mode as the parent route.
  ///
  /// A segment is not common when its travel mode differs from the route (for example a walk segment
  /// inside a public transport route).
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when the segment travel mode matches the route's travel mode; `false` otherwise.
  bool get isCommon {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteSegmentBase',
      'isCommon',
    );

    return resultString['result'];
  }

  /// Tolled sections contained in this segment.
  ///
  /// ## Returns
  ///
  /// - `List<TollSection>`: list of tolled sections with start/end distances, cost and currency.
  List<TollSection> get tollSections {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteSegmentBase',
      'getTollSections',
    );

    final List<dynamic> tollSectionsJson = resultString['result'];

    return tollSectionsJson
        .map((final dynamic e) => TollSection.fromJson(e))
        .toList();
  }

  /// Restricted sections contained in this segment.
  ///
  /// Each [RestrictionSection] describes a portion of the segment subject to
  /// one or more [RouteRestrictionType] flags (for example access
  /// restrictions, transport-mode restrictions or vehicle-attribute
  /// restrictions).
  ///
  /// ## Returns
  ///
  /// - `List<RestrictionSection>`: list of restricted sections with start/end
  ///   distances and the applicable restriction bitmask. Empty when the
  ///   segment has no restrictions.
  ///
  /// ## See also:
  ///
  /// - [RouteRestrictionType] - The kinds of restrictions that can apply.
  /// - [RouteBase.restrictionSections] - Restriction sections for the entire route.
  List<RestrictionSection> get restrictionSections {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteSegmentBase',
      'getRestrictionSections',
    );

    final List<dynamic> restrictionSectionsJson = resultString['result'];

    return restrictionSectionsJson
        .map((final dynamic e) => RestrictionSection.fromJson(e))
        .toList();
  }
}
