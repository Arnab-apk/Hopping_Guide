// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';

/// Listener for log upload events.
///
/// Should not be created directly by API users. Instead, provide a callback
/// function to the [LogUploader] constructor.
///
/// @nodoc
class LogUploadListener extends GemAutoreleaseObject implements EventHandler {
  factory LogUploadListener(
    void Function(String logPath, int status, int progress) onLogStatusChanged,
  ) {
    final LogUploadListener logUplaodListener = LogUploadListener._create();
    logUplaodListener.registerOnLogStatusChanged(onLogStatusChanged);
    return logUplaodListener;
  }
  // private ctor that forwards to base (base will register)
  LogUploadListener._(super.id);
  factory LogUploadListener._create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'LogUploadListener'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final int id = decodedVal['result'] as int;
    return LogUploadListener._(id);
  }
  void Function(String logPath, int status, int progress)? _onLogStatusChanged;

  @override
  FutureOr<void> dispose() {
    nativeClear();
    clearListeners();
  }

  @override
  void nativeClear() {
    // No native-side cleanup required for this listener.
  }

  @override
  void clearListeners() {
    _onLogStatusChanged = null;
  }

  @override
  void handleEvent(final Map<dynamic, dynamic> arguments) {
    if (arguments['event_subtype'] == 'onLogStatusChanged') {
      final String logPath = arguments['logPath'];
      final int status = arguments['status'];
      final int progress = arguments['progress'];

      _onLogStatusChanged?.call(logPath, status, progress);
    } else {
      gemSdkLogger.log(
        Level.WARNING,
        'Unknown event subtype: ${arguments['eventType']} in LogUploadListener',
      );
    }
  }

  /// Registers a callback for log status changes.
  ///
  /// ## Parameters
  ///
  /// - [onLogStatusChanged]: The callback function to be invoked when the log status changes.
  void registerOnLogStatusChanged(
    void Function(String logPath, int status, int progress)? onLogStatusChanged,
  ) {
    _onLogStatusChanged = onLogStatusChanged;
  }
}

/// State of a log upload operation.
///
/// Describes the lifecycle states a log upload can be in while being
/// transferred to the server. This enum is used by [LogUploader] callbacks to
/// report progress and completion status.
///
/// {@category Sensor Data Source}
enum LogUploaderState {
  /// Log upload in progress.
  progress,

  /// Log upload ready.
  ready,
}

/// @nodoc
extension LogUploaderStateExtension on LogUploaderState {
  int get id {
    switch (this) {
      case LogUploaderState.progress:
        return 0;
      case LogUploaderState.ready:
        return 1;
    }
  }

  static LogUploaderState fromId(final int id) {
    switch (id) {
      case 0:
        return LogUploaderState.progress;
      case 1:
        return LogUploaderState.ready;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
