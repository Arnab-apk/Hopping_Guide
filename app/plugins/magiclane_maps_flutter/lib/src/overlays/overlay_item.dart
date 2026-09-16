// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Represents a single item from an overlay dataset.
///
/// An [OverlayItem] models a single POI-like entity exposed by an overlay. It
/// exposes identifiers, coordinates, display image/name and preview data which
/// may be downloaded on demand. This class is provided by the SDK and should
/// not be constructed directly by consumers.
///
/// ## See also:
///
/// - [OverlayInfo] - Parent overlay metadata for this item.
/// - [OverlayCategory] - Category information for this item.
/// - [GemMapController.registerOnCursorSelectionUpdatedOverlayItems] - Method to receive overlay items at the map cursor position.
///
/// {@category Overlays}
class OverlayItem extends GemAutoreleaseObject {
  // ignore: unused_element
  OverlayItem._() : super(-1);

  @internal
  OverlayItem.init(super.id);

  /// Category identifier for this overlay item.
  ///
  /// The returned ID refers to the root category for the item; it might differ
  /// from the direct parent category in multi-level hierarchies.
  ///
  /// ## Returns
  ///
  /// - The root category ID, or 0 when no category is assigned.
  ///
  /// ## See also:
  /// - [OverlayInfo] - Parent overlay metadata for this item.
  /// - [OverlayInfo.getCategory] - Retrieve the [OverlayCategory] for this item.
  int get categoryId {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItem',
      'getCategoryId',
    );

