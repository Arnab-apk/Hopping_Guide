// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Structured representation of a junction or turn geometry.
///
/// [AbstractGeometry] models the intersection anchor, driving side and a
/// list of [AbstractGeometryItem] instances that describe how lanes, arrows
/// and other shapes are attached to the anchor. This structure is the
/// machine-readable source used to render a schematic of the junction or to
/// generate the abstract geometry image via [TurnDetails.getAbstractGeometryImage].
///
/// Typical fields include the [anchorType] (point, circle or waypoint), the
/// [driveSide] (left or right), a list of [items], and optional counts for
/// intermediate turns on the left/right side.
///
/// Consumers typically use the [TurnDetails.abstractGeometryImg] property to
/// obtain a ready-to-render image of the entire geometry.
///
/// ## See also:
///
/// - [TurnDetails.abstractGeometry] - The parent turn details object.
/// - [AbstractGeometryItem] - Geometry elements attached to the anchor.
///
/// {@category Images}
class AbstractGeometry {
  /// Creates an [AbstractGeometry] instance.
  ///
  /// API users should typically not create instances directly.
  /// Use [TurnDetails.abstractGeometry] instead.
  ///
  /// ## Parameters
  ///
  /// - [anchorType]: The anchor type for this geometry.
  /// - [driveSide]: The drive side for this geometry.
  /// - [items]: The list of geometry items attached to the anchor.
  /// - [leftIntermediateTurns]: The number of left side intermediate turns.
  /// - [rightIntermediateTurns]: The number of right side intermediate turns.
  AbstractGeometry({
    this.anchorType = AnchorType.point,
    this.driveSide = DriveSide.right,
    this.items = const <AbstractGeometryItem>[],
    this.leftIntermediateTurns = 0,
    this.rightIntermediateTurns = 0,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory AbstractGeometry.fromJson(final Map<String, dynamic> json) {
    return AbstractGeometry(
      anchorType: AnchorTypeExtension.fromId(json['anchortype']),
      driveSide: DriveSideExtension.fromId(json['driveside']),
      items: (json['items'] as List<dynamic>)
          .map(
            (final dynamic item) =>
                AbstractGeometryItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      leftIntermediateTurns: json['leftintermediateturns'],
      rightIntermediateTurns: json['rightintermediateturns'],
    );
  }

  /// Anchor type
  ///
  /// Can be point, circle or waypoint.
  AnchorType anchorType;

  /// Drive side
  ///
  /// Can be left or right.
  DriveSide driveSide;

  /// List of geometry items
  ///
  /// The list of geometry items attached to the anchor.
  List<AbstractGeometryItem> items;

  // Get the number of left side intermediate turns.
  int leftIntermediateTurns;

  // Get the number of right side intermediate turns.
  int rightIntermediateTurns;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['anchortype'] = anchorType.id;
    json['driveside'] = driveSide.id;
    json['items'] = items;
    json['leftintermediateturns'] = leftIntermediateTurns;
    json['rightintermediateturns'] = rightIntermediateTurns;
    return json;
  }
}

/// Anchor type for an abstract geometry.
///
/// The anchor describes the central feature of the junction geometry. It
/// can be a single point (regular intersection), a circle (roundabout or
/// similar feature) or a waypoint marker. Anchor type influences how slot
/// indices and circle segments are interpreted.
///
/// ## See also:
///
/// - [AbstractGeometry.anchorType] - The anchor type of the geometry.
///
/// {@category Images}
enum AnchorType {
  /// Point
  point,

  /// Circle
  circle,

  /// Waypoint
  waypoint,
}

/// @nodoc
extension AnchorTypeExtension on AnchorType {
  int get id {
    switch (this) {
      case AnchorType.point:
        return 0;
      case AnchorType.circle:
        return 1;
      case AnchorType.waypoint:
        return 2;
    }
  }

  static AnchorType fromId(final int id) {
    switch (id) {
      case 0:
        return AnchorType.point;
      case 1:
        return AnchorType.circle;
      case 2:
        return AnchorType.waypoint;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Drive side used to render side-dependent geometry.
///
/// Indicates whether traffic uses the left or right side of the road. This
/// affects the orientation of certain shapes (for example U-turns and
/// roundabout traversal direction) when converting abstract geometry to a
/// visual representation.
///
/// ## See also:
///
/// - [AbstractGeometry.driveSide] - The drive side of the geometry.
///
/// {@category Images}
enum DriveSide {
  /// Left
  left,

  /// Right
  right,
}

/// @nodoc
extension DriveSideExtension on DriveSide {
  int get id {
    switch (this) {
      case DriveSide.left:
        return 0;
      case DriveSide.right:
        return 1;
    }
  }

  static DriveSide fromId(final int id) {
    switch (id) {
      case 0:
        return DriveSide.left;
      case 1:
        return DriveSide.right;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
