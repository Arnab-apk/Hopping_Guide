// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/navigation.dart';
import 'package:magiclane_maps_flutter/position.dart';
import 'package:magiclane_maps_flutter/routing.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/gem_position_impl.dart';
import 'package:meta/meta.dart';

/// Real-time turn-by-turn navigation instruction for active navigation sessions.
///
/// Cannot be instantiated directly; instances are provided automatically by
/// the SDK during navigation or simulation via [NavigationService] callbacks.
/// Access instructions through `startNavigation` or `startSimulation` callbacks,
/// or retrieve the current instruction using [NavigationService.getNavigationInstruction]
/// (requires an active navigation/simulation session).
///
/// Provides comprehensive real-time guidance including:
/// - Current and upcoming road/street details (names, speed limits, country codes)
/// - Turn-by-turn instructions with schematic and detailed geometry images
/// - Lane guidance images for complex intersections
/// - Time and distance to upcoming turns, waypoints, and destination
/// - Signpost information for highway navigation
/// - Return-to-route guidance when off-route
///
/// [NavigationInstruction] is **real-time** and updates as
/// the user navigates, whereas [RouteInstruction] is **static** and available
/// immediately after route calculation. Use [NavigationInstruction] for live
/// navigation UI and [RouteInstruction] for route preview/overview.
///
/// ## Example
///
/// ```dart
/// NavigationService.startNavigation(
///   route,
///   onNavigationInstruction: (instruction, events) {
///     // Use the instruction object
///   },
/// );
/// ```
///
/// ## See also:
///
/// - [NavigationService] - Service to start navigation and obtain instructions.
/// - [RouteInstruction] - Static route instruction available after calculation.
/// - [TurnDetails] - Detailed turn information including geometry and event type.
/// - [NextSpeedLimit] - Speed limit variation information.
/// - [SignpostDetails] - Highway signpost rendering details.
///
/// {@category Navigation}
class NavigationInstruction extends GemAutoreleaseObject {
  // ignore: unused_element
  NavigationInstruction._() : super(-1);

  @internal
  NavigationInstruction.init(super.id);

  /// ISO 3166-1 alpha-3 country code for the current road segment.
  ///
  /// Returns the three-letter country code (e.g., "USA", "DEU", "GBR") for the
  /// road the user is currently traveling on. Returns an empty string if country
  /// information is unavailable.
  ///
  /// ## Returns
  ///
  /// - (String) ISO 3166-1 alpha-3 country code, or empty string if not available.
  ///
  /// ## See also:
  ///
  /// - [nextCountryCodeISO] - Country code for the next road segment.
  /// - [MapDetails] - Querry details about a map by country code.
  String get currentCountryCodeISO {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getCurrentCountryCodeISO',
    );

