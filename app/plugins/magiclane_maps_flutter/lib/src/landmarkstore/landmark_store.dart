// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:typed_data';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/landmark_store.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Provides access to a persistent collection of landmarks and categories.
///
/// A [LandmarkStore] represents a single persisted store (backed by a local database) that contains
/// landmarks and their categories. Use [LandmarkStoreService] factory methods to create or obtain
/// instances. Landmark stores support reading, adding, updating and removing landmarks and categories,
/// importing external datasets, and creating browse sessions for paged access.
///
/// Typical uses:
/// - Persisting user-created landmarks between sessions.
/// - Displaying a set of landmarks on the map via [LandmarkStoreCollection].
/// - Customizing search and alarm behavior by selecting stores and categories.
///
/// ## See also:
///
/// - [LandmarkStoreService] — create, lookup and remove landmark stores.
/// - [LandmarkStoreCollection] — control which stores and categories are visible on the map.
/// - [LandmarkBrowseSession] — browse a large store in pages.
///
/// {@category Landmark Store}
class LandmarkStore extends GemAutoreleaseObject {
  // ignore: unused_element
  LandmarkStore._() : _mapId = -1, super(-1);

  @internal
  LandmarkStore.init(super.id, final int mapId) : _mapId = mapId;
  final int _mapId;

  /// ID used to mark landmarks as uncategorized.
  ///
  /// Use this constant when assigning or querying landmarks that do not belong to any category.
  static const int uncategorizedLandmarkCategId = -1;

  /// Sentinel value that indicates an invalid category identifier.
  ///
  /// Some APIs accept `invalidLandmarkCategId` to request results across all categories.
  static const int invalidLandmarkCategId = -2;
  int get mapId => _mapId;

  /// Adds a new category to this landmark store.
  ///
  /// After a successful call the provided [category] becomes part of this store and should
  /// be used to group landmarks within this store.
  ///
  /// ## Parameters
  ///
  /// - [category]: The [LandmarkCategory] instance to add. The category must have a non-empty name.
  void addCategory(final LandmarkCategory category) {
    objectMethod(
      pointerId,
      'LandmarkStore',
      'addCategory',
      args: category.pointerId,
    );
  }

  /// Adds a landmark copy to this store under the specified category.
  ///
  /// If the landmark already exists in the store its category membership will be updated.
  ///
  /// ## Parameters
  ///
  /// - [landmark]: The [Landmark] to add (a copy is stored).
  /// - [categoryId]: The category id where the landmark will be stored. Defaults to
  ///   [uncategorizedLandmarkCategId].
  void addLandmark(
    final Landmark landmark, {
    final int categoryId = LandmarkStore.uncategorizedLandmarkCategId,
  }) {
    objectMethod(
      pointerId,
      'LandmarkStore',
      'addLandmark',
      args: <String, dynamic>{
        'landmark': landmark.pointerId,
        'categoryId': categoryId,
      },
    );
  }

  /// Retrieves a landmark by its id from this store.
  ///
  /// ## Parameters
  ///
  /// - [landmarkId]: The numeric id of the landmark to retrieve.
  ///
  /// ## Returns
  ///
  /// - [Landmark?]: The landmark instance when found, otherwise `null`.
  Landmark? getLandmark(final int landmarkId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'getLandmark',
      args: landmarkId,
    );

    if (resultString['gemApiError'] == -11) {
      return null;
    }

