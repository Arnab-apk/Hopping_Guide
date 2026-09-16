// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Geometry element used by [AbstractGeometry].
///
/// An [AbstractGeometryItem] represents a single drawable element attached to
/// an anchor (for example a lane, arrow or waypoint marker). It contains
/// rendering hints such as arrow presence/direction, the slot indexes where
/// the shape attaches to the anchor, the shape form/type and any traffic
/// restriction metadata.
///
/// Consumers typically use the [TurnDetails.abstractGeometryImg] property to
/// obtain a ready-to-render image of the entire geometry.
///
/// ## See also:
///
/// - [AbstractGeometry.items] — List of geometry items attached to the anchor.
///
/// {@category Images}
class AbstractGeometryItem {
  /// Creates an [AbstractGeometryItem] instance.
  ///
  /// API users should typically not create instances directly.
  /// Use [TurnDetails.abstractGeometry] instead.
  ///
  /// ## Parameters
  ///
  /// - [arrowType]: The arrow type for this geometry item.
  /// - [beginArrowDirection]: The arrow direction at the begin of this geometry item.
  /// - [beginSlot]: The slot index where the shape begin is attached to the anchor.
  /// - [endArrowDirection]: The arrow direction at the end of this geometry item.
  /// - [endSlot]: The slot index where the shape end is attached to the anchor.
  /// - [restrictionType]: The restriction type for this geometry item.
  /// - [shapeForm]: The shape form for this geometry item.
  /// - [shapeType]: The shape type for this geometry item.
  /// - [slotAllocation]: The slot allocation for this geometry item.
  AbstractGeometryItem({
    this.arrowType = ArrowType.none,
    this.beginArrowDirection = ArrowDirection.none,
    this.beginSlot = -1,
    this.endArrowDirection = ArrowDirection.none,
    this.endSlot = -1,
    this.restrictionType = RestrictionType.none,
    this.shapeForm = ShapeForm.line,
    this.shapeType = ShapeType.street,
    this.slotAllocation = 0,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory AbstractGeometryItem.fromJson(final Map<String, dynamic> json) {
    return AbstractGeometryItem(
      arrowType: ArrowTypeExtension.fromId(json['arrowtype']),
      beginArrowDirection: ArrowDirectionExtension.fromId(
        json['beginarrowdirection'],
      ),
      beginSlot: json['beginslot'],
      endArrowDirection: ArrowDirectionExtension.fromId(
        json['endarrowdirection'],
      ),
      endSlot: json['endslot'],
      restrictionType: RestrictionTypeExtension.fromId(json['restrictiontype']),
      shapeForm: ShapeFormExtension.fromId(json['shapeform']),
      shapeType: ShapeTypeExtension.fromId(json['shapetype']),
      slotAllocation: json['slotallocation'],
    );
  }
  // Arrow type
  ArrowType arrowType;

  /// Arrow direction at the begin.
  ArrowDirection beginArrowDirection;

  /// Get the slot the shape begin is attached to the anchor.
  /// The begin slot references the position where the begin shape is attached to the anchor.
  ///
  /// 12 slots are possible, -1 indicates N/A. The numbers indicate position similar to a clock face.
  /// [ShapeForm.circleSegment] follows the circle from begin to end slot, [ShapeForm.line] spans over the
  /// circle from begin to end slot
  int beginSlot;

  /// Arrow direction at the end.
  ArrowDirection endArrowDirection;

  /// Get the slot the shape end is attached to the anchor.
  /// The begin slot references the position where the end shape is attached to the anchor.
  ///
  /// 12 slots are possible, -1 indicates N/A. The numbers indicate position similar to a clock face.
  /// [ShapeForm.circleSegment] follows the circle from begin to end slot, [ShapeForm.line] spans over the
  /// circle from begin to end slot
  int endSlot;

  /// Restriction type.
  RestrictionType restrictionType;

  /// Shape form.
  ///
  /// It can be a line, circle segment or point.
  ShapeForm shapeForm;

  /// Shape type.
  ///
  /// The shape type describes the semantic layer of a geometry item.
  ShapeType shapeType;

  /// Slot allocation.
  ///
  /// The slot allocation indicates how many shapes are occupying a slot. The rendering should reflect this by different dividers.
  int slotAllocation;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['arrowtype'] = arrowType.id;
    json['beginarrowdirection'] = beginArrowDirection.id;
    json['beginslot'] = beginSlot;
    json['endarrowdirection'] = endArrowDirection.id;
    json['endslot'] = endSlot;
    json['restrictiontype'] = restrictionType.id;
    json['shapeform'] = shapeForm.id;
    json['shapetype'] = shapeType.id;
    json['slotallocation'] = slotAllocation;
    return json;
  }

  @override
  bool operator ==(covariant final AbstractGeometryItem other) {
    if (identical(this, other)) {
      return true;
    }
    return arrowType == other.arrowType &&
        beginArrowDirection == other.beginArrowDirection &&
        beginSlot == other.beginSlot &&
        endArrowDirection == other.endArrowDirection &&
        endSlot == other.endSlot &&
        restrictionType == other.restrictionType &&
        shapeForm == other.shapeForm &&
        shapeType == other.shapeType &&
        slotAllocation == other.slotAllocation;
  }

  @override
  int get hashCode {
    return arrowType.hashCode ^
        beginArrowDirection.hashCode ^
        beginSlot.hashCode ^
        endArrowDirection.hashCode ^
        endSlot.hashCode ^
        restrictionType.hashCode ^
        shapeForm.hashCode ^
        slotAllocation.hashCode;
  }
}

/// Indicates whether an arrow is present and on which side of the anchor it
/// is attached.
///
/// Arrows are visual hints attached to a geometry item. They may appear on
/// the side that connects to the anchor (begin) or on the opposite side
/// (end), or be absent entirely.
///
/// ## See also:
///
/// - [AbstractGeometryItem.arrowType]
///
/// {@category Images}
enum ArrowType {
  /// None
  none,

