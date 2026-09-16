// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:core';
import 'dart:typed_data';
import 'dart:ui';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Compact country metadata including display name, ISO code and flag.
///
/// This  value object is returned by several [MapDetails]
/// helpers (for example, [MapDetails.getCountryData] and [MapDetails.allCountriesData]) and can be
/// used by clients to display country information or retrieve flag images.
///
/// ## See also:
///
/// - [MapDetails] - Utilities for querying map metadata and country information.
///
/// {@category Maps & 3D Scenes}
class CountryData {
  /// Creates a [CountryData] instance.
  ///
  /// API users do not typically construct this object directly.
  ///
  /// ## Parameters
  ///
  /// - [name]: (`String`) Human-readable country name.
  /// - [isoCode]: (`String`) ISO 3166-1 alpha-3 country code (e.g. `USA`).
  /// - [flagImage]: (`Img?`) Optional flag image object; null when not present.
  CountryData({required this.name, required this.isoCode, this.flagImage});

  /// The country name.
  final String name;

  /// The ISO 3166-1 alpha-3 country code.
  ///
  /// ## Also see:
  ///
  /// - [ISOCodeConversions] - Utilities for converting and inspecting ISO codes.
  final String isoCode;

  /// The country flag image, if available.
  final Img? flagImage;

  @override
  bool operator ==(covariant final CountryData other) {
    if (identical(this, other)) {
      return true;
    }

    final bool imagesEqual;
    if (flagImage == null && other.flagImage == null) {
      imagesEqual = true;
    } else if (flagImage != null && other.flagImage != null) {
      imagesEqual = flagImage!.uid == other.flagImage!.uid;
    } else {
      imagesEqual = false;
    }

    return name == other.name && isoCode == other.isoCode && imagesEqual;
  }

  @override
  int get hashCode {
    final int imageUid = flagImage?.uid ?? 0;
    return name.hashCode ^ isoCode.hashCode ^ imageUid.hashCode;
  }
}

