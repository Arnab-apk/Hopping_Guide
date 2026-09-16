// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Collection managing routes displayed on a map view.
///
/// [MapViewRoutesCollection] stores and manages routes displayed by a map instance. Use the
/// [MapViewPreferences.routes] getter to obtain the collection for a given map.
///
/// The collection supports adding routes (one main route and zero or more secondary routes), updating render
/// settings and labels, centering the camera on displayed routes, and removing routes.
///
/// ## Example
/// ```dart
/// controller.preferences.routes.add(route, true);
/// ```
///
/// ## See also:
///
/// - [MapViewPreferences.routes] — Obtain the routes collection for a map.
/// - [RouteRenderSettings] — Customize the visual appearance of routes.
/// - [Route] — The objects used for routing, analysis and navigation.
///
/// {@category Maps & 3D Scenes}
class MapViewRoutesCollection extends GemList<Route> {
  MapViewRoutesCollection(final dynamic id, final int mapPointerId)
    : _mapPointerId = mapPointerId,
      super(
        id,
        'MapViewRouteCollection',
        (final dynamic data) => Route.init(data),
      ) {
    super.registerAutoReleaseObject(id);
  }

  // ignore: unused_element
  MapViewRoutesCollection._()
    : _mapPointerId = -1,
      super(
        0,
        'MapViewRouteCollection',
        (final dynamic data) => Route.init(data),
      );

  @internal
  MapViewRoutesCollection.init(final int id, final int mapPointerId)
    : _mapPointerId = mapPointerId,
      super(
        id,
        'MapViewRouteCollection',
        (final dynamic data) => Route.init(data),
        dependencyId: mapPointerId,
      ) {
    super.registerAutoReleaseObject(id);
    hasInit = true;
  }
  bool hasInit = false;

  final int _mapPointerId;
  int get mapPointerId => _mapPointerId;

