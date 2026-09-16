// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:ui' show Color;
import 'package:flutter/material.dart' show Colors;
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/extensions.dart';
import 'package:meta/meta.dart';

/// Visual and styling configuration for a single [Marker].
///
/// [MarkerRenderSettings] controls how an individual marker is drawn on the
/// [GemMap]. It includes icon/image configuration, label styling, polyline and
/// polygon colors and sizes, and labeling modes. Use a [MarkerRenderSettings]
/// instance when adding sketches or when you need to override collection-level
/// render settings for a single marker.
///
/// ## See also:
///
/// - [MarkerCollectionRenderSettings] - settings applied to whole collections.
/// - [MarkerSketches.addMarker] - add a sketch with per-marker settings.
///
/// {@category Maps & 3D Scenes}
class MarkerRenderSettings {
  /// Create a [MarkerRenderSettings] instance.
  ///
  /// Use this to configure how an individual [Marker] is rendered. All
  /// parameters are optional and have sensible defaults; only override the
  /// properties you need to change.
  ///
  /// ## Parameters
  ///
  /// - [image]: Optional [GemImage] used as the marker icon.
  /// - [polylineType]: Style of polylines when the marker represents a line.
  /// - [polylineInnerColor]/[polylineOuterColor]: Colors used to draw
  ///   polylines.
  /// - [polygonFillColor]: Fill color for polygon markers.
  /// - [labelTextColor]/[labelTextSize]: Label color and size in mm.
  /// - [polylineInnerSize]/[polylineOuterSize]: Stroke sizes for polylines.
  /// - [imageSize]: Size of the marker image in mm. Use negative default to
  ///   select SDK default behavior.
  /// - [labelingMode]: Which label modes to enable for this marker.
  MarkerRenderSettings({
    this.image,
    this.polylineType = LineType.styleDefault,
    this.polylineInnerColor = defaultColor,
    this.polylineOuterColor = defaultColor,
    this.polygonFillColor = defaultColor,
    this.labelTextColor = defaultColor,
    this.polylineInnerSize = defaultPolylineInnerSize,
    this.polylineOuterSize = defaultPolylineOuterSize,
    this.labelTextSize = defaultLabelTextSize,
    this.imageSize = defaultImageSize,
    this.labelingMode = const <MarkerLabelingMode>{
      MarkerLabelingMode.itemLabelVisible,
      MarkerLabelingMode.groupLabelVisible,
      MarkerLabelingMode.iconBottomCenter,
      MarkerLabelingMode.textAbove,
    },
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory MarkerRenderSettings.fromJson(Map<String, dynamic> json) {
    final Set<MarkerLabelingMode> labelingModeSet = <MarkerLabelingMode>{};
    final int packedMode = json['labelingMode'];
    for (final MarkerLabelingMode mode in MarkerLabelingMode.values) {
      if (packedMode & mode.id == mode.id) {
        labelingModeSet.add(mode);
      }
    }

    if (labelingModeSet.contains(MarkerLabelingMode.none)) {
      labelingModeSet.clear();
      labelingModeSet.add(MarkerLabelingMode.itemLabelVisible);
      labelingModeSet.add(MarkerLabelingMode.groupLabelVisible);
      labelingModeSet.add(MarkerLabelingMode.iconBottomCenter);
      labelingModeSet.add(MarkerLabelingMode.textAbove);
    }

    return MarkerRenderSettings(
      polylineInnerColor: json['polylineInnerColor'] != null
          ? ColorExtension.fromJson(json['polylineInnerColor'])
          : defaultColor,
      polylineOuterColor: json['polylineOuterColor'] != null
          ? ColorExtension.fromJson(json['polylineOuterColor'])
          : defaultColor,
      polygonFillColor: json['polygonFillColor'] != null
          ? ColorExtension.fromJson(json['polygonFillColor'])
          : defaultColor,
      labelTextColor: json['labelTextColor'] != null
          ? ColorExtension.fromJson(json['labelTextColor'])
          : defaultColor,
      polylineInnerSize: json['polylineInnerSize'].toDouble() == 0.0
          ? defaultPolylineInnerSize
          : json['polylineInnerSize'].toDouble(),
      polylineOuterSize: json['polylineOuterSize'].toDouble() == 0.0
          ? defaultPolylineOuterSize
          : json['polylineOuterSize'].toDouble(),
      labelTextSize: json['labelTextSize'].toDouble() == 2147483647.0
          ? defaultLabelTextSize
          : json['labelTextSize'].toDouble(),
      imageSize: json['imageSize'].toDouble() == -1
          ? defaultImageSize
          : json['imageSize'].toDouble(),
      labelingMode: labelingModeSet,
      polylineType: LineTypeExtension.fromId(json['polylineType'] ?? 0),
    );
  }

  /// Optional image used as marker icon.
  ///
  /// When set this image is used to render the marker. If `null` or set to
  /// [defaultMembersValue] the SDK will fall back to the default marker
  /// representation.
  GemImage? image = GemImage(imageId: defaultMembersValue);

  /// Inner color used when rendering polylines.
  ///
  /// Defaults to [defaultColor]. Use this to set the primary stroke color for
  /// polyline markers.
  Color polylineInnerColor;

  /// Outer color used when rendering polylines.
  ///
  /// Can be used to create a two-tone stroke (inner/outer) for polylines.
  Color polylineOuterColor;

  /// Fill color used when rendering polygon markers.
  ///
  /// Defaults to [defaultColor].
  Color polygonFillColor;

  /// Color used for marker label text.
  ///
  /// Defaults to [defaultColor].
  Color labelTextColor;

  /// Inner stroke width for polyline markers, in millimetres.
  double polylineInnerSize;

  /// Outer stroke width for polyline markers, in millimetres.
  double polylineOuterSize;

  /// The polyline drawing style.
  LineType polylineType;

  /// Label text size, expressed in millimetres.
  double labelTextSize;

  /// Size of the marker image in millimetres. A special default (-1.0)
  /// indicates SDK default sizing behavior.
  double imageSize;

  /// Which label modes are enabled for this marker.
  ///
  /// Use the [MarkerLabelingMode] enum to control whether item or group labels
  /// are visible, and how labels are positioned relative to the icon.
  Set<MarkerLabelingMode> labelingMode;

  @internal
  dynamic imagePointer;

  @internal
  dynamic imagePointerSize;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers. The map
  /// structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (image != null) {
      json['image'] = image;
    }
    json['polylineInnerColor'] = polylineInnerColor.toRgba();
    json['polylineOuterColor'] = polylineOuterColor.toRgba();
    json['polygonFillColor'] = polygonFillColor.toRgba();
    json['labelTextColor'] = labelTextColor.toRgba();
    json['polylineInnerSize'] = polylineInnerSize;
    json['polylineOuterSize'] = polylineOuterSize;
    json['labelTextSize'] = labelTextSize;
    json['imageSize'] = imageSize;
    json['polylineType'] = polylineType.id;
    int labelingModePacked = 0;
    for (final MarkerLabelingMode mode in labelingMode) {
      labelingModePacked |= mode.id;
    }
    json['labelingMode'] = labelingModePacked;
    if (imagePointer != null) {
      json['imagePointer'] = imagePointer;
    }
    if (imagePointerSize != null) {
      json['imagePointerSize'] = imagePointerSize;
    }
    json['hashCode'] =
        image.hashCode ^
        polylineInnerColor.hashCode ^
        polylineOuterColor.hashCode ^
        polygonFillColor.hashCode ^
        labelTextColor.hashCode ^
        polylineInnerSize.hashCode ^
        polylineOuterSize.hashCode ^
        labelTextSize.hashCode ^
        imageSize.hashCode ^
        labelingMode.hashCode ^
        imagePointer.hashCode ^
        imagePointerSize.hashCode ^
        polylineType.hashCode;
    return json;
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is MarkerRenderSettings &&
        other.image == image &&
        other.polylineInnerColor == polylineInnerColor &&
        other.polylineOuterColor == polylineOuterColor &&
        other.polygonFillColor == polygonFillColor &&
        other.labelTextColor == labelTextColor &&
        other.polylineInnerSize == polylineInnerSize &&
        other.polylineOuterSize == polylineOuterSize &&
        other.labelTextSize == labelTextSize &&
        other.imageSize == imageSize &&
        other.labelingMode == labelingMode &&
        other.polylineType == polylineType;
  }