    return resultString['result'];
  }

  /// Current street name.
  ///
  /// Returns the name of the street the user is currently traveling on. May return
  /// an empty string if the street has no assigned name or if the information is
  /// unavailable.
  ///
  /// ## Returns
  ///
  /// - (String) Street name, or empty string if not available.
  ///
  /// ## See also:
  ///
  /// - [nextStreetName] - Name of the next street.
  /// - [currentRoadInformation] - Additional road details including official codes.
  String get currentStreetName {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getCurrentStreetName',
    );

    return resultString['result'];
  }

  /// Maximum speed limit on the current street in meters per second.
  ///
  /// Returns the posted speed limit for the current road segment. Returns 0 if
  /// speed limit information is not available for this location.
  ///
  /// ## Returns
  ///
  /// - (double) Speed limit in m/s, or 0 if not available.
  ///
  /// ## See also:
  ///
  /// - [getNextSpeedLimitVariation] - Upcoming speed limit changes.
  /// - [AlarmService] - Get notified of speed limit violations.
  double get currentStreetSpeedLimit {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getCurrentStreetSpeedLimit',
    );

    return resultString['result'];
  }

  /// Drive side for the current road.
  ///
  /// Indicates whether traffic drives on the left or right side of the road for
  /// the current location. Essential for rendering correct lane guidance and
  /// turn icons.
  ///
  /// ## Returns
  ///
  /// - (DriveSide) The drive side (left or right) for the current road.
  DriveSide get driveSide {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getDriveSide',
    );

    return DriveSideExtension.fromId(resultString['result']);
  }

  /// Set of [RouteRestrictionType] values active at the current position.
  ///
  /// Describes the restrictions that apply to the part of the route the user
  /// is currently traveling on (for example access restricted, transport not
  /// allowed, vehicle over weight/height/length/width/axle limit, plate
  /// restriction).
  ///
  /// ## Returns
  ///
  /// - `Set<RouteRestrictionType>`: Currently active restrictions; empty
  ///   when no restriction is active.
  ///
  /// ## See also:
  ///
  /// - [RouteRestrictionType] - Enumeration of restriction kinds.
  /// - [TurnDetails.restrictions] - Restrictions associated with an
  ///   individual turn.
  /// - [NavigationInstructionUpdateEvents.restrictionsUpdated] - Update flag
  ///   delivered when the active restrictions change.
  Set<RouteRestrictionType> get currentRestrictions {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getCurrentRestrictions',
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

  /// Navigation session route.
  ///
  /// Returns the [Route] object for the active navigation session to which this
  /// instruction belongs. Use this to access route-level details such as total
  /// distance, waypoints, or alternative routes.
  ///
  /// ## Returns
  ///
  /// - (Route) The route object for the current navigation session.
  Route get navigationRoute {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNavigationRoute',
    );

    return Route.init(resultString['result']);
  }

  /// Closest position on route when waiting to return to route.
  ///
  /// Valid only when `navigationStatus` is `NavigationStatus.waitingReturnToRoute`.
  /// Returns the coordinates of the closest point on the original route, helping
  /// guide the user back when they have deviated from the planned path.
  ///
  /// ## Returns
  ///
  /// - (Coordinates?) Closest position on route, or null if not applicable.
  ///
  /// ## See also:
  ///
  /// - [returnToRouteImage] - Turn image for returning to route.
  /// - [navigationStatus] - Current navigation status.
  Coordinates? get returnToRoutePosition {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getReturnToRoutePosition',
    );

    final Coordinates coords = Coordinates.fromJson(resultString['result']);

    if (coords.isValid) {
      return coords;
    }
    return null;
  }

  /// Get the vectorial representation for the return-to-route image as a [AbstractGeometryImg].
  ///
  /// Prefer [AbstractGeometryImg] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes;
  ///
  /// ## Returns
  ///
  /// - (AbstractGeometryImg) Turn image for returning to route.
  ///
  /// ## See also:
  ///
  /// - [returnToRoutePosition] - Position to return to on route.
  AbstractGeometryImg get returnToRouteImage {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getReturnToRouteImg',
    );

    return AbstractGeometryImg.init(resultString['result']);
  }

  /// Export navigation instruction data.
  ///
  /// Exports the instruction in the specified format. Currently only supports
  /// [PathFileFormat.packedGeometry]. Useful for serializing instruction data
  /// for analysis or debugging.
  ///
  /// ## Parameters
  ///
  /// - [fileFormat]: (PathFileFormat) Data format for export. Defaults to `PathFileFormat.packedGeometry`.
  ///
  /// ## Returns
  ///
  /// - (Uint8List) Instruction data buffer in the requested format.
  Uint8List exportAs({
    PathFileFormat fileFormat = PathFileFormat.packedGeometry,
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'exportAs',
      args: fileFormat.id,
    );

    final String encodedResult = resultString['result'];
    final Uint8List resultAsUint8List = base64Decode(encodedResult);

    return resultAsUint8List;
  }

  /// Get the road info image for a specific [RoadInfoType] as a [RoadInfoImg].
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  ///
  /// ## Parameters
  ///
  /// - [type]: (RoadInfoType) The type of road information to render (e.g., shield, designation).
  ///
  /// ## Returns
  ///
  /// - (Img) Image representation of the specified road information type.
  ///
  /// ## See also:
  ///
  /// - [currentRoadInformation] - Current road info.
  /// - [nextRoadInformation] - Next road info.
  RoadInfoImg getRoadInfoImgByType(RoadInfoType type) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getRoadInfoImgByType',
      args: type.id,
    );

    return RoadInfoImg.init(resultString['result']);
  }

  /// Next route instruction on the route.
  ///
  /// Returns the [RouteInstruction] following the current navigation position.
  /// Returns null if unavailable (e.g., when at the destination or if an error occurs).
  ///
  /// ## Returns
  ///
  /// - (RouteInstruction?) Next route instruction, or null if not available.
  ///
  /// ## See also:
  ///
  /// - [nextNextInstruction] - Instruction after the next one.
  /// - [previousInstruction] - Previous instruction.
  /// - [hasNextTurnInfo] - Check for immediate next turn info.
  RouteInstruction? get nextInstruction {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNextInstruction',
    );

    final GemError gemApiError = GemErrorExtension.fromCode(
      resultString['gemApiError'],
    );

    if (gemApiError != GemError.success) {
      return null;
    }

    return RouteInstruction.init(resultString['result']);
  }

  /// Instruction after the next one on the route.
  ///
  /// Returns the [RouteInstruction] two steps ahead of the current navigation
  /// position. Returns null if unavailable (e.g., when the next instruction is
  /// the destination).
  ///
  /// ## Returns
  ///
  /// - (RouteInstruction?) Next-next route instruction, or null if not available.
  ///
  /// ## See also:
  ///
  /// - [nextInstruction] - Immediate next instruction.
  /// - [hasNextNextTurnInfo] - Check if next-next turn info is available.
  RouteInstruction? get nextNextInstruction {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNextNextInstruction',
    );

    final GemError gemApiError = GemErrorExtension.fromCode(
      resultString['gemApiError'],
    );

    if (gemApiError != GemError.success) {
      return null;
    }

    return RouteInstruction.init(resultString['result']);
  }

  /// Previous route instruction on the route.
  ///
  /// Returns the [RouteInstruction] immediately before the current navigation
  /// position. Returns null if unavailable (e.g., at the start of the route or
  /// if an error occurs).
  ///
  /// ## Returns
  ///
  /// - (RouteInstruction?) Previous route instruction, or null if not available.
  ///
  /// ## See also:
  ///
  /// - [nextInstruction] - Next instruction.
  RouteInstruction? get previousInstruction {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getPreviousInstruction',
    );

    final GemError gemApiError = GemErrorExtension.fromCode(
      resultString['gemApiError'],
    );

    if (gemApiError != GemError.success) {
      return null;
    }

    return RouteInstruction.init(resultString['result']);
  }

  /// Current position during navigation.
  ///
  /// Returns the current geographic position with additional navigation context.
  /// Returns null if position information is unavailable.
  ///
  /// ## Returns
  ///
  /// - (GemPosition?) Current position, or null if not available.
  GemPosition? get currentPosition {
    final OperationResult retVal = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getCurrentPosition',
      args: DataType.position.id,
    );

    final GemError gemApiError = GemErrorExtension.fromCode(
      retVal['gemApiError'],
    );

    if (gemApiError != GemError.success) {
      return null;
    }

    final dynamic result = retVal['result'];
    if (result != null) {
      return GemPositionImpl.fromJson(result);
    }
    return null;
  }

  /// Check if next-next turn information is available.
  ///
  /// Returns true if information about the turn after the next one is available.
  /// May return false if the next instruction is the destination or if data is
  /// unavailable. Always check this before accessing [nextNextTurnDetails] or
  /// related properties.
  ///
  /// ## Returns
  ///
  /// - (bool) True if next-next turn information is available, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [nextNextTurnDetails] - Details for the next-next turn.
  /// - [hasNextTurnInfo] - Check for immediate next turn info.
  bool get hasNextNextTurnInfo {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'hasNextNextTurnInfo',
    );

    return resultString['result'];
  }

  /// Check if next turn information is available.
  ///
  /// Returns true if information about the immediate next turn is available.
  /// Always check this before accessing [nextTurnDetails] or related properties
  /// to avoid errors.
  ///
  /// ## Returns
  ///
  /// - (bool) True if next turn information is available, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [nextTurnDetails] - Details for the next turn.
  /// - [hasNextNextTurnInfo] - Check for next-next turn info.
  bool get hasNextTurnInfo {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'hasNextTurnInfo',
    );

    return resultString['result'];
  }

  /// Index of the current route instruction on the current [RouteSegment].
  ///
  /// Returns the zero-based index of the current instruction within the active
  /// route segment. Useful for tracking progress through a segment.
  ///
  /// ## Returns
  ///
  /// - (int) Index of the current route instruction on the segment.
  ///
  /// ## See also:
  ///
  /// - [segmentIndex] - Index of the current route segment.
  int get instructionIndex {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getInstructionIndex',
    );

    return resultString['result'];
  }

  /// Lane configuration image for the current position.
  ///
  /// Renders an image showing the available lanes and which lane(s) to use for
  /// the upcoming maneuver. Customizable via size, format, and rendering settings.
  /// Returns null if lane information is unavailable.
  ///
  /// ## Parameters
  ///
  /// - [size]: (Size?) Desired image dimensions.
  /// - [format]: (ImageFileFormat?) Image format (PNG, JPEG, etc.).
  /// - [renderSettings]: (LaneImageRenderSettings) Rendering configuration. Defaults to `const LaneImageRenderSettings()`.
  /// - [allowResize]: (bool) Allow SDK to adjust size for optimal rendering. Defaults to `false`.
  ///
  /// ## Returns
  ///
  /// - (Uint8List?) Lane image data, or null if not available.
  ///
  /// ## See also:
  ///
  /// - [laneImg] - Lane image object.
  /// - [LaneImageRenderSettings] - Customize lane image rendering.
  Uint8List? getLaneImage({
    final Size? size,
    final ImageFileFormat? format,
    final LaneImageRenderSettings renderSettings =
        const LaneImageRenderSettings(),
    final bool allowResize = false,
  }) {
    return GemKitPlatform.instance.callGetImage(
      pointerId,
      'NavigationInstructionGetLaneImage',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
      arg: jsonEncode(renderSettings),
      allowResize: allowResize,
    );
  }

  /// Get the vectorial lane image as a [LaneImg].
  ///
  /// Prefer [LaneImg] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getLaneImage] when you only need the raster image bytes.
  ///
  /// ## Returns
  ///
  /// - (LaneImg) Lane image object (validate before use).
  ///
  /// ## See also:
  ///
  /// - [getLaneImage] - Simpler method to get lane image bytes directly.
  LaneImg get laneImg {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getLaneImg',
    );

    return LaneImg.init(resultString['result']);
  }

  /// Current navigation or simulation status.
  ///
  /// Returns the current state of the navigation/simulation session (e.g., running,
  /// paused, waiting to return to route, finished).
  ///
  /// ## Returns
  ///
  /// - (NavigationStatus) Current navigation/simulation status.
  ///
  /// ## See also:
  ///
  /// - [returnToRoutePosition] - Valid when status is `waitingReturnToRoute`.
  NavigationStatus get navigationStatus {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNavigationStatus',
    );

    return NavigationStatusExtension.fromId(resultString['result']);
  }

  /// ISO 3166-1 alpha-3 country code for the next road segment.
  ///
  /// Returns the three-letter country code for the road segment after the next
  /// turn or maneuver. Returns an empty string if country information is unavailable.
  ///
  /// ## Returns
  ///
  /// - (String) ISO 3166-1 alpha-3 country code, or empty string if not available.
  ///
  /// ## See also:
  ///
  /// - [currentCountryCodeISO] - Country code for the current road segment.
  /// - [MapDetails] - Querry details about a map by country code.
  String get nextCountryCodeISO {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNextCountryCodeISO',
    );

    return resultString['result'];
  }

  /// Street name for the road after the next turn.
  ///
  /// Returns the name of the street two maneuvers ahead. May return an empty string
  /// if the street has no assigned name or if information is unavailable. Always
  /// check [hasNextNextTurnInfo] before relying on this value.
  ///
  /// ## Returns
  ///
  /// - (String) Street name, or empty string if not available.
  ///
  /// ## See also:
  ///
  /// - [nextStreetName] - Name of the next street.
  /// - [hasNextNextTurnInfo] - Check if next-next turn info is available.
  String get nextNextStreetName {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNextNextStreetName',
    );

    return resultString['result'];
  }

  /// Full details for the turn after the next one.
  ///
  /// Provides comprehensive information about the second upcoming turn, including
  /// geometry, turn event type, and roundabout exit number. Use this for
  /// customized UI rendering. Always check [hasNextNextTurnInfo] before accessing.
  /// Returns null if not available.
  ///
  /// ## Returns
  ///
  /// - (TurnDetails?) Details for the next-next turn, or null if not available.
  ///
  /// ## See also:
  ///
  /// - [nextTurnDetails] - Details for the immediate next turn.
  /// - [getNextNextTurnImage] - Simplified schematic image.
  TurnDetails? get nextNextTurnDetails {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNextNextTurnDetails',
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return TurnDetails.init(resultString['result']);
  }

  /// Simplified schematic image for the turn after the next one.
  ///
  /// Returns a simplified turn icon for the second upcoming maneuver. For a
  /// detailed geometry image, use `nextNextTurnDetails.abstractGeometryImg`.
  /// Returns null if unavailable. Always check [hasNextNextTurnInfo] first.
  ///
  /// ## Parameters
  ///
  /// - [size]: (Size?) Desired image dimensions.
  /// - [format]: (ImageFileFormat?) Image format (PNG, JPEG, etc.).
  ///
  /// ## Returns
  ///
  /// - (Uint8List?) Turn image data, or null if not available.
  ///
  /// ## See also:
  ///
  /// - [nextNextTurnDetails] - Full details including detailed geometry.
  /// - [getNextTurnImage] - Image for the immediate next turn.
  Uint8List? getNextNextTurnImage({
    final Size? size,
    final ImageFileFormat? format,
  }) {
    return GemKitPlatform.instance.callGetImage(
      pointerId,
      'NavigationInstructionGetNextNextTurnImage',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
    );
  }

  /// Get the image of the turn after the next one as a [Img].
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getNextNextTurnImage] when you only need raw image bytes.
  ///
  /// ## Returns
  ///
  /// - (Img) Turn image object (validate before use).
  ///
  /// ## See also:
  ///
  /// - [getNextNextTurnImage] - Simpler method to get turn image bytes.
  /// - [nextTurnImg] - Image for the immediate next turn.
  Img get nextNextTurnImg {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNextNextTurnImg',
    );

    return Img.init(resultString['result']);
  }

  /// Textual description for the turn after the next one.
  ///
  /// Returns a human-readable instruction string (e.g., "Turn left onto Main St")
  /// for the second upcoming maneuver. Suitable for displaying in navigation UI.
  /// Always check [hasNextNextTurnInfo] before relying on this value.
  ///
  /// Note: For text-to-speech output, use the `onTextToSpeechInstruction` callback
  /// from [NavigationService] instead.
  ///
  /// ## Returns
  ///
  /// - (String) Instruction text for the next-next turn.
  ///
  /// ## See also:
  ///
  /// - [nextTurnInstruction] - Instruction for the immediate next turn.
  String get nextNextTurnInstruction {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNextNextTurnInstruction',
    );

    return _capitalizeFirstCharLatin(resultString['result']);
  }

  /// Next speed limit variation within a specified distance.
  ///
  /// Searches ahead on the planned route for speed limit changes within the
  /// specified distance. Returns a [NextSpeedLimit] object containing the location,
  /// distance, and new speed limit value. Check [NextSpeedLimit.status] to
  /// determine result validity.
  ///
  /// Calculates the result in dynamic way, two calls with the same parameters may return different results.
  ///
  /// ## Parameters
  ///
  /// - [checkDistance]: (int) Search distance in meters. Defaults to maximum int value (no limit).
  ///
  /// ## Returns
  ///
  /// - (NextSpeedLimit) Speed limit variation details.
  ///
  /// ## See also:
  ///
  /// - [currentStreetSpeedLimit] - Current road speed limit.
  /// - [NextSpeedLimit] - Result object with distance, speed, and status.
  NextSpeedLimit getNextSpeedLimitVariation({
    final int checkDistance = 2147483647,
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNextSpeedLimitVariation',
      args: checkDistance,
    );

    return NextSpeedLimit.fromJson(resultString['result']);
  }

  /// Street name for the road after the next turn.
  ///
  /// Returns the name of the street following the immediate next maneuver. May
  /// return an empty string if the street has no assigned name or if information
  /// is unavailable. Always check [hasNextTurnInfo] before relying on this value.
  ///
  /// ## Returns
  ///
  /// - (String) Street name, or empty string if not available.
  ///
  /// ## See also:
  ///
  /// - [currentStreetName] - Name of the current street.
  /// - [nextNextStreetName] - Street name two maneuvers ahead.
  String get nextStreetName {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNextStreetName',
    );

    return resultString['result'];
  }

  /// Full details for the immediate next turn.
  ///
  /// Provides comprehensive information about the upcoming turn, including geometry,
  /// turn event type, and roundabout exit number. Use this for customized UI
  /// rendering instead of [getNextTurnImage] for more control. Always check
  /// [hasNextTurnInfo] before accessing. Returns null if not available.
  ///
  /// ## Returns
  ///
  /// - (TurnDetails?) Details for the next turn, or null if not available.
  ///
  /// ## See also:
  ///
  /// - [getNextTurnImage] - Simplified schematic turn image.
  /// - [nextNextTurnDetails] - Details for the turn after next.
  TurnDetails? get nextTurnDetails {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNextTurnDetails',
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return TurnDetails.init(resultString['result']);
  }

  /// Simplified schematic image for the immediate next turn.
  ///
  /// Returns a simplified turn icon for the upcoming maneuver. For a detailed
  /// geometry image, use `nextTurnDetails.abstractGeometryImg`. Returns null
  /// if unavailable. Always check [hasNextTurnInfo] first.
  ///
  /// ## Parameters
  ///
  /// - [size]: (Size?) Desired image dimensions.
  /// - [format]: (ImageFileFormat?) Image format (PNG, JPEG, etc.).
  ///
  /// ## Returns
  ///
  /// - (Uint8List?) Turn image data, or null if not available.
  ///
  /// ## See also:
  ///
  /// - [nextTurnDetails] - Full details including detailed geometry.
  /// - [getNextNextTurnImage] - Image for the turn after next.
  Uint8List? getNextTurnImage({
    final Size? size,
    final ImageFileFormat? format,
  }) {
    return GemKitPlatform.instance.callGetImage(
      pointerId,
      'NavigationInstructionGetNextTurnImage',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
    );
  }

  /// Get the image of the immediate next turn as a [Img].
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getNextTurnImage] when you only need raw image bytes.
  ///
  /// ## Returns
  ///
  /// - (Img) Turn image object (validate before use).
  ///
  /// ## See also:
  ///
  /// - [getNextTurnImage] - Simpler method to get turn image bytes.
  /// - [nextNextTurnImg] - Image for the turn after next.
  Img get nextTurnImg {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNextTurnImg',
    );

    return Img.init(resultString['result']);
  }

  /// Textual description for the immediate next turn.
  ///
  /// Returns a human-readable instruction string (e.g., "Turn right onto Highway 101")
  /// for the upcoming maneuver. Suitable for displaying in navigation UI. Always
  /// check [hasNextTurnInfo] before relying on this value.
  ///
  /// Note: For text-to-speech output, use the `onTextToSpeechInstruction` callback
  /// from [NavigationService] instead.
  ///
  /// ## Returns
  ///
  /// - (String) Instruction text for the next turn.
  ///
  /// ## See also:
  ///
  /// - [nextNextTurnInstruction] - Instruction for the turn after next.
  /// - [hasNextTurnInfo] - Check for immediate next turn info.
  String get nextTurnInstruction {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNextTurnInstruction',
    );

    return _capitalizeFirstCharLatin(resultString['result']);
  }

  /// Remaining travel time and distance to the final destination.
  ///
  /// Returns estimated remaining travel time (seconds) and distance (meters) to
  /// the route's final destination, accounting for current traffic conditions and
  /// route geometry.
  ///
  /// ## Returns
  ///
  /// - (TimeDistance) Remaining time (seconds) and distance (meters) to destination.
  ///
  /// ## See also:
  ///
  /// - [remainingTravelTimeDistanceToNextWaypoint] - Time/distance to next waypoint.
  /// - [traveledTimeDistance] - Time/distance already traveled.
  TimeDistance get remainingTravelTimeDistance {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getRemainingTravelTimeDistance',
    );

    return TimeDistance.fromJson(resultString['result']);
  }

  /// Remaining travel time and distance to the next waypoint.
  ///
  /// Returns estimated remaining travel time (seconds) and distance (meters) to
  /// the next intermediate waypoint on the route, accounting for current traffic
  /// conditions and route geometry.
  ///
  /// ## Returns
  ///
  /// - (TimeDistance) Remaining time (seconds) and distance (meters) to next waypoint.
  ///
  /// ## See also:
  ///
  /// - [remainingTravelTimeDistance] - Time/distance to final destination.
  TimeDistance get remainingTravelTimeDistanceToNextWaypoint {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getRemainingTravelTimeDistanceToNextWaypoint',
    );

    return TimeDistance.fromJson(resultString['result']);
  }

  /// Current road information list.
  ///
  /// Returns detailed information about the current road, including official road
  /// designations (e.g., "A400", "I-95") and shield types. Complements
  /// [currentStreetName] with additional metadata.
  ///
  /// ## Returns
  ///
  /// - (`List<RoadInfo>`) Current road information list.
  ///
  /// ## See also:
  ///
  /// - [nextRoadInformation] - Road information for the next segment.
  /// - [currentStreetName] - Current street name.
  List<RoadInfo> get currentRoadInformation {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getCurrentRoadInformation',
    );

    final List<dynamic> res = resultString['result'];
    final List<RoadInfo> retList = res
        .map((dynamic e) => RoadInfo.fromJson(e))
        .toList();
    return retList;
  }

  /// Next road information list.
  ///
  /// Returns detailed information about the road after the next turn, including
  /// official road designations and shield types. Complements [nextStreetName]
  /// with additional metadata.
  ///
  /// ## Returns
  ///
  /// - (`List<RoadInfo>`) Next road information list.
  ///
  /// ## See also:
  ///
  /// - [currentRoadInformation] - Current road information.
  /// - [nextNextRoadInformation] - Road information two segments ahead.
  List<RoadInfo> get nextRoadInformation {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNextRoadInformation',
    );

    final List<dynamic> res = resultString['result'];
    final List<RoadInfo> retList = res
        .map((dynamic e) => RoadInfo.fromJson(e))
        .toList();
    return retList;
  }

  /// Road information two segments ahead.
  ///
  /// Returns detailed information about the road after the next-next turn,
  /// including official road designations and shield types. Complements
  /// [nextNextStreetName] with additional metadata.
  ///
  /// ## Returns
  ///
  /// - (`List<RoadInfo>`) Next-next road information list.
  ///
  /// ## See also:
  ///
  /// - [currentRoadInformation] - Current road information.
  /// - [nextRoadInformation] - Road information one segment ahead.
  List<RoadInfo> get nextNextRoadInformation {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getNextNextRoadInformation',
    );

    final List<dynamic> res = resultString['result'];
    final List<RoadInfo> retList = res
        .map((dynamic e) => RoadInfo.fromJson(e))
        .toList();
    return retList;
  }

  /// Current instruction segment index.
  ///
  /// Returns the zero-based index of the current [RouteSegment] within the active route.
  /// Increments as the user progresses through waypoints and route segments.
  ///
  /// ## Returns
  ///
  /// - (`int`) Current segment index (0-based).
  ///
  /// ## See also:
  ///
  /// - [instructionIndex] - Current instruction index within the route.
  int get segmentIndex {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getSegmentIndex',
    );

    return resultString['result'];
  }

  /// Whether signpost information is available.
  ///
  /// Checks if the current navigation instruction has associated signpost
  /// data (destination information typically displayed on highway signs).
  ///
  /// ## Returns
  ///
  /// - (`bool`) True if signpost information is available, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [signpostDetails] - Extended signpost details.
  /// - [signpostInstruction] - Signpost instruction text.
  bool get hasSignpostInfo {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'hasSignpostInfo',
    );

    return resultString['result'];
  }

  /// Extended signpost details.
  ///
  /// Returns structured signpost data including destination names, road numbers,
  /// exit information, and associated imagery. Available when [hasSignpostInfo]
  /// returns true.
  ///
  /// ## Returns
  ///
  /// - (`SignpostDetails?`) Signpost details object, or null if unavailable.
  ///
  /// ## See also:
  ///
  /// - [hasSignpostInfo] - Check signpost availability.
  /// - [signpostInstruction] - Signpost instruction text.
  SignpostDetails? get signpostDetails {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getSignpostDetails',
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return SignpostDetails.init(resultString['result']);
  }

  /// Textual signpost instruction.
  ///
  /// Returns a human-readable description of the signpost information,
  /// combining destination names, exit numbers, and road designations into
  /// a single formatted string.
  ///
  /// ## Returns
  ///
  /// - (`String`) Textual signpost instruction.
  ///
  /// ## See also:
  ///
  /// - [signpostDetails] - Structured signpost data.
  /// - [hasSignpostInfo] - Check signpost availability.
  String get signpostInstruction {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getSignpostInstruction',
    );

    return resultString['result'];
  }

  /// Time and distance to next-next turn.
  ///
  /// Returns the estimated time (in seconds) and distance (in meters) from the
  /// current position to the turn after the next turn. If no next-next turn is
  /// available, returns time/distance to the next turn instead.
  ///
  /// ## Returns
  ///
  /// - (`TimeDistance`) Time (seconds) and distance (meters) to next-next turn.
  ///
  /// ## See also:
  ///
  /// - [timeDistanceToNextTurn] - Time/distance to next turn.
  /// - [remainingTravelTimeDistance] - Total remaining time/distance.
  TimeDistance get timeDistanceToNextNextTurn {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getTimeDistanceToNextNextTurn',
    );

    return TimeDistance.fromJson(resultString['result']);
  }

  /// Time and distance to next turn.
  ///
  /// Returns the estimated time (in seconds) and distance (in meters) from the
  /// current position to the next turn instruction. Updated continuously as the
  /// user approaches the turn.
  ///
  /// ## Returns
  ///
  /// - (`TimeDistance`) Time (seconds) and distance (meters) to next turn.
  ///
  /// ## See also:
  ///
  /// - [timeDistanceToNextNextTurn] - Time/distance to next-next turn.
  /// - [remainingTravelTimeDistance] - Total remaining time/distance.
  TimeDistance get timeDistanceToNextTurn {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getTimeDistanceToNextTurn',
    );

    return TimeDistance.fromJson(resultString['result']);
  }

  /// Traveled time and distance.
  ///
  /// Returns the cumulative time (in seconds) and distance (in meters) traveled
  /// since navigation started or since the last waypoint was reached.
  ///
  /// ## Returns
  ///
  /// - (`TimeDistance`) Traveled time (seconds) and distance (meters).
  ///
  /// ## See also:
  ///
  /// - [remainingTravelTimeDistance] - Remaining time/distance.
  /// - [timeDistanceToNextTurn] - Time/distance to next turn.
  TimeDistance get traveledTimeDistance {
    final OperationResult resultString = objectMethod(
      pointerId,
      'NavigationInstruction',
      'getTraveledTimeDistance',
    );

    return TimeDistance.fromJson(resultString['result']);
  }

  /// Capitalize the first character if it's a latin letter
  String _capitalizeFirstCharLatin(String input) {
    if (input.isEmpty) {
      return input;
    }

    final String firstChar = input[0];
    final String rest = input.substring(1);

    final bool isLatinLetter = RegExp(r'[A-Za-z]').hasMatch(firstChar);

    if (isLatinLetter) {
      return firstChar.toUpperCase() + rest;
    }
    return input;
  }
}

