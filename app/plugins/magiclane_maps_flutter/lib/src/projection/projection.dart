// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Base class for map projections.
///
/// Common base type for all projection representations used by the SDK.
/// Subclasses represent specific coordinate systems (UTM, BNG, WGS84, etc.)
/// and provide type-specific accessors and mutators.
///
/// ## See also:
///
/// - [ProjectionService] — Utilities to convert between projection types.
/// - [BNGProjection] — British National Grid projection.
/// - [GKProjection] — Gauss-Krüger (Grid) projection.
/// - [UTMProjection] — Universal Transverse Mercator projection.
/// - [MGRSProjection] — Military Grid Reference System projection.
/// - [WGS84Projection] — WGS84 geographic coordinate projection.
///
/// {@category Projections}
class Projection extends GemAutoreleaseObject {
  // ignore: unused_element
  Projection._() : super(-1);

  @internal
  Projection.init(super.id);

  /// The projection type for this instance.
  ///
  /// Returns the specific [ProjectionType] that identifies the concrete
  /// projection subclass represented by this object.
  ///
  /// ## Returns
  ///
  /// - (ProjectionType) The projection type enumeration value.
  ProjectionType get type {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection',
      'type',
    );

    return ProjectionTypeExtension.fromId(resultString['result']);
  }
}

/// The map projection type
///
/// {@category Projections}
enum ProjectionType {
  /// British National Grid (BNG)
  bng,

  /// Lambert 93 (LAM)
  lam,

  /// Universal Transverse Mercator (UTM)
  utm,

  /// Military Grid Reference System (MGRS)
  mgrs,

  /// Gauss-Krüger (GK)
  gk,

  /// World Geodetic System (WGS84)
  wgs84,

  /// What3Words (W3W)
  w3w,

  /// Undefined
  undefined,
}

/// @nodoc
extension ProjectionTypeExtension on ProjectionType {
  int get id {
    switch (this) {
      case ProjectionType.bng:
        return 0;
      case ProjectionType.lam:
        return 1;
      case ProjectionType.utm:
        return 2;
      case ProjectionType.mgrs:
        return 3;
      case ProjectionType.gk:
        return 4;
      case ProjectionType.wgs84:
        return 5;
      case ProjectionType.w3w:
        return 6;
      case ProjectionType.undefined:
        return 7;
    }
  }

  static ProjectionType fromId(final int id) {
    switch (id) {
      case 0:
        return ProjectionType.bng;
      case 1:
        return ProjectionType.lam;
      case 2:
        return ProjectionType.utm;
      case 3:
        return ProjectionType.mgrs;
      case 4:
        return ProjectionType.gk;
      case 5:
        return ProjectionType.wgs84;
      case 6:
        return ProjectionType.w3w;
      case 7:
        return ProjectionType.undefined;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
