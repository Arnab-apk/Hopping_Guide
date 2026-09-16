// SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/navigation.dart';
import 'package:meta/meta.dart';

/// Detailed information about a navigation instruction update.
///
/// Provided by the `onNavigationInstructionOptimized` callback in
/// [NavigationService.startNavigation] and [NavigationService.startSimulation].
/// Contains the set of instruction fields that changed since the last update,
/// enabling efficient UI updates by redrawing only affected components.
///
/// ## See also:
///
/// - [NavigationService.startNavigation] - Register the optimized instruction callback.
/// - [NavigationInstructionDifferenceResult] - Enumeration of diffable instruction fields.
/// - [NavigationInstructionUpdateEvents] - Events that triggered the update.
///
/// {@category Navigation}
class NavigationInstructionUpdateInfo {
  /// Creates a [NavigationInstructionUpdateInfo] instance.
  ///
  /// The API users typically do not create [NavigationInstructionUpdateInfo] instances directly.
  ///
  /// ## Parameters
  ///
  /// - [differences]: Set of instruction fields that differ from the previous update.
  /// - [hasNewRoute]: Whether the update is due to a new route being set (e.g. after recalculation). When true, [differences] is empty because all fields should be considered changed.
  /// - [events]: Set of events that triggered this instruction update.
  NavigationInstructionUpdateInfo({
    required this.differences,
    required this.hasNewRoute,
    required this.events,
  });

  /// Deserializes a [NavigationInstructionUpdateInfo] from a native event map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory NavigationInstructionUpdateInfo.fromJson(Map<dynamic, dynamic> json) {
    final int eventsInt = json['events'] as int;
    final Set<NavigationInstructionUpdateEvents> events =
        <NavigationInstructionUpdateEvents>{};
    for (final NavigationInstructionUpdateEvents event
        in NavigationInstructionUpdateEvents.values) {
      if (event.id & eventsInt != 0) {
        events.add(event);
      }
    }

    final List<dynamic> diffsRaw = json['differences'] as List<dynamic>;
    final Set<NavigationInstructionDifferenceResult> differences =
        <NavigationInstructionDifferenceResult>{};
    for (final dynamic diff in diffsRaw) {
      differences.add(
        NavigationInstructionDifferenceResultExtension.fromId(diff as int),
      );
    }

    return NavigationInstructionUpdateInfo(
      differences: differences,
      hasNewRoute: json['hasNewRoute'] as bool,
      events: events,
    );
  }

  /// The set of instruction fields that differ from the previous instruction.
  Set<NavigationInstructionDifferenceResult> differences;

  /// Whether the update is due to a new route being set (e.g. after recalculation).
  ///
  /// When true, [differences] is empty because all fields should be considered changed.
  bool hasNewRoute;

  /// The set of events that triggered this instruction update.
  Set<NavigationInstructionUpdateEvents> events;
}

/// Identifies which field of a [NavigationInstruction] changed between two consecutive updates.
///
/// Used in [NavigationInstructionUpdateInfo.differences] to allow efficient,
/// targeted UI refreshes when using the optimized instruction callback.
///
/// ## See also:
///
/// - [NavigationInstructionUpdateInfo] - Update info containing the difference set.
/// - [NavigationService.startNavigation] - Register the optimized instruction callback.
///
/// {@category Navigation}
enum NavigationInstructionDifferenceResult {
  /// Current country code changed.
  ///
  /// See: [NavigationInstruction.currentCountryCodeISO]
  currentCountryCode,

  /// Next country code changed.
  ///
  /// See: [NavigationInstruction.nextCountryCodeISO]
  nextCountryCode,

  /// Current street name changed.
  ///
  /// See: [NavigationInstruction.currentStreetName]
  currentStreetName,

  /// Next street name changed.
  ///
  /// See: [NavigationInstruction.nextStreetName]
  nextStreetName,

  /// Current street speed limit changed.
  ///
  /// See: [NavigationInstruction.currentStreetSpeedLimit]
  currentStreetSpeedLimit,

  /// Drive side changed.
  ///
  /// See: [NavigationInstruction.driveSide]
  driveSide,

  /// Return-to-route state changed.
  ///
  /// See: [NavigationInstruction.returnToRouteImage] and
  /// [NavigationInstruction.returnToRoutePosition]. Only valid when status is
  /// [NavigationStatus.waitingReturnToRoute].
  returnToRoute,

  /// Next route instruction changed (instruction index and segment).
  ///
  /// See: [NavigationInstruction.instructionIndex] and
  /// [NavigationInstruction.segmentIndex]
  nextRouteInstruction,