    return Landmark.init(resultString['result']);
  }

  /// Updates the persisted data for an existing landmark in this store.
  ///
  /// This call does not change the category assignments of the landmark. The provided
  /// [landmark] instance must belong to this store. The store will update the landmark's
  /// timestamp to reflect the modification.
  ///
  /// ## Parameters
  ///
  /// - [landmark]: The [Landmark] instance containing updated values.
  void updateLandmark(final Landmark landmark) {
    objectMethod(
      pointerId,
      'LandmarkStore',
      'updateLandmark',
      args: landmark.pointerId,
    );
  }

  /// Returns true when the store contains a landmark with [landmarkId].
  ///
  /// ## Parameters
  ///
  /// - [landmarkId]: The numeric id to check.
  ///
  /// ## Returns
  ///
  /// - [bool]: `true` when present, otherwise `false`.
  bool containsLandmark(final int landmarkId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'containsLandmark',
      args: landmarkId,
    );

    return resultString['result'];
  }

  /// Returns all categories defined in this landmark store.
  ///
  /// ## Returns
  ///
  /// - [List<LandmarkCategory>]: The store's categories.
  List<LandmarkCategory> get categories {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'getCategories',
    );

    return LandmarkCategoryList.init(resultString['result']).toList();
  }

  /// Returns categories assigned to a specific landmark in this store.
  ///
  /// ## Parameters
  ///
  /// - [landmarkId]: The id of the landmark to inspect.
  ///
  /// ## Returns
  ///
  /// - [List<LandmarkCategory>]: Categories for the provided landmark id.
  List<LandmarkCategory> getCategoriesFromLandmark(int landmarkId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'getCategoriesFromLandmark',
      args: landmarkId,
    );

    return LandmarkCategoryList.init(resultString['result']).toList();
  }

  /// Retrieves a specific category by its id from this store.
  ///
  /// ## Parameters
  ///
  /// - [categoryId]: The numeric category id.
  ///
  /// ## Returns
  ///
  /// - [LandmarkCategory?]: The category when found, otherwise `null`.
  LandmarkCategory? getCategoryById(final int categoryId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'getCategoryById',
      args: categoryId,
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return LandmarkCategory.init(resultString['result']);
  }

  /// Retrieves a specific category by its name from this store.
  ///
  /// The match is exact and case-sensitive. Both built-in POI
  /// categories and user-created custom categories are eligible.
  ///
  /// ## Parameters
  ///
  /// - [name]: The category name to look up.
  ///
  /// ## Returns
  ///
  /// - [LandmarkCategory?]: The category when found, otherwise `null`.
  LandmarkCategory? getCategoryByName(final String name) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'getCategoryByName',
      args: name,
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return LandmarkCategory.init(resultString['result']);
  }

  /// Returns the unique identifier for this landmark store.
  ///
  /// ## Returns
  ///
  /// - [int]: The store id.
  int get id {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'getId',
    );

    return resultString['result'];
  }

  /// Returns landmarks that belong to [categoryId] or all landmarks when [invalidLandmarkCategId] is used.
  ///
  /// ## Parameters
  ///
  /// - [categoryId]: The category id to filter by. Use [uncategorizedLandmarkCategId] to fetch
  ///   uncategorized landmarks or [invalidLandmarkCategId] to fetch all landmarks.
  ///
  /// ## Returns
  ///
  /// - [List<Landmark>]: Landmarks matching the filter.
  List<Landmark> getLandmarks({
    final int categoryId = LandmarkStore.invalidLandmarkCategId,
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'getLandmarks',
      args: categoryId,
    );

    return LandmarkList.init(resultString['result']).toList();
  }

  /// Returns landmarks within a geographic [area], optionally filtered by [categoryId].
  ///
  /// ## Parameters
  ///
  /// - [area]: The geographic area to search inside. If null a default rectangle is used.
  /// - [categoryId]: Optional category filter. Use [uncategorizedLandmarkCategId] for the uncategorized
  ///   landmarks or [invalidLandmarkCategId] to fetch all landmarks.
  ///
  /// ## Returns
  ///
  /// - [List<Landmark>]: Landmarks matching the geographic and category criteria.
  List<Landmark> getLandmarksInArea({
    final GeographicArea? area,
    final int categoryId = LandmarkStore.invalidLandmarkCategId,
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'getLandmarksInArea',
      args: <String, dynamic>{
        'area':
            area ??
            RectangleGeographicArea(
              topLeft: Coordinates(),
              bottomRight: Coordinates(),
            ),
        'categoryId': categoryId,
      },
    );

    return LandmarkList.init(resultString['result']).toList();
  }

  /// Creates a [LandmarkBrowseSession] to iteratively browse landmarks in this store.
  ///
  /// The session captures a snapshot of landmarks available at creation time and supports
  /// paged retrieval and sorting according to [LandmarkBrowseSessionSettings].
  ///
  /// ## Parameters
  ///
  /// - [settings]: Optional settings that control ordering and filtering.
  ///
  /// ## Returns
  ///
  /// - [LandmarkBrowseSession]: A session object for paged access to landmarks.
  LandmarkBrowseSession createLandmarkBrowseSession({
    LandmarkBrowseSessionSettings? settings,
  }) {
    settings ??= LandmarkBrowseSessionSettings();

    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'createLandmarkBrowseSession',
      args: settings,
    );

    return LandmarkBrowseSession.init(resultString['result']);
  }

  /// Returns the persisted name of this landmark store.
  ///
  /// ## Returns
  ///
  /// - [String]: The store name.
  String get name {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'getName',
    );

    return resultString['result'];
  }

  /// Returns the type of this landmark store.
  ///
  /// The type indicates whether the store is a user-owned store, a map-provided store,
  /// or one of several special read-only types (for example map POIs or addresses).
  ///
  /// ## Returns
  ///
  /// - [LandmarkStoreType]: The store type.
  LandmarkStoreType get type {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'getType',
    );

    return LandmarkStoreTypeExtension.fromId(resultString['result']);
  }

  /// Removes a category from this store.
  ///
  /// Optionally also removes landmarks that belong to the removed category; when
  /// [removeLmkContent] is false affected landmarks are marked as uncategorized instead.
  ///
  /// ## Parameters
  ///
  /// - [categoryId]: The id of the category to remove.
  /// - [removeLmkContent]: When true delete landmarks assigned to the category.
  void removeCategory(
    final int categoryId, {
    final bool removeLmkContent = false,
  }) {
    objectMethod(
      pointerId,
      'LandmarkStore',
      'removeCategory',
      args: <String, Object>{
        'categoryId': categoryId,
        'removeLmkContent': removeLmkContent,
      },
    );
  }

  /// Removes a landmark from this store.
  ///
  /// ## Parameters
  ///
  /// - [landmark]: The [Landmark] instance to remove.
  void removeLandmark(final Landmark landmark) {
    objectMethod(
      pointerId,
      'LandmarkStore',
      'removeLandmark',
      args: landmark.pointerId,
    );
  }

  /// Returns the number of landmarks in [categoryId].
  ///
  /// Special values:
  /// - [uncategorizedLandmarkCategId] returns the count of uncategorized landmarks.
  /// - [invalidLandmarkCategId] returns the total count for the store.
  ///
  /// ## Parameters
  ///
  /// - [categoryId]: The category id to count.
  ///
  /// ## Returns
  ///
  /// - [int]: The landmark count.
  int getLandmarkCount({
    int categoryId = LandmarkStore.invalidLandmarkCategId,
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'getLandmarkCount',
      args: categoryId,
    );

    return resultString['result'];
  }

  /// Updates metadata for a category that belongs to this store.
  ///
  /// The provided [category] must already be part of this store; the call updates the
  /// persisted category details.
  ///
  /// ## Parameters
  ///
  /// - [category]: The [LandmarkCategory] with updated values.
  void updateCategory(final LandmarkCategory category) {
    objectMethod(
      pointerId,
      'LandmarkStore',
      'updateCategory',
      args: category.pointerId,
    );
  }

  /// Assigns a category id to a landmark in this store.
  ///
  /// ## Parameters
  ///
  /// - [landmark]: The [Landmark] to update.
  /// - [categoryId]: The category id to set for the landmark.
  void setLandmarkCategory(final Landmark landmark, final int categoryId) {
    objectMethod(
      pointerId,
      'LandmarkStore',
      'setLandmarkCategory',
      args: <String, int>{'first': landmark.pointerId, 'second': categoryId},
    );
  }

  /// Asynchronously imports landmarks into this store from a file path.
  ///
  /// The import supports formats defined by [LandmarkFileFormat] and can attach a map
  /// image to the imported landmarks. A [ProgressListener] is returned to monitor
  /// progress. The [onComplete] callback receives a [GemError] describing final status.
  ///
  /// ## Parameters
  ///
  /// - [filePath]: Path to the file containing landmark data (KML, GeoJSON, etc.).
  /// - [format]: The [LandmarkFileFormat] describing the file contents.
  /// - [image]: An [Img] used as the landmark image for imported items (or default when omitted).
  /// - [onComplete]: Optional callback invoked with a [GemError] when the import finishes. Possible values include:
  ///   - [GemError.success] — import completed successfully.
  ///   - [GemError.inUse] — an import is already in progress.
  ///   - [GemError.notFound] — file could not be opened or category id invalid.
  ///   - [GemError.cancel] — operation was cancelled.
  ///   - [GemError.invalidInput] — provided data could not be parsed.
  /// - [onProgressUpdated]: Optional progress callback (0-100).
  /// - [categoryId]: Optional category id to assign to imported landmarks. Use
  ///   [uncategorizedLandmarkCategId] to import without a category.
  ///
  /// ## Returns
  ///
  /// - [ProgressListener?]: A progress listener if the import started, otherwise null.
  ///
  /// ## See also:
  ///
  /// - [importLandmarksWithDataBuffer] — imports landmarks from a data buffer.
  ProgressListener? importLandmarks({
    required String filePath,
    required LandmarkFileFormat format,
    required Img image,
    final void Function(GemError error)? onComplete,
    final void Function(int progress)? onProgressUpdated,
    int categoryId = uncategorizedLandmarkCategId,
  }) {
    final EventDrivenProgressListener progressListener =
        EventDrivenProgressListener();

    if (onComplete != null) {
      progressListener.registerOnCompleteWithData(
        (final int err, final String hint, final Map<dynamic, dynamic> json) =>
            onComplete(GemErrorExtension.fromCode(err)),
      );
    }

    if (onProgressUpdated != null) {
      progressListener.registerOnProgress(onProgressUpdated);
    }

    GemKitPlatform.instance.registerEventHandler(
      progressListener.id,
      progressListener,
    );

    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'importLandmarks',
      args: <String, dynamic>{
        'path': filePath,
        'fileFormat': format.id,
        'image': image.pointerId,
        'categoryId': categoryId,
        'listener': progressListener.id,
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

  /// Asynchronously imports landmarks into this store from a raw data buffer.
  ///
  /// Use this when landmark data is available directly in memory (for example downloaded
  /// or received over a network). Parameters and completion semantics match [importLandmarks].
  ///
  /// ## Parameters
  ///
  /// - [buffer]: Binary data containing the landmark file content.
  /// - [format]: The [LandmarkFileFormat] of the buffer.
  /// - [image]: An [Img] used as the landmark image for imported items.
  /// - [onComplete]: Optional callback invoked with a [GemError] when the import finishes.
  ///   - Is called with [GemError.success] if the operation suceeded
  ///   - Is called with [GemError.inUse] if an import is already in progress
  ///   - Is called with [GemError.notFound] if the landmark store category id is invalid
  ///   - Is called with [GemError.cancel] if the operation was canceled
  ///   - Is called with [GemError.invalidInput] if the provided data could not be parsed
  /// - [onProgressUpdated]: Optional progress callback (0-100).
  /// - [categoryId]: Optional category id to assign to imported landmarks.
  ///
  /// ## Returns
  ///
  /// - [ProgressListener?]: A progress listener if the import started, otherwise null.
  ///
  /// ## See also:
  ///
  /// - [importLandmarks] — imports landmarks from a file path.
  ProgressListener? importLandmarksWithDataBuffer({
    required Uint8List buffer,
    required LandmarkFileFormat format,
    required Img image,
    final void Function(GemError error)? onComplete,
    final void Function(int progress)? onProgressUpdated,
    int categoryId = uncategorizedLandmarkCategId,
  }) {
    final EventDrivenProgressListener progressListener =
        EventDrivenProgressListener();

    if (onComplete != null) {
      progressListener.registerOnCompleteWithData(
        (final int err, final String hint, final Map<dynamic, dynamic> json) =>
            onComplete(GemErrorExtension.fromCode(err)),
      );
    }

    if (onProgressUpdated != null) {
      progressListener.registerOnProgress(onProgressUpdated);
    }

    GemKitPlatform.instance.registerEventHandler(
      progressListener.id,
      progressListener,
    );
    final dynamic dataBufferPointer = GemKitPlatform.instance.toNativePointer(
      buffer,
    );
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'importLandmarksWithDataBuffer',
      args: <String, dynamic>{
        'dataBuffer': dataBufferPointer.address,
        'dataBufferSize': buffer.length,
        'fileFormat': format.id,
        'image': image.pointerId,
        'categoryId': categoryId,
        'listener': progressListener.id,
      },
    );
    GemKitPlatform.instance.freeNativePointer(dataBufferPointer);
    final GemError errorCode = GemErrorExtension.fromCode(
      resultString['result'],
    );

    if (errorCode != GemError.success) {
      onComplete?.call(errorCode);
      return null;
    }

    return progressListener;
  }

  /// Cancels a previously started asynchronous import operation for this store.
  void cancelImportLandmarks() {
    objectMethod(pointerId, 'LandmarkStore', 'cancelImportLandmarks');
  }

  /// Returns the filesystem path used to persist this landmark store.
  ///
  /// ## Returns
  ///
  /// - [String]: Path to the store file on disk.
  @Deprecated('Use the filePath getter instead.')
  String getFilePath() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'getFilePath',
    );

    return resultString['result'];
  }

  /// Returns the filesystem path used to persist this landmark store.
  ///
  /// ## Returns
  ///
  /// - [String]: Path to the store file on disk.
  String get filePath {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'getFilePath',
    );

    return resultString['result'];
  }

  /// Enables fast update mode to optimize bulk insert/delete/update operations.
  ///
  /// Fast update mode sacrifices durability for throughput; if the application
  /// or device crashes during a fast-update session the database may be corrupted
  /// and deleted on next startup. Use it only for large imports and call
  /// [stopFastUpdateMode] when finished.
  ///
  /// ## See also:
  ///
  /// - [isFastUpdateMode] — checks whether fast update mode is active.
  /// - [stopFastUpdateMode] — disables fast update mode.
  void startFastUpdateMode() {
    objectMethod(pointerId, 'LandmarkStore', 'startFastUpdateMode');
  }

  /// Stops fast update mode and optionally discards pending changes.
  ///
  /// ## Parameters
  ///
  /// - [discard]: When true discard changes made during fast update mode.
  ///
  /// ## See also:
  ///
  /// - [isFastUpdateMode] — checks whether fast update mode is active.
  /// - [startFastUpdateMode] — enables fast update mode.
  void stopFastUpdateMode({bool discard = false}) {
    objectMethod(
      pointerId,
      'LandmarkStore',
      'stopFastUpdateMode',
      args: discard,
    );
  }

  /// Returns whether fast update mode is currently active for this store.
  ///
  /// ## Returns
  ///
  /// - [bool]: `true` when active, otherwise `false`.
  ///
  /// ## See also:
  ///
  /// - [startFastUpdateMode] — enables fast update mode.
  /// - [stopFastUpdateMode] — disables fast update mode.
  bool isFastUpdateMode() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'isFastUpdateMode',
    );

    return resultString['result'];
  }

  /// Get the image as a [Img].
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes.
  ///
  /// ## Returns
  ///
  /// - [Img]: The store image wrapper.
  Img get image {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'getImage',
    );

    return Img.init(resultString['result']);
  }

  /// Sets an image to represent this landmark store from an [Img] instance.
  ///
  /// A non-empty store image can be used to override individual landmark images when
  /// rendering the collection. Passing an empty image resets the behavior to use
  /// individual landmark images.
  ///
  /// ## Parameters
  ///
  /// - [image]: The [Img] to assign to the store.
  ///
  /// ## Returns
  ///
  /// - [GemError]: Status code indicating the result (for example [GemError.success]).
  GemError setImage(Img image) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkStore',
      'setImage',
      args: image.pointerId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Remove all landmarks from store.
  void removeAllLandmarks() {
    objectMethod(pointerId, 'LandmarkStore', 'removeAllLandmarks');
  }
}
