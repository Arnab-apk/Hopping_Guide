// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Keys used in overlay preview parameter lists.
///
/// These constants identify common parameters present in overlay preview
/// data. Use them when reading values from a [SearchableParameterList].
///
/// It is recommended to use the typed preview data classes such as
/// [PublicTransportParameters], [SafetyParameters] or [SocialReportParameters] instead.
///
/// {@category Overlays}
abstract class PredefinedOverlayGenericParametersIds {
  /// Integer identifier of the preview object.
  static const String id = 'id';

  /// Human-readable category name (localized string).
  static const String categName = 'type';

  /// Integer category identifier (icon id or internal category code).
  static const String categId = 'icon';

  /// Country name or code associated with the preview item.
  static const String country = 'Country';

  /// Raw location string provided by the overlay dataset.
  static const String location = 'eStrLocation';

  /// A list of key/value parameter groups containing translated names.
  static const String keyVals = 'keyvals';

  /// Longitude in decimal degrees.
  static const String longitude = 'longitude';

  /// Latitude in decimal degrees.
  static const String latitude = 'latitude';

  /// Address or human-readable location string.
  static const String address = 'location_address';

  /// UTC creation timestamp (seconds since epoch).
  static const String releaseDate = 'create_stamp_utc';
}

/// Predefined overlay identifiers used by the SDK.
///
/// The enum lists SDK-provided overlay types such as safety alerts and public
/// transport stops. Use [CommonOverlayIdExtension.id] to obtain the numeric UID
/// used by the platform.
///
/// {@category Overlays}
enum CommonOverlayId {
  /// Safety overlay (e.g. speed cameras, red-light cameras).
  safety,

  /// Public transport overlay (stops with schedule information).
  publicTransport,

  /// Social labels overlay. Work in progress, not fully implemented.
  socialLabels,

  /// Social reports overlay (user-submitted reports such as construction).
  socialReports,
}

/// @nodoc
extension CommonOverlayIdExtension on CommonOverlayId {
  int get id {
    switch (this) {
      case CommonOverlayId.safety:
        return 0x50A04;

      case CommonOverlayId.publicTransport:
        return 0x2EEFAA;

      case CommonOverlayId.socialLabels:
        return 0xA200;

      case CommonOverlayId.socialReports:
        return 0xA300;
    }
  }

  static CommonOverlayId fromId(final int id) {
    switch (id) {
      case 0x50A04:
        return CommonOverlayId.safety;
      case 0x2EEFAA:
        return CommonOverlayId.publicTransport;
      case 0xA200:
        return CommonOverlayId.socialLabels;
      case 0xA300:
        return CommonOverlayId.socialReports;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
