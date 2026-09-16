// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';

/// Listens for updates to social report overlay items and delivers update events.
///
/// Notifies about changes to social‑report overlay items such as new comments,
/// thumb (upvote/downvote) actions, or other detail changes. Use this listener
/// to receive the updated [OverlayItem] whenever the social overlay emits an
/// update for a specific report.
///
/// Typical usage:
///
/// ```dart
/// final listener = SocialReportListener(
///   onReportUpdated: (OverlayItem report) {
///     // Do something with the updated report
///   },
/// );
///
/// SocialOverlay.registerReportListener(reportItem, listener);
/// ```
///
/// Obtain and register instances via [SocialOverlay.registerReportListener].
///
/// ## Also see:
///
/// - [SocialOverlay.registerReportListener] - Register listeners for report updates.
/// - [OverlayItem] - Represents social report overlay items with preview data.
/// - [AlarmService] - Get notifications related to incoming social reports.
///
/// {@category Overlays}
class SocialReportListener extends EventHandler {
  /// Creates a [SocialReportListener] and sets an optional update callback.
  ///
  /// The optional [onReportUpdated] callback is invoked whenever the monitored
  /// report is updated (for example, when a comment is added or the score
  /// changes). The callback receives the updated [OverlayItem].
  ///
  /// ## Parameters
  ///
  /// - [onReportUpdated]: Optional callback called with the updated
  ///   [OverlayItem] whenever the report emits an update event. Example:
  ///   - report: The updated overlay item containing refreshed preview data
  ///     (comments, score, timestamps, etc.).
  factory SocialReportListener({
    final void Function(OverlayItem item)? onReportUpdated,
  }) {
    final SocialReportListener listener = SocialReportListener._create();
    if (onReportUpdated != null) {
      listener._onReportUpdated = onReportUpdated;
    }
    return listener;
  }

  SocialReportListener.init(this.id);
  void Function(OverlayItem item)? _onReportUpdated;

  dynamic id;

  static SocialReportListener _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'SocialReportListener',
        'args': <dynamic, dynamic>{},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return SocialReportListener.init(decodedVal['result']);
  }

  /// Registers a callback to receive report update notifications.
  ///
  /// The registered callback is invoked when the social overlay emits an
  /// update for the monitored report, for example when a new comment is
  /// posted, a thumb is applied, or report details change. The callback
  /// receives the updated [OverlayItem].
  ///
  /// ## Parameters
  ///
  /// - [onReportUpdated]: Callback invoked with the updated report.
  ///   - report: The updated [OverlayItem] carrying refreshed preview data
  ///     (comments, score, timestamps, owner info, etc.).
  void registerOnReportUpdated(
    final void Function(OverlayItem report)? onReportUpdated,
  ) {
    _onReportUpdated = onReportUpdated;
  }

  @override
  void handleEvent(final Map<dynamic, dynamic> arguments) {
    final String eventSubtype = arguments['event_subtype'];

    switch (eventSubtype) {
      case 'onReportUpdated':
        if (_onReportUpdated != null) {
          final OverlayItem report = OverlayItem.init(arguments['report']);
          _onReportUpdated!(report);
        }

      default:
        gemSdkLogger.log(
          Level.WARNING,
          'Unknown event subtype: $eventSubtype in SocialReportListener',
        );
    }
  }

  @override
  void nativeClear() {
    // No native-side cleanup required for this listener.
  }

  @override
  void clearListeners() {
    _onReportUpdated = null;
  }
}
