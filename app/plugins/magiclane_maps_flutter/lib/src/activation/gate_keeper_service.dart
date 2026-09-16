// SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// The [Gate] enum represents the different gates that can be checked by the [GateKeeperService].
///
/// {@category Activation}
@experimental
enum Gate {
  /// Used as a default value
  unknown,

  /// Core gate, unlocks the base functionality.
  core,
}

/// @nodoc
extension GateExtension on Gate {
  static Gate fromId(final int code) {
    switch (code) {
      case 0:
        return Gate.unknown;
      case 1:
        return Gate.core;
      default:
        throw ArgumentError('Invalid id');
    }
  }

  int get id {
    switch (this) {
      case Gate.unknown:
        return 0;
      case Gate.core:
        return 1;
    }
  }
}

/// [GateKeeperService] decisions. Describes the kind of states a [GateStatus] can be in.
///
/// {@category Activation}
@experimental
enum GateDecision {
  /// The gate is open, the user is allowed to use the gate.
  allowed,

  /// The gate is closed, the user is not allowed to use the gate.
  deniedNotOwned,

  /// The gate is closed, the user is not allowed to use the gate because the subscription has expired.
  deniedExpired,

  /// The gate is closed, the user is not allowed to use the gate because the subscription has been revoked.
  deniedPending,

  /// The gate is closed, the user is not allowed to use the gate because the subscription has been revoked.
  deniedRevoked,

  /// The gate is closed, the user is not allowed to use the gate because the subscription is not yet valid.
  deniedNotYetValid,
}

/// @nodoc
extension GateDecisionExtension on GateDecision {
  static GateDecision fromId(final int code) {
    switch (code) {
      case 0:
        return GateDecision.allowed;
      case 1:
        return GateDecision.deniedNotOwned;
      case 2:
        return GateDecision.deniedExpired;
      case 3:
        return GateDecision.deniedPending;
      case 4:
        return GateDecision.deniedRevoked;
      case 5:
        return GateDecision.deniedNotYetValid;
      default:
        throw ArgumentError('Invalid id');
    }
  }

  int get id {
    switch (this) {
      case GateDecision.allowed:
        return 0;
      case GateDecision.deniedNotOwned:
        return 1;
      case GateDecision.deniedExpired:
        return 2;
      case GateDecision.deniedPending:
        return 3;
      case GateDecision.deniedRevoked:
        return 4;
      case GateDecision.deniedNotYetValid:
        return 5;
    }
  }
}

/// Gives more details about the status of a gate, such as the decision, the time until which the decision is valid,
/// and a reason for the decision.
///
/// Use the [GateKeeperService.getStatus] to obtain the [GateStatus] for a specific gate.
///
/// {@category Activation}
@experimental
class GateStatus {
  /// Creates a new [GateStatus] with the given [decision], [notAfter], and [reason].
  /// The API user does not normally need to construct instances directly.
  ///
  /// ## Parameters
  ///
  /// - [decision]: The decision of the gate status.
  /// - [notAfter]: The expiry time of the Gate.
  /// - [reason]: Short reason for the decision.
  GateStatus({
    required this.decision,
    required this.notAfter,
    required this.reason,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  factory GateStatus.fromJson(Map<String, dynamic> json) {
    return GateStatus(
      decision: GateDecisionExtension.fromId(json['decision']),
      notAfter: DateTime.fromMillisecondsSinceEpoch(
        json['notAfter'],
        isUtc: true,
      ),
      reason: json['reason'],
    );
  }

  /// The decision of the gate status.
  final GateDecision decision;

  /// The expiry time of the Gate (UTC).
  final DateTime notAfter;

  /// Short reason for the decision
  final String reason;
}

/// Service used to check the status of gates.
///
/// {@category Activation}
@experimental
abstract class GateKeeperService {
  /// Checks whether or not the SDK has the gate and is available.
  ///
  /// ## Parameters
  ///
  /// - [gate]: The gate to check, defaults to [Gate.core].
  ///
  /// ## Returns
  ///
  /// - True if the gate is available, false otherwise.
  static bool has([Gate gate = Gate.core]) {
    final OperationResult resultString = staticMethod(
      'GateKeeper',
      'has',
      args: gate.id,
    );

    return resultString['result'];
  }

  /// Gets the status of the specified gate.
  ///
  /// ## Parameters
  ///
  /// - [gate]: The gate to check, defaults to [Gate.core].
  ///
  /// ## Returns
  ///
  /// - The status of the gate, including the decision, expiry time, and reason.
  static GateStatus getStatus([Gate gate = Gate.core]) {
    final OperationResult resultMap = staticMethod(
      'GateKeeper',
      'getStatus',
      args: gate.id,
    );

    return GateStatus.fromJson(resultMap['result']);
  }
}