/// The status of a [NextSpeedLimit] item
///
/// {@category Navigation}
enum NextSpeedLimitStatus {
  /// The speed changes within the given distance
  withSpeedChange,

  /// The speed does not change within the given distance
  noSpeedChange,

  /// No speed info is available
  noData,
}

/// Navigation state enumeration.
///
/// Defines the possible states of an active navigation session, indicating
/// whether navigation is proceeding normally or is paused awaiting specific
/// conditions (route update, GPS recovery, return to route).
///
/// ## See also:
///
/// - [NavigationInstruction.navigationStatus] - Current navigation status.
///
/// {@category Navigation}
enum NavigationStatus {
  /// Running, this is the normal state
  running,

  /// Paused, waiting for route to update
  ///
  /// Check navigation route status for details about route update
  waitingRoute,

  /// Paused, waiting for GPS location to recover
  waitingGps,

  /// Paused, waiting to return to the route ( re-routing disabled case )
  waitingReturnToRoute,
}

/// @nodoc
extension NavigationStatusExtension on NavigationStatus {
  int get id {
    switch (this) {
      case NavigationStatus.running:
        return 0;
      case NavigationStatus.waitingRoute:
        return 1;
      case NavigationStatus.waitingGps:
        return 2;
      case NavigationStatus.waitingReturnToRoute:
        return 3;
    }
  }

