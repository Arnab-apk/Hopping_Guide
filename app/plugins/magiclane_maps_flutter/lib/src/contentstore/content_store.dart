// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/contentstore/content_store_enums.dart';
import 'package:magiclane_maps_flutter/src/contentstore/content_store_item.dart';
import 'package:magiclane_maps_flutter/src/contentstore/content_updater.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Access and manage downloadable content provided by the content store.
///
/// Use this service to discover, query and manage downloadable content such as map regions,
/// style packages and voice packs represented as [ContentStoreItem] objects.
/// The API exposes methods to list local content, request online catalogues, start downloads
/// and control concurrent download behavior.
///
/// For content update workflows use the [ContentUpdater] available through [createContentUpdater]
///
/// {@category Content}
abstract class ContentStore {
  ContentStore._();

  /// Return the list of content items downloaded on the device for the specified type.
  ///
  /// ## Parameters
  ///
  /// - [type]: The [ContentType] to query (for example [ContentType.roadMap]).
  ///
  /// ## Returns
  ///
  /// - A list of [ContentStoreItem] objects representing local (completed or downloading)
  ///   content for the given type.
  ///
  /// ## See also:
  ///
  /// - [asyncGetStoreContentList] - Request the online content list for a specific type.
  static List<ContentStoreItem> getLocalContentList(final ContentType type) {
    final OperationResult resultString = staticMethod(
      'ContentStore',
      'getLocalContentList',
      args: type.id,
    );

    return ContentStoreItemList.init(resultString['result']).toList();
  }

  /// Return the last cached online store content list for the requested type.
  ///
  /// The returned tuple contains the cached content list and a boolean flag that indicates
  /// whether the list was cached locally. When the flag is `false` the caller should use
  /// [asyncGetStoreContentList] to request a fresh list from the server.
  ///
  /// ## Parameters
  ///
  /// - [type]: The [ContentType] to query.
  ///
  /// ## Returns
  ///
  /// - A tuple `(List<ContentStoreItem>, bool)` where the first element is the cached
  ///   list and the second element is `isCached`.
  ///
  /// ## See also:
  ///
  /// - [asyncGetStoreContentList] - Request the online content list for a specific type.
  static (List<ContentStoreItem>, bool) getStoreContentList(
    final ContentType type,
  ) {
    final OperationResult contentStoreListString = staticMethod(
      'ContentStore',
      'getStoreContentList',
      args: type.id,
    );

    final int listId = contentStoreListString['result']['contentStoreListId'];
    final bool isCached = contentStoreListString['result']['isCached'];
    return (ContentStoreItemList.init(listId).toList(), isCached);
  }

  /// Return the last filtered list requested by [asyncGetStoreFilteredList].
  ///
  /// The filtered list is kept in memory after the last successful call to
  /// [asyncGetStoreFilteredList] and can be retrieved synchronously using this method.
  ///
  /// ## Returns
  ///
  /// - A list of [ContentStoreItem] objects matching the last applied filters, or an empty
  ///   list when no filtered list is available.
  ///
  /// ## See also:
  ///
  /// - [asyncGetStoreFilteredList] - Search the online store content using filters.
  @Deprecated('Use the storeFilteredList getter instead.')
  static List<ContentStoreItem> getStoreFilteredList() {
    final OperationResult contentStoreListString = staticMethod(
      'ContentStore',
      'getStoreFilteredList',
    );

    final int listId = contentStoreListString['result'];
    return ContentStoreItemList.init(listId).toList();
  }

  /// Return the last filtered list requested by [asyncGetStoreFilteredList].
  ///
  /// The filtered list is kept in memory after the last successful call to
  /// [asyncGetStoreFilteredList] and can be retrieved synchronously using this method.
  ///
  /// ## Returns
  ///
  /// - A list of [ContentStoreItem] objects matching the last applied filters, or an empty
  ///   list when no filtered list is available.
  ///
  /// ## See also:
  ///
  /// - [asyncGetStoreFilteredList] - Search the online store content using filters.
  static List<ContentStoreItem> get storeFilteredList {
    final OperationResult contentStoreListString = staticMethod(
      'ContentStore',
      'getStoreFilteredList',
    );

    final int listId = contentStoreListString['result'];
    return ContentStoreItemList.init(listId).toList();
  }

