// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/routing/routing_enums.dart';
import 'package:meta/meta.dart';

/// Provides navigation turn details.
///
/// A [TurnDetails] object describes a manoeuvre and its
/// abstract geometry. It contains a machine-readable geometry model
/// [abstractGeometry], image representations of that geometry
/// [abstractGeometryImg], and the corresponding navigation event [event].
///
/// Instances are created by the SDK and returned from higher-level classes such as
/// [RouteInstruction] or [NavigationInstruction].
///
/// ## See also:
///
/// - [AbstractGeometry] — Structured geometry model for the turn.
/// - [AbstractGeometryImg] — Renderable image wrapper for abstract geometry.
/// - [RouteInstruction.getTurnImage] — Simplified turn image for UI as an alternative
/// to the [abstractGeometryImg].
///
/// {@category Common}
class TurnDetails {
  // ignore: unused_element
  TurnDetails._() : _pointerId = -1;

  @internal
  TurnDetails.init(final int id) : _pointerId = id;
  final int _pointerId;

  int get pointerId => _pointerId;

  /// Structured representation of the turn geometry.
  ///
  /// The returned [AbstractGeometry] describes the intersection anchor
  /// type, drive side and a list of geometry items that can be used to
  /// render a schematic of the junction programmatically.
  ///
  /// ## See also:
  ///
  /// - [AbstractGeometryImg] and [getAbstractGeometryImage] for image
  ///   representations of this geometry.
  AbstractGeometry get abstractGeometry {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'TurnDetails',
      'getAbstractGeometry',
    );

    return AbstractGeometry.fromJson(resultString['result']);
  }

  /// Returns image bytes for the abstract geometry.
  ///
  /// Generates an image representation of the [abstractGeometry]. The
  /// image may be customised using [renderSettings] to match your app
  /// colours (recommended for consistent theming).
  ///
  /// ## Parameters
  ///
  /// - [size]: Optional desired image size. If omitted, the SDK default
  ///   image size is used.
  /// - [format]: Optional image file format. Defaults to PNG when not set.
  /// - [renderSettings]: Optional [AbstractGeometryImageRenderSettings]
  ///   instance that controls active/inactive colours and other rendering
  ///   options.
  ///
  /// ## Returns
  ///
  /// - `Uint8List?`: Raw image bytes for the requested image, or `null` if
  ///   the image could not be generated. Callers are responsible for
  ///   validating the image before displaying it.
  ///
  /// ## Also see:
  ///
  /// - [abstractGeometryImg] — Renderable image wrapper for the abstract geometry.
  /// - [AbstractGeometryImg] — Class that provides metadata and access to renderable bytes.
  /// - [abstractGeometryImageUid] - Unique identifier for the abstract geometry image. Used
  /// to determine whether the image changed since the last instruction.
  Uint8List? getAbstractGeometryImage({
    final Size? size,
    final ImageFileFormat? format,
    final AbstractGeometryImageRenderSettings renderSettings =
        const AbstractGeometryImageRenderSettings(),
  }) {
    return GemKitPlatform.instance.callGetImage(
      pointerId,
      'TurnDetailsGetAbstractGeometryImage',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
      arg: jsonEncode(renderSettings),
    );
  }

  /// Get the vectorial representation for the turn details image as a [AbstractGeometryImg].
  ///
  /// Prefer [AbstractGeometryImg] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getAbstractGeometryImage] when you only need the raster image bytes.
  ///
  /// ## Returns
  ///
  /// - [AbstractGeometryImg]: Renderable image wrapper for the abstract geometry.
  ///
  /// ## See also:
  ///
  /// - [getAbstractGeometryImage] — obtain raw image bytes with custom
  ///   render settings.
  AbstractGeometryImg get abstractGeometryImg {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'TurnDetails',
      'getAbstractGeometryImg',
    );

    return AbstractGeometryImg.init(resultString['result']);
  }

  /// Unique identifier for the abstract geometry image.
  ///
  /// The UID can be used to determine whether the image changed since the
  /// last update. Compare this value to the previously-seen UID and only
  /// reload the UI image when it differs to save rendering work during
  /// navigation.
  ///
  /// ## Returns
  ///
  /// - `int`: Unique identifier for the abstract geometry image or `-1` if
  ///  the UID is not available.
  ///
  /// ## Also see:
  ///
  /// - [abstractGeometryImg] — Renderable image wrapper for the abstract geometry.
  /// - [getAbstractGeometryImage] — obtain raw image bytes with custom
  int get abstractGeometryImageUid {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'TurnDetails',
      'getAbstractGeometryImageUid',
    );

    return resultString['result'];
  }

  /// Navigation event for this turn (turn direction/type).
  ///
  /// The returned value is a [TurnEvent] enum describing the manoeuvre
  /// (for example `straight`, `right`, `left`, `roundabout`, `exitNr`,
  /// etc.). Use the enum to show the correct icon or voice instruction in
  /// your UI.
  ///
  /// ## Returns
  ///
  /// - [TurnEvent]: Navigation event for this turn (turn direction/type).
  TurnEvent get event {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'TurnDetails',
      'getEvent',
    );

    return TurnEventExtension.fromId(resultString['result']);
  }

  /// Roundabout exit index.
  ///
  /// Returns the exit number to take when the [event] is a roundabout
  /// exit. The value is a positive integer when available, or `-1` when
  /// not applicable.
  ///
  /// ## Returns
  ///
  /// - `int`: Exit number to take for roundabout exits, or `-1` if not
  /// applicable.
  ///
  /// ## Also see:
  ///
  /// - [event] — The navigation event for this turn.
  int get roundaboutExitNumber {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'TurnDetails',
      'getRoundaboutExitNumber',
    );

    return resultString['result'];
  }

  /// Set of [RouteRestrictionType] values that apply to this turn.
  ///
  /// ## Returns
  ///
  /// - `Set<RouteRestrictionType>`: Restrictions for the turn; empty when
  ///   there are no restrictions on the turn.
  ///
  /// ## See also:
  ///
  /// - [RouteRestrictionType] - Enumeration of restriction kinds.
  /// - [NavigationInstruction.currentRestrictions] - Restrictions active at
  ///   the current position during navigation.
  Set<RouteRestrictionType> get restrictions {
    final OperationResult resultString = objectMethod(
      _pointerId,
      'TurnDetails',
      'getRestrictions',
    );

    final int mask = resultString['result'];
    final Set<RouteRestrictionType> result = <RouteRestrictionType>{};
    for (final RouteRestrictionType value in RouteRestrictionType.values) {
      if (mask & value.id != 0) {
        result.add(value);
      }
    }
    return result;
  }

  void dispose() => GemKitPlatform.instance.callDeleteObject(
    jsonEncode(<String, Object>{'class': 'TurnDetails', 'id': _pointerId}),
  );
}

