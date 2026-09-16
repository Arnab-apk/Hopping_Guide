// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// MapCoverage indicates the availability of map data for a region.
///
/// Use this enum to understand whether map tiles are available offline,
/// available via cached tiles, only available online on the server, or
/// unknown.
///
/// {@category Maps & 3D Scenes}
enum MapCoverage {
  /// Data covered by an offline map available on the device. No connection required.
  coverageOffline,

  /// Data covered by the online cache available on the device. No connection required.
  ///
  /// Data is volatile and may be erased after a cache cleanup operation
  coverageOnlineTile,

  /// Data coverage exists, but it is not available on the device. Server connection required.
  coverageOnlineNoData,

  /// There is no map coverage available on the device, and it is not possible to determine if coverage is available on the server.
  coverageUnknown,
}

/// @nodoc
extension MapCoverageExtension on MapCoverage {
  int get id {
    switch (this) {
      case MapCoverage.coverageOffline:
        return 0;
      case MapCoverage.coverageOnlineTile:
        return 1;
      case MapCoverage.coverageOnlineNoData:
        return 2;
      case MapCoverage.coverageUnknown:
        return 3;
    }
  }

  static MapCoverage fromId(final int id) {
    switch (id) {
      case 0:
        return MapCoverage.coverageOffline;
      case 1:
        return MapCoverage.coverageOnlineTile;
      case 2:
        return MapCoverage.coverageOnlineNoData;
      case 3:
        return MapCoverage.coverageUnknown;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Identifiers for map data providers supported by the SDK.
///
/// Use these values when calling provider-specific APIs such as
/// [MapDetails.getProviderName] or [MapDetails.getProviderSentence]. The numeric ids returned by
/// [MapDetails.getMapProviderIds] correspond to these enum values.
///
/// {@category Maps & 3D Scenes}
enum MapProviderId {
  route66,
  navteq,
  teleatlas,
  nav2,
  navturk,
  navuri,
  transnavicom,
  suncart,
  mapmyindia,
  sensis,
  micropartes,
  genesys,
  osm,
  kingway,
  vietmap,
  last,
}

/// @nodoc
extension MapProviderIdExtension on MapProviderId {
  int get id {
    switch (this) {
      case MapProviderId.route66:
        return 0;
      case MapProviderId.navteq:
        return 1;
      case MapProviderId.teleatlas:
        return 2;
      case MapProviderId.nav2:
        return 3;
      case MapProviderId.navturk:
        return 4;
      case MapProviderId.navuri:
        return 5;
      case MapProviderId.transnavicom:
        return 6;
      case MapProviderId.suncart:
        return 7;
      case MapProviderId.mapmyindia:
        return 8;
      case MapProviderId.sensis:
        return 9;
      case MapProviderId.micropartes:
        return 10;
      case MapProviderId.genesys:
        return 11;
      case MapProviderId.osm:
        return 12;
      case MapProviderId.kingway:
        return 13;
      case MapProviderId.vietmap:
        return 14;
      case MapProviderId.last:
        return 15;
    }
  }

  static MapProviderId fromId(final int id) {
    switch (id) {
      case 0:
        return MapProviderId.route66;
      case 1:
        return MapProviderId.navteq;
      case 2:
        return MapProviderId.teleatlas;
      case 3:
        return MapProviderId.nav2;
      case 4:
        return MapProviderId.navturk;
      case 5:
        return MapProviderId.navuri;
      case 6:
        return MapProviderId.transnavicom;
      case 7:
        return MapProviderId.suncart;
      case 8:
        return MapProviderId.mapmyindia;
      case 9:
        return MapProviderId.sensis;
      case 10:
        return MapProviderId.micropartes;
      case 11:
        return MapProviderId.genesys;
      case 12:
        return MapProviderId.osm;
      case 13:
        return MapProviderId.kingway;
      case 14:
        return MapProviderId.vietmap;
      case 15:
        return MapProviderId.last;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Extended capabilities that may be available in a particular map dataset.
///
/// Each enum value represents an optional feature or behaviour flag that
/// map data may provide. Use [MapDetails.getMapExtendedCapabilities] to obtain the set
/// of capabilities available for the current map.
///
/// {@category Maps & 3D Scenes}
enum MapExtendedCapability {
  /// Avoid unpaved roads.
  avoidUnpavedRoads,

  /// Avoid carpool lanes.
  avoidCarpoolLanes,

  /// Elevation profile and flags.
  elvProfileAndFlags,

  /// Search developments.
  searchDevelopments,

  /// 64 Bit search offsets.
  searchOffsets64Bit,

  /// Ordered admin index.
  orderedAdminIndex,

  /// Alternative admin index.
  alternativeAdminIndex,

  /// Search index split into multiple sections.
  splitIndexData,

  /// Compatibility flag for using Sphere maps in a commercial app.
  upperLevelData,

  /// Extended routing speeds, extra info fields in nodes, changes to map header format.
  speedsExtraAndIncremental,

  /// Header contains only one map level & tile-ISO resource is only for the lowest map level.
  trimmedHeader,

  /// Sharper geometry & changes to encoding for buildings.
  highPrecisionBuildings,

  /// Links modified to support the storage of more properties and flags.
  extendedRoutingAttributes,

  /// Links modified to support storing of scenic routing data
  scenicRoutingAttributes,

  /// Strings converted to UTF8 instead of Unicode for encoding in map data
  utf8Strings,
}

/// @nodoc
extension MapExtendedCapabilityExtension on MapExtendedCapability {
  int get id {
    switch (this) {
      case MapExtendedCapability.avoidUnpavedRoads:
        return 1;
      case MapExtendedCapability.avoidCarpoolLanes:
        return 2;
      case MapExtendedCapability.elvProfileAndFlags:
        return 4;
      case MapExtendedCapability.searchDevelopments:
        return 8;
      case MapExtendedCapability.searchOffsets64Bit:
        return 16;
      case MapExtendedCapability.orderedAdminIndex:
        return 32;
      case MapExtendedCapability.alternativeAdminIndex:
        return 64;
      case MapExtendedCapability.splitIndexData:
        return 128;
      case MapExtendedCapability.upperLevelData:
        return 256;
      case MapExtendedCapability.speedsExtraAndIncremental:
        return 512;
      case MapExtendedCapability.trimmedHeader:
        return 1024;
      case MapExtendedCapability.highPrecisionBuildings:
        return 2048;
      case MapExtendedCapability.extendedRoutingAttributes:
        return 4096;
      case MapExtendedCapability.scenicRoutingAttributes:
        return 8192;
      case MapExtendedCapability.utf8Strings:
        return 16384;
    }
  }

  static MapExtendedCapability fromId(final int id) {
    switch (id) {
      case 1:
        return MapExtendedCapability.avoidUnpavedRoads;
      case 2:
        return MapExtendedCapability.avoidCarpoolLanes;
      case 4:
        return MapExtendedCapability.elvProfileAndFlags;
      case 8:
        return MapExtendedCapability.searchDevelopments;
      case 16:
        return MapExtendedCapability.searchOffsets64Bit;
      case 32:
        return MapExtendedCapability.orderedAdminIndex;
      case 64:
        return MapExtendedCapability.alternativeAdminIndex;
      case 128:
        return MapExtendedCapability.splitIndexData;
      case 256:
        return MapExtendedCapability.upperLevelData;
      case 512:
        return MapExtendedCapability.speedsExtraAndIncremental;
      case 1024:
        return MapExtendedCapability.trimmedHeader;
      case 2048:
        return MapExtendedCapability.highPrecisionBuildings;
      case 4096:
        return MapExtendedCapability.extendedRoutingAttributes;
      case 8192:
        return MapExtendedCapability.scenicRoutingAttributes;
      case 16384:
        return MapExtendedCapability.utf8Strings;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
