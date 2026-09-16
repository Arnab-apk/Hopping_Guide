// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

// ignore_for_file: unused_import

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show Color, Size;

import 'package:flutter/material.dart' show Colors;
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/extensions.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// A single route instruction used for route guidance.
///
/// [RouteInstructionBase] models one maneuver (for example, a turn, exit or follow-road instruction). It exposes
/// the instruction location, localized text, images (turn images and realistic intersection renderings), signpost
/// details and time/distance metrics used to present guidance to users and in UI lists. Instances are obtained from
/// [RouteSegment.instructions] and should not be constructed directly.
///
/// For real-time turn-by-turn updates use [NavigationInstruction] which is produced during navigation.
///
/// ## See also:
///
/// - [RouteSegment.instructions] - Obtain instructions from a segment.
/// - [NavigationInstruction] - Real-time navigation instructions.
///
/// {@category Route}
class RouteInstructionBase extends GemAutoreleaseObject {
  // ignore: unused_element
  RouteInstructionBase._() : super(-1);

  @internal
  RouteInstructionBase.init(super.id);

  /// Location coordinates for this instruction.
  ///
  /// ## Returns
  ///
  /// - [Coordinates]: geographic coordinates of the instruction location.
  Coordinates get coordinates {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getCoordinates',
    );