/// Navigation turn events.
///
/// Information about the manoeuvre that can be used by UI.
///
/// The enum contains common manoeuvres (e.g. [straight], [right], [left]),
/// roundabout-related events, exit numbers and waypoint markers. Values are
/// stable and intended to be consumed directly by client code.
///
/// ## See also:
///
/// - [TurnDetails.event]
///
/// {@category Common}
enum TurnEvent {
  /// Turn type not available
  na,

  /// Continue straight ahead
  straight,

  /// Turn right
  right,

  /// Turn right
  right1,

  /// Turn right
  right2,

  /// Turn left
  left,

  /// Turn left
  left1,

  /// Turn left
  left2,

  ///Turn half left
  lightLeft,

  /// Turn half left
  lightLeft1,

  ///Turn half left
  lightLeft2,

  ///Turn half right
  lightRight,

  ///Turn half right
  lightRight1,

  ///Turn half right
  lightRight2,

  /// Turn sharp right
  sharpRight,

  /// Turn sharp right
  sharpRight1,

  /// Turn sharp right
  sharpRight2,

  /// Turn sharp left
  sharpLeft,

  /// Turn sharp left
  sharpLeft1,

  /// Turn sharp left
  sharpLeft2,

  /// Leave the roundabout to the right
  roundaboutExitRight,

  /// Continue on the roundabout
  roundabout,

  /// Make a U-turn
  roundRight,

  /// Make a U-turn
  roundLeft,

  /// Take the exit
  exitRight,

  /// Take the exit
  exitRight1,

  /// Take the exit
  exitRight2,

  /// Generic info
  infoGeneric,

  /// Drive on
  driveOn,

  /// Take exit number
  exitNr,

  /// Take the exit
  exitLeft,

  /// Take the exit
  exitLeft1,

  /// Take the exit
  exitLeft2,

  /// Leave the roundabout to the left
  roundaboutExitLeft,

  /// Leave the roundabout at the ... exit
  intoRoundabout,

  /// Continue straight ahead
  stayOn,

  /// Take the ferry
  boatFerry,

  /// Take the car transport by train
  railFerry,

  /// Lane info
  infoLane,

  /// Info sign
  infoSign,

  /// Left and then turn right
  leftRight,

  /// Right and then turn left
  rightLeft,

  /// Bear left
  keepLeft,

  /// Bear right
  keepRight,

  /// Start waypoint
  start,

  /// Intermediate waypoint
  intermediate,

  /// Stop waypoint
  stop,
}

