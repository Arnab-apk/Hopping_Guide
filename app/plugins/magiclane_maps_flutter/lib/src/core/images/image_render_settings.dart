// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:ui' show Color;

import 'package:magiclane_maps_flutter/src/core/private/extensions.dart';
import 'package:meta/meta.dart';

/// Rendering settings for turn instruction images in navigation instructions.
///
/// Configures the visual appearance of [AbstractGeometry] images representing
/// turn arrows and maneuvers in navigation. Allows customization of inner and
/// outer colors for both active (recommended) and inactive (alternative) turns.
/// Active colors highlight the recommended turn direction, while inactive colors
/// show non-recommended alternatives. All color properties default to optimal
/// values if not specified.
///
/// ## See also:
///
/// - [TurnDetails] - Contains abstract geometry images for turn instructions
/// - [NavigationInstruction] - Provides turn details with abstract geometry
/// - [RouteInstruction] - Route instructions that may include turn images
/// - [AbstractGeometryImg] - Image representation of abstract geometry turn arrows
///
/// {@category Images}
class AbstractGeometryImageRenderSettings {
  /// Creates turn arrow rendering settings with customizable colors.
  ///
  /// Initializes rendering settings for abstract geometry turn arrow images.
  /// All color parameters are optional and default to SDK-optimized values:
  /// active inner (white), active outer (black), inactive inner (gray),
  /// inactive outer (gray).
  ///
  /// ## Parameters
  ///
  /// - [activeInnerColor] - Inner fill color for recommended turn arrows (default: white)
  /// - [activeOuterColor] - Outer border color for recommended turn arrows (default: black)
  /// - [inactiveInnerColor] - Inner fill color for alternative turn arrows (default: gray)
  /// - [inactiveOuterColor] - Outer border color for alternative turn arrows (default: gray)
  const AbstractGeometryImageRenderSettings({
    this.activeInnerColor = const Color.fromARGB(255, 255, 255, 255),
    this.activeOuterColor = const Color.fromARGB(255, 0, 0, 0),
    this.inactiveInnerColor = const Color.fromARGB(255, 128, 128, 128),
    this.inactiveOuterColor = const Color.fromARGB(255, 128, 128, 128),
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory AbstractGeometryImageRenderSettings.fromJson(
    final Map<String, dynamic> json,
  ) {
    return AbstractGeometryImageRenderSettings(
      activeInnerColor:
          json['activeInnerColor'] ?? const Color.fromARGB(255, 255, 255, 255),
      activeOuterColor:
          json['activeOuterColor'] ?? const Color.fromARGB(255, 0, 0, 0),
      inactiveInnerColor:
          json['inactiveInnerColor'] ??
          const Color.fromARGB(255, 128, 128, 128),
      inactiveOuterColor:
          json['inactiveOuterColor'] ??
          const Color.fromARGB(255, 128, 128, 128),
    );
  }

  /// Inner fill color for recommended turn arrows.
  ///
  /// Defines the main color inside active/recommended turn arrow symbols.
  /// Defaults to white if not specified.
  final Color activeInnerColor;

  /// Outer border color for recommended turn arrows.
  ///
  /// Defines the outline color for active/recommended turn arrow symbols.
  /// Defaults to black if not specified.
  final Color activeOuterColor;

  /// Inner fill color for alternative turn arrows.
  ///
  /// Defines the main color inside inactive/non-recommended turn arrow symbols.
  /// Defaults to gray if not specified.
  final Color inactiveInnerColor;

  /// Outer border color for alternative turn arrows.
  ///
  /// Defines the outline color for inactive/non-recommended turn arrow symbols.
  /// Defaults to gray if not specified.
  final Color inactiveOuterColor;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['activeInnerColor'] = activeInnerColor.toRgba();
    json['activeOuterColor'] = activeOuterColor.toRgba();
    json['inactiveInnerColor'] = inactiveInnerColor.toRgba();
    json['inactiveOuterColor'] = inactiveOuterColor.toRgba();
    return json;
  }

  @override
  bool operator ==(covariant final AbstractGeometryImageRenderSettings other) {
    if (identical(this, other)) {
      return true;
    }

    return other.activeInnerColor == activeInnerColor &&
        other.activeOuterColor == activeOuterColor &&
        other.inactiveInnerColor == inactiveInnerColor &&
        other.inactiveOuterColor == inactiveOuterColor;
  }

  @override
  int get hashCode {
    return activeInnerColor.hashCode ^
        activeOuterColor.hashCode ^
        inactiveInnerColor.hashCode ^
        inactiveOuterColor.hashCode;
  }
}

/// Rendering settings for signpost images in navigation instructions.
///
/// Configures the visual appearance of signpost images that display upcoming
/// exit information and destination names on highways and major roads. Controls
/// border styling, corner rounding, and the maximum number of destination rows
/// displayed. All properties default to optimal values: 10px border, rounded
/// corners enabled, and maximum 3 rows of details.
///
/// ## See also:
///
/// - [SignpostDetails] - Contains signpost data and rendering methods
/// - [NavigationInstruction] - Provides signpost details for upcoming exits
/// - [SignpostImg] - Image representation of signpost information
///
/// {@category Images}
class SignpostImageRenderSettings {
  /// Creates signpost rendering settings with customizable layout options.
  ///
  /// Initializes rendering settings for signpost images with optional border
  /// styling and row limits. Defaults provide a modern, readable appearance
  /// suitable for most navigation use cases.
  ///
  /// ## Parameters
  ///
  /// - [borderSize] - Border width in pixels around the signpost (default: 10)
  /// - [borderRoundCorners] - Whether to use rounded corners for modern styling (default: true)
  /// - [maxRows] - Maximum number of destination rows to display (default: 3)
  const SignpostImageRenderSettings({
    this.borderSize = 10,
    this.borderRoundCorners = true,
    this.maxRows = 3,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory SignpostImageRenderSettings.fromJson(
    final Map<String, dynamic> json,
  ) {
    return SignpostImageRenderSettings(
      borderSize: json['borderSize'],
      borderRoundCorners: json['borderRoundCorners'],
      maxRows: json['maxRows'],
    );
  }

  /// Border width in pixels around the signpost image.
  ///
  /// Controls the thickness of the border frame. Larger values create more
  /// prominent borders. Defaults to 10 pixels.
  final int borderSize;

  /// Whether to use rounded corners for the signpost border.
  ///
  /// When true, creates a modern appearance with rounded corners. When false,
  /// uses sharp rectangular corners. Defaults to true.
  final bool borderRoundCorners;

  /// Maximum number of destination rows to display on the signpost.
  ///
  /// Limits the vertical size of signpost images by capping the number of
  /// destination/exit detail rows shown. Prevents excessively tall signposts
  /// when many destinations exist. Defaults to 3 rows.
  final int maxRows;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['borderSize'] = borderSize;
    json['borderRoundCorners'] = borderRoundCorners;
    json['maxRows'] = maxRows;

    return json;
  }

  @override
  bool operator ==(covariant final SignpostImageRenderSettings other) {
    if (identical(this, other)) {
      return true;
    }

    return other.borderSize == borderSize &&
        other.borderRoundCorners == borderRoundCorners &&
        other.maxRows == maxRows;
  }

  @override
  int get hashCode {
    return borderSize.hashCode ^ borderRoundCorners.hashCode ^ maxRows.hashCode;
  }
}

/// Rendering settings for lane guidance images in navigation instructions.
///
/// Configures the visual appearance of lane guidance images that show which lanes
/// the driver should use for upcoming maneuvers. Controls the background color,
/// active lane color (recommended lanes), and inactive lane color (lanes to avoid).
/// All color properties default to optimal values: transparent background, white
/// active lanes, and gray inactive lanes for clear visual distinction.
///
/// ## See also:
///
/// - [LaneImg] - Image representation of lane guidance
/// - [NavigationInstruction] - Provides lane guidance information
/// - [RouteInstruction] - May include lane information for route segments
///
/// {@category Images}
class LaneImageRenderSettings {
  /// Creates lane guidance rendering settings with customizable colors.
  ///
  /// Initializes rendering settings for lane guidance images. All color parameters
  /// are optional and default to values optimized for clarity: transparent background,
  /// white for recommended lanes, and gray for non-recommended lanes.
  ///
  /// ## Parameters
  ///
  /// - [backgroundColor] - Background color behind the lane symbols (default: transparent)
  /// - [activeColor] - Color for lanes the driver should use (default: white)
  /// - [inactiveColor] - Color for lanes the driver should avoid (default: gray)
  const LaneImageRenderSettings({
    this.backgroundColor = const Color.fromARGB(0, 0, 0, 0),
    this.activeColor = const Color.fromARGB(255, 255, 255, 255),
    this.inactiveColor = const Color.fromARGB(255, 140, 140, 140),
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory LaneImageRenderSettings.fromJson(final Map<String, dynamic> json) {
    return LaneImageRenderSettings(
      backgroundColor:
          json['backgroundColor'] ?? const Color.fromARGB(0, 0, 0, 0),
      activeColor:
          json['activeColor'] ?? const Color.fromARGB(255, 255, 255, 255),
      inactiveColor:
          json['inactiveColor'] ?? const Color.fromARGB(255, 140, 140, 140),
    );
  }

  /// Background color behind the lane guidance symbols.
  ///
  /// Defines the background fill color for the entire lane image. Defaults to
  /// transparent, allowing the lane symbols to overlay navigation UI cleanly.
  final Color backgroundColor;

  /// Color for recommended lanes the driver should use.
  ///
  /// Highlights lanes the driver should be in for the upcoming maneuver.
  /// Defaults to white for high visibility against most backgrounds.
  final Color activeColor;

  /// Color for non-recommended lanes the driver should avoid.
  ///
  /// Shows lanes that should not be used for the upcoming maneuver.
  /// Defaults to gray to visually de-emphasize compared to active lanes.
  final Color inactiveColor;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['backgroundColor'] = backgroundColor.toRgba();
    json['activeColor'] = activeColor.toRgba();
    json['inactiveColor'] = inactiveColor.toRgba();
    return json;
  }

  @override
  bool operator ==(covariant final LaneImageRenderSettings other) {
    if (identical(this, other)) {
      return true;
    }

    return other.backgroundColor == backgroundColor &&
        other.activeColor == activeColor &&
        other.inactiveColor == inactiveColor;
  }

  @override
  int get hashCode {
    return backgroundColor.hashCode ^
        activeColor.hashCode ^
        inactiveColor.hashCode;
  }
}