  /// Asynchronously search the online store content using optional filters.
  ///
  /// Use this method to request a filtered catalogue from the server. Filters include
  /// the content [type], an optional list of ISO 3166-1 alpha-3 [countries] and an optional
  /// geographic [area]. Results are delivered via the provided completion callback.
  ///
  /// ## Parameters
  ///
  /// - [type]: Required [ContentType] to search for (for example [ContentType.roadMap]).
  /// - [countries]: Optional list of ISO 3166-1 alpha-3 country codes to restrict the search.
  /// - [area]: Optional [GeographicArea] (for example [RectangleGeographicArea]) to restrict
  ///   the search geographically. Pass `null` to search the whole world.
  /// - [onComplete]: Optional callback invoked when the operation finishes. The function is
  ///   called with:
  ///   - `err` — a [GemError] indicating the outcome. Possible values and behaviors include:
  ///     - [GemError.success] — success; the `result` list may be empty for incompatible or
  ///       invalid country codes.
  ///     - [GemError.noMemory] — insufficient memory; result list will be empty.
  ///     - [GemError.invalidInput] — invalid `area` (for example an empty TilesCollectionGeographicArea);
  ///       result list will be empty.
  ///     - [GemError.general] — network or HTTP failure; result list will be empty.
  ///   - `result` — a [List<ContentStoreItem>] when `err` is [GemError.success], otherwise `null`.
  ///
  /// ## Returns
  ///
  /// - A [ProgressListener] used to monitor or cancel the operation if the request was
  ///   successfully started, otherwise `null`.
  ///
  /// ## See also:
  ///
  /// - [asyncGetStoreContentList] - Request the online content list for a specific type.
  static ProgressListener? asyncGetStoreFilteredList({
    required ContentType type,
    List<String>? countries,
    GeographicArea? area,
    void Function(GemError err, List<ContentStoreItem> items)? onComplete,
  }) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    final OperationResult resultString = staticMethod(
      'ContentStore',
      'asyncGetStoreFilteredList',
      args: <String, dynamic>{
        'type': type.id,
        'countries': countries ?? <String>[],
        'area':
            area ??
            RectangleGeographicArea(
              topLeft: Coordinates(),
              bottomRight: Coordinates(),
            ),
        'listener': progListener.id,
      },
    );

