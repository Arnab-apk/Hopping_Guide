// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Base Metrics interface for metric objects used by the sense library.
///
/// Used internally to represent metric containers returned from recorder and
/// log metadata APIs.
///
/// ## See also:
///
/// - [LogMetrics] - Metrics about saved logs.
/// - [RecordMetrics] - Metrics available during active recordings.
///
/// {@category Sensor Data Source}
class Metrics {}

/// Provides metrics about a recorded log, such as distance, elevation gain,
/// and average speed.
///
/// These metrics are typically retrieved from a [LogMetadata] instance and
/// represent summary information for a saved recording.
///
/// ## See also:
///
/// - [LogMetadata.logMetrics] - Accessing log-related information.
/// - [RecordMetrics] - Metrics available while a recording is in progress.
///
/// {@category Sensor Data Source}
class LogMetrics implements Metrics {
  /// Creates a [LogMetrics] object with the specified metric values.
  ///
  /// API users typically do not create [LogMetrics] instances directly.
  ///
  /// ## Parameters
  ///
  /// - [distanceMeters]: The total distance traveled in meters.
  /// - [elevationGainMeters]: The total elevation gain in meters.
  /// - [avgSpeedMps]: The average speed in meters per second.
  /// - [maxSpeedMps]: The maximum speed in meters per second.
  LogMetrics({
    required this.distanceMeters,
    required this.elevationGainMeters,
    required this.avgSpeedMps,
    this.maxSpeedMps = 0.0,
  });

  /// Deserializes a JSON-compatible map to create a [LogMetrics] instance.
  ///
  /// Used internally, not intended for direct use by consumers. The expected
  /// map structure may change without notice.
  @internal
  factory LogMetrics.fromJson(final Map<String, dynamic> json) {
    return LogMetrics(
      distanceMeters: json['distanceMeters'],
      elevationGainMeters: json['elevationGainMeters'],
      avgSpeedMps: json['avgSpeedMps'],
      maxSpeedMps: (json['maxSpeedMps'] ?? 0.0).toDouble(),
    );
  }

  /// The total distance traveled, in meters.
  final double distanceMeters;

  /// The total elevation gain, in meters.
  final double elevationGainMeters;

  /// The average speed, in meters per second.
  final double avgSpeedMps;

  /// The maximum speed, in meters per second.
  final double maxSpeedMps;

  @override
  bool operator ==(covariant LogMetrics other) {
    if (identical(this, other)) {
      return true;
    }

    return other.distanceMeters == distanceMeters &&
        other.elevationGainMeters == elevationGainMeters &&
        other.avgSpeedMps == avgSpeedMps &&
        other.maxSpeedMps == maxSpeedMps;
  }

  @override
  int get hashCode {
    return distanceMeters.hashCode ^
        elevationGainMeters.hashCode ^
        avgSpeedMps.hashCode ^
        maxSpeedMps.hashCode;
  }
}

/// Performance metrics produced while a recording is active.
///
/// [RecordMetrics] is exposed by the [Recorder] while it is in
/// [RecorderStatus.recording]. The values reset at the start of each
/// recording session and provide realtime measurements that can be used in
/// UI or analytics.
///
/// ## See also:
///
/// - [Recorder] - Accessing recording functionality.
/// - [LogMetrics] - Metrics persisted with a saved log.
///
/// {@category Sensor Data Source}
class RecordMetrics implements Metrics {
  /// Creates a [RecordMetrics] instance.
  ///
  /// API users typically do not create [RecordMetrics] instances directly.
  ///
  /// ## Parameters
  ///
  /// - [distanceMeters]: The total distance traveled in meters. Defaults to
  ///   `0.0`.
  /// - [elevationGainMeters]: The total elevation gain in meters. Defaults to
  ///   `0.0`.
  /// - [avgSpeedMps]: The average speed in meters per second. Defaults to
  ///   `0.0`.
  /// - [maxSpeedMps]: The maximum speed in meters per second. Defaults to
  ///   `0.0`.
  RecordMetrics({
    this.distanceMeters = 0.0,
    this.elevationGainMeters = 0.0,
    this.avgSpeedMps = 0.0,
    this.maxSpeedMps = 0.0,
  });

  /// Deserializes a JSON-compatible map to create a [RecordMetrics] instance.
  ///
  /// Used internally by recorder and log APIs. The expected map structure may
  /// change without notice.
  @internal
  factory RecordMetrics.fromJson(final Map<String, dynamic> json) {
    return RecordMetrics(
      distanceMeters: (json['distanceMeters'] ?? 0.0).toDouble(),
      elevationGainMeters: (json['elevationGainMeters'] ?? 0.0).toDouble(),
      avgSpeedMps: (json['avgSpeedMps'] ?? 0.0).toDouble(),
      maxSpeedMps: (json['maxSpeedMps'] ?? 0.0).toDouble(),
    );
  }

  /// The total distance traveled, in meters.
  double distanceMeters;

  /// The total elevation gain, in meters.
  double elevationGainMeters;

  /// The average speed, in meters per second.
  double avgSpeedMps;

  /// The maximum speed, in meters per second.
  double maxSpeedMps;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers. The map
  /// structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['distanceMeters'] = distanceMeters;
    json['elevationGainMeters'] = elevationGainMeters;
    json['avgSpeedMps'] = avgSpeedMps;
    json['maxSpeedMps'] = maxSpeedMps;
    return json;
  }

  @override
  bool operator ==(covariant final RecordMetrics other) {
    if (identical(this, other)) {
      return true;
    }

    return other.distanceMeters == distanceMeters &&
        other.elevationGainMeters == elevationGainMeters &&
        other.avgSpeedMps == avgSpeedMps &&
        other.maxSpeedMps == maxSpeedMps;
  }

  @override
  int get hashCode {
    return distanceMeters.hashCode ^
        elevationGainMeters.hashCode ^
        avgSpeedMps.hashCode ^
        maxSpeedMps.hashCode;
  }
}
