// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/routing/vehicle_profile.dart';
import 'package:meta/meta.dart';

/// Represents metadata for a recorded activity.
///
/// Contains short and long descriptions, the sport type, perceived effort level,
/// an optional bicycle profile for cycling or e-bike activities, and visibility
/// settings that control who can view the activity. Attach an
/// [ActivityRecord] to a recording (for example via [Recorder.activityRecord])
/// to store user-provided metadata about the session.
///
/// The [ActivityRecord] is not detected automatically; it must be explicitly set by the user.
///
/// ## See also:
///
/// - [LogMetadata.activityRecord] - Get the activity record from a recorded session.
/// - [BikeProfileElectricBikeProfile] - Represents bicycle profile details for cycling activities.
///
/// {@category Sensor Data Source}
class ActivityRecord {
  /// Creates an [ActivityRecord] with the specified properties.
  ///
  /// The constructor builds metadata that can be attached to a recording. All
  /// parameters are optional and have sensible defaults.
  ///
  /// ## Parameters
  ///
  /// - [shortDescription]: A short title or summary for the activity. Defaults to an empty string.
  /// - [longDescription]: A more detailed description or notes for the activity. Defaults to an empty string.
  /// - [sportType]: The [SportType] for the activity. Defaults to [SportType.unknown].
  /// - [effortType]: The [EffortType] indicating the perceived intensity. Defaults to [EffortType.easy].
  /// - [bikeProfile]: Optional [BikeProfileElectricBikeProfile] used when the activity involves a bicycle or e-bike.
  /// - [visibility]: The [ActivityVisibility] controlling who can view the activity. Defaults to [ActivityVisibility.everyone].
  ActivityRecord({
    this.shortDescription = '',
    this.longDescription = '',
    this.sportType = SportType.unknown,
    this.effortType = EffortType.easy,
    this.bikeProfile,
    this.visibility = ActivityVisibility.everyone,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory ActivityRecord.fromJson(final Map<String, dynamic> json) {
    return ActivityRecord(
      shortDescription: json['shortDescription'],
      longDescription: json['longDescription'],
      sportType: SportTypeExtension.fromId(json['sportType']),
      effortType: EffortTypeExtension.fromId(json['effortType']),
      bikeProfile: BikeProfileElectricBikeProfile.fromJson(json['bikeProfile']),
      visibility: ActivityVisibilityExtension.fromId(json['visibility']),
    );
  }

  /// A short description of the activity.
  ///
  /// A concise title or summary suitable for lists or short displays.
  String shortDescription;

  /// A detailed description of the activity.
  ///
  /// Free-form notes or additional context about the activity. Use this for
  /// details that don't fit in the short description.
  String longDescription;

  /// The type of sport for this activity.
  ///
  /// Specifies the activity category (for example running, cycling, or swimming)
  /// using the [SportType] enumeration.
  SportType sportType;

  /// The effort level for this activity.
  ///
  /// Indicates the perceived intensity of the activity using the [EffortType]
  /// enumeration (for example `easy`, `moderate`, `hard`).
  EffortType effortType;

  /// The bicycle profile, if the activity involves cycling.
  ///
  /// Optional routing and specification details for bicycles and e-bikes.
  BikeProfileElectricBikeProfile? bikeProfile;

  /// The visibility settings for the activity.
  ///
  /// Activities are available only locally, there is no built-in sharing
  /// in the SDK. This setting is intended for use by applications.
  ActivityVisibility visibility;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};

    json['shortDescription'] = shortDescription;
    json['longDescription'] = longDescription;
    json['sportType'] = sportType.id;
    json['effortType'] = effortType.id;
    json['bikeProfile'] = bikeProfile ?? BikeProfileElectricBikeProfile();
    json['visibility'] = visibility.id;

    return json;
  }
}

/// Defines visibility settings for an activity.
///
/// Does not control sharing; activities are local only.
/// For use by applications to manage who can view the activity.
///
/// ## See also:
///
/// - [ActivityRecord.visibility] - The visibility setting for an activity.
///
/// {@category Sensor Data Source}
enum ActivityVisibility {
  /// Activity is visible to everyone.
  everyone,

  /// Activity is visible only to followers.
  followers,

  /// Activity is visible only to the user.
  onlyYou,
}

/// @nodoc
extension ActivityVisibilityExtension on ActivityVisibility {
  int get id {
    switch (this) {
      case ActivityVisibility.everyone:
        return 0;
      case ActivityVisibility.followers:
        return 1;
      case ActivityVisibility.onlyYou:
        return 2;
    }
  }

