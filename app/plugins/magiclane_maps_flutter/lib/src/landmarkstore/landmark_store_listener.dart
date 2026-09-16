// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';
import 'package:meta/meta.dart';

/// Listener for landmark store events.
///
/// [LandmarkStoreListener] lets you register callbacks that are invoked when
/// landmark stores or their contents change (landmarks added/updated/removed,
/// categories created/updated/removed, store lifecycle events, and browse-session
/// invalidation). Construct a listener and register it with
/// [LandmarkStoreService.addListener] to begin receiving events from the SDK.
///
/// ## See also:
///
/// - [LandmarkStoreService.addListener] — register a listener with the SDK.
/// - [LandmarkStoreService.removeListener] — unregister a previously added listener.
///
/// {@category Landmark Store}
class LandmarkStoreListener extends EventHandler {
  /// Creates a new [LandmarkStoreListener] and registers the provided callbacks.
  ///
  /// Each callback, when provided, will be invoked for the corresponding event
  /// emitted by the SDK. Callbacks receive identifiers such as `landmarkStoreId`,
  /// `landmarkId`, category ids or lists of ids depending on the event.
  ///
  /// ## Parameters
  ///
  /// - [onLandmarkCreated]: Called when a landmark (already existent) is added to a store.
  /// - [onLandmarkUpdated]: Called when an existing landmark is updated.
  /// - [onLandmarksUpdated]: Called when multiple landmarks are updated.
  /// - [onLandmarkRemoved]: Called when a landmark is removed.
  /// - [onLandmarksRemoved]: Called when multiple landmarks are removed.
  /// - [onCategoryCreated]: Called when a category is created in a store.
  /// - [onCategoryUpdated]: Called when a category is updated in a store.
  /// - [onCategoryRemoved]: Called when a category is removed from a store.
  /// - [onLandmarkStoreCreated]: Called when a new landmark store is created.
  /// - [onLandmarkStoreRegistered]: Called when a landmark store is registered.
  /// - [onLandmarkStoreRemoved]: Called when a landmark store is removed.
  /// - [onBrowseSessionInvalidated]: Called when a browse session is invalidated.
  ///
  /// ## Returns
  ///
  /// - [LandmarkStoreListener]: The created listener instance.
  factory LandmarkStoreListener({
    final void Function(int landmarkStoreId, int landmarkId)? onLandmarkCreated,
    final void Function(int landmarkStoreId, int landmarkId)? onLandmarkUpdated,
    final void Function(int landmarkStoreId, List<int> landmarksId)?
    onLandmarksUpdated,
    final void Function(int landmarkStoreId, int landmarkId)? onLandmarkRemoved,
    final void Function(int landmarkStoreId, List<int> landmarkIds)?
    onLandmarksRemoved,
    final void Function(int landmarkStoreId, int categoryId)? onCategoryCreated,
    final void Function(int landmarkStoreId, int categoryId)? onCategoryUpdated,
    final void Function(int landmarkStoreId, int categoryId)? onCategoryRemoved,
    final void Function(int landmarkStoreId)? onLandmarkStoreCreated,
    final void Function(int landmarkStoreId)? onLandmarkStoreRegistered,
    final void Function(int landmarkStoreId)? onLandmarkStoreRemoved,
    final void Function(int landmarkStoreId, int sessionId)?
    onBrowseSessionInvalidated,
  }) {
    final LandmarkStoreListener listener = LandmarkStoreListener._create();

    if (onLandmarkCreated != null) {
      listener.registerOnLandmarkCreated(onLandmarkCreated);
    }
    if (onLandmarkUpdated != null) {
      listener.registerOnLandmarkUpdated(onLandmarkUpdated);
    }
    if (onLandmarksUpdated != null) {
      listener.registerOnLandmarksUpdated(onLandmarksUpdated);
    }
    if (onLandmarkRemoved != null) {
      listener.registerOnLandmarkRemoved(onLandmarkRemoved);
    }
    if (onLandmarksRemoved != null) {
      listener.registerOnLandmarksRemoved(onLandmarksRemoved);
    }
    if (onCategoryCreated != null) {
      listener.registerOnCategoryCreated(onCategoryCreated);
    }
    if (onCategoryUpdated != null) {
      listener.registerOnCategoryUpdated(onCategoryUpdated);
    }
    if (onCategoryRemoved != null) {
      listener.registerOnCategoryRemoved(onCategoryRemoved);
    }
    if (onLandmarkStoreCreated != null) {
      listener.registerOnLandmarkStoreCreated(onLandmarkStoreCreated);
    }
    if (onLandmarkStoreRegistered != null) {
      listener.registerOnLandmarkStoreRegistered(onLandmarkStoreRegistered);
    }
    if (onLandmarkStoreRemoved != null) {
      listener.registerOnLandmarkStoreRemoved(onLandmarkStoreRemoved);
    }
    if (onBrowseSessionInvalidated != null) {
      listener.registerOnBrowseSessionInvalidated(onBrowseSessionInvalidated);
    }

    return listener;
  }

