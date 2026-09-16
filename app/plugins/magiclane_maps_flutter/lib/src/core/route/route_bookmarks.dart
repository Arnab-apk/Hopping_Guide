// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/routing.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Manages a persistent collection of saved routes (bookmarks).
///
/// Provides operations to create, add, import, update, remove and export saved routes.
/// Use [RouteBookmarks.create] to open or create a named bookmarks collection backed by a file.
///
/// ## See also:
///
/// - [RoutePreferences] - preferences that can be stored with a bookmarked route.
/// - [Landmark] - waypoints used to define routes.
///
/// {@category Route}
class RouteBookmarks extends GemAutoreleaseObject {
  @internal
  RouteBookmarks.init(super.id);

  // ignore: unused_element
  RouteBookmarks._(super.id);

  /// Open or create a bookmarks collection with the provided name.
  ///
  /// The factory creates or opens the underlying bookmarks database for the given [name]
  /// and returns a [RouteBookmarks] instance that operates on that collection.
  ///
  /// ## Parameters
  ///
  /// - [name]: The name (path) of the bookmarks collection to open or create.
  factory RouteBookmarks.create(final String name) {
    final String encodedVal = jsonEncode(<String, dynamic>{
      'class': 'RouteBookmarks',
      'args': <String, dynamic>{'name': name, 'folderPath': ''},
    });
    final String resultString = GemKitPlatform.instance.callCreateObject(
      encodedVal,
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return RouteBookmarks.init(decodedVal['result']);
  }

  /// Open or create a bookmarks collection with the provided name and folder path.
  ///
  /// The factory creates or opens the underlying bookmarks database for the given [name] and [folderPath]
  /// and returns a [RouteBookmarks] instance that operates on that collection.
  ///
  /// ## Parameters
  ///
  /// - [name]: The name (path) of the bookmarks collection to open or create.
  /// - [folderPath]: Optional folder absolute path where the bookmarks collection file is stored. Folder needs to exist in the app root directory before calling this method.
  ///
  /// ## Returns
  ///
  /// - `RouteBookmarks?`: the created [RouteBookmarks] instance on success, or `null` if creation failed (invalid folder path or lack of write permissions).
  static RouteBookmarks? createInFolder({
    required final String name,
    final String folderPath = '',
  }) {
    final String encodedVal = jsonEncode(<String, dynamic>{
      'class': 'RouteBookmarks',
      'args': <String, dynamic>{'name': name, 'folderPath': folderPath},
    });
    final String resultString = GemKitPlatform.instance.callCreateObject(
      encodedVal,
    );
    final dynamic decodedVal = jsonDecode(resultString);

    if (decodedVal['gemApiError'] != 0) {
      return null;
    }

    return RouteBookmarks.init(decodedVal['result']);
  }

  /// Adds a new route or updates an existing one in this bookmarks collection.
  ///
  /// Stores a route identified by [name] together with its [waypoints] and optional [preferences].
  /// When a route with the same [name] already exists the operation will fail unless [overwrite]
  /// is set to `true`, in which case the existing route is replaced.
  ///
  /// Only route-relevant preference fields are persisted.
  ///
  /// ## Parameters
  ///
  /// - [name]: Unique name identifying the route.
  /// - [waypoints]: Ordered list of [Landmark] objects defining the route.
  /// - [preferences]: Optional [RoutePreferences] to store with the route. If `null`, a default set of preferences will be used.
  /// - [overwrite]: When `true`, overwrite an existing route with the same name. Defaults to `false`.
  void add(
    final String name,
    final List<Landmark> waypoints, {
    final RoutePreferences? preferences,
    final bool overwrite = false,
  }) {
    final LandmarkList landmarkList = LandmarkList.fromList(waypoints);

    objectMethod(
      pointerId,
      'RouteBookmarks',
      'add',
      args: <String, dynamic>{
        'name': name,
        'waypoints': landmarkList.pointerId,
        'preferences': preferences?.pointerId,
        'overwrite': overwrite,
      },
    );
  }

  /// Import routes from a file and add them to this bookmarks collection.
  ///
  /// The method attempts to parse and import trips from the given [filename]. On success it
  /// returns the number of imported routes. If the import fails the method returns an error code
  /// (for example [GemError.invalidInput].code).
  ///
  /// ## Parameters
  ///
  /// - [filename]: Path to the file containing exported bookmarks/trips.
  ///
  /// ## Returns
  ///
  /// - `int`: number of imported routes on success, or a [GemError.invalidInput] code on failure.
  int addTrips(final String filename) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBookmarks',
      'addTrips',
      args: filename,
    );

