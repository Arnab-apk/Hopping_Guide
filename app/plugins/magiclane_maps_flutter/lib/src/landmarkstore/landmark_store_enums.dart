// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Supported file formats for importing landmarks.
///
/// Use these values with import methods such as [LandmarkStore.importLandmarks] and
/// [LandmarkStore.importLandmarksWithDataBuffer] to indicate the data format being provided.
///
/// {@category Landmark Store}
enum LandmarkFileFormat {
  /// Unknown or unsupported format.
  unknown,

  /// KML format.
  kml,

  /// GeoJSON format.
  geoJson,
}

/// @nodoc
extension LandmarkFileFormatExtension on LandmarkFileFormat {
  int get id {
    switch (this) {
      case LandmarkFileFormat.unknown:
        return 0;
      case LandmarkFileFormat.kml:
        return 1;
      case LandmarkFileFormat.geoJson:
        return 2;
    }
  }

  static LandmarkFileFormat fromId(final int id) {
    switch (id) {
      case 0:
        return LandmarkFileFormat.unknown;
      case 1:
        return LandmarkFileFormat.kml;
      case 2:
        return LandmarkFileFormat.geoJson;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Types of landmark stores available in the SDK.
///
/// Identifies the origin and capabilities of a store.
///
/// {@category Landmark Store}
enum LandmarkStoreType {
  /// No landmark store type.
  none,

  /// Regular user or application-defined landmark store.
  defaultType,

  /// Address database provided by the map (read-only).
  mapAddress,

  /// Map POIs store (read-only; browse operations might be limited).
  mapPoi,

  /// City database provided by the map.
  mapCity,

  /// Highway exit dataset provided by the map.
  mapHighwayExit,

  /// Country dataset provided by the map.
  mapCountry,

  /// Road-related dataset provided by the map.
  mapRoads,

  /// Overlay dataset (e.g., user overlays).
  overlays,

  /// Geofence dataset.
  geofence,
}

/// @nodoc
extension LandmarkStoreTypeExtension on LandmarkStoreType {
  int get id {
    switch (this) {
      case LandmarkStoreType.none:
        return 0;
      case LandmarkStoreType.defaultType:
        return 1;
      case LandmarkStoreType.mapAddress:
        return 2;
      case LandmarkStoreType.mapPoi:
        return 3;
      case LandmarkStoreType.mapCity:
        return 4;
      case LandmarkStoreType.mapHighwayExit:
        return 5;
      case LandmarkStoreType.mapCountry:
        return 6;
      case LandmarkStoreType.mapRoads:
        return 7;
      case LandmarkStoreType.overlays:
        return 8;
      case LandmarkStoreType.geofence:
        return 9;
    }
  }

  static LandmarkStoreType fromId(final int id) {
    switch (id) {
      case 0:
        return LandmarkStoreType.none;
      case 1:
        return LandmarkStoreType.defaultType;
      case 2:
        return LandmarkStoreType.mapAddress;
      case 3:
        return LandmarkStoreType.mapPoi;
      case 4:
        return LandmarkStoreType.mapCity;
      case 5:
        return LandmarkStoreType.mapHighwayExit;
      case 6:
        return LandmarkStoreType.mapCountry;
      case 7:
        return LandmarkStoreType.mapRoads;
      case 8:
        return LandmarkStoreType.overlays;
      case 9:
        return LandmarkStoreType.geofence;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