  @internal
  LandmarkStoreListener.init(this.id);
  void Function(int landmarkStoreId, int landmarkId)?
  _onLandmarkCreatedCallback;
  void Function(int landmarkStoreId, int landmarkId)?
  _onLandmarkUpdatedCallback;
  void Function(int landmarkStoreId, List<int> landmarksId)?
  _onLandmarksUpdatedCallback;
  void Function(int landmarkStoreId, int landmarkId)?
  _onLandmarkRemovedCallback;
  void Function(int landmarkStoreId, List<int> landmarkIds)?
  _onLandmarksRemovedCallback;
  void Function(int landmarkStoreId, int categoryId)?
  _onCategoryCreatedCallback;
  void Function(int landmarkStoreId, int categoryId)?
  _onCategoryUpdatedCallback;
  void Function(int landmarkStoreId, int categoryId)?
  _onCategoryRemovedCallback;
  void Function(int landmarkStoreId)? _onLandmarkStoreCreatedCallback;
  void Function(int landmarkStoreId)? _onLandmarkStoreRegisteredCallback;
  void Function(int landmarkStoreId)? _onLandmarkStoreRemovedCallback;
  void Function(int landmarkStoreId, int sessionId)?
  _onBrowseSessionInvalidatedCallback;

  dynamic id;

