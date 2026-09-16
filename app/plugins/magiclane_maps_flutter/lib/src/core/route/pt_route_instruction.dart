// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Public transport route instruction.
///
/// Instruction specific to public transport segments (for example platform and
/// schedule details). Instances are obtained from [PTRouteSegment.instructions]
/// when converting a route to a [PTRoute].
///
/// ## See also:
///
/// - [RouteInstruction.toPTRouteInstruction] - Create a [PTRouteInstruction] from a generic instruction.
/// - [PTRouteSegment.instructions] - Segments containing these instructions.
///
/// {@category Route}
class PTRouteInstruction extends RouteInstructionBase {
  PTRouteInstruction.init(super.id) : super.init();

  /// Instruction name (for example station or stop name).
  ///
  /// ## Returns
  ///
  /// - `String`: The instruction name.
  String get name {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteInstruction',
      'getName',
    );

    return resultString['result'];
  }

  /// Platform code for this instruction's stop, when available.
  ///
  /// ## Returns
  ///
  /// - `String`: Platform code or empty string if not available.
  String get platformCode {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteInstruction',
      'getPlatformCode',
    );

    return resultString['result'];
  }

  /// Scheduled arrival time for this instruction (UTC).
  ///
  /// ## Returns
  ///
  /// - [DateTime?]: Arrival time in UTC or `null` when unavailable.
  DateTime? get arrivalTime {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteInstruction',
      'getArrivalTime',
    );

    final int val = resultString['result'];
    if (val < -8640000000000000 || val > 8640000000000000) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(val, isUtc: true);
  }

  /// Scheduled departure time for this instruction (UTC).
  ///
  /// ## Returns
  ///
  /// - [DateTime?]: Departure time in UTC or `null` when unavailable.
  DateTime? get departureTime {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteInstruction',
      'getDepartureTime',
    );

    final int val = resultString['result'];
    if (val < -8640000000000000 || val > 8640000000000000) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(val, isUtc: true);
  }

  /// Whether wheelchair access is available for this instruction/stop.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when wheelchair support is provided.
  bool get hasWheelchairSupport {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRouteInstruction',
      'getHasWheelchairSupport',
    );

    return resultString['result'];
  }
}
