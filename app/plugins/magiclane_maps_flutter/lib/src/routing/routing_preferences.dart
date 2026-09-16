// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/routing.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Comprehensive route calculation configuration for customizing routing behavior.
///
/// [RoutePreferences] centralizes all route calculation options including transport
/// mode, vehicle profiles, avoidance settings (motorways, tolls, ferries, unpaved
/// roads), traffic handling, algorithm selection, result detail levels, and
/// alternative route handling. Set preferences before calling
/// [RoutingService.calculateRoute] to control how routes are computed.
///
/// Each transport mode supports specific profile configurations:
/// - [carProfile] for cars, including fuel type and vehicle mass
/// - [truckProfile] for trucks, with dimensions and axle load constraints
/// - [bikeProfile] for bicycles, supporting both standard and electric bikes
/// - [pedestrianProfile] for walking or wheelchair-accessible routes
///
/// Common preferences include [routeType] (fastest, shortest, economic),
/// [avoidMotorways], [avoidTollRoads], [avoidFerries], [avoidUnpavedRoads], and
/// [avoidTraffic] strategies. Public transport options include departure/arrival
/// times via [timestamp] and [algorithmType], transfer constraints, and sorting
/// strategies. Emergency vehicle mode relaxes routing constraints.
///
/// ## See also:
///
/// - [RoutingService.calculateRoute] - Uses these preferences to compute routes.
/// - [CarProfile] - Car-specific routing constraints.
/// - [TruckProfile] - Truck-specific routing constraints.
/// - [RouteTransportMode] - Transport mode options.
///
/// {@category Routing}
class RoutePreferences extends GemAutoreleaseObject {
  /// Creates a new set of routing preferences used to customize how routes are calculated.
  ///
  /// These preferences control routing behavior such as transport mode, avoidance options,
  /// algorithm selection, profile overrides, and constraints for transfers, walking distance,
  /// and timing. Provide only the options you need; unspecified profile fields will fall back
  /// to default behavior. This constructor configures a request-level set of hints that
  /// influence route generation and result formatting.
  ///
  /// ## Parameters
  ///
  /// - [accurateTrackMatch]: When true, prefer tighter matching of the computed route to an existing track or path to increase positional accuracy.
  /// - [algorithmType]: Public-transport algorithm selection. Specifies if the [timestamp] should be interpreted for departure or arrival-based strategies.
  /// - [allowOnlineCalculation]: Whether online calculation can be used. If `false`, the routing engine will rely solely on offline data.
  /// - [alternativeRoutesBalancedSorting]: Balances sorting of alternative routes.
  /// - [alternativesSchema]: Defines the schema for alternative routes.
  /// - [avoidBikingHillFactor]: (Deprecated) Use [fitnessFactor] instead. Factor that influences how strongly hills are avoided when computing bike routes.
  /// - [fitnessFactor]: Factor that influences routing for bikes and pedestrians; affects slope preferences based on profile type.
  /// - [avoidCarpoolLanes]: When true, avoid carpool/HOV lanes in car routing.
  /// - [avoidFerries]: When true, avoid ferry segments in the route.
  /// - [avoidMotorways]: When true, avoid motorways/highways when possible.
  /// - [avoidTollRoads]: When true, avoid toll roads when possible.
  /// - [avoidTraffic]: Level of traffic avoidance to apply when computing motorized routes.
  /// - [avoidTurnAroundInstruction]: When true, prefer routes that do not require explicit turn-around maneuvers.
  /// - [avoidUnpavedRoads]: When true, avoid unpaved or unsealed roads in the route.
  /// - [bikeProfile]: Optional bike-specific routing profile to override default bicycle behavior.
  /// - [buildConnections]: When true, construct and include connections.
  /// - [buildTerrainProfile]: Options controlling whether and how a terrain profile is built for the route. Is crucial for [RouteTerrainProfile] availability.
  /// - [carProfile]: Optional car-specific routing profile to override default car behavior.
  /// - [departureHeading]: Optional heading constraint applied at the route origin.
  /// - [emergencyVehicleExtraFreedomLevels]: Extra freedom levels for emergency vehicles.
  /// - [emergencyVehicleMode]: When true, enable emergency-vehicle routing behavior and allowances.
  /// - [ignoreRestrictionsOverTrack]: When true, ignore map-based restrictions during path based calculations.
  /// - [maximumDistanceConstraint]: When true, enforce maximum distance constraints where applicable.
  /// - [maximumTransferTimeInMinutes]: Maximum allowed transfer time (in minutes) when building transit routes.
  /// - [maximumWalkDistance]: Maximum walking distance (in meters) that is allowed in the public transport route.
  /// - [minimumTransferTimeInMinutes]: Minimum allowed transfer time (in minutes) between connections in public transport routes.
  /// - [pathAlgorithm]: Choice of pathfinding algorithm used to compute the route geometry.
  /// - [pathAlgorithmFlavor]: Variant or flavor of the chosen path algorithm to tweak behavior or heuristics.
  /// - [pedestrianProfile]: Pedestrian profile selection (for example, walk, run) to influence pedestrian routing.
  /// - [resultDetails]: Level of detail to include in the returned [Route] (summary vs full details).
  /// - [routeGroupIdsEarlierLater]: IDs for earlier/later route groups.
  /// - [routeRanges]: List of route ranges thresholds used when generating route ranges. The unit depends on the [routeType].
  /// - [routeRangesQuality]: Quality threshold applied to route ranges.
  /// - [routeResultType]: The type of the returned [Route] type: navigable path or range.
  /// - [routeType]: Preferred route type (for example, fastest, shortest, or eco).
  /// - [routeTypePreferences]: Set of additional public-transport route type preferences influencing the preferred transport modes.
  /// - [sortingStrategy]: Strategy used to sort or rank public-transport alternatives.
  /// - [timestamp]: Optional reference timestamp for the routing request (e.g., departure/arrival time).
  /// - [transportMode]: Primary transport mode for the route (for example, car, bike, pedestrian).
  /// - [truckProfile]: Optional truck-specific routing profile to override default truck behavior.
  /// - [useBikes]: When true, enable bike-accessible routing constraints.
  /// - [useWheelchair]: When true, enable wheelchair-accessible routing constraints.
  /// - [isTrackResume]: Whether path-based routing should follow the whole track or resume from the closest point.
  /// - [roundTripParameters]: Optional parameters for roundtrip route generation.
  /// - [roundTripRange]: Desired roundtrip distance or duration, depending on [roundTripRangeType].
  /// - [roundTripRangeType]: Unit type for the roundtrip range (distance or duration).
  /// - [roundTripRandomSeed]: Optional random seed to influence roundtrip route generation variability.
  ///
  /// ## See also:
  ///
  /// - [RoutePreferences] - The class holding these constructor options.
  /// - [RouteTransportMode] - Available transport modes that affect routing behavior.
  /// - [CarProfile] - Car-specific routing constraints.
  /// - [TruckProfile] - Truck-specific routing constraints.
  factory RoutePreferences({
    final bool accurateTrackMatch = _defaultAccurateTrackMatch,
    final PTAlgorithmType algorithmType = _defaultAlgorithmType,
    final bool allowOnlineCalculation = _defaultAllowOnlineCalculation,
    final bool alternativeRoutesBalancedSorting =
        _defaultAlternativeRoutesBalancedSorting,
    final RouteAlternativesSchema alternativesSchema =
        _defaultAlternativesSchema,
    @Deprecated('Use fitnessFactor instead')
    final double? avoidBikingHillFactor,
    final double fitnessFactor = _defaultFitnessFactor,
    final bool avoidCarpoolLanes = _defaultAvoidCarpoolLanes,
    final bool avoidFerries = _defaultAvoidFerries,
    final bool avoidMotorways = _defaultAvoidMotorways,
    final bool avoidTollRoads = _defaultAvoidTollRoads,
    final TrafficAvoidance avoidTraffic = _defaultAvoidTraffic,
    final bool avoidTurnAroundInstruction = _defaultAvoidTurnAroundInstruction,
    final bool avoidUnpavedRoads = _defaultAvoidUnpavedRoads,
    final BikeProfileElectricBikeProfile? bikeProfile,
    final bool buildConnections = _defaultBuildConnections,
    final BuildTerrainProfile buildTerrainProfile = _defaultBuildTerrainProfile,
    final CarProfile? carProfile,
    final DepartureHeading departureHeading = _defaultDepartureHeading,
    final int emergencyVehicleExtraFreedomLevels =
        _defaultEmergencyVehicleExtraFreedomLevels,
    final bool emergencyVehicleMode = _defaultEmergencyVehicleMode,
    final bool ignoreRestrictionsOverTrack =
        _defaultIgnoreRestrictionsOverTrack,
    final bool maximumDistanceConstraint = _defaultMaximumDistanceConstraint,
    final int maximumTransferTimeInMinutes =
        _defaultMaximumTransferTimeInMinutes,
    final int maximumWalkDistance = _defaultMaximumWalkDistance,
    final int minimumTransferTimeInMinutes =
        _defaultMinimumTransferTimeInMinutes,
    final RoutePathAlgorithm pathAlgorithm = _defaultPathAlgorithm,
    final RoutePathAlgorithmFlavor pathAlgorithmFlavor =
        _defaultPathAlgorithmFlavor,
    final PedestrianProfile pedestrianProfile = _defaultPedestrianProfile,
    final RouteResultDetails resultDetails = _defaultResultDetails,
    final List<int> routeGroupIdsEarlierLater = const <int>[],
    final List<int> routeRanges = const <int>[],
    final int routeRangesQuality = _defaultRouteRangesQuality,
    final RouteType routeType = _defaultRouteType,
    final Set<RouteTypePreferences> routeTypePreferences =
        const <RouteTypePreferences>{RouteTypePreferences.none},
    final PTSortingStrategy sortingStrategy = _defaultSortingStrategy,
    final DateTime? timestamp,
    final RouteTransportMode transportMode = _defaultTransportMode,
    final TruckProfile? truckProfile,
    final bool useBikes = _defaultUseBikes,
    final bool useWheelchair = _defaultUseWheelchair,
    final bool isTrackResume = _defaultIsTrackResume,
    final bool immutableRoadblockAvoidance =
        _defaultImmutableRoadblockAvoidance,
    final bool accurateWaypointsApproach = _defaultAccurateWaypointsApproach,
    final RoundTripParameters? roundTripParameters,
  }) {
    final RoutePreferences result = RoutePreferences._create();
    result._applyRoutingOptions(
      transportMode: transportMode,
      routeType: routeType,
      pathAlgorithm: pathAlgorithm,
      pathAlgorithmFlavor: pathAlgorithmFlavor,
      resultDetails: resultDetails,
      allowOnlineCalculation: allowOnlineCalculation,
      maximumDistanceConstraint: maximumDistanceConstraint,
      alternativeRoutesBalancedSorting: alternativeRoutesBalancedSorting,
      alternativesSchema: alternativesSchema,
      buildConnections: buildConnections,
      buildTerrainProfile: buildTerrainProfile,
      departureHeading: departureHeading,
      immutableRoadblockAvoidance: immutableRoadblockAvoidance,
      accurateWaypointsApproach: accurateWaypointsApproach,
      avoidCarpoolLanes: avoidCarpoolLanes,
      avoidFerries: avoidFerries,
      avoidMotorways: avoidMotorways,
      avoidTollRoads: avoidTollRoads,
      avoidTraffic: avoidTraffic,
      avoidTurnAroundInstruction: avoidTurnAroundInstruction,
      avoidUnpavedRoads: avoidUnpavedRoads,
    );
    result._applyTrackAndFitnessOptions(
      accurateTrackMatch: accurateTrackMatch,
      ignoreRestrictionsOverTrack: ignoreRestrictionsOverTrack,
      isTrackResume: isTrackResume,
      fitnessFactor: avoidBikingHillFactor ?? fitnessFactor,
      pedestrianProfile: pedestrianProfile,
    );
    result._applyPublicTransportOptions(
      algorithmType: algorithmType,
      sortingStrategy: sortingStrategy,
      routeTypePreferences: routeTypePreferences,
      routeGroupIdsEarlierLater: routeGroupIdsEarlierLater,
      minimumTransferTimeInMinutes: minimumTransferTimeInMinutes,
      maximumTransferTimeInMinutes: maximumTransferTimeInMinutes,
      maximumWalkDistance: maximumWalkDistance,
      useBikes: useBikes,
      useWheelchair: useWheelchair,
      timestamp: timestamp,
    );
    result._applyCompoundOptions(
      routeRanges: routeRanges,
      routeRangesQuality: routeRangesQuality,
      emergencyVehicleMode: emergencyVehicleMode,
      emergencyVehicleExtraFreedomLevels: emergencyVehicleExtraFreedomLevels,
    );
    result._applyProfileOptions(
      bikeProfile: bikeProfile,
      carProfile: carProfile,
      truckProfile: truckProfile,
      roundTripParameters: roundTripParameters,
    );
    return result;
  }

