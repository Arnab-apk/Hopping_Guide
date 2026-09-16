// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Vehicle registration information.
///
/// Base class that holds vehicle registration details used by routing and
/// transport-related preferences. Subclasses such as [MotorVehicleProfile]
/// and [ElectricBikeProfile] extend this to provide additional routing
/// parameters.
///
/// ## See also:
///
/// - [MotorVehicleProfile] - Adds motor-vehicle specific routing fields.
/// - [ElectricBikeProfile] - Electric bike routing profile with energy settings.
///
/// {@category Routing}
class VehicleRegistration {
  /// Creates a registration record containing the vehicle's plate number.
  ///
  /// ## Parameters
  ///
  /// - [plateNumber] - The vehicle's registration plate number.
  VehicleRegistration({required this.plateNumber});

  /// Vehicle plate number.
  String plateNumber;

  @override
  bool operator ==(covariant final VehicleRegistration other) {
    if (identical(this, other)) {
      return true;
    }

    return other.plateNumber == plateNumber;
  }

  @override
  int get hashCode {
    return plateNumber.hashCode;
  }
}

/// Motor vehicle profile.
///
/// Base class for motorized vehicle profiles such as [CarProfile] and
/// [TruckProfile]. Provides common routing parameters used by the routing
/// engine (mass, maximum speed and fuel type).
///
/// ## See also:
///
/// - [CarProfile] - Profile used for car routing.
/// - [TruckProfile] - Profile used for truck/lorry routing.
///
/// {@category Routing}
class MotorVehicleProfile extends VehicleRegistration {
  /// Creates a motor vehicle profile with sensible defaults.
  ///
  /// ## Parameters
  ///
  /// - [mass] - Vehicle mass in kilograms (default 0).
  /// - [maxSpeed] - Maximum vehicle speed in m/s (default 0).
  /// - [fuel] - Engine [FuelType] (default [FuelType.petrol]).
  /// - [plateNumber] - Registration plate number (default empty).
  MotorVehicleProfile({
    this.mass = 0,
    this.maxSpeed = 0,
    this.fuel = FuelType.petrol,
    super.plateNumber = '',
  });

  /// Vehicle mass in kg. By default it is 0 and is not considered in routing.
  int mass;

  /// Vehicle maximum speed in m/s. By default it is 0 and is not considered in routing.
  double maxSpeed;

  /// Engine fuel type. Default is [FuelType.petrol].
  FuelType fuel;
}

