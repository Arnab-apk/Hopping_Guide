// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Electric vehicle charging connector type
///
/// Not yet supported by the routing engine.
///
/// {@category Routing}
@experimental
enum EVChargingConnector {
  /// J1772 connector
  j1772,

  /// Mennekes connector
  mennekes,

  /// Type 2 connector
  type2,

  /// Type 3 connector
  type3,

  /// GBT AC connector
  gbtAc,

  /// GBT DC connector
  gbtDc,

  /// CHAdeMO connector
  chaemo,

  /// CSS1 connector
  css1,

  /// CSS2 connector
  css2,

  /// Tesla connector
  tesla,

  /// Super Tesla connector
  superTesla,

  /// Super Tesla CCS connector
  superTeslaCCS,

  /// Tesla destination charger connector
  teslaDestination,
}

/// @nodoc
extension EVChargingConnectorExtension on EVChargingConnector {
  int get id {
    switch (this) {
      case EVChargingConnector.j1772:
        return 0x1;
      case EVChargingConnector.mennekes:
        return 0x2;
      case EVChargingConnector.type2:
        return 0x4;
      case EVChargingConnector.type3:
        return 0x8;
      case EVChargingConnector.gbtAc:
        return 0x10;
      case EVChargingConnector.gbtDc:
        return 0x20;
      case EVChargingConnector.chaemo:
        return 0x40;
      case EVChargingConnector.css1:
        return 0x80;
      case EVChargingConnector.css2:
        return 0x100;
      case EVChargingConnector.tesla:
        return 0x200;
      case EVChargingConnector.superTesla:
        return 0x400;
      case EVChargingConnector.superTeslaCCS:
        return 0x800;
      case EVChargingConnector.teslaDestination:
        return 0x1000;
    }
  }

