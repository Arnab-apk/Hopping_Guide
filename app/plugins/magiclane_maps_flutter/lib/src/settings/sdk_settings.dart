// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui';

import 'package:magiclane_maps_flutter/content_store.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// SDK-level configuration and utility methods.
///
/// This class exposes global SDK settings such as unit system, language,
/// theme, caching limits and other runtime flags. Settings are global to the
/// running SDK instance and affect behavior for routing, navigation,
/// content updates and rendering.
///
/// {@category Settings}
abstract class SdkSettings {
  /// Returns the SDK-wide unit system.
  ///
  /// The unit system controls how distances and measurements are formatted in
  /// textual and spoken instructions (for example, kilometres vs miles).
  ///
  /// ## Returns
  ///
  /// - [UnitSystem]: the current unit system used by the SDK.
  static UnitSystem get unitSystem {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getUnitSystem',
    );

    return UnitSystemExtension.fromId(resultString['result']);
  }

  /// Sets the SDK-wide unit system.
  ///
  /// This affects route text, navigation instructions and voice output.
  ///
  /// ## Parameters
  ///
  /// - [unitSystem]: the [UnitSystem] to apply.
  static set unitSystem(UnitSystem unitSystem) {
    staticMethod('SdkSettings', 'setUnitSystem', args: unitSystem.id);
  }

  /// Returns the decimal separator used when formatting numbers.
  ///
  /// ## Returns
  ///
  /// - [String]: the currently configured decimal separator (for example "." or ",").
  static String get decimalSeparator {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getDecimalSeparator',
    );

    return resultString['result'];
  }

  /// Sets a custom decimal separator used for number formatting.
  ///
  /// ## Parameters
  ///
  /// - [sepatator]: the decimal separator string to use (for example ".").
  static set decimalSeparator(String sepatator) {
    staticMethod('SdkSettings', 'setDecimalSeparator', args: sepatator);
  }

  /// Returns the digit group (thousands) separator used for number formatting.
  ///
  /// ## Returns
  ///
  /// - [String]: the character used to separate digit groups (for example "," or " ").
  static String get digitGroupSeparator {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getDigitGroupSeparator',
    );

    return resultString['result'];
  }

  /// Sets the digit group (thousands) separator used for number formatting.
  ///
  /// ## Parameters
  ///
  /// - [sepatator]: the separator to use between digit groups.
  static set digitGroupSeparator(String sepatator) {
    staticMethod('SdkSettings', 'setDigitGroupSeparator', args: sepatator);
  }

  /// Returns whether offboard (internet) connections are allowed.
  ///
  /// ## Returns
  ///
  /// - [bool]: true when network access is allowed by the SDK settings.
  static bool get allowConnection {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getAllowConnection',
    );

    return resultString['result'];
  }

  static OffBoardListener? _offBoardListener;

  /// Returns the SDK-wide offboard listener instance.
  ///
  /// The offboard listener receives events related to worldwide road map
  /// updates and available content updates.
  ///
  /// ## Returns
  ///
  /// - [OffBoardListener]: the singleton offboard listener.
  static OffBoardListener get offBoardListener {
    _offBoardListener ??= OffBoardListener(true);
    return _offBoardListener!;
  }

  /// Enables or disables SDK access to the internet.
  ///
  /// When enabled, the SDK may perform offboard operations such as checking
  /// for content updates. Disabling internet access prevents those operations
  /// from starting.
  ///
  /// This function needs to be awaited as it may perform asynchronous operations.
  ///
  /// ## Parameters
  ///
  /// - [allowInternetConnection]: set true to allow SDK network access, false to block it.
  ///
  /// ## Also see:
  ///
  /// - [SdkSettings.allowConnection] - Query the current internet access setting.
  /// - [SdkSettings.offBoardListener] - Receiving events about content updates.
  /// - [NetworkProvider] - Managing network connectivity and status.
  static Future<void> setAllowInternetConnection(
    bool allowInternetConnection,
  ) async {
    GemKitPlatform.instance.registerEventHandler(
      offBoardListener.id,
      offBoardListener,
    );

    if (GemKitPlatform.instance.androidVersion > -1) {
      await GemKitPlatform.instance
          .getChannel(mapId: -1)
          .invokeMethod<bool>(
            'networkProviderCall',
            jsonEncode(<String, dynamic>{
              'action': 'setUserDisabledNetwork',
              'disabled': !allowInternetConnection,
            }),
          );
    } else {
      staticMethod(
        'SdkSettings',
        'setAllowConnection',
        args: <String, dynamic>{
          'allow': allowInternetConnection,
          'listener': offBoardListener.id,
        },
      );
    }

    _offBoardListener = offBoardListener;
    if (allowInternetConnection) {
      unawaited(NetworkProvider.refreshNetwork());
    }
  }

  /// Triggers automatic content updates according to the configured auto-update settings.
  ///
  /// Depending on the auto-update settings configured on the
  /// [SdkSettings.offBoardListener], this may initiate checks for roadmap, style,
  /// voice and car model updates and can trigger callbacks registered on
  /// [SdkSettings.offBoardListener].
  ///
  /// ## Returns
  ///
  /// - [GemError.success] when the update checks were started successfully.
  /// - [GemError.connectionRequired] when a network connection is required but
  ///   not available.
  static GemError autoUpdate() {
    if (offBoardListener.isAutoUpdateForRoadMapEnabled) {
      final GemError err = ContentStore.checkForUpdate(ContentType.roadMap);
      if (err != GemError.success) {
        return err;
      }
    }

    if (offBoardListener.isAutoUpdateForViewStyleHighResEnabled) {
      final GemError err = ContentStore.checkForUpdate(
        ContentType.viewStyleHighRes,
      );
      if (err != GemError.success) {
        return err;
      }
    }

    if (offBoardListener.isAutoUpdateForViewStyleLowResEnabled) {
      final GemError err = ContentStore.checkForUpdate(
        ContentType.viewStyleLowRes,
      );
      if (err != GemError.success) {
        return err;
      }
    }

    if (offBoardListener.isAutoUpdateForHumanVoiceEnabled) {
      final GemError err = ContentStore.checkForUpdate(ContentType.humanVoice);
      if (err != GemError.success) {
        return err;
      }
    }

    if (offBoardListener.isAutoUpdateForComputerVoiceEnabled) {
      final GemError err = ContentStore.checkForUpdate(
        ContentType.computerVoice,
      );
      if (err != GemError.success) {
        return err;
      }
    }

    if (offBoardListener.isAutoUpdateForCarModelEnabled) {
      final GemError err = ContentStore.checkForUpdate(ContentType.carModel);
      if (err != GemError.success) {
        return err;
      }
    }

    return GemError.success;
  }

  /// Internal reset used by tests to clear cached listeners. Not intended
  /// for SDK consumers.
  ///
  /// @nodoc
  @internal
  static void reset() {
    _offBoardListener = null;
  }

  /// Returns whether a service group type is allowed on metered (extra-charged) networks.
  ///
  /// ## Parameters
  ///
  /// - [serviceType]: the [ServiceGroupType] to query.
  ///
  /// ## Returns
  ///
  /// - [bool]: true when the service type is allowed on metered networks.
  ///
  /// ## Also see:
  ///
  /// - [SdkSettings.setAllowOffboardServiceOnExtraChargedNetwork] to enable or disable
  /// a service group on metered networks.
  static bool getAllowOffboardServiceOnExtraChargedNetwork(
    ServiceGroupType serviceType,
  ) {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getAllowOffboardServiceOnExtraChargedNetwork',
      args: serviceType.id,
    );

    return resultString['result'];
  }

  /// Enables or disables a service group on metered (extra-charged) networks.
  ///
  /// ## Parameters
  ///
  /// - [serviceType]: the [ServiceGroupType] to configure.
  /// - [allow]: true to allow the service type on metered networks, false to block it.
  ///
  /// ## Also see:
  ///
  /// - [getAllowOffboardServiceOnExtraChargedNetwork] to query the current setting.
  static void setAllowOffboardServiceOnExtraChargedNetwork(
    ServiceGroupType serviceType,
    bool allow,
  ) {
    staticMethod(
      'SdkSettings',
      'setAllowOffboardServiceOnExtraChargedNetwork',
      args: <String, Object>{'serviceType': serviceType.id, 'allow': allow},
    );
  }

  /// Returns the online service restrictions for a service group.
  ///
  /// ## Parameters
  ///
  /// - [serviceType]: the service group to query.
  ///
  /// ## Returns
  ///
  /// - [Set<OnlineRestrictions>]: the set of restrictions currently configured.
  static Set<OnlineRestrictions> getOnlineServiceRestriction(
    ServiceGroupType serviceType,
  ) {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getOnlineServiceRestriction',
      args: serviceType.id,
    );

    final int packed = resultString['result'];

    return OnlineRestrictions.values
        .where((OnlineRestrictions element) => (packed & element.id) != 0)
        .toSet();
  }

  /// Returns topic notification service restrictions for a service group.
  ///
  /// ## Parameters
  ///
  /// - [serviceType]: the service group to query.
  ///
  /// ## Returns
  ///
  /// - [Set<OnlineRestrictions>]: the set of restrictions currently configured.
  static Set<OnlineRestrictions> getTopicNotificationsServiceRestriction(
    ServiceGroupType serviceType,
  ) {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getTopicNotificationsServiceRestriction',
      args: serviceType.id,
    );

    final int packed = resultString['result'];

    return OnlineRestrictions.values
        .where((OnlineRestrictions element) => (packed & element.id) != 0)
        .toSet();
  }

  /// Returns the currently selected API language.
  ///
  /// ## Returns
  ///
  /// - [Language]: the active language used by the SDK API.
  ///
  /// ## Also see:
  ///
  /// - [getBestLanguageMatch] - Find the best matching language for given codes.
  /// - [setTTSVoiceByLanguage] - Set the TTS voice (used by text-to-speech) by language.
  static Language get language {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getLanguage',
    );

    return Language.fromJson(resultString['result']);
  }

  /// Finds the best language match for the provided codes and variant.
  ///
  /// The method attempts to match language, region, script and variant to an
  /// SDK-supported [Language]. If no suitable match exists an explicit `null`
  /// is returned.
  ///
  /// ## Parameters
  ///
  /// - [languageCode]: ISO 639-3 three-letter language code.
  /// - [regionCode]: ISO 3166-1_3 three-letter region code (optional).
  /// - [scriptCode]: ISO 15924 four-letter script code (optional).
  /// - [variant]: a [ScriptVariant] indicating the script variant to prefer.
  ///
  /// ## Returns
  ///
  /// - [Language?]: the matched language or `null` when no match is available.
  ///
  /// ## Also see:
  ///
  /// - [language] - Get the currently selected API language.
  /// - [setTTSVoiceByLanguage] - Set the TTS voice (used by text-to-speech) by language.
  static Language? getBestLanguageMatch(
    String languageCode, {
    String regionCode = '',
    String scriptCode = '',
    ScriptVariant variant = ScriptVariant.native,
  }) {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getBestLanguageMatch',
      args: <String, Object>{
        'languageCode': languageCode,
        'regionCode': regionCode,
        'scriptCode': scriptCode,
        'variant': variant.id,
      },
    );

    final Language result = Language.fromJson(resultString['result']);
    if (result.name.isEmpty) {
      return null;
    }
    return result;
  }

  /// Returns transfer statistics for SDK network usage.
  ///
  /// Returns a [TransferStatistics] object containing counters and metrics
  /// about network usage performed by the traffic service. This information
  /// can be used for diagnostics or to display usage to end users.
  ///
  /// ## Returns
  ///
  /// - [TransferStatistics]: the current transfer statistics snapshot.
  static TransferStatistics get transferStatistics {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getTransferStatistics',
    );

    return TransferStatistics.init(resultString['result']);
  }

  /// Returns the list of languages supported by the SDK API.
  ///
  /// ## Returns
  ///
  /// - [List<Language>]: available languages.
  ///
  /// ## Also see:
  ///
  /// - [getBestLanguageMatch] - Find the best matching language for given codes.
  /// - [setTTSVoiceByLanguage] - Set the TTS voice (used by text-to-speech) by language.
  static List<Language> get languageList {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getLanguageList',
    );

    final List<dynamic> categoriesJson = resultString['result'];
    final List<Language> categories = categoriesJson
        .map((dynamic categoryJson) => Language.fromJson(categoryJson))
        .toList();
    return categories;
  }

  /// Sets the SDK API language.
  ///
  /// This affects map labels, routing instructions and other
  /// API-generated text.
  ///
  /// This does not affect the current voice.
  /// The API user is responsible for setting the desired TTS voice
  /// separately via [setTTSVoiceByLanguage] or [setVoiceByPath].
  ///
  /// ## Parameters
  ///
  /// - [language]: the [Language] to set as the active API language.
  static set language(Language language) {
    staticMethod('SdkSettings', 'setLanguage', args: language);
  }

  /// Returns the current map language selection method.
  ///
  /// ## Returns
  ///
  /// - [MapLanguage]: how map labels are selected (automatic or native).
  static MapLanguage get mapLanguage {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getMapLanguage',
    );

    return MapLanguageExtension.fromId(resultString['result']);
  }

  /// Sets the map language selection method.
  ///
  /// ## Parameters
  ///
  /// - [mapLanguage]: the [MapLanguage] selection mode.
  static set mapLanguage(MapLanguage mapLanguage) {
    staticMethod('SdkSettings', 'setMapLanguage', args: mapLanguage.id);
  }

  /// Sets the maximum cache/storage size for downloaded tiles (in kilobytes).
  ///
  /// ## Parameters
  ///
  /// - [maxSpace]: size in KB. A value of `0` means no space restriction.
  static set tilesMaxSpace(int maxSpace) {
    staticMethod('SdkSettings', 'setTilesMaxSpace', args: maxSpace);
  }

  /// Returns the maximum tile cache/storage size in kilobytes.
  ///
  /// ## Returns
  ///
  /// - [int]: configured maximum size in KB.
  static int get tilesMaxSpace {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getTilesMaxSpace',
    );

    return resultString['result'];
  }

  /// Sets the application name exposed to the SDK.
  ///
  /// ## Parameters
  ///
  /// - [name]: the application name string.
  static set applicationName(String name) {
    staticMethod('SdkSettings', 'setApplicationName', args: name);
  }

  /// Returns the configured application name.
  ///
  /// ## Returns
  ///
  /// - [String]: the application name.
  static String get applicationName {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getApplicationName',
    );

    return resultString['result'];
  }

  /// Sets the application version information exposed to the SDK.
  ///
  /// ## Parameters
  ///
  /// - [version]: major version number.
  /// - [subVersion]: minor/sub-version number.
  /// - [revision]: revision value (treated as unsigned hex when reading back).
  @Deprecated('Use SdkSettings.setApplicationVersion instead')
  static void setSdkVersion(int version, int subVersion, int revision) {
    staticMethod(
      'SdkSettings',
      'setApplicationVersion',
      args: <String, int>{
        'first': version,
        'second': subVersion,
        'third': revision,
      },
    );
  }

  /// Sets the application version information exposed to the SDK.
  ///
  /// ## Parameters
  ///
  /// - [version]: major version number.
  /// - [subVersion]: minor/sub-version number.
  /// - [revision]: revision value (treated as unsigned hex when reading back).
  static void setApplicationVersion(int version, int subVersion, int revision) {
    staticMethod(
      'SdkSettings',
      'setApplicationVersion',
      args: <String, int>{
        'first': version,
        'second': subVersion,
        'third': revision,
      },
    );
  }

  /// Returns the application version as a human-readable string.
  ///
  /// The returned format is `major.minor.revision` where `revision` is shown
  /// as an uppercase hexadecimal string.
  ///
  /// It is used to store the application version set via [setApplicationVersion].
  /// If no version was set, the returned string will be the [sdkVersion] except the year and week part.
  ///
  /// ## Returns
  ///
  /// - [String]: the formatted SDK version (for example `0.1.AB12`).
  static String get applicationVersion {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getApplicationVersion',
    );

    final dynamic resultMap = resultString['result'];
    final int first = resultMap['first'];
    final int second = resultMap['second'];

    final int third = resultMap['third'];
    final int unsignedValue = third & 0xFFFFFFFF;
    final String hexValue = unsignedValue.toRadixString(16).toUpperCase();

    return '$first.$second.$hexValue';
  }

  /// Returns the SDK version as a human-readable string.
  ///
  /// The returned format is `major.minor.year.week.revision`
  ///
  /// ## Returns
  ///
  /// - [String]: the formatted SDK version (for example `7.1.25.46.4923803B`).
  static String get sdkVersion {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getSdkVersion',
    );

    return resultString['result'];
  }

  /// Sets the device name reported to the SDK.
  ///
  /// ## Parameters
  ///
  /// - [name]: the device name string.
  static set deviceName(String name) {
    staticMethod('SdkSettings', 'setDeviceName', args: name);
  }

  /// Returns the configured device name.
  ///
  /// ## Returns
  ///
  /// - [String]: device name.
  static String get deviceName {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getDeviceName',
    );

    return resultString['result'];
  }

  /// Sets the device model string reported to the SDK.
  ///
  /// ## Parameters
  ///
  /// - [model]: the device model string.
  static set deviceModel(String model) {
    staticMethod('SdkSettings', 'setDeviceModel', args: model);
  }

  /// Returns the device model configured for the SDK.
  ///
  /// ## Returns
  ///
  /// - [String]: device model.
  static String get deviceModel {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getDeviceModel',
    );

    return resultString['result'];
  }

  /// Selects the default TTS (computer) voice by language.
  ///
  /// The SDK will try to pick the best available voice that matches the
  /// provided [language].
  ///
  /// ## Parameters
  ///
  /// - [language]: the preferred voice language.
  ///
  /// ## Returns
  ///
  /// - [GemError]: [GemError.success] on success, otherwise an error code
  ///   describing why the voice could not be set.
  static GemError setTTSVoiceByLanguage(Language language) {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'setVoice',
      args: language,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Sets the TTS/computer voice by absolute file path.
  ///
  /// Providing [language] helps the SDK choose the best matching voice when
  /// interacting with platform TTS capabilities.
  ///
  /// ## Parameters
  ///
  /// - [path]: absolute path to the voice file.
  /// - [language]: optional [Language] to guide voice selection.
  ///
  /// ## Returns
  ///
  /// - [GemError]: [GemError.success] on success, otherwise an error code.
  ///
  /// ## Also see:
  ///
  /// - [setTTSVoiceByLanguage] - Set the TTS voice by language.
  /// - [voice] - Get the currently selected voice.
  static GemError setVoiceByPath(String path, {Language? language}) {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'setVoiceByPath',
      args: <String, dynamic>{
        'filePath': path,
        'lang': language ?? Language(name: 'noLang'),
      },
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Returns the currently selected [Voice] object.
  ///
  /// ## Returns
  ///
  /// - [Voice]: the active voice instance.
  ///
  /// ## Also see:
  ///
  /// - [setTTSVoiceByLanguage] - Set the TTS voice by language.
  @Deprecated('Use voice getter instead')
  static Voice getVoice() {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getVoice',
    );

    return Voice.init(resultString['result']);
  }

  /// Returns the currently selected [Voice] object.
  ///
  /// ## Returns
  ///
  /// - [Voice]: the active voice instance.
  ///
  /// ## Also see:
  ///
  /// - [setTTSVoiceByLanguage] - Set the TTS voice by language.
  static Voice get voice {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getVoice',
    );

    return Voice.init(resultString['result']);
  }

  /// Sets the application authorization API token used by the SDK.
  ///
  /// The SDK must be initialized before setting the token; otherwise a
  /// [GemKitUninitializedException] is thrown.
  ///
  /// The token is typically passed at the time of SDK initialization via
  /// [GemKit.initialize] but can be updated later.
  ///
  /// ## Parameters
  ///
  /// - [token]: API token (JWT or other scheme accepted by the SDK).
  ///
  /// ## Also see:
  ///
  /// - [verifyAppAuthorization] - Validate an authorization token.
  static set appAuthorization(String token) {
    if (isSDkInitialized) {
      staticMethod(
        'SdkSettings',
        'setAppAuthorization',
        args: token,
        logPrivacyLevel: LogPrivacyLevel.hideArgumentValues,
      );
    } else {
      throw GemKitUninitializedException();
    }
  }

  /// Returns the configured application authorization API token.
  ///
  /// Returns an empty string when no valid token is set.
  ///
  /// ## Returns
  ///
  /// - [String]: the API token or empty string.
  ///
  /// ## Also see:
  ///
  /// - [verifyAppAuthorization] - Validate an authorization token.
  static String get appAuthorization {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getAppAuthorization',
      logPrivacyLevel: LogPrivacyLevel.hideArgumentValues,
    );

    return resultString['result'];
  }

  /// Validates an application authorization token and reports the result via a callback.
  ///
  /// The validation process is asynchronous; the provided callback is invoked
  /// once validation completes with a [GemError] that indicates the result.
  ///
  /// ## Parameters
  ///
  /// - [token]: the token to validate (typically a JWT).
  /// - [callback]: a function invoked with a [GemError] describing the
  ///   validation outcome. Typical values include:
  ///   - [GemError.success] — token is valid.
  ///   - [GemError.invalidInput] — token was malformed.
  ///   - [GemError.expired] — token has expired.
  ///   - [GemError.accessDenied] — token is blacklisted or otherwise denied.
  ///
  /// ## Example
  ///
  /// ```dart
  /// SdkSettings.verifyAppAuthorization(token, (status) {
  ///   switch (status) {
  ///     case GemError.success:
  ///       print('The token is set and is valid.');
  ///       break;
  ///     case GemError.invalidInput:
  ///       print('The token is invalid.');
  ///       break;
  ///     case GemError.expired:
  ///       print('The token is expired.');
  ///       break;
  ///     case GemError.accessDenied:
  ///       print('The token is blacklisted.');
  ///       break;
  ///     default:
  ///       print('Other error regarding token validation : $status.');
  ///       break;
  ///   }
  /// });
  /// ```
  static void verifyAppAuthorization(
    String token,
    void Function(GemError err) callback,
  ) {
    final EventDrivenProgressListener listener = EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);
    listener.registerOnCompleteWithData((
      int err,
      String hint,
      Map<dynamic, dynamic> json,
    ) {
      callback(GemErrorExtension.fromCode(err));
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
    });
    staticMethod(
      'SdkSettings',
      'verifyAppAuthorization',
      args: <String, dynamic>{'token': token, 'listener': listener.id},
      logPrivacyLevel: LogPrivacyLevel.hideArgumentValues,
    );
  }

  /// Returns the configured app theme used for image and text rendering.
  ///
  /// The default is [AppTheme.automatic].
  ///
  /// ## Returns
  ///
  /// - [AppTheme]: the configured theme.
  static AppTheme get appTheme {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getTheme',
    );

    return AppThemeExtension.fromId(resultString['result']);
  }

  /// Returns the actual theme currently in effect.
  ///
  /// When the SDK theme is set to [AppTheme.automatic], this returns the
  /// actual resolved theme ([AppTheme.dark] or [AppTheme.light]).
  ///
  /// ## Returns
  ///
  /// - [AppTheme]: the actual theme in use.
  static AppTheme get actualAppTheme {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getActualTheme',
    );

    return AppThemeExtension.fromId(resultString['result']);
  }

  /// Sets the images and text rendering theme.
  ///
  /// ## Parameters
  ///
  /// - [theme]: the [AppTheme] to apply.
  static set appTheme(AppTheme theme) {
    staticMethod('SdkSettings', 'setTheme', args: theme.id);
  }

  /// Returns the raw image bytes for the given image id.
  ///
  /// ## Parameters
  ///
  /// - [id]: image identifier.
  /// - [size]: optional desired image [Size]. If omitted the SDK default is used.
  /// - [format]: optional [ImageFileFormat]. If omitted the SDK default is used.
  ///
  /// ## Returns
  ///
  /// - [Uint8List?]: the image bytes, or `null` when no image exists for [id].
  ///
  /// ## Also see:
  ///
  /// - [SdkSettings.setDefaultWidthHeightImageFormat] - Set the SDK default size and format.
  /// - [SdkSettings.getImgById] - Get an [Img] wrapper for the image.
  static Uint8List? getImageById({
    required int id,
    Size? size,
    ImageFileFormat? format,
  }) {
    return GemKitPlatform.instance.callGetImage(
      id,
      'SdkSettingsgetImageById',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
      imageId: id,
    );
  }

  /// Get the image as a [Img].
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getImageById] when you only need raw image bytes.
  ///
  /// ## Parameters
  ///
  /// - [id]: image identifier.
  ///
  /// ## Returns
  ///
  /// - [Img?]: an [Img] instance when the image exists, or `null` otherwise.
  ///
  /// ## Also see:
  ///
  /// - [getImageById] - Get the raw image bytes.
  static Img? getImgById(int id) {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getImgById',
      args: id,
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return Img.init(resultString['result']);
  }

  /// Returns true when the SDK has been initialized.
  ///
  /// ## Returns
  ///
  /// - [bool]: true when the SDK is initialized and ready to use.
  static bool get isSDkInitialized {
    return GemKitPlatform.instance.isSdkInitialized;
  }

  // static set networkProvider(NetworkProvider networkProvider) {
  //   GemKitPlatform.instance
  //       .registerEventHandler(networkProvider.id, networkProvider);
  //   GemKitPlatform.instance.callObjectMethod(jsonEncode({
  //     'id': 0,
  //     'SdkSettings',
  //     'setNetworkProvider',
  //     'args': networkProvider.id
  //   );
  // }

  /// Sets the SDK default image width, height and format used when the
  /// platform returns images automatically.
  ///
  /// ## Parameters
  ///
  /// - [size]: the desired [Size] (width and height in logical pixels).
  /// - [format]: the [ImageFileFormat] to use. Defaults to [ImageFileFormat.png].
  static void setDefaultWidthHeightImageFormat(
    Size size, {
    ImageFileFormat format = ImageFileFormat.png,
  }) {
    staticMethod(
      'DefaultWidthHeightImageFormat',
      'set',
      args: <String, num>{
        'width': size.width,
        'height': size.height,
        'format': format.id,
      },
    );
  }

  /// Returns the SDK default image size and format used for automatically
  /// returned images.
  ///
  /// ## Returns
  ///
  /// - [SizeAndFormat]: configured default size and format.
  static SizeAndFormat getDefaultWidthHeightImageFormat() {
    final OperationResult resultString = staticMethod(
      'DefaultWidthHeightImageFormat',
      'get',
    );

    return SizeAndFormat(
      size: Size(
        resultString['width'].toDouble(),
        resultString['height'].toDouble(),
      ),
      format: ImageFileFormatExtension.fromId(resultString['format']),
    );
  }

  /// Returns whether the current Dart thread is the main/UI thread.
  ///
  /// ## Returns
  ///
  /// - [bool]: true when running on the main thread.
  static bool get isCurrentThreadMainThread {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'isCurrentThreadMainThread',
    );

    return resultString['result'];
  }

  /// Returns the set of capabilities enabled in the current SDK build.
  ///
  /// ## Returns
  ///
  /// - [Set<SdkCapability>]: features available in this SDK binary.
  static Set<SdkCapability> get capabilities {
    final OperationResult resultString = staticMethod(
      'SdkSettings',
      'getCapabilities',
    );

    final int packed = resultString['result'];

    return SdkCapability.values
        .where((SdkCapability element) => (packed & element.id) != 0)
        .toSet();
  }

  /// Returns the set of capabilities enabled in the current SDK build.
  @Deprecated('Use capabilities getter instead')
  static Set<SdkCapability> get capabilitties => capabilities;
}