  /// Begin
  begin,

  /// End
  end,
}

/// @nodoc
extension ArrowTypeExtension on ArrowType {
  int get id {
    switch (this) {
      case ArrowType.none:
        return 0;
      case ArrowType.begin:
        return 1;
      case ArrowType.end:
        return 2;
    }
  }

  static ArrowType fromId(final int id) {
    switch (id) {
      case 0:
        return ArrowType.none;
      case 1:
        return ArrowType.begin;
      case 2:
        return ArrowType.end;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Restriction type for a geometry item.
///
/// Used to visualise traffic restrictions that apply to the connected
/// street segment. For example a direction restriction or a manoeuvre
/// prohibition. Use this value to choose an overlay icon or special
/// styling for the affected slot.
///
/// ## See also:
///
/// - [AbstractGeometryItem.restrictionType]
///
/// {@category Images}
enum RestrictionType {
  /// No restriction
  none,

  /// Direction restriction
  direction,

  /// Maneuver restriction
  manoeuvre,
}

/// @nodoc
extension RestrictionTypeExtension on RestrictionType {
  int get id {
    switch (this) {
      case RestrictionType.none:
        return 0;
      case RestrictionType.direction:
        return 1;
      case RestrictionType.manoeuvre:
        return 2;
    }
  }

  static RestrictionType fromId(final int id) {
    switch (id) {
      case 0:
        return RestrictionType.none;
      case 1:
        return RestrictionType.direction;
      case 2:
        return RestrictionType.manoeuvre;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Shape form for an abstract geometry item.
///
/// Describes the geometric primitive used to draw a slot on the anchor. Use
/// the form to decide rendering rules (for example how to connect segments
/// and which drawing routine to use). Typical values are a line spanning
/// between two slots, a circle segment (used for roundabouts) or an
/// independent point marker.
///
/// ## See also:
///
/// - [AbstractGeometryItem.shapeForm] - The shape form of a geometry item.
///
/// {@category Images}
enum ShapeForm {
  /// Line is a simple line with width defined by [ShapeType],
  line,

  /// CircleSegment (clock wise or counter clock wise depending on drive side) is a part of a [AnchorType.circle]
  circleSegment,

  /// Point is a maker (e.g. Waypoint place) outside the anchor and not connected by a line. Get the index of the next route instruction on the current route segment.
  point,
}

/// @nodoc
extension ShapeFormExtension on ShapeForm {
  int get id {
    switch (this) {
      case ShapeForm.line:
        return 0;
      case ShapeForm.circleSegment:
        return 1;
      case ShapeForm.point:
        return 2;
    }
  }

  static ShapeForm fromId(final int id) {
    switch (id) {
      case 0:
        return ShapeForm.line;
      case 1:
        return ShapeForm.circleSegment;
      case 2:
        return ShapeForm.point;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Direction of the arrow drawn for a shape.
///
/// The direction indicates the travel bearing represented by a shape and is
/// primarily valid for circular segments (roundabouts) and combined turn
/// geometries. Typical values are [left], [straight] and [right].
///
/// ## See also:
///
/// - [AbstractGeometryItem.beginArrowDirection] - Direction at the begin.
/// - [AbstractGeometryItem.endArrowDirection] - Direction at the end.
///
/// {@category Images}
enum ArrowDirection {
  /// None
  none,

  /// Left
  left,

  /// Straight
  straight,

  /// Right
  right,
}

/// @nodoc
extension ArrowDirectionExtension on ArrowDirection {
  int get id {
    switch (this) {
      case ArrowDirection.none:
        return 0;
      case ArrowDirection.left:
        return 1;
      case ArrowDirection.straight:
        return 2;
      case ArrowDirection.right:
        return 3;
    }
  }

  static ArrowDirection fromId(final int id) {
    switch (id) {
      case 0:
        return ArrowDirection.none;
      case 1:
        return ArrowDirection.left;
      case 2:
        return ArrowDirection.straight;
      case 3:
        return ArrowDirection.right;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Shape type describing the semantic layer of a geometry item.
///
/// Use this to distinguish route-oriented geometry from ordinary street
/// graphics. For example, [ShapeType.route] should be rendered above and
/// highlighted compared to [ShapeType.street]. The type can affect stroke
/// width, color and z-order.
///
/// ## See also:
///
/// - [AbstractGeometryItem.shapeType] - The shape type of a geometry item.
///
/// {@category Images}
enum ShapeType {
  /// Route
  route,

  /// Street
  street,
}

/// @nodoc
extension ShapeTypeExtension on ShapeType {
  int get id {
    switch (this) {
      case ShapeType.route:
        return 0;
      case ShapeType.street:
        return 1;
    }
  }

  static ShapeType fromId(final int id) {
    switch (id) {
      case 0:
        return ShapeType.route;
      case 1:
        return ShapeType.street;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
