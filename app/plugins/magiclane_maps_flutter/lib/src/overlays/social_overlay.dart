// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:typed_data';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/routing.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/core/private/holders.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/obj_type.dart';

/// Static service for crowd-sourced social event reporting and interaction.
///
/// Provides a complete system for creating, managing, and interacting with
/// user-generated reports about real-time road conditions and incidents. Reports
/// include accidents, police presence, traffic conditions, road hazards, weather
/// hazards, fixed cameras, and road closures. All operations execute asynchronously
/// with callback-based result delivery.
///
/// Users can create reports with categories, descriptions, images, and custom
/// parameters. Reports can be prepared from the device's current position (via
/// [PositionService] data source) or from explicit coordinates.
///
/// Reports are visible to all users with the social overlay enabled and a
/// compatible map style. Each report displays for a limited duration before
/// automatic removal. Reports with many downvotes are removed earlier.
///
/// ## Prerequisites
///
/// - Active [PositionService] with high-accuracy data source for most report
///   categories (exception: Weather Hazard).
/// - Social reports overlay enabled on map (see [AlarmService] for alarm events).
///
/// ## See also:
///
/// - [AlarmService] - Provides notifications about incoming social reports.
/// - [PositionService] - Provides high-accuracy position data for reporting.
/// - [SocialReportsOverlayInfo] - Access to report categories and metadata.
/// - [SocialReportListener] - Monitors updates to specific reports.
/// - [OverlayItem] - Represents individual social report items on the map.
///
/// {@category Overlays}
abstract class SocialOverlay {
  /// Submits a prepared social event report to the community.
  ///
  /// Uploads a previously prepared report (via [prepareReporting] or
  /// [prepareReportingCoords]) with the specified category, optional description,
  /// image snapshot, and custom parameters. The report becomes visible to all
  /// users with social overlay enabled and displays for a limited duration
  /// before automatic removal.
  ///
  /// Reports must be prepared before submission to validate location accuracy
  /// and rate limiting. The preparation step returns a [prepareId] that must
  /// be used within a short time window before expiration.
  ///
  /// ## Parameters
  ///
  /// - [prepareId]: Prepared operation ID returned by [prepareReporting] or
  ///   [prepareReportingCoords]. Must be used before expiration (typically
  ///   within a few minutes).
  /// - [categId]: Report category or subcategory ID. Must match a valid
  ///   social report category. See [SocialReportsOverlayInfo.getSocialReportsCategories] for available IDs.
  /// - [description]: Optional text description providing additional context
  ///   about the reported event (default: empty string).
  /// - [snapshot]: Optional image data (Uint8List) for the report. Must be
  ///   provided together with [format]. If provided without [format], returns
  ///   [GemError.invalidInput] immediately.
  /// - [format]: Image format for [snapshot] (e.g., [ImageFileFormat.png],
  ///   [ImageFileFormat.jpeg]). Required if [snapshot] is provided.
  /// - [params]: Optional custom parameters for the report, following a specific structure.
  ///   Use [PredefinedReportParameterKeys] for standard parameter keys.
  /// - [onComplete]: Callback invoked when the operation completes or fails.
  ///   Called with:
  ///   - [GemError.success] when report is successfully submitted and visible.
  ///   - [GemError.invalidInput] if [categId] is invalid, [params] are ill-formed,
  ///     [snapshot] is invalid, or [snapshot]/[format] mismatch.
  ///   - [GemError.suspended] if user has exceeded report rate limit (too many
  ///     reports in short time period).
  ///   - [GemError.expired] if [prepareId] not found or too old (preparation expired).
  ///   - [GemError.notFound] if no high-accuracy position data available to
  ///     complete the report (position lost after preparation).
  ///
  /// ## Returns
  ///
  /// - [ProgressListener] if operation was successfully initiated (use with [cancel]).
  /// - `null` if operation could not be started (e.g., [snapshot]/[format]
  ///   mismatch detected immediately).
  ///
  /// ## Example
  ///
  /// ```dart
  /// SocialOverlay.report(
  ///   prepareId: prepareId,
  ///   categId: categId,
  ///   onComplete: (error) {
  ///     if (error == GemError.success) {
  ///       print('Report submitted successfully');
  ///     } else {
  ///       print('Report failed: $error');
  ///     }
  ///   },
  /// );
  /// ```
  ///
  /// ## See also:
  ///
  /// - [prepareReporting] - Prepares report using current position.
  /// - [prepareReportingCoords] - Prepares report for explicit coordinates. Only
  /// available for Weather Hazard category.
  /// - [cancel] - Cancels ongoing report submission.
  /// - [SocialReportsOverlayInfo.getSocialReportsCategories] - Lists available categories.
  static ProgressListener? report({
    required final int prepareId,
    required final int categId,
    final String description = '',
    final Uint8List? snapshot,
    final ImageFileFormat? format,
    final ParameterList? params,
    final void Function(GemError error)? onComplete,
  }) {
    if ((snapshot == null) != (format == null)) {
      onComplete?.call(GemError.invalidInput);
      return null;
    }

    dynamic gemImage;
    if (snapshot != null) {
      gemImage = GemKitPlatform.instance.createGemImage(snapshot, format!.id);
    }
    try {
      final EventDrivenProgressListener progListener =
          EventDrivenProgressListener();
      GemKitPlatform.instance.registerEventHandler(
        progListener.id,
        progListener,
      );

      progListener.registerOnCompleteWithData((final int err, _, _) {
        GemKitPlatform.instance.unregisterEventHandler(progListener.id);
        onComplete?.call(GemErrorExtension.fromCode(err));
      });

      final OperationResult result = staticMethod(
        'SocialOverlay',
        'report',
        args: <String, dynamic>{
          'prepareId': prepareId,
          'categId': categId,
          'description': description,
          'snapshot': gemImage ?? 0,
          'params': params != null ? params.pointerId : 0,
          'listener': progListener.id,
        },
      );
      final int id = result['result'];
      final GemError error = GemErrorExtension.fromCode(id);

      if (error != GemError.scheduled) {
        GemKitPlatform.instance.unregisterEventHandler(progListener.id);
        onComplete?.call(error);
        return null;
      }

      return progListener;
    } finally {
      if (gemImage != null) {
        GemKitPlatform.instance.deleteCPointer(gemImage, ObjType.gemImage);
      }
    }
  }

