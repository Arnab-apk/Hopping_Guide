// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:typed_data';

import 'package:magiclane_maps_flutter/map.dart';

/// @nodoc
Uint8List serializeListOfMarkers(final List<MarkerWithRenderSettings> markers) {
  int totalLength = 4; // Initial 4 bytes for the length of the list

  // Calculate the total length of the binary data
  for (final MarkerWithRenderSettings marker in markers) {
    totalLength += marker.toBinary().length;
  }

  final ByteData buffer = ByteData(totalLength);
  int offset = 0;

  // Write the length of the list
  buffer.setInt32(offset, markers.length, Endian.little);
  offset += 4;

  // Serialize each MarkerWithRenderSettings and append to the buffer
  for (final MarkerWithRenderSettings marker in markers) {
    final Uint8List markerData = marker.toBinary();
    buffer.buffer.asUint8List().setRange(
      offset,
      offset + markerData.length,
      markerData,
    );
    offset += markerData.length;
  }

  return buffer.buffer.asUint8List();
}

/// @nodoc
class MarkerInfoSpecialAccess {
  // Static method to access the imagePointer of a MarkerJson instance
  static dynamic getImagePointer(final MarkerRenderSettings markerJson) {
    return markerJson.imagePointer;
  }

  // Static method to access the imagePointerSize of a MarkerJson instance
  static dynamic getImagePointerSize(final MarkerRenderSettings markerJson) {
    return markerJson.imagePointerSize;
  }

  static void updateImagePointerValueRenderSettings(
    final MarkerRenderSettings settings,
    final dynamic value,
  ) {
    settings.imagePointer = value;
  }

  static void updateImagePointerSizeRenderSettings(
    final MarkerRenderSettings settings,
    final dynamic value,
  ) {
    settings.imagePointerSize = value;
  }
}
