// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

/// Utilities for decoding raw image bytes into Flutter `ui.Image` objects.
///
/// [ImageHandler] provides a single helper to decode raw image data
/// asynchronously. The implementation returns a [Future] which completes
/// with a decoded [ui.Image] or `null` if decoding fails. This API is
/// intended for internal SDK usage where a lightweight, synchronous image
/// decoder is not available.
///
/// {@category Images}
abstract class ImageHandler {
  /// Decode raw image bytes into a [ui.Image] asynchronously.
  ///
  /// This method decodes the provided [data] buffer into a [ui.Image]. The
  /// operation is performed asynchronously and the returned `Future` will
  /// complete once decoding finishes. If decoding fails the `Future` will
  /// complete with `null`.
  ///
  /// ## Parameters
  ///
  /// - [data]: Raw image bytes to decode (PNG, JPEG or raw pixel data as
  ///   supported by the underlying platform).
  /// - [width]: Desired width for the decoded image. When applicable the
  ///   decoder may use this to scale or interpret the input. Defaults to 100.
  /// - [height]: Desired height for the decoded image. Defaults to 100.
  ///
  /// ## Returns
  ///
  /// - `Future<ui.Image?>`: Completes with the decoded [ui.Image] on
  ///   success, or `null` when decoding fails.
  static Future<ui.Image?> decodeImageData(
    final Uint8List data, {
    final int width = 100,
    final int height = 100,
  }) async {
    final Completer<ui.Image?> completer = Completer<ui.Image?>();

    ui.decodeImageFromPixels(data, width, height, ui.PixelFormat.rgba8888, (
      final ui.Image img,
    ) async {
      completer.complete(img);
    });

    return completer.future;
  }
}