  /// Prepares a report for submission using explicit coordinates.
  ///
  /// Validates and prepares a report at the specified geographic location
  /// without requiring active position tracking. Works only for Weather Hazard
  /// and its subcategories. Other categories require [prepareReporting] with
  /// high-accuracy position data for safety and accuracy reasons.
  ///
  /// Operates in two modes based on [categId]:
  /// - **Preparing mode** ([categId] = 0): Returns a preparation ID for use
  ///   with [report]. The ID expires after a short time (typically minutes).
  /// - **Dry run mode** ([categId] ≠ 0): Tests if the category can be reported
  ///   at these coordinates without actually preparing. Returns error code as
  ///   integer (check against [GemError] ID values).
  ///
  /// ## Parameters
  ///
  /// - [coords]: Geographic coordinates where the event is being reported.
  ///   Must be valid latitude/longitude values.
  /// - [categId]: Category ID for dry run validation, or 0 for actual
  ///   preparation (default: 0). Use 0 when preparing for [report] submission.
  ///
  /// ## Returns
  ///
  /// **Dry run mode** ([categId] ≠ 0):
  /// - [GemError.suspended]`.id` if report rate limit exceeded.
  /// - [GemError.invalidInput]`.id` if [categId] is not a valid category ID.
  /// - [GemError.accessDenied]`.id` if category doesn't allow coordinate-based
  ///   reporting (use [prepareReporting] with [DataSource] instead).
  ///
  /// **Preparing mode** ([categId] = 0):
  /// - [GemError.suspended]`.id` if report rate limit exceeded.
  /// - Positive integer: Preparation ID for use with [report] (valid for short duration).
  ///
  /// ## See also:
  ///
  /// - [prepareReporting] - Prepares report using current position (required for most categories).
  /// - [report] - Submits prepared report using returned preparation ID.
  static int prepareReportingCoords(
    final Coordinates coords, {
    final int categId = 0,
  }) {
    final OperationResult result = staticMethod(
      'SocialOverlay',
      'prepareReportingCoords',
      args: <String, dynamic>{'coords': coords, 'categId': categId},
    );
    return result['result'];
  }

