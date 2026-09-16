// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Manager for driver behaviour analysis: start/stop sessions and retrieve
/// results.
///
/// Use [DriverBehaviour.startAnalysis] to begin a session and
/// [DriverBehaviour.stopAnalysis] to finish it and obtain a
/// [DriverBehaviourAnalysis]. The instance must be created with a
/// configured [DataSource] and a flag indicating whether map-matching should
/// be applied to position data.
///
/// {@category Driver Behaviour}
class DriverBehaviour extends GemAutoreleaseObject {
  /// Creates a new driver behaviour instance.
  ///
  /// ## Parameters
  ///
  /// - [dataSource]: The configured [DataSource] that provides position and
  ///   sensor data used for analysis.
  /// - [useMapMatch]: If true, position samples will be matched to the road
  ///   network before analysis which can improve event detection accuracy.
  ///
  /// ## Also see:
  ///
  /// - [DataSource.createLiveDataSource] - To create a live data source from sensors.
  factory DriverBehaviour({
    required final DataSource dataSource,
    required final bool useMapMatch,
  }) {
    return DriverBehaviour._create(dataSource, useMapMatch);
  }
  // ignore: unused_element
  DriverBehaviour._() : super(-1);

  @internal
  DriverBehaviour.init(super.id);

  /// Start a new driver behaviour analysis session.
  ///
  /// ## Returns
  ///
  /// - True if the analysis was started successfully, false otherwise.
  ///
  /// ## Also see:
  ///
  /// - [DriverBehaviour.stopAnalysis] - To stop the analysis and retrieve results.
  /// - [DriverBehaviour.ongoingAnalysis] - To get the current ongoing analysis.
  bool startAnalysis() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviour',
      'startAnalysis',
    );

    return resultString['result'];
  }

  /// Stop the current analysis and return the completed analysis.
  ///
  /// ## Returns
  ///
  /// - A [DriverBehaviourAnalysis] instance when the analysis completed
  ///   successfully and contains valid data, or null if the analysis failed
  ///   or no valid data is available. Always check [DriverBehaviourAnalysis.isValid]
  ///   before using the returned analysis.
  ///
  /// ## Also see:
  ///
  /// - [DriverBehaviour.startAnalysis] - To start a new analysis session.
  /// - [DriverBehaviour.ongoingAnalysis] - To get the current ongoing analysis.
  DriverBehaviourAnalysis? stopAnalysis() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviour',
      'stopAnalysis',
    );

    if (resultString['result'] == -1 || resultString['gemApiError'] != 0) {
      return null;
    }

    return DriverBehaviourAnalysis.init(resultString['result']);
  }

  /// Retrieve the currently ongoing analysis (if any).
  ///
  /// ## Returns
  ///
  /// - A [DriverBehaviourAnalysis] instance representing the ongoing
  ///   analysis, or null if no valid analysis is in progress.
  ///
  /// ## Also see:
  ///
  /// - [DriverBehaviour.startAnalysis] - To start a new analysis session.
  /// - [DriverBehaviour.stopAnalysis] - To stop the analysis and retrieve results.
  /// - [getLastAnalysis] - To get the most recently completed analysis.
  @Deprecated('Use ongoingAnalysis getter instead')
  DriverBehaviourAnalysis? getOngoingAnalysis() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviour',
      'getOngoingAnalysis',
    );

    if (resultString['result'] == -1 || resultString['gemApiError'] != 0) {
      return null;
    }

    return DriverBehaviourAnalysis.init(resultString['result']);
  }

  /// Retrieve the currently ongoing analysis (if any).
  ///
  /// ## Returns
  ///
  /// - A [DriverBehaviourAnalysis] instance representing the ongoing
  ///   analysis, or null if no valid analysis is in progress.
  ///
  /// ## Also see:
  ///
  /// - [DriverBehaviour.startAnalysis] - To start a new analysis session.
  /// - [DriverBehaviour.stopAnalysis] - To stop the analysis and retrieve results.
  /// - [lastAnalysis] - To get the most recently completed analysis.
  DriverBehaviourAnalysis? get ongoingAnalysis {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviour',
      'getOngoingAnalysis',
    );

    if (resultString['result'] == -1 || resultString['gemApiError'] != 0) {
      return null;
    }

    return DriverBehaviourAnalysis.init(resultString['result']);
  }

  /// Get the most recently completed analysis.
  ///
  /// ## Returns
  ///
  /// - The last [DriverBehaviourAnalysis] or null if none is available.
  ///
  /// ## Also see:
  ///
  /// - [DriverBehaviour.ongoingAnalysis] - To get the current ongoing analysis.
  @Deprecated('Use lastAnalysis getter instead')
  DriverBehaviourAnalysis? getLastAnalysis() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviour',
      'getLastAnalysis',
    );

    if (resultString['result'] == -1 || resultString['gemApiError'] != 0) {
      return null;
    }

    return DriverBehaviourAnalysis.init(resultString['result']);
  }

  /// Get the most recently completed analysis.
  ///
  /// ## Returns
  ///
  /// - The last [DriverBehaviourAnalysis] or null if none is available.
  ///
  /// ## Also see:
  ///
  /// - [DriverBehaviour.ongoingAnalysis] - To get the current ongoing analysis.
  DriverBehaviourAnalysis? get lastAnalysis {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviour',
      'getLastAnalysis',
    );

    if (resultString['result'] == -1 || resultString['gemApiError'] != 0) {
      return null;
    }

    return DriverBehaviourAnalysis.init(resultString['result']);
  }

  /// Retrieve current instantaneous driving scores for real-time feedback.
  ///
  /// ## Returns
  ///
  /// - A [DrivingScores] instance representing the current scores, or null
  ///   if no ongoing analysis or scores are unavailable.
  @Deprecated('Use instantaneousScores getter instead')
  DrivingScores? getInstantaneousScores() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviour',
      'getInstantaneousScores',
    );

    if (resultString['result'] == -1 || resultString['gemApiError'] != 0) {
      return null;
    }

    return DrivingScores.init(resultString['result']);
  }

  /// Retrieve current instantaneous driving scores for real-time feedback.
  ///
  /// ## Returns
  ///
  /// - A [DrivingScores] instance representing the current scores, or null
  ///   if no ongoing analysis or scores are unavailable.
  DrivingScores? get instantaneousScores {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviour',
      'getInstantaneousScores',
    );

    if (resultString['result'] == -1 || resultString['gemApiError'] != 0) {
      return null;
    }

    return DrivingScores.init(resultString['result']);
  }

  /// Retrieve all stored driver behaviour analyses recorded on the device.
  ///
  /// ## Returns
  ///
  /// - A list of [DriverBehaviourAnalysis] instances (may be empty).
  ///
  /// ## Also see:
  ///
  /// - [getCombinedAnalysis] - To aggregate analyses over a time range.
  @Deprecated('Use allDriverBehaviourAnalyses getter instead')
  List<DriverBehaviourAnalysis> getAllDriverBehaviourAnalyses() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviour',
      'getAllDriverBehaviourAnalyses',
    );

    final List<dynamic> listJson = resultString['result'];
    final List<DriverBehaviourAnalysis> retList = listJson
        .map(
          (final dynamic behaviourAnalysis) =>
              DriverBehaviourAnalysis.init(behaviourAnalysis),
        )
        .toList();
    return retList;
  }

  /// Retrieve all stored driver behaviour analyses recorded on the device.
  ///
  /// ## Returns
  ///
  /// - A list of [DriverBehaviourAnalysis] instances (may be empty).
  ///
  /// ## Also see:
  ///
  /// - [getCombinedAnalysis] - To aggregate analyses over a time range.
  List<DriverBehaviourAnalysis> get allDriverBehaviourAnalyses {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviour',
      'getAllDriverBehaviourAnalyses',
    );

    final List<dynamic> listJson = resultString['result'];
    final List<DriverBehaviourAnalysis> retList = listJson
        .map(
          (final dynamic behaviourAnalysis) =>
              DriverBehaviourAnalysis.init(behaviourAnalysis),
        )
        .toList();
    return retList;
  }

  /// Combine analyses from multiple sessions within a time range into a
  /// single aggregated [DriverBehaviourAnalysis].
  ///
  /// ## Parameters
  ///
  /// - [startTime]: The start of the time range (inclusive).
  /// - [endTime]: The end of the time range (inclusive).
  ///
  /// ## Returns
  ///
  /// - A combined [DriverBehaviourAnalysis] summarizing all analyses in the
  ///   interval, or null if the operation failed or no valid data is
  ///   available.
  ///
  /// ## Also see:
  ///
  /// - [allDriverBehaviourAnalyses] - To retrieve all stored analyses.
  /// - [eraseAnalysesOlderThan] - To delete old analyses from storage.
  DriverBehaviourAnalysis? getCombinedAnalysis(
    DateTime startTime,
    DateTime endTime,
  ) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'DriverBehaviour',
      'getCombinedAnalysis',
      args: <String, dynamic>{
        'first': startTime.millisecondsSinceEpoch,
        'second': endTime.millisecondsSinceEpoch,
      },
    );

    if (resultString['result'] == -1 || resultString['gemApiError'] != 0) {
      return null;
    }

    return DriverBehaviourAnalysis.init(resultString['result']);
  }

  /// Erase stored analyses older than the specified reference time.
  ///
  /// ## Parameters
  ///
  /// - [time]: Analyses with a finish time earlier than this value will be
  ///   removed from local storage.
  void eraseAnalysesOlderThan(DateTime time) {
    objectMethod(
      pointerId,
      'DriverBehaviour',
      'eraseAnalysesOlderThan',
      args: time.millisecondsSinceEpoch,
    );
  }

  static DriverBehaviour _create(
    final DataSource dataSource,
    final bool useMapMatch,
  ) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'DriverBehaviour',
        'args': <String, dynamic>{
          'dataSource': dataSource.pointerId,
          'useMapMatch': useMapMatch,
        },
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return DriverBehaviour.init(decodedVal['result']);
  }
}