  static EVChargingConnector fromId(final int id) {
    switch (id) {
      case 0x1:
        return EVChargingConnector.j1772;
      case 0x2:
        return EVChargingConnector.mennekes;
      case 0x4:
        return EVChargingConnector.type2;
      case 0x8:
        return EVChargingConnector.type3;
      case 0x10:
        return EVChargingConnector.gbtAc;
      case 0x20:
        return EVChargingConnector.gbtDc;
      case 0x40:
        return EVChargingConnector.chaemo;
      case 0x80:
        return EVChargingConnector.css1;
      case 0x100:
        return EVChargingConnector.css2;
      case 0x200:
        return EVChargingConnector.tesla;
      case 0x400:
        return EVChargingConnector.superTesla;
      case 0x800:
        return EVChargingConnector.superTeslaCCS;
      case 0x1000:
        return EVChargingConnector.teslaDestination;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Route result
///
/// Used to specify the type of route result to be returned.
/// Determines whether a navigable path or a reachable area is computed.
///
/// ## See also:
///
/// - [RoutePreferences] - Holds the overall routing preferences including transport mode and profiles.
/// - [RoutePreferences.routeRanges] - Specifies range limits for reachable area calculations.
///
/// {@category Routing}
enum RouteResultType {
  /// Path route result type - navigable route.
  path,

  /// Route range (Isochrone) result type - reachable area within a range of travel costs.
  range,
}

/// @nodoc
extension RouteResultTypeExtension on RouteResultType {
  int get id {
    switch (this) {
      case RouteResultType.path:
        return 0;
      case RouteResultType.range:
        return 1;
    }
  }

  static RouteResultType fromId(final int id) {
    switch (id) {
      case 0:
        return RouteResultType.path;
      case 1:
        return RouteResultType.range;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Algorithm type
///
/// Used to specify whether the provided [RoutePreferences.timestamp] is for departure or arrival.
/// Only used for public transport routing.
///
/// {@category Routing}
enum PTAlgorithmType {
  /// Algorithm type - departure/starting point
  departure,

  /// Algorithm type - arrival/destination point
  arrival,
}

/// @nodoc
extension PTAlgorithmTypeExtension on PTAlgorithmType {
  int get id {
    switch (this) {
      case PTAlgorithmType.departure:
        return 0;
      case PTAlgorithmType.arrival:
        return 1;
    }
  }

  static PTAlgorithmType fromId(final int id) {
    switch (id) {
      case 0:
        return PTAlgorithmType.departure;
      case 1:
        return PTAlgorithmType.arrival;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Sorting strategy
///
/// Used to specify the preferred sorting strategy for public transport routes.
/// Only used for public transport routing.
///
/// {@category Routing}
enum PTSortingStrategy {
  /// Sorting strategy - best time
  bestTime,

  /// Sorting strategy - least walk
  leastWalk,

  /// Sorting strategy - fewest transfers
  leastTransfers,
}

/// @nodoc
extension PTSortingStrategyExtension on PTSortingStrategy {
  int get id {
    switch (this) {
      case PTSortingStrategy.bestTime:
        return 0;
      case PTSortingStrategy.leastWalk:
        return 1;
      case PTSortingStrategy.leastTransfers:
        return 2;
    }
  }

  static PTSortingStrategy fromId(final int id) {
    switch (id) {
      case 0:
        return PTSortingStrategy.bestTime;
      case 1:
        return PTSortingStrategy.leastWalk;
      case 2:
        return PTSortingStrategy.leastTransfers;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Route type
///
/// Used to specify the type of route to be calculated.
/// Influences the optimization criteria for the route calculation.
///
/// {@category Routing}
enum RouteType {
  /// Fastest route between the given waypoints
  fastest,

  /// Shortest route between the given waypoints
  shortest,

  /// Economical, as fuel consumption, route between the given waypoints
  economic,

  /// Fastest route, with best scenic view, between the given waypoints
  scenic,
}

/// @nodoc
extension RouteTypeExtension on RouteType {
  int get id {
    switch (this) {
      case RouteType.fastest:
        return 0;
      case RouteType.shortest:
        return 1;
      case RouteType.economic:
        return 2;
      case RouteType.scenic:
        return 3;
    }
  }

  static RouteType fromId(final int id) {
    switch (id) {
      case 0:
        return RouteType.fastest;
      case 1:
        return RouteType.shortest;
      case 2:
        return RouteType.economic;
      case 3:
        return RouteType.scenic;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Transport mode
///
/// Used to specify the primary transport mode for route calculation.
/// Determines the vehicle or movement type used for routing.
///
/// {@category Routing}
enum RouteTransportMode {
  /// Transport mode - car.
  car,

  /// Transport mode - lorry/truck.
  lorry,

  /// Transport mode - on foot.
  pedestrian,

  /// Transport mode - bike.
  bicycle,

  /// Transport mode - public transport.
  public,

  /// Transport mode - shared vehicles.
  sharedVehicles,
}

/// @nodoc
extension RouteTransportModeExtension on RouteTransportMode {
  int get id {
    switch (this) {
      case RouteTransportMode.car:
        return 0;
      case RouteTransportMode.lorry:
        return 1;
      case RouteTransportMode.pedestrian:
        return 2;
      case RouteTransportMode.bicycle:
        return 3;
      case RouteTransportMode.public:
        return 4;
      case RouteTransportMode.sharedVehicles:
        return 5;
    }
  }

  static RouteTransportMode fromId(final int id) {
    switch (id) {
      case 0:
        return RouteTransportMode.car;
      case 1:
        return RouteTransportMode.lorry;
      case 2:
        return RouteTransportMode.pedestrian;
      case 3:
        return RouteTransportMode.bicycle;
      case 4:
        return RouteTransportMode.public;
      case 5:
        return RouteTransportMode.sharedVehicles;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Traffic avoidance options
///
/// Used to specify the level of traffic avoidance during route calculation.
/// Determines which types of traffic events to avoid.
///
/// {@category Routing}
enum TrafficAvoidance {
  /// Disable traffic avoidance.
  none,

  /// Avoid all traffic events: congestions and roadblocks.
  all,

  /// Avoid only roadblock traffic events.
  roadblocks,
}

/// @nodoc
extension TrafficAvoidanceExtension on TrafficAvoidance {
  int get id {
    switch (this) {
      case TrafficAvoidance.none:
        return 0;
      case TrafficAvoidance.all:
        return 1;
      case TrafficAvoidance.roadblocks:
        return 2;
    }
  }

  static TrafficAvoidance fromId(final int id) {
    switch (id) {
      case 0:
        return TrafficAvoidance.none;
      case 1:
        return TrafficAvoidance.all;
      case 2:
        return TrafficAvoidance.roadblocks;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Pedestrian profile
///
/// Used to specify the type of pedestrian for route calculation.
/// Determines the pedestrian characteristics and routing preferences.
///
/// {@category Routing}
enum PedestrianProfile {
  /// Pedestrian profile - walk.
  walk,

  /// Pedestrian profile - hike.
  hike,
}

/// @nodoc
extension PedestrianProfileExtension on PedestrianProfile {
  int get id {
    switch (this) {
      case PedestrianProfile.walk:
        return 0;
      case PedestrianProfile.hike:
        return 1;
    }
  }

  static PedestrianProfile fromId(final int id) {
    switch (id) {
      case 0:
        return PedestrianProfile.walk;
      case 1:
        return PedestrianProfile.hike;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Routing result details
///
/// Used to specify the level of detail in the routing result.
///
/// {@category Routing}
enum RouteResultDetails {
  /// Path and guidance
  full,

  /// Path time / distance only
  timeDistance,

  /// Path time / distance and geometry
  path,
}

/// @nodoc
extension RouteResultDetailsExtension on RouteResultDetails {
  int get id {
    switch (this) {
      case RouteResultDetails.full:
        return 0;
      case RouteResultDetails.timeDistance:
        return 1;
      case RouteResultDetails.path:
        return 2;
    }
  }

  static RouteResultDetails fromId(final int id) {
    switch (id) {
      case 0:
        return RouteResultDetails.full;
      case 1:
        return RouteResultDetails.timeDistance;
      case 2:
        return RouteResultDetails.path;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Alternative routes scheme
///
/// {@category Routing}
enum RouteAlternativesSchema {
  /// Alternative routes scheme - Service default - depending on selected transport, route type & result details
  defaultSchema,

  /// Alternative routes scheme - never
  never,

  /// Alternative routes scheme - always ( even if not recommended, e.g. for shortest etc )
  always,
}

/// @nodoc
extension RouteAlternativesSchemaExtension on RouteAlternativesSchema {
  int get id {
    switch (this) {
      case RouteAlternativesSchema.defaultSchema:
        return 0;
      case RouteAlternativesSchema.never:
        return 1;
      case RouteAlternativesSchema.always:
        return 2;
    }
  }

  static RouteAlternativesSchema fromId(final int id) {
    switch (id) {
      case 0:
        return RouteAlternativesSchema.defaultSchema;
      case 1:
        return RouteAlternativesSchema.never;
      case 2:
        return RouteAlternativesSchema.always;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Path calculation algorithm
///
/// Used to specify the path calculation algorithm for route calculation.
///
/// ## Also see:
///
/// - [RoutePathAlgorithmFlavor] - Specifies the path calculation flavor.
///
/// {@category Routing}
enum RoutePathAlgorithm {
  /// Path calculation algorithm - Service default - Magic Lane routing algorithm
  ml,

  /// Simplified Magic Lane routing algorithm - Best speed, recommended for low end devices
  simplifiedMl,

  /// Path calculation algorithm - External CH routing algorithm
  externalCH,

  /// Magic Lane CH routing algorithm
  mlch,
}

/// @nodoc
extension RoutePathAlgorithmExtension on RoutePathAlgorithm {
  int get id {
    switch (this) {
      case RoutePathAlgorithm.ml:
        return 0;
      case RoutePathAlgorithm.simplifiedMl:
        return 1;
      case RoutePathAlgorithm.externalCH:
        return 2;
      case RoutePathAlgorithm.mlch:
        return 3;
    }
  }

  static RoutePathAlgorithm fromId(final int id) {
    switch (id) {
      case 0:
        return RoutePathAlgorithm.ml;
      case 1:
        return RoutePathAlgorithm.simplifiedMl;
      case 2:
        return RoutePathAlgorithm.externalCH;
      case 3:
        return RoutePathAlgorithm.mlch;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Path calculation flavors
///
/// Used to specify the path calculation flavor for route calculation.
///
/// ## Also see:
///
/// - [RoutePathAlgorithm] - Specifies the path calculation algorithm.
///
/// {@category Routing}
enum RoutePathAlgorithmFlavor {
  /// Service default - Magic Lane routing flavor
  magicLane,

  /// GraphHopper flavor
  graphHopper,
}

/// @nodoc
extension RoutePathAlgorithmFlavorExtension on RoutePathAlgorithmFlavor {
  int get id {
    switch (this) {
      case RoutePathAlgorithmFlavor.magicLane:
        return 0;
      case RoutePathAlgorithmFlavor.graphHopper:
        return 1;
    }
  }

  static RoutePathAlgorithmFlavor fromId(final int id) {
    switch (id) {
      case 0:
        return RoutePathAlgorithmFlavor.magicLane;
      case 1:
        return RoutePathAlgorithmFlavor.graphHopper;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Route type preference
///
/// Only relevant for public transport routing.
/// Used to specify the preferred type of public transport for route calculation.
///
/// ## Also see:
///
/// - [RoutePreferences] - Holds the overall routing preferences including transport mode and profiles.
/// - [RouteTransportMode] - Specifies the type of route to be calculated.
///
/// {@category Routing}
enum RouteTypePreferences {
  /// No preference regarding route type, unpaved road is good enough
  none,

  /// Prefer buses
  bus,

  /// Prefer underground/overground subways/metro and underground railway/tunnel transportation
  underground,

  /// Prefer train and coach services
  railway,

  /// Prefer trams
  tram,

  /// Prefer water transportation (boats, ships, gondolas, water taxis)
  waterTransport,

  /// Prefer other means of transportation: funicular, telecabins, air transportation, taxis etc.
  misc,

  /// Prefer shared bikes
  sharedBike,

  /// Prefer shared cars
  sharedCar,

  /// Prefer shared scooters
  sharedScooter,
}

/// @nodoc
extension RouteTypePreferencesExtension on RouteTypePreferences {
  int get id {
    switch (this) {
      case RouteTypePreferences.none:
        return 0x00000000;
      case RouteTypePreferences.bus:
        return 0x00000001;
      case RouteTypePreferences.underground:
        return 0x00000002;
      case RouteTypePreferences.railway:
        return 0x00000004;
      case RouteTypePreferences.tram:
        return 0x00000008;
      case RouteTypePreferences.waterTransport:
        return 0x00000010;
      case RouteTypePreferences.misc:
        return 0x00000020;
      case RouteTypePreferences.sharedBike:
        return 0x00000040;
      case RouteTypePreferences.sharedCar:
        return 0x00000080;
      case RouteTypePreferences.sharedScooter:
        return 0x00000100;
    }
  }

  static RouteTypePreferences fromId(final int id) {
    switch (id) {
      case 0x00000000:
        return RouteTypePreferences.none;
      case 0x00000001:
        return RouteTypePreferences.bus;
      case 0x00000002:
        return RouteTypePreferences.underground;
      case 0x00000004:
        return RouteTypePreferences.railway;
      case 0x00000008:
        return RouteTypePreferences.tram;
      case 0x00000010:
        return RouteTypePreferences.waterTransport;
      case 0x00000020:
        return RouteTypePreferences.misc;
      case 0x00000040:
        return RouteTypePreferences.sharedBike;
      case 0x00000080:
        return RouteTypePreferences.sharedCar;
      case 0x00000100:
        return RouteTypePreferences.sharedScooter;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Route restriction type.
///
/// Describes a kind of restriction that applies to a portion of a route, such
/// as access restrictions, transport restrictions or vehicle-attribute
/// restrictions (weight, height, length, width, axle load, plate based).
///
/// Values are flag bits and can be combined into a `Set`. The SDK returns
/// restriction information as a `Set<RouteRestrictionType>` via
/// [TurnDetails.restrictions], [NavigationInstruction.currentRestrictions],
/// and [RestrictionSection.restrictions].
///
/// ## See also:
///
/// - [RestrictionSection] - Section of a route subject to one or more restrictions.
/// - [RouteBase.restrictionSections] - List of restricted sections for a route.
/// - [RouteSegmentBase.restrictionSections] - List of restricted sections for a segment.
///
/// {@category Routing}
enum RouteRestrictionType {
  /// Route transport mode restriction.
  transportNotAllowed,

  /// Access restriction (e.g. private road).
  accessRestricted,

  /// User avoid preferences restriction (e.g. avoid toll road, avoid motorway, etc.).
  avoidPreferences,

  /// Vehicle weight over limit restriction.
  vehicleWeight,

  /// Vehicle height over limit restriction.
  vehicleHeight,

  /// Vehicle length over limit restriction.
  vehicleLength,

  /// Vehicle width over limit restriction.
  vehicleWidth,

  /// Vehicle axle load over limit restriction.
  vehicleAxleLoad,

  /// Vehicle plate restriction.
  vehiclePlate,
}

/// @nodoc
extension RouteRestrictionTypeExtension on RouteRestrictionType {
  int get id {
    switch (this) {
      case RouteRestrictionType.transportNotAllowed:
        return 0x1;
      case RouteRestrictionType.accessRestricted:
        return 0x2;
      case RouteRestrictionType.avoidPreferences:
        return 0x4;
      case RouteRestrictionType.vehicleWeight:
        return 0x8;
      case RouteRestrictionType.vehicleHeight:
        return 0x10;
      case RouteRestrictionType.vehicleLength:
        return 0x20;
      case RouteRestrictionType.vehicleWidth:
        return 0x40;
      case RouteRestrictionType.vehicleAxleLoad:
        return 0x80;
      case RouteRestrictionType.vehiclePlate:
        return 0x100;
    }
  }

  static RouteRestrictionType fromId(final int id) {
    switch (id) {
      case 0x1:
        return RouteRestrictionType.transportNotAllowed;
      case 0x2:
        return RouteRestrictionType.accessRestricted;
      case 0x4:
        return RouteRestrictionType.avoidPreferences;
      case 0x8:
        return RouteRestrictionType.vehicleWeight;
      case 0x10:
        return RouteRestrictionType.vehicleHeight;
      case 0x20:
        return RouteRestrictionType.vehicleLength;
      case 0x40:
        return RouteRestrictionType.vehicleWidth;
      case 0x80:
        return RouteRestrictionType.vehicleAxleLoad;
      case 0x100:
        return RouteRestrictionType.vehiclePlate;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Range type to define ranges in.
///
/// Unit type to define ranges in. Currently only used for the roundtrips feature, not the ranges (aka isochrones) feature.
///
/// {@category Routing}
enum RangeType {
  /// Use DistanceBased for route type "shortest"
  /// and TimeBased for route type "fastest" (backward compatibility).
  defaultType,

  /// Range unit is in meters.
  distanceBased,

  /// Range unit is in seconds.
  timeBased,

  /// Range unit is in Watt-hours (not currently supported for roundtrips).
  energyBased,
}

/// @nodoc
extension RangeTypeExtension on RangeType {
  int get id {
    switch (this) {
      case RangeType.defaultType:
        return 0;
      case RangeType.distanceBased:
        return 1;
      case RangeType.timeBased:
        return 2;
      case RangeType.energyBased:
        return 3;
    }
  }

  static RangeType fromId(final int id) {
    switch (id) {
      case 0:
        return RangeType.defaultType;
      case 1:
        return RangeType.distanceBased;
      case 2:
        return RangeType.timeBased;
      case 3:
        return RangeType.energyBased;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