  static ActivityVisibility fromId(final int id) {
    switch (id) {
      case 0:
        return ActivityVisibility.everyone;
      case 1:
        return ActivityVisibility.followers;
      case 2:
        return ActivityVisibility.onlyYou;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Represents the effort level for an activity.
///
/// ## See also:
///
/// - [ActivityRecord.effortType] - The effort level for an activity.
///
/// {@category Sensor Data Source}
enum EffortType {
  /// Easy effort level.
  easy,

  /// Moderate effort level.
  moderate,

  /// Hard effort level.
  hard,

  /// Maximum effort level.
  maxEffort,
}

/// @nodoc
extension EffortTypeExtension on EffortType {
  int get id {
    switch (this) {
      case EffortType.easy:
        return 0;
      case EffortType.moderate:
        return 1;
      case EffortType.hard:
        return 2;
      case EffortType.maxEffort:
        return 3;
    }
  }

  static EffortType fromId(final int id) {
    switch (id) {
      case 0:
        return EffortType.easy;
      case 1:
        return EffortType.moderate;
      case 2:
        return EffortType.hard;
      case 3:
        return EffortType.maxEffort;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Sport type enumeration.
///
/// Represents various sports activities, categorized by their nature
///
/// ## Also see:
///
/// - [ActivityRecord.sportType] - The sport type for an activity.
///
/// {@category Sensor Data Source}
enum SportType {
  // Foot Sports
  run,
  trailRun,
  walk,
  hike,
  virtualRun,

  // Cycle Sports
  ride,
  mountainBike,
  gravelRide,
  eBikeRide,
  eMountainBike,
  velomobile,
  virtualRide,

  // Water Sports
  canoe,
  kayak,
  kitesurf,
  rowing,
  standUpPaddling,
  surf,
  swim,
  windsurf,

  // Winter Sports
  iceSkate,
  alpineSki,
  backcountrySki,
  nordicSki,
  snowboard,
  snowshoe,

  // Other Sports
  handcycle,
  inlineSkate,
  rockClimb,
  rollerSki,
  golf,
  skateboard,
  soccer,
  wheelchair,
  badminton,
  tennis,
  pickleball,
  crossfit,
  elliptical,
  stairStepper,
  weightTraining,
  yoga,
  workout,
  hiit,
  pilates,
  tableTennis,
  squash,
  racquetball,

  // Multi-sport or General
  unknown,
}

/// @nodoc
extension SportTypeExtension on SportType {
  int get id {
    switch (this) {
      case SportType.run:
        return 0;
      case SportType.trailRun:
        return 1;
      case SportType.walk:
        return 2;
      case SportType.hike:
        return 3;
      case SportType.virtualRun:
        return 4;
      case SportType.ride:
        return 5;
      case SportType.mountainBike:
        return 6;
      case SportType.gravelRide:
        return 7;
      case SportType.eBikeRide:
        return 8;
      case SportType.eMountainBike:
        return 9;
      case SportType.velomobile:
        return 10;
      case SportType.virtualRide:
        return 11;
      case SportType.canoe:
        return 12;
      case SportType.kayak:
        return 13;
      case SportType.kitesurf:
        return 14;
      case SportType.rowing:
        return 15;
      case SportType.standUpPaddling:
        return 16;
      case SportType.surf:
        return 17;
      case SportType.swim:
        return 18;
      case SportType.windsurf:
        return 19;
      case SportType.iceSkate:
        return 20;
      case SportType.alpineSki:
        return 21;
      case SportType.backcountrySki:
        return 22;
      case SportType.nordicSki:
        return 23;
      case SportType.snowboard:
        return 24;
      case SportType.snowshoe:
        return 25;
      case SportType.handcycle:
        return 26;
      case SportType.inlineSkate:
        return 27;
      case SportType.rockClimb:
        return 28;
      case SportType.rollerSki:
        return 29;
      case SportType.golf:
        return 30;
      case SportType.skateboard:
        return 31;
      case SportType.soccer:
        return 32;
      case SportType.wheelchair:
        return 33;
      case SportType.badminton:
        return 34;
      case SportType.tennis:
        return 35;
      case SportType.pickleball:
        return 36;
      case SportType.crossfit:
        return 37;
      case SportType.elliptical:
        return 38;
      case SportType.stairStepper:
        return 39;
      case SportType.weightTraining:
        return 40;
      case SportType.yoga:
        return 41;
      case SportType.workout:
        return 42;
      case SportType.hiit:
        return 43;
      case SportType.pilates:
        return 44;
      case SportType.tableTennis:
        return 45;
      case SportType.squash:
        return 46;
      case SportType.racquetball:
        return 47;
      case SportType.unknown:
        return 48;
    }
  }

  static SportType fromId(final int id) {
    switch (id) {
      case 0:
        return SportType.run;
      case 1:
        return SportType.trailRun;
      case 2:
        return SportType.walk;
      case 3:
        return SportType.hike;
      case 4:
        return SportType.virtualRun;
      case 5:
        return SportType.ride;
      case 6:
        return SportType.mountainBike;
      case 7:
        return SportType.gravelRide;
      case 8:
        return SportType.eBikeRide;
      case 9:
        return SportType.eMountainBike;
      case 10:
        return SportType.velomobile;
      case 11:
        return SportType.virtualRide;
      case 12:
        return SportType.canoe;
      case 13:
        return SportType.kayak;
      case 14:
        return SportType.kitesurf;
      case 15:
        return SportType.rowing;
      case 16:
        return SportType.standUpPaddling;
      case 17:
        return SportType.surf;
      case 18:
        return SportType.swim;
      case 19:
        return SportType.windsurf;
      case 20:
        return SportType.iceSkate;
      case 21:
        return SportType.alpineSki;
      case 22:
        return SportType.backcountrySki;
      case 23:
        return SportType.nordicSki;
      case 24:
        return SportType.snowboard;
      case 25:
        return SportType.snowshoe;
      case 26:
        return SportType.handcycle;
      case 27:
        return SportType.inlineSkate;
      case 28:
        return SportType.rockClimb;
      case 29:
        return SportType.rollerSki;
      case 30:
        return SportType.golf;
      case 31:
        return SportType.skateboard;
      case 32:
        return SportType.soccer;
      case 33:
        return SportType.wheelchair;
      case 34:
        return SportType.badminton;
      case 35:
        return SportType.tennis;
      case 36:
        return SportType.pickleball;
      case 37:
        return SportType.crossfit;
      case 38:
        return SportType.elliptical;
      case 39:
        return SportType.stairStepper;
      case 40:
        return SportType.weightTraining;
      case 41:
        return SportType.yoga;
      case 42:
        return SportType.workout;
      case 43:
        return SportType.hiit;
      case 44:
        return SportType.pilates;
      case 45:
        return SportType.tableTennis;
      case 46:
        return SportType.squash;
      case 47:
        return SportType.racquetball;
      case 48:
        return SportType.unknown;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
