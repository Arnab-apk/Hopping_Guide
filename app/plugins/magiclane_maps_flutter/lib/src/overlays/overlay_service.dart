// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/common/task_handler.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Service-level APIs to discover and manage overlays.
///
/// [OverlayService] exposes static helpers for retrieving available overlays,
/// enabling/disabling overlays or categories, and managing offline overlay data
/// grabbers.
///
/// ## See also:
///
/// - [OverlayInfo] - Information about a single overlay dataset.
/// - [OverlayCollection] - A collection of available overlay datasets.
///
/// {@category Overlays}
abstract class OverlayService {
  /// Retrieve overlays available for the current map style.
  ///
  /// The method returns a tuple containing an [OverlayCollection] and a boolean
  /// that indicates whether all overlay information was immediately available.
  /// If the boolean is `false` some overlay metadata will be downloaded later and
  /// the optional [onCompleteDownload] callback will be invoked when the download completes.
  ///
  /// ## Parameters
  ///
  /// - [onCompleteDownload]: Optional callback invoked with a [GemError] when asynchronous
  /// overlay metadata download finishes.
  ///
  /// ## Returns
  ///
  /// - A [OverlayCollection] containing the available overlays.
  /// - A [bool] which is `true` when all overlay information was immediately available.
  ///   If `false`, some overlay metadata will be downloaded later and the optional [onCompleteDownload]
  ///   callback will be invoked when the download completes.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final Completer<GemError> completer = Completer<GemError>();
  /// final (OverlayCollection, bool) availableOverlays = OverlayService.getAvailableOverlays(onCompleteDownload: (error) {
  ///     completer.complete(error);
  /// });
  /// await completer.future;
  /// OverlayCollection collection = availableOverlays.$1;
  /// ```
  static (OverlayCollection, bool) getAvailableOverlays({
    final void Function(GemError error)? onCompleteDownload,
  }) {
    EventDrivenProgressListener? listener;
    if (onCompleteDownload != null) {
      listener = EventDrivenProgressListener();

      listener.registerOnCompleteWithData((
        final int err,
        final String hint,
        final Map<dynamic, dynamic> json,
      ) {
        GemKitPlatform.instance.unregisterEventHandler(listener!.id);
        onCompleteDownload(GemErrorExtension.fromCode(err));
      });

      GemKitPlatform.instance.registerEventHandler(listener.id, listener);
    }

    final OperationResult resultString = staticMethod(
      'OverlayService',
      'getAvailableOverlays',
      args: (listener != null) ? listener.id : 0,
    );

    final (OverlayCollection, bool) result = (
      OverlayCollection.init(resultString['result']['first']),
      resultString['result']['second'],
    );

    if (onCompleteDownload != null && result.$2) {
      onCompleteDownload(GemError.success);
    }

    return result;
  }