  static LandmarkStoreListener _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'LandmarkStoreListener',
        'args': <String, dynamic>{},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return LandmarkStoreListener.init(decodedVal['result']);
  }

  /// Register a callback that is invoked when a landmark is added to a store.
  ///
  /// This event is only raised for existing landmarks (for example, landmarks provided by
  /// search results or map selection). It is not triggered for user-created landmarks.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when a landmark is created. Arguments:
  ///   - `landmarkStoreId`: Identifier of the [LandmarkStore].
  ///   - `landmarkId`: Identifier of the added [Landmark].
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreService.getLandmarkStoreById] — retrieve the [LandmarkStore] by its id.
  /// - [LandmarkStore.getLandmark] — retrieve the [Landmark] by its id.
  void registerOnLandmarkCreated(
    final void Function(int landmarkStoreId, int landmarkId)? callback,
  ) {
    _onLandmarkCreatedCallback = callback;
  }

  /// Register a callback invoked when an existing landmark is updated.
  ///
  /// This event is raised for modifications of landmarks that already exist in the store.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when a landmark is updated. Arguments:
  ///   - `landmarkStoreId`: Identifier of the [LandmarkStore].
  ///   - `landmarkId`: Identifier of the updated [Landmark].
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreService.getLandmarkStoreById] — retrieve the [LandmarkStore] by its id.
  /// - [LandmarkStore.getLandmark] — retrieve the [Landmark] by its id.
  /// - [registerOnLandmarksUpdated] — register a callback for when multiple landmarks are updated.
  void registerOnLandmarkUpdated(
    final void Function(int landmarkStoreId, int landmarkId)? callback,
  ) {
    _onLandmarkUpdatedCallback = callback;
  }

  /// Register a callback invoked when multiple landmarks are updated at once.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when multiple landmarks are updated. Arguments:
  ///   - `landmarkStoreId`: Identifier of the [LandmarkStore].
  ///   - `landmarksId`: Identifiers of the updated [Landmark]s.
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreService.getLandmarkStoreById] — retrieve the [LandmarkStore] by its id.
  /// - [LandmarkStore.getLandmark] — retrieve the [Landmark] by its id.
  /// - [registerOnLandmarkUpdated] — register a callback for when a landmark is updated.
  void registerOnLandmarksUpdated(
    final void Function(int landmarkStoreId, List<int> landmarksId)? callback,
  ) {
    _onLandmarksUpdatedCallback = callback;
  }

  /// Register a callback invoked when a landmark is removed from a store.
  ///
  /// This is only raised for existing landmarks (not user-created ones).
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when a landmark is removed. Arguments:
  ///   - `landmarkStoreId`: Identifier of the [LandmarkStore].
  ///   - `landmarkId`: Identifier of the removed [Landmark].
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreService.getLandmarkStoreById] — retrieve the [LandmarkStore] by its id.
  /// - [LandmarkStore.getLandmark] — retrieve the [Landmark] by its id.
  void registerOnLandmarkRemoved(
    final void Function(int landmarkStoreId, int landmarkId)? callback,
  ) {
    _onLandmarkRemovedCallback = callback;
  }

  /// Register a callback invoked when multiple landmarks are removed.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when multiple landmarks are removed. Arguments:
  ///   - `landmarkStoreId`: Identifier of the [LandmarkStore].
  ///   - `landmarksId`: Identifiers of the removed [Landmark]s.
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreService.getLandmarkStoreById] — retrieve the [LandmarkStore] by its id.
  /// - [LandmarkStore.getLandmark] — retrieve the [Landmark] by its id.
  void registerOnLandmarksRemoved(
    final void Function(int landmarkStoreId, List<int> landmarksId)? callback,
  ) {
    _onLandmarksRemovedCallback = callback;
  }

  /// Register a callback invoked when a category is created in a store.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when a category is created. Arguments:
  ///   - `landmarkStoreId`: Identifier of the [LandmarkStore].
  ///   - `categoryId`: Identifier of the created category.
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreService.getLandmarkStoreById] — retrieve the [LandmarkStore] by its id.
  /// - [LandmarkStore.getCategoryById] — retrieve the [LandmarkCategory] by its id.
  void registerOnCategoryCreated(
    final void Function(int landmarkStoreId, int categoryId)? callback,
  ) {
    _onCategoryCreatedCallback = callback;
  }

  /// Register a callback invoked when a category is updated in a store.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when a category is updated. Arguments:
  ///   - `landmarkStoreId`: Identifier of the [LandmarkStore].
  ///   - `categoryId`: Identifier of the updated category.
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreService.getLandmarkStoreById] — retrieve the [LandmarkStore] by its id.
  /// - [LandmarkStore.getCategoryById] — retrieve the [LandmarkCategory] by its id.
  void registerOnCategoryUpdated(
    final void Function(int landmarkStoreId, int categoryId)? callback,
  ) {
    _onCategoryUpdatedCallback = callback;
  }

  /// Register a callback invoked when a category is removed from a store.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when a category is removed. Arguments:
  ///   - `landmarkStoreId`: Identifier of the [LandmarkStore].
  ///   - `categoryId`: Identifier of the removed category.
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreService.getLandmarkStoreById] — retrieve the [LandmarkStore] by its id.
  /// - [LandmarkStore.getCategoryById] — retrieve the [LandmarkCategory] by its id.
  void registerOnCategoryRemoved(
    final void Function(int landmarkStoreId, int categoryId)? callback,
  ) {
    _onCategoryRemovedCallback = callback;
  }

  /// Register a callback invoked when a new landmark store is created.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when a store is created. Arguments:
  ///   - `landmarkStoreId`: Identifier of the [LandmarkStore].
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreService.getLandmarkStoreById] — retrieve the [LandmarkStore] by its id.
  void registerOnLandmarkStoreCreated(
    final void Function(int landmarkStoreId)? callback,
  ) {
    _onLandmarkStoreCreatedCallback = callback;
  }

  /// Register a callback invoked when a landmark store is registered with the SDK.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when a store is registered. Arguments:
  ///   - `landmarkStoreId`: Identifier of the [LandmarkStore].
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreService.getLandmarkStoreById] — retrieve the [LandmarkStore] by its id.
  void registerOnLandmarkStoreRegistered(
    final void Function(int landmarkStoreId)? callback,
  ) {
    _onLandmarkStoreRegisteredCallback = callback;
  }

  /// Register a callback invoked when a landmark store is removed.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when a store is removed. Arguments:
  ///   - `landmarkStoreId`: Identifier of the [LandmarkStore].
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreService.getLandmarkStoreById] — retrieve the [LandmarkStore] by its id.
  void registerOnLandmarkStoreRemoved(
    final void Function(int landmarkStoreId)? callback,
  ) {
    _onLandmarkStoreRemovedCallback = callback;
  }

  /// Register a callback invoked when a `LandmarkBrowseSession` becomes invalid.
  ///
  /// This event occurs when the underlying store changes in a way that invalidates
  /// existing browse sessions. The callback receives the store id and the session id
  /// so consumers can refresh or recreate sessions as needed.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called on session invalidation. Arguments:
  ///   - `landmarkStoreId`: Identifier of the [LandmarkStore].
  ///   - `sessionId`: Identifier of the [LandmarkBrowseSession].
  ///
  /// ## See also:
  ///
  /// - [LandmarkStoreService.getLandmarkStoreById] — retrieve the [LandmarkStore] by its id.
  /// - [LandmarkStore.createLandmarkBrowseSession] — create a new browse session.
  void registerOnBrowseSessionInvalidated(
    final void Function(int landmarkStoreId, int sessionId)? callback,
  ) {
    _onBrowseSessionInvalidatedCallback = callback;
  }

  @override
  void nativeClear() {
    // Unregister this listener from the global LandmarkStoreService so the
    // native side stops dispatching landmark-store events to it.
    staticMethod('LandmarkStoreService', 'removeListener', args: id);
  }

  @override
  void clearListeners() {
    _onLandmarkCreatedCallback = null;
    _onLandmarkUpdatedCallback = null;
    _onLandmarksUpdatedCallback = null;
    _onLandmarkRemovedCallback = null;
    _onLandmarksRemovedCallback = null;
    _onCategoryCreatedCallback = null;
    _onCategoryUpdatedCallback = null;
    _onCategoryRemovedCallback = null;
    _onLandmarkStoreCreatedCallback = null;
    _onLandmarkStoreRegisteredCallback = null;
    _onLandmarkStoreRemovedCallback = null;
    _onBrowseSessionInvalidatedCallback = null;
  }

  @override
  void handleEvent(final Map<dynamic, dynamic> arguments) {
    final String eventSubtype = arguments['event_subtype'];

    switch (eventSubtype) {
      case 'onLandmarkCreated':
        if (_onLandmarkCreatedCallback != null) {
          _onLandmarkCreatedCallback!(
            arguments['landmarkStoreId'],
            arguments['landmarkId'],
          );
        }

      case 'onLandmarkUpdated':
        if (_onLandmarkUpdatedCallback != null) {
          _onLandmarkUpdatedCallback!(
            arguments['landmarkStoreId'],
            arguments['landmarkId'],
          );
        }

      case 'onLandmarksUpdated':
        if (_onLandmarksUpdatedCallback != null) {
          _onLandmarksUpdatedCallback!(
            arguments['landmarkStoreId'],
            arguments['landmarksId'].cast<int>(),
          );
        }

      case 'onLandmarkRemoved':
        if (_onLandmarkRemovedCallback != null) {
          _onLandmarkRemovedCallback!(
            arguments['landmarkStoreId'],
            arguments['landmarkId'],
          );
        }

      case 'onLandmarksRemoved':
        if (_onLandmarksRemovedCallback != null) {
          _onLandmarksRemovedCallback!(
            arguments['landmarkStoreId'],
            arguments['landmarksId'].cast<int>(),
          );
        }

      case 'onCategoryCreated':
        if (_onCategoryCreatedCallback != null) {
          _onCategoryCreatedCallback!(
            arguments['landmarkStoreId'],
            arguments['categoryId'],
          );
        }

      case 'onCategoryUpdated':
        if (_onCategoryUpdatedCallback != null) {
          _onCategoryUpdatedCallback!(
            arguments['landmarkStoreId'],
            arguments['categoryId'],
          );
        }

      case 'onCategoryRemoved':
        if (_onCategoryRemovedCallback != null) {
          _onCategoryRemovedCallback!(
            arguments['landmarkStoreId'],
            arguments['categoryId'],
          );
        }

      case 'onLandmarkStoreCreated':
        if (_onLandmarkStoreCreatedCallback != null) {
          _onLandmarkStoreCreatedCallback!(arguments['landmarkStoreId']);
        }

      case 'onLandmarkStoreRegistered':
        if (_onLandmarkStoreRegisteredCallback != null) {
          _onLandmarkStoreRegisteredCallback!(arguments['landmarkStoreId']);
        }

      case 'onLandmarkStoreRemoved':
        if (_onLandmarkStoreRemovedCallback != null) {
          _onLandmarkStoreRemovedCallback!(arguments['landmarkStoreId']);
        }

      case 'onBrowseSessionInvalidated':
        if (_onBrowseSessionInvalidatedCallback != null) {
          _onBrowseSessionInvalidatedCallback!(
            arguments['landmarkStoreId'],
            arguments['sessionId'],
          );
        }

      default:
        gemSdkLogger.log(
          Level.WARNING,
          'Unknown event subtype: $eventSubtype in LandmarkStoreListener',
        );
    }
  }
}
