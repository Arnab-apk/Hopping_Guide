// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:flutter/services.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/contentstore/content_store_enums.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/map/map_details.dart';
import 'package:meta/meta.dart';

/// A single downloadable content product managed by the [ContentStore].
///
/// This class models one content product (for example: a map/region, style, or voice pack).
/// Do not construct instances directly; obtain items from the public [ContentStore] API.
///
/// The object exposes identification and localized display text, content type and language,
/// size and downloaded-size metrics, availability/status and progress indicators, preview imagery,
/// additional content-specific parameters and update metadata (version and update size).
///
/// Use this object to start/pause/cancel downloads, query state, access previews and delete local content.
///
/// {@category Content}
class ContentStoreItem extends GemAutoreleaseObject {
  // ignore: unused_element
  ContentStoreItem._() : super(-1);

  @internal
  ContentStoreItem.init(super.id);

  /// Get the name of the associated product.
  ///
  /// The name is automatically translated based on [SdkSettings.language].
  ///
  /// ## Returns
  ///
  /// - The localized name of the product.
  String get name {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getName',
    );

    return resultString['result'];
  }

  /// Get the unique id of the item in the content store.
  ///
  /// ## Returns
  ///
  /// - The content store item id.
  int get id {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getId',
    );

    return resultString['result'];
  }

  /// Get the product chapter name translated to interface language.
  ///
  /// Relevant for [ContentType.roadMap] items, where large countries are split in multiple
  /// downloadable pieces. All items from the same chapter share the same chapter name. The
  /// value is empty when the item is not a road map item or when the country is not split.
  ///
  /// ## Returns
  ///
  /// - The chapter name of the product, or an empty string when not applicable.
  String get chapterName {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getChapterName',
    );

    return resultString['result'];
  }

  /// Get the country code (ISO 3166-1 alpha-3) list of the product as text.
  ///
  /// The list is empty for non-road-map products.
  ///
  /// ## Returns
  ///
  /// - A list of ISO 3166-1 alpha-3 country codes, or an empty list when not applicable.
  ///
  /// ## Also see:
  ///
  /// - [ISOCodeConversions] - Convert country ISO codes between different formats.
  /// - [MapDetails] - Access country flag images and other map details.
  List<String> get countryCodes {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getCountryCodes',
    );
    return resultString['result'].cast<String>();
  }

  /// Get the language of the product.
  ///
  /// The returned [Language] may be null if the product has no associated language.
  ///
  /// ## Returns
  ///
  /// - A [Language] describing the product language or `null` when no language is associated.
  Language? get language {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getLanguage',
    );

    final Language result = Language.fromJson(resultString['result']);
    if (result.name.isEmpty) {
      return null;
    }
    return result;
  }

  /// Get the content type of the product.
  ///
  /// ## Returns
  ///
  /// - The [ContentType] of the product.
  ContentType get type {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getType',
    );

    return ContentTypeExtension.fromId(resultString['result']);
  }

  /// Get the full path to the local content data file when available.
  ///
  /// Not downloaded content returns an empty string.
  ///
  /// ## Returns
  ///
  /// - The full path to the content data file if the item is available on the device, or an
  ///   empty string otherwise.
  String get fileName {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getFileName',
    );

    return resultString['result'];
  }

  /// The locally installed [Version] of the content.
  ///
  /// Requires that the content is available locally (available size > 0).
  ///
  /// ## Returns
  ///
  /// - The local [Version]. Check [Version.isValid] to determine whether a valid version
  ///   is present.
  Version get clientVersion {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getClientVersion',
    );

    return Version.fromJson(resultString['result']);
  }

  /// The total size of the content in bytes.
  ///
  /// ## Returns
  ///
  /// - The total size in bytes. Returns `0` when the content is not available.
  ///
  /// ## Also see:
  ///
  /// - [availableSize] - The size currently downloaded on the client.
  int get totalSize {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getTotalSize',
    );

    return resultString['result'];
  }

  /// The size in bytes currently available (downloaded) on the client.
  ///
  /// ## Returns
  ///
  /// - The available size in bytes. May differ from [totalSize].
  ///
  /// ## Also see:
  ///
  /// - [totalSize] - The total size of the content.
  int get availableSize {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getAvailableSize',
    );

    return resultString['result'];
  }

  /// Whether the content item is fully downloaded.
  ///
  /// ## Returns
  ///
  /// - `true` when the download is complete, otherwise `false`.
  bool get isCompleted {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'isCompleted',
    );

    return resultString['result'];
  }

  /// Current status of the content item.
  ///
  /// ## Returns
  ///
  /// - A [ContentStoreItemStatus] value describing the current state.
  ContentStoreItemStatus get status {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getStatus',
    );

    return ContentStoreItemStatusExtension.fromId(resultString['result']);
  }

  /// Pause a running or previously started download.
  ///
  /// Calling this method asks the underlying service to suspend an in-progress download.
  /// When the pause request completes the original download `onComplete` callback (the one passed to
  /// [asyncDownload]) will be invoked with a [GemError.suspended] result to indicate the download
  /// stopped due to suspension.
  ///
  /// While a pause is being processed you should avoid performing other operations on
  /// the same [ContentStoreItem] instance. Use the [onComplete] callback to detect
  /// when it is safe to proceed.
  ///
  /// Use [asyncDownload] to start or resume downloads after a pause.
  ///
  /// ## Parameters
  ///
  /// - [onComplete]: optional callback invoked when the pause request finishes. The callback
  ///   receives a single [GemError] argument. On success it will be [GemError.success].
  ///
  /// ## Returns
  ///
  /// - A [GemError] indicating immediate result of the pause request. See [GemError] values for
  ///   possible outcomes.
  ///
  /// ## Also see:
  ///
  /// - [asyncDownload] - Start or resume downloads.
  GemError pauseDownload({void Function(GemError)? onComplete}) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'pauseDownload',
    );

    final GemError err = GemErrorExtension.fromCode(resultString['result']);

    if (err == GemError.success && onComplete != null) {
      _tryNotifyComplete(onComplete: onComplete);
    }

    if (err != GemError.success) {
      onComplete?.call(err);
    }

    return err;
  }

  Future<void> _tryNotifyComplete({
    void Function(GemError)? onComplete,
    Duration duration = const Duration(milliseconds: 2000),
  }) async {
    const Duration step = Duration(milliseconds: 50);

    if (status == ContentStoreItemStatus.paused || duration <= step) {
      final GemError result = status == ContentStoreItemStatus.paused
          ? GemError.success
          : GemError.general;
      onComplete?.call(result);
    } else {
      await Future<void>.delayed(step, () {});
      _tryNotifyComplete(onComplete: onComplete, duration: duration - step);
    }
  }

  /// Cancel an ongoing download and remove any partially downloaded data.
  ///
  /// The cancellation is executed immediately. Any temporary or partially downloaded files
  /// associated with this content item are removed. No `onComplete` notifications are triggered
  /// for this operation.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success; otherwise see [GemError] for other returned values.
  GemError cancelDownload() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'cancelDownload',
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Replace the current progress listener for this item.
  ///
  /// This method allows the change of the progress listener callback provided to the
  /// [asyncDownload] method. The returned [ProgressListener] forwards progress and completion events into provided callbacks.
  ///
  /// ## Parameters
  ///
  /// - [onComplete]: callback invoked when the operation finishes. Receives a single
  ///   [GemError] argument.
  /// - [onProgress]: optional callback invoked with a single `int` progress value (0..100).
  ///
  /// ## Returns
  ///
  /// - The new [ProgressListener] instance.
  ProgressListener? setProgressListener(
    final void Function(GemError err) onComplete,
    final void Function(int progress)? onProgress,
  ) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();

    objectMethod(
      pointerId,
      'ContentStoreItem',
      'setProgressListener',
      args: progListener.id,
    );

    if (onProgress != null) {
      progListener.registerOnProgress((final int p0) {
        onProgress.call(p0);
      });
    }

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      if (err == 0) {
        onComplete(GemErrorExtension.fromCode(0));
      } else {
        onComplete(GemErrorExtension.fromCode(err));
      }
    });
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);

    return progListener;
  }

  /// Returns the currently registered progress listener for this item, if any.
  ///
  /// ## Returns
  ///
  /// - The [ProgressListener] previously installed with [setProgressListener] or [asyncDownload],
  /// or `null` if no listener is registered.
  ///
  /// ## Also see:
  ///
  /// - [setProgressListener] - Install or replace the progress listener.
  ProgressListener? get progressListener {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getProgressListener',
    );

    if (resultString['result'] == -1) {
      return null;
    }

    final EventHandler? foundHandler = GemKitPlatform.instance.getEventHandler(
      resultString['result'],
    );
    if (foundHandler == null || foundHandler is! EventDrivenProgressListener) {
      return null;
    }

    return foundHandler;
  }

  /// Current download progress for this item.
  ///
  /// Can also be obtained from a registered callbacks to [asyncDownload] and
  /// [setProgressListener] methods.
  ///
  /// ## Returns
  ///
  /// - An `int` progress value in the range 0..100 representing download completion.
  ///
  /// ## Also see:
  ///
  /// - [status] - Current status of the content item.
  int get downloadProgress {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getDownloadProgress',
    );

    return resultString['result'];
  }

  /// Whether the local content associated with this item can be deleted.
  ///
  /// Content may be deleted if there is local data (partial or complete) and the item is not
  /// flagged as an SDK resource.
  ///
  /// ## Returns
  ///
  /// - `true` when deletion is allowed, otherwise `false`.
  bool get canDeleteContent {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'canDeleteContent',
    );

    return resultString['result'];
  }

  /// Delete the local content data for this item.
  ///
  /// The operation is executed immediately and does not emit notifications. The return value
  /// indicates the outcome and possible failure reasons.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success
  /// - [GemError.accessDenied] if the content is an SDK resource and cannot be removed
  /// - [GemError.notFound] if the content item does not exist on the device
  /// - [GemError.inUse] if the item is currently in use and cannot be deleted
  GemError deleteContent() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'deleteContent',
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Whether a preview image for this content item is available on the client.
  ///
  /// ## Returns
  ///
  /// - `true` when a preview image exists locally, otherwise `false`.
  bool get isImagePreviewAvailable {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'isImagePreviewAvailable',
    );

    return resultString['result'];
  }

  /// Retrieve the raw preview bytes for this item if available.
  ///
  /// This call returns the preview image as a `Uint8List`. Use [isImagePreviewAvailable] to
  /// check for availability before calling.
  ///
  /// ## Parameters
  ///
  /// - [size] — optional target size for the returned image.
  /// - [format] — optional [ImageFileFormat] describing the requested encoding.
  ///
  /// ## Returns
  ///
  /// - The preview image bytes as `Uint8List`, or `null` when no preview is present.
  Uint8List? getImagePreview({
    final Size? size,
    final ImageFileFormat? format,
  }) {
    return GemKitPlatform.instance.callGetImage(
      pointerId,
      'ContentStoreItemGetImagePreview',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
    );
  }

  /// Get the image as a [Img].
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getImagePreview] when you only need raw image bytes.
  ///
  /// ## Returns
  ///
  /// - The item `Img`. The caller is responsible for checking whether the image is valid.
  Img get imgPreview {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getImgPreview',
    );

    return Img.init(resultString['result']);
  }

  /// Additional content-specific parameters if present.
  ///
  /// Only a subset of content types include extra parameters (road maps, human voice packs and
  /// certain style packages). The returned object is a concrete subtype of [ContentParameters].
  ///
  /// The actual runtime type can be one of:
  ///
  /// - [RoadMapParameters] for [ContentType.roadMap]
  /// - [VoiceParameters] for [ContentType.humanVoice]
  /// - [StyleParameters] for [ContentType.viewStyleHighRes] or [ContentType.viewStyleLowRes]s
  ///
  /// ## Returns
  ///
  /// - A [ContentParameters] instance for available parameters, or `null` when none are present.
  ContentParameters? get contentParameters {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getContentParameters',
    );

    if (resultString['gemApiError'] != 0) {
      return null;
    }

    final List<GemParameter> params = SearchableParameterList.init(
      resultString['result'],
    ).toList();

    final Set<String> keys = <String>{
      for (final GemParameter p in params)
        if (p.key != null && p.key!.isNotEmpty) p.key!,
    };

    if (keys.contains('Copyright')) {
      return RoadMapParameters.fromParameters(params);
    }
    if (keys.contains('native_language')) {
      return VoiceParameters.fromParameters(params);
    }
    if (keys.contains('Background-Color')) {
      return StyleParameters.fromParameters(params);
    }
    return null;
  }

  /// Typed accessor for [contentParameters] that avoids explicit casts.
  ///
  /// ## Returns
  ///
  /// - The underlying parameters object only if it is of type `T`, otherwise `null`.
  T? getContentParametersAs<T extends ContentParameters>() {
    final ContentParameters? cp = contentParameters;
    if (cp is T) {
      return cp;
    }
    return null;
  }

  /// Return the [ContentStoreItem] that represents an in-progress update for this item.
  ///
  /// ## Returns
  ///
  /// - The update [ContentStoreItem] when an update is in progress, or `null` otherwise.
  ///
  /// ## Also see:
  ///
  /// - [isUpdatable] - Whether an update is available for this item.
  /// - [ContentUpdater] - Manage content updates in the content store.
  ContentStoreItem? get updateItem {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getUpdateItem',
    );

    final int id = resultString['result'];
    if (id == -1) {
      return null;
    }
    return ContentStoreItem.init(id);
  }

  /// Whether a newer version of this item is available in the content store.
  ///
  /// ## Returns
  ///
  /// - `true` when an update is available, otherwise `false`.
  ///
  /// ## Also see:
  ///
  /// - [updateItem] - The content store item representing the available update.
  /// - [ContentUpdater] - Manage content updates in the content store.
  bool get isUpdatable {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'isUpdatable',
    );

    return resultString['result'];
  }

  /// The size in bytes of an available update for this item.
  ///
  /// Note: querying this does not trigger the update; it only reports the size if an update
  /// is available.
  ///
  /// ## Returns
  ///
  /// - The update size in bytes, or `0` when no update is available.
  int get updateSize {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getUpdateSize',
    );

    return resultString['result'];
  }

  /// The [Version] object describing an available update for this item.
  ///
  /// ## Returns
  ///
  /// - A [Version] when an update exists, otherwise a [Version] where [Version.isValid] is false.
  Version get updateVersion {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'getUpdateVersion',
    );

    return Version.fromJson(resultString['result']);
  }

  /// Start or resume an asynchronous download of the content product.
  ///
  /// The method creates and registers a [ProgressListener] which will receive progress and
  /// completion events. The caller must provide a mandatory [onComplete] callback to receive the
  /// final outcome. When the operation finishes the listener's completion callback and the
  /// supplied [onComplete] are invoked with a [GemError] indicating success or the failure reason.
  ///
  /// The callback can be changed later using [setProgressListener] or retrieved via the
  /// [progressListener] property.
  ///
  /// ## Parameters
  ///
  /// - [onComplete]: Required callback invoked when the download completes. The function is
  ///   called with:
  ///   - `err` — a [GemError] describing the final result. It is called with [GemError.success] on
  ///   success, or another [GemError] value on failure.
  /// - [onProgress]: Optional callback invoked periodically with a single `int` argument (0..100)
  ///   representing the current download progress.
  /// - [allowChargedNetworks]: When `true`, charged networks are allowed for this download. This
  ///   overrides the global setting configured via [SdkSettings.setAllowOffboardServiceOnExtraChargedNetwork]
  ///   for the [ServiceGroupType.contentService] group.
  /// - [savePolicy]: A [DataSavePolicy] value selecting where downloaded data will be stored.
  /// - [priority]: A [ContentDownloadThreadPriority] hint for downloader thread scheduling.
  ///
  /// ## Returns
  ///
  /// - A `ProgressListener` instance associated with the download. The listener reports progress
  ///   updates and completion. If the operation cannot be started an error is reported via the
  ///   [onComplete] callback and a placeholder listener is returned.
  ///
  /// ## Example
  ///
  /// The following example starts a download and logs progress and completion:
  ///
  /// ```dart
  /// item.asyncDownload((GemError err) {
  ///   if (err == GemError.success) {
  ///     print('Download finished successfully');
  ///   } else {
  ///     print('Download failed: $err');
  ///   }
  /// }, onProgress: (int p) {
  ///   print('Download progress: $p%');
  /// });
  /// ```
  ///
  /// ## Also see:
  ///
  /// - [pauseDownload] - Pause an ongoing download.
  /// - [cancelDownload] - Cancel an ongoing download.
  /// - [setProgressListener] - Change the progress listener callbacks.
  /// - [progressListener] - Access the current progress listener.
  ProgressListener asyncDownload(
    final void Function(GemError err) onComplete, {
    final void Function(int progress)? onProgress,
    final bool allowChargedNetworks = false,
    final DataSavePolicy savePolicy = DataSavePolicy.useDefault,
    final ContentDownloadThreadPriority priority =
        ContentDownloadThreadPriority.defaultPriority,
  }) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    final OperationResult resultString = objectMethod(
      pointerId,
      'ContentStoreItem',
      'asyncDownload',
      args: <String, dynamic>{
        'listener': progListener.id,
        'allowChargedNetworks': allowChargedNetworks,
        'savePolicy': savePolicy.id,
        'priority': priority.id,
      },
    );

    final GemError errorCode = GemErrorExtension.fromCode(
      resultString['result'],
    );

    if (errorCode != GemError.success) {
      onComplete(errorCode);
      return EventDrivenProgressListener.init(0);
    }

    if (onProgress != null) {
      progListener.registerOnProgress((final int p0) {
        onProgress.call(p0);
      });
    }

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      if (err == 0) {
        onComplete(GemErrorExtension.fromCode(0));
      } else {
        onComplete(GemErrorExtension.fromCode(err));
      }
    });
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);
    return progListener;
  }
}
