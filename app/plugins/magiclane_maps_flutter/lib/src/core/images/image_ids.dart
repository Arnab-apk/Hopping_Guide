// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// SDK icon identifiers.
///
/// These enums list the built-in icon identifiers used by the SDK for
/// various purposes, such as representing landmarks, waypoints, and engine
/// features.
///
/// {@category Images}
enum GemIcon {
  /// Blue ball icon.
  blueBall,

  /// Favorite heart icon.
  favoriteHeart,

  /// Ferry icon.
  ferry,

  /// Green ball icon.
  greenBall,

  /// Menu more dots circle icon.
  menuMoreDotsCircle,

  /// Red ball icon.
  redBall,

  /// Search results pin icon.
  searchResultsPin,

  /// Toll icon.
  toll,

  /// Waypoint finish icon.
  waypointFinish,

  /// Waypoint intermediary icon.
  waypointIntermediary,

  /// Waypoint start icon.
  waypointStart,

  /// Yellow ball icon.
  yellowBall,

  /// Core count icon (not an actual icon, used for count).
  coreCount,

  /// Core base icon (base id for icons).
  coreBase,
}

/// @nodoc
extension GemIconExtension on GemIcon {
  int get id {
    switch (this) {
      case GemIcon.blueBall:
        return 54000;
      case GemIcon.favoriteHeart:
        return 54009;
      case GemIcon.greenBall:
        return 54001;
      case GemIcon.menuMoreDotsCircle:
        return 54005;
      case GemIcon.redBall:
        return 54002;
      case GemIcon.searchResultsPin:
        return 54003;
      case GemIcon.waypointFinish:
        return 54006;
      case GemIcon.waypointIntermediary:
        return 54007;
      case GemIcon.waypointStart:
        return 54008;
      case GemIcon.yellowBall:
        return 54004;
      case GemIcon.coreCount:
        return 10;
      case GemIcon.coreBase:
        return 54000;
      case GemIcon.ferry:
        return 44008;
      case GemIcon.toll:
        return 44000;
    }
  }

