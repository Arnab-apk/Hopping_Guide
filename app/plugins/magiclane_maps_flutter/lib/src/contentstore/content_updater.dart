// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/contentstore/content_store_enums.dart';
import 'package:magiclane_maps_flutter/src/contentstore/content_store_item.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Manages and applies updates for downloaded content in the content store.
///
/// A [ContentUpdater] represents a single update session created by the [ContentStore].
/// Use [ContentStore.createContentUpdater] to obtain an instance. The updater is responsible
/// for starting or resuming the download of available updates, reporting progress and status
/// changes via callbacks, and applying the downloaded update when ready.
///
/// The updater supports updating content types such as [ContentType.roadMap],
/// [ContentType.viewStyleLowRes] and [ContentType.viewStyleHighRes]. For road maps the SDK
/// requires all local road map items to have the same version; partial updates of individual
/// roadMap items with different versions are not supported.
///
/// ## Example
///
/// ```dart
/// final (contentUpdater, code) = ContentStore.createContentUpdater(ContentType.roadMap);
/// if (code == GemError.success || code == GemError.exist) {
///   final ProgressListener? listener = contentUpdater.update(
///     true,
///     onStatusUpdated: (status) {
///       if (status == ContentUpdaterStatus.fullyReady || status == ContentUpdaterStatus.partiallyReady) {
///         if (contentUpdater.canApply) {
///           final applyErr = contentUpdater.apply();
///           print('Apply resolved with code ${applyErr.code}');
///         }
///       }
///     },
///     onProgressUpdated: (p) => print('Progress: $p/100'),
///     onComplete: (err) => print('Update finished: $err'),
///   );
/// }
/// ```
///
/// ## See also:
///
/// - [ContentStore.createContentUpdater] - Obtain a [ContentUpdater] instance.
/// - [ContentUpdater.update] - Start or resume the update process and register callbacks.
/// - [ContentUpdater.apply] - Apply a downloaded update when ready.
///
/// {@category Content}
class ContentUpdater extends GemAutoreleaseObject {
  // ignore: unused_element
  ContentUpdater._() : _mapId = -1, super(-1);

  @internal
  ContentUpdater.init(super.id, final int mapId) : _mapId = mapId;

  final int _mapId;

  int get mapId => _mapId;

  /// Starts or resumes the content update process.
  ///
  /// Initiates downloading of available updates for the updater's [contentType]. The
  /// download runs in background and reports status and progress via optional callbacks.
  /// If the operation cannot be started the provided [onComplete] callback will be invoked
  /// with the corresponding [GemError] code and the method returns `null`.
  ///
  /// ## Parameters
  ///
  /// - [allowChargeNetwork]: Whether updates are allowed to proceed on metered/charged networks (mobile data).
  /// - [onStatusUpdated]: Optional callback invoked when the updater status changes. Receives a [ContentUpdaterStatus].
  /// Apply the update when the status is [ContentUpdaterStatus.fullyReady] or [ContentUpdaterStatus.partiallyReady].
  /// - [onProgressUpdated]: Optional callback invoked when download progress updates. Receives an integer 0..100.
  /// - [onComplete]: Optional callback invoked when the update operation completes or fails. Receives a [GemError].
  ///   - [GemError.success] when the update finishes successfully.
  ///   - [GemError.inUse] when the update is already running and cannot be started.
  ///   - [GemError.notSupported] when updates are not supported for the [contentType].
  ///   - [GemError.noDiskSpace] when there is insufficient device storage to download the update.
  ///   - [GemError.io] when a filesystem-related error occurred.
  ///   - Other [GemError] values for additional failure reasons.
  /// - [dataSavePolicy]: Specifies how downloaded data should be saved. Defaults to [DataSavePolicy.useDefault].
  ///
  /// ## Returns
  ///
  /// - [ProgressListener]? : The associated [ProgressListener] for tracking the operation if it was started, otherwise `null`.
  ///
  /// ## Also see:
  ///
  /// - [apply]: Apply a downloaded update when ready.
  ProgressListener? update(
    final bool allowChargeNetwork, {
    final void Function(ContentUpdaterStatus status)? onStatusUpdated,
    final void Function(int progress)? onProgressUpdated,
    final void Function(GemError error)? onComplete,
    final DataSavePolicy dataSavePolicy = DataSavePolicy.useDefault,
  }) {
    final EventDrivenProgressListener progressListener =
        EventDrivenProgressListener();

    if (onStatusUpdated != null) {
      progressListener.registerOnNotifyStatusChanged(
        (final int status) =>
            onStatusUpdated(ContentUpdaterStatusExtension.fromId(status)),
      );
    }

    if (onProgressUpdated != null) {
      progressListener.registerOnProgress(
        (final int progress) => onProgressUpdated(progress),
      );
    }

    if (onComplete != null) {
      progressListener.registerOnCompleteWithData(
        (final int err, final String hint, final Map<dynamic, dynamic> json) =>
            onComplete(GemErrorExtension.fromCode(err)),
      );
    }

    GemKitPlatform.instance.registerEventHandler(
      progressListener.id,
      progressListener,
    );

    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentUpdater',
      'update',
      args: <String, dynamic>{
        'allowChargeNetwork': allowChargeNetwork,
        'listener': progressListener.id,
        'savePolicy': dataSavePolicy.id,
      },
    );

