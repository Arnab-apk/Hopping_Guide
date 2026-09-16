// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';
import 'dart:core';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/images/img_cache.dart';
import 'package:magiclane_maps_flutter/src/core/private/extensions.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/obj_type.dart';
import 'package:meta/meta.dart';

/// Base class for all SDK image representations with rendering capabilities.
///
/// Represents images in an abstract form that is not directly drawable on UI.
/// Provides metadata access ([uid], [imageType], [isValid], [isScalable]) and
/// methods to obtain renderable image data ([getRenderableImage], [getRenderableImageBytes]).
///
/// Use concrete subclasses for specific image types: [Img] for plain images,
/// [AbstractGeometryImg] for turn arrows, [LaneImg] for lane guidance, [SignpostImg]
/// for directional signs, and [RoadInfoImg] for road shields.
///
/// Images can be rendered to [Uint8List] format suitable for [Image.memory] or
/// to [RenderableImg] which includes both bytes and final dimensions.
///
/// ## See also:
///
/// - [Img] - Plain raster images with fixed size and aspect ratio
/// - [AbstractGeometryImg] - Vector turn arrow images for navigation
/// - [LaneImg] - Vector lane guidance images with rendering options
/// - [SignpostImg] - Vector signpost images for highway exits
/// - [RoadInfoImg] - Vector road shield and label images
/// - [RenderableImg] - Container for rendered image bytes with dimensions
///
/// {@category Images}
abstract class ImgBase extends GemAutoreleaseObject {
  // ignore: unused_element
  ImgBase._() : super(-1);

  ImgBase.init(super.id);

  // Cached uid. Computed on first access via _fetchUid; subsequent reads
  // are free. Safe because the SDK contract guarantees uid is content-stable
  // for the lifetime of a wrapper. The exception is "live" SignpostImg
  // handles, which bypass the cache entirely via `isCacheable => false`, so
  // their uid is never used as a cache key.
  late final int _cachedUid = _fetchUid();

