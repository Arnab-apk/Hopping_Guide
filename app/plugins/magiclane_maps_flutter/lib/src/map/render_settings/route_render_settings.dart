// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:flutter/material.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/extensions.dart';
import 'package:meta/meta.dart';

/// Additional rendering settings used to customize how routes are displayed on the map.
///
/// A [RouteRenderSettings] object extends [RenderSettings] with route-specific options such as
/// colors for the traveled portion of the route, turn arrow styling, waypoint text sizing and a
/// fill color for the route polygon. Sizes are expressed in millimetres. Use an instance of this
/// class when adding a route via [MapViewRoutesCollection.add] or when updating an existing route's
/// appearance through [MapViewRoute.renderSettings] or [MapViewRoutesCollection.setRenderSettings].
///
/// ## Example
///
/// ```dart
/// final renderSettings = RouteRenderSettings(
///   innerColor: Colors.black,
///   fillColor: Colors.purple,
///   lineType: LineType.dashed,
/// );
/// controller.preferences.routes.getMapViewRoute(0)!.renderSettings = renderSettings;
/// ```
///
/// ## See also:
///
/// - [MapViewRoutesCollection.add] — Add a route with custom render settings.
/// - [MapViewRoute.renderSettings] — Access or update a route's render settings.
///
/// {@category Maps & 3D Scenes}
class RouteRenderSettings extends RenderSettings<RouteRenderOptions> {
  /// Create a new set of route render settings.
  ///
  /// The constructor initializes route rendering properties with sensible defaults. Provide any
  /// parameters you want to override. Sizes are in millimetres.
  ///
  /// ## Parameters
  ///
  /// - [options]: Which route elements to display (for example [RouteRenderOptions.showTraffic]).
  /// - [innerColor]: Color for the inner part of the route line.
  /// - [outerColor]: Color for the outer part of the route line.
  /// - [innerSz]: Inner size of the route line in millimetres.
  /// - [outerSz]: Outer size of the route line in millimetres.
  /// - [lineType]: Style of the route line (solid, dashed, etc.).
  /// - [imgSz]: Size for route-related images in millimetres.
  /// - [textSz]: Size for route text in millimetres.
  /// - [textColor]: Color for route text.
  /// - [traveledInnerColor]: Color for the traveled portion of the route.
  /// - [turnArrowInnerColor]: Inner color for turn arrows.
  /// - [turnArrowOuterColor]: Outer color for turn arrows.
  /// - [turnArrowInnerSz]: Inner size for turn arrows in millimetres.
  /// - [turnArrowOuterSz]: Outer size for turn arrows in millimetres.
  /// - [waypointTextSz]: Text size for waypoint labels in millimetres.
  /// - [waypointTextInnerColor]: Inner color for waypoint text.
  /// - [waypointTextOuterColor]: Outer color for waypoint text.
  /// - [fillColor]: Fill color used for route polygons.
  /// - [directionArrowInnerColor]: Inner color for direction arrows.
  /// - [directionArrowOuterColor]: Outer color for direction arrows.
  RouteRenderSettings({
    super.options = const <RouteRenderOptions>{
      RouteRenderOptions.showTraffic,
      RouteRenderOptions.showTurnArrows,
      RouteRenderOptions.showWaypoints,
      RouteRenderOptions.showHighlights,
    },
    super.innerColor = RenderSettings.defaultInnerColor,
    super.outerColor = RenderSettings.defaultOuterColor,
    super.innerSz = RenderSettings.defaultInnerSize,
    super.outerSz = RenderSettings.defaultOuterSize,
    super.lineType = RenderSettings.defaultLineType,
    super.imgSz = RenderSettings.defaultImageSize,
    super.textSz = RenderSettings.defaultTextSize,
    super.textColor = RenderSettings.defaultTextColor,
    this.traveledInnerColor = Colors.transparent,
    this.turnArrowInnerColor = Colors.transparent,
    this.turnArrowOuterColor = Colors.transparent,
    this.turnArrowInnerSz = RenderSettings.defaultInnerSize,
    this.turnArrowOuterSz = RenderSettings.defaultOuterSize,
    this.waypointTextSz = RenderSettings.defaultTextSize,
    this.waypointTextInnerColor = Colors.transparent,
    this.waypointTextOuterColor = Colors.transparent,
    this.fillColor = Colors.transparent,
    this.directionArrowInnerColor = Colors.transparent,
    this.directionArrowOuterColor = Colors.transparent,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory RouteRenderSettings.fromJson(final Map<String, dynamic> json) {
    final Set<RouteRenderOptions> loptions = <RouteRenderOptions>{};
    final int id = json['options'];
    for (final RouteRenderOptions option in RouteRenderOptions.values) {
      if (id & option.id != 0) {
        loptions.add(option);
      }
    }

    return RouteRenderSettings(
      traveledInnerColor: ColorExtension.tryFromJson(
        json['traveledInnerColor'],
      ),
      turnArrowInnerColor: ColorExtension.tryFromJson(
        json['turnArrowInnerColor'],
      ),
      turnArrowOuterColor: ColorExtension.tryFromJson(
        json['turnArrowOuterColor'],
      ),
      turnArrowInnerSz:
          json['turnArrowInnerSz'] ?? RenderSettings.defaultInnerSize,
      turnArrowOuterSz:
          json['turnArrowOuterSz'] ?? RenderSettings.defaultOuterSize,
      fillColor: ColorExtension.tryFromJson(json['fillColor']),
      waypointTextSz: json['waypointTextSz'] ?? RenderSettings.defaultTextSize,
      waypointTextInnerColor: ColorExtension.tryFromJson(
        json['waypointTextInnerColor'],
      ),
      waypointTextOuterColor: ColorExtension.tryFromJson(
        json['waypointTextOuterColor'],
      ),
      lineType: LineTypeExtension.fromId(
        json['lineType'] ?? RenderSettings.defaultLineType.id,
      ),
      imgSz: json['imgSz'] ?? RenderSettings.defaultImageSize,
      innerColor: ColorExtension.tryFromJson(json['innerColor']),
      outerColor: ColorExtension.tryFromJson(json['outerColor']),
      innerSz: json['innerSz'] ?? RenderSettings.defaultInnerSize,
      outerSz: json['outerSz'] ?? RenderSettings.defaultOuterSize,
      textSz: json['textSz'] ?? RenderSettings.defaultTextSize,
      textColor: ColorExtension.tryFromJson(json['textColor']),
      options: loptions,
      directionArrowInnerColor: ColorExtension.tryFromJson(
        json['directionArrowInnerColor'],
      ),
      directionArrowOuterColor: ColorExtension.tryFromJson(
        json['directionArrowOuterColor'],
      ),
    );
  }

  /// The color of the traveled part of the route.
  Color traveledInnerColor;

  /// The inner color of the turn arrows on the route.
  Color turnArrowInnerColor;

  /// The outer color of the turn arrows on the route.
  Color turnArrowOuterColor;

  /// The default inner size for turn arrows on the route in millimeters.
  double turnArrowInnerSz;

  /// The outer size of the turn arrows on the route in millimeters.
  double turnArrowOuterSz;

  /// The fill color for the route.
  Color fillColor;

  /// The text size for waypoints on the route in millimeters.
  double waypointTextSz;

  /// The inner text color for waypoint labels on the route.
  Color waypointTextInnerColor;

  /// The outer text color for waypoint labels on the route.
  Color waypointTextOuterColor;

  ///Direction arrow inner color.
  Color directionArrowInnerColor;

  /// Direction arrow outer color.
  Color directionArrowOuterColor;

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = super.toJsonWithOptions((
      final Set<dynamic> options,
    ) {
      int el1 = (options.first as RouteRenderOptions).id;
      for (final dynamic option in options.skip(1)) {
        el1 |= (option as RouteRenderOptions).id;
      }
      return el1;
    });
    json['traveledInnerColor'] = traveledInnerColor.toRgba();
    json['turnArrowInnerColor'] = turnArrowInnerColor.toRgba();
    json['turnArrowOuterColor'] = turnArrowOuterColor.toRgba();
    json['turnArrowInnerSz'] = turnArrowInnerSz;
    json['turnArrowOuterSz'] = turnArrowOuterSz;
    json['fillColor'] = fillColor.toRgba();
    json['waypointTextSz'] = waypointTextSz;
    json['waypointTextInnerColor'] = waypointTextInnerColor.toRgba();
    json['waypointTextOuterColor'] = waypointTextOuterColor.toRgba();
    json['directionArrowInnerColor'] = directionArrowInnerColor.toRgba();
    json['directionArrowOuterColor'] = directionArrowOuterColor.toRgba();
    return json;
  }
}

/// Route rendering options.
///
/// Flags to control which elements of a route are shown (traffic, arrows,
/// waypoints, highlights, user images). Combine flags in a set to enable
/// multiple behaviors.
///
/// ## See also:
///
/// - [RouteRenderSettings.options] — The options used for route rendering.
///
/// {@category Maps & 3D Scenes}
enum RouteRenderOptions {
  /// Main route.
  main,

