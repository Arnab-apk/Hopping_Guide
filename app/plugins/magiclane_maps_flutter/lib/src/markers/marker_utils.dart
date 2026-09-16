// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Marker info
///
/// {@category Markers}
class MarkerInfo {
  MarkerInfo() {
    screenCoordinatesNotifier = ValueNotifier<XyType<double>>(
      XyType<double>(x: 0.0, y: 0.0),
    );
  }

  /// The marker coordinates
  late Coordinates coords;

  /// The marker screen coordinates
  late XyType<double> screenCoordinates;
  late GemMapController mapController;
  late ValueNotifier<XyType<double>> screenCoordinatesNotifier;

  /// Extra info
  dynamic info;
  //  MarkerInfo({
  //   required this.coordinates,
  //   required this.screenCoordinates,
  //   required this.mapController,
  //   this.info,
  // }) {
  //   // Initialize the positionNotifier with the initial screen coordinates
  //   positionNotifier = ValueNotifier(_calculateInitialOffset());
  // }

  /// Set coordinates
  ///
  /// ## Parameters
  ///
  /// - [value]: The new coordinates
  set coordinates(Coordinates value) {
    coords = value;
  }

  Coordinates get coordinates => coords;

  @override
  bool operator ==(covariant final MarkerInfo other) {
    if (identical(this, other)) {
      return true;
    }
    return other.coords == coords &&
        other.screenCoordinates == screenCoordinates &&
        other.info == info;
  }

  @override
  int get hashCode =>
      coords.hashCode ^ screenCoordinates.hashCode ^ info.hashCode;
}

/// External renderer markers
///
/// {@category Maps & 3D Scenes}
@experimental
class ExternalRendererMarkers {
  Map<int, MarkerInfo> visiblePoints = <int, MarkerInfo>{};
  GemMapController? mapController;
  void Function(dynamic value)? onNotifyCustom;

  void processData(final GemMapController mapController, final dynamic data) {
    final List<dynamic> listJson = data['coordinates'];
    final List<Coordinates> retList = listJson
        .map((final dynamic categoryJson) => Coordinates.fromJson(categoryJson))
        .toList();

    final MarkerInfo markerInfo = MarkerInfo();
    markerInfo.coordinates = retList[0];
    final XyType<double> theF = XyType<double>(
      x: data['screen_coordinates_x'],
      y: data['screen_coordinates_y'],
    );
    if (visiblePoints.containsKey(data['dataMarkerId'])) {
      visiblePoints[data['dataMarkerId']]!.screenCoordinates = theF;
      visiblePoints[data['dataMarkerId']]!.screenCoordinatesNotifier.value =
          XyType<double>(x: theF.x, y: theF.y);
      //visiblePoints[data['dataMarkerId']]!.screenCoordinates.x = visiblePoints[data['dataMarkerId']]!.screenCoordinates.x! * mapController.viewport.width!;
      //visiblePoints[data['dataMarkerId']]!.screenCoordinates.y = visiblePoints[data['dataMarkerId']]!.screenCoordinates.y! * mapController.viewport.height!;
    } else {
      markerInfo.screenCoordinates = theF;
      //  markerInfo.screenCoordinates.x = markerInfo.screenCoordinates.x! * mapController.viewport.width!;
      // markerInfo.screenCoordinates.y = markerInfo.screenCoordinates.y! * mapController.viewport.height!;
      markerInfo.info = jsonDecode(data['info']);
      markerInfo.mapController = mapController;
      // Add to the map
      visiblePoints[data['dataMarkerId']] = markerInfo;
    }
    if (onNotifyCustom != null) {
      onNotifyCustom!(2);
    }
  }

  void removeData(final dynamic markerId) {
    visiblePoints.remove(markerId);
    //visiblePoints.remove();
  }
}

/// Contains a marker and its render settings
///
/// {@category Markers}
class MarkerWithRenderSettings {
  MarkerWithRenderSettings(this.marker, this.settings);

  /// The marker to be rendered
  MarkerJson marker;

