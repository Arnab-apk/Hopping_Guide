// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// A paged, snapshot-based session for browsing landmarks in a [LandmarkStore].
///
/// [LandmarkBrowseSession] provides efficient, paginated access to landmarks contained
/// in a store at the time the session was created. Construct sessions via
/// [LandmarkStore.createLandmarkBrowseSession] and use the session to fetch ranges of
/// landmarks, query positions and read session settings.
///
/// Only landmarks present in the store before session creation are visible
/// within the session; later additions are not included.
///
/// ## See also:
///
/// - [LandmarkStore.createLandmarkBrowseSession] — create a browse session for a store.
/// - [LandmarkBrowseSessionSettings] — configure sorting and filtering for a session.
///
/// {@category Landmark Store}
class LandmarkBrowseSession extends GemAutoreleaseObject {
  LandmarkBrowseSession.init(super.id);

  // ignore: unused_element
  LandmarkBrowseSession._() : super(0);

  /// Returns the unique id of this browse session.
  ///
  /// ## Returns
  ///
  /// - [int]: The session identifier.
  int get id {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkBrowseSession',
      'getId',
    );

    return resultString['result'];
  }

  /// Returns the id of the associated [LandmarkStore].
  ///
  /// ## Returns
  ///
  /// - [int]: The `LandmarkStore.id` that this session targets.
  ///
  /// ## See also:
  ///
  /// - [LandmarkStore] — the store associated with this session.
  /// - [LandmarkStoreService.getLandmarkStoreById] — retrieve the [LandmarkStore] by its id.
  int get landmarkStoreId {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkBrowseSession',
      'getLandmarkStoreId',
    );

    return resultString['result'];
  }

  /// Returns the total number of landmarks captured by this session.
  ///
  /// ## Returns
  ///
  /// - [int]: Number of landmarks available through this session.
  int get landmarkCount {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkBrowseSession',
      'getLandmarkCount',
    );

    return resultString['result'];
  }

  /// Retrieves landmarks for the half-open index range `[start, end)` in this session.
  ///
  /// Use this method to page through results; indexes are zero-based and the
  /// returned list may be shorter than `(end - start)` if fewer items remain.
  ///
  /// ## Parameters
  ///
  /// - [start]: Starting index (inclusive, zero-based).
  /// - [end]: Ending index (exclusive).
  ///
  /// ## Returns
  ///
  /// - [List<Landmark>]: Landmarks within the requested range.
  List<Landmark> getLandmarks(int start, int end) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkBrowseSession',
      'getLandmarks',
      args: <String, int>{'first': start, 'second': end},
    );

    return LandmarkList.init(resultString['result']).toList();
  }

  /// Returns the zero-based index of the landmark with id [landmarkId] within this session.
  ///
  /// ## Parameters
  ///
  /// - [landmarkId]: Landmark identifier.
  ///
  /// ## Returns
  ///
  /// - [int]: The 0-based index when found, otherwise the sentinel value
  ///   `[GemError.notFound].code`.
  int getLandmarkPosition(final int landmarkId) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkBrowseSession',
      'getLandmarkPos',
      args: landmarkId,
    );

    return resultString['result'];
  }

  /// Returns the settings used to create this session.
  ///
  /// Modifying the returned object does not alter the active session; to change
  /// filtering or ordering create a new session with different settings.
  ///
  /// ## Returns
  ///
  /// - [LandmarkBrowseSessionSettings]: The session settings snapshot.
  LandmarkBrowseSessionSettings get settings {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkBrowseSession',
      'getSettings',
    );

    return LandmarkBrowseSessionSettings.fromJson(resultString['result']);
  }
}

/// Criteria used to order landmarks inside a [LandmarkBrowseSession].
///
/// Use in [LandmarkBrowseSessionSettings] to choose how results are sorted.
///
/// {@category Landmark Store}
enum LandmarkOrder {
  /// Order results alphabetically by landmark `name`.
  name,

  /// Order results by insertion `date`.
  date,

  /// Order results by `distance` relative to the provided [Coordinates].
  distance,
}

/// @nodoc
extension LandmarkOrderExtension on LandmarkOrder {
  int get id {
    switch (this) {
      case LandmarkOrder.name:
        return 0;
      case LandmarkOrder.date:
        return 1;
      case LandmarkOrder.distance:
        return 2;
    }
  }

  static LandmarkOrder fromId(final int id) {
    switch (id) {
      case 0:
        return LandmarkOrder.name;
      case 1:
        return LandmarkOrder.date;
      case 2:
        return LandmarkOrder.distance;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Settings used to configure a [LandmarkBrowseSession].
///
/// Controls sorting, name filtering, category filtering and an optional reference
/// coordinate used when ordering by distance.
///
/// {@category Landmark Store}
class LandmarkBrowseSessionSettings {
  LandmarkBrowseSessionSettings({
    this.descendingOrder = false,
    this.orderBy = LandmarkOrder.name,
    this.nameFilter = '',
    this.categoryIdFilter = LandmarkStore.invalidLandmarkCategId,
    Coordinates? coordinates,
  }) {
    this.coordinates = coordinates ?? Coordinates();
  }

  /// Creates a new instance from a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory LandmarkBrowseSessionSettings.fromJson(
    final Map<String, dynamic> json,
  ) {
    return LandmarkBrowseSessionSettings(
      descendingOrder: json['descendingOrder'],
      orderBy: LandmarkOrderExtension.fromId(json['orderBy']),
      nameFilter: json['nameFilter'],
      categoryIdFilter: json['categoryIdFilter'],
      coordinates: Coordinates.fromJson(json['coordinates']),
    );
  }

  /// When true sort in descending order. Defaults to `false` (ascending).
  bool descendingOrder;

  /// Ordering criteria for results (default: [LandmarkOrder.name]).
  LandmarkOrder orderBy;

  /// Case-insensitive substring filter for landmark names. Defaults to empty (no filter).
  String nameFilter;

  /// Category id to filter results. Defaults to [LandmarkStore.invalidLandmarkCategId]
  /// to include all categories.
  int categoryIdFilter;

  /// Reference coordinates used when [orderBy] is [LandmarkOrder.distance].
  late Coordinates coordinates;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['descendingOrder'] = descendingOrder;
    json['orderBy'] = orderBy.id;
    json['nameFilter'] = nameFilter;
    json['categoryIdFilter'] = categoryIdFilter;
    json['coordinates'] = coordinates.toJson();
    return json;
  }

  @override
  bool operator ==(covariant LandmarkBrowseSessionSettings other) =>
      other.descendingOrder == descendingOrder &&
      other.orderBy == orderBy &&
      other.categoryIdFilter == categoryIdFilter &&
      other.nameFilter == nameFilter &&
      other.coordinates == coordinates;

  @override
  int get hashCode =>
      descendingOrder.hashCode ^
      orderBy.hashCode ^
      nameFilter.hashCode ^
      categoryIdFilter.hashCode ^
      coordinates.hashCode;
}