/// Utilities for querying map metadata, coverage and country information.
///
/// The static [MapDetails] API provides read-only helpers to inspect local
/// map coverage, obtain country names and flags, compute sunrise/sunset
/// times, enumerate map providers, and fetch version/release information.
///
/// ## Also see:
///
/// - [CountryData] - Compact country metadata including name, ISO code and flag.
/// - [ISOCodeConversions] - Utilities for converting and inspecting ISO codes.
/// - [Language] - Represents language metadata used by the SDK.
///
/// {@category Maps & 3D Scenes}
abstract class MapDetails {
  /// Returns the map coverage status for a region defined by WGS84 coordinates.
  ///
  /// This method performs a local check using only device data and does not
  /// perform any network requests. It is suitable for quickly determining
  /// whether map tiles for a region are available offline.
  ///
  /// ## Parameters
  ///
  /// - [coords]: (`List<Coordinates>`) List of WGS84 coordinates that define
  ///   the region of interest.
  ///
  /// ## Returns
  ///
  /// - ([MapCoverage]) Enum value describing the coverage status for the
  ///   supplied region.
  static MapCoverage getMapCoverage(final List<Coordinates> coords) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getMapCoverageList',
      args: coords,
    );

    return MapCoverageExtension.fromId(resultString['result']);
  }

  /// Returns the map coverage status for a single WGS84 coordinate.
  ///
  /// This convenience helper evaluates coverage for a single point using only
  /// device-local information.
  ///
  /// ## Parameters
  ///
  /// - [coords]: (`Coordinates`) WGS84 coordinate to check.
  ///
  /// ## Returns
  ///
  /// - ([MapCoverage]) Enum value describing the coverage status for the
  ///   supplied coordinate.
  static MapCoverage getPointMapCoverage(final Coordinates coords) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getPointMapCoverage',
      args: coords,
    );

    return MapCoverageExtension.fromId(resultString['result']);
  }

  /// Returns the map coverage status for a country identified by its ISO code.
  ///
  /// The check is performed locally and is fast. Use the returned value to
  /// determine whether offline tiles exist for the whole country.
  ///
  /// ## Parameters
  ///
  /// - [code]: (`String`) ISO 3166-1 alpha-3 country code (for example,
  ///   `USA`).
  ///
  /// ## Returns
  ///
  /// - ([MapCoverage]) Coverage status for the specified country.
  static MapCoverage getCountryMapCoverage(final String code) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getCountryMapCoverage',
      args: code,
    );

    return MapCoverageExtension.fromId(resultString['result']);
  }

  /// Returns the display name of the country that contains the coordinates.
  ///
  /// ## Parameters
  ///
  /// - [coords]: (`Coordinates`) WGS84 coordinate.
  ///
  /// ## Returns
  ///
  /// - (`String`) The country name, or an empty string if none is found.
  static String getCountryName(final Coordinates coords) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getCountryName',
      args: coords,
    );

    return resultString['result'];
  }

  /// Returns the country name associated with an internal country index.
  ///
  /// ## Parameters
  ///
  /// - [index]: (`int`) Internal country index.
  ///
  /// ## Returns
  ///
  /// - (`String`) The country name for the given index.
  static String getCountryNameByIndex(final int index) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getCountryNameByIndex',
      args: index,
    );

    return resultString['result'];
  }

  /// Returns the country name for the supplied ISO 3166-1 alpha-3 code.
  ///
  /// ## Parameters
  ///
  /// - [code]: (`String`) ISO 3166-1 alpha-3 country code.
  ///
  /// ## Returns
  ///
  /// - (`String`) The country name for the given code.
  static String getCountryNameByISO(final String code) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getCountryNameByISO',
      args: code,
    );

    return resultString['result'];
  }

  /// Returns language codes for the country with the given index.
  ///
  /// ## Parameters
  ///
  /// - [index]: (`int`) Country index.
  ///
  /// ## Returns
  ///
  /// - (`List<String>`) A list of language ISO codes.
  static List<String> getLanguageCodeByIndex(final int index) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getLanguageCodesByIndex',
      args: index,
    );

    return (resultString['result'] as List<dynamic>).cast<String>();
  }

  /// Returns language codes for the country that contains the coordinates.
  ///
  /// Returns an empty list when the coordinates do not map to a known
  /// country.
  ///
  /// ## Parameters
  ///
  /// - [coords]: (`Coordinates`) WGS84 coordinates.
  ///
  /// ## Returns
  ///
  /// - (`List<String>`) Language ISO codes for the country, or an empty list.
  static List<String> getLanguageCode(final Coordinates coords) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getLanguageCodes',
      args: coords,
    );

    return (resultString['result'] as List<dynamic>).cast<String>();
  }

  /// Returns the ISO 3166-1 alpha-3 country code for the supplied WGS84
  /// coordinates.
  ///
  /// The method returns an empty string when the coordinates do not fall
  /// within any recognised country.
  ///
  /// ## Parameters
  ///
  /// - [coords]: (`Coordinates`) WGS84 coordinates.
  ///
  /// ## Returns
  ///
  /// - (`String`) ISO 3166-1 alpha-3 country code, or an empty string.
  static String getCountryCode(final Coordinates coords) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getCountryCode',
      args: coords,
    );

    return resultString['result'];
  }

  /// Returns the ISO 3166-1 alpha-3 country code for an internal index.
  ///
  /// ## Parameters
  ///
  /// - [index]: (`int`) Country index.
  ///
  /// ## Returns
  ///
  /// - (`String`) ISO 3166-1 alpha-3 country code, or an empty string.
  static String getCountryCodeByIndex(final int index) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getCountryCodeByIndex',
      args: index,
    );

    return resultString['result'];
  }

  /// Returns the country flag image bytes for the specified country index.
  ///
  /// ## Parameters
  ///
  /// - [index]: (`int`) Internal country index.
  /// - [size]: (`Size?`) Optional desired image size. If omitted the image's
  ///   natural size is returned.
  /// - [format]: (`ImageFileFormat?`) Optional image format.
  ///
  /// ## Returns
  ///
  /// - (`Uint8List?`) Raw image bytes for the flag, or null if unavailable.
  ///
  /// ## Also see:
  ///
  /// - [getCountryFlagImgByIndex] - Retrieve an [Img] wrapper for the flag.
  /// - [getCountryFlag] - Retrieve flag image bytes by ISO code.
  static Uint8List? getCountryFlagByIndex({
    required final int index,
    final Size? size,
    final ImageFileFormat? format,
  }) {
    return GemKitPlatform.instance.callGetImage(
      0,
      'MapDetailsgetCountryIcon',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
      arg: index.toString(),
    );
  }

  /// Get the country flag image by index as a [Img].
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getCountryFlagByIndex] when you only need raw image bytes.
  ///
  /// ## Parameters
  ///
  /// - [index]: (`int`) Country index.
  ///
  /// ## Returns
  ///
  /// - (`Img?`) An [Img] object when available, otherwise null.
  ///
  /// ## Also see:
  ///
  /// - [getCountryFlagByIndex] - Retrieve flag image bytes directly.
  /// - [getCountryFlagImg] - Retrieve an [Img] wrapper by ISO code.
  static Img? getCountryFlagImgByIndex(final int index) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getCountryFlagImgByIndex',
      args: index,
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return Img.init(resultString['result']);
  }

  /// Returns raw image bytes for the country flag by ISO 3166-1 alpha-3 code.
  ///
  /// If the provided `countryCode` is invalid a default question-mark image
  /// may be returned by the platform implementation.
  ///
  /// ## Parameters
  ///
  /// - [countryCode]: (`String`) ISO 3166-1 alpha-3 code of the country.
  /// - [size]: (`Size?`) Optional desired image size.
  /// - [format]: (`ImageFileFormat?`) Optional image format.
  ///
  /// ## Returns
  ///
  /// - (`Uint8List?`) Raw image bytes for the flag, or null if unavailable.
  ///
  /// ## Also see:
  ///
  /// - [getCountryFlagImg] - Retrieve an [Img] wrapper for the flag.
  /// - [getCountryFlagByIndex] - Retrieve flag image bytes by index.
  static Uint8List? getCountryFlag({
    required final String countryCode,
    final Size? size,
    final ImageFileFormat? format,
  }) {
    return GemKitPlatform.instance.callGetImage(
      0,
      'MapDetailsgetCountryFlag',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
      arg: countryCode,
    );
  }

  /// Get the country flag image by ISO code as a [Img].
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getCountryFlag] when you only need raw image bytes.
  ///
  /// ## Parameters
  ///
  /// - [countryCode]: (`String`) ISO 3166-1 alpha-3 code.
  ///
  /// ## Returns
  ///
  /// - (`Img?`) The [Img] object representing the flag, or null if not
  ///   available.
  ///
  /// ## See also:
  ///
  /// - [getCountryFlag] - Retrieve flag image bytes directly.
  /// - [getCountryFlagByIndex] - Retrieve flag image bytes by index.
  static Img? getCountryFlagImg(final String countryCode) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getCountryFlagImg',
      args: countryCode,
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return Img.init(resultString['result']);
  }

  /// Returns the geographic bounding rectangle for a country code.
  ///
  /// ## Parameters
  ///
  /// - [code]: (`String`) ISO 3166-1 alpha-3 country code.
  ///
  /// ## Returns
  ///
  /// - (`RectangleGeographicArea`) The country's bounding rectangle in WGS84
  ///   coordinates.
  static RectangleGeographicArea getCountryBoundingRectangle(
    final String code,
  ) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getCountryBoundingRectangle',
      args: code,
    );

    return RectangleGeographicArea.fromJson(resultString['result']);
  }

  /// Returns the sunrise and sunset times (UTC) for the supplied position and
  /// reference date.
  ///
  /// The returned times are in UTC. Near the poles the sunrise or sunset may
  /// fall on a different calendar day; callers should treat these values as
  /// UTC instants.
  ///
  /// ## Parameters
  ///
  /// - [coords]: (`Coordinates`) WGS84 coordinates for the location.
  /// - [time]: (`DateTime`) Reference date/time (used to compute seasonal
  ///   sunrise/sunset times).
  ///
  /// ## Returns
  ///
  /// - (DateTime, DateTime) Tuple where the first element is sunrise (UTC)
  ///   and the second is sunset (UTC).
  static (DateTime, DateTime) getSunriseAndSunset(
    final Coordinates coords,
    final DateTime time,
  ) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getSunriseAndSunset',
      args: <String, Object>{
        'coords': coords,
        'refTime': time.millisecondsSinceEpoch,
      },
    );

    final Map<String, dynamic> result =
        resultString['result'] as Map<String, dynamic>;
    final int first = result['first'];
    final int second = result['second'];

    return (
      DateTime.fromMillisecondsSinceEpoch(first, isUtc: true),
      DateTime.fromMillisecondsSinceEpoch(second, isUtc: true),
    );
  }

  /// Returns whether it is night at the given coordinates and reference time.
  ///
  /// ## Parameters
  ///
  /// - [coords]: (`Coordinates`) WGS84 coordinates.
  /// - [time]: (`DateTime`) Reference time.
  ///
  /// ## Returns
  ///
  /// - (`bool`) True if it is night at the specified location/time, false
  ///   otherwise.
  ///
  /// ## Also see:
  ///
  /// - [getSunriseAndSunset] - Retrieve sunrise/sunset times for a location.
  static bool isNight(final Coordinates coords, final DateTime time) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'isNight',
      args: <String, Object>{
        'coords': coords,
        'refTime': time.millisecondsSinceEpoch,
      },
    );

    return resultString['result'];
  }

  /// Returns a list of available map provider IDs present on the device.
  ///
  /// ## Returns
  ///
  /// - (`List<int>`) Integer IDs corresponding to [MapProviderId] values. The
  ///   list may be empty if no map data is present.
  @Deprecated('Use the mapProviderIds getter instead.')
  static List<int> getMapProviderIds() {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getMapProviderIds',
    );

    return (resultString['result'] as List<dynamic>).cast<int>();
  }

  /// Returns a list of available map provider IDs present on the device.
  ///
  /// ## Returns
  ///
  /// - (`List<int>`) Integer IDs corresponding to [MapProviderId] values. The
  ///   list may be empty if no map data is present.
  static List<int> get mapProviderIds {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getMapProviderIds',
    );

    return (resultString['result'] as List<dynamic>).cast<int>();
  }

  /// Returns the display name for a map provider.
  ///
  /// ## Parameters
  ///
  /// - [id]: (`MapProviderId`) Provider identifier.
  ///
  /// ## Returns
  ///
  /// - (`String`) Provider name.
  static String getProviderName(final MapProviderId id) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getProviderName',
      args: id.id,
    );

    return resultString['result'];
  }

  /// Returns the copyright or attribution sentence for a provider.
  ///
  /// Use this text when displaying attribution for map tiles or provider
  /// content.
  ///
  /// ## Parameters
  ///
  /// - [id]: (`MapProviderId`) Provider identifier.
  ///
  /// ## Returns
  ///
  /// - (`String`) Copyright/attribution sentence for the provider.
  static String getProviderSentence(final MapProviderId id) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getProviderSentence',
      args: id.id,
    );

    return resultString['result'];
  }

  /// Returns the set of extended map capabilities enabled for the current
  /// map data.
  ///
  /// ## Returns
  ///
  /// - (`Set<MapExtendedCapability>`) A set containing enabled capabilities.
  ///
  /// ## See also:
  ///
  /// - [MapExtendedCapability] - Enumeration of possible capabilities.
  static Set<MapExtendedCapability> getMapExtendedCapabilities() {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getMapExtendedCapabilities',
    );

    final int res = resultString['result'];
    final Set<MapExtendedCapability> result = <MapExtendedCapability>{};

    for (final MapExtendedCapability mode in MapExtendedCapability.values) {
      if (mode.id & res != 0) {
        result.add(mode);
      }
    }
    return result;
  }

  /// Returns the number of country entries available in the SDK.
  ///
  /// ## Returns
  ///
  /// - (`int`) Total count of country data entries.
  @Deprecated('Use the countryDataCount getter instead.')
  static int getCountryDataCount() {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getCountryDataCount',
    );

    return resultString['result'];
  }

  /// Returns the number of country entries available in the SDK.
  ///
  /// ## Returns
  ///
  /// - (`int`) Total count of country data entries.
  static int get countryDataCount {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getCountryDataCount',
    );

    return resultString['result'];
  }

  /// Returns the currently installed map data version.
  ///
  /// ## Returns
  ///
  /// - ([Version]) Version object describing the installed map data.
  ///
  /// ## Also see:
  ///
  /// - [latestOnlineMapVersion] - Retrieve the latest available online map version.
  static Version get mapVersion {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getMapVersion',
    );

    return Version.fromJson(resultString['result']);
  }

  /// Returns the latest available online map version known to the SDK.
  ///
  /// ## Returns
  ///
  /// - ([Version]) Latest online map version metadata.
  ///
  /// ## Also see:
  ///
  /// - [mapVersion] - Retrieve the currently installed map data version.
  static Version get latestOnlineMapVersion {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getLatestOnlineMapVersion',
    );

    return Version.fromJson(resultString['result']);
  }

  /// Returns the map release date/time in UTC.
  ///
  /// ## Returns
  ///
  /// - (`DateTime`) UTC timestamp representing the map release instant.
  @Deprecated('Use the mapReleaseInfo getter instead.')
  static DateTime getMapReleaseInfo() {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getMapReleaseInfo',
    );

    final Map<String, dynamic> result =
        resultString['result'] as Map<String, dynamic>;
    final int first = result['first'];

    return DateTime.fromMillisecondsSinceEpoch(first, isUtc: true);
  }

  /// Returns the map release date/time in UTC.
  ///
  /// ## Returns
  ///
  /// - (`DateTime`) UTC timestamp representing the map release instant.
  static DateTime get mapReleaseInfo {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getMapReleaseInfo',
    );

    final Map<String, dynamic> result =
        resultString['result'] as Map<String, dynamic>;
    final int first = result['first'];

    return DateTime.fromMillisecondsSinceEpoch(first, isUtc: true);
  }

  /// Returns country metadata for the supplied country ID.
  ///
  /// ## Parameters
  ///
  /// - [id]: (`int`) Internal country identifier.
  ///
  /// ## Returns
  ///
  /// - (`CountryData?`) A [CountryData] instance when available, otherwise
  ///   null.
  static CountryData? getCountryData(final int id) {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getCountryData',
      args: id,
    );

    if (resultString['gemApiError'] != 0) {
      return null;
    }

    if (resultString['result']['image'] == -1) {
      return CountryData(
        name: resultString['result']['name'],
        isoCode: resultString['result']['iso'],
      );
    }

    final Img image = Img.init(resultString['result']['image']);

    return CountryData(
      name: resultString['result']['name'],
      isoCode: resultString['result']['iso'],
      flagImage: image,
    );
  }

  /// Returns a list with metadata for all countries known to the SDK.
  ///
  /// ## Returns
  ///
  /// - (`List<CountryData>`) Country metadata objects. Image objects may be
  ///   null when a flag is not available for a country.
  static List<CountryData> get allCountriesData {
    final OperationResult resultString = staticMethod(
      'MapDetails',
      'getCountriesData',
    );

    final List<dynamic> results = resultString['result'];
    final List<CountryData> countries = <CountryData>[];

    for (final dynamic item in results) {
      final int imageId = item['image'] ?? -1;

      final Img? flagImage = imageId != -1 ? Img.init(imageId) : null;

      countries.add(
        CountryData(
          name: item['name'],
          isoCode: item['iso'],
          flagImage: flagImage,
        ),
      );
    }

    return countries;
  }
}