  /// The marker render settings
  MarkerRenderSettings settings;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['marker'] = marker;
    json['settings'] = settings;
    return json;
  }

  Uint8List toBinary() {
    final int markerCoordsLength = marker.coords.length;

    // Calculate total bytes required
    int totalBytes = 0;
    totalBytes += 4; // Number of coordinates
    totalBytes +=
        markerCoordsLength *
        16; // 8 bytes for each double (latitude, longitude)

    int nameLength = 0;
    if (marker.name != null) {
      final Uint8List nameBytes = utf8.encode(marker.name!);
      nameLength = nameBytes.length;
      totalBytes += 4; // Length of the name string
      totalBytes += nameLength; // Name string bytes
    } else {
      totalBytes += 4; // Length of the name string (0)
    }

    totalBytes += 8; // polylineInnerSize
    totalBytes += 8; // polylineOuterSize
    totalBytes += 8; // labelTextSize
    totalBytes += 8; // imageSize
    totalBytes += 4; // labelingMode
    if (GemKitPlatform.instance.is32BitSystem) {
      totalBytes += 4;
      totalBytes += 4;
    } else {
      totalBytes += 8; // _imagePointer (assuming 64-bit pointer)
      totalBytes += 8; // _hashValue
    }
    totalBytes += 4; // _imagePointerSize

    // Adding 4 bytes for each color (RGBA)
    totalBytes +=
        4 *
        4; // polylineInnerColor, polylineOuterColor, polygonFillColor, labelTextColor

    final ByteData buffer = ByteData(totalBytes);
    int offset = 0;

    // Serialize MarkerJson
    buffer.setInt32(offset, markerCoordsLength, Endian.little);
    offset += 4;

    for (final Coordinates coord in marker.coords) {
      buffer.setFloat64(offset, coord.latitude, Endian.little);
      offset += 8;
      buffer.setFloat64(offset, coord.longitude, Endian.little);
      offset += 8;
    }

    // Serialize the name string
    buffer.setInt32(offset, nameLength, Endian.little);
    offset += 4;

    if (nameLength > 0) {
      final Uint8List nameBytes = utf8.encode(marker.name!);
      buffer.buffer.asUint8List().setAll(offset, nameBytes);
      offset += nameLength;
    }

    // Serialize MarkerRenderSettings
    buffer.setFloat64(offset, settings.polylineInnerSize, Endian.little);
    offset += 8;

    buffer.setFloat64(offset, settings.polylineOuterSize, Endian.little);
    offset += 8;

    buffer.setFloat64(offset, settings.labelTextSize, Endian.little);
    offset += 8;

    buffer.setFloat64(offset, settings.imageSize, Endian.little);
    offset += 8;

    buffer.setInt32(offset, settings.packedLabelingMode, Endian.little);
    offset += 4;
    if (!GemKitPlatform.instance.is32BitSystem) {
      buffer.setInt64(offset, settings.imagePointer ?? 0, Endian.little);
      offset += 8;
    } else {
      buffer.setInt32(offset, settings.imagePointer ?? 0, Endian.little);
      offset += 4;
    }
    buffer.setInt32(offset, settings.imagePointerSize ?? 0, Endian.little);
    offset += 4;
    if (!GemKitPlatform.instance.is32BitSystem) {
      buffer.setInt64(offset, settings.hashCode, Endian.little);
      offset += 8;
    } else {
      buffer.setInt32(offset, settings.hashCode, Endian.little);
      offset += 4;
    }

    // Serialize Colors
    buffer.setUint8(offset++, (settings.polylineInnerColor.r * 255).toInt());
    buffer.setUint8(offset++, (settings.polylineInnerColor.g * 255).toInt());
    buffer.setUint8(offset++, (settings.polylineInnerColor.b * 255).toInt());
    buffer.setUint8(offset++, (settings.polylineInnerColor.a * 255).toInt());

    buffer.setUint8(offset++, (settings.polylineOuterColor.r * 255).toInt());
    buffer.setUint8(offset++, (settings.polylineOuterColor.g * 255).toInt());
    buffer.setUint8(offset++, (settings.polylineOuterColor.b * 255).toInt());
    buffer.setUint8(offset++, (settings.polylineOuterColor.a * 255).toInt());

    buffer.setUint8(offset++, (settings.polygonFillColor.r * 255).toInt());
    buffer.setUint8(offset++, (settings.polygonFillColor.g * 255).toInt());
    buffer.setUint8(offset++, (settings.polygonFillColor.b * 255).toInt());
    buffer.setUint8(offset++, (settings.polygonFillColor.a * 255).toInt());

    buffer.setUint8(offset++, (settings.labelTextColor.r * 255).toInt());
    buffer.setUint8(offset++, (settings.labelTextColor.g * 255).toInt());
    buffer.setUint8(offset++, (settings.labelTextColor.b * 255).toInt());
    buffer.setUint8(offset++, (settings.labelTextColor.a * 255).toInt());

    return buffer.buffer.asUint8List();
  }
}

/// A simplified representation of a Marker
///
/// {@category Markers}
class MarkerJson {
  MarkerJson({required this.coords, this.name});

  /// Coordinates of the marker
  final List<Coordinates> coords;

  /// Name of the marker
  String? name;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['coords'] = coords;
    if (name != null) {
      json['name'] = name;
    }
    return json;
  }
}
