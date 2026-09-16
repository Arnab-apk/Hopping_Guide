// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:typed_data';

import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/core/common/gem_error.dart';
import 'package:magiclane_maps_flutter/src/core/common/progress_listener.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_driven_progress_listener.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Recorder for capturing sensor and multimedia logs.
///
/// Use a configured [RecorderConfiguration] to create a [Recorder] with
/// [Recorder.create]. The recorder manages recording lifecycle (start, stop,
/// pause, resume), audio/video capture and user metadata. See recorder guides
/// for background permissions and storage recommendations.
///
/// The recorded logs can be accessed and managed using
/// [RecorderBookmarks] and their metadata through [LogMetadata].
///
/// {@category Sensor Data Source}
class Recorder extends GemAutoreleaseObject {
  // ignore: unused_element
  Recorder._() : super(-1);

  Recorder.init(super.id);

  /// Creates a configured [Recorder] instance.
  ///
  /// Use this static factory with a [RecorderConfiguration] to obtain a
  /// recorder instance. The factory only constructs the recorder; to begin
  /// capturing data call [startRecording]. If recording must work while the
  /// app is in the background, ensure the required platform permissions and
  /// background location settings are configured (see SDK guides).
  ///
  /// ## Parameters
  ///
  /// - [config]: The [RecorderConfiguration] describing what to record and where to store logs.
  ///
  /// ## Returns
  ///
  /// - A new [Recorder] instance.
  static Recorder create(final RecorderConfiguration config) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'Recorder',
        'args': config.pointerId,
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return Recorder.init(decodedVal['result']);
  }

  /// Starts the recording session.
  ///
  /// Initiates the recorder and transitions status to [RecorderStatus.starting]
  /// and then to [RecorderStatus.recording] on success.
  ///
  /// Always `await` the returned future to ensure the operation has completed.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] The recorder started and is in [RecorderStatus.recording].
  /// - [GemError.busy] The recorder is busy and could not start.
  /// - [GemError.invalidInput] The provided configuration is invalid (for example none of the requested [RecorderConfiguration.recordedTypes] are available).
  /// - [GemError.noDiskSpace] Not enough disk space to start recording.
  /// - [GemError.overheated] Device temperature prevents starting the recorder.
  /// - [GemError.accessDenied] Required permissions are missing to start recording (check audio recording permissions).
  /// - [GemError.general] A generic error occurred.
  Future<GemError> startRecording() async {
    final String? resultString = await GemKitPlatform.instance
        .getChannel(mapId: -1)
        .invokeMethod<String>(
          'callObjectMethod',
          jsonEncode(<String, Object>{
            'id': pointerId,
            'class': 'Recorder',
            'method': 'startRecording',
            'args': <dynamic, dynamic>{},
          }),
        );
    return GemErrorExtension.fromCode(jsonDecode(resultString!)['result']);
  }

  /// Stops the recording session.
  ///
  /// Stops the recorder and transitions the status to [RecorderStatus.stopping].
  /// On success the status becomes [RecorderStatus.stopped]; if
  /// [RecorderConfiguration.continuousRecording] is enabled and a chunk
  /// boundary was reached the status becomes [RecorderStatus.restarting].
  ///
  /// ## Returns
  ///
  /// - [GemError.success] Recording stopped successfully (or restarted when chunking with continuous recording).
  /// - [GemError.recordedLogTooShort] The recording was shorter than [RecorderConfiguration.minDurationSeconds] and was discarded.
  /// - [GemError.busy] The recorder is busy and could not stop.
  /// - [GemError.general] A generic error occurred while stopping the recorder.
  Future<GemError> stopRecording() async {
    final String? resultString = await GemKitPlatform.instance
        .getChannel(mapId: -1)
        .invokeMethod<String>(
          'callObjectMethod',
          jsonEncode(<String, Object>{
            'id': pointerId,
            'class': 'Recorder',
            'method': 'stopRecording',
            'args': <dynamic, dynamic>{},
          }),
        );
    return GemErrorExtension.fromCode(jsonDecode(resultString!)['result']);
  }

  /// Pauses an ongoing recording.
  ///
  /// Transitions the recorder to [RecorderStatus.pausing] and then to
  /// [RecorderStatus.paused] when successful.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] Recorder paused successfully.
  /// - [GemError.busy] Recorder could not pause because it is busy.
  /// - [GemError.general] A generic error occurred while pausing.
  GemError pauseRecording() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Recorder',
      'pauseRecording',
    );
    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Resumes a paused recording.
  ///
  /// Transitions the recorder to [RecorderStatus.resuming] and then to
  /// [RecorderStatus.recording] when the operation succeeds.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] Recording resumed successfully.
  /// - [GemError.busy] Recorder is busy and could not resume.
  /// - [GemError.general] A generic error occurred while resuming.
  GemError resumeRecording() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Recorder',
      'resumeRecording',
    );
    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Starts audio capture for the current recording.
  ///
  /// Resumes audio recording only if a recording is currently active and
  /// audio is enabled in the recorder configuration ([RecorderConfiguration.enableAudio]).
  ///
  /// ## See also:
  ///
  /// - [stopAudioRecording] — Stops audio capture.
  /// - [RecorderConfiguration.enableAudio] - Configuration option to enable audio recording.
  void startAudioRecording() {
    objectMethod(pointerId, 'Recorder', 'startAudioRecording');
  }

  /// Stops audio capture for the current recording.
  ///
  /// Suspends audio recording when a recording is active and audio was
  /// enabled in the recorder configuration.
  ///
  /// ## See also:
  ///
  /// - [startAudioRecording] — Starts audio capture.
  /// - [RecorderConfiguration.enableAudio] - Configuration option to enable audio recording.
  void stopAudioRecording() {
    objectMethod(pointerId, 'Recorder', 'stopAudioRecording');
  }

  /// Whether audio capture is currently active.
  ///
  /// ## Returns
  ///
  /// - `true` if audio recording is in progress; otherwise `false`.
  ///
  /// ## See also:
  ///
  /// - [startAudioRecording] — Starts audio capture.
  /// - [stopAudioRecording] — Stops audio capture.
  bool isAudioRecording() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Recorder',
      'isAudioRecording',
    );
    return resultString['result'];
  }

  /// The current [RecorderConfiguration] in use by the recorder.
  ///
  /// Returns the active configuration reflecting the settings applied at
  /// creation or through [setRecorderConfiguration]. Useful for inspection or
  /// diagnostics.
  ///
  /// Changing the configuration while recording does not take effect.
  /// Use the [setRecorderConfiguration] method to apply a new configuration.
  ///
  /// ## Returns
  ///
  /// - A [RecorderConfiguration] instance containing the current settings.
  ///
  /// ## See also:
  ///
  /// - [setRecorderConfiguration] — Apply a new configuration to the recorder.
  /// - [RecorderConfiguration] — Configuration class used to create or update the recorder.
  RecorderConfiguration get recorderConfiguration {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Recorder',
      'getConfiguration',
    );

    return RecorderConfiguration.init(resultString['result']);
  }

  /// Apply a new recorder configuration.
  ///
  /// If the recorder is currently recording it will be stopped, reconfigured
  /// and restarted. Callers should handle the returned result to know whether
  /// the update succeeded.
  ///
  /// ## Parameters
  ///
  /// - [config]: The [RecorderConfiguration] to apply.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] Configuration updated successfully.
  /// - [GemError.busy] The recorder was busy and could not be reconfigured.
  /// - [GemError.general] A general error occurred while updating the configuration.
  ///
  /// ## See also:
  ///
  /// - [recorderConfiguration] — Retrieves the current recorder configuration.
  /// - [RecorderConfiguration] — Configuration class used to create or update the recorder.
  GemError setRecorderConfiguration(final RecorderConfiguration config) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Recorder',
      'setConfiguration',
      args: config.pointerId,
    );
    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Current recorder status.
  ///
  /// ## Returns
  ///
  /// - The active [RecorderStatus] value describing the recorder state.
  RecorderStatus get recorderStatus {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Recorder',
      'getStatus',
    );
    return RecorderStatusExtension.fromId(resultString['result']);
  }

  /// Path to the current log file.
  ///
  /// ## Returns
  ///
  /// - A string with the absolute path to the current recording file.
  String get currentRecordPath {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Recorder',
      'getCurrentRecordPath',
    );
    return resultString['result'];
  }

  /// Disk space used per second, in bytes.
  ///
  /// ## Returns
  ///
  /// - An `int` representing the number of bytes used per second by the recorder.
  int get diskSpaceUsedPerSecond {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Recorder',
      'diskSpaceUsedPerSecond',
    );
    return resultString['result'];
  }

  /// Recording performance metrics.
  ///
  /// Returns various runtime statistics for an active recording (average
  /// speed, distance, elevation gain, etc.). Available while the recorder is
  /// in [RecorderStatus.recording].
  ///
  /// ## Returns
  ///
  /// - A [RecordMetrics] object with current recording statistics.
  ///
  /// ## Also see:
  ///
  /// - [LogMetrics] — Metrics persisted with a saved log.
  RecordMetrics get metrics {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Recorder',
      'getMetrics',
    );
    return RecordMetrics.fromJson(resultString['result']);
  }

  /// Attach activity metadata to the current recording.
  ///
  /// Provide an [ActivityRecord] describing the activity (title,
  /// description, sport type, visibility, etc.). Call this before stopping
  /// the recording to ensure the metadata is saved with the log.
  ///
  /// The activity record does not influence the recording process itself but rather
  /// provides descriptive metadata for the saved log.
  ///
  /// ## Parameters
  ///
  /// - [activityRecord]: The [ActivityRecord] to attach to the current recording.
  set activityRecord(final ActivityRecord activityRecord) {
    objectMethod(
      pointerId,
      'Recorder',
      'setActivityRecord',
      args: activityRecord,
    );
  }

  /// Add a textual annotation (text mark) to the current recording.
  ///
  /// Call before stopping the recording to include the annotation in the
  /// final log file.
  ///
  /// ## Parameters
  ///
  /// - [text]: The annotation text to add.
  void addTextMark(final String text) {
    objectMethod(pointerId, 'Recorder', 'addTextMark', args: text);
  }

  /// Save arbitrary binary user metadata into the current log.
  ///
  /// Attach a binary blob under the provided string [key]. Call before
  /// stopping the recording so the data is included in the saved log.
  ///
  /// ## Parameters
  ///
  /// - [key]: The string identifier for the metadata entry.
  /// - [userMetadata]: Binary data to store (as [Uint8List]).
  ///
  /// ## See also:
  ///
  /// - [LogMetadata.getUserMetadata] — Retrieve user metadata from a saved log.
  /// - [LogMetadata.addUserMetadata] — Add user metadata to a log's metadata.
  void addUserMetadata(final String key, final Uint8List userMetadata) {
    final dynamic dataBufferPointer = GemKitPlatform.instance.toNativePointer(
      userMetadata,
    );
    objectMethod(
      pointerId,
      'Recorder',
      'addUserMetadata',
      args: <String, dynamic>{
        'key': key,
        'dataBuffer': dataBufferPointer.address,
        'dataBufferSize': userMetadata.length,
      },
    );

    GemKitPlatform.instance.freeNativePointer(dataBufferPointer);
  }

  /// Register callbacks to monitor recorder progress and status changes.
  ///
  /// ## Parameters
  ///
  /// - [onComplete]: Optional callback called when the listener registration completes. Arguments:
  ///   - `error`: A [GemError] indicating registration result. Possible values include:
  ///     - [GemError.success] registration succeeded.
  ///     - [GemError.exist] listener was already registered.
  /// - [onStatusChanged]: Optional callback invoked when the recorder status changes. Arguments:
  ///   - `status`: The new [RecorderStatus] value.
  ///
  /// ## Returns
  ///
  /// - An [ProgressListener] representing the registered listener if registration succeeded, otherwise `null`.
  ///
  /// ## See also:
  ///
  /// - [removeListener] — Remove a previously registered listener.
  ProgressListener? addListener({
    final void Function(GemError error)? onComplete,
    final void Function(RecorderStatus status)? onStatusChanged,
  }) {
    final EventDrivenProgressListener listener = EventDrivenProgressListener();

    if (onComplete != null) {
      listener.registerOnCompleteWithData((
        final int err,
        final String hint,
        final Map<dynamic, dynamic> json,
      ) {
        onComplete(GemErrorExtension.fromCode(err));
      });
    }

    if (onStatusChanged != null) {
      listener.registerOnNotifyStatusChanged((final int status) {
        onStatusChanged(RecorderStatusExtension.fromId(status));
      });
    }

    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    final OperationResult resultString = objectMethod(
      pointerId,
      'Recorder',
      'addListener',
      args: listener.id,
    );

    final GemError result = GemErrorExtension.fromCode(resultString['result']);

    if (result != GemError.success) {
      return null;
    }

    return listener;
  }

  /// Remove a previously registered listener.
  ///
  /// ## Parameters
  ///
  /// - [listener]: The listener [ProgressListener] to remove (returned by [addListener]).
  ///
  /// ## Returns
  ///
  /// - [GemError.success] Listener removed successfully.
  /// - [GemError.notFound] The provided handler was not found.
  ///
  /// ## See also:
  ///
  /// - [addListener] — Register a new listener to monitor recorder status changes.
  GemError removeListener(ProgressListener listener) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Recorder',
      'removeListener',
      args: listener.id,
    );

    final GemError result = GemErrorExtension.fromCode(resultString['result']);

    return result;
  }
}
