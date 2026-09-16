// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:ui';

import 'package:magiclane_maps_flutter/src/core/private/extensions.dart';

/// Base class for render settings used by map view elements.
///
/// A generic, typed container that centralizes appearance choices such as
/// visibility options, colors and sizing for inner/outer areas, image and
/// text sizing, line style, and image placement. Subclass this for
/// specialized rendering settings (for markers, routes, highlights, etc.).
///
/// ## See also:
///
/// - [HighlightRenderSettings] — Render settings specialized for landmark highlights.
/// - [RouteRenderSettings] — Render settings specialized for routes.
///
/// {@category Maps & 3D Scenes}
class RenderSettings<T> {
  /// Creates a new [RenderSettings] instance.
  ///
  /// ## Parameters
  ///
  /// - [options]: (`Set<T>`) The set that defines which rendering options are enabled.
  /// - [innerColor]: (`Color`) Color used for the inner area.
  /// - [outerColor]: (`Color`) Color used for the outer area.
  /// - [innerSz]: (`double`) Size for the inner area in millimeters.
  /// - [outerSz]: (`double`) Size for the outer area in millimeters.
  /// - [imgSz]: (`double`) Image size in millimeters.
  /// - [textSz]: (`double`) Text size in millimeters.
  /// - [textColor]: (`Color`) Color used for text.
  /// - [lineType]: (`LineType`) Line style used by the element.
  /// - [imagePosition]: (`ImagePosition`) Positioning of the image relative to the reference point.
  RenderSettings({
    this.options = const <Never>{},
    this.innerColor = defaultInnerColor,
    this.outerColor = defaultOuterColor,
    this.innerSz = defaultInnerSize,
    this.outerSz = defaultOuterSize,
    this.imgSz = defaultImageSize,
    this.textSz = defaultTextSize,
    this.textColor = defaultTextColor,
    this.lineType = defaultLineType,
    this.imagePosition = defaultImagePosition,
  });

  /// The set that defines what elements to show.
  Set<T> options;

  /// The color for the inner area.
  Color innerColor;

  /// The color for the outer area.
  Color outerColor;

  /// The size for the inner area in millimeters.
  double innerSz;

  /// The size for the outer area in millimeters.
  double outerSz;

  /// The size of the image in millimeters.
  double imgSz;

  /// The size for the text in millimeters.
  double textSz;

  /// The color for the text.
  Color textColor;

  /// The line type.
  LineType lineType;

  /// Image position
  ImagePosition imagePosition;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  Map<String, dynamic> toJsonWithOptions(
    final dynamic Function(Set<dynamic> options) optionsSerializer,
  ) {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['options'] = optionsSerializer(options);
    json['innerColor'] = innerColor.toRgba();
    json['outerColor'] = outerColor.toRgba();
    json['innerSz'] = innerSz;
    json['outerSz'] = outerSz;
    json['imgSz'] = imgSz;
    json['textSz'] = textSz;
    json['textColor'] = textColor.toRgba();
    json['lineType'] = lineType.id;
    json['imagePosition'] = imagePosition.id;
    return json;
  }

  /// Default value for [innerColor]
  static const Color defaultInnerColor = Color(0x00000000);

  /// Default value for [outerColor]
  static const Color defaultOuterColor = Color(0x00000000);

  /// Default value for [textColor]
  static const Color defaultTextColor = Color(0x00000000);

  /// Default value for [innerSz]
  static const double defaultInnerSize = -1.0;

  /// Default value for [outerSz]
  static const double defaultOuterSize = 0.0;

  /// Default value for [imgSz]
  static const double defaultImageSize = 0.0;

  /// Default value for [textSz]
  static const double defaultTextSize = 0.0;

  /// Default value for [lineType]
  static const LineType defaultLineType = LineType.styleDefault;

  /// Default value for [imagePosition]
  static const ImagePosition defaultImagePosition = ImagePosition.styleDefault;
}

/// Line style options used for linear features.
///
/// Choose an appropriate [LineType] when customizing polylines or borders.
///
/// ## See also:
///
/// - [RenderSettings.lineType] — Line type used in render settings.
///
/// {@category Maps & 3D Scenes}
enum LineType {
  /// Default line style.
  styleDefault,

  /// Solid line style.
  solid,

  /// Dashed line style.
  dashed,
}

/// @nodoc
extension LineTypeExtension on LineType {
  int get id {
    switch (this) {
      case LineType.styleDefault:
        return 0;
      case LineType.solid:
        return 1;
      case LineType.dashed:
        return 2;
    }
  }

  static LineType fromId(final int id) {
    switch (id) {
      case 0:
        return LineType.styleDefault;
      case 1:
        return LineType.solid;
      case 2:
        return LineType.dashed;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Image placement options relative to a reference point.
///
/// Use these values to control how an image/icon is anchored relative to
/// its reference coordinates on the map.
///
/// ## See also:
///
/// - [RenderSettings.imagePosition] — Image position used in render settings.
///
/// {@category Maps & 3D Scenes}
enum ImagePosition {
  /// Default image position (style defined).
  styleDefault,

  /// Centered on position. Default.
  center,

  /// Left-top side relative to position.
  leftTop,

  /// Horizontal centered-top side relative to position.
  centerTop,

  /// Right-top side relative to position.
  rightTop,

  /// Right-vertical centered side relative to position.
  rightCenter,

  /// Right-bottom side relative to position.
  rightBottom,

  /// Horizontal centered-bottom side relative to position.
  centerBottom,

  /// Left-bottom side relative to position.
  leftBottom,

  /// Left-vertical centered side relative to position.
  leftCenter,
}

/// @nodoc
extension ImagePositionExtension on ImagePosition {
  int get id {
    switch (this) {
      case ImagePosition.styleDefault:
        return 0;
      case ImagePosition.center:
        return 1;
      case ImagePosition.leftTop:
        return 2;
      case ImagePosition.centerTop:
        return 3;
      case ImagePosition.rightTop:
        return 4;
      case ImagePosition.rightCenter:
        return 5;
      case ImagePosition.rightBottom:
        return 6;
      case ImagePosition.centerBottom:
        return 7;
      case ImagePosition.leftBottom:
        return 8;
      case ImagePosition.leftCenter:
        return 9;
    }
  }

  static ImagePosition fromId(final int id) {
    switch (id) {
      case 0:
        return ImagePosition.styleDefault;
      case 1:
        return ImagePosition.center;
      case 2:
        return ImagePosition.leftTop;
      case 3:
        return ImagePosition.centerTop;
      case 4:
        return ImagePosition.rightTop;
      case 5:
        return ImagePosition.rightCenter;
      case 6:
        return ImagePosition.rightBottom;
      case 7:
        return ImagePosition.centerBottom;
      case 8:
        return ImagePosition.leftBottom;
      case 9:
        return ImagePosition.leftCenter;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
