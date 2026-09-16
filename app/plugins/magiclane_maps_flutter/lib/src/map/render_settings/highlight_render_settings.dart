// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:ui';

import 'package:magiclane_maps_flutter/src/map/render_settings/render_settings.dart';
import 'package:meta/meta.dart';

/// Render settings specialized for landmark highlights.
///
/// Provides defaults tailored for highlight rendering (colors, sizes and
/// options). Use this class when adding or configuring highlight-style
/// renderings on the map (for example, landmark emphasis bubbles).
///
/// ## Also see:
///
/// - [GemMapController.activateHighlight] — Method to activate landmark highlights.
///
/// {@category Maps & 3D Scenes}
class HighlightRenderSettings extends RenderSettings<HighlightOptions> {
  /// Creates highlight-specific render settings with sensible defaults.
  ///
  /// ## Parameters
  ///
  /// - [options]: (`Set<HighlightOptions>`) Enabled highlight options. Defaults to showing the landmark.
  /// - [innerColor]: (`Color`) Inner highlight color.
  /// - [outerColor]: (`Color`) Outer highlight color.
  /// - [innerSz]: (`double`) Inner size in millimeters.
  /// - [outerSz]: (`double`) Outer size in millimeters.
  /// - [imgSz]: (`double`) Image size in millimeters.
  /// - [textSz]: (`double`) Text size in millimeters.
  /// - [textColor]: (`Color`) Text color.
  /// - [lineType]: (`LineType`) Line style used for the highlight border.
  /// - [imagePosition]: (`ImagePosition`) Image placement relative to the highlight.
  HighlightRenderSettings({
    super.options = const <HighlightOptions>{HighlightOptions.showLandmark},
    super.innerColor = const Color.fromARGB(255, 255, 98, 0),
    super.outerColor = const Color.fromARGB(255, 255, 98, 0),
    super.innerSz = 1.5,
    super.outerSz = RenderSettings.defaultOuterSize,
    super.imgSz = RenderSettings.defaultImageSize,
    super.textSz = RenderSettings.defaultTextSize,
    super.textColor = RenderSettings.defaultTextColor,
    super.lineType = RenderSettings.defaultLineType,
    super.imagePosition = RenderSettings.defaultImagePosition,
  });

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    return super.toJsonWithOptions((final Set<dynamic> options) {
      int el1 = (options.first as HighlightOptions).id;
      for (final dynamic option in options.skip(1)) {
        el1 |= (option as HighlightOptions).id;
      }
      return el1;
    });
  }
}

/// Highlight display options for landmarks.
///
/// Flags that control visual behavior for landmark highlights (bubbles,
/// contours, grouping, selectable behavior, and fading). Combine multiple
/// flags in a set when configuring highlight rendering.
///
/// ## See also:
///
/// - [HighlightRenderSettings.options] — The options used for landmark highlights.
///
/// {@category Maps & 3D Scenes}
enum HighlightOptions {
  /// Shows the landmark icon & text.
  showLandmark,

  /// Shows the landmark impact area contour (when available).
  ///
  /// Enabled by default.
  showContour,

  /// Groups landmarks.
  ///
  /// Available only when [showLandmark] is enabled. Disabled by default.
  group,

  /// Overlap highlight over existing map data.
  ///
  /// Available only when [showLandmark] is enabled. Disabled by default.
  overlap,

  /// Disable highlight fading in/out.
  ///
  /// Available only when [showLandmark] is enabled. Disabled by default.
  noFading,

  /// Display the highlight in a bubble with custom icon placement.
  ///
  /// Use `%%0%%` as an icon placeholder in the text (for example:
  /// `"My header text %%0%%\nMy footer text"`). Disabled by default.
  bubble,

  /// Make highlights selectable via `setCursorScreenPosition`.
  ///
  /// Available only when [showLandmark] is enabled. Disabled by default.
  selectable,

  /// Render a drop shadow / blur around the highlight bubble.
  ///
  /// Available only when [bubble] is enabled. Disabled by default.
  shadow,
}

/// @nodoc
extension HighlightOptionsExtension on HighlightOptions {
  int get id {
    switch (this) {
      case HighlightOptions.showLandmark:
        return 1;
      case HighlightOptions.showContour:
        return 2;
      case HighlightOptions.group:
        return 4;
      case HighlightOptions.overlap:
        return 8;
      case HighlightOptions.noFading:
        return 16;
      case HighlightOptions.bubble:
        return 32;
      case HighlightOptions.selectable:
        return 64;
      case HighlightOptions.shadow:
        return 128;
    }
  }

  static HighlightOptions fromId(final int id) {
    switch (id) {
      case 1:
        return HighlightOptions.showLandmark;
      case 2:
        return HighlightOptions.showContour;
      case 4:
        return HighlightOptions.group;
      case 8:
        return HighlightOptions.overlap;
      case 16:
        return HighlightOptions.noFading;
      case 32:
        return HighlightOptions.bubble;
      case 64:
        return HighlightOptions.selectable;
      case 128:
        return HighlightOptions.shadow;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