    final GemError errorCode = GemErrorExtension.fromCode(
      resultString['result'],
    );
    if (errorCode != GemError.success) {
      onComplete?.call(errorCode);
      return null;
    }

    return progressListener;
  }

  /// Gets the list of content items involved in the update process.
  ///
  /// Returns the list of [ContentStoreItem] instances that are part of the currently
  /// prepared update. This collection is populated when the updater status transitions
  /// to [ContentUpdaterStatus.fullyReady] or [ContentUpdaterStatus.partiallyReady].
  ///
  /// ## Returns
  ///
  /// - `List<ContentStoreItem>`: Items targeted by the pending update.
  ///
  /// ## Also see:
  ///
  /// - [ContentStoreItem.updateItem] - Get the update item for a specific content store item.
  List<ContentStoreItem> get items {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentUpdater',
      'getItems',
    );

    return ContentStoreItemList.init(resultString['result']).toList();
  }

  /// Gets the content type being updated.
  ///
  /// ## Returns
  ///
  /// - [ContentType]: The content type this updater manages (for example [ContentType.roadMap]).
  ContentType get contentType {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentUpdater',
      'getContentType',
    );

    return ContentTypeExtension.fromId(resultString['result']);
  }

  /// Gets the current status of the update operation.
  ///
  /// ## Returns
  ///
  /// - [ContentUpdaterStatus]: Current status of the update flow.
  ContentUpdaterStatus get status {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentUpdater',
      'getStatus',
    );

    return ContentUpdaterStatusExtension.fromId(resultString['result']);
  }

  /// Gets the progress value of the update operation.
  ///
  /// Progress is expressed as an integer percentage (0..100) and is calculated with respect
  /// to [ProgressListener.progressMultiplier].
  ///
  /// ## Returns
  ///
  /// - `int`: The current progress value for the update operation.
  int get progress {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentUpdater',
      'getProgress',
    );

    return resultString['result'];
  }

  /// Checks if the content update can be applied.
  ///
  /// Returns `true` when the updater has a fully or partially downloaded update that can
  /// be applied by calling [apply]. Note that applying a partially downloaded update will
  /// remove any old content that was not updated and may restrict offline availability.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` if the update can be applied, otherwise `false`.
  bool get canApply {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentUpdater',
      'canApply',
    );

    return resultString['result'];
  }

  /// Applies the content update.
  ///
  /// Attempts to atomically replace the current local content with the downloaded update.
  /// If the updater is in a ready state ([ContentUpdaterStatus.fullyReady] or [ContentUpdaterStatus.partiallyReady])
  /// and [canApply] is `true`, this call will perform the swap. For partially ready updates any content that
  /// was not downloaded will be removed when the update is applied.
  ///
  /// ## Returns
  ///
  /// - [GemError.success]: Update applied successfully.
  /// - [GemError.upToDate]: No changes were required; local content is already up-to-date.
  /// - [GemError.invalidated]: The update operation has not been started or was invalidated.
  /// - [GemError.io]: A filesystem error occurred while applying the update.
  GemError apply() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentUpdater',
      'apply',
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Cancels the content update operation.
  void cancel() {
    objectMethod(pointerId, 'ContentUpdater', 'cancel');
  }

  /// Checks if the content updater has started.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` if the update process has been started, otherwise `false`.
  bool get isStarted {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentUpdater',
      'isStarted',
    );

    return resultString['result'];
  }
}
