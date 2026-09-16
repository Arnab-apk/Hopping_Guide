// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:typed_data';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Manages collections of markers displayed on a map view.
///
/// [MapViewMarkerCollections] provides the entry point for adding, removing and
/// querying collections of markers that are rendered on a [GemMap].
///
/// Do not construct this class directly — obtain an instance from
/// [MapViewPreferences.markers]. It also exposes access to the three singleton
/// [MarkerSketches] collections (one per marker type) used for per-marker render
/// settings.
///
/// ## Example:
/// ```dart
/// final collection = MarkerCollection(markerType: MarkerType.point, name: 'POIs');
/// collection.add(Marker()..add(Coordinates(latitude: 52.0, longitude: 4.0)));
/// controller.preferences.markers.add(collection);
/// ```
///
/// ## See also:
/// - [MarkerCollection] for managing groups of markers.
/// - [MarkerSketches] for special collections allowing per-marker render customizations.
/// - [MarkerCollectionRenderSettings] for customizing the appearance of marker collections.
/// - [MarkerRenderSettings] for per-marker render customizations.
///
/// {@category Maps & 3D Scenes}
class MapViewMarkerCollections extends GemAutoreleaseObject {
  // ignore: unused_element
  MapViewMarkerCollections._() : _mapId = -1, _mapPointerId = -1, super(-1);

  @internal
  MapViewMarkerCollections.init(
    super.id,
    final int mapId,
    final dynamic mapPointerId,
  ) : _mapId = mapId,
      _mapPointerId = mapPointerId;

  final int _mapId;
  final dynamic _mapPointerId;
  int get mapId => _mapId;
  Map<int, ExternalRendererMarkers> externalRenderers =
      <int, ExternalRendererMarkers>{};

  /// Add a marker collection to the map view.
  ///
  /// The collection will be displayed using the provided [settings], unless an
  /// external renderer is supplied. When [externalRender] is given the collection
  /// will be delegated to an external rendering engine (experimental).
  ///
  /// ## Parameters
  ///
  /// - [col]: The [MarkerCollection] to add.
  /// - [settings]: Optional [MarkerCollectionRenderSettings] that control the
  ///   collection appearance. If omitted, default settings are used.
  /// - [externalRender]: Optional experimental [ExternalRendererMarkers] which
  ///   will handle rendering for this collection.
  void add(
    final MarkerCollection col, {
    MarkerCollectionRenderSettings? settings,
    @experimental final ExternalRendererMarkers? externalRender,
  }) {
    settings ??= MarkerCollectionRenderSettings();
    if (externalRender != null) {
      externalRenderers[col.id] = externalRender;
    }
    final bool hasExternalRender = externalRender != null;
    objectMethod(
      pointerId,
      'MapViewMarkerCollections',
      'add',
      args: <String, Object>{
        'col': col.pointerId,
        'settings': settings,
        if (externalRender != null) 'externalRender': hasExternalRender,
        'maxzoomlevel': 10,
      },
      dependencyId: _mapPointerId,
    );
  }

  /// Add a large list of markers to the map efficiently.
  ///
  /// Accepts a list of [MarkerWithRenderSettings] together with a
  /// single [MarkerCollectionRenderSettings] and a collection [name]. It is
  /// optimized for bulk insertion (useful when adding thousands of markers).
  ///
  /// ## Parameters
  ///
  /// - [list]: A list of [MarkerWithRenderSettings] to add.
  /// - [settings]: Global [MarkerCollectionRenderSettings] applied to the
  ///   collection.
  /// - [name]: Desired name for the created collection.
  /// - [markerType]: Optional [MarkerType] for the created collection.
  ///
  /// ## Returns
  ///
  /// - A [Future<List<int>>] that completes with the ids of the added markers.
  Future<List<int>> addList({
    required final List<MarkerWithRenderSettings> list,
    required final MarkerCollectionRenderSettings settings,
    required final String name,
    final MarkerType markerType = MarkerType.point,
  }) async {
    final dynamic jsonResponse = await GemKitPlatform.instance.addList(
      object: this,
      list: list,
      settings: settings,
      name: name,
      parentMapId: _mapPointerId,
      markerType: markerType,
    );
    final Map<String, dynamic> parsedResponse = jsonDecode(jsonResponse);
    final List<int> resultList = List<int>.from(parsedResponse['result']);
    return resultList;
  }

  /// Returns whether [col] is currently present in this [MapViewMarkerCollections].
  ///
  /// ## Parameters
  ///
  /// - [col]: The [MarkerCollection] to check for.
  ///
  /// ## Returns
  ///
  /// - `true` when the collection is present, otherwise `false`.
  bool contains(final MarkerCollection col) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewMarkerCollections',
      'contains',
      args: col.pointerId,
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Retrieve the [MarkerCollection] at [index].
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the collection to retrieve.
  ///
  /// ## Returns
  ///
  /// - A [MarkerCollection] instance for the requested index if the index is valid,
  ///  otherwise `null`.
  MarkerCollection? getCollectionAt(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewMarkerCollections',
      'getCollectionAt',
      args: index,
      dependencyId: _mapPointerId,
    );