  /// Add or update a route in the collection with optional render settings and label.
  ///
  /// Adds the provided [route] to the collection. If [bMainRoute] is `true` the added route becomes the
  /// main route (rendered prominently); otherwise it is treated as a secondary/alternative route. When a
  /// route is already present in the collection this method updates its display settings.
  ///
  /// ## Parameters
  ///
  /// - [route]: the [Route] to add or update in the collection.
  /// - [bMainRoute]: `true` to set the route as the main route; `false` to add it as an alternative.
  /// - [label]: optional text label shown on the route (for example ETA or distance).
  /// - [labelIcons]: optional list of up to two `Img` icons displayed inside the label. Use
  ///   `SdkSettings.getImgById(GemIcon.<name>.id)` to obtain images.
  /// - [routeRenderSettings]: optional [RouteRenderSettings] to customize route appearance. When omitted a
  ///   default [RouteRenderSettings] is used. All sizes in [RouteRenderSettings] are measured in millimetres.
  /// - [autoGenerateLabel]: when `true` the SDK automatically generates a label (overrides `label` and
  ///   `labelIcons`).
  ///
  /// ## See also:
  ///
  /// - [RouteRenderSettings] — Customize the visual appearance of routes.
  /// - [Route] — The objects used for routing, analysis and navigation.
  /// - [SdkSettings.getImgById] - Obtain images for [labelIcons].
  void add(
    final Route route,
    final bool bMainRoute, {
    final String? label,
    final List<Img>? labelIcons,
    RouteRenderSettings? routeRenderSettings,
    final bool autoGenerateLabel = false,
  }) {
    routeRenderSettings ??= RouteRenderSettings();

    if (bMainRoute) {
      routeRenderSettings.options = <RouteRenderOptions>{
        RouteRenderOptions.main,
        ...routeRenderSettings.options,
      };
    }

    objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'add',
      args: <String, dynamic>{
        'route': route.pointerId,
        'bMainRoute': bMainRoute,
        'routeRenderSettings': routeRenderSettings,
        'autoGenerateLabel': autoGenerateLabel,
        if (label != null) 'label': label,
        'labelIcons': labelIcons != null
            ? ImageList.fromList(labelIcons).pointerId
            : ImageList().pointerId,
      },
      dependencyId: mapPointerId,
    );
  }

  /// Add or update a [MapViewRoute] instance in the collection.
  ///
  /// Use this overload when you already have a [MapViewRoute] object. When the route is present the
  /// existing entry is updated with the values from [route].
  ///
  /// ## Parameters
  ///
  /// - [route]: the [MapViewRoute] to add or update in the collection.
  ///
  /// ## See also:
  ///
  /// - [MapViewRoute] — The route with render settings and label as shown on the map.
  /// - [add] — Add a route with detailed parameters.
  void addMapViewRoute(final MapViewRoute route) {
    objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'add',
      args: route.pointerId,
      dependencyId: mapPointerId,
    );
  }

  /// Remove all routes from the collection.
  ///
  /// After calling this method the map will no longer display any routes managed by this collection.
  ///
  /// ## See also:
  ///
  /// - [clearAllButMainRoute] — Remove all secondary routes, leaving the main route in the collection.
  void clear() {
    objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'clear',
      dependencyId: mapPointerId,
    );
  }

  /// Remove all secondary routes, leaving the main route in the collection.
  ///
  /// Useful when you want to keep the currently selected main route visible while removing alternative
  /// suggestions.
  ///
  /// ## See also:
  ///
  /// - [clear] — Remove all routes from the collection.
  void clearAllButMainRoute() {
    objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'clearAllButMainRoute',
      dependencyId: mapPointerId,
    );
  }

  /// Retrieve the label text currently shown for [route].
  ///
  /// ## Parameters
  ///
  /// - [route]: the [Route] whose label will be returned.
  ///
  /// ## Returns
  ///
  /// - `String`: current label text for the route (may be empty).
  String getLabel(final Route route) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'getLabel',
      args: route.pointerId,
      dependencyId: mapPointerId,
    );

    return resultString['result'];
  }

  /// The current main route in the collection, if any.
  ///
  /// ## Returns
  ///
  /// - [Route]?: the main route, or `null` when there is no main route set.
  Route? get mainRoute {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'getMainRoute',
      dependencyId: mapPointerId,
    );

    final dynamic result = resultString['result'];
    if (result['empty'] == true) {
      return null;
    }
    return Route.init(result['oid']);
  }

  /// Get the [MapViewRoute] wrapper for the route at [index].
  ///
  /// ## Parameters
  ///
  /// - [index]: zero-based index of the map view route in this collection.
  ///
  /// ## Returns
  ///
  /// - [MapViewRoute]?: wrapper object for the route at the given index, or `null` if none exists.
  ///
  /// ## See also:
  ///
  /// - [MapViewRoute] — The route with rendersettings and label as shown on the map.
  /// - [getRoute] — Get the underlying route object at the given index.
  /// - [length] — The number of routes in the collection.
  MapViewRoute? getMapViewRoute(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'getMapViewRoute',
      args: index,
      dependencyId: mapPointerId,
    );

    if (resultString['gemApiError'] == -11) {
      return null;
    }
    return MapViewRoute.init(resultString['result'], this);
  }

  /// Get the [Route] object present at [index] in the collection.
  ///
  /// ## Parameters
  ///
  /// - [index]: zero-based index of the route in the collection.
  ///
  /// ## Returns
  ///
  /// - [Route]?: the route at the given index, or `null` when the index is invalid.
  ///
  /// ## See also:
  ///
  /// - [length] — The number of routes in the collection.
  /// - [getMapViewRoute] — Obtain the map view wrapper for the route at the given index.
  Route? getRoute(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'getRoute',
      args: index,
      dependencyId: mapPointerId,
    );

    final dynamic result = resultString['result'];
    if (result['empty'] == true) {
      return null;
    }
    return Route.init(result['oid']);
  }

  /// Hide the label for [route].
  ///
  /// Use this method to programmatically remove the visible label from a route previously added to the
  /// collection.
  ///
  /// ## Parameters
  ///
  /// - [route]: route whose label will be hidden.
  ///
  /// ## Also see:
  ///
  /// - [clear] — Remove all routes from the collection.
  void hideLabel(final Route route) {
    objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'hideLabel',
      args: route.pointerId,
      dependencyId: mapPointerId,
    );
  }

  /// Get the index of [route] in the collection.
  ///
  /// ## Parameters
  ///
  /// - [route]: the route to search for.
  ///
  /// ## Returns
  ///
  /// - `int`: zero-based index of the route, or [GemError.notFound].code (negative) when the route is not found.
  int indexOf(final Route route) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'indexOf',
      args: route.pointerId,
      dependencyId: mapPointerId,
    );

    return resultString['result'];
  }

  /// Check whether [route] is marked as the main route in the collection.
  ///
  /// ## Parameters
  ///
  /// - [route]: the route to check.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when the route is the current main route; otherwise `false`.
  ///
  /// ## See also:
  ///
  /// - [mainRoute] — The current main route in the collection, if any.
  bool isMainRoute(final Route route) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'isMainRoute',
      args: route.pointerId,
      dependencyId: mapPointerId,
    );

    return resultString['result'];
  }

  /// Set the label text for [route].
  ///
  /// The label supports embedding up to two icons using the placeholder syntax `%<index>%`. For example:
  /// `'Header %%0%%\n%%1%% Footer'` where `0` and `1` are indices into the `labelIcons` list previously
  /// attached to the route.
  ///
  /// ## Parameters
  ///
  /// - [route]: the route whose label will be updated.
  /// - [text]: label text to set. Use icon placeholders to embed icons.
  ///
  /// ## Also see:
  ///
  /// - [hideLabel] — Hide the label for a route.
  void setLabel(final Route route, final String text) {
    objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'setLabel',
      args: <String, dynamic>{'route': route.pointerId, 'label': text},
      dependencyId: mapPointerId,
    );
  }

  /// Set the route as the main route in the collection.
  ///
  /// Does not work unless the route is already in the collection.
  ///
  /// ## Parameters
  ///
  /// - [route]: The route to be set as the main route.
  set mainRoute(final Route? route) {
    if (route == null) {
      ApiErrorServiceImpl.apiErrorAsInt = GemError.invalidInput.code;
      return;
    }

    objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'setMainRoute',
      args: route.pointerId,
      dependencyId: mapPointerId,
    );
  }

  /// Remove the route from the collection.
  ///
  /// ## Parameters
  ///
  /// - [route]: The route to be removed.
  void remove(final Route route) {
    objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'remove',
      args: route.pointerId,
      dependencyId: mapPointerId,
    );
  }

  /// Set route render settings.
  ///
  /// ## Parameters
  ///
  /// - [route]: The route whose render settings should be set.
  /// - [settings]: The render settings to apply.
  void setRenderSettings(
    final Route route,
    final RouteRenderSettings settings,
  ) {
    objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'setRenderSettings',
      args: <String, dynamic>{
        'route': route.pointerId,
        'routeRenderSettings': settings,
      },
      dependencyId: mapPointerId,
    );
  }

  /// Get the route custom render settings (read-only).
  ///
  /// ## Parameters
  ///
  /// - [route]: The route for which the render settings are requested.
  ///
  /// ## Returns
  ///
  /// - [RouteRenderSettings]?: object if the route is in the collection, `null` otherwise.
  RouteRenderSettings? getRenderSettings(final Route route) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewRouteCollection',
      'getRenderSettings',
      args: route.pointerId,
      dependencyId: mapPointerId,
    );

    if (resultString['gemApiError'] == -15) {
      return null;
    }
    return RouteRenderSettings.fromJson(resultString['result']);
  }

  @override
  void dispose() {
    GemKitPlatform.instance.callDeleteObject(
      jsonEncode(<String, dynamic>{
        'class': 'MapViewRouteCollection',
        'id': pointerId,
      }),
    );
  }
}