  @internal
  RoutePreferences.init(super.id);

  /// Creates an independent deep copy of these preferences.
  ///
  /// The returned [RoutePreferences] starts out with the same values as this
  /// instance but is fully independent — mutations on either side do not
  /// affect the other. Use this when you want to derive a variant of an
  /// existing configuration (for example to issue a slightly tweaked route
  /// calculation) without disturbing the original.
  ///
  /// All scalar, enum, vehicle profile (car / truck / bike / EV), route
  /// range, geofence avoidance, and round-trip configuration is preserved,
  /// including internal sentinels that are not directly observable through
  /// the public API such as the `avoidTurnAroundInstruction` tri-state and
  /// the automatic / explicit timestamp flag.
  ///
  /// The new instance is registered with the native auto-release machinery
  /// just like a factory-constructed one, so no manual disposal is
  /// required.
  ///
  /// ## Returns
  ///
  /// A new [RoutePreferences] whose fields equal those of this instance at
  /// the moment of the call.
  RoutePreferences copy() {
    final OperationResult result = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'copy',
    );
    return RoutePreferences.init(result['result']);
  }

  static const bool _defaultAccurateTrackMatch = true;
  static const PTAlgorithmType _defaultAlgorithmType =
      PTAlgorithmType.departure;
  static const bool _defaultAllowOnlineCalculation = true;
  static const bool _defaultAlternativeRoutesBalancedSorting = true;
  static const RouteAlternativesSchema _defaultAlternativesSchema =
      RouteAlternativesSchema.defaultSchema;
  static const double _defaultFitnessFactor = 0.5;
  static const bool _defaultAvoidCarpoolLanes = false;
  static const bool _defaultAvoidFerries = false;
  static const bool _defaultAvoidMotorways = false;
  static const bool _defaultAvoidTollRoads = false;
  static const TrafficAvoidance _defaultAvoidTraffic = TrafficAvoidance.none;
  static const bool _defaultAvoidTurnAroundInstruction = false;
  static const bool _defaultAvoidUnpavedRoads = false;
  static const bool _defaultBuildConnections = false;
  static const BuildTerrainProfile _defaultBuildTerrainProfile =
      BuildTerrainProfile();
  static const DepartureHeading _defaultDepartureHeading = DepartureHeading();
  static const int _defaultEmergencyVehicleExtraFreedomLevels = 0;
  static const bool _defaultEmergencyVehicleMode = false;
  static const bool _defaultIgnoreRestrictionsOverTrack = false;
  static const bool _defaultMaximumDistanceConstraint = true;
  static const int _defaultMaximumTransferTimeInMinutes = 300;
  static const int _defaultMaximumWalkDistance = 5000;
  static const int _defaultMinimumTransferTimeInMinutes = 1;
  static const RoutePathAlgorithm _defaultPathAlgorithm = RoutePathAlgorithm.ml;
  static const RoutePathAlgorithmFlavor _defaultPathAlgorithmFlavor =
      RoutePathAlgorithmFlavor.magicLane;
  static const PedestrianProfile _defaultPedestrianProfile =
      PedestrianProfile.walk;
  static const RouteResultDetails _defaultResultDetails =
      RouteResultDetails.full;
  static const int _defaultRouteRangesQuality = 100;
  static const RouteType _defaultRouteType = RouteType.fastest;
  static const PTSortingStrategy _defaultSortingStrategy =
      PTSortingStrategy.bestTime;
  static const RouteTransportMode _defaultTransportMode =
      RouteTransportMode.car;
  static const bool _defaultUseBikes = false;
  static const bool _defaultUseWheelchair = false;
  static const bool _defaultIsTrackResume = true;
  static const bool _defaultImmutableRoadblockAvoidance = false;
  static const bool _defaultAccurateWaypointsApproach = false;

  void _applyRoutingOptions({
    required final RouteTransportMode transportMode,
    required final RouteType routeType,
    required final RoutePathAlgorithm pathAlgorithm,
    required final RoutePathAlgorithmFlavor pathAlgorithmFlavor,
    required final RouteResultDetails resultDetails,
    required final bool allowOnlineCalculation,
    required final bool maximumDistanceConstraint,
    required final bool alternativeRoutesBalancedSorting,
    required final RouteAlternativesSchema alternativesSchema,
    required final bool buildConnections,
    required final BuildTerrainProfile buildTerrainProfile,
    required final DepartureHeading departureHeading,
    required final bool immutableRoadblockAvoidance,
    required final bool accurateWaypointsApproach,
    required final bool avoidCarpoolLanes,
    required final bool avoidFerries,
    required final bool avoidMotorways,
    required final bool avoidTollRoads,
    required final TrafficAvoidance avoidTraffic,
    required final bool avoidTurnAroundInstruction,
    required final bool avoidUnpavedRoads,
  }) {
    if (transportMode != _defaultTransportMode) {
      this.transportMode = transportMode;
    }
    if (routeType != _defaultRouteType) {
      this.routeType = routeType;
    }
    if (pathAlgorithm != _defaultPathAlgorithm) {
      this.pathAlgorithm = pathAlgorithm;
    }
    if (pathAlgorithmFlavor != _defaultPathAlgorithmFlavor) {
      this.pathAlgorithmFlavor = pathAlgorithmFlavor;
    }
    if (resultDetails != _defaultResultDetails) {
      this.resultDetails = resultDetails;
    }
    if (allowOnlineCalculation != _defaultAllowOnlineCalculation) {
      this.allowOnlineCalculation = allowOnlineCalculation;
    }
    if (maximumDistanceConstraint != _defaultMaximumDistanceConstraint) {
      this.maximumDistanceConstraint = maximumDistanceConstraint;
    }
    if (alternativeRoutesBalancedSorting !=
        _defaultAlternativeRoutesBalancedSorting) {
      this.alternativeRoutesBalancedSorting = alternativeRoutesBalancedSorting;
    }
    if (alternativesSchema != _defaultAlternativesSchema) {
      this.alternativesSchema = alternativesSchema;
    }
    if (buildConnections != _defaultBuildConnections) {
      this.buildConnections = buildConnections;
    }
    if (buildTerrainProfile != _defaultBuildTerrainProfile) {
      this.buildTerrainProfile = buildTerrainProfile;
    }
    if (departureHeading != _defaultDepartureHeading) {
      this.departureHeading = departureHeading;
    }
    if (immutableRoadblockAvoidance != _defaultImmutableRoadblockAvoidance) {
      this.immutableRoadblockAvoidance = immutableRoadblockAvoidance;
    }
    if (accurateWaypointsApproach != _defaultAccurateWaypointsApproach) {
      this.accurateWaypointsApproach = accurateWaypointsApproach;
    }
    if (avoidCarpoolLanes != _defaultAvoidCarpoolLanes) {
      this.avoidCarpoolLanes = avoidCarpoolLanes;
    }
    if (avoidFerries != _defaultAvoidFerries) {
      this.avoidFerries = avoidFerries;
    }
    if (avoidMotorways != _defaultAvoidMotorways) {
      this.avoidMotorways = avoidMotorways;
    }
    if (avoidTollRoads != _defaultAvoidTollRoads) {
      this.avoidTollRoads = avoidTollRoads;
    }
    if (avoidTraffic != _defaultAvoidTraffic) {
      this.avoidTraffic = avoidTraffic;
    }
    // `avoidTurnAroundInstruction` is backed by a tri-state on the C++ side
    // (`EDefault`/`ETrue`/`EFalse`). When the state is `EDefault`, the native
    // getter computes a transport-mode-dependent value (e.g. `true` for cars
    // and lorries), which would not match the documented Dart default of
    // `false`. The setter must therefore be invoked unconditionally so the
    // state transitions out of `EDefault` to the explicit value provided here.
    this.avoidTurnAroundInstruction = avoidTurnAroundInstruction;
    if (avoidUnpavedRoads != _defaultAvoidUnpavedRoads) {
      this.avoidUnpavedRoads = avoidUnpavedRoads;
    }
  }

  void _applyTrackAndFitnessOptions({
    required final bool accurateTrackMatch,
    required final bool ignoreRestrictionsOverTrack,
    required final bool isTrackResume,
    required final double fitnessFactor,
    required final PedestrianProfile pedestrianProfile,
  }) {
    if (accurateTrackMatch != _defaultAccurateTrackMatch) {
      this.accurateTrackMatch = accurateTrackMatch;
    }
    if (ignoreRestrictionsOverTrack != _defaultIgnoreRestrictionsOverTrack) {
      this.ignoreRestrictionsOverTrack = ignoreRestrictionsOverTrack;
    }
    if (isTrackResume != _defaultIsTrackResume) {
      this.isTrackResume = isTrackResume;
    }
    if (fitnessFactor != _defaultFitnessFactor) {
      this.fitnessFactor = fitnessFactor;
    }
    if (pedestrianProfile != _defaultPedestrianProfile) {
      this.pedestrianProfile = pedestrianProfile;
    }
  }

  void _applyPublicTransportOptions({
    required final PTAlgorithmType algorithmType,
    required final PTSortingStrategy sortingStrategy,
    required final Set<RouteTypePreferences> routeTypePreferences,
    required final List<int> routeGroupIdsEarlierLater,
    required final int minimumTransferTimeInMinutes,
    required final int maximumTransferTimeInMinutes,
    required final int maximumWalkDistance,
    required final bool useBikes,
    required final bool useWheelchair,
    required final DateTime? timestamp,
  }) {
    if (algorithmType != _defaultAlgorithmType) {
      this.algorithmType = algorithmType;
    }
    if (sortingStrategy != _defaultSortingStrategy) {
      this.sortingStrategy = sortingStrategy;
    }
    final int routeTypePreferencesBitmask = routeTypePreferences.fold(
      0,
      (final int res, final RouteTypePreferences item) => res | item.id,
    );
    if (routeTypePreferencesBitmask != 0) {
      this.routeTypePreferences = routeTypePreferences;
    }
    if (routeGroupIdsEarlierLater.isNotEmpty) {
      this.routeGroupIdsEarlierLater = routeGroupIdsEarlierLater;
    }
    if (minimumTransferTimeInMinutes != _defaultMinimumTransferTimeInMinutes) {
      this.minimumTransferTimeInMinutes = minimumTransferTimeInMinutes;
    }
    if (maximumTransferTimeInMinutes != _defaultMaximumTransferTimeInMinutes) {
      this.maximumTransferTimeInMinutes = maximumTransferTimeInMinutes;
    }
    if (maximumWalkDistance != _defaultMaximumWalkDistance) {
      this.maximumWalkDistance = maximumWalkDistance;
    }
    if (useBikes != _defaultUseBikes) {
      this.useBikes = useBikes;
    }
    if (useWheelchair != _defaultUseWheelchair) {
      this.useWheelchair = useWheelchair;
    }
    if (timestamp != null) {
      this.timestamp = timestamp;
    }
  }

  void _applyCompoundOptions({
    required final List<int> routeRanges,
    required final int routeRangesQuality,
    required final bool emergencyVehicleMode,
    required final int emergencyVehicleExtraFreedomLevels,
  }) {
    if (routeRanges.isNotEmpty ||
        routeRangesQuality != _defaultRouteRangesQuality) {
      objectMethod(
        pointerId,
        'RoutePrefWrapper',
        'routeranges',
        args: <String, dynamic>{
          'list': routeRanges,
          'quality': routeRangesQuality,
        },
      );
    }
    if (emergencyVehicleMode != _defaultEmergencyVehicleMode ||
        emergencyVehicleExtraFreedomLevels !=
            _defaultEmergencyVehicleExtraFreedomLevels) {
      objectMethod(
        pointerId,
        'RoutePrefWrapper',
        'emergencyVehicleMode',
        args: <String, dynamic>{
          'enable': emergencyVehicleMode,
          'extraFreedom': emergencyVehicleExtraFreedomLevels,
        },
      );
    }
  }

  void _applyProfileOptions({
    required final BikeProfileElectricBikeProfile? bikeProfile,
    required final CarProfile? carProfile,
    required final TruckProfile? truckProfile,
    required final RoundTripParameters? roundTripParameters,
  }) {
    if (bikeProfile != null) {
      this.bikeProfile = bikeProfile;
    }
    if (carProfile != null) {
      this.carProfile = carProfile;
    }
    if (truckProfile != null) {
      this.truckProfile = truckProfile;
    }
    if (roundTripParameters != null) {
      this.roundTripParameters = roundTripParameters;
    }
  }

  /// Enables accurate track matching for route-over-track computations.
  ///
  /// When true, the SDK uses more precise track matching algorithms during
  /// route calculation when track-based landmarks are provided.
  ///
  /// Default is true
  bool get accurateTrackMatch {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAccurateTrackMatch',
    );
    return resultString['result'];
  }

  /// Enables accurate track matching for route-over-track computations.
  ///
  /// When true, the SDK uses more precise track matching algorithms during
  /// route calculation when track-based landmarks are provided.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to enable accurate track matching, false to disable.
  ///
  /// Default is true
  set accurateTrackMatch(final bool value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'accuratetrackmatch',
      args: value,
    );
  }

  /// Public transport algorithm type for determining departure or arrival time optimization.
  ///
  /// Controls whether public transport routes are optimized for departure time
  /// or arrival time specified in [timestamp]. Only applies to public transport
  /// routes.
  ///
  /// Default is [PTAlgorithmType.departure].
  PTAlgorithmType get algorithmType {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAlgorithmType',
    );
    return PTAlgorithmTypeExtension.fromId(resultString['result']);
  }

  /// Public transport algorithm type for determining departure or arrival time optimization.
  ///
  /// Controls whether public transport routes are optimized for departure time
  /// or arrival time specified in [timestamp]. Only applies to public transport
  /// routes.
  ///
  /// ## Parameters
  ///
  /// - [value]: The algorithm type to use for public transport routing.
  ///
  /// Default is [PTAlgorithmType.departure].
  set algorithmType(final PTAlgorithmType value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'algorithmtype',
      args: value.id,
    );
  }

  /// Allows route calculation using online services when available.
  ///
  /// When enabled, the SDK may use online routing services for calculating
  /// routes in addition to or instead of offline data. Network connectivity is
  /// required when this option is enabled.
  ///
  /// Default is `true`.
  bool get allowOnlineCalculation {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAllowOnlineCalculation',
    );
    return resultString['result'];
  }

  /// Allows route calculation using online services when available.
  ///
  /// When enabled, the SDK may use online routing services for calculating
  /// routes in addition to or instead of offline data. Network connectivity is
  /// required when this option is enabled.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to allow online calculation, false to use only offline data.
  ///
  /// Default is `true`.
  set allowOnlineCalculation(final bool value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'allowonlinecalculation',
      args: value,
    );
  }

  /// Enables balanced sorting for alternative route results.
  ///
  /// Balances sorting of alternative routes.
  ///
  /// Default is `true`.
  bool get alternativeRoutesBalancedSorting {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAlternativeRoutesBalancedSorting',
    );
    return resultString['result'];
  }

  /// Enables balanced sorting for alternative route results.
  ///
  /// Balances sorting of alternative routes.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to enable balanced sorting, false to disable.
  ///
  /// Default is `true`.
  set alternativeRoutesBalancedSorting(final bool value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'alternativeroutesbalancedsorting',
      args: value,
    );
  }

  /// Schema defining how alternative routes are generated and returned.
  ///
  /// Defines the schema for alternative routes.
  ///
  /// Default is [RouteAlternativesSchema.defaultSchema].
  RouteAlternativesSchema get alternativesSchema {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAlternativesSchema',
    );
    return RouteAlternativesSchemaExtension.fromId(resultString['result']);
  }

  /// Get route connections build max length.
  ///
  /// Default is -1.
  @experimental
  int get buildConnectionsMaxLength {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getBuildConnectionsMaxLength',
    );
    return resultString['result'];
  }

  /// Schema defining how alternative routes are generated and returned.
  ///
  /// Defines the schema for alternative routes.
  ///
  /// ## Parameters
  ///
  /// - [value]: The schema to use for generating alternative routes.
  ///
  /// Default is [RouteAlternativesSchema.defaultSchema].
  set alternativesSchema(final RouteAlternativesSchema value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'alternativesschema',
      args: value.id,
    );
  }

  /// Hill avoidance factor for bicycle routes, ranging from 0.0 to 1.0.
  ///
  /// Controls how strongly hills and steep inclines are avoided when
  /// calculating bicycle routes.
  ///
  /// Default is `0.5`.
  @Deprecated('Use fitnessFactor instead')
  double get avoidBikingHillFactor {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getFitnessFactor',
    );
    return resultString['result'];
  }

  /// Hill avoidance factor for bicycle routes, ranging from 0.0 to 1.0.
  ///
  /// Controls how strongly hills and steep inclines are avoided when
  /// calculating bicycle routes.
  ///
  /// ## Parameters
  ///
  /// - [value]: Factor from 0.0 (no avoidance) to 1.0 (maximum avoidance).
  ///
  /// Default is `0.5`.
  @Deprecated('Use fitnessFactor instead')
  set avoidBikingHillFactor(final double value) {
    objectMethod(pointerId, 'RoutePrefWrapper', 'fitnessFactor', args: value);
  }

  /// Bike & pedestrian routing fitness factor, ranging from 0.0 to 1.0.
  ///
  /// Controls how strongly hills and steep inclines are avoided when
  /// calculating bicycle routes.
  ///
  /// Default is `0.5` ( normal / good shape ).
  double get fitnessFactor {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getFitnessFactor',
    );
    return resultString['result'];
  }

  /// Bike & pedestrian routing fitness factor, ranging from 0.0 to 1.0.
  ///
  /// The fitness factor affects route path configuration.
  ///
  /// For mountain bike and pedestrian hiking profiles the fitness factor is used to boost to steeper slopes in path links selection.
  ///
  /// For city bike, road bike and cross bike the fitness factor is used to avoid steeper slopes in path links selection.
  ///
  /// ## Parameters
  ///
  /// - [value]: Factor from 0.0 (untrained) to 1.0 (professional).
  ///
  /// Default is `0.5`.
  set fitnessFactor(final double value) {
    objectMethod(pointerId, 'RoutePrefWrapper', 'fitnessFactor', args: value);
  }

  /// Avoids carpool/HOV lanes when calculating routes.
  ///
  /// When true, routes avoid high-occupancy vehicle (HOV) or carpool lanes.
  /// This option is only available for custom builds containing TomTom map data
  /// and is ignored in public builds.
  ///
  /// Default is `false`.
  bool get avoidCarpoolLanes {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAvoidCarpoolLanes',
    );
    return resultString['result'];
  }

  /// Avoids carpool/HOV lanes when calculating routes.
  ///
  /// When true, routes avoid high-occupancy vehicle (HOV) or carpool lanes.
  /// This option is only available for custom builds containing TomTom map data
  /// and is ignored in public builds.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to avoid carpool lanes, false to allow them.
  ///
  /// Default is `false`.
  set avoidCarpoolLanes(final bool value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'avoidcarpoollanes',
      args: value,
    );
  }

  /// Get the geofence area avoidance ids list
  List<String> get avoidGeofenceAreas {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAvoidGeofenceAreas',
    );
    return resultString['result'].cast<String>();
  }

  /// Set avoidance of the given geofence area ids
  ///
  /// Send an empty list to disable geofence anti area avoidance
  ///
  /// ## Parameters
  ///
  /// - [value]: The geofence area ids to avoid
  set avoidGeofenceAreas(final List<String> value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'avoidGeofenceAreas',
      args: value,
    );
  }

  /// Get the geofence anti area avoidance ids list
  /// An anti area geofence is an area in which boundaries the route should remain during the calculation.
  /// If [immutableRoadblockAvoidance] == true and the route cannot stay in the requested boundaries, the routing will fail with [GemError.noRoute]
  /// Send an empty list to disable geofence anti area avoidance
  @experimental
  List<String> get avoidGeofenceAntiAreas {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAvoidGeofenceAntiAreas',
    );
    return resultString['result'].cast<String>();
  }

  /// Set avoidance of the given geofence anti area ids
  /// An anti area geofence is an area in which boundaries the route should remain during the calculation.
  /// If [immutableRoadblockAvoidance] == true and the route cannot stay in the requested boundaries, the routing will fail with [GemError.noRoute]
  /// Send an empty list to disable geofence anti area avoidance
  ///
  /// ## Parameters
  ///
  /// - [value]: The geofence anti area ids to avoid
  @experimental
  set avoidGeofenceAntiAreas(final List<String> value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'avoidGeofenceAntiAreas',
      args: value,
    );
  }

  /// Avoids ferry crossings when calculating routes.
  ///
  /// When true, the routing engine avoids routes that include ferry segments.
  ///
  /// Default is `false`.
  bool get avoidFerries {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAvoidFerries',
    );
    return resultString['result'];
  }

  /// Avoids ferry crossings when calculating routes.
  ///
  /// When true, the routing engine avoids routes that include ferry segments.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to avoid ferries, false to allow them.
  ///
  /// Default is `false`.
  set avoidFerries(final bool value) {
    objectMethod(pointerId, 'RoutePrefWrapper', 'avoidferries', args: value);
  }

  /// Avoids motorways/highways when calculating routes.
  ///
  /// When true, the routing engine avoids high-speed motorways and highways,
  /// preferring local roads instead.
  ///
  /// Default is `false`.
  bool get avoidMotorways {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAvoidMotorways',
    );
    return resultString['result'];
  }

  /// Avoids motorways/highways when calculating routes.
  ///
  /// When true, the routing engine avoids high-speed motorways and highways,
  /// preferring local roads instead.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to avoid motorways, false to allow them.
  ///
  /// Default is `false`.
  set avoidMotorways(final bool value) {
    objectMethod(pointerId, 'RoutePrefWrapper', 'avoidmotorways', args: value);
  }

  /// Avoids toll roads when calculating routes.
  ///
  /// When true, the routing engine avoids roads that require toll payments.
  ///
  /// Default is `false`.
  bool get avoidTollRoads {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAvoidTollRoads',
    );
    return resultString['result'];
  }

  /// Avoids toll roads when calculating routes.
  ///
  /// When true, the routing engine avoids roads that require toll payments.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to avoid toll roads, false to allow them.
  ///
  /// Default is `false`.
  set avoidTollRoads(final bool value) {
    objectMethod(pointerId, 'RoutePrefWrapper', 'avoidtollroads', args: value);
  }

  /// Traffic avoidance strategy for route calculation.
  ///
  /// Determines how the routing engine considers real-time traffic, road
  /// blocks, and congestion when computing routes. Options include avoiding
  /// traffic completely, considering roadblocks only, or using live traffic
  /// data.
  ///
  /// Default is [TrafficAvoidance.none].
  TrafficAvoidance get avoidTraffic {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAvoidTraffic',
    );
    return TrafficAvoidanceExtension.fromId(resultString['result']);
  }

  /// Traffic avoidance strategy for route calculation.
  ///
  /// Determines how the routing engine considers real-time traffic, road
  /// blocks, and congestion when computing routes. Options include avoiding
  /// traffic completely, considering roadblocks only, or using live traffic
  /// data.
  ///
  /// ## Parameters
  ///
  /// - [value]: The traffic avoidance strategy to apply.
  ///
  /// Default is [TrafficAvoidance.none].
  set avoidTraffic(final TrafficAvoidance value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'avoidtraffic',
      args: value.index,
    );
  }

  /// Avoids generating "Turnaround when possible" instructions during navigation.
  ///
  /// When true, the SDK avoids generating turn-around instructions. For car and
  /// truck transport modes, this preference is overridden during route
  /// recalculation (the current driving direction is used instead), except when
  /// emergency vehicle mode is active.
  ///
  /// When setting user roadblocks during navigation, this preference controls
  /// whether a turn-around instruction may be generated.
  ///
  /// Default is `false`.
  bool get avoidTurnAroundInstruction {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAvoidTurnAroundInstruction',
    );
    return resultString['result'];
  }

  /// Avoids generating "Turnaround when possible" instructions during navigation.
  ///
  /// When true, the SDK avoids generating turn-around instructions. For car and
  /// truck transport modes, this preference is overridden during route
  /// recalculation (the current driving direction is used instead), except when
  /// emergency vehicle mode is active.
  ///
  /// When setting user roadblocks during navigation, this preference controls
  /// whether a turn-around instruction may be generated.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to avoid turn-around instructions, false to allow them.
  ///
  /// Default is `false`.
  set avoidTurnAroundInstruction(final bool value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'avoidturnaroundinstruction',
      args: value,
    );
  }

  /// Avoids unpaved roads when calculating routes.
  ///
  /// When true, the routing engine avoids gravel, dirt, and other unpaved road
  /// surfaces.
  ///
  /// Default is `false`.
  bool get avoidUnpavedRoads {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAvoidUnpavedRoads',
    );
    return resultString['result'];
  }

  /// Avoids unpaved roads when calculating routes.
  ///
  /// When true, the routing engine avoids gravel, dirt, and other unpaved road
  /// surfaces.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to avoid unpaved roads, false to allow them.
  ///
  /// Default is `false`.
  set avoidUnpavedRoads(final bool value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'avoidunpavedroads',
      args: value,
    );
  }

  /// Bicycle routing profile for standard and electric bikes.
  ///
  /// Configure bike-specific routing preferences including bike type (road,
  /// mountain, city, cross) and electric bike parameters (mass, auxiliary
  /// consumption). Only used when [transportMode] is [RouteTransportMode.bicycle].
  ///
  /// Default is `null` (no bike profile).
  BikeProfileElectricBikeProfile get bikeProfile {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getBikeProfile',
    );
    return BikeProfileElectricBikeProfile.fromJson(resultString['result']);
  }

  /// Default electric bike profile configuration.
  @experimental
  ElectricBikeProfile get defaultEBikeProfile {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getDefaultEBikeProfile',
    );
    return ElectricBikeProfile.fromJson(resultString['result']);
  }

  /// Bicycle routing profile for standard and electric bikes.
  ///
  /// Configure bike-specific routing preferences including bike type (road,
  /// mountain, city, cross) and electric bike parameters (mass, auxiliary
  /// consumption). Only used when [transportMode] is [RouteTransportMode.bicycle].
  ///
  /// ## Parameters
  ///
  /// - [value]: The bike profile configuration to use.
  ///
  /// Default is `null` (no bike profile).
  set bikeProfile(final BikeProfileElectricBikeProfile value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'bikeprofile',
      args: value.toJson(),
    );
  }

  /// Enables building route segment connections metadata.
  ///
  /// When true, the computed route includes detailed connection information.
  ///
  /// Default is `false`.
  bool get buildConnections {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getBuildConnections',
    );
    return resultString['result'];
  }

  /// Enables building route segment connections metadata.
  ///
  /// When true, the computed route includes detailed connection information.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to build connections metadata, false to omit it.
  ///
  /// Default is `false`.
  set buildConnections(final bool value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'buildconnections',
      args: value,
    );
  }

  /// Controls whether terrain profile data is generated for the route.
  ///
  /// When [BuildTerrainProfile.enable] is true, the computed route includes
  /// elevation and terrain profile information accessible via
  /// [RouteBase.terrainProfile]. When false, terrain profile data is not
  /// computed and [RouteBase.terrainProfile] will be null.
  ///
  /// Default is an object with [BuildTerrainProfile.enable] set to `false`.
  BuildTerrainProfile get buildTerrainProfile {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getBuildTerrainProfile',
    );
    return BuildTerrainProfile.fromJson(resultString['result']);
  }

  /// Controls whether terrain profile data is generated for the route.
  ///
  /// When [BuildTerrainProfile.enable] is true, the computed route includes
  /// elevation and terrain profile information accessible via
  /// [RouteBase.terrainProfile]. When false, terrain profile data is not
  /// computed and [RouteBase.terrainProfile] will be null.
  ///
  /// ## Parameters
  ///
  /// - [value]: The terrain profile build configuration.
  ///
  /// Default is an object with [BuildTerrainProfile.enable] set to `false`.
  set buildTerrainProfile(final BuildTerrainProfile value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'buildterrainprofile',
      args: value.toJson(),
    );
  }

  /// Car routing profile with vehicle-specific constraints.
  ///
  /// Configure car-specific routing preferences including mass, fuel type, max
  /// speed, and plate number. Only used when [transportMode] is
  /// [RouteTransportMode.car].
  ///
  /// Default is `null` (no car profile).
  CarProfile get carProfile {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getCarProfile',
    );
    return CarProfile.fromJson(resultString['result']);
  }

  /// Car routing profile with vehicle-specific constraints.
  ///
  /// Configure car-specific routing preferences including mass, fuel type, max
  /// speed, and plate number. Only used when [transportMode] is
  /// [RouteTransportMode.car].
  ///
  /// ## Parameters
  ///
  /// - [value]: The car profile configuration to use.
  ///
  /// Default is `null` (no car profile).
  set carProfile(final CarProfile value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'carprofile',
      args: value.toJson(),
    );
  }

  /// Departure heading and accuracy for route calculation.
  ///
  /// Specifies the initial heading direction (in degrees) and accuracy when
  /// starting a route. When [DepartureHeading.heading] is -1, no departure
  /// heading constraint is applied.
  ///
  /// Default is `DepartureHeading(heading: -1, accuracy: -1)` (no constraint).
  DepartureHeading get departureHeading {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getDepartureHeading',
    );
    return DepartureHeading.fromJson(resultString['result']);
  }

  /// Departure heading and accuracy for route calculation.
  ///
  /// Specifies the initial heading direction (in degrees) and accuracy when
  /// starting a route. When [DepartureHeading.heading] is -1, no departure
  /// heading constraint is applied.
  ///
  /// ## Parameters
  ///
  /// - [value]: The departure heading configuration.
  ///
  /// Default is `DepartureHeading(heading: -1, accuracy: -1)` (no constraint).
  set departureHeading(final DepartureHeading value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'departureheading',
      args: value.toJson(),
    );
  }

  /// Extra freedom levels for emergency vehicle routing constraints in a
  /// packed integer format.
  ///
  /// Only applies when [emergencyVehicleMode] is true.
  ///
  /// Default is `0`.
  int get emergencyVehicleExtraFreedomLevels {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getEmergencyVehicleMode',
    );
    return resultString['result']['extraFreedom'];
  }

  /// Extra freedom levels for emergency vehicle routing constraints in a
  /// packed integer format.
  ///
  /// Only applies when [emergencyVehicleMode] is true.
  ///
  /// ## Parameters
  ///
  /// - [value]: The extra freedom levels as a packed integer.
  ///
  /// Default is `0`.
  set emergencyVehicleExtraFreedomLevels(final int value) {
    final Map<String, dynamic> emergencyMode = <String, dynamic>{
      'enable': emergencyVehicleMode,
      'extraFreedom': value,
    };
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'emergencyVehicleMode',
      args: emergencyMode,
    );
  }

  /// Enables emergency vehicle routing mode with relaxed constraints.
  ///
  /// When true, enables access to emergency-dedicated road links and relaxes
  /// routing constraints.
  ///
  /// Default is `false`.
  bool get emergencyVehicleMode {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getEmergencyVehicleMode',
    );
    return resultString['result']['enable'];
  }

  /// Enables emergency vehicle routing mode with relaxed constraints.
  ///
  /// When true, enables access to emergency-dedicated road links and relaxes
  /// routing constraints.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to enable emergency vehicle mode, false to disable.
  ///
  /// Default is `false`.
  set emergencyVehicleMode(final bool value) {
    final Map<String, dynamic> emergencyMode = <String, dynamic>{
      'enable': value,
      'extraFreedom': emergencyVehicleExtraFreedomLevels,
    };
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'emergencyVehicleMode',
      args: emergencyMode,
    );
  }

  /// Ignores map restrictions during route-over-track calculations.
  ///
  /// When true, map-based routing restrictions (turn restrictions, access
  /// restrictions) are ignored when using track-based routing with path
  /// landmarks.
  ///
  /// Default is `false`.
  bool get ignoreRestrictionsOverTrack {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getIgnoreRestrictionsOverTrack',
    );
    return resultString['result'];
  }

  /// Ignores map restrictions during route-over-track calculations.
  ///
  /// When true, map-based routing restrictions (turn restrictions, access
  /// restrictions) are ignored when using track-based routing with path
  /// landmarks.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to ignore restrictions, false to apply them.
  ///
  /// Default is `false`.
  set ignoreRestrictionsOverTrack(final bool value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'ignorerestrictionsovertrack',
      args: value,
    );
  }

  /// Enables maximum distance constraints based on transport mode.
  ///
  /// When true, the routing service applies transport-mode-specific maximum
  /// distance limits. The actual limit depends on the selected transport mode
  /// and result detail level.
  ///
  /// Default is `true`.
  bool get maximumDistanceConstraint {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getMaximumDistanceConstraint',
    );
    return resultString['result'] == 1;
  }

  /// Enables maximum distance constraints based on transport mode.
  ///
  /// When true, the routing service applies transport-mode-specific maximum
  /// distance limits. The actual limit depends on the selected transport mode
  /// and result detail level.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to enable distance constraints, false to disable.
  ///
  /// Default is `true`.
  set maximumDistanceConstraint(final bool value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'maximumdistanceconstraint',
      args: value ? 1 : 0,
    );
  }

  /// Maximum transfer time between public transport connections, in minutes.
  ///
  /// For public transport routes, specifies the maximum allowed time between
  /// the arrival of one transport and the departure of the next. Only applies
  /// to [RouteTransportMode.public].
  ///
  /// Default is `300` (5 hours).
  int get maximumTransferTimeInMinutes {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getMaximumTransferTimeInMinutes',
    );
    return resultString['result'];
  }

  /// Maximum transfer time between public transport connections, in minutes.
  ///
  /// For public transport routes, specifies the maximum allowed time between
  /// the arrival of one transport and the departure of the next. Only applies
  /// to [RouteTransportMode.public].
  ///
  /// ## Parameters
  ///
  /// - [value]: Maximum transfer time in minutes.
  ///
  /// Default is `300` (5 hours).
  set maximumTransferTimeInMinutes(final int value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'maximumtransfertimeInminutes',
      args: value,
    );
  }

  /// Maximum walking distance for public transport routes, in meters.
  ///
  /// For public transport routes, specifies the maximum distance a user is
  /// willing to walk between transit stops or to reach the final destination.
  /// Only applies to [RouteTransportMode.public].
  ///
  /// Default is `5000` meters (5 km).
  int get maximumWalkDistance {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getMaximumWalkDistance',
    );
    return resultString['result'];
  }

  /// Maximum walking distance for public transport routes, in meters.
  ///
  /// For public transport routes, specifies the maximum distance a user is
  /// willing to walk between transit stops or to reach the final destination.
  /// Only applies to [RouteTransportMode.public].
  ///
  /// ## Parameters
  ///
  /// - [value]: Maximum walking distance in meters.
  ///
  /// Default is `5000` meters (5 km).
  set maximumWalkDistance(final int value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'maximumwalkdistance',
      args: value,
    );
  }

  /// Minimum transfer time between public transport connections, in minutes.
  ///
  /// For public transport routes, specifies the minimum required time between
  /// the arrival of one transport and the departure of the next to ensure
  /// feasible transfers. Only applies to [RouteTransportMode.public].
  ///
  /// Default is `1` minute.
  int get minimumTransferTimeInMinutes {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getMinimumTransferTimeInMinutes',
    );
    return resultString['result'];
  }

  /// Minimum transfer time between public transport connections, in minutes.
  ///
  /// For public transport routes, specifies the minimum required time between
  /// the arrival of one transport and the departure of the next to ensure
  /// feasible transfers. Only applies to [RouteTransportMode.public].
  ///
  /// ## Parameters
  ///
  /// - [value]: Minimum transfer time in minutes.
  ///
  /// Default is `1` minute.
  set minimumTransferTimeInMinutes(final int value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'minimumtransfertimeInminutes',
      args: value,
    );
  }

  /// Path calculation algorithm to use for routing.
  ///
  /// Selects the core routing algorithm. Different algorithms may provide
  /// different trade-offs between calculation speed and route optimality.
  ///
  /// Default is [RoutePathAlgorithm.ml].
  RoutePathAlgorithm get pathAlgorithm {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getPathAlgorithm',
    );
    return RoutePathAlgorithmExtension.fromId(resultString['result']);
  }

  /// Path calculation algorithm to use for routing.
  ///
  /// Selects the core routing algorithm. Different algorithms may provide
  /// different trade-offs between calculation speed and route optimality.
  ///
  /// ## Parameters
  ///
  /// - [value]: The path algorithm to use.
  ///
  /// Default is [RoutePathAlgorithm.ml].
  set pathAlgorithm(final RoutePathAlgorithm value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'pathalgorithm',
      args: value.id,
    );
  }

  /// Flavor variant of the selected path algorithm.
  ///
  /// Specifies the algorithmic flavor or variant to use with the selected
  /// [pathAlgorithm]. Different flavors may optimize differently.
  ///
  /// Default is [RoutePathAlgorithmFlavor.magicLane].
  RoutePathAlgorithmFlavor get pathAlgorithmFlavor {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getPathAlgorithmFlavor',
    );
    return RoutePathAlgorithmFlavorExtension.fromId(resultString['result']);
  }

  /// Flavor variant of the selected path algorithm.
  ///
  /// Specifies the algorithmic flavor or variant to use with the selected
  /// [pathAlgorithm]. Different flavors may optimize differently.
  ///
  /// ## Parameters
  ///
  /// - [value]: The algorithm flavor to use.
  ///
  /// Default is [RoutePathAlgorithmFlavor.magicLane].
  set pathAlgorithmFlavor(final RoutePathAlgorithmFlavor value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'pathalgorithmflavor',
      args: value.id,
    );
  }

  /// Pedestrian routing profile for walking and wheelchair accessibility.
  ///
  /// Selects pedestrian-specific routing behavior. Options include standard
  /// walking or hiking. Only used when
  /// [transportMode] is [RouteTransportMode.pedestrian].
  ///
  /// Default is [PedestrianProfile.walk].
  PedestrianProfile get pedestrianProfile {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getPedestrianProfile',
    );
    return PedestrianProfileExtension.fromId(resultString['result']);
  }

  /// Pedestrian routing profile for walking and wheelchair accessibility.
  ///
  /// Selects pedestrian-specific routing behavior. Options include standard
  /// walking or hiking. Only used when
  /// [transportMode] is [RouteTransportMode.pedestrian].
  ///
  /// ## Parameters
  ///
  /// - [value]: The pedestrian profile to use.
  ///
  /// Default is [PedestrianProfile.walk].
  set pedestrianProfile(final PedestrianProfile value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'pedestrianprofile',
      args: value.id,
    );
  }

  /// Level of detail to include in route calculation results.
  ///
  /// Controls how much information is included in the computed route. Higher
  /// detail levels include more information but may increase calculation time and
  /// data size.
  ///
  /// Default is [RouteResultDetails.full].
  RouteResultDetails get resultDetails {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getResultDetails',
    );
    return RouteResultDetailsExtension.fromId(resultString['result']);
  }

  /// Level of detail to include in route calculation results.
  ///
  /// Controls how much information is included in the computed route. Higher
  /// detail levels include more information but may increase calculation time and
  /// data size.
  ///
  /// ## Parameters
  ///
  /// - [value]: The level of detail to include in results.
  ///
  /// Default is [RouteResultDetails.full].
  set resultDetails(final RouteResultDetails value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'resultdetails',
      args: value.id,
    );
  }

  /// Route group IDs for earlier/later trip calculations in public transport.
  ///
  /// Default is an empty list.
  List<int> get routeGroupIdsEarlierLater {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getRouteGroupIdsEarlierLater',
    );
    return (resultString['result'] as List<dynamic>)
        .map((final dynamic item) => item as int)
        .toList();
  }

  /// Route group IDs for earlier/later trip calculations in public transport.
  ///
  /// ## Parameters
  ///
  /// - [value]: List of route group IDs.
  ///
  /// Default is an empty list.
  set routeGroupIdsEarlierLater(final List<int> value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'routegroupidsearlierlater',
      args: value,
    );
  }

  /// Route range values for isoline/isochrone calculations.
  ///
  /// Specifies range limits for computing reachable areas. Units depend on
  /// the [routeType]:
  ///   - seconds for [RouteType.fastest]
  ///   - meters for [RouteType.shortest]
  ///   - watt-hours for [RouteType.economic].
  ///
  /// Default is an empty list (no range calculation).
  ///
  /// ## Also see:
  ///
  /// - [RouteType] - Defines the type of route which affects the unit of route ranges.
  /// - [RouteResultType] - Indicates if the result is a path or range.
  /// - [RouteBase.preferences] - Contains the preferences used for route calculation.
  /// - [routeRangesQuality] - Controls the quality of route range calculations.
  List<int> get routeRanges {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getRouteRanges',
    );
    return (resultString['result']['list'] as List<dynamic>)
        .map((final dynamic item) => item as int)
        .toList();
  }

  /// Route range values for isoline/isochrone calculations.
  ///
  /// Specifies range limits for computing reachable areas. Units depend on
  /// the [routeType]:
  ///   - seconds for [RouteType.fastest]
  ///   - meters for [RouteType.shortest]
  ///   - watt-hours for [RouteType.economic].
  ///
  /// ## Parameters
  ///
  /// - [value]: List of range values in units based on route type.
  ///
  /// Default is an empty list (no range calculation).
  ///
  /// ## Also see:
  ///
  /// - [RouteType] - Defines the type of route which affects the unit of route ranges.
  /// - [RouteResultType] - Indicates if the result is a path or range.
  /// - [RouteBase.preferences] - Contains the preferences used for route calculation.
  /// - [routeRangesQuality] - Controls the quality of route range calculations.
  set routeRanges(final List<int> value) {
    final Map<String, dynamic> rangeQuality = <String, dynamic>{
      'list': value,
      'quality': routeRangesQuality,
    };
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'routeranges',
      args: rangeQuality,
    );
  }

  /// Quality level for route range calculations, from 0 to 100.
  ///
  /// Controls the accuracy vs. performance trade-off for route range
  /// (isoline/isochrone) calculations. 0 is lowest quality (fastest), 100 is
  /// highest quality (most accurate).
  ///
  /// Default is `100` (maximum quality).
  ///
  /// ## Also see:
  ///
  /// - [RouteType] - Defines the type of route which affects the unit of route ranges.
  /// - [RouteResultType] - Indicates if the result is a path or range.
  /// - [RouteBase.preferences] - Contains the preferences used for route calculation.
  /// - [routeRanges] - List of route ranges thresholds used when generating route ranges.
  int get routeRangesQuality {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getRouteRanges',
    );
    return resultString['result']['quality'];
  }

  /// Quality level for route range calculations, from 0 to 100.
  ///
  /// Controls the accuracy vs. performance trade-off for route range
  /// (isoline/isochrone) calculations. 0 is lowest quality (fastest), 100 is
  /// highest quality (most accurate).
  ///
  /// ## Parameters
  ///
  /// - [value]: Quality level from 0 to 100.
  ///
  /// Default is `100` (maximum quality).
  ///
  /// ## Also see:
  ///
  /// - [RouteType] - Defines the type of route which affects the unit of route ranges.
  /// - [RouteResultType] - Indicates if the result is a path or range.
  /// - [RouteBase.preferences] - Contains the preferences used for route calculation.
  /// - [routeRanges] - List of route ranges thresholds used when generating route ranges.
  set routeRangesQuality(final int value) {
    final Map<String, dynamic> rangeQuality = <String, dynamic>{
      'list': routeRanges,
      'quality': value,
    };
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'routeranges',
      args: rangeQuality,
    );
  }

  /// Route result type indicating the format of the returned route.
  ///
  /// This value is not used during route calculation but is included in the
  /// result via [RouteBase.preferences] to indicate how the route was computed.
  ///
  /// Default is [RouteResultType.path].
  RouteResultType get routeResultType {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getRouteResultType',
    );
    return RouteResultTypeExtension.fromId(resultString['result']);
  }

  /// Primary route optimization criterion.
  ///
  /// Selects whether routes are optimized for fastest time, shortest distance,
  /// or most economic (fuel/energy efficient) path.
  ///
  /// Default is [RouteType.fastest].
  RouteType get routeType {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getRouteType',
    );
    return RouteTypeExtension.fromId(resultString['result']);
  }

  /// Primary route optimization criterion.
  ///
  /// Selects whether routes are optimized for fastest time, shortest distance,
  /// or most economic (fuel/energy efficient) path.
  ///
  /// ## Parameters
  ///
  /// - [value]: The route optimization type to use.
  ///
  /// Default is [RouteType.fastest].
  set routeType(final RouteType value) {
    objectMethod(pointerId, 'RoutePrefWrapper', 'routetype', args: value.id);
  }

  /// Additional route type preference flags.
  ///
  /// A set of optional routing preferences that can be combined to further
  /// customize route calculation when using public transport.
  /// Only applies to [RouteTransportMode.public].
  ///
  /// Default is `{RouteTypePreferences.none}`.
  Set<RouteTypePreferences> get routeTypePreferences {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getRouteTypePreferences',
    );
    final int routeTypePreferencesInt = resultString['result'];
    final Set<RouteTypePreferences> prefs = <RouteTypePreferences>{};
    for (final RouteTypePreferences value in RouteTypePreferences.values) {
      if (routeTypePreferencesInt & value.id != 0) {
        prefs.add(value);
      }
    }
    if (prefs.isEmpty) {
      prefs.add(RouteTypePreferences.none);
    }
    return prefs;
  }

  /// Additional route type preference flags.
  ///
  /// A set of optional routing preferences that can be combined to further
  /// customize route calculation when using public transport.
  /// Only applies to [RouteTransportMode.public].
  ///
  /// ## Parameters
  ///
  /// - [value]: Set of route type preferences to apply.
  ///
  /// Default is `{RouteTypePreferences.none}`.
  set routeTypePreferences(final Set<RouteTypePreferences> value) {
    final int bitmask = value.fold(
      0,
      (final int res, final RouteTypePreferences item) => res | item.id,
    );
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'routetypepreferences',
      args: bitmask,
    );
  }

  /// Public transport route sorting strategy.
  ///
  /// Determines how public transport routes are sorted when multiple options
  /// are available. Options include best time, fewest transfers, or shortest
  /// walking distance. Only applies to [RouteTransportMode.public].
  ///
  /// Default is [PTSortingStrategy.bestTime].
  PTSortingStrategy get sortingStrategy {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getSortingStrategy',
    );
    return PTSortingStrategyExtension.fromId(resultString['result']);
  }

  /// Public transport route sorting strategy.
  ///
  /// Determines how public transport routes are sorted when multiple options
  /// are available. Options include best time, fewest transfers, or shortest
  /// walking distance. Only applies to [RouteTransportMode.public].
  ///
  /// ## Parameters
  ///
  /// - [value]: The sorting strategy to use.
  ///
  /// Default is [PTSortingStrategy.bestTime].
  set sortingStrategy(final PTSortingStrategy value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'sortingstrategy',
      args: value.id,
    );
  }

  /// Local departure or arrival time for public transport routing.
  ///
  /// A UTC [DateTime] object containing the local time at the route location.
  /// When null, the current time is used. The [algorithmType] determines
  /// interpretation: if [PTAlgorithmType.departure], this is the desired
  /// departure time; if [PTAlgorithmType.arrival], this is the desired arrival
  /// time. Only applies to [RouteTransportMode.public].
  ///
  /// The local time is a UTC [DateTime] object but containing the local time at
  /// the location. Use [TimezoneService.getTimezoneInfoFromCoordinates] to compute the
  /// correctly formatted timestamp for a specific location and time.
  ///
  /// Default is `null` (current time).
  DateTime? get timestamp {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'isAutomaticTimestamp',
    );
    if (resultString['result']) {
      return null;
    }
    final OperationResult timestampResult = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getTimestamp',
    );
    return DateTime.fromMillisecondsSinceEpoch(
      timestampResult['result'],
      isUtc: true,
    );
  }

  /// Local departure or arrival time for public transport routing.
  ///
  /// A UTC [DateTime] object containing the local time at the route location.
  /// When null, the current time is used. The [algorithmType] determines
  /// interpretation: if [PTAlgorithmType.departure], this is the desired
  /// departure time; if [PTAlgorithmType.arrival], this is the desired arrival
  /// time. Only applies to [RouteTransportMode.public].
  ///
  /// The local time is a UTC [DateTime] object but containing the local time at
  /// the location. Use [TimezoneService.getTimezoneInfoFromCoordinates] to compute the
  /// correctly formatted timestamp for a specific location and time.
  ///
  /// ## Parameters
  ///
  /// - [value]: The timestamp to use, or null for current time.
  ///
  /// Default is `null` (current time).
  set timestamp(final DateTime? value) {
    if (value == null) {
      objectMethod(
        pointerId,
        'RoutePrefWrapper',
        'automatictimestamp',
        args: true,
      );
    } else {
      objectMethod(
        pointerId,
        'RoutePrefWrapper',
        'automatictimestamp',
        args: false,
      );
      objectMethod(
        pointerId,
        'RoutePrefWrapper',
        'timestamp',
        args: value.millisecondsSinceEpoch,
      );
    }
  }

  /// Primary transport mode for route calculation.
  ///
  /// Determines the vehicle or movement type used for routing. Options include
  /// car, truck/lorry, bicycle, pedestrian, public transport, and shared
  /// vehicles. Each mode uses different road networks and constraints.
  ///
  /// Default is [RouteTransportMode.car].
  RouteTransportMode get transportMode {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getTransportMode',
    );
    return RouteTransportModeExtension.fromId(resultString['result']);
  }

  /// Primary transport mode for route calculation.
  ///
  /// Determines the vehicle or movement type used for routing. Options include
  /// car, truck/lorry, bicycle, pedestrian, public transport, and shared
  /// vehicles. Each mode uses different road networks and constraints.
  ///
  /// ## Parameters
  ///
  /// - [value]: The transport mode to use for routing.
  ///
  /// Default is [RouteTransportMode.car].
  set transportMode(final RouteTransportMode value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'transportmode',
      args: value.id,
    );
  }

  /// Truck routing profile with vehicle-specific constraints.
  ///
  /// Configure truck-specific routing preferences including dimensions (height,
  /// length, width), axle load, mass, max speed, fuel type, and plate number.
  /// Only used when [transportMode] is [RouteTransportMode.lorry].
  ///
  /// For caravan/trailer routing, use [transportMode] = [RouteTransportMode.car]
  /// with a [truckProfile] to apply size constraints while avoiding
  /// truck-specific road restrictions.
  ///
  /// Default is `null` (no truck profile).
  TruckProfile get truckProfile {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getTruckProfile',
    );
    return TruckProfile.fromJson(resultString['result']);
  }

  /// Truck routing profile with vehicle-specific constraints.
  ///
  /// Configure truck-specific routing preferences including dimensions (height,
  /// length, width), axle load, mass, max speed, fuel type, and plate number.
  /// Only used when [transportMode] is [RouteTransportMode.lorry].
  ///
  /// For caravan/trailer routing, use [transportMode] = [RouteTransportMode.car]
  /// with a [truckProfile] to apply size constraints while avoiding
  /// truck-specific road restrictions.
  ///
  /// ## Parameters
  ///
  /// - [value]: The truck profile configuration to use.
  ///
  /// Default is `null` (no truck profile).
  set truckProfile(final TruckProfile value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'truckprofile',
      args: value.toJson(),
    );
  }

  /// Ensures bike accessibility for public transport routes.
  ///
  /// When true, routes are computed to be bike-friendly. Only applies to
  /// [RouteTransportMode.public].
  ///
  /// Default is `false`.
  bool get useBikes {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getUseBikes',
    );
    return resultString['result'];
  }

  /// Ensures bike accessibility for public transport routes.
  ///
  /// When true, routes are computed to be bike-friendly. Only applies to
  /// [RouteTransportMode.public].
  ///
  /// ## Parameters
  ///
  /// - [value]: True to ensure bike accessibility, false otherwise.
  ///
  /// Default is `false`.
  set useBikes(final bool value) {
    objectMethod(pointerId, 'RoutePrefWrapper', 'usebikes', args: value);
  }

  /// Ensures wheelchair accessibility for public transport routes.
  ///
  /// When true, routes are computed to be wheelchair-accessible. Only applies to
  /// [RouteTransportMode.public].
  ///
  /// Default is `false`.
  bool get useWheelchair {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getUseWheelchair',
    );
    return resultString['result'];
  }

  /// Ensures wheelchair accessibility for public transport routes.
  ///
  /// When true, routes are computed to be wheelchair-accessible. Only applies to
  /// [RouteTransportMode.public].
  ///
  /// ## Parameters
  ///
  /// - [value]: True to ensure wheelchair accessibility, false otherwise.
  ///
  /// Default is `false`.
  set useWheelchair(final bool value) {
    objectMethod(pointerId, 'RoutePrefWrapper', 'usewheelchair', args: value);
  }

  /// Get the immutable roadblock avoidance state
  /// If set, the algorithm rather fails than routing through roadblocks.
  ///
  /// Default is `false`.
  bool get immutableRoadblockAvoidance {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getImmutableRoadblockAvoidance',
    );
    return resultString['result'];
  }

  /// Get the immutable roadblock avoidance state
  /// If set, the algorithm rather fails than routing through roadblocks.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to enable immutable roadblock avoidance, false otherwise.
  ///
  /// Default is `false`.
  set immutableRoadblockAvoidance(final bool value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'immutableRoadblockAvoidance',
      args: value,
    );
  }

  /// Set the accurate waypoints approach.
  /// An accurate approach implies that the route arrives at the waypoint on the drive side of the region
  ///
  /// ## Parameters
  ///
  /// - [value]: True to enable accurate waypoints approach, false otherwise.
  @experimental
  set accurateWaypointsApproach(final bool value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'accurateWaypointsApproach',
      args: value,
    );
  }

  /// Get accurate waypoints approach.
  /// An accurate approach implies that the route arrives at the waypoint on the drive side of the region.
  ///
  /// Default is `false`.
  bool get accurateWaypointsApproach {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getAccurateWaypointsApproach',
    );
    return resultString['result'];
  }

  /// Track resume mode for path-based routing with track landmarks.
  ///
  /// When true, routing uses the track from the closest coordinate to the last
  /// waypoint. When false, the entire track is used from the first to the last
  /// coordinate. At least one waypoint before the track waypoint is required to
  /// determine the closest track position.
  ///
  /// Default is `true`.
  bool get isTrackResume {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getTrackResume',
    );
    return resultString['result'];
  }

  /// Track resume mode for path-based routing with track landmarks.
  ///
  /// When true, routing uses the track from the closest coordinate to the last
  /// waypoint. When false, the entire track is used from the first to the last
  /// coordinate. At least one waypoint before the track waypoint is required to
  /// determine the closest track position.
  ///
  /// ## Parameters
  ///
  /// - [value]: True to resume from closest point, false to use entire track.
  ///
  /// Default is `true`.
  set isTrackResume(final bool value) {
    objectMethod(pointerId, 'RoutePrefWrapper', 'trackresume', args: value);
  }

  /// Set parameters for roundtrip feature.
  ///
  /// ## Parameters
  ///
  /// - [value]: The roundtrip parameters configuration.
  set roundTripParameters(final RoundTripParameters value) {
    objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'setRoundtripParameters',
      args: value.toJson(),
    );
  }

  /// Get roundtrip range (see [roundTripParameters] for explanation of how the units work).
  @experimental
  int get roundTripRange {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getRoundtripRange',
    );
    return resultString['result'];
  }

  /// Get roundtrip range type.
  @experimental
  RangeType get roundTripRangeType {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getRoundtripRangeType',
    );
    return RangeTypeExtension.fromId(resultString['result']);
  }

  /// Get roundtrip random seed.
  int get roundTripRandomSeed {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RoutePrefWrapper',
      'getRoundtripRandomSeed',
    );
    return resultString['result'];
  }

  /// Returns the vehicle registration profile for the current transport mode.
  ///
  /// Extracts the relevant vehicle profile ([CarProfile], [TruckProfile], or
  /// [ElectricBikeProfile]) based on the selected [transportMode]. Returns null
  /// for pedestrian, public, and shared vehicle modes or when no profile is
  /// configured.
  VehicleRegistration? get vehicleRegistration {
    switch (transportMode) {
      case RouteTransportMode.car:
        return carProfile;
      case RouteTransportMode.lorry:
        return truckProfile;
      case RouteTransportMode.bicycle:
        final ElectricBikeType ebikeType =
            bikeProfile.eProfile?.type ?? ElectricBikeType.none;
        if (ebikeType != ElectricBikeType.none) {
          return bikeProfile.eProfile;
        }
        return null;
      case RouteTransportMode.pedestrian:
        return null;
      case RouteTransportMode.public:
        return null;
      case RouteTransportMode.sharedVehicles:
        return null;
    }
  }

  static RoutePreferences _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'RoutePrefWrapper'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return RoutePreferences.init(decodedVal['result']);
  }
}