  int _fetchUid() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ImgFlutter',
      'getUid',
    );

    return resultString['result'];
  }

  /// Unique identifier for this image instance.
  ///
  /// Two images with the same UID contain identical content, allowing UI
  /// optimization by avoiding unnecessary redraws when the image hasn't changed.
  /// Compare UIDs to determine if an image update is needed.
  ///
  /// ## Returns
  ///
  /// - The unique integer identifier for this image
  int get uid => _cachedUid;

  /// Whether renders of this image may be memoized by [ImgCache].
  ///
  /// Default is `true`. Subclasses whose bytes depend on shared mutable state
  /// (notably `SignpostImg`, whose "live" handles render from the active
  /// `NavigationInstruction` at call time) override to `false` so the cache
  /// is bypassed.
  @protected
  bool get isCacheable => true;

  // Cached imageType; identical rationale to _cachedUid above.
  late final ImageType _cachedImageType = _fetchImageType();

  ImageType _fetchImageType() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ImgFlutter',
      'getType',
    );
    return ImageTypeExtension.fromId(resultString['result']);
  }

  /// Category of this image indicating its source and purpose.
  ///
  /// ## Returns
  ///
  /// - The [ImageType] enum value (base, abstractGeometry, roadInfo, signpost, or lane)
  ImageType get imageType => _cachedImageType;

  /// Whether the SDK has valid image data available.
  ///
  /// Always check this before calling [getRenderableImage] or [getRenderableImageBytes],
  /// as those methods return null when the image is invalid.
  ///
  /// ## Returns
  ///
  /// - `true` if valid image data exists, `false` otherwise
  bool get isValid {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ImgFlutter',
      'isValid',
    );

    return resultString['result'] == 1;
  }

  /// Retrieves image bytes suitable for display with [Image.memory].
  ///
  /// Convenience method that returns only the raw bytes from [getRenderableImage].
  /// Use when you don't need the final rendered dimensions.
  ///
  /// ## Parameters
  ///
  /// - [size] - Optional desired image size (width, height). If omitted, uses SDK-recommended size
  /// - [format] - Desired image format (default: [ImageFileFormat.png])
  ///
  /// ## Returns
  ///
  /// - Image bytes as [Uint8List] if [isValid] is true, null otherwise
  ///
  /// ## See also:
  ///
  /// - [getRenderableImage] - Returns [RenderableImg] with bytes and dimensions
  Uint8List? getRenderableImageBytes({
    Size? size,
    ImageFileFormat format = ImageFileFormat.png,
  }) {
    return getRenderableImage(size: size, format: format)?.bytes;
  }

  /// Retrieves image data with both bytes and actual rendered dimensions.
  ///
  /// Returns a [RenderableImg] containing the image bytes plus the final width
  /// and height produced by the SDK. Use when you need to know the actual rendered
  /// size, especially with vector images or when using `allowResize` in subclasses.
  ///
  /// ## Parameters
  ///
  /// - [size] - Optional desired image size (width, height). If omitted, uses SDK-recommended size
  /// - [format] - Desired image format (default: [ImageFileFormat.png])
  ///
  /// ## Returns
  ///
  /// - [RenderableImg] with bytes and dimensions if [isValid] is true, null otherwise
  ///
  /// ## See also:
  ///
  /// - [getRenderableImageBytes] - Returns only raw bytes without dimensions
  RenderableImg? getRenderableImage({
    Size? size,
    ImageFileFormat format = ImageFileFormat.png,
  }) {
    return cachedFlutterImgCall(
      widthPx: size != null ? size.width.toInt() : -1,
      heightPx: size != null ? size.height.toInt() : -1,
      format: format,
      arg: null,
      settingsHash: 0,
      allowResize: false,
    );
  }

  /// Memoized variant of `GemKitPlatform.callGetFlutterImg`.
  ///
  /// Consults [ImgCache] keyed by `(uid, size, format, settingsHash,
  /// imageType, allowResize)`. On a miss, performs the FFI call and stores
  /// the result. Subclasses that report `isCacheable => false` (currently
  /// only `SignpostImg`) bypass the cache entirely.
  RenderableImg? cachedFlutterImgCall({
    required int widthPx,
    required int heightPx,
    required ImageFileFormat format,
    required String? arg,
    required int settingsHash,
    required bool allowResize,
  }) {
    if (!isCacheable) {
      return GemKitPlatform.instance.callGetFlutterImg(
        pointerId,
        widthPx,
        heightPx,
        format.id,
        arg: arg,
        allowResize: allowResize,
      );
    }
    final ImgCacheKey key = ImgCacheKey(
      uid: uid,
      widthPx: widthPx,
      heightPx: heightPx,
      formatId: format.id,
      settingsHash: settingsHash,
      imageTypeId: imageType.id,
      allowResize: allowResize,
    );
    final RenderableImg? cached = ImgCache.instance.get(key);
    if (cached != null) {
      return cached;
    }
    final RenderableImg? fresh = GemKitPlatform.instance.callGetFlutterImg(
      pointerId,
      widthPx,
      heightPx,
      format.id,
      arg: arg,
      allowResize: allowResize,
    );
    if (fresh != null) {
      ImgCache.instance.put(key, fresh);
    }
    return fresh;
  }

  /// Whether the image uses a vector format and supports lossless scaling.
  ///
  /// Vector images can be rendered at any size without quality degradation.
  /// Raster images return false and may show pixelation when scaled.
  ///
  /// ## Returns
  ///
  /// - `true` for vector/scalable images, `false` for raster images
  bool get isScalable {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ImgFlutter',
      'isScalable',
    );

    return resultString['result'] == 1;
  }
}