  static NavigationStatus fromId(final int id) {
    switch (id) {
      case 0:
        return NavigationStatus.running;
      case 1:
        return NavigationStatus.waitingRoute;
      case 2:
        return NavigationStatus.waitingGps;
      case 3:
        return NavigationStatus.waitingReturnToRoute;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// The type of road information to retrieve.
///
/// Used within [NavigationInstruction.getRoadInfoImgByType] to specify which road information image to retrieve (current or next).
/// Offers better performance than retrieving the full road information list when only an image is needed for the current or next road segment.
///
/// ## See also:
///
/// - [NavigationInstruction.getRoadInfoImgByType] - Method to retrieve road information image by type.
///
/// {@category Navigation}
enum RoadInfoType {
  /// Road information for the current road segment.
  currentRoadInformation,

  /// Road information for the next road segment after the upcoming turn.
  nextRoadInformation,

  /// Road information for the segment after the next turn (two ahead).
  nextNextRoadInformation,
}

/// @nodoc
extension RoadInfoTypeExtension on RoadInfoType {
  int get id {
    switch (this) {
      case RoadInfoType.currentRoadInformation:
        return 0;
      case RoadInfoType.nextRoadInformation:
        return 1;
      case RoadInfoType.nextNextRoadInformation:
        return 2;
    }
  }

  static RoadInfoType fromId(final int id) {
    switch (id) {
      case 0:
        return RoadInfoType.currentRoadInformation;
      case 1:
        return RoadInfoType.nextRoadInformation;
      case 2:
        return RoadInfoType.nextNextRoadInformation;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