  /// Next-turn info availability changed.
  ///
  /// See: [NavigationInstruction.hasNextTurnInfo]
  hasNextTurnInfo,

  /// Next turn details changed (detailed geometry / `TurnDetails`).
  ///
  /// See: [NavigationInstruction.nextTurnDetails]
  nextTurnDetails,

  /// Next turn schematic image changed.
  ///
  /// See: [NavigationInstruction.nextTurnImg] and [NavigationInstruction.getNextTurnImage]
  nextTurnImage,

  /// Next turn instruction text changed.
  ///
  /// See: [NavigationInstruction.nextTurnInstruction]
  nextTurnInstruction,

  /// Lane image changed.
  ///
  /// See: [NavigationInstruction.laneImg] and [NavigationInstruction.getLaneImage]
  laneImage,

  /// Navigation status changed.
  ///
  /// See: [NavigationInstruction.navigationStatus]
  navigationStatus,

  /// Current road information list changed.
  ///
  /// See: [NavigationInstruction.currentRoadInformation]
  currentRoadInformation,

  /// Next road information list changed.
  ///
  /// See: [NavigationInstruction.nextRoadInformation]
  nextRoadInformation,

  /// Signpost information changed.
  ///
  /// See: [NavigationInstruction.hasSignpostInfo], [NavigationInstruction.signpostDetails]
  /// and [NavigationInstruction.signpostInstruction]
  signpost,
}

/// @nodoc
extension NavigationInstructionDifferenceResultExtension
    on NavigationInstructionDifferenceResult {
  static NavigationInstructionDifferenceResult fromId(final int code) {
    switch (code) {
      case 0:
        return NavigationInstructionDifferenceResult.currentCountryCode;
      case 1:
        return NavigationInstructionDifferenceResult.nextCountryCode;
      case 2:
        return NavigationInstructionDifferenceResult.currentStreetName;
      case 3:
        return NavigationInstructionDifferenceResult.nextStreetName;
      case 4:
        return NavigationInstructionDifferenceResult.currentStreetSpeedLimit;
      case 5:
        return NavigationInstructionDifferenceResult.driveSide;
      case 6:
        return NavigationInstructionDifferenceResult.returnToRoute;
      case 7:
        return NavigationInstructionDifferenceResult.nextRouteInstruction;
      case 8:
        return NavigationInstructionDifferenceResult.hasNextTurnInfo;
      case 9:
        return NavigationInstructionDifferenceResult.nextTurnDetails;
      case 10:
        return NavigationInstructionDifferenceResult.nextTurnImage;
      case 11:
        return NavigationInstructionDifferenceResult.nextTurnInstruction;
      case 12:
        return NavigationInstructionDifferenceResult.laneImage;
      case 13:
        return NavigationInstructionDifferenceResult.navigationStatus;
      case 14:
        return NavigationInstructionDifferenceResult.currentRoadInformation;
      case 15:
        return NavigationInstructionDifferenceResult.nextRoadInformation;
      case 16:
        return NavigationInstructionDifferenceResult.signpost;
      default:
        throw ArgumentError('Invalid id');
    }
  }

  int get id {
    switch (this) {
      case NavigationInstructionDifferenceResult.currentCountryCode:
        return 0;
      case NavigationInstructionDifferenceResult.nextCountryCode:
        return 1;
      case NavigationInstructionDifferenceResult.currentStreetName:
        return 2;
      case NavigationInstructionDifferenceResult.nextStreetName:
        return 3;
      case NavigationInstructionDifferenceResult.currentStreetSpeedLimit:
        return 4;
      case NavigationInstructionDifferenceResult.driveSide:
        return 5;
      case NavigationInstructionDifferenceResult.returnToRoute:
        return 6;
      case NavigationInstructionDifferenceResult.nextRouteInstruction:
        return 7;
      case NavigationInstructionDifferenceResult.hasNextTurnInfo:
        return 8;
      case NavigationInstructionDifferenceResult.nextTurnDetails:
        return 9;
      case NavigationInstructionDifferenceResult.nextTurnImage:
        return 10;
      case NavigationInstructionDifferenceResult.nextTurnInstruction:
        return 11;
      case NavigationInstructionDifferenceResult.laneImage:
        return 12;
      case NavigationInstructionDifferenceResult.navigationStatus:
        return 13;
      case NavigationInstructionDifferenceResult.currentRoadInformation:
        return 14;
      case NavigationInstructionDifferenceResult.nextRoadInformation:
        return 15;
      case NavigationInstructionDifferenceResult.signpost:
        return 16;
    }
  }
}