/// Truck routing profile.
///
/// Profile used for truck/lorry routing that includes vehicle dimensions and
/// axle/load constraints. These parameters are considered by the routing engine
/// when calculating truck-compatible routes (bridges, height/weight limits,
/// etc.).
///
/// Make sure to specify accurate values for the truck dimensions as they
/// are measured in centimetres.
///
/// ## See also:
///
/// - [RoutePreferences] - Attach a [TruckProfile] when requesting truck routes.
///
/// {@category Routing}
/// {@category Snapshot Types}
class TruckProfile extends MotorVehicleProfile {
  /// Truck profile constructor with default diesel fuel type.
  ///
  /// ## Parameters
  ///
  /// - [height] - Truck height in centimetres (default 0).
  /// - [length] - Truck length in centimetres (default 0).
  /// - [width] - Truck width in centimetres (default 0).
  /// - [axleLoad] - Axle load in kilograms (default 0).
  /// - [maxSpeed] - Maximum speed in m/s (default 0).
  /// - [mass] - Vehicle mass in kilograms (default 0).
  /// - [fuel] - Engine [FuelType] (default [FuelType.diesel]).
  /// - [plateNumber] - Registration plate number (inherited).
  TruckProfile({
    this.height = 0,
    this.length = 0,
    this.width = 0,
    this.axleLoad = 0,
    super.maxSpeed = 0,
    super.mass = 0,
    super.fuel = FuelType.diesel,
    super.plateNumber = '',
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory TruckProfile.fromJson(final Map<String, dynamic> json) {
    return TruckProfile(
      mass: json['mass'],
      height: json['height'],
      length: json['length'],
      width: json['width'],
      axleLoad: json['axleLoad'],
      maxSpeed: json['maxSpeed'],
      fuel: FuelTypeExtension.fromId(json['fuel']),
      plateNumber: json['plateNumber'],
    );
  }

  /// Truck height in cm. By default it is 0 and is not considered in routing.
  int height;

  /// Truck length in cm. By default it is 0 and is not considered in routing.
  int length;

  /// Truck width in cm. By default it is 0 and is not considered in routing.
  int width;

  /// Truck axle load in kg. By default it is 0 and is not considered in routing.
  int axleLoad;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['mass'] = mass;
    json['height'] = height;
    json['length'] = length;
    json['width'] = width;
    json['axleLoad'] = axleLoad;
    json['maxSpeed'] = maxSpeed;
    json['fuel'] = fuel.id;
    json['plateNumber'] = plateNumber;
    return json;
  }

  @override
  bool operator ==(covariant final TruckProfile other) {
    if (identical(this, other)) {
      return true;
    }
    return mass == other.mass &&
        height == other.height &&
        length == other.length &&
        width == other.width &&
        axleLoad == other.axleLoad &&
        maxSpeed == other.maxSpeed &&
        fuel == other.fuel &&
        plateNumber == other.plateNumber;
  }

  @override
  int get hashCode {
    return Object.hash(
      mass,
      height,
      length,
      width,
      axleLoad,
      maxSpeed,
      fuel,
      plateNumber,
    );
  }
}

/// Car routing profile.
///
/// Profile used for car routing. Extends [MotorVehicleProfile] and exposes
/// parameters relevant when computing car routes.
///
/// ## See also:
///
/// - [RoutePreferences] - Include a [CarProfile] when requesting car routes.
///
/// {@category Routing}
/// {@category Snapshot Types}
class CarProfile extends MotorVehicleProfile {
  /// Car profile constructor with predefined [FuelType.petrol] as fuel type.
  ///
  /// ## Parameters
  ///
  /// - [mass] - Mass in kg (default 0).
  /// - [fuel] - Engine [FuelType] (default [FuelType.petrol]).
  /// - [maxSpeed] - Max speed in m/s (default 0.0).
  /// - [plateNumber] - Registration plate number (inherited).
  CarProfile({
    super.mass = 0,
    super.fuel = FuelType.petrol,
    super.maxSpeed = 0.0,
    super.plateNumber = '',
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory CarProfile.fromJson(final Map<String, dynamic> json) {
    return CarProfile(
      mass: json['mass'],
      fuel: FuelTypeExtension.fromId(json['fuel']),
      maxSpeed: json['maxSpeed'],
      plateNumber: json['plateNumber'],
    );
  }

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['mass'] = mass;
    json['fuel'] = fuel.id;
    json['maxSpeed'] = maxSpeed;
    json['plateNumber'] = plateNumber;
    return json;
  }

  @override
  bool operator ==(covariant final CarProfile other) {
    if (identical(this, other)) {
      return true;
    }

    return other.mass == mass &&
        other.fuel == fuel &&
        other.maxSpeed == maxSpeed &&
        other.plateNumber == plateNumber;
  }

  @override
  int get hashCode {
    return mass.hashCode ^
        fuel.hashCode ^
        maxSpeed.hashCode ^
        plateNumber.hashCode;
  }
}

/// Electric bike profile containing e-bike configuration and rider/vehicle parameters.
///
/// Holds electric bike specific routing parameters used by the routing engine
/// to estimate energy consumption, apply legal constraints, and tune route
/// generation for e-bike capabilities.
///
/// ## See also:
///
/// - [BikeProfileElectricBikeProfile] - Container for selecting bike/e-bike profiles.
/// - [RoutePreferences] - Attach an [ElectricBikeProfile] when requesting bicycle routes.
///
/// {@category Routing}
/// {@category Snapshot Types}
class ElectricBikeProfile extends VehicleRegistration {
  /// Creates an [ElectricBikeProfile] with optional values.
  ///
  /// Constructs an instance with sensible defaults if specific values are not
  /// provided. The defaults model a typical pedelec with no masses or
  /// auxiliary consumption specified.
  ///
  /// ## Parameters
  ///
  /// - [type] - The e-bike drivetrain type. Defaults to [ElectricBikeType.pedelec].
  /// - [bikeMass] - The bike mass in kilograms. If 0, a default internal value may be used.
  /// - [bikerMass] - The rider mass in kilograms. If 0, a default internal value may be used.
  /// - [auxConsumptionDay] - Auxiliary power consumption during daytime in Watts. If 0, a default internal value may be used.
  /// - [auxConsumptionNight] - Auxiliary power consumption during nighttime in Watts. If 0, a default internal value may be used.
  /// - [ignoreLegalRestrictions] - When true, country-based legal restrictions related to e-bikes are ignored in routing.
  /// - [plateNumber] - Vehicle plate number (inherited from [VehicleRegistration]).
  ElectricBikeProfile({
    this.type = ElectricBikeType.pedelec,
    this.bikeMass = 0.0,
    this.bikerMass = 0.0,
    this.auxConsumptionDay = 0.0,
    this.auxConsumptionNight = 0.0,
    this.ignoreLegalRestrictions = false,
    super.plateNumber = '',
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory ElectricBikeProfile.fromJson(final Map<String, dynamic> json) {
    return ElectricBikeProfile(
      type: ElectricBikeTypeExtension.fromId(json['type']),
      bikeMass: json['bikeMass'],
      bikerMass: json['bikerMass'],
      auxConsumptionDay: json['auxConsumptionDay'],
      auxConsumptionNight: json['auxConsumptionNight'],
      ignoreLegalRestrictions: json['ignoreLegalRestrictions'],
      plateNumber: json['plateNumber'],
    );
  }

  /// Ebike drivetrain type. Default is [ElectricBikeType.pedelec].
  ElectricBikeType type;

  /// Bike mass in kilograms.
  ///
  /// If zero, a default internal value may be applied by routing logic.
  double bikeMass;

  /// Rider (biker) mass in kilograms.
  ///
  /// If zero, a default internal value may be applied by routing logic.
  double bikerMass;

  /// Auxiliary power consumption during day in Watts.
  ///
  /// If zero, a default internal value may be applied by routing logic.
  double auxConsumptionDay;

  /// Auxiliary power consumption during night in Watts.
  ///
  /// If zero, a default internal value may be applied by routing logic.
  double auxConsumptionNight;

  /// Ignore country-based legal restrictions related to e-bikes.
  ///
  /// When true, routing will not apply jurisdiction-specific constraints for e-bike classification.
  bool ignoreLegalRestrictions;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['type'] = type.id;
    json['bikeMass'] = bikeMass;
    json['bikerMass'] = bikerMass;
    json['auxConsumptionDay'] = auxConsumptionDay;
    json['auxConsumptionNight'] = auxConsumptionNight;
    json['ignoreLegalRestrictions'] = ignoreLegalRestrictions;
    json['plateNumber'] = plateNumber;
    return json;
  }

  @override
  bool operator ==(covariant final ElectricBikeProfile other) {
    if (identical(this, other)) {
      return true;
    }

    return other.type == type &&
        other.bikeMass == bikeMass &&
        other.bikerMass == bikerMass &&
        other.auxConsumptionDay == auxConsumptionDay &&
        other.auxConsumptionNight == auxConsumptionNight &&
        other.ignoreLegalRestrictions == ignoreLegalRestrictions &&
        other.plateNumber == plateNumber;
  }

  @override
  int get hashCode {
    return Object.hash(
      type,
      bikeMass,
      bikerMass,
      auxConsumptionDay,
      auxConsumptionNight,
      ignoreLegalRestrictions,
      plateNumber,
    );
  }
}

/// Bike and electric bike routing profile.
///
/// Container used to select a standard bike profile or an electric-bike
/// profile for routing. The [profile] field selects the general cycling
/// behaviour (city, road, etc.) while [eProfile] holds optional
/// electric-specific parameters.
///
/// {@category Routing}
/// {@category Snapshot Types}
class BikeProfileElectricBikeProfile {
  /// Creates a container for bike/e-bike profile selection.
  ///
  /// ## Parameters
  ///
  /// - [profile] - Selected bike profile (default [BikeProfile.city]).
  /// - [eProfile] - Optional [ElectricBikeProfile] when using an e-bike.
  BikeProfileElectricBikeProfile({
    this.profile = BikeProfile.city,
    this.eProfile,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory BikeProfileElectricBikeProfile.fromJson(
    final Map<String, dynamic> json,
  ) {
    return BikeProfileElectricBikeProfile(
      profile: BikeProfileExtension.fromId(json['profile']),
      eProfile: json['eprofile'] is ElectricBikeProfile
          ? json['eprofile'] as ElectricBikeProfile
          : ElectricBikeProfile.fromJson(json['eprofile']),
    );
  }

  /// Selected bike profile. Default is [BikeProfile.city].
  BikeProfile profile;

  /// Selected e-bike profile.
  ElectricBikeProfile? eProfile;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['profile'] = profile.id;

    json['eprofile'] = eProfile ?? ElectricBikeProfile();
    return json;
  }

  @override
  bool operator ==(covariant final BikeProfileElectricBikeProfile other) {
    return other.profile == profile && other.eProfile == eProfile;
  }

  @override
  int get hashCode => profile.hashCode ^ eProfile.hashCode;
}

/// Fuel type for motorized vehicles.
///
/// Enumerates engine fuel types used by vehicle profiles.
///
/// {@category Routing}
enum FuelType {
  /// Petrol fuel type.
  petrol,

