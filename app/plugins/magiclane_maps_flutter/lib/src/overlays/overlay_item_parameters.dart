// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Base parameters for an overlay item.
///
/// An abstract container that exposes the common metadata available for overlay items
/// (map annotations, reports, safety markers, transit stops, etc.). Concrete subclasses
/// carry parameters specific to an overlay type and are typically produced by the
/// [OverlayItem.previewData] accessor.
///
/// The properties declared here are nullable because not every provider includes all
/// metadata keys. Use the concrete subclasses to access type-specific fields.
///
/// ## See also:
/// - [OverlayItem.previewData] for obtaining typed parameters from an overlay item.
/// - [SocialReportParameters] for social report-specific fields.
/// - [SafetyParameters] for safety overlay-specific fields.
/// - [PublicTransportParameters] for transit overlay-specific fields.
///
/// {@category Overlays}
abstract class OverlayItemParameters {
  /// The unique identifier of the overlay item.
  int? get id;

  /// The creation timestamp of the overlay item in UTC.
  DateTime? get createStampUtc;

  /// The Overlay item category id.
  int? get iconId;
}

/// Parameters for a social-report overlay item.
///
/// Contains fields commonly provided for user-generated social reports such as the
/// report type, optional TTS text (`tts`), owner information, a numeric `score`,
/// optional `coordinates`, and lifecycle timestamps (created/updated/expiry).
///
/// {@category Overlays}
class SocialReportParameters extends OverlayItemParameters {
  SocialReportParameters({
    required this.id,
    required this.createStampUtc,
    required this.iconId,
    required this.type,
    required this.tts,
    required this.coordinates,
    required this.description,
    required this.ownerId,
    required this.ownerName,
    required this.score,
    required this.updateStampUtc,
    required this.expireStampUtc,
    required this.validityMins,
    required this.hasSnapshot,
    required this.direction,
    required this.allowThumb,
    required this.allowUpdate,
    required this.allowDelete,
    required this.ownReport,
    required this.country,
  });

  @internal
  factory SocialReportParameters.fromParameters(List<GemParameter> params) {
    T? findValue<T>(String key) {
      for (final GemParameter param in params) {
        if (param.key == key) {
          return param.value as T?;
        }
      }
      return null;
    }

    return SocialReportParameters(
      id: findValue<int>('id'),
      iconId: findValue<int>('icon'),
      type: findValue<String?>('type'),
      tts: findValue<String?>('tts'),
      coordinates:
          findValue<double?>('latitude') != null &&
              findValue<double?>('longitude') != null
          ? Coordinates(
              latitude: findValue<double>('latitude')!,
              longitude: findValue<double>('longitude')!,
            )
          : null,
      description: findValue<String?>('description'),
      ownerId: findValue<int?>('owner_id'),
      ownerName: findValue<String?>('owner_name'),
      score: findValue<int?>('score'),
      createStampUtc: (() {
        final int? seconds = findValue<int>('create_stamp_utc');
        return seconds == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
      })(),
      updateStampUtc: (() {
        final int? seconds = findValue<int>('update_stamp_utc');
        return seconds == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
      })(),
      expireStampUtc: (() {
        final int? seconds = findValue<int>('expire_stamp_utc');
        return seconds == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
      })(),
      validityMins: findValue<int?>('validity_mins'),
      hasSnapshot: findValue<bool?>('has_snapshot'),
      direction: findValue<double?>('direction_1'),
      allowThumb: findValue<bool?>('allow_thumb'),
      allowUpdate: findValue<bool?>('allow_update'),
      allowDelete: findValue<bool?>('allow_delete'),
      ownReport: findValue<bool?>('own_report'),
      country: findValue<String?>('Country'),
    );
  }

  @override
  int? id;

  @override
  DateTime? createStampUtc;

  @override
  int? iconId;

  /// Reported subject type (eg: Police, Fixed Camera, Traffic, Crash, Road Hazard, Weather Hazard or Road Closure)
  String? type;

  /// Text to speech description of the report, depends on the SDK language
  String? tts;

  /// Reported location coordinates
  Coordinates? coordinates;

  /// Report description
  String? description;

  /// Report owner identifier
  int? ownerId;

  /// Report owner name
  String? ownerName;

  /// Report score
  int? score;

  /// Last update timestamp in UTC
  DateTime? updateStampUtc;

  /// Expiration timestamp in UTC
  DateTime? expireStampUtc;

  /// Validity time left in minutes
  int? validityMins;

  /// Returns true if the report has a snapshot image, the [SocialOverlay.getReportSnapshot] method can be used on OverlayItem to retrieve the image
  bool? hasSnapshot;

  /// The azimuth direction of the report, relative to the north axis
  double? direction;

  /// Whether the report can be thumbed up or down (eg. your own reports cannot be thumbed or the admin inhibitor blocks the user if it considers him as a vandalizer).
  //
  /// Thumbing increases the report score.
  bool? allowThumb;

