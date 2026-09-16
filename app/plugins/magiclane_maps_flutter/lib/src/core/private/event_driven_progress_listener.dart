// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// @nodoc
library;

import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';
import 'package:meta/meta.dart';

/// @nodoc
class EventDrivenProgressListener extends ProgressListener
    implements EventHandler {
  EventDrivenProgressListener() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'ProgressListener'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    id = decodedVal['result'];
  }

  @internal
  EventDrivenProgressListener.init(final dynamic id) {
    this.id = id;
  }
  void Function(int err, String hint, Map<dynamic, dynamic> json)?
  _onCompleteWithDataCallback;
  void Function(int progress)? _onProgressCallback;
  void Function(int status)? _onNotifyStatusChanged;

  @override
  void registerOnCompleteWithData(
    final void Function(int err, String hint, Map<dynamic, dynamic> json)?
    callback,
  ) {
    _onCompleteWithDataCallback = callback;
  }

  @override
  void registerOnProgress(final void Function(int progress)? callback) {
    _onProgressCallback = callback;
  }

  @override
  void registerOnNotifyStatusChanged(
    final void Function(int status)? callback,
  ) {
    _onNotifyStatusChanged = callback;
  }

  @internal
  @override
  Future<void> notifyComplete(final int err, final String hint) async {
    if (err == 0) {}
  }

  @internal
  @override
  void notifyCompleteWithData(
    final int err,
    final String hint,
    final Map<dynamic, dynamic> json,
  ) {
    if (_onCompleteWithDataCallback != null) {
      _onCompleteWithDataCallback!(err, hint, json);
    }
  }

  @internal
  @override
  void notifyProgress(final int progress) {
    if (_onProgressCallback != null) {
      _onProgressCallback!(progress);
    }
  }

  @internal
  @override
  void notifyStart(final bool hasProgress) {
    if (hasProgress) {}
  }

  @internal
  @override
  void notifyStatusChanged(final int status) {
    if (_onNotifyStatusChanged != null) {
      _onNotifyStatusChanged!(status);
    }
  }

  @internal
  @override
  void handleEvent(final Map<dynamic, dynamic> arguments) {
    if (arguments['eventType'] == 'startEvent') {
      notifyStart(false);
    } else if (arguments['eventType'] == 'completeEvent') {
      final int err = arguments['errCode'];
      final String hint = arguments.containsKey('hint')
          ? arguments['hint']
          : '';
      notifyCompleteWithData(err, hint, arguments);
    } else if (arguments['eventType'] == 'notifyProgress') {
      notifyProgress(arguments['progress']);
    } else if (arguments['eventType'] == 'statusEvent') {
      notifyStatusChanged(arguments['status']);
    } else {
      gemSdkLogger.log(
        Level.WARNING,
        'Unknown event type: ${arguments['eventType']} in EventDrivenProgressListener',
      );
    }
  }

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
    _onCompleteWithDataCallback = null;
    _onProgressCallback = null;
    _onNotifyStatusChanged = null;
  }

  @override
  int get progressMultiplier {
    final OperationResult resultString = objectMethod(
      id,
      'ProgressListener',
      'getProgressMultiplier',
    );

    return resultString['result'] as int;
  }

  @override
  int get notifyProgressInterval {
    final OperationResult resultString = objectMethod(
      id,
      'ProgressListener',
      'getNotifyProgressInterval',
    );

    return resultString['result'] as int;
  }

  @override
  set notifyProgressInterval(final int ms) {
    objectMethod(id, 'ProgressListener', 'setNotifyProgressInterval', args: ms);
  }
}