/// @nodoc
extension TurnEventExtension on TurnEvent {
  int get id {
    switch (this) {
      case TurnEvent.na:
        return 0;
      case TurnEvent.straight:
        return 1;
      case TurnEvent.right:
        return 2;
      case TurnEvent.right1:
        return 3;
      case TurnEvent.right2:
        return 4;
      case TurnEvent.left:
        return 5;
      case TurnEvent.left1:
        return 6;
      case TurnEvent.left2:
        return 7;
      case TurnEvent.lightLeft:
        return 8;
      case TurnEvent.lightLeft1:
        return 9;
      case TurnEvent.lightLeft2:
        return 10;
      case TurnEvent.lightRight:
        return 11;
      case TurnEvent.lightRight1:
        return 12;
      case TurnEvent.lightRight2:
        return 13;
      case TurnEvent.sharpRight:
        return 14;
      case TurnEvent.sharpRight1:
        return 15;
      case TurnEvent.sharpRight2:
        return 16;
      case TurnEvent.sharpLeft:
        return 17;
      case TurnEvent.sharpLeft1:
        return 18;
      case TurnEvent.sharpLeft2:
        return 19;
      case TurnEvent.roundaboutExitRight:
        return 20;
      case TurnEvent.roundabout:
        return 21;
      case TurnEvent.roundRight:
        return 22;
      case TurnEvent.roundLeft:
        return 23;
      case TurnEvent.exitRight:
        return 24;
      case TurnEvent.exitRight1:
        return 25;
      case TurnEvent.exitRight2:
        return 26;
      case TurnEvent.infoGeneric:
        return 27;
      case TurnEvent.driveOn:
        return 28;
      case TurnEvent.exitNr:
        return 29;
      case TurnEvent.exitLeft:
        return 30;
      case TurnEvent.exitLeft1:
        return 31;
      case TurnEvent.exitLeft2:
        return 32;
      case TurnEvent.roundaboutExitLeft:
        return 33;
      case TurnEvent.intoRoundabout:
        return 34;
      case TurnEvent.stayOn:
        return 35;
      case TurnEvent.boatFerry:
        return 36;
      case TurnEvent.railFerry:
        return 37;
      case TurnEvent.infoLane:
        return 38;
      case TurnEvent.infoSign:
        return 39;
      case TurnEvent.leftRight:
        return 40;
      case TurnEvent.rightLeft:
        return 41;
      case TurnEvent.keepLeft:
        return 42;
      case TurnEvent.keepRight:
        return 43;
      case TurnEvent.start:
        return 44;
      case TurnEvent.intermediate:
        return 45;
      case TurnEvent.stop:
        return 46;
    }
  }

  static TurnEvent fromId(final int id) {
    switch (id) {
      case 0:
        return TurnEvent.na;
      case 1:
        return TurnEvent.straight;
      case 2:
        return TurnEvent.right;
      case 3:
        return TurnEvent.right1;
      case 4:
        return TurnEvent.right2;
      case 5:
        return TurnEvent.left;
      case 6:
        return TurnEvent.left1;
      case 7:
        return TurnEvent.left2;
      case 8:
        return TurnEvent.lightLeft;
      case 9:
        return TurnEvent.lightLeft1;
      case 10:
        return TurnEvent.lightLeft2;
      case 11:
        return TurnEvent.lightRight;
      case 12:
        return TurnEvent.lightRight1;
      case 13:
        return TurnEvent.lightRight2;
      case 14:
        return TurnEvent.sharpRight;
      case 15:
        return TurnEvent.sharpRight1;
      case 16:
        return TurnEvent.sharpRight2;
      case 17:
        return TurnEvent.sharpLeft;
      case 18:
        return TurnEvent.sharpLeft1;
      case 19:
        return TurnEvent.sharpLeft2;
      case 20:
        return TurnEvent.roundaboutExitRight;
      case 21:
        return TurnEvent.roundabout;
      case 22:
        return TurnEvent.roundRight;
      case 23:
        return TurnEvent.roundLeft;
      case 24:
        return TurnEvent.exitRight;
      case 25:
        return TurnEvent.exitRight1;
      case 26:
        return TurnEvent.exitRight2;
      case 27:
        return TurnEvent.infoGeneric;
      case 28:
        return TurnEvent.driveOn;
      case 29:
        return TurnEvent.exitNr;
      case 30:
        return TurnEvent.exitLeft;
      case 31:
        return TurnEvent.exitLeft1;
      case 32:
        return TurnEvent.exitLeft2;
      case 33:
        return TurnEvent.roundaboutExitLeft;
      case 34:
        return TurnEvent.intoRoundabout;
      case 35:
        return TurnEvent.stayOn;
      case 36:
        return TurnEvent.boatFerry;
      case 37:
        return TurnEvent.railFerry;
      case 38:
        return TurnEvent.infoLane;
      case 39:
        return TurnEvent.infoSign;
      case 40:
        return TurnEvent.leftRight;
      case 41:
        return TurnEvent.rightLeft;
      case 42:
        return TurnEvent.keepLeft;
      case 43:
        return TurnEvent.keepRight;
      case 44:
        return TurnEvent.start;
      case 45:
        return TurnEvent.intermediate;
      case 46:
        return TurnEvent.stop;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