/// Plain raster image with recommended size and aspect ratio.
///
/// Represents non-vector images backed by raw data ([Uint8List]) or loaded from
/// assets. Unlike SDK-generated vector images ([AbstractGeometryImg], [LaneImg],
/// etc.), [Img] has a recommended [size] and [aspectRatio] but can be resized
/// to any dimensions (with possible quality loss for raster formats).
///
/// Create instances using the constructor with image data, or load from asset
/// bundles using [Img.fromAsset].
///
/// ## See also:
///
/// - [ImgBase] - Base class providing core image functionality
/// - [RenderableImg] - Container for rendered bytes with dimensions
/// - [AbstractGeometryImg] - For SDK-generated vector turn arrows
///
/// {@category Images}
class Img extends ImgBase {
  /// Creates an image from raw byte data.
  ///
  /// Constructs an [Img] from a [Uint8List] containing encoded image data.
  /// The format can be explicitly specified or auto-detected.
  ///
  /// ## Parameters
  ///
  /// - [data] - Raw image bytes (PNG, JPEG, etc.)
  /// - [format] - Image format (default: [ImageFileFormat.autoDetect])
  factory Img(
    Uint8List data, {
    ImageFileFormat format = ImageFileFormat.autoDetect,
  }) {
    final dynamic gemImage = GemKitPlatform.instance.createGemImage(
      data,
      format.id,
    );

    try {
      final String resultString = GemKitPlatform.instance.callCreateObject(
        jsonEncode(<String, dynamic>{'class': 'ImgFlutter', 'args': gemImage}),
      );
      final dynamic decodedVal = jsonDecode(resultString);
      final Img retVal = Img.init(decodedVal['result']);
      return retVal;
    } finally {
      GemKitPlatform.instance.deleteCPointer(gemImage, ObjType.gemImage);
    }
  }

  // ignore: unused_element
  Img._() : super._();

  Img.init(super.id) : super.init();

  /// Loads an image from the app's asset bundle.
  ///
  /// Asynchronously reads image data from the specified asset path and constructs
  /// an [Img] instance. The image format is auto-detected.
  ///
  /// ## Parameters
  ///
  /// - [key] - Asset path (e.g., 'assets/icon.png')
  /// - [bundle] - Optional bundle to load from (default: [rootBundle])
  ///
  /// ## Returns
  ///
  /// - A Future resolving to an [Img] instance
  static Future<Img> fromAsset(String key, {AssetBundle? bundle}) async {
    bundle ??= rootBundle;

    final ByteData byteData = await bundle.load(key);
    final ByteBuffer buffer = byteData.buffer;
    final Uint8List uint8list = buffer.asUint8List();

    return Img(uint8list);
  }

  /// SDK-recommended dimensions for optimal rendering.
  ///
  /// Returns the preferred width and height for this image. When no size is
  /// specified in rendering methods, this recommendation is used for retrieving
  /// the image via [getRenderableImage] or [getRenderableImageBytes].
  ///
  /// ## Returns
  ///
  /// - [Size] with recommended width and height
  Size get size {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ImgFlutter',
      'getSize',
    );

    final Map<String, dynamic> decodedVal = resultString['result'];
    return Size(decodedVal['first'] + 0.0, decodedVal['second'] + 0.0);
  }

  /// SDK-recommended aspect ratio for proportional display.
  ///
  /// Returns width divided by height as a convenience for UI layout calculations
  /// that need to maintain the image's proportions.
  ///
  /// ## Returns
  ///
  /// - Aspect ratio as a double (width / height)
  double get aspectRatio {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ImgFlutter',
      'getAspectRatioF',
    );

    return resultString['result'];
  }
}

/// Vector turn arrow image for navigation instructions.
///
/// SDK-generated vector image representing turn maneuvers and abstract geometry
/// in navigation UI. Supports lossless scaling to any size ([isScalable] returns true).
///
/// Cannot be instantiated by users - only provided by the SDK through [TurnDetails.abstractGeometryImg]
/// and [RouteInstructionBase.realisticNextTurnImg].
///
/// Customize appearance using [AbstractGeometryImageRenderSettings] to control
/// active/inactive colors for inner and outer elements.
///
/// ## See also:
///
/// - [TurnDetails] - Contains abstract geometry images for turn instructions
/// - [AbstractGeometryImageRenderSettings] - Customize rendering colors
///
/// {@category Images}
class AbstractGeometryImg extends ImgBase {
  @internal
  AbstractGeometryImg.init(super.id) : super.init();

