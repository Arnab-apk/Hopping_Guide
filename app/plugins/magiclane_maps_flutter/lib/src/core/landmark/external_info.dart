// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/holders.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Wikipedia information for a [Landmark].
///
/// An [ExternalInfo] instance exposes article metadata (title, summary,
/// language and URL) and image-related helpers (count, titles, URLs and
/// asynchronous loaders). Instances are created by the platform and returned
/// via [ExternalInfoService.requestWikiInfo]; do not construct this class
/// directly.
///
/// ## See also:
///
/// - [ExternalInfoService.requestWikiInfo] - Request Wikipedia information for a landmark.
///
/// {@category Landmarks}
class ExternalInfo extends GemAutoreleaseObject {
  @internal
  ExternalInfo.init(super.id, final int mapId) : _mapId = mapId;

  final int _mapId;

  int get mapId => _mapId;

  @internal
  static ExternalInfo create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'ExternalInfo'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final ExternalInfo retVal = ExternalInfo.init(decodedVal['result'], 0);
    return retVal;
  }

  /// Returns the description for the Wikipedia image at [index].
  ///
  /// The method accesses the platform object directly and returns an empty
  /// string if [index] is invalid.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the image.
  ///
  /// ## Returns
  ///
  /// - `String`: The image description or an empty string when invalid.
  ///
  /// ## Also see:
  ///
  /// - [imagesCount] — Get the total number of images.
  String getWikiImageDescription(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ExternalInfo',
      'getWikiImageDescription',
      args: index,
    );

    return resultString['result'];
  }

  /// Number of images found on the Wikipedia page.
  ///
  /// ## Returns
  ///
  /// - `int`: Number of images available for the article.
  int get imagesCount {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ExternalInfo',
      'getWikiImagesCount',
    );

    return resultString['result'];
  }

  /// Returns the title for the Wikipedia image at [index].
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the image.
  ///
  /// ## Returns
  ///
  /// - `String`: The image title or an empty string when invalid.
  ///
  /// ## Also see:
  ///
  /// - [imagesCount] — Get the total number of images.
  String getWikiImageTitle(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ExternalInfo',
      'getWikiImageTitle',
      args: index,
    );

    return resultString['result'];
  }

  /// Returns the direct URL for the Wikipedia image at [index].
  ///
  /// Returns the original image URL, which may be large in size. For
  /// thumbnails, consider using [requestWikiImage] with the desired
  /// [ExternalImageQuality].
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the image.
  ///
  /// ## Returns
  ///
  /// - `String`: The image URL or an empty string when invalid.
  ///
  /// ## Also see:
  ///
  /// - [imagesCount] — Get the total number of images.
  String getWikiImageUrl(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ExternalInfo',
      'getWikiImageURL',
      args: index,
    );

    return resultString['result'];
  }

  /// Short textual summary of the Wikipedia page.
  ///
  /// It is influenced by the selected SDK language and the availability of
  /// localized content on Wikipedia. Check the [wikiPageLanguage] to determine
  /// the language of the summary.
  ///
  /// ## Returns
  ///
  /// - `String`: The page summary text.
  String get wikiPageDescription {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ExternalInfo',
      'getWikiPageDescription',
    );

    return resultString['result'];
  }

  /// Language code of the retrieved Wikipedia page (for example `en`).
  ///
  /// ## Returns
  ///
  /// - `String`: Page language code.
  String get wikiPageLanguage {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ExternalInfo',
      'getWikiPageLanguage',
    );

    return resultString['result'];
  }

  /// Title of the Wikipedia page in the currently selected SDK language.
  ///
  /// ## Returns
  ///
  /// - `String`: The page title.
  String get wikiPageTitle {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ExternalInfo',
      'getWikiPageTitle',
    );

    return resultString['result'];
  }

  /// Canonical URL of the Wikipedia page.
  ///
  /// ## Returns
  ///
  /// - `String`: The page URL.
  String get wikiPageUrl {
    final OperationResult resultString = objectMethod(
      pointerId,
      'ExternalInfo',
      'getWikiPageURL',
    );

    return resultString['result'];
  }

  /// Asynchronously requests information about a Wikipedia image.
  ///
  /// The information (for example metadata or an information string) is
  /// delivered via [onComplete]. A [ProgressListener] is returned when the
  /// operation starts and can be used to monitor or cancel the request.
  ///
  /// ## Parameters
  ///
  /// - [imageIndex]: Zero-based index of the requested image.
  /// - [onComplete]: Callback invoked when the request completes. Depending on
  ///   the result, the callback receives a [GemError] and the optional image:
  ///   - [GemError.success] for `err` and the image info string for `imageInfo` on success.
  ///   - [GemError.general] describing the failure reason and `null` for `imageInfo` on error.
  ///
  /// ## Returns
  ///
  /// - `ProgressListener?`: A progress listener when the operation started,
  ///   otherwise `null`.
  ///
  /// ## Example:
  ///
  /// ```dart
  /// externalInfo.requestWikiImageInfo(
  ///  imageIndex: 0,
  ///  onComplete: (err, info) {
  ///     if (err == GemError.success) {
  ///       print('Successfully retrieved Wiki image info.');
  ///       // Use the retrieved info as needed
  ///     } else if (info != null) {
  ///       print('Failed to retrieve Wiki image info.');
  ///     }
  ///   },
  /// );
  /// ```
  ///
  /// ## Also see:
  ///
  /// - [imageIndex] — Get the total number of images.
  /// - [requestWikiImage] — Request Wikipedia image.
  /// - [cancelWikiImageInfoRequest] — Cancel a pending image info request.
  ProgressListener? requestWikiImageInfo({
    required int imageIndex,
    required void Function(GemError error, String? imageInfo) onComplete,
  }) {
    final StringHolder result = StringHolder();
    final EventDrivenProgressListener listener = EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    listener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
      if (err == 0) {
        onComplete(GemErrorExtension.fromCode(err), result.value);
      } else {
        onComplete(GemErrorExtension.fromCode(err), null);
      }
      result.dispose();
    });

    objectMethod(
      pointerId,
      'ExternalInfo',
      'requestWikiImageInfo',
      args: <String, dynamic>{
        'progressListener': listener.id,
        'nImageIdx': imageIndex,
        'strImageInfo': result.pointerId,
      },
    );

    final GemError err = ApiErrorService.apiError;
    if (err != GemError.success) {
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
      onComplete(err, null);
      return null;
    }

    return listener;
  }

  /// Asynchronously requests the binary image data for a Wikipedia image.
  ///
  /// The image is requested in the requested [quality]. The result is
  /// provided via [onComplete] as an [Img] (or `null` on error). A
  /// [ProgressListener] is returned when the request starts.
  ///
  /// ## Parameters
  ///
  /// - [imageIndex]: Zero-based index of the requested image.
  /// - [quality]: Desired image quality ([ExternalImageQuality]).
  /// - [onComplete]: Callback invoked when the request completes. Depending on
  ///   the result, the callback receives a [GemError] and the optional image:
  ///   - [GemError.success] for `err` and the image info string for `image` on success.
  ///   - [GemError.general] for failure and `null` for `image` on error.
  ///
  /// ## Returns
  ///
  /// - `ProgressListener?`: A progress listener when the operation started,
  ///   otherwise `null`.
  ///
  /// ## Example:
  /// ```dart
  /// externalInfo.requestWikiImage(
  ///   imageIndex: 0,
  ///   quality: ExternalImageQuality.highImageQuality,
  ///   onComplete: (err, info) {
  ///     if (err == GemError.success) {
  ///       print('Successfully retrieved Wiki image.');
  ///       // Use the retrieved info as needed
  ///     } else if (info != null) {
  ///       print('Failed to retrieve Wiki image info.');
  ///     }
  ///   },
  /// );
  /// ```
  ///
  /// ## Also see:
  ///
  /// - [imageIndex] — Get the total number of images.
  /// - [requestWikiImageInfo] — Request Wikipedia image metadata.
  ProgressListener? requestWikiImage({
    required int imageIndex,
    required ExternalImageQuality quality,
    required void Function(GemError error, Img? image) onComplete,
  }) {
    final ImgHolder result = ImgHolder();
    final EventDrivenProgressListener listener = EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    listener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
      if (err == 0) {
        onComplete(GemErrorExtension.fromCode(err), result.value);
      } else {
        onComplete(GemErrorExtension.fromCode(err), null);
      }
      result.dispose();
    });

    objectMethod(
      pointerId,
      'ExternalInfo',
      'requestWikiImage',
      args: <String, dynamic>{
        'progressListener': listener.id,
        'nImageIdx': imageIndex,
        'image': result.pointerId,
        'imageQuality': quality.id,
      },
    );

    final GemError err = ApiErrorService.apiError;
    if (err != GemError.success) {
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
      onComplete(err, null);
      return null;
    }

    return listener;
  }

  /// Cancel a pending image info request previously started by
  /// [requestWikiImageInfo].
  ///
  /// ## Parameters
  ///
  /// - [listener]: The [ProgressListener] returned by [requestWikiImageInfo].
  void cancelWikiImageInfoRequest(ProgressListener listener) {
    staticMethod(
      'ExternalInfo',
      'cancelWikiImageInfoRequest',
      args: listener.id,
    );
  }
}

/// Represents the quality of an external image.
///
/// See more info: https://www.mediawiki.org/wiki/Common_thumbnail_sizes
/// {@category Landmarks}
enum ExternalImageQuality {
  /// Low image quality.
  lowImageQuality,

  /// Medium image quality.
  mediumImageQuality,

  /// High image quality.
  highImageQuality,
}

/// @nodoc
extension ExternalImageQualityExtension on ExternalImageQuality {
  int get id {
    switch (this) {
      case ExternalImageQuality.lowImageQuality:
        return 250;
      case ExternalImageQuality.mediumImageQuality:
        return 500;
      case ExternalImageQuality.highImageQuality:
        return 960;
    }
  }

  static ExternalImageQuality fromId(int id) {
    switch (id) {
      case 250:
        return ExternalImageQuality.lowImageQuality;
      case 500:
        return ExternalImageQuality.mediumImageQuality;
      case 960:
        return ExternalImageQuality.highImageQuality;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