  /// Prepares a report using the device's current high-accuracy position.
  ///
  /// Validates position accuracy and rate limits, then generates a preparation
  /// ID for submitting a report via [report]. Required for most report categories.
  /// The position must be classified as high-accuracy by the map-matching
  /// system to ensure report reliability.
  ///
  /// Operates in two modes based on [categId]:
  /// - **Preparing mode** ([categId] = 0): Returns a preparation ID for use
  ///   with [report]. The ID expires after a short time (typically minutes).
  /// - **Dry run mode** ([categId] ≠ 0): Tests if reporting is possible for
  ///   the category without actually preparing. Returns error code as integer
  ///   (check against [GemError] ID values).
  ///
  /// ## Prerequisites
  ///
  /// - High-accuracy position data available from [PositionService] or specified
  ///   [dataSource]. Low-accuracy positions are rejected.
  /// - [dataSource] must have type [DataSourceType.live].
  ///
  /// ## Parameters
  ///
  /// - [dataSource]: Optional [DataSource] providing position. If `null`, uses
  ///   current [PositionService] data source. Must be live type with high-accuracy
  ///   position data.
  /// - [categId]: Category ID for dry run validation, or 0 for actual
  ///   preparation (default: 0). Use 0 when preparing for [report] submission.
  ///
  /// ## Returns
  ///
  /// **Dry run mode** ([categId] ≠ 0):
  /// - [GemError.suspended]`.id` if report rate limit exceeded.
  /// - [GemError.invalidInput]`.id` if [categId] is not a valid category ID.
  /// - [GemError.notFound]`.id` if no valid high-accuracy position available.
  /// - [GemError.required]`.id` if [dataSource] type is not [DataSourceType.live].
  ///
  /// **Preparing mode** ([categId] = 0):
  /// - [GemError.suspended]`.id` if report rate limit exceeded.
  /// - [GemError.notFound]`.id` if no valid high-accuracy position available.
  /// - Positive integer: Preparation ID for use with [report] (valid for short duration).
  ///
  /// ## See also:
  ///
  /// - [prepareReportingCoords] - Prepares report for explicit coordinates (Weather Hazard only).
  /// - [report] - Submits prepared report using returned preparation ID.
  /// - [PositionService] - Provides position data for reporting.
  static int prepareReporting({DataSource? dataSource, final int categId = 0}) {
    dataSource ??= PositionService.getDataSource();
    final OperationResult result = staticMethod(
      'SocialOverlay',
      'prepareReporting',
      args: <String, dynamic>{
        'categId': categId,
        'dataSource': dataSource == null ? 0 : dataSource.pointerId,
      },
    );
    return result['result'];
  }