  /// Retrieves image with bytes and actual rendered dimensions.
  ///
  /// ## Parameters
  ///
  /// - [size] - Optional desired dimensions (width/height in pixels). If omitted, uses SDK default size
  /// - [format] - Output format (default: [ImageFileFormat.png])
  /// - [renderSettings] - Optional [AbstractGeometryImageRenderSettings] to customize active/inactive colors for inner/outer elements
  ///
  /// ## Returns
  ///
  /// - [RenderableImg] containing bytes, width, and height, or null if invalid
  ///
  /// ## See also:
  ///
  /// - [getRenderableImageBytes] - Returns only raw image bytes as [Uint8List]
  /// - [AbstractGeometryImageRenderSettings] - Customize colors and appearance
  @override
  RenderableImg? getRenderableImage({
    Size? size,
    ImageFileFormat format = ImageFileFormat.png,
    AbstractGeometryImageRenderSettings? renderSettings,
  }) {
    renderSettings ??= const AbstractGeometryImageRenderSettings();

    return cachedFlutterImgCall(
      widthPx: size != null ? size.width.toInt() : -1,
      heightPx: size != null ? size.height.toInt() : -1,
      format: format,
      arg: jsonEncode(renderSettings),
      settingsHash: renderSettings.hashCode,
      allowResize: false,
    );
  }

  /// Retrieves image bytes suitable for display with [Image.memory].
  ///
  /// Convenience method that returns only the raw bytes without dimensions.
  /// Internally calls [getRenderableImage] and extracts the bytes.
  ///
  /// ## Parameters
  ///
  /// - [size] - Optional desired dimensions (width/height in pixels). If omitted, uses SDK default size
  /// - [format] - Output format (default: [ImageFileFormat.png])
  /// - [renderSettings] - Optional [AbstractGeometryImageRenderSettings] to customize active/inactive colors for inner/outer elements
  ///
  /// ## Returns
  ///
  /// - Image bytes as [Uint8List] if [isValid] is true, null otherwise
  ///
  /// ## See also:
  ///
  /// - [getRenderableImage] - Returns [RenderableImg] with bytes and dimensions
  /// - [AbstractGeometryImageRenderSettings] - Customize colors and appearance
  @override
  Uint8List? getRenderableImageBytes({
    Size? size,
    ImageFileFormat format = ImageFileFormat.png,
    AbstractGeometryImageRenderSettings? renderSettings,
  }) {
    return getRenderableImage(
      size: size,
      format: format,
      renderSettings: renderSettings,
    )?.bytes;
  }

  @override
  bool get isScalable => true;
}

/// Vector lane guidance image for navigation instructions.
///
/// SDK-generated vector image showing lane guidance arrows and markings for
/// turn-by-turn navigation. Supports lossless scaling to any size ([isScalable]
/// returns true). Cannot be instantiated by users - only provided by the SDK
/// through navigation [NavigationInstruction.laneImg] and
///
/// Customize appearance using [LaneImageRenderSettings] to control colors for
/// active/inactive lanes and background. Set `allowResize` to true to let the SDK
/// choose optimal aspect ratio based on requested height.
///
/// ## See also:
///
/// - [LaneImageRenderSettings] - Customize lane colors and background
/// - [NavigationInstruction] - Provides lane guidance images
///
/// {@category Images}
class LaneImg extends ImgBase {
  @internal
  LaneImg.init(super.id) : super.init();

  /// Retrieves image with bytes and actual rendered dimensions.
  ///
  /// ## Parameters
  ///
  /// - [size] - Optional desired dimensions (width/height in pixels). If omitted, uses SDK recommended size
  /// - [format] - Output format (default: [ImageFileFormat.png])
  /// - [renderSettings] - Optional [LaneImageRenderSettings] to customize lane colors and background
  /// - [allowResize] - When true, SDK chooses optimal width based on height; when false, uses exact size (default: false)
  ///
  /// ## Returns
  ///
  /// - [RenderableImg] containing bytes, width, and height, or null if invalid
  ///
  /// ## See also:
  ///
  /// - [getRenderableImageBytes] - Returns only raw image bytes as [Uint8List]
  /// - [LaneImageRenderSettings] - Customize lane colors and appearance
  @override
  RenderableImg? getRenderableImage({
    Size? size,
    ImageFileFormat format = ImageFileFormat.png,
    LaneImageRenderSettings? renderSettings,
    bool allowResize = false,
  }) {
    renderSettings ??= const LaneImageRenderSettings();

    return cachedFlutterImgCall(
      widthPx: size != null ? size.width.toInt() : -1,
      heightPx: size != null ? size.height.toInt() : -1,
      format: format,
      arg: jsonEncode(renderSettings),
      settingsHash: renderSettings.hashCode,
      allowResize: allowResize,
    );
  }