    return resultString['result'];
  }

  /// Item coordinates on the map.
  ///
  /// ## Returns
  ///
  /// - A [Coordinates] instance. When coordinates are not available the returned
  ///   object's [Coordinates.isValid] field will be false.
  Coordinates get coordinates {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItem',
      'coordinates',
    );

    return Coordinates.fromJson(resultString['result']);
  }

  /// Whether this item supports preview extended data (downloadable dynamic data).
  ///
  /// ## Returns
  ///
  /// - True when preview extended data is available for this item type.
  ///
  /// ## See also:
  ///
  /// - [getPreviewExtendedData] - Method to download the extended preview data.
  /// - [previewDataParameterList] - Raw preview data already available with the item.
  bool get hasPreviewExtendedData {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItem',
      'hasPreviewExtendedData',
    );

    return resultString['result'];
  }

  /// Deprecated image accessor. Use [getImage] or [img] instead.
  ///
  /// ## Returns
  ///
  /// - Raw image bytes when available, otherwise an empty [Uint8List].
  @Deprecated('Use getImage method or the img getter instead')
  Uint8List get image {
    return img.getRenderableImageBytes() ?? Uint8List.fromList(<int>[]);
  }

  /// Obtain the overlay item's image bytes in a specific size/format.
  ///
  /// It is also the icon shown on the map for this overlay item.
  ///
  /// ## Parameters
  ///
  /// - [size]: Optional desired image size.
  /// - [format]: Optional image file format.
  ///
  /// ## Returns
  ///
  /// - Image bytes as [Uint8List] if available, otherwise null.
  ///
  /// ## See also:
  ///
  /// - [img] - Get a lightweight [Img] wrapper for the overlay item's image.
  Uint8List? getImage({final Size? size, final ImageFileFormat? format}) {
    return GemKitPlatform.instance.callGetImage(
      pointerId,
      'OverlayItem',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
    );
  }

  /// Get the image as a [Img].
  ///
  /// It is also the icon shown on the map for this overlay item.
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getImage] when you only need raw image bytes.
  ///
  /// ## Returns
  ///
  /// - An [Img] instance; callers should verify the image validity before use.
  Img get img {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItem',
      'img',
    );

    return Img.init(resultString['result']);
  }

  /// Item display name.
  ///
  /// Depends on the current language setting.
  ///
  /// ## Returns
  ///
  /// - The item name as a [String], or an empty string if unavailable.
  String get name {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItem',
      'name',
    );

    return resultString['result'];
  }

  /// Unique identifier of the item within its parent overlay.
  ///
  /// ## Returns
  ///
  /// - The item UID as an [int].
  int get uid {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItem',
      'uid',
    );

    return resultString['result'];
  }

  /// Parent overlay metadata for this item.
  ///
  /// ## Returns
  ///
  /// - The [OverlayInfo] instance, or null when overlay metadata is not available.
  OverlayInfo? get overlayInfo {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItem',
      'overlayinfo',
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return OverlayInfo.init(resultString['result']);
  }

  /// Raw preview data represented as a [SearchableParameterList].
  ///
  /// Use [previewData] to obtain a typed [OverlayItemParameters] when the
  /// preview data corresponds to a known overlay type.
  ///
  /// ## Returns
  ///
  /// - A [SearchableParameterList] containing the preview parameters.
  ///
  /// ## See also:
  ///
  /// - [previewData] - Typed preview data for predefined overlay types.
  SearchableParameterList get previewDataParameterList {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItem',
      'getPreviewData',
    );

    return SearchableParameterList.init(resultString['result']);
  }

  /// Typed preview data for the overlay item, when available.
  ///
  /// The method returns a subclass of [OverlayItemParameters] depending on the
  /// overlay type (for example [PublicTransportParameters], [SafetyParameters]
  /// or [SocialReportParameters]). For unknown/custom preview structures this
  /// property returns null; in that case use [previewDataParameterList].
  ///
  /// ## Returns
  ///
  /// - A concrete [OverlayItemParameters] subtype when recognised, otherwise null.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final OverlayItemParameters? params = item.previewData;
  /// if (params is PublicTransportParameters) {
  ///   print('Stop name: ${params.name}');
  /// }
  /// ```
  ///
  /// ## See also:
  ///
  /// - [previewDataParameterList] - Raw preview data as a [SearchableParameterList].
  /// - [getPreviewExtendedData] - Method to download additional preview data (if available).
  OverlayItemParameters? get previewData {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItem',
      'getPreviewData',
    );

    final List<GemParameter> params = SearchableParameterList.init(
      resultString['result'],
    ).toList();

    final Set<String> keys = <String>{
      for (final GemParameter p in params)
        if (p.key != null && p.key!.isNotEmpty) p.key!,
    };

    if (keys.contains('own_report')) {
      return SocialReportParameters.fromParameters(params);
    }
    if (keys.contains('camera_type_id')) {
      return SafetyParameters.fromParameters(params);
    }
    if (keys.contains('name')) {
      return PublicTransportParameters.fromParameters(params);
    }
    return null;
  }

  /// Convenience typed accessor for [previewData].
  ///
  /// ## Returns
  ///
  /// - The underlying parameters object if it is of type [T], otherwise null.
  T? getPreviewParametersAs<T extends OverlayItemParameters>() {
    final OverlayItemParameters? cp = previewData;
    if (cp is T) {
      return cp;
    }
    return null;
  }

  /// Preview data as a JSON-compatible map.
  ///
  /// ## Returns
  ///
  /// - A JSON-serializable map containing the preview parameters.
  Map<dynamic, dynamic> get previewDataJson {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItem',
      'getPreviewDataJson',
    );

    return jsonDecode(resultString['result']);
  }

  /// Optional web preview URL for the item.
  ///
  /// The URL can be opened by the UI to show more details in a browser window.
  ///
  /// ## Returns
  ///
  /// - The preview URL as a [String], or an empty string when none is available.
  String get previewUrl {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItem',
      'previewurl',
    );

    return resultString['result'];
  }

  /// Parent overlay UID for this item.
  ///
  /// ## Returns
  ///
  /// - The parent overlay UID, or 0 when it is not set.
  ///
  /// ## See also:
  ///
  /// - [overlayInfo] - Parent [OverlayInfo] for this item.
  int get overlayUid {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItem',
      'overlayuid',
    );

    return resultString['result'];
  }

  /// Check whether this item belongs to the specified predefined overlay type.
  ///
  /// ## Parameters
  ///
  /// - [overlayId]: One of the values from [CommonOverlayId].
  ///
  /// ## Returns
  ///
  /// - True when the item's `overlayUid` matches `overlayId.id`.
  bool isOfType(CommonOverlayId overlayId) {
    return overlayUid == overlayId.id;
  }

  /// Retrieve public-transport stop details when available.
  ///
  /// This helper calls [getPreviewExtendedData] and converts the result to a
  /// [PTStopInfo] when the item belongs to [CommonOverlayId.publicTransport].
  ///
  /// ## Returns
  ///
  /// - A [PTStopInfo] when available, otherwise null.
  Future<PTStopInfo?> getPTStopInfo() async {
    final Completer<PTStopInfo?> completer = Completer<PTStopInfo?>();

    if (isOfType(CommonOverlayId.publicTransport)) {
      // Trigger the callback-based async operation
      getPreviewExtendedData((GemError err, SearchableParameterList? params) {
        if (params != null) {
          // If successful, complete the Future with PTStopInfo
          completer.complete(PTStopInfo.fromParameters(params));
        } else {
          // In case of an error or null params, complete with null
          completer.complete(null);
        }
      });
    } else {
      // If the item isn't of the correct type, complete with null
      completer.complete(null);
    }

    // Return the Future that will eventually be completed
    return completer.future;
  }

  /// Asynchronously retrieve the preview extended data for this item.
  ///
  /// The operation is asynchronous and delivers results via the provided
  /// callback.
  ///
  /// ## Parameters
  ///
  /// - [onComplete]: Callback invoked with a [GemError] and a
  ///   [SearchableParameterList] when available.
  ///
  /// ## Parameters
  ///
  /// - [onComplete]: Function called when the operation is completed. The function is called with:
  ///   - [GemError.success] for `error` and non-null `parameters` on success.
  ///   - [GemError.invalidInput] for `error` and null `parameters` if no listener was provided.
  ///   - [GemError.couldNotStart] for `error` and null `parameters` if the request couldn't be started.
  ///   - [GemError.notSupported] for `error` and null `parameters` if called even though [hasPreviewExtendedData] returned false.
  ///   - [GemError.general] for `error` and null `parameters` in any other error case.
  ///   - Other error codes for `error` and null `parameters` if an error occurred.
  ///
  /// ## Returns
  ///
  /// - A [ProgressListener] that can be used to monitor or cancel the operation.
  ///
  /// ## See also:
  ///
  /// - [hasPreviewExtendedData] - Property to check if extended data is available for this item.
  /// - [cancelGetPreviewExtendedData] - Method to cancel a running preview extended data request.
  ProgressListener? getPreviewExtendedData(
    final void Function(GemError error, SearchableParameterList? parameters)
    onComplete,
  ) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);
    final SearchableParameterList params = SearchableParameterList();

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(progListener.id);
      if (err != 0) {
        onComplete(GemErrorExtension.fromCode(err), null);
      } else {
        onComplete(GemErrorExtension.fromCode(err), params);
      }
    });

    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItem',
      'getPreviewExtendedData',
      args: <String, dynamic>{
        'list': params.pointerId,
        'listener': progListener.id,
      },
    );

    final int id = resultString['result'];

    if (id != 0) {
      onComplete(GemErrorExtension.fromCode(id), null);
      return null;
    }

    return progListener;
  }

  /// Cancel a running preview-extended-data request started with
  /// [getPreviewExtendedData].
  ///
  /// ## Parameters
  ///
  /// - [listener]: The [ProgressListener] that identifies the running operation.
  ///
  /// ## See also:
  ///
  /// - [getPreviewExtendedData] - Method to start an asynchronous preview extended data request.
  void cancelGetPreviewExtendedData(final ProgressListener listener) {
    objectMethod(
      pointerId,
      'OverlayItem',
      'cancelGetPreviewExtendedData',
      args: <String, dynamic>{'progress': listener.id},
    );
  }
}