  @override
  int get hashCode =>
      image.hashCode ^
      polylineInnerColor.hashCode ^
      polylineOuterColor.hashCode ^
      polygonFillColor.hashCode ^
      labelTextColor.hashCode ^
      polylineInnerSize.hashCode ^
      polylineOuterSize.hashCode ^
      labelTextSize.hashCode ^
      imageSize.hashCode ^
      labelingMode.hashCode ^
      imagePointer.hashCode ^
      imagePointerSize.hashCode ^
      polylineType.hashCode;

  @internal
  int get packedLabelingMode {
    int labelingModePacked = 0;
    for (final MarkerLabelingMode mode in labelingMode) {
      labelingModePacked |= mode.id;
    }
    return labelingModePacked;
  }

  /// Default value of various members. Members assigned with this value will be changed internally to something more appropriate.
  static const int defaultMembersValue = 2147483647;

  /// Default color for various members. Members assigned with this value will be changed internally to something more appropriate.
  static const Color defaultColor = Colors.transparent;

  /// Default size for [polylineInnerSize].
  static const double defaultPolylineInnerSize = 1.5;

  /// Default size for [polylineOuterSize].
  static const double defaultPolylineOuterSize = 0.0;

  /// Default size for [imageSize].
  static const double defaultImageSize = 4.0;

