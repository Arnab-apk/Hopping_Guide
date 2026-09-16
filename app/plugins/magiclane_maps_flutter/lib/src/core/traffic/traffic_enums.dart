// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Traffic event shape
///
/// {@category Traffic & Roadblocks}
enum TrafficEventImpactZone {
  /// path as a collection of roads impact zone
  path,

  /// geographic area impact zone
  area,
}

/// @nodoc
extension TrafficEventImpactZoneExtension on TrafficEventImpactZone {
  int get id {
    switch (this) {
      case TrafficEventImpactZone.path:
        return 0;
      case TrafficEventImpactZone.area:
        return 1;
    }
  }

  static TrafficEventImpactZone fromId(final int id) {
    switch (id) {
      case 0:
        return TrafficEventImpactZone.path;
      case 1:
        return TrafficEventImpactZone.area;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Traffic events classes
///
/// {@category Traffic & Roadblocks}
enum TrafficEventClass {
  /// other
  other,

  /// congestion
  levelOfService,

  /// attention
  expectedLevelOfService,

  /// accident
  accidents,

  /// accident
  incidents,

  /// no entry
  closuresAndLaneRestrictions,

  /// no entry
  carriagewayRestrictions,

  /// no entry
  exitRestrictions,

  /// no entry
  entryRestrictions,

  /// info
  trafficRestrictions,

  /// info
  carpoolInfo,

  /// roadworks
  roadworks,

  /// slippery road
  obstructionHazards,

  /// mandatory
  dangerousSituations,

  /// slippery road
  roadConditions,

  /// temperatures
  temperatures,

  /// precipitation and visibility
  precipitationAndVisibility,

  /// wind and air quality
  windAndAirQuality,

  /// activities
  activities,

  /// security alerts
  securityAlerts,

  /// info
  delays,

  /// restrictions removal
  cancellations,

  /// warning
  travelTimeInfo,

  /// dangerous vehicles
  dangerousVehicles,

  /// exceptional loads or vehicles
  exceptionalLoadsOrVehicles,

  /// traffic equipment status
  trafficEquipmentStatus,

  /// circulation closed
  sizeAndWeightLimits,

  /// parking restrictions
  parkingRestrictions,

  /// parking
  parking,

  /// info
  referenceToAudioBroadcast,

  /// info
  serviceMessages,

  /// info
  specialMessages,

  /// user events above this value
  userEventsBase,

  /// user-defined roadblock.
  userRoadblock,
}

/// @nodoc
extension TrafficEventClassExtension on TrafficEventClass {
  int get id {
    switch (this) {
      case TrafficEventClass.other:
        return 0;
      case TrafficEventClass.levelOfService:
        return 1;
      case TrafficEventClass.expectedLevelOfService:
        return 2;
      case TrafficEventClass.accidents:
        return 3;
      case TrafficEventClass.incidents:
        return 4;
      case TrafficEventClass.closuresAndLaneRestrictions:
        return 5;
      case TrafficEventClass.carriagewayRestrictions:
        return 6;
      case TrafficEventClass.exitRestrictions:
        return 7;
      case TrafficEventClass.entryRestrictions:
        return 8;
      case TrafficEventClass.trafficRestrictions:
        return 9;
      case TrafficEventClass.carpoolInfo:
        return 10;
      case TrafficEventClass.roadworks:
        return 11;
      case TrafficEventClass.obstructionHazards:
        return 12;
      case TrafficEventClass.dangerousSituations:
        return 13;
      case TrafficEventClass.roadConditions:
        return 14;
      case TrafficEventClass.temperatures:
        return 15;
      case TrafficEventClass.precipitationAndVisibility:
        return 16;
      case TrafficEventClass.windAndAirQuality:
        return 17;
      case TrafficEventClass.activities:
        return 18;
      case TrafficEventClass.securityAlerts:
        return 19;
      case TrafficEventClass.delays:
        return 20;
      case TrafficEventClass.cancellations:
        return 21;
      case TrafficEventClass.travelTimeInfo:
        return 22;
      case TrafficEventClass.dangerousVehicles:
        return 23;
      case TrafficEventClass.exceptionalLoadsOrVehicles:
        return 24;
      case TrafficEventClass.trafficEquipmentStatus:
        return 25;
      case TrafficEventClass.sizeAndWeightLimits:
        return 26;
      case TrafficEventClass.parkingRestrictions:
        return 27;
      case TrafficEventClass.parking:
        return 28;
      case TrafficEventClass.referenceToAudioBroadcast:
        return 29;
      case TrafficEventClass.serviceMessages:
        return 30;
      case TrafficEventClass.specialMessages:
        return 31;
      case TrafficEventClass.userEventsBase:
        return 100;
      case TrafficEventClass.userRoadblock:
        return 100;
    }
  }

  static TrafficEventClass fromId(final int id) {
    switch (id) {
      case 0:
        return TrafficEventClass.other;
      case 1:
        return TrafficEventClass.levelOfService;
      case 2:
        return TrafficEventClass.expectedLevelOfService;
      case 3:
        return TrafficEventClass.accidents;
      case 4:
        return TrafficEventClass.incidents;
      case 5:
        return TrafficEventClass.closuresAndLaneRestrictions;
      case 6:
        return TrafficEventClass.carriagewayRestrictions;
      case 7:
        return TrafficEventClass.exitRestrictions;
      case 8:
        return TrafficEventClass.entryRestrictions;
      case 9:
        return TrafficEventClass.trafficRestrictions;
      case 10:
        return TrafficEventClass.carpoolInfo;
      case 11:
        return TrafficEventClass.roadworks;
      case 12:
        return TrafficEventClass.obstructionHazards;
      case 13:
        return TrafficEventClass.dangerousSituations;
      case 14:
        return TrafficEventClass.roadConditions;
      case 15:
        return TrafficEventClass.temperatures;
      case 16:
        return TrafficEventClass.precipitationAndVisibility;
      case 17:
        return TrafficEventClass.windAndAirQuality;
      case 18:
        return TrafficEventClass.activities;
      case 19:
        return TrafficEventClass.securityAlerts;
      case 20:
        return TrafficEventClass.delays;
      case 21:
        return TrafficEventClass.cancellations;
      case 22:
        return TrafficEventClass.travelTimeInfo;
      case 23:
        return TrafficEventClass.dangerousVehicles;
      case 24:
        return TrafficEventClass.exceptionalLoadsOrVehicles;
      case 25:
        return TrafficEventClass.trafficEquipmentStatus;
      case 26:
        return TrafficEventClass.sizeAndWeightLimits;
      case 27:
        return TrafficEventClass.parkingRestrictions;
      case 28:
        return TrafficEventClass.parking;
      case 29:
        return TrafficEventClass.referenceToAudioBroadcast;
      case 30:
        return TrafficEventClass.serviceMessages;
      case 31:
        return TrafficEventClass.specialMessages;
      case 100:
        return TrafficEventClass.userRoadblock;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Traffic event severity enum.
///
/// {@category Traffic & Roadblocks}
enum TrafficEventSeverity {
  /// Stationary
  /// Traffic is stationary: vehicles are stopped and no movement is expected.
  stationary,

  /// Queuing
  /// Traffic is queuing: stop-and-go conditions where vehicles are moving
  /// intermittently and speeds are well below normal.
  queuing,

  /// Slow traffic
  /// Slow traffic: traffic is moving but at reduced speeds compared to
  /// normal conditions.
  slowTraffic,

  /// Possible delay
  /// Possible delay: conditions may cause delays but the extent is minor
  /// or not yet confirmed.
  possibleDelay,

  /// Unknown
  /// Unknown traffic state: there is insufficient or unreliable data to
  /// determine current conditions.
  unknown,

  /// Free traffic
  /// Free traffic (also referred to as lowTraffic): traffic is flowing
  /// normally with no expected delays.
  free,
}

/// @nodoc
extension TrafficEventSeverityExtension on TrafficEventSeverity {
  int get id {
    switch (this) {
      case TrafficEventSeverity.stationary:
        return 0;
      case TrafficEventSeverity.queuing:
        return 1;
      case TrafficEventSeverity.slowTraffic:
        return 2;
      case TrafficEventSeverity.possibleDelay:
        return 3;
      case TrafficEventSeverity.unknown:
        return 4;
      case TrafficEventSeverity.free:
        return 5;
    }
  }

  static TrafficEventSeverity fromId(final int id) {
    switch (id) {
      case 0:
        return TrafficEventSeverity.stationary;
      case 1:
        return TrafficEventSeverity.queuing;
      case 2:
        return TrafficEventSeverity.slowTraffic;
      case 3:
        return TrafficEventSeverity.possibleDelay;
      case 4:
        return TrafficEventSeverity.unknown;
      case 5:
        return TrafficEventSeverity.free;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Restrictions which prevent online service functionality
///
/// {@category Traffic & Roadblocks}
enum TrafficOnlineRestrictions {
  /// No restrictions
  none,

  /// Service is disabled from settings
  settings,

  /// No internet connection
  connection,

  /// Restricted by network type
  networkType,

  /// Missing provider data
  providerData,

  /// Outdated world map version
  worldMapVersion,

  /// Not enough disk space to store data
  diskSpace,

  /// Failed to initialize
  initFail,
}

/// @nodoc
extension TrafficOnlineRestrictionsExtension on TrafficOnlineRestrictions {
  int get id {
    switch (this) {
      case TrafficOnlineRestrictions.none:
        return 0;
      case TrafficOnlineRestrictions.settings:
        return 1;
      case TrafficOnlineRestrictions.connection:
        return 2;
      case TrafficOnlineRestrictions.networkType:
        return 4;
      case TrafficOnlineRestrictions.providerData:
        return 8;
      case TrafficOnlineRestrictions.worldMapVersion:
        return 16;
      case TrafficOnlineRestrictions.diskSpace:
        return 32;
      case TrafficOnlineRestrictions.initFail:
        return 64;
    }
  }

  static TrafficOnlineRestrictions fromId(final int id) {
    switch (id) {
      case 0:
        return TrafficOnlineRestrictions.none;
      case 1:
        return TrafficOnlineRestrictions.settings;
      case 2:
        return TrafficOnlineRestrictions.connection;
      case 4:
        return TrafficOnlineRestrictions.networkType;
      case 8:
        return TrafficOnlineRestrictions.providerData;
      case 16:
        return TrafficOnlineRestrictions.worldMapVersion;
      case 32:
        return TrafficOnlineRestrictions.diskSpace;
      case 64:
        return TrafficOnlineRestrictions.initFail;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
