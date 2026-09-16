// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/holders.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Service helpers to request Wikipedia (External) information for landmarks.
///
/// [ExternalInfoService] provides methods to check the
/// availability of Wikipedia data for a [Landmark], to request the data and
/// to cancel outstanding requests. Request methods are asynchronous and use
/// callbacks to deliver results and errors.
///
/// ## See also:
///
/// - [ExternalInfo] — the data object returned when a request succeeds.
///
/// {@category Landmarks}
abstract class ExternalInfoService {
  /// Checks whether Wikipedia information is available for [landmark].
  ///
  /// This performs a lightweight availability check (title, url, summary and
  /// picture URLs) and returns `true` when the platform reports that wiki
  /// information exists for the supplied landmark.
  ///
  /// ## Parameters
  ///
  /// - [landmark]: The landmark to check for Wikipedia information.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when Wikipedia info is available, otherwise `false`.
  static bool hasWikiInfo(Landmark landmark) {
    return _checkWikiInfo(landmark).$1;
  }

  static (bool, ExternalInfo) _checkWikiInfo(Landmark landmark) {
    final ExternalInfo externalInfo = ExternalInfo.create();
    final OperationResult resultString = objectMethod(
      externalInfo.pointerId,
      'ExternalInfo',
      'hasWikiInfo',
      args: landmark.pointerId,
    );

    return (resultString['result'], externalInfo);
  }

  /// Requests Wikipedia information for [landmark].
  ///
  /// When available, the platform-side Wikipedia data is returned as an
  /// [ExternalInfo] instance via the [onComplete] callback. The callback is
  /// invoked with a [GemError] indicating success or the failure reason and
  /// the [ExternalInfo] object on success.
  ///
  /// The [Landmark] needs to have Wikipedia information available;
  /// use [hasWikiInfo] to check before requesting.
  ///
  /// ## Parameters
  ///
  /// - [landmark]: The landmark for which to request Wikipedia information.
  /// - [onComplete]: Callback invoked when the request completes. The
  ///   callback receives:
  ///     - [GemError.success] for `err` and the [ExternalInfo] instance for `extraInfo` on success.
  ///     - [GemError.general] describing the failure reason and `null` for `extraInfo` on error.
  ///
  /// ## Returns
  ///
  /// - `ProgressListener?`: A listener that can be used to track or cancel the pending
  ///   request, or `null` if the request could not be initiated.
  ///
  /// ## Example:
  /// ```dart
  /// if (!ExternalInfoService.hasWikiInfo(landmark)) {
  ///   print('The landmark does not have Wiki info.');
  ///   return;
  /// }
  ///
  /// ExternalInfoService.requestWikiInfo(landmark, onComplete: (err, info) {
  ///   if (err == GemError.success) {
  ///     print('Successfully retrieved Wiki info.');
  ///     // Use the retrieved info as needed
  ///   } else if (info != null) {
  ///     print('Failed to retrieve Wiki info.');
  ///   }
  /// });
  /// ```
  static ProgressListener? requestWikiInfo(
    Landmark landmark, {
    required void Function(GemError err, ExternalInfo? extraInfo) onComplete,
  }) {
    final (bool hasWikiInfo, ExternalInfo externalInfo) = _checkWikiInfo(
      landmark,
    );
    if (!hasWikiInfo) {
      onComplete(GemError.invalidInput, null);
      return null;
    }

    final ExternalInfoHandler wikiListener = ExternalInfoHandler(externalInfo);

    wikiListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      GemKitPlatform.instance.unregisterEventHandler(wikiListener.id);
      final GemError error = GemErrorExtension.fromCode(err);
      if (error == GemError.success) {
        onComplete(error, externalInfo);
      } else {
        onComplete(error, null);
      }
    });
    GemKitPlatform.instance.registerEventHandler(wikiListener.id, wikiListener);

    objectMethod(
      externalInfo.pointerId,
      'ExternalInfo',
      'requestWikiInfo',
      args: <String, dynamic>{
        'first': landmark.pointerId,
        'second': wikiListener.id,
      },
    );

    return wikiListener;
  }

  /// Cancel a previously started Wikipedia request.
  ///
  /// The provided [operationHandler] must be an instance returned by
  /// [requestWikiInfo] (an `ExternalInfoHandler`).
  ///
  /// ## Parameters
  ///
  /// - [operationHandler]: The progress listener returned by [requestWikiInfo].
  static void cancelWikiInfo(ProgressListener operationHandler) {
    if (operationHandler is! ExternalInfoHandler) {
      ApiErrorServiceImpl.apiErrorAsInt = -1;
      return;
    }

    operationHandler.cancelWikiInfo();
  }
}
