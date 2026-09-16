// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/landmark_store.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// High-level service for creating, registering and discovering landmark stores.
///
/// [LandmarkStoreService] is a static helper that manages landmark store lifecycle and discovery.
/// Use it to create or register stores, look up existing stores by id or name, enumerate all
/// available stores, obtain SDK-provided special-purpose store identifiers, and register
/// listeners for store-level events. Typical flows include creating a store for importing landmarks,
/// retrieving a store for queries, or removing an unused store.
///
/// ## See also:
///
/// - [LandmarkStore] — per-store operations (add/update/remove landmarks and categories).
/// - [LandmarkStoreListener] — listen for store and browse-session events.
///
/// {@category Landmark Store}
abstract class LandmarkStoreService {
  /// Creates a new landmark store with the given name.
  ///
  /// The created store uses [LandmarkStoreType.defaultType]. If a store with the same `name`
  /// already exists the existing store instance is returned instead of creating a duplicate.
  ///
  /// ## Parameters
  ///
  /// - [name]: The unique name for the store. If a store with this name already exists, the
  ///   existing store is returned.
  /// - [zoom]: The maximum zoom level at which the landmark store will be visible. Use `-1`
  ///   to let the SDK choose a sensible default.
  /// - [folder]: Filesystem folder where the store will be created. When empty the SDK's
  ///   default storage location is used.
  ///
  /// ## Returns
  ///
  /// - [LandmarkStore]: Newly created or existing store instance.
  static LandmarkStore createLandmarkStore(
    final String name, {
    final int zoom = -1,
    final String folder = '',
  }) {
    final OperationResult resultString = staticMethod(
      'LandmarkStoreService',
      'createLandmarkStore',
      args: <String, Object>{'name': name, 'zoom': zoom, 'folder': folder},
    );

    final LandmarkStore retVal = LandmarkStore.init(resultString['result'], 0);
    return retVal;
  }

  /// Returns the [LandmarkStore] with the specified id, or `null` if not found.
  ///
  /// ## Parameters
  ///
  /// - [landmarkStoreId]: The id of the store to retrieve.
  ///
  /// ## Returns
  ///
  /// - [LandmarkStore?]: The store instance when found, otherwise `null`.
  static LandmarkStore? getLandmarkStoreById(final int landmarkStoreId) {
    final OperationResult resultString = staticMethod(
      'LandmarkStoreService',
      'getLandmarkStoreById',
      args: landmarkStoreId,
    );

    if (resultString['result'] == -1) {
      return null;
    }

    final LandmarkStore retVal = LandmarkStore.init(resultString['result'], 0);
    return retVal;
  }

  /// Returns the [LandmarkStore] with the specified `name`, or `null` if not found.
  ///
  /// ## Parameters
  ///
  /// - [name]: The name of the store to lookup.
  ///
  /// ## Returns
  ///
  /// - [LandmarkStore?]: The store instance when found, otherwise `null`.
  static LandmarkStore? getLandmarkStoreByName(final String name) {
    final OperationResult resultString = staticMethod(
      'LandmarkStoreService',
      'getLandmarkStoreByName',
      args: name,
    );

    if (resultString['result'] == -1) {
      return null;
    }

    final LandmarkStore retVal = LandmarkStore.init(resultString['result'], 0);
    return retVal;
  }

  /// Returns the special-purpose landmark store id used for map POIs.
  ///
  /// This id references an internal store and cannot be resolved with [getLandmarkStoreById].
  ///
  /// ## Returns
  ///
  /// - [int]: The map POIs landmark store id.
  static int get mapPoisLandmarkStoreId {
    final OperationResult resultString = staticMethod(
      'LandmarkStoreService',
      'getMapPoisLandmarkStoreId',
    );

    final int res = resultString['result'];
    return res;
  }

  /// Returns the special-purpose landmark store id containing map address data.
  ///
  /// This id references an internal store and cannot be resolved with [getLandmarkStoreById].
  ///
  /// ## Returns
  ///
  /// - [int]: The map address landmark store id.
  static int get mapAddressLandmarkStoreId {
    final OperationResult resultString = staticMethod(
      'LandmarkStoreService',
      'getMapAddressLandmarkStoreId',
    );

    return resultString['result'];
  }

  /// Returns the special-purpose landmark store id for map roads data.
  ///
  /// This id references an internal store and cannot be resolved with [getLandmarkStoreById].
  ///
  /// ## Returns
  ///
  /// - [int]: The map roads landmark store id.
  static int get mapRoadsLandmarkStoreId {
    final OperationResult resultString = staticMethod(
      'LandmarkStoreService',
      'getMapRoadsLandmarkStoreId',
    );

    return resultString['result'];
  }

  /// Returns the special-purpose landmark store id used for overlays.
  ///
  /// This id references an internal store and cannot be resolved with [getLandmarkStoreById].
  ///
  /// ## Returns
  ///
  /// - [int]: The overlays landmark store id.
  static int get overlaysLandmarkStoreId {
    final OperationResult resultString = staticMethod(
      'LandmarkStoreService',
      'getOverlaysLandmarkStoreId',
    );

    return resultString['result'];
  }