  /// Retrieves image bytes suitable for display with [Image.memory].
  ///
  /// Convenience method that returns only the raw bytes without dimensions.
  /// Internally calls [getRenderableImage] and extracts the bytes.
  ///
  /// ## Parameters
  ///
  /// - [size] - Optional desired dimensions (width/height in pixels). If omitted, uses SDK recommended size
  /// - [format] - Output format (default: [ImageFileFormat.png])
  /// - [renderSettings] - Optional [LaneImageRenderSettings] to customize lane colors and background
  /// - [allowResize] - When true, SDK chooses optimal width based on height; when false, uses exact size (default: false)
  ///
  /// ## Returns
  ///
  /// - Image bytes as [Uint8List] if [isValid] is true, null otherwise
  ///
  /// ## See also:
  ///
  /// - [getRenderableImage] - Returns [RenderableImg] with bytes and dimensions
  /// - [LaneImageRenderSettings] - Customize lane colors and appearance
  @override
  Uint8List? getRenderableImageBytes({
    Size? size,
    ImageFileFormat format = ImageFileFormat.png,
    LaneImageRenderSettings? renderSettings,
    bool allowResize = false,
  }) {
    return getRenderableImage(
      size: size,
      format: format,
      renderSettings: renderSettings,
      allowResize: allowResize,
    )?.bytes;
  }

  @override
  bool get isScalable => true;
}

/// Vector signpost image for directional navigation signs.
///
/// SDK-generated vector image representing directional road signs (exit signs,
/// destination boards, etc.) in navigation UI. Supports lossless scaling to any
/// size ([isScalable] returns true). Cannot be instantiated by users - only
/// provided via [SignpostDetails.image] in navigation instructions.
///
/// Customize appearance using [SignpostImageRenderSettings] to control layout
/// (border width, row height, max rows). Set `allowResize` to true to let the SDK
/// choose optimal aspect ratio based on requested height.
///
/// ## Important note on navigation sessions
///
/// At creation time, each [SignpostImg] is tagged by the native layer with
/// its source: if the underlying signpost matched the one carried by the
/// currently-active [NavigationInstruction]
/// (`NavigationService.getNavigationInstruction()`), the handle is flagged
/// as "live". Calls on a live handle render from whatever
/// [NavigationInstruction] is currently published by `NavigationService`,
/// not from the memory captured when the handle was created. This means
/// a [SignpostImg] retained across instruction updates (next step, rematch,
/// route recalculation, arrival) keeps rendering the active instruction's
/// signpost rather than use-after-freeing into recycled native memory.
///
/// Handles obtained from a [RouteInstructionBase] or from a
/// [SignpostDetails] that did not correspond to the active instruction at
/// creation time (route preview, static route-instruction list, off-map
/// inspection) render from the image captured when the handle was
/// produced, as before.
///
/// ## See also:
///
/// - [SignpostImageRenderSettings] - Customize layout and borders
/// - [SignpostDetails.image] - The accessor that produces this handle
///
/// {@category Images}
class SignpostImg extends ImgBase {
  @internal
  SignpostImg.init(super.id) : super.init();

  // Live signpost handles render from whatever NavigationInstruction is
  // active at call time, so the underlying bytes can change without uid
  // updating. Skip the cache entirely; the native renderer remains the
  // source of truth.
  @override
  bool get isCacheable => false;

