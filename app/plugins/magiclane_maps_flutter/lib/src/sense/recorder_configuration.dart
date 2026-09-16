// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Configuration used to control recorder behavior and log storage settings.
///
/// Use this object to specify which data types to record, where logs are
/// stored, chunking and retention policies, video quality and audio options,
/// and device-specific hardware metadata. Construct a [RecorderConfiguration]
/// and pass it to [Recorder.create] or [Recorder.setRecorderConfiguration]
/// to apply the settings.
///
/// {@category Sensor Data Source}
class RecorderConfiguration extends GemAutoreleaseObject {
  /// Creates a configured [RecorderConfiguration].
  ///
  /// Use this factory to prepare recorder settings before creating a
  /// [Recorder] instance. The constructor only builds the configuration; it
  /// does not start or modify any active recorder by itself.
  ///
  /// ## Parameters
  ///
  /// - [dataSource]: The data source used for recording. Required.
  /// - [logsDir]: Absolute path to the directory used to store recorded logs. Defaults to an empty string.
  /// - [hardwareSpecifications]: Optional map of device metadata keyed by [HardwareSpecification].
  /// - [recordedTypes]: List of [DataType] values to record. If a requested type is not produced by the [dataSource], recording will not start. Defaults to an empty list.
  /// - [minDurationSeconds]: Minimum duration (seconds) a recording must reach to be saved. Defaults to 30.
  /// - [videoQuality]: Video resolution used when [DataType.camera] is recorded. Defaults to [Resolution.unknown].
  /// - [chunkDurationSeconds]: Split recordings into chunks of this many seconds. 0 disables chunking. Defaults to 0.
  /// - [continuousRecording]: If true, a new recording starts automatically when a chunk ends. Defaults to true.
  /// - [enableAudio]: Enable audio tracks for recordings. Defaults to false.
  /// - [maxDiskSpaceUsed]: Maximum disk space in bytes that recordings may occupy. 0 disables disk checks. Defaults to 0.
  /// - [keepMinSeconds]: Minimum seconds of recordings to retain on disk. Defaults to 0.
  /// - [deleteOlderThanKeepMin]: If true, older logs are deleted once [keepMinSeconds] is exceeded. Defaults to false.
  /// - [transportMode]: Transport mode associated with recorded logs. Defaults to [RecordingTransportMode.unknown].
  ///
  /// ## Returns
  ///
  /// - A configured [RecorderConfiguration] instance.
  factory RecorderConfiguration({
    required DataSource dataSource,
    String logsDir = '',
    Map<HardwareSpecification, String>? hardwareSpecifications,
    List<DataType> recordedTypes = const <DataType>[],
    int minDurationSeconds = 30,
    Resolution videoQuality = Resolution.unknown,
    int chunkDurationSeconds = 0,
    bool continuousRecording = true,
    bool enableAudio = false,
    int maxDiskSpaceUsed = 0,
    int keepMinSeconds = 0,
    bool deleteOlderThanKeepMin = false,
    RecordingTransportMode transportMode = RecordingTransportMode.unknown,
  }) {
    final RecorderConfiguration result = RecorderConfiguration._create();

    result.dataSource = dataSource;
    result.logsDir = logsDir;
    result.recordedTypes = recordedTypes;
    if (hardwareSpecifications != null) {
      result.hardwareSpecifications = hardwareSpecifications;
    }
    result.minDurationSeconds = minDurationSeconds;
    result.videoQuality = videoQuality;
    result.chunkDurationSeconds = chunkDurationSeconds;
    result.continuousRecording = continuousRecording;
    result.enableAudio = enableAudio;
    result.maxDiskSpaceUsed = maxDiskSpaceUsed;
    result.keepMinSeconds = keepMinSeconds;
    result.deleteOlderThanKeepMin = deleteOlderThanKeepMin;
    result.transportMode = transportMode;

    return result;
  }
  // ignore: unused_element
  RecorderConfiguration._() : super(-1);

  RecorderConfiguration.init(super.id);

  static RecorderConfiguration _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'RecorderConfiguration',
        'args': <dynamic, dynamic>{},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final RecorderConfiguration config = RecorderConfiguration.init(
      decodedVal['result'],
    );

