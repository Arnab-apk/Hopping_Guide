// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:typed_data';

import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/core/geographic/coordinates.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Provides metadata for a recorded sensor data log.
///
/// The [LogMetadata] object exposes information extracted from a recorded log file
/// such as start/end timestamps and positions, route coordinates, activity details,
/// user-provided metadata, and basic metrics. The [LogMetadata] class provides
/// information about the recorded log via the [Recorder] class.
///
/// Do not construct this class directly; obtain an instance via [RecorderBookmarks.getLogMetadata].
///
/// ## See also:
///
/// - [RecorderBookmarks.getLogMetadata]: Obtain a [LogMetadata] for a file path.
/// - [LogMetrics]: high-level metrics for the recorded log.
///
/// {@category Sensor Data Source}
class LogMetadata extends GemAutoreleaseObject {
  LogMetadata(super.id);

  // ignore: unused_element
  LogMetadata._() : super(-1);

  /// Timestamp of the first sensor data in the log, in milliseconds since epoch.
  ///
  /// This value represents the timestamp of the first recorded sensor sample in
  /// the log. It can be used to align log events with other time-based data.
  ///
  /// ## Returns
  ///
  /// - An integer with milliseconds since epoch for the first sample.
  int get startTimestampInMillis {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getStartTimestampInMillis',
    );
    return resultString['result'];
  }

  /// Timestamp of the last sensor data in the log, in milliseconds since epoch.
  ///
  /// This value represents the timestamp of the final recorded sensor sample
  /// contained in the log and can be used together with
  /// [startTimestampInMillis] to compute durations.
  ///
  /// ## Returns
  ///
  /// - An integer with milliseconds since epoch for the last sample.
  int get endTimestampInMillis {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getEndTimestampInMillis',
    );
    return resultString['result'];
  }

  /// Total duration of the log in milliseconds.
  ///
  /// This is the reported duration for the recorded log and is typically equal
  /// to [endTimestampInMillis] - [startTimestampInMillis] but may differ slightly
  /// depending on how samples are recorded.
  ///
  /// ## Returns
  ///
  /// - An integer representing the duration in milliseconds.
  ///
  /// ## See also:
  ///
  /// - [activeDurationMillis]: Total active recording time excluding pauses.
  int get durationMillis {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getDurationMillis',
    );
    return resultString['result'];
  }

  /// Total active recording time in milliseconds (excludes paused intervals).
  ///
  /// The active duration counts only periods when recording was actually
  /// running; any paused segments are excluded.
  ///
  /// ## Returns
  ///
  /// - An integer representing active recording time in milliseconds.
  ///
  /// ## See also:
  ///
  /// - [durationMillis]: Total duration including paused time.
  int get activeDurationMillis {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getActiveDurationMillis',
    );
    return resultString['result'];
  }

  /// First recorded GPS coordinate in the log.
  ///
  /// Returns the earliest valid [Coordinates] recorded in the log. If the log
  /// contains no GPS samples, an invalid coordinate `(0, 0)` is returned.
  ///
  /// ## Returns
  ///
  /// - A [Coordinates] instance representing the starting position, or
  ///   `(0, 0)` if no GPS data is available.
  Coordinates get startPosition {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getStartPosition',
    );

    return Coordinates.fromJson(resultString['result']);
  }

  /// Last recorded GPS coordinate in the log.
  ///
  /// Returns the most recent valid [Coordinates] recorded in the log. If the
  /// log contains no GPS samples, an invalid coordinate `(0, 0)` is returned.
  ///
  /// ## Returns
  ///
  /// - A [Coordinates] instance representing the ending position, or
  ///   `(0, 0)` if no GPS data is available.
  Coordinates get endPosition {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getEndPosition',
    );

    return Coordinates.fromJson(resultString['result']);
  }

  /// Transport mode used during recording.
  ///
  /// The transport mode reflects the primary mode of movement (for example
  /// walking, driving, cycling) inferred or selected when the log was
  /// recorded.
  ///
  /// ## Returns
  ///
  /// - A [RecordingTransportMode] value describing the transport mode.
  RecordingTransportMode get transportMode {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getTransportMode',
    );

    return RecordingTransportModeExtension.fromId(resultString['result']);
  }

  /// Activity details recorded with the log.
  ///
  /// This returns an [ActivityRecord] describing the activity metadata
  /// associated with the log (sport type, effort, visibility, etc.).
  ///
  /// ## Returns
  ///
  /// - An [ActivityRecord] instance parsed from the log metadata.
  ActivityRecord get activityRecord {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getActivityRecord',
    );

    return ActivityRecord.fromJson(resultString['result']);
  }

  /// Basic metrics computed for the log (distance, elevation gain, average speed).
  ///
  /// Returns a [LogMetrics] object containing summary metrics for the recorded
  /// log.
  ///
  /// ## Returns
  ///
  /// - A [LogMetrics] instance with distance, elevation and speed metrics.
  LogMetrics get logMetrics {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getMetrics',
    );
    return LogMetrics.fromJson(resultString['result']);
  }

  /// A simplified route sampled from the recorded log.
  ///
  /// The [route] contains coordinates selected from the full recording such
  /// that consecutive points are at least 20 meters apart or respecting a
  /// three-second delay rule; it is suitable for quick map rendering.
  ///
  /// Can be used to compute a path-based route.
  ///
  /// ## Returns
  ///
  /// - A list of [Coordinates] representing the sampled route.
  ///
  /// ## See also:
  ///
  /// - [preciseRoute] - A full-resolution version of the recorded path.
  /// - [Path] - A class representing a geometric path.
  List<Coordinates> get route {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getRoute',
    );

    return resultString['result']
        .map<Coordinates>((final dynamic e) => Coordinates.fromJson(e))
        .toList();
  }

  /// The precise, full-resolution route recorded in the log.
  ///
  /// The [preciseRoute] returns every recorded GPS sample from the log and should
  /// be used when an exact replay or analysis of the recorded path is
  /// required. This list can be large for long recordings.
  ///
  /// ## Returns
  ///
  /// - A list of [Coordinates] containing all recorded positions.
  ///
  /// ## See also:
  ///
  /// - [route] - A simplified, downsampled version of the recorded path.
  /// - [Path] - A class representing a geometric path.
  List<Coordinates> get preciseRoute {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getPreciseRoute',
    );

    final List<dynamic> rawList = resultString['result'];

    return rawList
        .map((dynamic e) => Coordinates.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Sound annotations recorded within the log.
  ///
  /// Returns a list of [SoundMark] objects describing intervals where audio
  /// was recorded during the session. These marks are generated when audio
  /// recording is enabled in the [Recorder] during the session.
  ///
  /// ## Returns
  ///
  /// - A list of [SoundMark] instances.
  List<SoundMark> get soundMarks {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getSoundMarks',
    );
    final List<dynamic> retval = resultString['result'];
    return retval.map((final dynamic e) => SoundMark.fromJson(e)).toList();
  }

  /// Text annotations recorded within the log.
  ///
  /// Returns a list of [TextMark] objects created during the recording to
  /// annotate the log with short textual notes. These marks are added by
  /// calling [Recorder.addTextMark] while recording.
  ///
  /// ## Returns
  ///
  /// - A list of [TextMark] instances.
  List<TextMark> get textMarks {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getTextMarks',
    );
    final List<dynamic> retval = resultString['result'];
    return retval.map((final dynamic e) => TextMark.fromJson(e)).toList();
  }

  /// Checks whether a given data type exists in the log.
  ///
  /// ## Parameters
  ///
  /// - [type]: The [DataType] to check for availability in the recorded log.
  ///
  /// ## Returns
  ///
  /// - `true` if the data type is present in the log, otherwise `false`.
  bool isDataTypeAvailable(final DataType type) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'isDataTypeAvailable',
      args: type.id,
    );
    return resultString['result'];
  }

  /// List of data types recorded in the log.
  ///
  /// Use this getter to discover which sensor/data streams were recorded.
  /// The returned list contains [DataType] values present in the log.
  ///
  /// ## Returns
  ///
  /// - A list of [DataType] items available in the log.
  List<DataType> get availableDataTypes {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getAvailableDataTypes',
    );
    final List<dynamic> res = resultString['result'];
    return res.map((final dynamic e) => DataTypeExtension.fromId(e)).toList();
  }

  /// Whether the log file was uploaded to the server.
  ///
  /// Returns `true` if the log has been successfully uploaded and is
  /// available on the server for processing.
  ///
  /// ## Returns
  ///
  /// - `true` when the log is uploaded; otherwise `false`.
  bool get isUploaded {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'isUploaded',
    );
    return resultString['result'];
  }

  /// Whether the log file is marked as protected from automatic deletion.
  ///
  /// Protected logs are preserved even when automatic cleanup of old logs is
  /// performed due to space or retention settings.
  ///
  /// ## Returns
  ///
  /// - `true` when the log is protected; otherwise `false`.
  bool get isProtected {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'isProtected',
    );
    return resultString['result'];
  }

  /// Size of the log file in bytes.
  ///
  /// ## Returns
  ///
  /// - An integer with the total size of the log file in bytes.
  int get logSize {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getLogSize',
    );
    return resultString['result'];
  }

  /// Retrieves custom user metadata stored with the given key.
  ///
  /// The method returns the raw byte buffer that was previously saved using
  /// [addUserMetadata]. If the key does not exist an asynchronous empty
  /// response is represented as `null`.
  ///
  /// ## Parameters
  ///
  /// - [key]: The string key used when saving the metadata.
  ///
  /// ## Returns
  ///
  /// - A [Uint8List] with the stored data, or `null` if no data exists for
  ///   the provided key.
  ///
  /// ## Also see:
  ///
  /// - [addUserMetadata] - Store custom metadata in the log.
  /// - [Recorder.addUserMetadata] - Add custom metadata during recording.
  Uint8List? getUserMetadata(final String key) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogMetadata',
      'getUserMetadata',
      args: key,
    );
    final String result = resultString['result'];

    if (result == '') {
      return null;
    }
    return base64Decode(result);
  }

  /// Adds or overwrites custom metadata for the given key.
  ///
  /// The provided byte buffer will be stored in the log file's metadata area.
  /// If a value already exists for the same key it will be replaced. This
  /// operation is asynchronous and returns `true` when the write succeeded.
  ///
  /// ## Parameters
  ///
  /// - [key]: The string key to associate with the metadata.
  /// - [userMetadata]: A [Uint8List] containing the data to store.
  ///
  /// ## Returns
  ///
  /// - A [Future<bool>] that completes with `true` on success, `false` on
  ///   failure.
  ///
  /// ## Also see:
  ///
  /// - [getUserMetadata] - Retrieve custom metadata from the log.
  /// - [Recorder.addUserMetadata] - Add custom metadata during recording.
  Future<bool> addUserMetadata(
    final String key,
    final Uint8List userMetadata,
  ) async {
    final dynamic dataBufferPointer = GemKitPlatform.instance.toNativePointer(
      userMetadata,
    );

    final String? resultString = await GemKitPlatform.instance
        .getChannel(mapId: -1)
        .invokeMethod<String>(
          'callObjectMethod',
          jsonEncode(<String, Object>{
            'id': pointerId,
            'class': 'LogMetadata',
            'method': 'addUserMetadata',
            'args': <String, dynamic>{
              'key': key,
              'dataBuffer': dataBufferPointer.address,
              'dataBufferSize': userMetadata.length,
            },
          }),
        );
    GemKitPlatform.instance.freeNativePointer(dataBufferPointer);
    return jsonDecode(resultString!)['result'] as bool;
  }
}
