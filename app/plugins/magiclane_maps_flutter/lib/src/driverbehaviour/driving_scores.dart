// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Driving scores for a driving session.
///
/// Each score quantifies safety for a specific driving aspect. Scores range
/// from 0 (unsafe) to 100 (safe). A value of -1 indicates the score is not
/// available.
///
/// This class is returned by [DriverBehaviourAnalysis.drivingScores] and is
/// not intended to be instantiated directly by library users.
///
/// {@category Driver Behaviour}
class DrivingScores extends GemAutoreleaseObject {
  // ignore: unused_element
  DrivingScores._() : super(-1);

  @internal
  DrivingScores.init(super.id);

  /// Average-speed related risk score.
  ///
  /// ## Returns
  ///
  /// - A double in `[0, 100]`, or -1 if unavailable.
  double get speedAverageRiskScore {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DrivingScores',
      'getSpeedAverageRiskScore',
    );

    return resultString['result'];
  }

  /// Risk score for speed variation (consistency).
  ///
  /// ## Returns
  ///
  /// - A double in `[0, 100]`, or -1 if unavailable.
  double get speedVariableRiskScore {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DrivingScores',
      'getSpeedVariableRiskScore',
    );

    return resultString['result'];
  }

  /// Risk score for harsh acceleration events.
  ///
  /// ## Returns
  ///
  /// - A double in `[0, 100]`, or -1 if unavailable.
  double get harshAccelerationScore {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DrivingScores',
      'getHarshAccelerationScore',
    );

    return resultString['result'];
  }

  /// Risk score for harsh braking events.
  ///
  /// ## Returns
  ///
  /// - A double in `[0, 100]`, or -1 if unavailable.
  double get harshBrakingScore {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DrivingScores',
      'getHarshBrakingScore',
    );

    return resultString['result'];
  }

  /// Risk score for swerving behaviour.
  ///
  /// ## Returns
  ///
  /// - A double in `[0, 100]`, or -1 if unavailable.
  double get swervingScore {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DrivingScores',
      'getSwervingScore',
    );

    return resultString['result'];
  }

  /// Risk score for cornering behaviour.
  ///
  /// ## Returns
  ///
  /// - A double in `[0, 100]`, or -1 if unavailable.
  double get corneringScore {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DrivingScores',
      'getCorneringScore',
    );

    return resultString['result'];
  }

  /// Risk score for tailgating behaviour.
  ///
  /// This API is experimental and may change in future releases.
  ///
  /// ## Returns
  ///
  /// - A double in `[0, 100]`, or -1 if unavailable.
  @experimental
  double get tailgatingScore {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DrivingScores',
      'getTailgatingScore',
    );

    return resultString['result'];
  }

  /// Risk score for instances where stop signs were ignored.
  ///
  /// ## Returns
  ///
  /// - A double in `[0, 100]`, or -1 if unavailable.
  double get ignoredStopSignsScore {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DrivingScores',
      'getIgnoredStopSignsScore',
    );

    return resultString['result'];
  }

  /// Risk score indicating potential driver fatigue.
  ///
  /// ## Returns
  ///
  /// - A double in `[0, 100]`, or -1 if unavailable.
  double get fatigueScore {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DrivingScores',
      'getFatigueScore',
    );

    return resultString['result'];
  }

  /// Aggregate driving safety score combining the partial scores.
  ///
  /// ## Returns
  ///
  /// - A double in `[0, 100]`, or -1 if unavailable.
  double get aggregateScore {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DrivingScores',
      'getAggregateScore',
    );

    return resultString['result'];
  }
}
