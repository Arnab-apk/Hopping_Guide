// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/extensions.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Signpost rendering and semantic details.
///
/// Provides appearance cues and structured sign elements used by navigation UI.
/// Obtain instances via [NavigationInstruction.signpostDetails] or [RouteInstructionBase.signpostDetails].
/// This class should not be constructed directly.
///
/// It exposes background/border/text colors, a rendered image representation (configurable by size, format and
/// render settings), and a list of [SignpostItem] elements used to assemble on‑screen sign displays.
///
/// ## See also:
///
/// - [NavigationInstruction.signpostDetails] — Obtain signpost details for a navigation instruction.
/// - [RouteInstructionBase.signpostDetails] — obtain signpost details for a route instruction.
/// - [SignpostImg] — abstract image representation returned by [image].
///
/// {@category Route}
class SignpostDetails extends GemAutoreleaseObject {
  // ignore: unused_element
  SignpostDetails._() : super(-1);

  @internal
  SignpostDetails.init(super.id);

  /// Background color used by the signpost, when available.
  ///
  /// Returns the color that should be used as the signpost background when rendering UI. The value is
  /// parsed using [ColorExtension.fromJson] from the native result.
  ///
  /// ## Returns
  ///
  /// - [Color]: the background color for the signpost.
  ///
  /// ## See also:
  ///
  /// - [hasBackgroundColor] - check if a background color is present.
  Color get backgroundColor {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostDetails',
      'getBackgroundColor',
    );

    return ColorExtension.fromJson(resultString['result']);
  }

  /// Border color used by the signpost, when available.
  ///
  /// ## Returns
  ///
  /// - [Color]: the border color for the signpost.
  ///
  /// ## See also:
  ///
  /// - [hasBorderColor] - check if a border color is present.
  Color get borderColor {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostDetails',
      'getBorderColor',
    );

    return ColorExtension.fromJson(resultString['result']);
  }

  /// Text color used for signpost labels, when available.
  ///
  /// ## Returns
  ///
  /// - [Color]: the text color for signpost text.
  ///
  /// ## See also:
  ///
  /// - [hasTextColor] - check if a text color is present.
  Color get textColor {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostDetails',
      'getTextColor',
    );

    return ColorExtension.fromJson(resultString['result']);
  }

  /// Whether a background color is present for this signpost.
  ///
  /// Use this property to determine if [backgroundColor] contains a meaningful value before using it.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when a background color is present; otherwise `false`.
  ///
  /// ## See also:
  ///
  /// - [backgroundColor] - obtain the background color for the signpost.
  bool get hasBackgroundColor {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostDetails',
      'hasBackgroundColor',
    );

    return resultString['result'];
  }

  /// Whether a border color is present for this signpost.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when a border color is present; otherwise `false`.
  ///
  /// ## See also:
  ///
  /// - [borderColor] - obtain the border color for the signpost.
  bool get hasBorderColor {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostDetails',
      'hasBorderColor',
    );

    return resultString['result'];
  }

  /// Whether a text color is present for this signpost.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when a text color is present; otherwise `false`.
  ///
  /// ## See also:
  ///
  /// - [textColor] - obtain the text color for the signpost.
  bool get hasTextColor {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostDetails',
      'hasTextColor',
    );

    return resultString['result'];
  }

  /// Rendered image bytes for this signpost.
  ///
  /// Returns a byte array containing the rendered image produced using the provided [size], [format] and
  /// [renderSettings]. The value may be `null` if the signpost could not be rendered with the requested parameters.
  ///
  /// ## Which image is rendered?
  ///
  /// When this handle's signpost image matches the one carried by the
  /// currently-active navigation instruction (as reported by
  /// `NavigationService.getNavigationInstruction()`), the native method
  /// parser renders from the live instruction rather than from the cached
  /// `SignpostDetails` this call was made on. This shields callers from
  /// use-after-free when the engine replaces the active instruction
  /// (next step, rematch, route recalculation, arrival) and the cached
  /// native memory behind the Dart handle is recycled. When the handle
  /// does not correspond to the live instruction (route preview, static
  /// route-instruction list, off-map inspection) rendering uses this
  /// `SignpostDetails` as before.
  ///
  /// ## Parameters
  ///
  /// - [size]: Optional desired image size. When omitted the SDK default size is used.
  /// - [format]: Optional image file format. When omitted an appropriate default (PNG) is used.
  /// - [renderSettings]: Rendering options to control border, corner rounding and maximum rows.
  /// - [allowResize]: When `true` the SDK may choose a suitable size based on the provided height; otherwise the
  ///   requested size is used as-is.
  ///
  /// ## Returns
  ///
  /// - `Uint8List?`: the image bytes when available, otherwise `null`.
  ///
  /// ## See also:
  ///
  /// - [SignpostImg] — image helpers for signpost rendering.
  Uint8List? getImage({
    final Size? size,
    final ImageFileFormat? format,
    final SignpostImageRenderSettings renderSettings =
        const SignpostImageRenderSettings(),
    final bool allowResize = false,
  }) {
    return GemKitPlatform.instance.callGetImage(
      pointerId,
      'SignPostDetailsGetImage',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
      arg: jsonEncode(renderSettings),
      allowResize: allowResize,
    );
  }

  /// Get the signpost image as a [SignpostImg].
  ///
  /// Prefer [SignpostImg] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getImage] when you only need the raster image bytes.
  ///
  /// ## Which image is rendered?
  ///
  /// The native layer records, at the moment this handle is created, whether
  /// the underlying signpost matches the one on the currently-active
  /// [NavigationInstruction] (as reported by
  /// `NavigationService.getNavigationInstruction()`). If it does, calls on the
  /// returned [SignpostImg] re-resolve the image from the live instruction at
  /// render time — even if the engine has since replaced the instruction
  /// (next step, rematch, route recalculation, arrival) and the native memory
  /// backing this Dart handle has been recycled. This prevents use-after-free
  /// on the render thread.
  ///
  /// For handles obtained from a [RouteInstructionBase] (route preview,
  /// static route-instruction list) or from `SignpostDetails` belonging to a
  /// non-active route, rendering uses the image captured at the moment this
  /// [SignpostImg] was created, as before.
  ///
  /// ## Returns
  ///
  /// - [SignpostImg]: an abstract image object containing metadata and rendering helpers.
  ///
  /// ## See also:
  ///
  /// - [SignpostImg] — image helpers for signpost rendering.
  /// - [NavigationService.getNavigationInstruction] — source of the live instruction used during active navigation.
  SignpostImg get image {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostDetails',
      'getImg',
    );

    return SignpostImg.init(resultString['result']);
  }

  /// Structured signpost elements used to assemble the sign layout.
  ///
  /// Each entry in the returned list is a [SignpostItem] describing the semantic content and display hints for
  /// a portion of the signpost (text, pictogram, shield, etc.).
  ///
  /// ## Returns
  ///
  /// - `List<SignpostItem>`: the ordered list of signpost elements.
  List<SignpostItem> get items {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostDetails',
      'getItems',
    );

    return SignpostItemList.init(resultString['result']).toList();
  }
}
