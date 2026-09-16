// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Enumerates the possible capabilities included in this SDK build.
///
/// Use these flags to query which features are present in the binary.
///
/// {@category Settings}
enum SdkCapability {
  /// Capability for offline functionality.
  searchOffline,

  /// Capability for search functionality.
  search,

  /// Capability for social functionality (ex: social reports).
  social,

  /// Capability for Advanced Driver Assistance Systems (ADAS).
  ///
  /// Not available, in development.
  adas,

  /// Capability for mapping functionality.
  mapping,

  /// Capability for navigation functionality.
  navigation,

  /// Capability for content-related functionality.
  content,

  /// Capability for vehicle routing and planning (VRP).
  ///
  /// Not available, in development
  vrp,

  /// Capability for weather-related functionality.
  weather,

  /// Capability for dashcam-related functionality. Includes the Driver Behaviour feature
  dashcam,

  /// Capability for sensor-related functionality.
  sense,

  /// Capability for places-related functionality.
  places,

  /// Capability for timezone-related functionality.
  timezone,

  /// Capability for sound-related functionality.
  sound,

  /// Capability for projection-related functionality.
  projection,

  /// Capability for Flutter-related functionality.
  flutter,

  /// Capability for image-related functionality.
  images,

  /// Capability for ridesharing-related functionality.
  ///
  /// Not available, in development
  ridesharing,

  /// Capability for delivery-related functionality.
  ///
  /// Not available, in development
  delivery,

  /// Capability for data acquisition functionality
  acquisition,

  /// Capability for online geofence functionality
  ///
  /// Not available, in development.
  ///
  /// See the [AlarmService] class of offline geofence functionality.
  geofence,

  /// Capability for activation-related functionality.
  ///
  /// If present, the SDK supports manual activation of the product using the [ActivationService] class.
  /// Otherwise, the SDK will be activated automatically with the provided app authentication token and the [ActivationService]
  /// class will not be available. The [GateKeeperService] class can be used to check the activation status of the SDK in this case.
  activation,
}

/// @nodoc
extension SdkCapabilityExtension on SdkCapability {
  int get id {
    switch (this) {
      case SdkCapability.searchOffline:
        return 0x1;
      case SdkCapability.search:
        return 0x2;
      case SdkCapability.navigation:
        return 0x4;
      case SdkCapability.mapping:
        return 0x8;
      case SdkCapability.social:
        return 0x10;
      case SdkCapability.adas:
        return 0x20;
      case SdkCapability.content:
        return 0x40;
      case SdkCapability.dashcam:
        return 0x80;
      case SdkCapability.weather:
        return 0x100;
      case SdkCapability.vrp:
        return 0x200;
      case SdkCapability.sense:
        return 0x400;
      case SdkCapability.places:
        return 0x800;
      case SdkCapability.timezone:
        return 0x1000;
      case SdkCapability.sound:
        return 0x2000;
      case SdkCapability.projection:
        return 0x4000;
      case SdkCapability.flutter:
        return 0x8000;
      case SdkCapability.images:
        return 0x10000;
      case SdkCapability.ridesharing:
        return 0x20000;
      case SdkCapability.delivery:
        return 0x40000;
      case SdkCapability.acquisition:
        return 0x80000;
      case SdkCapability.geofence:
        return 0x100000;
      case SdkCapability.activation:
        return 0x200000;
    }
  }

  static SdkCapability fromId(int id) {
    switch (id) {
      case 0x1:
        return SdkCapability.searchOffline;
      case 0x2:
        return SdkCapability.search;
      case 0x4:
        return SdkCapability.navigation;
      case 0x8:
        return SdkCapability.mapping;
      case 0x10:
        return SdkCapability.social;
      case 0x20:
        return SdkCapability.adas;
      case 0x40:
        return SdkCapability.content;
      case 0x80:
        return SdkCapability.dashcam;
      case 0x100:
        return SdkCapability.weather;
      case 0x200:
        return SdkCapability.vrp;
      case 0x400:
        return SdkCapability.sense;
      case 0x800:
        return SdkCapability.places;
      case 0x1000:
        return SdkCapability.timezone;
      case 0x2000:
        return SdkCapability.sound;
      case 0x4000:
        return SdkCapability.projection;
      case 0x8000:
        return SdkCapability.flutter;
      case 0x10000:
        return SdkCapability.images;
      case 0x20000:
        return SdkCapability.ridesharing;
      case 0x40000:
        return SdkCapability.delivery;
      case 0x80000:
        return SdkCapability.acquisition;
      case 0x100000:
        return SdkCapability.geofence;
      case 0x200000:
        return SdkCapability.activation;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