  /// Default size for [labelTextSize].
  static const double defaultLabelTextSize = 1.0;
}

/// Render settings for a [MarkerCollection].
///
/// [MarkerCollectionRenderSettings] extends [MarkerRenderSettings] with
/// collection-specific options such as density-based grouping images,
/// grouping zoom level, group label styling, and polygon/polyline textures.
///
/// Use this when adding a marker collection to a map (for example with
/// [MapViewMarkerCollections.add]).
///
/// ## See also:
///
/// - [MarkerRenderSettings] - per-marker render settings.
/// - [MapViewMarkerCollections.addList] - add a collection with settings.
///
/// {@category Maps & 3D Scenes}
class MarkerCollectionRenderSettings extends MarkerRenderSettings {
  /// Create collection-level render settings.
  ///
  /// Use [MarkerCollectionRenderSettings] to control how a whole
  /// [MarkerCollection] is rendered on the map. It extends
  /// [MarkerRenderSettings] with collection-specific options such as
  /// density-based grouping images, grouping zoom level and group label
  /// styling.
  ///
  /// ## Parameters
  ///
  /// - [pointsGroupingZoomLevel]: Zoom level at which point grouping becomes active.
  /// - [lowDensityPointsGroupImage]/[mediumDensityPointsGroupImage]/[highDensityPointsGroupImage]:
  ///   Images used for grouped markers depending on density.
  /// - [lowDensityPointsGroupMaxCount]/[mediumDensityPointsGroupMaxCount]:
  ///   Maximum number of items in low/medium density groups.
  /// - [labelGroupTextColor]/[labelGroupTextSize]: Styling for group labels.
  /// - [buildPointsGroupConfig]: When true, enables access to points-group
  ///   relations (getPointsGroupHead / getPointsGroupComponents).
  MarkerCollectionRenderSettings({
    this.pointsGroupingZoomLevel = MarkerRenderSettings.defaultMembersValue,
    this.lowDensityPointsGroupImage,
    this.mediumDensityPointsGroupImage,
    this.highDensityPointsGroupImage,
    this.polylineTexture,
    this.polygonTexture,
    this.lowDensityPointsGroupMaxCount = defaultLowGCount,
    this.mediumDensityPointsGroupMaxCount = defaultMedGCount,
    this.labelGroupTextColor = MarkerRenderSettings.defaultColor,
    this.labelGroupTextSize = 2,
    this.buildPointsGroupConfig = false,
    super.image,
    super.imageSize = -1.0,
    super.labelingMode,
    super.labelTextSize = MarkerRenderSettings.defaultLabelTextSize,
    super.labelTextColor = const Color.fromARGB(0, 84, 71, 71),
    super.polylineInnerColor = MarkerRenderSettings.defaultColor,
    super.polylineType = LineType.styleDefault,
    super.polylineOuterColor = MarkerRenderSettings.defaultColor,
    super.polygonFillColor = MarkerRenderSettings.defaultColor,
    super.polylineInnerSize = MarkerRenderSettings.defaultPolylineInnerSize,
    super.polylineOuterSize = MarkerRenderSettings.defaultPolylineOuterSize,
  }) {
    lowDensityPointsGroupImage ??= GemImage(
      imageId: MarkerRenderSettings.defaultMembersValue,
    );
    mediumDensityPointsGroupImage ??= GemImage(
      imageId: MarkerRenderSettings.defaultMembersValue,
    );
    highDensityPointsGroupImage ??= GemImage(
      imageId: MarkerRenderSettings.defaultMembersValue,
    );
    polygonTexture ??= GemImage(
      imageId: MarkerRenderSettings.defaultMembersValue,
    );
    polylineTexture ??= GemImage(
      imageId: MarkerRenderSettings.defaultMembersValue,
    );
    image ??= GemImage(imageId: MarkerRenderSettings.defaultMembersValue);
  }

