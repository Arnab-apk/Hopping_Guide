// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/sense/log_upload_listener.dart';

/// Uploads a recorded log file to Magic Lane servers for bug reports.
///
/// [LogUploader] sends `.gm` or `.mp4` recordings to Magic Lane backends and
/// reports progress and status updates through the optional callback provided
/// at construction.
///
/// Use this class to programmatically upload logs for
/// diagnostics or bug reporting.
///
/// ## See also:
///
/// - [LogUploadListener]: internal listener used to receive upload events.
///
/// {@category Sensor Data Source}
class LogUploader extends GemAutoreleaseObject {
  /// Creates a [LogUploader] instance.
  ///
  /// The optional [onLogStatusChanged] callback receives status updates
  /// during the lifecycle of an upload.
  ///
  /// ## Parameters
  ///
  /// - [onLogStatusChanged]: Callback invoked to report upload progress and
  ///   completion. The callback is called with:
  ///   - `error` (GemError): `GemError.success` on success, or another error
  ///     code if the operation failed.
  ///   - `logPath` (String): The path of the log file associated with the
  ///     event.
  ///   - `status` (LogUploaderState?): The current upload state; `null` when
  ///     `error` is not `GemError.success`.
  ///   - `progress` (int?): Progress percentage (0–100) when available; `null`
  ///     when not applicable.
  factory LogUploader({
    final void Function(
      GemError error,
      String logPath,
      LogUploaderState? status,
      int? progress,
    )?
    onLogStatusChanged,
  }) {
    // create the listener first (so we have its pointer)
    final LogUploadListener listener = LogUploadListener((
      final String logPath,
      final int status,
      final int progress,
    ) {
      if (status < 0) {
        final GemError err = GemErrorExtension.fromCode(status);
        onLogStatusChanged?.call(err, logPath, null, null);
      } else {
        final LogUploaderState state = LogUploaderStateExtension.fromId(status);
        onLogStatusChanged?.call(GemError.success, logPath, state, progress);
      }
    });

    // call platform to create the native LogUploader and get its pointer id
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'LogUploader',
        'args': listener.pointerId,
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final int pointerId = decodedVal['result'] as int;

    // construct the Dart object (this calls super(pointerId) and registers once)
    final LogUploader instance = LogUploader._(pointerId, listener);

    // register the listener with the platform event system (if required)
    GemKitPlatform.instance.registerEventHandler(listener.pointerId, listener);

    return instance;
  }

  /// Private constructor: forwards the native pointer id to the base class.
  LogUploader._(super.id, LogUploadListener listener)
    : _logUploadListener = listener;

  late final LogUploadListener _logUploadListener;

  /// Starts uploading a log file to the server.
  ///
  /// Initiates an upload operation; progress and final status are reported via
  /// the [onLogStatusChanged] callback supplied when the [LogUploader] was
  /// created.
  ///
  /// ## Parameters
  ///
  /// - [logPath]: Path to the log file to upload.
  /// - [userName]: User name to associate with the upload.
  /// - [userMail]: User email to associate with the upload.
  /// - [details]: Optional additional details describing the upload.
  /// - [externalFiles]: Optional list of additional file paths to include in
  /// the upload. Can be used to attach screenshots, logs, or other relevant
  /// files.
  ///
  /// ## Returns
  ///
  /// - A [GemError] indicating the immediate outcome of the start request
  ///   (for example, [GemError.success] when the operation was accepted).
  ///
  /// ## See also:
  ///
  /// - [cancel] — cancels an ongoing upload.
  GemError upload({
    required final String logPath,
    required final String userName,
    required final String userMail,
    final String details = '',
    final List<String> externalFiles = const <String>[],
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogUploader',
      'upload',
      args: <String, Object>{
        'logPath': logPath,
        'userName': userName,
        'userMail': userMail,
        'details': details,
        'externalFiles': externalFiles,
      },
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Cancels an ongoing upload for the specified log file.
  ///
  /// The cancel request will trigger status updates via the
  /// [onLogStatusChanged] callback passed to the [LogUploader] constructor.
  ///
  /// ## Parameters
  ///
  /// - [logPath]: Path to the log file whose upload should be cancelled.
  ///
  /// ## Returns
  ///
  /// - A [GemError] indicating the result of the cancel request.
  ///
  /// ## See also:
  ///
  /// - [upload] — starts a new log upload.
  GemError cancel({required final String logPath}) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LogUploader',
      'cancel',
      args: logPath,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  @override
  void dispose() {
    try {
      GemKitPlatform.instance.unregisterEventHandler(
        _logUploadListener.pointerId,
      );
    } catch (_) {}
    super.dispose();
  }
}