  /// Retrieves image with bytes and actual rendered dimensions.
  ///
  /// ## Parameters
  ///
  /// - [size] - Optional desired dimensions (width/height in pixels). If omitted, uses SDK recommended size
  /// - [format] - Output format (default: [ImageFileFormat.png])
  /// - [renderSettings] - Optional [SignpostImageRenderSettings] to customize layout (border, rows, etc.)
  /// - [allowResize] - When true, SDK chooses optimal width based on height; when false, uses exact size (default: false)
  ///
  /// ## Returns
  ///
  /// - [RenderableImg] containing bytes, width, and height, or null if invalid
  ///
  /// ## See also:
  ///
  /// - [getRenderableImageBytes] - Returns only raw image bytes as [Uint8List]
  /// - [SignpostImageRenderSettings] - Customize layout and appearance
  @override
  RenderableImg? getRenderableImage({
    Size? size,
    ImageFileFormat format = ImageFileFormat.png,
    SignpostImageRenderSettings? renderSettings,
    bool allowResize = false,
  }) {
    renderSettings ??= const SignpostImageRenderSettings();

    // isCacheable is false here, so cachedFlutterImgCall short-circuits
    // directly to the FFI without touching ImgCache.
    return cachedFlutterImgCall(
      widthPx: size != null ? size.width.toInt() : -1,
      heightPx: size != null ? size.height.toInt() : -1,
      format: format,
      arg: jsonEncode(renderSettings),
      settingsHash: renderSettings.hashCode,
      allowResize: allowResize,
    );
  }

  /// Retrieves image bytes suitable for display with `Image.memory`.
  ///
  /// Convenience method that returns only the raw bytes without dimensions.
  /// Internally calls [getRenderableImage] and extracts the bytes.
  ///
  /// ## Parameters
  ///
  /// - [size] - Optional desired dimensions (width/height in pixels). If omitted, uses SDK recommended size
  /// - [format] - Output format (default: [ImageFileFormat.png])
  /// - [renderSettings] - Optional [SignpostImageRenderSettings] to customize layout (border, rows, etc.)
  /// - [allowResize] - When true, SDK chooses optimal width based on height; when false, uses exact size (default: false)
  ///
  /// ## Returns
  ///
  /// - Image bytes as [Uint8List] if [isValid] is true, null otherwise
  ///
  /// ## See also:
  ///
  /// - [getRenderableImage] - Returns [RenderableImg] with bytes and dimensions
  /// - [SignpostImageRenderSettings] - Customize layout and appearance
  @override
  Uint8List? getRenderableImageBytes({
    Size? size,
    ImageFileFormat format = ImageFileFormat.png,
    SignpostImageRenderSettings? renderSettings,
    bool allowResize = false,
  }) {
    return getRenderableImage(
      size: size,
      format: format,
      renderSettings: renderSettings,
      allowResize: allowResize,
    )?.bytes;
  }

  @override
  bool get isScalable => true;
}

/// Vector road shield image for highway and route markers.
///
/// SDK-generated vector image representing road shields (interstate signs, route
/// numbers, highway markers) in navigation and map UI. Supports lossless scaling
/// to any size ([isScalable] returns true). Cannot be instantiated by users - only
/// provided by [RouteInstructionBase.roadInfo].
///
/// Customize appearance using `backgroundColor` parameter to control the rendered
/// background color. Set `allowResize` to true to let the SDK choose optimal
/// aspect ratio based on requested height.
///
/// ## See also:
///
/// - [RoadInfo] - Contains road shield images
///
/// {@category Images}
class RoadInfoImg extends ImgBase {
  @internal
  RoadInfoImg.init(super.id) : super.init();

  /// Retrieves image with bytes and actual rendered dimensions.
  ///
  /// ## Parameters
  ///
  /// - [size] - Optional desired dimensions (width/height in pixels). If omitted, uses SDK recommended size
  /// - [format] - Output format (default: [ImageFileFormat.png])
  /// - [backgroundColor] - Background color (default: [Colors.transparent])
  /// - [allowResize] - When true, SDK chooses optimal width based on height; when false, uses exact size (default: false)
  ///
  /// ## Returns
  ///
  /// - [RenderableImg] containing bytes, width, and height, or null if invalid
  ///
  /// ## See also:
  ///
  /// - [getRenderableImageBytes] - Returns only raw image bytes as [Uint8List]
  @override
  RenderableImg? getRenderableImage({
    Size? size,
    ImageFileFormat format = ImageFileFormat.png,
    Color backgroundColor = Colors.transparent,
    bool allowResize = false,
  }) {
    final Rgba bgColor = backgroundColor.toRgba();

    return cachedFlutterImgCall(
      widthPx: size != null ? size.width.toInt() : -1,
      heightPx: size != null ? size.height.toInt() : -1,
      format: format,
      arg: jsonEncode(bgColor),
      settingsHash: bgColor.hashCode,
      allowResize: allowResize,
    );
  }