  /// Enable an overlay (or a single category) globally.
  ///
  /// The operation affects all registered consumers such as map views and alarms.
  ///
  /// ## Parameters
  ///
  /// - [uid]: The overlay UID to enable.
  /// - [categUid]: Optional category UID within the overlay. When set to -1 the
  ///   whole overlay is enabled.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success.
  /// - [GemError.notFound] when the overlay (or category) was not found.
  ///
  /// ## See also:
  ///
  /// - [OverlayInfo.uid] - Retrieve the unique identifier of an overlay.
  /// - [OverlayCategory.uid] - Retrieve the unique identifier of an overlay category.
  /// - [disableOverlay] - Disable an overlay or category globally.
  /// - [isOverlayEnabled] - Check whether an overlay or category is enabled.
  /// - [CommonOverlayId] - Predefined common overlay identifiers.
  static GemError enableOverlay(final int uid, {final int categUid = -1}) {
    final OperationResult resultString = staticMethod(
      'OverlayService',
      'enableOverlay',
      args: <String, int>{'uid': uid, 'categUid': categUid},
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Disable an overlay (or a single category) globally.
  ///
  /// ## Parameters
  ///
  /// - [uid]: The overlay UID to disable.
  /// - [categUid]: Optional category UID. When -1 the whole overlay is disabled.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success.
  /// - [GemError.notFound] when the overlay (or category) was not found.
  ///
  /// ## See also:
  ///
  /// - [OverlayInfo.uid] - Retrieve the unique identifier of an overlay.
  /// - [OverlayCategory.uid] - Retrieve the unique identifier of an overlay category.
  /// - [enableOverlay] - Enable an overlay or category globally.
  /// - [isOverlayEnabled] - Check whether an overlay or category is enabled.
  /// - [CommonOverlayId] - Predefined common overlay identifiers.
  static GemError disableOverlay(final int uid, {final int categUid = -1}) {
    final OperationResult resultString = staticMethod(
      'OverlayService',
      'disableOverlay',
      args: <String, int>{'uid': uid, 'categUid': categUid},
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Check whether an overlay (or a category) is currently enabled.
  ///
  /// ## Parameters
  ///
  /// - [uid]: The overlay UID.
  /// - [categUid]: Optional category UID. When -1 the check targets the whole overlay.
  ///
  /// ## Returns
  ///
  /// - True when enabled, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [OverlayInfo.uid] - Retrieve the unique identifier of an overlay.
  /// - [OverlayCategory.uid] - Retrieve the unique identifier of an overlay category.
  /// - [enableOverlay] - Enable an overlay or category globally.
  /// - [disableOverlay] - Disable an overlay or category globally.
  static bool isOverlayEnabled(final int uid, {final int categUid = -1}) {
    final OperationResult resultString = staticMethod(
      'OverlayService',
      'isOverlayEnabled',
      args: <String, int>{'uid': uid, 'categUid': categUid},
    );

    return resultString['result'];
  }

  /// Enable the offline data grabber for an overlay UID.
  ///
  /// When enabled the SDK will download overlay data covering offline map
  /// regions after map content downloads and cache it for offline use.
  ///
  ///
  /// ## Parameters
  ///
  /// - [uid]: Overlay UID to enable the grabber for.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success.
  /// - [GemError.notFound] when the overlay UID is unknown.
  /// - [GemError.exist] when the grabber is already enabled.
  ///
  /// ## See also:
  ///
  /// - [OverlayInfo.uid] - Retrieve the unique identifier of an overlay.
  /// - [disableOverlayOfflineDataGrabber] - Disable the offline data grabber for an overlay.
  /// - [isOverlayOfflineDataGrabberEnabled] - Check whether the offline data grabber is enabled for an overlay.
  /// - [isOverlayOfflineDataGrabberSupported] - Check whether an overlay supports the offline data grabber feature.
  static GemError enableOverlayOfflineDataGrabber(int uid) {
    final OperationResult resultString = staticMethod(
      'OverlayService',
      'enableOverlayOfflineDataGrabber',
      args: uid,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Disable the offline data grabber for the specified overlay UID.
  ///
  /// ## Parameters
  ///
  /// - [uid]: Overlay UID.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success.
  /// - [GemError.notFound] when the overlay is already disabled.
  ///
  /// ## See also:
  ///
  /// - [OverlayInfo.uid] - Retrieve the unique identifier of an overlay.
  /// - [enableOverlayOfflineDataGrabber] - Enable the offline data grabber for an overlay.
  /// - [isOverlayOfflineDataGrabberEnabled] - Check whether the offline data grabber is enabled for an overlay.
  /// - [isOverlayOfflineDataGrabberSupported] - Check whether an overlay supports the offline data grabber feature.
  static GemError disableOverlayOfflineDataGrabber(int uid) {
    final OperationResult resultString = staticMethod(
      'OverlayService',
      'disableOverlayOfflineDataGrabber',
      args: uid,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Return whether the offline data grabber is enabled for an overlay.
  ///
  /// ## Parameters
  ///
  /// - [uid]: Overlay UID to query.
  ///
  /// ## Returns
  ///
  /// - True when the grabber is enabled, false otherwise.
  ///
  /// ## See also:
  ///
  /// - [OverlayInfo.uid] - Retrieve the unique identifier of an overlay.
  /// - [enableOverlayOfflineDataGrabber] - Enable the offline data grabber for an overlay.
  /// - [disableOverlayOfflineDataGrabber] - Disable the offline data grabber for an overlay.
  /// - [isOverlayOfflineDataGrabberSupported] - Check whether an overlay supports the offline data grabber feature.
  static bool isOverlayOfflineDataGrabberEnabled(int uid) {
    final OperationResult resultString = staticMethod(
      'OverlayService',
      'isOverlayOfflineDataGrabberEnabled',
      args: uid,
    );

    return resultString['result'];
  }

  /// Check whether an overlay UID supports the offline data grabber feature.
  ///
  /// ## Parameters
  ///
  /// - [uid]: Overlay UID.
  ///
  /// ## Returns
  ///
  /// - True when the grabber is supported for the given overlay.
  ///
  /// ## See also:
  ///
  /// - [OverlayInfo.uid] - Retrieve the unique identifier of an overlay.
  /// - [enableOverlayOfflineDataGrabber] - Enable the offline data grabber for an overlay.
  /// - [disableOverlayOfflineDataGrabber] - Disable the offline data grabber for an overlay.
  /// - [isOverlayOfflineDataGrabberEnabled] - Check whether the offline data grabber is enabled for an overlay.
  static bool isOverlayOfflineDataGrabberSupported(int uid) {
    final OperationResult resultString = staticMethod(
      'OverlayService',
      'isOverlayOfflineDataGrabberSupported',
      args: uid,
    );

    return resultString['result'];
  }

  /// Start grabbing (downloading) the latest offline overlay data for all
  /// existing offline map areas.
  ///
  /// The operation is asynchronous; the provided [onComplete] callback is
  /// invoked with a [GemError] indicating completion status. If the grabber
  /// is not enabled for the overlay the callback receives [GemError.activation].
  ///
  /// ## Parameters
  ///
  /// - [uid]: Overlay UID to download data for.
  /// - [onComplete]: Callback is always invoked to indicate operation result:
  ///   - [GemError.success] on successful completion.
  ///   - [GemError.activation] when the grabber is not enabled for the overlay.
  ///   - [GemError.notFound] when the [uid] is invalid.
  ///   - [GemError.noConnection] when there is no network connection.
  ///
  /// ## Returns
  ///
  /// - A [TaskHandler] if the operation started successfully, otherwise null.
  /// ## Example
  ///
  /// ```dart
  /// final overlayUid = CommonOverlayId.safety.id; // Example overlay UID (e.g., speed cameras)
  /// if (!OverlayService.isOverlayOfflineDataGrabberSupported(overlayUid)) {
  ///   print('Overlay offline data grabber not supported for this overlay');
  ///   return;
  /// }
  ///
  /// OverlayService.enableOverlayOfflineDataGrabber(overlayUid);
  ///
  // final taskHandler = OverlayService.grabOverlayOfflineData(
  //     uid: overlayUid,
  //     onComplete: (error) {
  //     // Handle the completion of the offline data grabber (check GemError)
  //   }
  // );
  /// ```
  ///
  /// ## See also:
  ///
  /// - [OverlayInfo.uid] - Retrieve the unique identifier of an overlay.
  /// - [enableOverlayOfflineDataGrabber] - Enable the offline data grabber for an overlay.
  /// - [disableOverlayOfflineDataGrabber] - Disable the offline data grabber for an overlay.
  /// - [isOverlayOfflineDataGrabberEnabled] - Check whether the offline data grabber is enabled for an overlay.
  /// - [isOverlayOfflineDataGrabberSupported] - Check whether an overlay supports the offline data grabber feature.
  /// - [cancelGrabOverlayOfflineData] - Cancel a running offline data grab operation.
  static TaskHandler? grabOverlayOfflineData({
    required final int uid,
    required final void Function(GemError error) onComplete,
  }) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete(GemErrorExtension.fromCode(err));
    });

    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);

    final OperationResult resultString = staticMethod(
      'OverlayService',
      'grabOverlayOfflineData',
      args: <String, dynamic>{'uid': uid, 'listener': progListener.id},
    );

    final GemError errorCode = GemErrorExtension.fromCode(
      resultString['result'],
    );

    if (errorCode != GemError.success) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      onComplete(errorCode);
      return null;
    }

    return TaskHandlerImpl(progListener.id);
  }

  /// Cancel a previously started offline overlay data grab operation for the
  /// specified overlay UID.
  ///
  /// ## Parameters
  ///
  /// - [uid]: Overlay UID whose grab operation should be cancelled.
  ///
  /// ## See also:
  ///
  /// - [OverlayInfo.uid] - Retrieve the unique identifier of an overlay.
  /// - [grabOverlayOfflineData] - Start grabbing offline overlay data for an overlay.
  static void cancelGrabOverlayOfflineData(final int uid) {
    staticMethod('OverlayService', 'cancelGrabOverlayOfflineData', args: uid);
  }
}