  /// Returns the special-purpose landmark store id used for geofence data.
  ///
  /// This id references an internal store and cannot be resolved with [getLandmarkStoreById].
  ///
  /// ## Returns
  ///
  /// - [int]: The geofence landmark store id.
  static int get geofenceLandmarkStoreId {
    final OperationResult resultString = staticMethod(
      'LandmarkStoreService',
      'getGeofenceLandmarkStoreId',
    );

    return resultString['result'];
  }

  /// Returns the special-purpose landmark store id for map cities data.
  ///
  /// This id references an internal store and cannot be resolved with [getLandmarkStoreById].
  ///
  /// ## Returns
  ///
  /// - [int]: The map cities landmark store id.
  static int get mapCitiesLandmarkStoreId {
    final OperationResult resultString = staticMethod(
      'LandmarkStoreService',
      'getMapCitiesLandmarkStoreId',
    );

    final int res = resultString['result'];
    return res;
  }

  /// Removes the landmark store identified by [landmarkStoreId].
  ///
  /// The [LandmarkStore] instance must be disposed (see [LandmarkStore.dispose]) before
  /// removal; otherwise the store will not be removed. The operation fails when the store
  /// is currently in use.
  ///
  /// ## Parameters
  ///
  /// - [landmarkStoreId]: Identifier of the store to remove.
  static void removeLandmarkStore(final int landmarkStoreId) {
    staticMethod(
      'LandmarkStoreService',
      'removeLandmarkStore',
      args: landmarkStoreId,
    );
  }

  /// Returns the [LandmarkStoreType] for the specified store id.
  ///
  /// ## Parameters
  ///
  /// - [landmarkStoreId]: The id of the landmark store to query.
  ///
  /// ## Returns
  ///
  /// - [LandmarkStoreType]: The type of the store. Returns [LandmarkStoreType.none]
  ///   when [landmarkStoreId] is invalid.
  static LandmarkStoreType getLandmarkStoreType(int landmarkStoreId) {
    final OperationResult resultString = staticMethod(
      'LandmarkStoreService',
      'getLandmarkStoreType',
      args: landmarkStoreId,
    );

    if (resultString['result'] == -1) {
      return LandmarkStoreType.none;
    }

    return LandmarkStoreType.values[resultString['result']];
  }

  /// Registers an existing landmark store that already exists on disk.
  ///
  /// Use this to make an external store available to the SDK. The supplied [name]
  /// overrides the store's internal name and must be unique.
  ///
  /// ## Parameters
  ///
  /// - [name]: The name to register the store under. If this name is already used the
  ///   operation fails with `GemError.exist.code`.
  /// - [path]: Filesystem path pointing to the existing landmark store.
  ///
  /// ## Returns
  ///
  /// - [int]: On success returns the landmark store id (positive integer).
  /// - [int]: On failure returns a `GemError` code. Possible error codes include:
  ///   - `[GemError.exist].code`: The `name` is already taken.
  ///   - `[GemError.notFound].code`: The store could not be found at `path`.
  ///   - `[GemError.invalidInput].code`: The provided `path` does not contain a valid store.
  static int registerLandmarkStore({
    required final String name,
    required final String path,
  }) {
    final OperationResult resultString = staticMethod(
      'LandmarkStoreService',
      'registerLandmarkStore',
      args: <String, String>{'name': name, 'path': path},
    );

    final int res = resultString['result'];
    return res;
  }

  /// Returns a list containing all registered [LandmarkStore] instances.
  ///
  /// ## Returns
  ///
  /// - [List<LandmarkStore>]: All known landmark stores.
  static List<LandmarkStore> get landmarkStores {
    final OperationResult resultString = staticMethod(
      'LandmarkStoreService',
      'getLandmarkStores',
    );

    final List<dynamic> res = resultString['result'];
    return res.map((final dynamic e) => LandmarkStore.init(e, 0)).toList();
  }

  /// Registers a [LandmarkStoreListener] to receive landmark store events.
  ///
  /// The listener is registered with the underlying event platform and will receive
  /// callbacks for events such as category creation, landmark updates and browse-session
  /// invalidation. The same listener instance must be passed to [removeListener] to
  /// unregister it.
  ///
  /// ## Parameters
  ///
  /// - [listener]: The listener to register for store events.
  ///
  /// ## See also:
  ///
  /// - [removeListener] — Unregisters a previously added [LandmarkStoreListener].
  static void addListener(final LandmarkStoreListener listener) {
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    staticMethod('LandmarkStoreService', 'addListener', args: listener.id);
  }

  /// Unregisters a previously added [LandmarkStoreListener].
  ///
  /// This removes the listener from the platform event registry; after removal the
  /// listener will no longer receive store events.
  ///
  /// ## Parameters
  ///
  /// - [listener]: The listener instance to remove (must be the same instance used
  ///   when calling [addListener]).
  ///
  /// ## See also:
  ///
  /// - [addListener] — Registers a [LandmarkStoreListener] to receive landmark store events.
  static void removeListener(final LandmarkStoreListener listener) {
    staticMethod('LandmarkStoreService', 'removeListener', args: listener.id);

    GemKitPlatform.instance.unregisterEventHandler(listener.id);
  }
}
