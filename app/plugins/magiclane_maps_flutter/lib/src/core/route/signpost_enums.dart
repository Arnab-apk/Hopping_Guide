// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Signpost connection information.
///
/// Indicates how this item connects to adjacent sign elements (for example a branch or an exit). Use this value
/// to determine layout flow and precedence when composing signpost renderings.
///
/// {@category Route}
enum SignpostConnectionInfo {
  /// Invalid
  invalid,

  /// Branch
  branch,

  /// Towards
  towards,

  /// Exit
  exit,
}

/// @nodoc
extension SignpostConnectionInfoExtension on SignpostConnectionInfo {
  int get id {
    switch (this) {
      case SignpostConnectionInfo.invalid:
        return 0;
      case SignpostConnectionInfo.branch:
        return 1;
      case SignpostConnectionInfo.towards:
        return 2;
      case SignpostConnectionInfo.exit:
        return 3;
    }
  }

  static SignpostConnectionInfo fromId(final int id) {
    switch (id) {
      case 0:
        return SignpostConnectionInfo.invalid;
      case 1:
        return SignpostConnectionInfo.branch;
      case 2:
        return SignpostConnectionInfo.towards;
      case 3:
        return SignpostConnectionInfo.exit;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Signpost pictogram type.
///
/// Enumerates pictogram icons that can appear on signposts (for example airport, parking or petrol station).
/// Pictogram values are used when [SignpostItem.type] is [SignpostItemType.pictogram].
///
/// {@category Route}
enum SignpostPictogramType {
  /// Invalid
  invalid,

  /// Airport
  airport,

  /// Bus station
  busStation,

  /// Fair ground
  fairGround,

  /// Ferry
  ferry,

  /// First aid post
  firstAidPost,

  /// Harbour
  harbour,

  /// Hospital
  hospital,

  /// Hotel/motel
  hotelMotel,

  /// Industrial area
  industrialArea,

  /// Information centre
  informationCentre,

  /// Parking facility
  parkingFacility,

  /// Petrol station
  petrolStation,

  /// Railway station
  railwayStation,

  /// Rest area
  restArea,

  /// Restaurant
  restaurant,

  /// Toilet
  toilet,
}

/// @nodoc
extension SignpostPictogramTypeExtension on SignpostPictogramType {
  int get id {
    switch (this) {
      case SignpostPictogramType.invalid:
        return 0;
      case SignpostPictogramType.airport:
        return 1;
      case SignpostPictogramType.busStation:
        return 2;
      case SignpostPictogramType.fairGround:
        return 3;
      case SignpostPictogramType.ferry:
        return 4;
      case SignpostPictogramType.firstAidPost:
        return 5;
      case SignpostPictogramType.harbour:
        return 6;
      case SignpostPictogramType.hospital:
        return 7;
      case SignpostPictogramType.hotelMotel:
        return 8;
      case SignpostPictogramType.industrialArea:
        return 9;
      case SignpostPictogramType.informationCentre:
        return 10;
      case SignpostPictogramType.parkingFacility:
        return 11;
      case SignpostPictogramType.petrolStation:
        return 12;
      case SignpostPictogramType.railwayStation:
        return 13;
      case SignpostPictogramType.restArea:
        return 14;
      case SignpostPictogramType.restaurant:
        return 15;
      case SignpostPictogramType.toilet:
        return 16;
    }
  }

  static SignpostPictogramType fromId(final int id) {
    switch (id) {
      case 0:
        return SignpostPictogramType.invalid;
      case 1:
        return SignpostPictogramType.airport;
      case 2:
        return SignpostPictogramType.busStation;
      case 3:
        return SignpostPictogramType.fairGround;
      case 4:
        return SignpostPictogramType.ferry;
      case 5:
        return SignpostPictogramType.firstAidPost;
      case 6:
        return SignpostPictogramType.harbour;
      case 7:
        return SignpostPictogramType.hospital;
      case 8:
        return SignpostPictogramType.hotelMotel;
      case 9:
        return SignpostPictogramType.industrialArea;
      case 10:
        return SignpostPictogramType.informationCentre;
      case 11:
        return SignpostPictogramType.parkingFacility;
      case 12:
        return SignpostPictogramType.petrolStation;
      case 13:
        return SignpostPictogramType.railwayStation;
      case 14:
        return SignpostPictogramType.restArea;
      case 15:
        return SignpostPictogramType.restaurant;
      case 16:
        return SignpostPictogramType.toilet;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Road shield classification used for route-number items.
///
/// Enumerates the shield styles or jurisdiction levels used to render route number shields on signposts.
/// Use the value to select the appropriate shield artwork or styling when presenting route numbers.
///
/// {@category Route}
enum RoadShieldType {
  /// Invalid
  invalid,

  /// County
  county,

  /// State
  state,

  /// Federal
  federal,

  /// Interstate
  interstate,

  /// Four
  four,

  /// Five
  five,

  /// Six
  six,

  /// Seven
  seven,
}

/// @nodoc
extension RoadShieldTypeExtension on RoadShieldType {
  int get id {
    switch (this) {
      case RoadShieldType.invalid:
        return 0;
      case RoadShieldType.county:
        return 1;
      case RoadShieldType.state:
        return 2;
      case RoadShieldType.federal:
        return 3;
      case RoadShieldType.interstate:
        return 4;
      case RoadShieldType.four:
        return 5;
      case RoadShieldType.five:
        return 6;
      case RoadShieldType.six:
        return 7;
      case RoadShieldType.seven:
        return 8;
    }
  }

  static RoadShieldType fromId(final int id) {
    switch (id) {
      case 0:
        return RoadShieldType.invalid;
      case 1:
        return RoadShieldType.county;
      case 2:
        return RoadShieldType.state;
      case 3:
        return RoadShieldType.federal;
      case 4:
        return RoadShieldType.interstate;
      case 5:
        return RoadShieldType.four;
      case 6:
        return RoadShieldType.five;
      case 7:
        return RoadShieldType.six;
      case 8:
        return RoadShieldType.seven;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Signpost item type.
///
/// Enumerates the semantic categories for a signpost element. The type controls which additional properties
/// are meaningful (for example [pictogram] items expose pictogramType).
///
/// {@category Route}
enum SignpostItemType {
  /// Invalid
  invalid,

  /// Place name
  placeName,

  /// Route number
  routeNumber,

  /// Route name
  routeName,

  /// Exit number
  exitNumber,

  /// Exit name
  exitName,

  /// Pictogram
  pictogram,

  /// Other
  otherDestination,
}

/// @nodoc
extension SignpostItemTypeExtension on SignpostItemType {
  int get id {
    switch (this) {
      case SignpostItemType.invalid:
        return 0;
      case SignpostItemType.placeName:
        return 1;
      case SignpostItemType.routeNumber:
        return 2;
      case SignpostItemType.routeName:
        return 3;
      case SignpostItemType.exitNumber:
        return 4;
      case SignpostItemType.exitName:
        return 5;
      case SignpostItemType.pictogram:
        return 6;
      case SignpostItemType.otherDestination:
        return 7;
    }
  }

  static SignpostItemType fromId(final int id) {
    switch (id) {
      case 0:
        return SignpostItemType.invalid;
      case 1:
        return SignpostItemType.placeName;
      case 2:
        return SignpostItemType.routeNumber;
      case 3:
        return SignpostItemType.routeName;
      case 4:
        return SignpostItemType.exitNumber;
      case 5:
        return SignpostItemType.exitName;
      case 6:
        return SignpostItemType.pictogram;
      case 7:
        return SignpostItemType.otherDestination;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