  /// Whether the report can be updated
  bool? allowUpdate;

  /// Whether the report can be deleted
  bool? allowDelete;

  /// Whether this is the user's own report
  bool? ownReport;

  /// The country ISO3 code
  String? country;
}

/// Parameters for safety-related overlay items.
///
/// Safety overlays represent traffic safety devices and warnings (for example: cameras,
/// speed measurement points, or other road-safety markers).
///
/// This class exposes provider information, camera type identifiers, textual status fields and measured values such
/// as `speedValue`/`speedUnit` when available.
///
/// {@category Overlays}
class SafetyParameters extends OverlayItemParameters {
  SafetyParameters({
    required this.id,
    required this.createStampUtc,
    required this.iconId,
    required this.country,
    required this.angleIcon,
    required this.cameraTypeId,
    required this.strCameraStatus,
    required this.strDrivingDirection,
    required this.strLocation,
    required this.strTowards,
    required this.provider,
    required this.providerId,
    required this.speedUnit,
    required this.speedValue,
    required this.type,
    required this.strDrivingDirectionFlag,
  });

  @internal
  factory SafetyParameters.fromParameters(List<GemParameter> params) {
    T? findValue<T>(String key) {
      for (final GemParameter param in params) {
        if (param.key == key) {
          return param.value as T?;
        }
      }
      return null;
    }

    return SafetyParameters(
      id: findValue<int>('id'),
      iconId: findValue<int>('icon'),
      country: findValue<String?>('Country'),
      angleIcon: findValue<int?>('angleIcon'),
      cameraTypeId: findValue<int?>('camera_type_id'),
      strCameraStatus: findValue<String?>('eStrCameraStatus'),
      strDrivingDirection: findValue<String?>('eStrDrivingDirection'),
      strLocation: findValue<String?>('eStrLocation'),
      strTowards: findValue<int?>('eStrTowards'),
      provider: findValue<String?>('provider'),
      providerId: findValue<int?>('provider_id'),
      speedUnit: findValue<String?>('speedUnit'),
      speedValue: findValue<int?>('speedValue'),
      type: findValue<String?>('type'),
      strDrivingDirectionFlag: findValue<bool?>('eStrDrivingDirectionFlag'),
      createStampUtc: (() {
        final int? ms = findValue<int>('create_stamp_utc');
        return ms == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(ms * 1000, isUtc: true);
      })(),
    );
  }

  @override
  int? id;

  @override
  DateTime? createStampUtc;

  @override
  int? iconId;

  /// The country ISO3 code
  String? country;

  /// Angle used to calculate the icon rotation
  int? angleIcon;

  /// The icon camera id
  int? cameraTypeId;

  /// Camera status (eg. Active, Inactive)
  String? strCameraStatus;

  /// The direction of driving (eg. Both Ways, One way)
  String? strDrivingDirection;

  /// Street address
  String? strLocation;

  /// Angle used to calculate the icon rotation
  int? strTowards;

  /// Data provider name
  String? provider;

  /// Data provider identifier
  int? providerId;

  /// Speed unit (eg. km/h, mph)
  String? speedUnit;

  /// Speed value
  int? speedValue;

  /// Safety overlay type (eg. Speed Limit)
  String? type;

  /// True if the camera is located on a two‑way street; false if it is on a one‑way street
  bool? strDrivingDirectionFlag;
}

/// Parameters for public-transport overlay items.
///
/// Used for transit-related overlays (stops, stations, lines). This container provides
/// a human-readable `name`, the icon id and creation timestamp, and direction flags
/// used for rendering direction-specific icons.
///
/// ## Also see:
///
/// - [OverlayItem.getPTStopInfo] for obtaining more detailed transit stop information.
///
/// {@category Overlays}
class PublicTransportParameters extends OverlayItemParameters {
  PublicTransportParameters({
    required this.id,
    required this.createStampUtc,
    required this.iconId,
    required this.name,
    required this.strDrivingDirectionFlag,
  });

  @internal
  factory PublicTransportParameters.fromParameters(List<GemParameter> params) {
    T? findValue<T>(String key) {
      for (final GemParameter param in params) {
        if (param.key == key) {
          return param.value as T?;
        }
      }
      return null;
    }

    return PublicTransportParameters(
      id: findValue<int>('id'),
      iconId: findValue<int>('icon'),
      name: findValue<String?>('name'),
      strDrivingDirectionFlag: findValue<bool?>('eStrDrivingDirectionFlag'),
      createStampUtc: (() {
        final int? ms = findValue<int>('create_stamp_utc');
        return ms == null
            ? null
            : DateTime.fromMillisecondsSinceEpoch(ms * 1000, isUtc: true);
      })(),
    );
  }

  @override
  DateTime? createStampUtc;

  @override
  int? iconId;

  @override
  int? id;

  /// Public transport stop name
  String? name;

  /// True if the public transport stop is located on a two‑way street; false if it is on a one‑way street
  bool? strDrivingDirectionFlag;
}