  /// The zoom level at which points grouping is enabled.
  ///
  /// When the map's zoom is equal or higher than this value, points grouping
  /// may be applied. Use [MarkerCollectionRenderSettings.pointsGroupingZoomLevel]
  /// to control clustering behaviour for large marker sets.
  int pointsGroupingZoomLevel;

  /// The image used to render low-density point groups.
  ///
  /// When point grouping is active and the number of items in a group is
  /// less than or equal to [lowDensityPointsGroupMaxCount], this image will
  /// be displayed for the group head.
  GemImage? lowDensityPointsGroupImage = GemImage(
    imageId: MarkerRenderSettings.defaultMembersValue,
  );

  /// Maximum number of items in a low-density points group.
  ///
  /// Groups with size <= this value are displayed using
  /// [lowDensityPointsGroupImage].
  int lowDensityPointsGroupMaxCount;

  /// The image used to render medium-density point groups.
  GemImage? mediumDensityPointsGroupImage = GemImage(
    imageId: MarkerRenderSettings.defaultMembersValue,
  );

  /// Maximum number of items in a medium-density points group.
  ///
  /// Groups with size <= this value are displayed using
  /// [mediumDensityPointsGroupImage].
  int mediumDensityPointsGroupMaxCount;

  /// The image used to render high-density point groups.
  GemImage? highDensityPointsGroupImage = GemImage(
    imageId: MarkerRenderSettings.defaultMembersValue,
  );

  /// Text color used for group labels.
  ///
  /// Defaults are provided by the current style if not set explicitly.
  Color labelGroupTextColor;

  /// Text size for group labels, in millimetres.
  double labelGroupTextSize;

  /// When true, the SDK builds the points-group configuration for the
  /// collection.
  ///
  /// This enables APIs that expose the relation between individual markers
  /// and their group head (for example `pointsGroupHead` and
  /// `pointsGroupComponents`). Building this config has a runtime cost,
  /// so enable only when you need grouping introspection.
  bool buildPointsGroupConfig;

  /// Optional texture used when rendering polylines for the collection.
  ///
  /// The texture is blended with [polylineInnerColor]. To preserve the
  /// original texture colors, set [polylineInnerColor] to fully opaque white.
  GemImage? polylineTexture = GemImage(
    imageId: MarkerRenderSettings.defaultMembersValue,
  );