  /// Show traffic on the route.
  showTraffic,

  /// Show turn arrows on the route.
  showTurnArrows,

  /// Show waypoints on the route.
  showWaypoints,

  /// Show highlights on the route.
  showHighlights,

  /// Show user images previously set on route landmarks/waypoints instead of the default icon.
  showUserImage,

  /// Render a drop shadow on the route bubble.
  ///
  /// Disabled by default.
  shadow,
}

/// @nodoc
extension RouteRenderOptionsExtension on RouteRenderOptions {
  int get id {
    switch (this) {
      case RouteRenderOptions.main:
        return 1;
      case RouteRenderOptions.showTraffic:
        return 2;
      case RouteRenderOptions.showTurnArrows:
        return 4;
      case RouteRenderOptions.showWaypoints:
        return 8;
      case RouteRenderOptions.showHighlights:
        return 16;
      case RouteRenderOptions.showUserImage:
        return 32;
      case RouteRenderOptions.shadow:
        return 128;
    }
  }

  static RouteRenderOptions fromId(final int id) {
    switch (id) {
      case 1:
        return RouteRenderOptions.main;
      case 2:
        return RouteRenderOptions.showTraffic;
      case 4:
        return RouteRenderOptions.showTurnArrows;
      case 8:
        return RouteRenderOptions.showWaypoints;
      case 16:
        return RouteRenderOptions.showHighlights;
      case 32:
        return RouteRenderOptions.showUserImage;
      case 128:
        return RouteRenderOptions.shadow;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
