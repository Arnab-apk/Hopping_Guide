// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Unit system used for textual and spoken measurements.
///
/// Controls whether distances, speeds and other measurements are formatted
/// using metric units (kilometres/metres) or imperial units (miles/feet).
///
/// {@category Settings}
enum UnitSystem {
  /// Metric
  metric,

  /// Imperial UK - miles and yards
  imperialUK,

  /// Imperial US - feet and inches
  imperialUS,
}

/// @nodoc
extension UnitSystemExtension on UnitSystem {
  int get id {
    switch (this) {
      case UnitSystem.metric:
        return 0;
      case UnitSystem.imperialUK:
        return 1;
      case UnitSystem.imperialUS:
        return 2;
    }
  }

  static UnitSystem fromId(int id) {
    switch (id) {
      case 0:
        return UnitSystem.metric;
      case 1:
        return UnitSystem.imperialUK;
      case 2:
        return UnitSystem.imperialUS;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Map language selection options.
///
/// Use these options to control whether map objects use the API language or
/// their native language for labels and names.
///
/// {@category Settings}
enum MapLanguage {
  /// The map language is automatically selected based on the API language.
  automaticLanguage,

  /// The native language is used on map objects.
  nativeLanguage,
}

/// @nodoc
extension MapLanguageExtension on MapLanguage {
  int get id {
    switch (this) {
      case MapLanguage.automaticLanguage:
        return 0;
      case MapLanguage.nativeLanguage:
        return 1;
    }
  }

  static MapLanguage fromId(int id) {
    switch (id) {
      case 0:
        return MapLanguage.automaticLanguage;
      case 1:
        return MapLanguage.nativeLanguage;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Application theme selection used for images and text rendering.
///
/// - Use [AppTheme.automatic] to let the SDK pick light/dark based on system
///   settings.
/// - [AppTheme.dark] and [AppTheme.light] force a specific rendering theme.
///
/// ## Also see:
///
/// - [SdkSettings.appTheme] to get or set the current application theme.
///
/// {@category Settings}
enum AppTheme {
  /// Automatic theme selection
  automatic,

  /// Dark theme
  dark,

  /// Light theme
  light,
}

/// @nodoc
extension AppThemeExtension on AppTheme {
  int get id {
    switch (this) {
      case AppTheme.automatic:
        return 0;
      case AppTheme.dark:
        return 1;
      case AppTheme.light:
        return 2;
    }
  }

  static AppTheme fromId(int id) {
    switch (id) {
      case 0:
        return AppTheme.automatic;
      case 1:
        return AppTheme.dark;
      case 2:
        return AppTheme.light;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Error reason type
///
/// {@category Settings}
enum Reason {
  /// There is not enough space on disk.
  ///
  /// Resolution: run a cleanup procedure in order to free more disk space
  noDiskSpace,

  /// There is not enough space on disk.
  ///
  /// Resolution: run a cleanup procedure in order to free more disk space
  expiredSDK,
}

/// @nodoc
extension ReasonExtension on Reason {
  int get id {
    switch (this) {
      case Reason.noDiskSpace:
        return 0;
      case Reason.expiredSDK:
        return 1;
    }
  }

  static Reason fromId(final int id) {
    switch (id) {
      case 0:
        return Reason.noDiskSpace;
      case 1:
        return Reason.expiredSDK;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// The status for [ContentStore] data.
///
/// {@category Settings}
enum ContentStoreStatus {
  /// Notifies that the existing content is old, which implies that the SDK still has
  /// support but will not use the latest data.
  ///
  /// An update is recommended as soon as possible.
  oldData,

  /// Notifies that the existing worldwide road map data is expired, which implies that the SDK worldwide road map does
  /// not have support anymore.
  ///
  /// Can only use data available online. An update is required in order to use online operations.
  ///
  /// Only relevant for [ContentType.roadMap].
  expiredData,

  /// Notifies that the worldwide road map data is up to date. This notification is sent only as a result of a
  /// [ContentStore.checkForUpdate] request.
  ///
  /// No action is required.
  upToDate,
}

/// @nodoc
extension ContentStoreStatusExtension on ContentStoreStatus {
  int get id {
    switch (this) {
      case ContentStoreStatus.oldData:
        return 0;
      case ContentStoreStatus.expiredData:
        return 1;
      case ContentStoreStatus.upToDate:
        return 2;
    }
  }

  static ContentStoreStatus fromId(final int id) {
    switch (id) {
      case 0:
        return ContentStoreStatus.oldData;
      case 1:
        return ContentStoreStatus.expiredData;
      case 2:
        return ContentStoreStatus.upToDate;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Service group enum, including map tiles, traffic, terrain.
///
/// {@category Settings}
enum ServiceGroupType {
  /// All map data related services: map tiles, overlays, searching, routing.
  mapDataService,

  /// Traffic related services: live traffic flow, congestion, detours, closed roads.
  trafficService,

  /// Terrain/satellite/external WMTS services.
  terrainService,

  /// Content download service
  contentService,
}

/// @nodoc
extension ServiceGroupTypeExtension on ServiceGroupType {
  int get id {
    switch (this) {
      case ServiceGroupType.mapDataService:
        return 0;
      case ServiceGroupType.trafficService:
        return 1;
      case ServiceGroupType.terrainService:
        return 2;
      case ServiceGroupType.contentService:
        return 3;
    }
  }

  static ServiceGroupType fromId(final int id) {
    switch (id) {
      case 0:
        return ServiceGroupType.mapDataService;
      case 1:
        return ServiceGroupType.trafficService;
      case 2:
        return ServiceGroupType.terrainService;
      case 3:
        return ServiceGroupType.contentService;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Represents online restrictions using bitwise flags.
///
/// {@category Settings}
enum OnlineRestrictions {
  /// No internet connection
  connection,

  /// Restricted by network type (e.g., mobile network restrictions)
  networkType,

  /// Restricted due to rate limiting (too many requests)
  rateLimit,

  /// Restricted due to outdated service version
  outdated,

  /// Restricted due to authorization issues (e.g., no access rights)
  authorization,
}

/// @nodoc
extension OnlineRestrictionsExtension on OnlineRestrictions {
  int get id {
    switch (this) {
      case OnlineRestrictions.connection:
        return 1;
      case OnlineRestrictions.networkType:
        return 2;
      case OnlineRestrictions.rateLimit:
        return 4;
      case OnlineRestrictions.outdated:
        return 8;
      case OnlineRestrictions.authorization:
        return 16;
    }
  }

  static OnlineRestrictions fromId(final int id) {
    switch (id) {
      case 1:
        return OnlineRestrictions.connection;
      case 2:
        return OnlineRestrictions.networkType;
      case 4:
        return OnlineRestrictions.rateLimit;
      case 8:
        return OnlineRestrictions.outdated;
      case 16:
        return OnlineRestrictions.authorization;
      default:
        throw ArgumentError('Invalid id: $id');
    }
  }
}