  /// Optional texture used when rendering polygons for the collection.
  ///
  /// The texture is blended with [polygonFillColor]. To preserve the
  /// original texture colors, set [polygonFillColor] to fully opaque white.
  GemImage? polygonTexture = GemImage(
    imageId: MarkerRenderSettings.defaultMembersValue,
  );

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['groupingLevel'] = pointsGroupingZoomLevel;
    if (lowDensityPointsGroupImage != null) {
      json['lowDensityGroupImage'] = lowDensityPointsGroupImage;
    }
    json['lowGroupMaxCount'] = lowDensityPointsGroupMaxCount;
    if (mediumDensityPointsGroupImage != null) {
      json['mediumDensityGroupImage'] = mediumDensityPointsGroupImage;
    }
    json['mediumGroupMaxCount'] = mediumDensityPointsGroupMaxCount;
    if (highDensityPointsGroupImage != null) {
      json['highDensityGroupImage'] = highDensityPointsGroupImage;
    }
    json['groupLabelTextColor'] = labelGroupTextColor.toRgba();
    json['groupLabelTextSize'] = labelGroupTextSize;
    json['buildGroupConfig'] = buildPointsGroupConfig;
    if (polylineTexture != null) {
      json['polylineTexture'] = polylineTexture;
    }
    if (polygonTexture != null) {
      json['polygonTexture'] = polygonTexture;
    }
    if (image != null) {
      json['image'] = image;
    }
    json['polylineInnerColor'] = polylineInnerColor.toRgba();
    json['polylineOuterColor'] = polylineOuterColor.toRgba();
    json['polygonFillColor'] = polygonFillColor.toRgba();
    json['labelTextColor'] = labelTextColor.toRgba();
    if (imagePointer != null) {
      json['imagePointer'] = imagePointer;
    }
    if (imagePointerSize != null) {
      json['imagePointerSize'] = imagePointerSize;
    }

    json['imageSize'] = imageSize;
    json['labelingMode'] = packedLabelingMode;
    json['labelTextSize'] = labelTextSize;
    json['labelTextColor'] = labelTextColor.toRgba();
    json['hashCode'] = json.hashCode;
    json['polylineInnerSize'] = polylineInnerSize;
    json['polylineType'] = polylineType.id;
    json['polylineOuterSize'] = polylineOuterSize;
    return json;
  }

  /// The default maximum number of items in a low density points group.
  static const int defaultLowGCount = 50;

  /// The default maximum number of items in a medium density points group.
  static const int defaultMedGCount = 300;
}

/// Controls which labeling modes are enabled for markers.
///
/// Use [MarkerLabelingMode] to toggle item and group labels and to control
/// label placement relative to marker icons.
///
/// {@category Maps & 3D Scenes}
enum MarkerLabelingMode {
  /// No labels are displayed.
  none,

  /// Display a label for each individual marker item.
  itemLabelVisible,

  /// Display labels for grouped markers (when grouping is active).
  groupLabelVisible,

  /// Center text on top of the icon.
  textCentered,

  /// Center the group label on the group's icon.
  groupCenter,

  /// Scale the label so it fits within the image bounds.
  fitImage,

  /// Place the icon above the marker's geographic coordinates; label sits below.
  iconBottomCenter,

  /// Place text above the icon.
  textAbove,

  /// Place text below the icon.
  textBelow,

  /// Position group labels in the top-right corner of the group icon.
  groupTopRight,
}

/// @nodoc
extension MarkerLabelingModeExtension on MarkerLabelingMode {
  int get id {
    switch (this) {
      case MarkerLabelingMode.none:
        return 0;
      case MarkerLabelingMode.itemLabelVisible:
        return 1;
      case MarkerLabelingMode.groupLabelVisible:
        return 2;
      case MarkerLabelingMode.textCentered:
        return 4;
      case MarkerLabelingMode.groupCenter:
        return 8;
      case MarkerLabelingMode.fitImage:
        return 16;
      case MarkerLabelingMode.iconBottomCenter:
        return 32;
      case MarkerLabelingMode.textAbove:
        return 64;
      case MarkerLabelingMode.textBelow:
        return 128;
      case MarkerLabelingMode.groupTopRight:
        return 256;
    }
  }

  static MarkerLabelingMode fromId(final int id) {
    switch (id) {
      case 0:
        return MarkerLabelingMode.none;
      case 1:
        return MarkerLabelingMode.itemLabelVisible;
      case 2:
        return MarkerLabelingMode.groupLabelVisible;
      case 4:
        return MarkerLabelingMode.textCentered;
      case 8:
        return MarkerLabelingMode.groupCenter;
      case 16:
        return MarkerLabelingMode.fitImage;
      case 32:
        return MarkerLabelingMode.iconBottomCenter;
      case 64:
        return MarkerLabelingMode.textAbove;
      case 128:
        return MarkerLabelingMode.textBelow;
      case 256:
        return MarkerLabelingMode.groupTopRight;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