  /// Diesel fuel type.
  diesel,

  /// LPG (Liquid Petroleum Gas) fuel type.
  lpg,

  /// Electric fuel type.
  electric,
}

/// @nodoc
extension FuelTypeExtension on FuelType {
  int get id {
    switch (this) {
      case FuelType.petrol:
        return 0;
      case FuelType.diesel:
        return 1;
      case FuelType.lpg:
        return 2;
      case FuelType.electric:
        return 3;
    }
  }

  static FuelType fromId(final int id) {
    switch (id) {
      case 0:
        return FuelType.petrol;
      case 1:
        return FuelType.diesel;
      case 2:
        return FuelType.lpg;
      case 3:
        return FuelType.electric;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Electric bike drivetrain type.
///
/// Enumerates supported e-bike drivetrain classifications used in
/// [ElectricBikeProfile].
///
/// {@category Routing}
enum ElectricBikeType {
  /// No electric assistance.
  none,

  /// Pedelec (pedal-assist) type.
  pedelec,

  /// Power-on-demand electric assistance.
  powerOnDemand,
}

/// @nodoc
extension ElectricBikeTypeExtension on ElectricBikeType {
  int get id {
    switch (this) {
      case ElectricBikeType.none:
        return 0;
      case ElectricBikeType.pedelec:
        return 1;
      case ElectricBikeType.powerOnDemand:
        return 2;
    }
  }

  static ElectricBikeType fromId(final int id) {
    switch (id) {
      case 0:
        return ElectricBikeType.none;
      case 1:
        return ElectricBikeType.pedelec;
      case 2:
        return ElectricBikeType.powerOnDemand;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Bike profile selection used for bicycle routing.
///
/// Influences route generation to prefer roads/paths suitable for the chosen
/// cycling style.
///
/// {@category Routing}
enum BikeProfile {
  /// Road cycling profile.
  road,

  /// Cross-country cycling profile.
  cross,

  /// City cycling profile (default).
  city,

  /// Mountain biking profile.
  mountain,
}

/// @nodoc
extension BikeProfileExtension on BikeProfile {
  int get id {
    switch (this) {
      case BikeProfile.road:
        return 0;
      case BikeProfile.cross:
        return 1;
      case BikeProfile.city:
        return 2;
      case BikeProfile.mountain:
        return 3;
    }
  }

  static BikeProfile fromId(final int id) {
    switch (id) {
      case 0:
        return BikeProfile.road;
      case 1:
        return BikeProfile.cross;
      case 2:
        return BikeProfile.city;
      case 3:
        return BikeProfile.mountain;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