    return resultString['result'];
  }

  /// Remove all routes from this bookmarks collection.
  ///
  /// After calling this method the collection will be empty.
  void clear() {
    objectMethod(pointerId, 'RouteBookmarks', 'clear');
  }

  /// Export a bookmarked route to the filesystem.
  ///
  /// Writes the route at [index] to the given filesystem [path] in a standard interchange format
  /// (for example GPX). The returned value communicates success or the type of failure.
  ///
  /// ## Parameters
  ///
  /// - [index]: Index of the route in the current sort order.
  /// - [path]: Destination file path where the route will be written.
  ///
  /// ## Returns
  ///
  /// - [GemError]: [GemError.success] on success, or an error such as [GemError.notFound] or [GemError.io].
  GemError exportToFile(final int index, final String path) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBookmarks',
      'exportToFile',
      args: <String, Object>{'index': index, 'path': path},
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Find a bookmarked route by its [name].
  ///
  /// ## Parameters
  ///
  /// - [name]: The unique name of the route to find.
  ///
  /// ## Returns
  ///
  /// - `int`: non-negative index of the found route on success.
  /// - GemError codes: [GemError.notFound].code when not found or [GemError.internalAbort].code on internal errors.
  int find(final String name) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBookmarks',
      'find',
      args: name,
    );

    return resultString['result'];
  }

  /// Whether the underlying bookmarks database is automatically deleted when this object is destroyed.
  ///
  /// When `true`, the database file is removed when the [RouteBookmarks] instance is disposed.
  /// Default value is `false`.
  ///
  /// ## Returns
  ///
  /// - `bool`: current auto-delete mode.
  bool get autoDeleteMode {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBookmarks',
      'getAutoDeleteMode',
    );

    return resultString['result'];
  }

  /// File path of the bookmarks collection used by this [RouteBookmarks] instance.
  ///
  /// This is the platform-specific file path where the bookmarks database is stored.
  ///
  /// ## Returns
  ///
  /// - `String`: absolute path to the bookmarks file.
  String get filePath {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBookmarks',
      'getFilePath',
    );

    return resultString['result'];
  }

  /// Returns the name of the bookmarked route at [index], or `null` when the index is invalid.
  ///
  /// ## Parameters
  ///
  /// - [index]: Index of the route in the current sort order.
  ///
  /// ## Returns
  ///
  /// - `String?`: the route name when present, otherwise `null`.
  String? getName(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBookmarks',
      'getName',
      args: index,
    );

    final GemError err = GemErrorExtension.fromCode(
      resultString.data['gemApiError'],
    );

    if (err != GemError.success) {
      return null;
    }

    return resultString['result'];
  }

  /// Retrieves the [RoutePreferences] saved with the route at [index].
  ///
  /// ## Parameters
  ///
  /// - [index]: Index of the route in the current sort order.
  ///
  /// ## Returns
  ///
  /// - `RoutePreferences?`: preferences when present, otherwise `null`.
  RoutePreferences? getPreferences(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBookmarks',
      'getPreferences',
      args: index,
    );

    final GemError err = GemErrorExtension.fromCode(
      resultString.data['gemApiError'],
    );

    if (err != GemError.success) {
      return null;
    }

    return RoutePreferences.init(resultString.data['result']);
  }

  /// Number of bookmarked routes in this collection.
  ///
  /// ## Returns
  ///
  /// - `int`: count of stored routes.
  int get size {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBookmarks',
      'size',
    );

    return resultString['result'];
  }

  /// UTC timestamp of when the route was saved.
  ///
  /// ## Parameters
  ///
  /// - [index]: Index of the route in the current sort order.
  ///
  /// ## Returns
  ///
  /// - `DateTime?`: UTC timestamp when the route was saved, or `null` if not available.
  DateTime? getTimestamp(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBookmarks',
      'getTimestamp',
      args: index,
    );

    final GemError err = GemErrorExtension.fromCode(
      resultString.data['gemApiError'],
    );

    if (err != GemError.success) {
      return null;
    }

    return DateTime.fromMillisecondsSinceEpoch(
      resultString['result'],
      isUtc: true,
    );
  }

  /// Returns the list of [Landmark] waypoints for the route at [index].
  ///
  /// ## Parameters
  ///
  /// - [index]: Index of the route in the current sort order.
  ///
  /// ## Returns
  ///
  /// - `List<Landmark>?`: ordered list of waypoints, or `null` when the index is invalid.
  List<Landmark>? getWaypoints(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RouteBookmarks',
      'getWaypoints',
      args: index,
    );

    final GemError err = GemErrorExtension.fromCode(
      resultString.data['gemApiError'],
    );

    if (err != GemError.success) {
      return null;
    }

    return LandmarkList.init(resultString['result']).toList();
  }

  /// Remove the bookmarked route at [index].
  ///
  /// ## Parameters
  ///
  /// - [index]: Index of the route to remove in the current sort order.
  void remove(final int index) {
    objectMethod(pointerId, 'RouteBookmarks', 'remove', args: index);
  }

  /// Enable or disable automatic deletion of the underlying bookmarks file when this object is disposed.
  ///
  /// ## Parameters
  ///
  /// - [mode]: `true` to enable auto-delete, `false` to disable.
  set autoDeleteMode(final bool mode) {
    objectMethod(pointerId, 'RouteBookmarks', 'setAutoDeleteMode', args: mode);
  }

  /// Change the sort order used to present routes from this collection.
  ///
  /// The default sort order is [RouteBookmarksSortOrder.sortByDate]. The UI should refresh any
  /// views after changing the sort order to reflect the updated ordering.
  ///
  /// ## Parameters
  ///
  /// - [order]: Desired [RouteBookmarksSortOrder].
  set sortOrder(final RouteBookmarksSortOrder order) {
    objectMethod(pointerId, 'RouteBookmarks', 'setSortOrder', args: order.id);
  }

  /// Update an existing bookmarked route.
  ///
  /// Only the fields provided will be updated; omit a parameter to leave the existing value intact.
  ///
  /// ## Parameters
  ///
  /// - [index]: Index of the route to update in the current sort order.
  /// - [name]: Optional new unique name for the route. If a route with this name already exists the update will fail.
  /// - [waypoints]: Optional new list of [Landmark] waypoints.
  /// - [preferences]: Optional [RoutePreferences] to persist with the route.
  ///
  /// Notes: Only route-relevant preferences (transport mode and avoid settings) are persisted.
  void update(
    final int index, {
    final String? name,
    final List<Landmark>? waypoints,
    final RoutePreferences? preferences,
  }) {
    final LandmarkList landmarkList = waypoints == null
        ? LandmarkList()
        : LandmarkList.fromList(waypoints);

    objectMethod(
      pointerId,
      'RouteBookmarks',
      'update',
      args: <String, dynamic>{
        'index': index,
        'name': name ?? '',
        'waypoints': landmarkList.pointerId,
        'preferences': preferences?.pointerId,
        'hasName': name != null,
        'hasWaypoints': waypoints != null,
        'hasPreferences': preferences != null,
      },
    );
  }
}

/// Sort order options for [RouteBookmarks].
///
/// - [sortByDate]: sort descending by update time (most recent first).
/// - [sortByName]: sort ascending by name.
///
/// {@category Route}
enum RouteBookmarksSortOrder {
  /// Sort descending by update time (most recent at top).
  sortByDate,

  /// Sort ascending by name.
  sortByName,
}

/// @nodoc
extension RouteBookmarksSortOrderExtension on RouteBookmarksSortOrder {
  int get id {
    switch (this) {
      case RouteBookmarksSortOrder.sortByDate:
        return 0;
      case RouteBookmarksSortOrder.sortByName:
        return 1;
    }
  }

  static RouteBookmarksSortOrder fromId(final int id) {
    switch (id) {
      case 0:
        return RouteBookmarksSortOrder.sortByDate;
      case 1:
        return RouteBookmarksSortOrder.sortByName;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