  static GemIcon fromId(final int id) {
    switch (id) {
      case 54000:
        return GemIcon.blueBall;
      case 54009:
        return GemIcon.favoriteHeart;
      case 54001:
        return GemIcon.greenBall;
      case 54005:
        return GemIcon.menuMoreDotsCircle;
      case 54002:
        return GemIcon.redBall;
      case 54003:
        return GemIcon.searchResultsPin;
      case 54006:
        return GemIcon.waypointFinish;
      case 54007:
        return GemIcon.waypointIntermediary;
      case 54008:
        return GemIcon.waypointStart;
      case 54004:
        return GemIcon.yellowBall;
      case 10:
        return GemIcon.coreCount;
      case 44008:
        return GemIcon.ferry;
      case 44000:
        return GemIcon.toll;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Miscellaneous engine icon identifiers.
///
/// {@category Images}
enum EngineMisc {
  /// Alert active icon.
  alertActive,

  /// Alert inactive icon.
  alertInactive,

  /// Compass enable sensor OFF icon.
  compassEnableSensorOFF,

  /// Compass enable sensor OFF night icon.
  compassEnableSensorOFFnight,

  /// Compass enable sensor ON icon.
  compassEnableSensorON,

  /// Compass enable sensor ON night icon.
  compassEnableSensorONNight,

  /// Folder icon.
  folder,

  /// Location details favourite push pin icon.
  locationDetailsFavouritePushPin,

  /// Location details place pushpin icon.
  locationDetailsPlacePushpin,

  /// Location details place street icon.
  locationDetailsPlaceStreet,

  /// Location details place street sign icon.
  locationDetailsPlaceStreetSign,

  /// Location details send details icon.
  locationDetailsSendDetails,

  /// Map scale icon.
  mapScale,

  /// My location icon.
  myLocation,

  /// POI home icon.
  poiHome,

  /// POI to left icon.
  poiToLeft,

  /// POI to right icon.
  poiToRight,

  /// POI work icon.
  poiWork,

  /// Position GPS navigation available icon.
  positionGPSNavigationAvailable,

  /// Position GPS no navigation available icon.
  positionGPSNoNavigationAvailable,

  /// Position GPS slice icon.
  positionGPSSlice,

  /// Road shield exit name icon.
  roadShieldExitName,

  /// Road shield exit number icon.
  roadShieldExitNumber,

  /// Settlement island icon.
  settlementIsland,

  /// Sorting icon.
  sorting,

  /// Waypoint flag point finish icon.
  waypointFlagPointFinish,

  /// Waypoint flag point finish search on map icon.
  waypointFlagPointFinishSearchOnMap,

  /// Waypoint flag point intermediary icon.
  waypointFlagPointIntermediary,

  /// Waypoint flag point intermediary search on map icon.
  waypointFlagPointIntermediarySearchOnMap,

  /// Waypoint flag point start icon.
  waypointFlagPointStart,

  /// Waypoint flag point start search on map icon.
  waypointFlagPointStartSearchOnMap,

  /// Engine misc count (not an actual icon, used for count).
  engineMiscCount,

  /// Engine misc base (base id for icons).
  engineMiscBase,
}

/// @nodoc
///
/// {@category Images}
extension EngineMiscExtension on EngineMisc {
  int get id {
    switch (this) {
      case EngineMisc.alertActive:
        return 6060;
      case EngineMisc.alertInactive:
        return 6061;
      case EngineMisc.compassEnableSensorOFF:
        return 6001;
      case EngineMisc.compassEnableSensorOFFnight:
        return 6071;
      case EngineMisc.compassEnableSensorON:
        return 6003;
      case EngineMisc.compassEnableSensorONNight:
        return 6072;
      case EngineMisc.folder:
        return 6096;
      case EngineMisc.locationDetailsFavouritePushPin:
        return 6005;
      case EngineMisc.locationDetailsPlacePushpin:
        return 6008;
      case EngineMisc.locationDetailsPlaceStreet:
        return 6102;
      case EngineMisc.locationDetailsPlaceStreetSign:
        return 6103;
      case EngineMisc.locationDetailsSendDetails:
        return 6108;
      case EngineMisc.mapScale:
        return 6010;
      case EngineMisc.myLocation:
        return 6078;
      case EngineMisc.poiHome:
        return 6067;
      case EngineMisc.poiToLeft:
        return 6014;
      case EngineMisc.poiToRight:
        return 6015;
      case EngineMisc.poiWork:
        return 6068;
      case EngineMisc.positionGPSNavigationAvailable:
        return 6019;
      case EngineMisc.positionGPSNoNavigationAvailable:
        return 6021;
      case EngineMisc.positionGPSSlice:
        return 6023;
      case EngineMisc.roadShieldExitName:
        return 6069;
      case EngineMisc.roadShieldExitNumber:
        return 6070;
      case EngineMisc.settlementIsland:
        return 6029;
      case EngineMisc.sorting:
        return 6098;
      case EngineMisc.waypointFlagPointFinish:
        return 6034;
      case EngineMisc.waypointFlagPointFinishSearchOnMap:
        return 6073;
      case EngineMisc.waypointFlagPointIntermediary:
        return 6035;
      case EngineMisc.waypointFlagPointIntermediarySearchOnMap:
        return 6074;
      case EngineMisc.waypointFlagPointStart:
        return 6036;
      case EngineMisc.waypointFlagPointStartSearchOnMap:
        return 6075;
      case EngineMisc.engineMiscCount:
        return 31;
      case EngineMisc.engineMiscBase:
        return 6000;
    }
  }

  static EngineMisc fromId(final int id) {
    switch (id) {
      case 6060:
        return EngineMisc.alertActive;
      case 6061:
        return EngineMisc.alertInactive;
      case 6001:
        return EngineMisc.compassEnableSensorOFF;
      case 6071:
        return EngineMisc.compassEnableSensorOFFnight;
      case 6003:
        return EngineMisc.compassEnableSensorON;
      case 6072:
        return EngineMisc.compassEnableSensorONNight;
      case 6096:
        return EngineMisc.folder;
      case 6005:
        return EngineMisc.locationDetailsFavouritePushPin;
      case 6008:
        return EngineMisc.locationDetailsPlacePushpin;
      case 6102:
        return EngineMisc.locationDetailsPlaceStreet;
      case 6103:
        return EngineMisc.locationDetailsPlaceStreetSign;
      case 6108:
        return EngineMisc.locationDetailsSendDetails;
      case 6010:
        return EngineMisc.mapScale;
      case 6078:
        return EngineMisc.myLocation;
      case 6067:
        return EngineMisc.poiHome;
      case 6014:
        return EngineMisc.poiToLeft;
      case 6015:
        return EngineMisc.poiToRight;
      case 6068:
        return EngineMisc.poiWork;
      case 6019:
        return EngineMisc.positionGPSNavigationAvailable;
      case 6021:
        return EngineMisc.positionGPSNoNavigationAvailable;
      case 6023:
        return EngineMisc.positionGPSSlice;
      case 6069:
        return EngineMisc.roadShieldExitName;
      case 6070:
        return EngineMisc.roadShieldExitNumber;
      case 6029:
        return EngineMisc.settlementIsland;
      case 6098:
        return EngineMisc.sorting;
      case 6034:
        return EngineMisc.waypointFlagPointFinish;
      case 6073:
        return EngineMisc.waypointFlagPointFinishSearchOnMap;
      case 6035:
        return EngineMisc.waypointFlagPointIntermediary;
      case 6074:
        return EngineMisc.waypointFlagPointIntermediarySearchOnMap;
      case 6036:
        return EngineMisc.waypointFlagPointStart;
      case 6075:
        return EngineMisc.waypointFlagPointStartSearchOnMap;
      case 31:
        return EngineMisc.engineMiscCount;
      case 6000:
        return EngineMisc.engineMiscBase;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