  /// Provides positive feedback (upvote) for a report.
  ///
  /// Confirms that a reported event is accurate and still in effect, increasing
  /// the report's score value in [OverlayItem.previewData].
  ///
  /// Each user can confirm or deny a report only once. The operation executes
  /// asynchronously with result delivered via [onComplete] callback.
  ///
  /// ## Parameters
  ///
  /// - [item]: The social report [OverlayItem] to confirm. Must be a valid
  ///   social report overlay item obtained from map selection, search, or
  ///   alarm notification.
  /// - [onComplete]: Callback invoked when operation completes or fails.
  ///   Called with:
  ///   - [GemError.success] when confirmation is successfully recorded.
  ///   - [GemError.invalidInput] if [item] is not a social report overlay item
  ///     or not from alarm notification.
  ///   - [GemError.accessDenied] if user has already confirmed or denied this report.
  ///
  /// ## Returns
  ///
  /// - [ProgressListener] if operation was successfully initiated (use with [cancel]).
  /// - `null` if operation could not be started.
  ///
  /// ## See also:
  ///
  /// - [denyReport] - Provides negative feedback for inaccurate reports.
  /// - [addComment] - Adds contextual comment to report.
  /// - [AlarmService] - Provides notifications about incoming social reports.
  static ProgressListener? confirmReport(
    final OverlayItem item, {
    final void Function(GemError error)? onComplete,
  }) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);

    progListener.registerOnCompleteWithData((final int err, _, _) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete?.call(GemErrorExtension.fromCode(err));
    });

    final OperationResult result = staticMethod(
      'SocialOverlay',
      'confirmReport',
      args: <String, dynamic>{
        'item': item.pointerId,
        'listener': progListener.id,
      },
    );

    final GemError errorCode = GemErrorExtension.fromCode(result['result']);

    if (errorCode != GemError.scheduled) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete?.call(errorCode);
      return null;
    }

    return progListener;
  }

  /// Provides negative feedback (downvote) for an inaccurate report.
  ///
  /// Denies that a reported event is accurate or still in effect, decreasing
  /// the report's score. Reports with many downvotes are automatically removed
  /// to maintain information quality. Use when the reported condition no longer
  /// exists or was never accurate.
  ///
  /// Each user can confirm or deny a report only once. The operation executes
  /// asynchronously with result delivered via [onComplete] callback.
  ///
  /// ## Parameters
  ///
  /// - [item]: The social report [OverlayItem] to deny. Must be a valid
  ///   social report overlay item obtained from map selection, search, or
  ///   alarm notification.
  /// - [onComplete]: Callback invoked when operation completes or fails.
  ///   Called with:
  ///   - [GemError.success] when denial is successfully recorded.
  ///   - [GemError.invalidInput] if [item] is not a social report overlay item
  ///     or not from alarm notification.
  ///   - [GemError.accessDenied] if user has already confirmed or denied this report.
  ///
  /// ## Returns
  ///
  /// - [ProgressListener] if operation was successfully initiated (use with [cancel]).
  /// - `null` if operation could not be started.
  ///
  /// ## See also:
  ///
  /// - [confirmReport] - Provides positive feedback for accurate reports.
  /// - [deleteReport] - Deletes own report completely (owner only).
  /// - [AlarmService] - Provides notifications about incoming social reports.
  static ProgressListener? denyReport(
    final OverlayItem item, {
    final void Function(GemError error)? onComplete,
  }) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);

    progListener.registerOnCompleteWithData((final int err, _, _) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete?.call(GemErrorExtension.fromCode(err));
    });

    final OperationResult result = staticMethod(
      'SocialOverlay',
      'denyReport',
      args: <String, dynamic>{
        'item': item.pointerId,
        'listener': progListener.id,
      },
    );

    final GemError errorCode = GemErrorExtension.fromCode(result['result']);

    if (errorCode != GemError.scheduled) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete?.call(errorCode);
      return null;
    }

    return progListener;
  }

  /// Permanently removes a user's own report.
  ///
  /// Deletes a social report created by the current user, removing it completely
  /// from the map for all users. Only the original report creator has authority
  /// to delete their reports. The operation executes asynchronously with result
  /// delivered via [onComplete] callback.
  ///
  /// ## Parameters
  ///
  /// - [item]: The social report [OverlayItem] to delete. Must be a valid
  ///   social report overlay item created by the current user.
  /// - [onComplete]: Callback invoked when operation completes or fails.
  ///   Called with:
  ///   - [GemError.success] when report is successfully deleted.
  ///   - [GemError.invalidInput] if [item] is not a social report overlay item
  ///     or not from alarm notification.
  ///   - [GemError.accessDenied] if user is not the report creator (only owner
  ///     can delete their reports).
  ///
  /// ## Returns
  ///
  /// - [ProgressListener] if operation was successfully initiated (use with [cancel]).
  /// - `null` if operation could not be started.
  ///
  /// ## See also:
  ///
  /// - [denyReport] - Provides negative feedback (available to all users).
  /// - [updateReport] - Modifies report parameters (owner only).
  /// - [AlarmService] - Provides notifications about incoming social reports.
  static ProgressListener? deleteReport(
    final OverlayItem item, {
    final void Function(GemError error)? onComplete,
  }) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);

    progListener.registerOnCompleteWithData((final int err, _, _) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete?.call(GemErrorExtension.fromCode(err));
    });

    final OperationResult result = staticMethod(
      'SocialOverlay',
      'deleteReport',
      args: <String, dynamic>{
        'item': item.pointerId,
        'listener': progListener.id,
      },
    );

    final GemError errorCode = GemErrorExtension.fromCode(result['result']);

    if (errorCode != GemError.scheduled) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete?.call(errorCode);
      return null;
    }

    return progListener;
  }

  /// Modifies parameters of an existing owned report.
  ///
  /// Updates custom parameters for a report created by the current user, such
  /// as location address or other metadata. The [params] structure must follow
  /// the format from [OverlayItem.previewDataParameterList]. Only the original
  /// report creator has authority to update their reports.
  ///
  /// ## Parameters
  ///
  /// - [item]: The social report [OverlayItem] to update. Must be created by
  ///   the current user.
  /// - [params]: Optional custom parameters for the report, following a specific structure.
  ///   Use [PredefinedReportParameterKeys] for standard parameter keys.
  /// - [onComplete]: Callback invoked when operation completes or fails.
  ///   Called with:
  ///   - [GemError.success] when report is successfully updated.
  ///   - [GemError.invalidInput] if [item] is not a social report overlay item
  ///     or [params] structure is ill-formatted.
  ///
  /// ## Returns
  ///
  /// - [ProgressListener] if operation was successfully initiated (use with [cancel]).
  /// - `null` if operation could not be started.
  ///
  /// ## See also:
  ///
  /// - [deleteReport] - Permanently removes owned report.
  /// - [PredefinedReportParameterKeys] - Standard parameter keys for reports.
  static ProgressListener? updateReport({
    required final OverlayItem item,
    required final SearchableParameterList params,
    void Function(GemError error)? onComplete,
  }) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);

    progListener.registerOnCompleteWithData((final int err, _, _) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete?.call(GemErrorExtension.fromCode(err));
    });

    final OperationResult result = staticMethod(
      'SocialOverlay',
      'updateReport',
      args: <String, dynamic>{
        'item': item.pointerId,
        'listener': progListener.id,
        'params': params.pointerId,
      },
    );

    final GemError error = GemErrorExtension.fromCode(result['result']);
    if (error != GemError.scheduled) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete?.call(error);
      return null;
    }

    return progListener;
  }

  /// Adds a text comment to an existing social report.
  ///
  /// Submits user commentary on a social report, visible to all users viewing
  /// that report. Comments support community discussion and provide additional
  /// context. The comment appears in [OverlayItem.previewData]. Operation
  /// executes asynchronously with result delivered via [onComplete] callback.
  ///
  /// ## Parameters
  ///
  /// - [item]: The social report [OverlayItem] to comment on. Must be a valid
  ///   social report from alarm notification or map selection.
  /// - [comment]: Comment text content.
  /// - [onComplete]: Callback invoked when operation completes or fails.
  ///   Called with:
  ///   - [GemError.success] when comment is successfully submitted.
  ///   - [GemError.invalidInput] if [item] is not a social report overlay item
  ///     or not from alarm notification.
  ///   - [GemError.connectionRequired] if no data connection is available.
  ///   - [GemError.busy] if another add comment operation is in progress.
  ///
  /// ## Returns
  ///
  /// - [ProgressListener] if operation was successfully initiated (use with [cancel]).
  /// - `null` if operation could not be started.
  ///
  /// ## See also:
  ///
  /// - [confirmReport] - Upvotes the report validity.
  /// - [denyReport] - Downvotes the report validity.
  static ProgressListener? addComment({
    required final OverlayItem item,
    required final String comment,
    void Function(GemError error)? onComplete,
  }) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);

    progListener.registerOnCompleteWithData((final int err, _, _) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete?.call(GemErrorExtension.fromCode(err));
    });

    final OperationResult result = staticMethod(
      'SocialOverlay',
      'addComment',
      args: <String, dynamic>{
        'item': item.pointerId,
        'comment': comment,
        'listener': progListener.id,
      },
    );

    final GemError error = GemErrorExtension.fromCode(result['result']);
    if (error != GemError.scheduled) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete?.call(error);
      return null;
    }

    return progListener;
  }

  /// Retrieves the image snapshot associated with a social report.
  ///
  /// Downloads the photo attached to a social report when submitted with image
  /// data. Only applicable to Social Reports Overlay items. Returns image via
  /// [onComplete] callback with [Img] result. Operation executes asynchronously
  /// with progress tracking.
  ///
  /// ## Parameters
  ///
  /// - [item]: The social report [OverlayItem] containing snapshot. Must be a
  ///   valid social report from alarm notification or map selection.
  /// - [onComplete]: Callback invoked when operation completes or fails.
  ///   Called with error code and image:
  ///   - [GemError.success] with [Img] when snapshot is retrieved successfully.
  ///   - [GemError.invalidInput] if [item] is not a social report overlay item
  ///     or not from alarm notification.
  ///   - [GemError.connectionRequired] if no data connection is available.
  ///
  /// ## Returns
  ///
  /// - [ProgressListener] for tracking operation progress if started successfully.
  /// - `null` if operation could not be started.
  ///
  /// ## See also:
  ///
  /// - [report] - Submits report with optional snapshot image.
  static ProgressListener? getReportSnapshot({
    required final OverlayItem item,
    required void Function(GemError error, Img? imageInfo) onComplete,
  }) {
    final ImgHolder result = ImgHolder();
    final EventDrivenProgressListener listener = EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    listener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
      if (err == 0) {
        onComplete(GemErrorExtension.fromCode(err), result.value);
      } else {
        onComplete(GemErrorExtension.fromCode(err), null);
      }
      result.dispose();
    });

    staticMethod(
      'SocialOverlay',
      'getReportSnapshot',
      args: <String, dynamic>{
        'item': item.pointerId,
        'image': result.pointerId,
        'listener': listener.id,
      },
    );

    final GemError err = ApiErrorService.apiError;
    if (err != GemError.success) {
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
      onComplete(err, null);
      return null;
    }

    return listener;
  }

  /// Cancels an ongoing social overlay operation.
  ///
  /// Terminates an active asynchronous operation started by methods returning
  /// [ProgressListener], such as [report], [confirmReport], [denyReport],
  /// [deleteReport], [updateReport], or [addComment]. Cancellation prevents
  /// the [onComplete] callback from executing.
  ///
  /// ## Parameters
  ///
  /// - [progressListener]: The [ProgressListener] returned from the operation to cancel.
  ///
  /// ## See also:
  ///
  /// - [report] - Submits new social report (cancellable).
  /// - [confirmReport] - Upvotes report validity (cancellable).
  static void cancel(ProgressListener progressListener) {
    staticMethod('SocialOverlay', 'cancel', args: progressListener.id);
  }

  /// Provides access to social report category hierarchy and metadata.
  ///
  /// Returns [SocialReportsOverlayInfo] containing all available report categories
  /// with their subcategories and configuration. Use for discovering valid
  /// [categId] values for [report] method and category-specific parameters.
  ///
  /// ## See also:
  ///
  /// - [SocialReportsOverlayInfo] - Provides category querying methods.
  /// - [report] - Requires category ID from this hierarchy.
  static SocialReportsOverlayInfo get reportsOverlayInfo {
    final OperationResult result = staticMethod(
      'SocialOverlay',
      'getReportsOverlayInfo',
    );

    return SocialReportsOverlayInfo.init(result['result']);
  }

  /// Provides network traffic statistics for social reports operations.
  ///
  /// Returns a [TransferStatistics] object containing counters and metrics
  /// about network usage performed by the traffic service. This information
  /// can be used for diagnostics or to display usage to end users.
  ///
  /// ## See also:
  ///
  /// - [TransferStatistics] - Contains upload/download byte counters.
  /// - [report] - Operation contributing to upload statistics.
  static TransferStatistics get transferStatistics {
    final OperationResult resultString = staticMethod(
      'SocialOverlay',
      'getTransferStatistics',
    );

    return TransferStatistics.init(resultString['result']);
  }

  /// Registers a listener to monitor changes to a specific social report.
  ///
  /// Subscribes [listener] to receive notifications when the specified social
  /// report is modified (e.g., updated parameters, new comments, score changes).
  /// Use with [unregisterReportListener] to stop monitoring.
  ///
  /// ## Parameters
  ///
  /// - [report]: The social report [OverlayItem] to monitor for changes.
  /// - [listener]: The [SocialReportListener] to receive change notifications.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] if listener successfully registered.
  /// - [GemError.invalidInput] if [report] is not a Social Reports Overlay item.
  /// - [GemError.exist] if [listener] is already registered for this report.
  ///
  /// ## See also:
  ///
  /// - [unregisterReportListener] - Stops monitoring changes.
  /// - [SocialReportListener] - Listener interface for report changes.
  static GemError registerReportListener(
    OverlayItem report,
    SocialReportListener listener,
  ) {
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    final OperationResult res = staticMethod(
      'SocialOverlay',
      'registerReportListener',
      args: <String, dynamic>{'first': report.pointerId, 'second': listener.id},
    );

    return GemErrorExtension.fromCode(res['result']);
  }

  /// Unregisters a listener from monitoring a specific social report.
  ///
  /// Removes [listener] subscription from the specified social report, stopping
  /// change notifications. Call when no longer interested in report updates to
  /// prevent memory leaks and unnecessary callbacks.
  ///
  /// ## Parameters
  ///
  /// - [report]: The social report [OverlayItem] to stop monitoring.
  /// - [listener]: The [SocialReportListener] to unregister.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] if listener successfully unregistered.
  /// - [GemError.invalidInput] if [report] is not a Social Reports Overlay item.
  /// - [GemError.notFound] if [listener] is not currently registered for this report.
  ///
  /// ## See also:
  ///
  /// - [registerReportListener] - Starts monitoring changes.
  /// - [SocialReportListener] - Listener interface for report changes.
  static GemError unregisterReportListener(
    OverlayItem report,
    SocialReportListener listener,
  ) {
    final OperationResult res = staticMethod(
      'SocialOverlay',
      'unregisterReportListener',
      args: <String, dynamic>{'first': report.pointerId, 'second': listener.id},
    );

    return GemErrorExtension.fromCode(res['result']);
  }
}
