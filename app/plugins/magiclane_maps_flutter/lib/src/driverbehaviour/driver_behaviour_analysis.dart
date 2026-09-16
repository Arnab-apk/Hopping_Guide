// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Analysis results for a single driver behaviour session.
///
/// The analysis contains aggregated metrics (distance, duration, risk
/// percentages), counts of detected events (harsh braking, cornering, etc.),
/// and optionally the [DrivingScores] and a list of [MappedDrivingEvent]
/// instances. Instances are returned by [DriverBehaviour.stopAnalysis],
/// [DriverBehaviour.lastAnalysis] and related APIs. Always check
/// [DriverBehaviourAnalysis.isValid] before reading other properties.
///
/// ## See also:
///
/// - [DriverBehaviourAnalysis.drivingScores] - Represents driving scores for the session.
///
/// {@category Driver Behaviour}
class DriverBehaviourAnalysis extends GemAutoreleaseObject {
  // ignore: unused_element
  DriverBehaviourAnalysis._() : super(-1);

  @internal
  DriverBehaviourAnalysis.init(super.id);

  /// Start time of the session in milliseconds since Unix epoch (UTC).
  ///
  /// ## Returns
  ///
  /// - The start time in milliseconds since epoch.
  int get startTime {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getStartTime',
    );

    return resultString['result'];
  }

  /// Finish time of the session in milliseconds since Unix epoch (UTC).
  ///
  /// ## Returns
  ///
  /// - The finish time in milliseconds since epoch.
  int get finishTime {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getFinishTime',
    );

    return resultString['result'];
  }

  /// Total distance driven during the session, in kilometers.
  ///
  /// ## Returns
  ///
  /// - The driven distance in kilometres as a double.
  double get kilometersDriven {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getKilometersDriven',
    );

    return resultString['result'];
  }

  /// Total driving time in minutes for the session.
  ///
  /// ## Returns
  ///
  /// - The number of minutes spent driving as a double.
  double get minutesDriven {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getMinutesDriven',
    );

    return resultString['result'];
  }

  /// Total elapsed time of the session in minutes (including non-driving
  /// pauses).
  ///
  /// ## Returns
  ///
  /// - The total elapsed minutes as a double.
  double get minutesTotalElapsed {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getMinutesTotalElapsed',
    );

    return resultString['result'];
  }

  /// Total minutes the driver exceeded applicable speed thresholds.
  ///
  /// ## Returns
  ///
  /// - Minutes spent speeding as a double.
  double get minutesSpeeding {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getMinutesSpeeding',
    );

    return resultString['result'];
  }

  /// Total minutes spent tailgating (following too closely).
  ///
  /// This metric is experimental and may be subject to change.
  ///
  /// ## Returns
  ///
  /// - Minutes spent tailgating as a double.
  @experimental
  double get minutesTailgating {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getMinutesTailgating',
    );

    return resultString['result'];
  }

  /// Percentage increase in accident probability related to mean speed.
  ///
  /// ## Returns
  ///
  /// - A percentage value (double) indicating increased risk.
  double get riskRelatedToMeanSpeed {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getRiskRelatedToMeanSpeed',
    );

    return resultString['result'];
  }

  /// Percentage increase in accident probability related to speed variation.
  ///
  /// ## Returns
  ///
  /// - A percentage value (double) indicating increased risk.
  double get riskRelatedToSpeedVariation {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getRiskRelatedToSpeedVariation',
    );

    return resultString['result'];
  }

  /// Count of harsh acceleration events detected during the session.
  ///
  /// ## Returns
  ///
  /// - The number of harsh acceleration events as an integer.
  int get numberOfHarshAccelerationEvents {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getNumberOfHarshAccelerationEvents',
    );

    return resultString['result'];
  }

  /// Count of harsh braking events detected during the session.
  ///
  /// ## Returns
  ///
  /// - The number of harsh braking events as an integer.
  int get numberOfHarshBrakingEvents {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getNumberOfHarshBrakingEvents',
    );

    return resultString['result'];
  }

  /// Count of cornering events detected during the session.
  ///
  /// ## Returns
  ///
  /// - The number of cornering events as an integer.
  int get numberOfCorneringEvents {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getNumberOfCorneringEvents',
    );

    return resultString['result'];
  }

  /// Count of swerving events detected during the session.
  ///
  /// ## Returns
  ///
  /// - The number of swerving events as an integer.
  int get numberOfSwervingEvents {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getNumberOfSwervingEvents',
    );

    return resultString['result'];
  }

  /// Count of ignored stop sign events detected during the session.
  ///
  /// ## Returns
  ///
  /// - The number of ignored stop signs as an integer.
  int get numberOfIgnoredStopSigns {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getNumberOfIgnoredStopSigns',
    );

    return resultString['result'];
  }

  /// Number of stop signs encountered during the session.
  ///
  /// ## Returns
  ///
  /// - The number of encountered stop signs as an integer.
  int get numberOfEncounteredStopSigns {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getNumberOfEncounteredStopSigns',
    );

    return resultString['result'];
  }

  /// Whether this analysis contains valid results.
  ///
  /// Always check this flag before accessing other properties of the
  /// analysis. If false, other fields may be missing or meaningless.
  ///
  /// ## Returns
  ///
  /// - True if the analysis is valid, false otherwise.
  bool get isValid {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'isValid',
    );

    return resultString['result'];
  }

  /// Driving scores (partial and aggregate) for this session.
  ///
  /// ## Returns
  ///
  /// - A [DrivingScores] instance or null if scores are unavailable.
  DrivingScores? get drivingScores {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getDrivingScores',
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return DrivingScores.init(resultString['result']);
  }

  /// All mapped driving events detected during the session.
  ///
  /// ## Returns
  ///
  /// - A list of [MappedDrivingEvent] instances (may be empty).
  List<MappedDrivingEvent> get drivingEvents {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviourAnalysis',
      'getDrivingEvents',
    );

    final List<dynamic> listJson = resultString['result'];
    final List<MappedDrivingEvent> retList = listJson
        .map((final dynamic eventId) => MappedDrivingEvent.init(eventId))
        .toList();
    return retList;
  }
}