    return config;
  }

  /// The data source used for recording.
  ///
  /// The [DataSource] that supplies sensor and location input used by the recorder.
  DataSource get dataSource {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderConfiguration',
      'getDataSource',
    );
    return DataSource.init(resultString['result']);
  }

  /// Set the data source used for recording.
  ///
  /// Provide a [DataSource] that will supply sensor and location input for recordings.
  set dataSource(final DataSource dataSource) {
    objectMethod(
      pointerId,
      'RecorderConfiguration',
      'setDataSource',
      args: dataSource.pointerId,
    );
  }

  /// Directory used to store recorder logs.
  ///
  /// Returns an absolute path to the directory where log files are written.
  String get logsDir {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderConfiguration',
      'getLogsDir',
    );
    return resultString['result'];
  }

  /// Set the directory used to store recorder logs.
  ///
  /// Provide an absolute path that will be used to write recorded log files.
  set logsDir(final String logsDir) {
    objectMethod(
      pointerId,
      'RecorderConfiguration',
      'setLogsDir',
      args: logsDir,
    );
  }

  /// Device hardware specifications attached to recordings.
  ///
  /// Returns a map keyed by [HardwareSpecification] containing string values
  /// describing device metadata collected at recording time (for example
  /// model, cpu cores, memory).
  ///
  /// Needs to be populated by the API user.
  Map<HardwareSpecification, String> get hardwareSpecifications {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderConfiguration',
      'getHardwareSpecifications',
    );
    final Map<String, dynamic> hardwareSpecificationsAsString =
        jsonDecode(resultString['result']) ?? <String, dynamic>{};

    final Map<HardwareSpecification, String> hardwareSpecifications =
        <HardwareSpecification, String>{};
    for (final HardwareSpecification spec in HardwareSpecification.values) {
      if (!hardwareSpecificationsAsString.containsKey(spec.id.toString())) {
        continue;
      }
      hardwareSpecifications[spec] =
          hardwareSpecificationsAsString[spec.id.toString()] ?? '';
    }
    return hardwareSpecifications;
  }

  /// Set device hardware specifications to attach to recordings.
  ///
  /// Provide a map keyed by [HardwareSpecification] containing string values
  /// describing the device (for example model, cpu cores, memory). These
  /// values are stored alongside logs for diagnostics.
  set hardwareSpecifications(
    final Map<HardwareSpecification, String> hardwareSpecifications,
  ) {
    final Map<String, String> hardwareSpecificationsAsString =
        <String, String>{};
    for (final HardwareSpecification spec in hardwareSpecifications.keys) {
      hardwareSpecificationsAsString[spec.id.toString()] =
          hardwareSpecifications[spec] ?? '';
    }
    objectMethod(
      pointerId,
      'RecorderConfiguration',
      'setHardwareSpecifications',
      args: jsonEncode(hardwareSpecificationsAsString),
    );
  }

  /// Types of data that are configured to be recorded.
  ///
  /// Returns the list of [DataType] values that the recorder will capture. If
  /// any requested type is not produced by the configured [dataSource], the
  /// recorder will refuse to start.
  List<DataType> get recordedTypes {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderConfiguration',
      'getRecordedTypes',
    );
    return (resultString['result'] as List<dynamic>)
        .map(
          (final dynamic item) =>
              DataType.values.firstWhere((final DataType e) => e.id == item),
        )
        .toList();
  }

  /// Set which data types should be recorded.
  ///
  /// Provide a list of [DataType] values. If any requested type is unavailable
  /// from the current [dataSource], recording will not start.
  set recordedTypes(final List<DataType> recordedTypes) {
    objectMethod(
      pointerId,
      'RecorderConfiguration',
      'setRecordedTypes',
      args: recordedTypes.map((final DataType type) => type.id).toList(),
    );
  }

  /// Minimum recording duration (seconds) required to save a recording.
  ///
  /// Recordings shorter than this value are discarded. Defaults to 30 seconds.
  int get minDurationSeconds {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderConfiguration',
      'getMinDurationSeconds',
    );
    return resultString['result'];
  }

  /// Set the minimum recording duration (seconds) required to save a recording.
  set minDurationSeconds(final int minDurationSeconds) {
    objectMethod(
      pointerId,
      'RecorderConfiguration',
      'setMinDurationSeconds',
      args: minDurationSeconds,
    );
  }

  /// Video quality (resolution) used when camera recording is active.
  ///
  /// If set to [Resolution.unknown] and camera recording is requested, video
  /// will not be recorded.
  Resolution get videoQuality {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderConfiguration',
      'getVideoQuality',
    );
    return ResolutionExtension.fromId(resultString['result']);
  }

  /// Set the video quality (resolution) used when camera recording is active.
  set videoQuality(final Resolution videoQuality) {
    objectMethod(
      pointerId,
      'RecorderConfiguration',
      'setVideoQuality',
      args: videoQuality.id,
    );
  }

  /// Chunk duration (seconds) used to split recordings.
  ///
  /// A value of 0 disables chunking. When enabled the recorder verifies there
  /// is enough disk space to store a full chunk before starting. When a chunk
  /// finishes the current recording stops; if [continuousRecording] is true a
  /// new recording starts automatically.
  int get chunkDurationSeconds {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderConfiguration',
      'getChunkDurationSeconds',
    );
    return resultString['result'];
  }

  /// Set the chunk duration (seconds) used to split recordings.
  ///
  /// Set to 0 to disable chunking.
  set chunkDurationSeconds(final int chunkDurationSeconds) {
    objectMethod(
      pointerId,
      'RecorderConfiguration',
      'setChunkDurationSeconds',
      args: chunkDurationSeconds,
    );
  }

  /// Whether recordings continue automatically after a chunk ends.
  ///
  /// When `true` a new recording is started automatically when the current
  /// chunk completes.
  bool get continuousRecording {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderConfiguration',
      'getContinuousRecording',
    );
    return resultString['result'];
  }

  /// Set whether recordings continue automatically after a chunk completes.
  set continuousRecording(final bool continuousRecording) {
    objectMethod(
      pointerId,
      'RecorderConfiguration',
      'setContinuousRecording',
      args: continuousRecording,
    );
  }

  /// Whether audio tracks are enabled for recordings.
  ///
  /// When `true` an audio track is created during setup. Audio recording can
  /// be started and stopped independently using the recorder's
  /// [Recorder.startAudioRecording] and [Recorder.stopAudioRecording] methods.
  bool get enableAudio {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderConfiguration',
      'getEnableAudio',
    );
    return resultString['result'];
  }

  /// Enable or disable audio tracks for recordings.
  set enableAudio(final bool enableAudio) {
    objectMethod(
      pointerId,
      'RecorderConfiguration',
      'setEnableAudio',
      args: enableAudio,
    );
  }

  /// Maximum disk space (bytes) that recordings may occupy.
  ///
  /// When the total size of recordings reaches this limit the recorder stops
  /// to avoid exceeding the configured space. A value of `0` disables disk
  /// checks.
  int get maxDiskSpaceUsed {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderConfiguration',
      'getMaxDiskSpaceUsed',
    );
    return resultString['result'];
  }

  /// Configure the maximum disk space (in bytes) that recordings may occupy.
  set maxDiskSpaceUsed(final int maxDiskSpaceUsed) {
    objectMethod(
      pointerId,
      'RecorderConfiguration',
      'setMaxDiskSpaceUsed',
      args: maxDiskSpaceUsed,
    );
  }

  /// Minimum total seconds of recordings to retain on disk.
  ///
  /// When this threshold is exceeded and space is low, older recordings may be
  /// removed. To force deletion regardless of space set
  /// [deleteOlderThanKeepMin] to `true`.
  int get keepMinSeconds {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderConfiguration',
      'getKeepMinSeconds',
    );
    return resultString['result'];
  }

  /// Set the minimum total seconds of recordings to retain on disk.
  set keepMinSeconds(final int keepMinSeconds) {
    objectMethod(
      pointerId,
      'RecorderConfiguration',
      'setKeepMinSeconds',
      args: keepMinSeconds,
    );
  }

  /// Whether logs older than [keepMinSeconds] are deleted regardless of free space.
  ///
  /// When `true`, older logs are removed once the retention threshold is
  /// exceeded even if there is available disk space.
  bool get deleteOlderThanKeepMin {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderConfiguration',
      'getDeleteOlderThanKeepMin',
    );
    return resultString['result'];
  }

  /// Set whether logs older than [keepMinSeconds] should be deleted regardless of free space.
  set deleteOlderThanKeepMin(final bool deleteOlderThanKeepMin) {
    objectMethod(
      pointerId,
      'RecorderConfiguration',
      'setDeleteOlderThanKeepMin',
      args: deleteOlderThanKeepMin,
    );
  }

  /// Transport mode associated with recorded logs.
  ///
  /// Returns a [RecordingTransportMode] value captured when the log was
  /// recorded. Defaults to [RecordingTransportMode.unknown] when not set.
  RecordingTransportMode get transportMode {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderConfiguration',
      'getTransportMode',
    );
    return RecordingTransportMode.values.firstWhere(
      (final RecordingTransportMode e) => e.id == resultString['result'],
    );
  }

  /// Set the transport mode associated with recorded logs.
  set transportMode(final RecordingTransportMode transportMode) {
    objectMethod(
      pointerId,
      'RecorderConfiguration',
      'setTransportMode',
      args: transportMode.id,
    );
  }
}
