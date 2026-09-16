// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Predefined generic category identifiers used to classify landmarks
///
/// This enum lists the built-in generic categories the SDK exposes. Each
/// enum value maps to an integer identifier (see [GenericCategoriesIdExtension.id])
/// which is used by APIs such as [GenericCategories.getCategory].
///
/// Custom [LandmarkCategory] instances may also be created with IDs differing from
/// those listed here to represent application-specific categories.
///
/// Each generic category represents a broad class of landmarks or points of interest (POIs)
/// which is further detailed by specific POI categories. Use the [GenericCategories.getPoiCategories]
/// method to retrieve the list of POI categories associated with a given generic category.
///
/// ## See also:
///
/// - [GenericCategories] — Utilities to enumerate and resolve generic categories.
/// - [GenericCategories.getCategory] — Retrieve the generic [LandmarkCategory] for a given
///   category id.
/// - [GenericCategories.getPoiCategories] — Retrieve the list of POI categories for a given
///  generic category.
///
/// {@category Landmarks}
enum GenericCategoriesId {
  /// Gas station category.
  gasStation,

  /// Parking category.
  parking,

  /// Food and drink category.
  foodAndDrink,

  /// Accommodation category.
  accommodation,

  /// Medical services category.
  medicalServices,

  /// Shopping category.
  shopping,

  /// Car services category.
  carServices,

  /// Public transport category.
  publicTransport,

  /// Wikipedia category.
  wikipedia,

  /// Education category.
  education,

  /// Entertainment category.
  entertainment,

  /// Public services category.
  publicServices,

  /// Geographical area category.
  geographicalArea,

  /// Business category.
  business,

  /// Sightseeing category.
  sightseeing,

  /// Religious places category.
  religiousPlaces,

  /// Roadside category.
  roadside,

  /// Sports category.
  sports,

  /// Uncategorized.
  uncategorized,

  /// Hydrants category.
  hydrants,

  /// Emergency services support category.
  emergencyServicesSupport,

  /// Civil emergency infrastructure category.
  civilEmergencyInfrastructure,

  /// Charging station category.
  chargingStation,

  /// Bicycle charging station category.
  bicycleChargingStation,

  /// Bicycle parking category.
  bicycleParking,
}

/// @nodoc
extension GenericCategoriesIdExtension on GenericCategoriesId {
  int get id {
    switch (this) {
      case GenericCategoriesId.gasStation:
        return 1000;
      case GenericCategoriesId.parking:
        return 1001;
      case GenericCategoriesId.foodAndDrink:
        return 1002;
      case GenericCategoriesId.accommodation:
        return 1003;
      case GenericCategoriesId.medicalServices:
        return 1004;
      case GenericCategoriesId.shopping:
        return 1005;
      case GenericCategoriesId.carServices:
        return 1006;
      case GenericCategoriesId.publicTransport:
        return 1007;
      case GenericCategoriesId.wikipedia:
        return 1008;
      case GenericCategoriesId.education:
        return 1009;
      case GenericCategoriesId.entertainment:
        return 1010;
      case GenericCategoriesId.publicServices:
        return 1011;
      case GenericCategoriesId.geographicalArea:
        return 1012;
      case GenericCategoriesId.business:
        return 1013;
      case GenericCategoriesId.sightseeing:
        return 1014;
      case GenericCategoriesId.religiousPlaces:
        return 1015;
      case GenericCategoriesId.roadside:
        return 1016;
      case GenericCategoriesId.sports:
        return 1017;
      case GenericCategoriesId.uncategorized:
        return 1018;
      case GenericCategoriesId.hydrants:
        return 1019;
      case GenericCategoriesId.emergencyServicesSupport:
        return 1020;
      case GenericCategoriesId.civilEmergencyInfrastructure:
        return 1021;
      case GenericCategoriesId.chargingStation:
        return 1022;
      case GenericCategoriesId.bicycleChargingStation:
        return 1023;
      case GenericCategoriesId.bicycleParking:
        return 1024;
    }
  }

  static GenericCategoriesId fromId(final int id) {
    switch (id) {
      case 1000:
        return GenericCategoriesId.gasStation;
      case 1001:
        return GenericCategoriesId.parking;
      case 1002:
        return GenericCategoriesId.foodAndDrink;
      case 1003:
        return GenericCategoriesId.accommodation;
      case 1004:
        return GenericCategoriesId.medicalServices;
      case 1005:
        return GenericCategoriesId.shopping;
      case 1006:
        return GenericCategoriesId.carServices;
      case 1007:
        return GenericCategoriesId.publicTransport;
      case 1008:
        return GenericCategoriesId.wikipedia;
      case 1009:
        return GenericCategoriesId.education;
      case 1010:
        return GenericCategoriesId.entertainment;
      case 1011:
        return GenericCategoriesId.publicServices;
      case 1012:
        return GenericCategoriesId.geographicalArea;
      case 1013:
        return GenericCategoriesId.business;
      case 1014:
        return GenericCategoriesId.sightseeing;
      case 1015:
        return GenericCategoriesId.religiousPlaces;
      case 1016:
        return GenericCategoriesId.roadside;
      case 1017:
        return GenericCategoriesId.sports;
      case 1018:
        return GenericCategoriesId.uncategorized;
      case 1019:
        return GenericCategoriesId.hydrants;
      case 1020:
        return GenericCategoriesId.emergencyServicesSupport;
      case 1021:
        return GenericCategoriesId.civilEmergencyInfrastructure;
      case 1022:
        return GenericCategoriesId.chargingStation;
      case 1023:
        return GenericCategoriesId.bicycleChargingStation;
      case 1024:
        return GenericCategoriesId.bicycleParking;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
