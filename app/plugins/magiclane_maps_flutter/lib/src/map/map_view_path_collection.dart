// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/extensions.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Collection of paths for a map view.
///
/// Provides a managed collection of [Path] objects that are displayed on a map view.
/// Use [MapViewPreferences.paths] to obtain the collection of visible [Path] entities for a map.
///
/// ## See also:
///
/// - [MapViewPreferences.paths] method to get the path collection
/// - [Path] class to represent a path
///
/// {@category Maps & 3D Scenes}
class MapViewPathCollection extends GemAutoreleaseObject {
  // ignore: unused_element
  MapViewPathCollection._() : _mapId = -1, _mapPointerId = -1, super(-1);

  @internal
  MapViewPathCollection.init(super.id, final int mapId, final int mapPointerId)
    : _mapId = mapId,
      _mapPointerId = mapPointerId;

  final int _mapId;
  final int _mapPointerId;

  int get mapId => _mapId;
  int get mapPointerId => _mapPointerId;

  /// Adds a [Path] to this collection with optional visual styling.
  ///
  /// The path will be rendered using the provided colors and sizes. When a size
  /// parameter is negative the current map view style's default size is used.
  ///
  /// ## Parameters
  ///
  /// - [path]: The [Path] to add to the collection.
  /// - [colorBorder]: Optional border color. Defaults to the map view style's border color.
  /// - [colorInner]: Optional inner/fill color. Defaults to the map view style's inner color.
  /// - [szBorder]: Border size in millimeters. If < 0 the style default is used.
  /// - [szInner]: Inner size in millimeters. If < 0 the style default is used.
  void add(
    final Path path, {
    final Color colorBorder = const Color(0x00000000),
    final Color colorInner = const Color(0x00000000),
    final double szBorder = -1,
    final double szInner = -1,
  }) {
    objectMethod(
      pointerId,
      'MapViewPathCollection',
      'add',
      args: <String, Object>{
        'path': path.pointerId,
        'colorBorder': colorBorder.toRgba(),
        'colorInner': colorInner.toRgba(),
        'szBorder': szBorder,
        'szInner': szInner,
      },
      dependencyId: _mapPointerId,
    );
  }

  /// Removes all paths from this collection.
  ///
  /// Use this to clear the map of all displayed paths.
  ///
  /// ## See also:
  ///
  /// - [remove] to remove a specific [Path].
  /// - [removeAt] to remove a path by index.
  /// {@category Core}
  void clear() {
    objectMethod(
      pointerId,
      'MapViewPathCollection',
      'clear',
      dependencyId: _mapPointerId,
    );
  }

  /// Returns the border color for the path at [index].
  ///
  /// If the index is invalid the method returns [Colors.transparent].
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the path in the collection.
  ///
  /// ## Returns
  ///
  /// - The border [Color] for the given path, or [Colors.transparent] if the index is out of range.
  Color getBorderColorAt(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewPathCollection',
      'getBorderColorAt',
      args: index,
      dependencyId: _mapPointerId,
    );

    return ColorExtension.fromJson(resultString['result']);
  }

  /// Returns the border size (in millimeters) for the path at [index].
  ///
  /// If the index is invalid this method returns `-1`.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the path.
  ///
  /// ## Returns
  ///
  /// - The border size in millimeters, or `-1` when the index is invalid.
  double getBorderSizeAt(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewPathCollection',
      'getBorderSizeAt',
      args: index,
      dependencyId: _mapPointerId,
    );
    return resultString['result'];
  }

  /// Returns the inner (fill) color for the path at [index].
  ///
  /// If the index is invalid the method returns [Colors.transparent].
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the path.
  ///
  /// ## Returns
  ///
  /// - The inner [Color] for the path, or [Colors.transparent] if not found.
  Color getFillColorAt(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewPathCollection',
      'getFillColorAt',
      args: index,
      dependencyId: _mapPointerId,
    );

    return ColorExtension.fromJson(resultString['result']);
  }

  /// Returns the inner size (in millimeters) for the path at [index].
  ///
  /// If the index is invalid this method returns `-1`.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the path.
  ///
  /// ## Returns
  ///
  /// - The inner size in millimeters, or `-1` when the index is invalid.
  double getInnerSizeAt(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewPathCollection',
      'getInnerSizeAt',
      args: index,
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Retrieves the [Path] at [index], or `null` if the index is out of range.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the path to retrieve.
  ///
  /// ## Returns
  ///
  /// - The [Path] instance for the given index, or `null` when not found.
  Path? getPathAt(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewPathCollection',
      'getPathAt',
      args: index,
      dependencyId: _mapPointerId,
    );

    if (resultString['result'] == -1) {
      return null;
    }
    return Path.init(resultString['result']);
  }

  /// Finds a [Path] in the collection by its [name].
  ///
  /// ## Parameters
  ///
  /// - [name]: The name of the path to search for.
  ///
  /// ## Returns
  ///
  /// - The matching [Path], or `null` if no path with this name exists.
  Path? getPathByName(final String name) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewPathCollection',
      'getPathByName',
      args: name,
      dependencyId: _mapPointerId,
    );

    if (resultString['result'] == -1) {
      return null;
    }
    return Path.init(resultString['result']);
  }

  /// Returns the index of the path with the given [name] in the collection.
  ///
  /// ## Parameters
  ///
  /// - [name]: The name of the path to search for.
  ///
  /// ## Returns
  ///
  /// - The zero-based index of the matching path, or `-1` if no path with this
  ///   name exists in the collection.
  int getPathIndexByName(final String name) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewPathCollection',
      'getPathIndexByName',
      args: name,
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// The number of [Path] objects currently in this collection.
  ///
  /// ## Returns
  ///
  /// - An integer count of paths.
  int get size {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewPathCollection',
      'size',
      dependencyId: _mapPointerId,
    );

    return resultString['result'];
  }

  /// Removes [path] from this collection if present.
  ///
  /// ## Parameters
  ///
  /// - [path]: The [Path] instance to remove.
  void remove(final Path path) {
    objectMethod(
      pointerId,
      'MapViewPathCollection',
      'remove',
      args: path.pointerId,
      dependencyId: _mapPointerId,
    );
  }

  /// Removes the path at [index] from the collection.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the path to remove.
  void removeAt(final int index) {
    objectMethod(
      pointerId,
      'MapViewPathCollection',
      'removeAt',
      args: index,
      dependencyId: _mapPointerId,
    );
  }

  /// Performs a hit test to find paths within the specified [area].
  ///
  /// Returns a list of [PathMatch] entries describing matches found inside
  /// the geographic rectangle.
  ///
  /// ## Parameters
  ///
  /// - [area]: The [RectangleGeographicArea] to test.
  ///
  /// ## Returns
  ///
  /// - A [List<PathMatch>] containing matched paths and their match details.
  List<PathMatch> hitTest(final RectangleGeographicArea area) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewPathCollection',
      'hitTest',
      args: area,
      dependencyId: _mapPointerId,
    );

    return resultString['result']
        .map<PathMatch>((final dynamic e) => PathMatch.fromJson(e))
        .toList();
  }
}