    final int result = resultString['result'];
    if (result == -1) {
      return null;
    }
    return MarkerCollection.init(result, _mapId);
  }

  /// Perform a hit test across all marker collections at the given [coordinates].
  ///
  /// ## Parameters
  ///
  /// - [coordinates]: The geographic coordinates to test.
  ///
  /// ## Returns
  ///
  /// - A [List<MarkerMatch>] describing matches found at the location.
  List<MarkerMatch> hitTest(final Coordinates coordinates) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewMarkerCollections',
      'hitTest',
      args: coordinates,
      dependencyId: _mapPointerId,
    );

    return MarkerMatchList.init(resultString['result']).toList();
  }

  /// Return the index of [col] inside the map view collections.
  ///
  /// ## Parameters
  ///
  /// - [col]: The [MarkerCollection] to search for.
  ///
  /// ## Returns
  ///
  /// - The collection index on success, or a [GemError] code (e.g. [GemError.notFound].code) on error.
  int indexOf(final MarkerCollection col) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewMarkerCollections',
      'indexOf',
      args: col.pointerId,
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Returns true when [coll] is one of the internal [MarkerSketches] collections.
  ///
  /// ## Parameters
  ///
  /// - [coll]: The [MarkerCollection] to inspect.
  ///
  /// ## Returns
  ///
  /// - `true` if the collection is a sketches collection, otherwise `false`.
  bool isSketches(final MarkerCollection coll) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewMarkerCollections',
      'isSketches',
      args: coll.pointerId,
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Return the singleton [MarkerSketches] collection for a given [type].
  ///
  /// The returned [MarkerSketches] instance allows per-marker render customizations
  /// and does not need to be added to [MapViewMarkerCollections].
  ///
  /// ## Parameters
  ///
  /// - [type]: The [MarkerType] whose sketches collection is requested.
  ///
  /// ## Returns
  ///
  /// - The corresponding [MarkerSketches] singleton instance.
  MarkerSketches getSketches(MarkerType type) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewMarkerCollections',
      'sketches',
      args: type.id,
      dependencyId: _mapPointerId,
    );

    return MarkerSketches.init(resultString['result'], 0);
  }

  @internal
  void onMarkerRender(
    final GemMapController mapController,
    final dynamic data,
  ) => externalRenderers[data['sourceId']]!.processData(mapController, data);

  @internal
  void onViewRendered(final dynamic data) {
    if (data['markersIds']!.length > 0) {
      final List<dynamic> markersIds = data['markersIds'];
      final List<dynamic> sourcesIds = data['sourcesIds'];
      for (int i = 0; i < markersIds.length; ++i) {
        externalRenderers[sourcesIds.elementAt(i)]!.removeData(markersIds[i]);
      }
    }
    externalRenderers[data['sourceId']]?.onNotifyCustom!(2);
  }

  /// Remove the collection at [index] from the map view.
  ///
  /// ## Parameters
  ///
  /// - [index]: Index of the collection to remove.
  void removeAt(final int index) {
    objectMethod(
      pointerId,
      'MapViewMarkerCollections',
      'remove',
      args: index,
      dependencyId: _mapPointerId,
    );
  }

  /// Apply render [settings] to the collection at [index].
  ///
  /// ## Parameters
  ///
  /// - [index]: Index of the collection to update.
  /// - [settings]: The [MarkerCollectionRenderSettings] to apply.
  ///
  /// ## Returns
  ///
  /// - A [GemError] indicating success or the failure reason.
  GemError setRenderSettings(
    final int index,
    final MarkerCollectionRenderSettings settings,
  ) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewMarkerCollections',
      'setRenderSettings',
      args: <String, Object>{'index': index, 'settings': settings},
      dependencyId: _mapPointerId,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Number of marker collections currently managed by the map view.
  ///
  /// ## Returns
  ///
  /// - The integer count of collections.
  int get size {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewMarkerCollections',
      'size',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Remove all marker collections from the map view.
  ///
  /// ## Returns
  ///
  /// - A [Future] that completes when the operation has finished.
  Future<void> clear() async {
    await GemKitPlatform.instance
        .getChannel(mapId: _mapId)
        .invokeMethod<String>(
          'callObjectMethod',
          jsonEncode(<String, dynamic>{
            'id': pointerId,
            'class': 'MapViewMarkerCollections',
            'method': 'clear',
            'args': <String, dynamic>{},
          }),
        );
  }

  /// Serialize all marker collections to a binary buffer.
  ///
  /// ## Returns
  ///
  /// - A [Uint8List] containing the serialized data on success, or `null` on error.
  ///
  /// ## See also:
  ///
  /// - [load] for restoring marker collections from a serialized buffer.
  Uint8List? save() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewMarkerCollections',
      'save',
    );

    if (resultString['gemApiError'] != 0) {
      return null;
    }

    final String encodedResult = resultString['result'];
    final Uint8List resultAsUint8List = base64Decode(encodedResult);
    return resultAsUint8List;
  }

  /// Restore marker collections from a previously serialized buffer.
  ///
  /// ## Parameters
  ///
  /// - [buffer]: The binary buffer produced by [save].
  ///
  /// ## Returns
  ///
  /// - A [GemError] code indicating success or the failure reason.
  ///
  /// ## See also:
  ///
  /// - [save] for obtaining a serialized buffer of the current marker collections.
  GemError load(Uint8List buffer) {
    final dynamic dataBufferPointer = GemKitPlatform.instance.toNativePointer(
      buffer,
    );
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewMarkerCollections',
      'load',
      args: <String, dynamic>{
        'dataBuffer': dataBufferPointer.address,
        'dataBufferSize': buffer.length,
      },
    );
    return GemErrorExtension.fromCode(resultString['result']);
  }
}