  /// Retrieves image bytes suitable for display with [Image.memory].
  ///
  /// Convenience method that returns only the raw bytes without dimensions.
  /// Internally calls [getRenderableImage] and extracts the bytes.
  ///
  /// ## Parameters
  ///
  /// - [size] - Optional desired dimensions (width/height in pixels). If omitted, uses SDK recommended size
  /// - [format] - Output format (default: [ImageFileFormat.png])
  /// - [backgroundColor] - Background color (default: [Colors.transparent])
  /// - [allowResize] - When true, SDK chooses optimal width based on height; when false, uses exact size (default: false)
  ///
  /// ## Returns
  ///
  /// - Image bytes as [Uint8List] if [isValid] is true, null otherwise
  ///
  /// ## See also:
  ///
  /// - [getRenderableImage] - Returns [RenderableImg] with bytes and dimensions
  @override
  Uint8List? getRenderableImageBytes({
    Size? size,
    ImageFileFormat format = ImageFileFormat.png,
    Color backgroundColor = Colors.transparent,
    bool allowResize = false,
  }) {
    return getRenderableImage(
      size: size,
      format: format,
      backgroundColor: backgroundColor,
      allowResize: allowResize,
    )?.bytes;
  }

  @override
  bool get isScalable => true;
}

/// Image category used by SDK subsystems for classification.
///
/// Distinguishes where an image originates or how it should be interpreted
/// by consumers. Different image types support different rendering options
/// and use cases (for example lane guidance images support [LaneImageRenderSettings]
/// while signpost icons use [SignpostImageRenderSettings]).
///
/// Different image types support different sizing and rendering options.
///
/// ## See also:
///
/// - [ImgBase] - Base class providing access to image type information
/// - [LaneImg] - Uses [ImageType.lane] for lane guidance images
/// - [SignpostImg] - Uses [ImageType.signpost] for directional signs
/// - [AbstractGeometryImg] - Uses [ImageType.abstractGeometry] for turn arrows
/// - [RoadInfoImg] - Uses [ImageType.roadInfo] for road shields and labels
///
/// {@category Images}
enum ImageType {
  /// Generic image from the image database.
  ///
  /// Standard images stored in the SDK's image database, typically used for
  /// map markers, icons, and general-purpose visual elements.
  base,

  /// Turn arrow or abstract geometry image for navigation instructions.
  ///
  /// Vector-based turn arrow images generated from [TurnDetails] for displaying
  /// upcoming maneuvers in navigation UI.
  abstractGeometry,

  /// Road shield or label image for road information display.
  ///
  /// Images showing road numbers, shields, and labels provided by [RoadInfo]
  /// for rendering on map views.
  roadInfo,

  /// Directional sign image for highway exits and destinations.
  ///
  /// Signpost images showing exit information and destination names, provided
  /// by [SignpostDetails] for highway navigation display.
  signpost,

  /// Lane guidance image showing recommended lanes for maneuvers.
  ///
  /// Vector-based lane guidance images from [NavigationInstruction] indicating
  /// which lanes drivers should use for upcoming turns.
  lane,
}

/// @nodoc
extension ImageTypeExtension on ImageType {
  int get id {
    switch (this) {
      case ImageType.base:
        return 0;
      case ImageType.abstractGeometry:
        return 1;
      case ImageType.roadInfo:
        return 2;
      case ImageType.signpost:
        return 3;
      case ImageType.lane:
        return 4;
    }
  }

  static ImageType fromId(int id) {
    switch (id) {
      case 0:
        return ImageType.base;
      case 1:
        return ImageType.abstractGeometry;
      case 2:
        return ImageType.roadInfo;
      case 3:
        return ImageType.signpost;
      case 4:
        return ImageType.lane;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