    return Coordinates.fromJson(resultString['result']);
  }

  /// ISO 3166-1 alpha-3 country code for the instruction location.
  ///
  /// Empty string indicates no country information is available.
  ///
  /// ## Returns
  ///
  /// - `String`: ISO 3166-1 alpha-3 country code (e.g., `USA`, `NLD`) or empty string when unknown.
  String get countryCodeISO {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getCountryCodeISO',
    );

    return resultString['result'];
  }

  /// Exit instruction text when this instruction is an exit.
  ///
  /// ## Returns
  ///
  /// - `String`: exit text, or an empty string when the instruction is not an exit.
  ///
  /// ## See also:
  ///
  /// - [RouteInstruction.isExit] - check if the instruction is an exit.
  String get exitDetails {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getExitDetails',
    );

    return resultString['result'];
  }

  /// Localized textual description for follow-road guidance associated with this instruction.
  ///
  /// ## Returns
  ///
  /// - `String`: follow-road instruction text, or an empty string if not available.
  String get followRoadInstruction {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getFollowRoadInstruction',
    );

    return resultString['result'];
  }

  /// Retrieve a rasterized image for the realistic next-turn rendering.
  ///
  /// The image is rendered using the optional [renderSettings] and returned in the requested [format].
  ///
  /// ## Parameters
  ///
  /// - [size]: Desired image dimensions. When `null` a default size is returned.
  /// - [format]: Desired image file format, or `null` to use the platform default.
  /// - [renderSettings]: Rendering options controlling styling and visibility of features.
  ///
  /// ## Returns
  ///
  /// - `Uint8List?`: raw image bytes, or `null` when an image cannot be produced.
  ///
  /// ## See also:
  ///
  /// - [AbstractGeometryImageRenderSettings] - settings to control realistic image rendering.
  /// - [realisticNextTurnImg] - the next turn image in a [AbstractGeometryImg] format.
  Uint8List? getRealisticNextTurnImage({
    final Size? size,
    final ImageFileFormat? format,
    final AbstractGeometryImageRenderSettings renderSettings =
        const AbstractGeometryImageRenderSettings(),
  }) {
    return GemKitPlatform.instance.callGetImage(
      pointerId,
      'RouteInstructionGetRealisticNextTurnImage',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
      arg: jsonEncode(renderSettings),
    );
  }

  /// Get the vectorial representation for the realistic next turn image as a [AbstractGeometryImg].
  ///
  /// Prefer [AbstractGeometryImg] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getRealisticNextTurnImage] when you only need the raster image bytes.
  ///
  /// ## Returns
  ///
  /// - [AbstractGeometryImg]: vector image object for the realistic next turn.
  AbstractGeometryImg get realisticNextTurnImg {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getRealisticNextTurnImg',
    );

    return AbstractGeometryImg.init(resultString['result']);
  }

  /// Remaining travel time and distance from this instruction to the route end.
  ///
  /// ## Returns
  ///
  /// - [TimeDistance]: remaining travel time (seconds) and distance (meters).
  TimeDistance get remainingTravelTimeDistance {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getRemainingTravelTimeDistance',
    );

    return TimeDistance.fromJson(resultString['result']);
  }

  /// Remaining time/distance to the next waypoint from this instruction.
  ///
  /// ## Returns
  ///
  /// - [TimeDistance]: remaining travel time (seconds) and distance (meters) to the next waypoint.
  TimeDistance get remainingTravelTimeDistanceToNextWaypoint {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getRemainingTravelTimeDistanceToNextWaypoint',
    );

    return TimeDistance.fromJson(resultString['result']);
  }

  /// Road information associated with this instruction (name, shield, attributes).
  ///
  /// ## Returns
  ///
  /// - `List<RoadInfo>`: list of road info objects describing signs, names or shields relevant to the instruction.
  ///
  /// ## See also:
  ///
  /// - [roadInfoImg] - the road info image in a [RoadInfoImg] format.
  /// - [hasRoadInfo] - check if road information is available.
  List<RoadInfo> get roadInfo {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getRoadInfo',
    );

    final List<dynamic> res = resultString['result'];
    final List<RoadInfo> retList = res
        .map((dynamic e) => RoadInfo.fromJson(e))
        .toList();
    return retList;
  }

  /// Retrieve a raster image representing the road information (e.g., shield or icon).
  ///
  /// ## Parameters
  ///
  /// - [size]: Desired image dimensions. When `null` a default size is used.
  /// - [format]: Desired file format for the image, or `null` to use the default format.
  /// - [backgroundColor]: Background color to apply when rendering images that support background fill.
  /// - [allowResize]: When `true`, the platform may return an image resized to better match available assets.
  ///
  /// ## Returns
  ///
  /// - `Uint8List?`: raw image bytes for the road info, or `null` when unavailable.
  ///
  /// ## See also:
  ///
  /// - [roadInfoImg] - the road info image in a [RoadInfoImg] format.
  Uint8List? getRoadInfoImage({
    final Size? size,
    final ImageFileFormat? format,
    final Color backgroundColor = Colors.transparent,
    final bool allowResize = false,
  }) {
    final Rgba bkColor = backgroundColor.toRgba();
    return GemKitPlatform.instance.callGetImage(
      pointerId,
      'RouteInstructionGetRoadInfoImage',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
      arg: jsonEncode(bkColor),
      allowResize: allowResize,
    );
  }

  /// Get the signpost image as a [RoadInfoImg].
  ///
  /// Prefer [RoadInfoImg] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getRoadInfoImage] when you only need the raster image bytes.
  ///
  /// ## Returns
  ///
  /// - [RoadInfoImg]: vector image object associated with the road information.
  ///
  /// ## See also:
  ///
  /// - [getRoadInfoImage] - retrieve the road info as a raster image.
  /// - [hasRoadInfo] - check if road information is available.
  RoadInfoImg get roadInfoImg {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getRoadInfoImg',
    );

    return RoadInfoImg.init(resultString['result']);
  }

  /// Detailed signpost information associated with this instruction.
  ///
  /// ## Returns
  ///
  /// - [SignpostDetails]: extended signpost data, or an object with empty fields when unavailable.
  ///
  /// ## See also:
  ///
  /// - [hasSignpostInfo] - check if signpost information is available.
  SignpostDetails get signpostDetails {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getSignpostDetails',
    );

    return SignpostDetails.init(resultString['result']);
  }

  /// Localized text description for signpost guidance.
  ///
  /// ## Returns
  ///
  /// - `String`: text for the signpost instruction, or an empty string when not available.
  String get signpostInstruction {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getSignpostInstruction',
    );

    return resultString['result'];
  }

  /// Distance and time to the next turn from this instruction.
  ///
  /// ## Returns
  ///
  /// - [TimeDistance]: distance (meters) and time (seconds) until the next turn.
  TimeDistance get timeDistanceToNextTurn {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getTimeDistanceToNextTurn',
    );

    return TimeDistance.fromJson(resultString['result']);
  }

  /// Distance/time metrics already traveled up to this instruction.
  ///
  /// ## Returns
  ///
  /// - [TimeDistance]: distance (meters) and time (seconds) that have been traveled prior to this instruction.
  TimeDistance get traveledTimeDistance {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getTraveledTimeDistance',
    );

    return TimeDistance.fromJson(resultString['result']);
  }

  /// Detailed information describing the upcoming turn.
  ///
  /// ## Returns
  ///
  /// - [TurnDetails]: full turn metadata used to render or customize UI representations.
  ///
  /// ## See also:
  ///
  /// - [hasTurnInfo] - check if detailed turn information is available.
  TurnDetails get turnDetails {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getTurnDetails',
    );

    return TurnDetails.init(resultString['result']);
  }

  /// Retrieve a raster image representing the turn symbol.
  ///
  /// ## Parameters
  ///
  /// - [size]: Desired image dimensions. When `null` a default size is returned.
  /// - [format]: Desired image format, or `null` for platform default.
  ///
  /// ## Returns
  ///
  /// - `Uint8List?`: raw image bytes for the turn symbol, or `null` when unavailable.
  Uint8List? getTurnImage({final Size? size, final ImageFileFormat? format}) {
    return GemKitPlatform.instance.callGetImage(
      pointerId,
      'RouteInstructionGetTurnImage',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
    );
  }

  /// Vector image representation of the turn symbol as an [Img].
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getTurnImage] when you only need raw image bytes.
  ///
  /// ## Returns
  ///
  /// - [Img]: vector image for the turn, or an empty/invalid image object when not available.
  Img get turnImg {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getTurnImg',
    );

    return Img.init(resultString['result']);
  }

  /// Localized textual instruction for the turn.
  ///
  /// ## Returns
  ///
  /// - `String`: turn instruction text, or an empty string if not present.
  String get turnInstruction {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'getTurnInstruction',
    );

    return resultString['result'];
  }

  /// Whether follow-road guidance information is available for this instruction.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when follow-road data is present; otherwise `false`.
  bool get hasFollowRoadInfo {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'hasFollowRoadInfo',
    );

    return resultString['result'];
  }

  /// Whether signpost information is available for this instruction.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when signpost data is present; otherwise `false`.
  ///
  /// ## Also see:
  ///
  /// - [signpostDetails] - detailed signpost information.
  bool get hasSignpostInfo {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'hasSignpostInfo',
    );

    return resultString['result'];
  }

  /// Whether detailed turn information is available for this instruction.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when turn metadata is available; otherwise `false`.
  ///
  /// ## Also see:
  ///
  /// - [turnDetails] - detailed turn information.
  bool get hasTurnInfo {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'hasTurnInfo',
    );

    return resultString['result'];
  }

  /// Whether road information (names, shields) is available for this instruction.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when road info is present; otherwise `false`.
  ///
  /// ## Also see:
  ///
  /// - [roadInfo] - detailed road information.
  bool get hasRoadInfo {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'hasRoadInfo',
    );

    return resultString['result'];
  }

  /// Whether this instruction belongs to a common-type segment (see [RouteSegment.isCommon]).
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when the instruction is part of a segment whose travel mode matches the route.
  bool get isCommon {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'isCommon',
    );

    return resultString['result'];
  }

  /// Whether this instruction represents a main-road exit maneuver.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when the instruction denotes an exit; otherwise `false`.
  ///
  /// ## See also:
  ///
  /// - [exitDetails] - get exit-specific information when the instruction is an exit.
  bool get isExit {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'isExit',
    );

    return resultString['result'];
  }

  /// Whether this instruction involves a ferry crossing.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when the instruction corresponds to a ferry segment.
  bool get isFerry {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'isFerry',
    );

    return resultString['result'];
  }

  /// Whether this instruction involves a tolled road.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when the instruction corresponds to a toll-road segment.
  bool get isTollRoad {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteInstructionBase',
      'isTollRoad',
    );

    return resultString['result'];
  }
}