    if (resultString.containsKey('gemApiError')) {
      final int errorCode = resultString['gemApiError'] as int;
      final GemError error = GemErrorExtension.fromCode(errorCode);
      if (error != GemError.success) {
        onComplete?.call(error, <ContentStoreItem>[]);
        return null;
      }
    }

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      if (err == 0) {
        final OperationResult contentStoreListString = staticMethod(
          'ContentStore',
          'getStoreFilteredList',
        );
        final int listId = contentStoreListString['result'];

        onComplete?.call(
          GemErrorExtension.fromCode(0),
          ContentStoreItemList.init(listId).toList(),
        );
      } else {
        onComplete?.call(GemErrorExtension.fromCode(err), <ContentStoreItem>[]);
      }
    });
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);
    return progListener;
  }

  /// Asynchronously request the online store content list for a specific content type.
  ///
  /// Call this method when an active internet connection is available and the offline
  /// data on the device is not expired. Results are delivered through the provided
  /// completion callback.
  ///
  /// ## Parameters
  ///
  /// - [type]: The [ContentType] to request (for example [ContentType.roadMap] or
  ///   [ContentType.viewStyleHighRes]).
  /// - [onComplete]: Required callback invoked when the operation completes. The function is
  ///   called with:
  ///   - `err` — a [GemError] indicating the operation result (for example `GemError.success`,
  ///     `GemError.noConnection`, etc.).
  ///   - `items` — a `List<ContentStoreItem>` containing the retrieved items when `err` is
  ///     `GemError.success`, or an empty list on error.
  ///   - `isCached` — `true` when the returned list was retrieved from a local cache, otherwise
  ///     `false`.
  ///
  /// ## Returns
  ///
  /// - A [ProgressListener] to monitor or cancel the request if it started successfully, or
  ///   `null` when the request could not be started (for example when offline and no cached data is valid).
  ///
  /// ## See also:
  ///
  /// - [getStoreContentList] - Synchronously retrieve the last cached online content list.
  static ProgressListener? asyncGetStoreContentList(
    final ContentType type,
    final void Function(
      GemError err,
      List<ContentStoreItem> items,
      bool isCached,
    )
    onComplete,
  ) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    final OperationResult resultString = staticMethod(
      'ContentStore',
      'asyncGetStoreContentList',
      args: <String, dynamic>{'type': type.id, 'listener': progListener.id},
    );

    if (resultString.containsKey('gemApiError')) {
      final int errorCode = resultString['gemApiError'] as int;
      final GemError error = GemErrorExtension.fromCode(errorCode);
      if (error != GemError.success) {
        onComplete(error, <ContentStoreItem>[], false);
        return null;
      }
    }

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      if (err == 0) {
        final OperationResult contentStoreListString = staticMethod(
          'ContentStore',
          'getStoreContentList',
          args: type.id,
        );
        final int listId =
            contentStoreListString['result']['contentStoreListId'];
        final bool isCached = contentStoreListString['result']['isCached'];
        onComplete(
          GemErrorExtension.fromCode(0),
          ContentStoreItemList.init(listId).toList(),
          isCached,
        );
      } else {
        onComplete(
          GemErrorExtension.fromCode(err),
          <ContentStoreItem>[],
          false,
        );
      }
    });
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);
    return progListener;
  }

  /// Cancel an asynchronous content operation previously started with a returned listener.
  ///
  /// ## Parameters
  ///
  /// - [listener]: The [ProgressListener] instance returned by the operation to cancel.
  static void cancel(final ProgressListener listener) {
    staticMethod('ContentStore', 'cancel', args: listener.id);
  }

  /// Create a [ContentUpdater] for the specified content type.
  ///
  /// The created updater must be started with [ContentUpdater.update]. Updaters support
  /// resume across SDK sessions: to detect a pending update create an updater and inspect
  /// its [ContentUpdater.status]. If the status is not [ContentUpdaterStatus.idle] a
  /// pending update can be resumed.
  ///
  /// ## Parameters
  ///
  /// - [type]: The [ContentType] for which to create an updater.
  ///
  /// ## Returns
  ///
  /// - A tuple `(ContentUpdater, GemError)` where the first element is the created updater
  ///   and the second is a [GemError] indicating success or failure (for example
  ///   [GemError.exist] when an updater already exists).
  static (ContentUpdater, GemError) createContentUpdater(
    final ContentType type,
  ) {
    final OperationResult resultString = staticMethod(
      'ContentStore',
      'createContentUpdater',
      args: type.id,
    );

    final dynamic result = resultString['result'];
    return (
      ContentUpdater.init(result['first'], 0),
      GemErrorExtension.fromCode(result['second']),
    );
  }

  /// Check for available updates for the specified content type.
  ///
  /// On success the result is published via the appropriate [OffBoardListener] callbacks:
  /// [OffBoardListener.registerOnWorldwideRoadMapVersionUpdated] for [ContentType.roadMap], or
  /// [OffBoardListener.registerOnAvailableContentUpdate] for other types.
  ///
  /// ## Parameters
  ///
  /// - [type]: The [ContentType] to check.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] when the check was initiated successfully.
  /// - [GemError.connectionRequired] when there is no internet connection.
  ///
  /// ## See also:
  ///
  /// - [OffBoardListener.registerOnWorldwideRoadMapVersionUpdated] - Register for worldwide road map version updates.
  /// - [OffBoardListener.registerOnAvailableContentUpdate] - Register for available content updates.
  /// - [createContentUpdater] - Create a content updater for a specific content type.
  static GemError checkForUpdate(final ContentType type) {
    final OperationResult resultString = staticMethod(
      'ContentStore',
      'checkForUpdate',
      args: type.id,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Retrieve the [ContentStoreItem] with the specified id, if it exists.
  ///
  /// ## Parameters
  ///
  /// - [id]: The content item id (see [ContentStoreItem.id]).
  ///
  /// ## Returns
  ///
  /// - The [ContentStoreItem] when found, or `null` if no item with the given id exists.
  ///
  /// ## Also see:
  ///
  /// - [ContentStoreItem.id] - The unique identifier of a content store item.
  static ContentStoreItem? getItemById(final int id) {
    final OperationResult resultString = staticMethod(
      'ContentStore',
      'getItemById',
      args: id,
    );

    final int resultId = resultString['result'];
    if (resultId == -1) {
      return null;
    }
    return ContentStoreItem.init(resultId);
  }

  /// Refresh the local content store state by loading external changes from disk.
  ///
  /// May be unstable and is not recommended for general use.
  ///
  /// Call this after manually adding or modifying content assets so that subsequent
  /// calls to [getLocalContentList] return up-to-date information.
  static void refresh() {
    staticMethod('ContentStore', 'refreshContentStore');
  }

  /// Configure the maximum number of parallel downloads performed by the SDK.
  ///
  /// The default value is `3`.
  ///
  /// ## Parameters
  ///
  /// - [count]: The maximum number of concurrent downloads.
  static void setParallelDownloadsLimit(final int count) {
    staticMethod('ContentStore', 'setParallelDownloadsLimit', args: count);
  }

  /// Transfer statistics for content downloads/uploads.
  ///
  /// Returns a [TransferStatistics] object containing counters and metrics
  /// about network usage performed by the traffic service. This information
  /// can be used for diagnostics or to display usage to end users.
  ///
  /// ## Returns
  ///
  /// - A [TransferStatistics] instance containing cumulative transfer counters and metrics.
  static TransferStatistics get transferStatistics {
    final OperationResult resultString = staticMethod(
      'ContentStore',
      'getTransferStatistics',
    );

    return TransferStatistics.init(resultString['result']);
  }
}