/// Wrapper representing the [Route], [RenderSettings] and label as displayed on the map view.
///
/// [MapViewRoute] provides convenient accessors to control and inspect the route's visual appearance
/// and label. Obtain instances from [MapViewRoutesCollection.getMapViewRoute].
///
/// Do not construct this class directly.
///
/// ## See also:
///
/// - [MapViewRoutesCollection] — collection managing displayed routes.
/// - [RouteRenderSettings] — customize rendering options for the route.
/// - [Route] — The objects used for routing, analysis and navigation.
///
/// {@category Maps & 3D Scenes}
class MapViewRoute extends GemAutoreleaseObject {
  // ignore: unused_element
  MapViewRoute._() : super(-1);

  @internal
  MapViewRoute.init(
    super.id,
    final MapViewRoutesCollection mapViewRouteCollection,
  ) : _mapViewRouteCollection = mapViewRouteCollection;

  late MapViewRoutesCollection _mapViewRouteCollection;

  /// Label text currently shown for this map view route.
  ///
  /// ## Returns
  ///
  /// - `String`: the label text displayed for the route. Returns an empty string when no label is set.
  ///
  /// ## See also:
  ///
  /// - [MapViewRoutesCollection.getLabel] — Retrieve the label text for a given route.
  String get labelText {
    return _mapViewRouteCollection.getLabel(route);
  }

  /// Current render settings applied to this route.
  ///
  /// ## Returns
  ///
  /// - [RouteRenderSettings]: the custom render settings for this map view route.
  RouteRenderSettings get renderSettings {
    return _mapViewRouteCollection.getRenderSettings(route)!;
  }

  /// The underlying [Route] object represented by this map view entry.
  ///
  /// ## Returns
  ///
  /// - [Route]: the route model used for routing, analysis and navigation.
  ///
  /// ## See also:
  ///
  /// - [MapViewRoutesCollection.getRoute] — Get the underlying route object at the given index.
  Route get route {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapViewRoute',
      'getRoute',
    );

    return Route.init(resultString['result']);
  }

  /// Hide the route label for this map view route.
  ///
  /// ## See also:
  ///
  /// - [MapViewRoutesCollection.hideLabel] — Hide the label for a route.
  void hideLabel() {
    _mapViewRouteCollection.hideLabel(route);
  }

  /// Update the label text for this route.
  ///
  /// ## Parameters
  ///
  /// - [text]: label text to set. Use icon placeholders `%<index>%` to embed icons previously supplied
  ///   via `labelIcons` when the route was added.
  ///
  /// ## Also see:
  ///
  /// - [MapViewRoutesCollection.setLabel] — Set the label text for a given route.
  set labelText(final String text) {
    _mapViewRouteCollection.setLabel(route, text);
  }

  /// Update the render settings for this route.
  ///
  /// ## Parameters
  ///
  /// - [settings]: new [RouteRenderSettings] to apply to the route. All dimensional values are in
  ///   millimetres.
  ///
  /// ## See also:
  ///
  /// - [MapViewRoutesCollection.setRenderSettings] — Set route render settings.
  set renderSettings(final RouteRenderSettings settings) {
    _mapViewRouteCollection.setRenderSettings(route, settings);
  }
}
