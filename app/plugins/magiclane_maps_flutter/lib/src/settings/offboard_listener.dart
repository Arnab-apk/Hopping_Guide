// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/content_store.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';
import 'package:meta/meta.dart';

/// Expired Content
///
/// Describes content that has expired and is no longer valid.
/// Usually returned by the [OffBoardListener] when offline content versions differ from the current worldwide map.
///
/// {@category Settings}
class ExpiredContent {
  ExpiredContent(this.version, this.path);

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory ExpiredContent.fromJson(final Map<String, dynamic> json) {
    return ExpiredContent(
      Version(encodedVersion: json['version']),
      json['path'],
    );
  }

  /// Content version
  Version version;

  /// Content path
  String path;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpiredContent &&
          runtimeType == other.runtimeType &&
          version == other.version &&
          path == other.path;

  @override
  int get hashCode => Object.hash(version, path);
}

/// Listener receiving offboard/content-related events from the SDK.
///
/// [OffBoardListener] delivers notifications about connectivity, content updates,
/// resource deployment and auto-update progress. Register callbacks using the
/// `registerOn*` methods to receive these events. Use [SdkSettings.offBoardListener]
/// to obtain the singleton instance used by the SDK.
///
/// ## See also:
///
/// - [ContentStore] — APIs that trigger many of the content-related callbacks delivered by this listener.
/// - [SdkSettings.offBoardListener] — Obtain the global offboard listener instance.
///
/// {@category Settings}
class OffBoardListener extends EventHandler {
  @internal
  factory OffBoardListener(final bool canDoAutoUpdate) =>
      OffBoardListener._create(canDoAutoUpdate);

  @internal
  OffBoardListener.init(this.id);

  void Function(bool isConnected)? _onConnectionStatusUpdatedCallback;
  void Function(ServiceGroupType type, bool isConnected)?
  _onConnectionStatusUpdated2Callback;
  void Function(bool isTopicNotificationsEnabled)?
  _onTopicNotificationsStatusUpdatedCallback;
  void Function(Reason reason)? _onWorldwideRoadMapSupportDisabledCallback;
  void Function(ContentStoreStatus state)?
  _onWorldwideRoadMapSupportStatusCallback;
  void Function()? _onWorldwideRoadMapSupportEnabledCallback;
  void Function()? _onResourcesReadyToDeployCallback;
  void Function(int size)? _onOnlineCacheSizeChangeCallback;
  void Function()? _onWorldwideRoadMapVersionUpdatedCallback;
  void Function(ContentType contentType, ContentStoreStatus statusCode)?
  _onAvailableContentUpdateCallback;
  void Function(ContentType type, List<ExpiredContent> status)?
  _onExpiredContentCallback;
  void Function()? _onWorldwideRoadMapRefreshedCallback;
  void Function()? _onWorldwideRoadMapUnsupportedCapabilitiesCallback;
  void Function()? _onApiTokenRejectedCallback;
  void Function()? _onApiTokenUpdatedCallback;
  void Function(bool loggedIn)? _onLoginStatusUpdatedCallback;

  dynamic id;

  static OffBoardListener _create(final bool canDoAutoUpdateResources) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'OffBoardListener',
        'args': canDoAutoUpdateResources,
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return OffBoardListener.init(decodedVal['result']);
  }

  /// Notifies that the general connection status changed.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with a single boolean argument indicating whether
  ///   the connection to online services is currently established (`true`) or not (`false`).
  void registerOnConnectionStatusUpdated(
    final void Function(bool isConnected)? callback,
  ) {
    _onConnectionStatusUpdatedCallback = callback;
  }

  /// Notifies that the connection status changed for a specific service group.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with two arguments:
  ///   - [ServiceGroupType] service group type.
  ///   - [bool] whether the service group is connected.
  void registerOnConnectionStatusUpdated2(
    final void Function(ServiceGroupType serviceType, bool isConnected)?
    callback,
  ) {
    _onConnectionStatusUpdated2Callback = callback;
  }

  /// Notifies that the topic notifications service status changed.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with a single boolean argument indicating whether
  ///   topic notifications are enabled.
  void registerOnTopicNotificationsStatusUpdated(
    final void Function(bool isNotifying)? callback,
  ) {
    _onTopicNotificationsStatusUpdatedCallback = callback;
  }

  /// Notifies that worldwide road map support has been disabled.
  ///
  /// The callback receives a [Reason] describing why the support was disabled.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with a single [Reason] argument explaining why support
  ///   was disabled.
  ///
  /// ## See also:
  ///
  /// - [ExpiredContent] — Details of expired offline content when available.
  void registerOnWorldwideRoadMapSupportDisabled(
    final void Function(Reason reason)? callback,
  ) {
    _onWorldwideRoadMapSupportDisabledCallback = callback;
  }

  /// Notifies about the worldwide road map data state.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with a [ContentStoreStatus] describing the current
  ///   worldwide road map support state.
  void registerOnWorldwideRoadMapSupportStatus(
    final void Function(ContentStoreStatus status)? callback,
  ) {
    _onWorldwideRoadMapSupportStatusCallback = callback;
  }

  /// Notifies that worldwide road map support is enabled.
  ///
  /// This callback is invoked when the SDK regains access to worldwide road map data
  /// and related features (routing, traffic) become available.
  void registerOnWorldwideRoadMapSupportEnabled(
    final void Function()? callback,
  ) {
    _onWorldwideRoadMapSupportEnabledCallback = callback;
  }

  /// Notifies that application resources are ready to be deployed.
  ///
  /// Register this callback to receive a notification when downloaded resources are
  /// available and the application can safely deploy them.
  void registerOnResourcesReadyToDeploy(final void Function()? callback) {
    _onResourcesReadyToDeployCallback = callback;
  }

  /// Notifies that the offboard cache size changed.
  ///
  /// The callback receives the new cache size in kilobytes (KB).
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with a single `int` argument containing the new cache
  ///   size in KB.
  void registerOnOnlineCacheSizeChange(
    final void Function(int size)? callback,
  ) {
    _onOnlineCacheSizeChangeCallback = callback;
  }

  /// Notifies that the worldwide road map version was updated.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with no arguments when the worldwide road map version
  ///   is updated.
  ///
  /// ## See also:
  ///
  /// - [MapDetails] - Details of the current map version.
  void registerOnWorldwideRoadMapVersionUpdated(
    final void Function()? callback,
  ) {
    _onWorldwideRoadMapVersionUpdatedCallback = callback;
  }

  /// Notifies about available content updates.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with two arguments:
  ///   - [ContentType] indicating which content type updated.
  ///   - [ContentStoreStatus] describing the new content state.
  void registerOnAvailableContentUpdate(
    final void Function(ContentType type, ContentStoreStatus status)? callback,
  ) {
    _onAvailableContentUpdateCallback = callback;
  }

  /// Notifies about expired content.
  ///
  /// This callback is triggered when offline content versions differ from the current
  /// worldwide map (WorldMap). The callback provides a list of [ExpiredContent] entries
  /// describing the mismatched packages.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with two arguments:
  ///   - [ContentType] the content kind affected (for example [ContentType.roadMap]).
  ///   - `List<ExpiredContent>` details of expired content packages.
  void registerOnExpiredContent(
    final void Function(ContentType type, List<ExpiredContent> content)?
    callback,
  ) {
    _onExpiredContentCallback = callback;
  }

  /// Notifies that the worldwide road map has been refreshed.
  ///
  /// This callback is triggered when offline regions are added or removed.
  /// This type of callback is temporarily unavailable on Android.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with no arguments when the worldwide road map is refreshed.
  void registerOnWorldwideRoadMapRefreshed(final void Function()? callback) {
    _onWorldwideRoadMapRefreshedCallback = callback;
  }

  /// Notifies that the current SDK does not support all worldwide road map capabilities.
  ///
  /// This indicates that while a newer worldwide map version may be available, some
  /// advanced capabilities are disabled due to SDK limitations.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with no arguments when the worldwide road map version
  ///   is updated.
  void registerOnWorldwideRoadMapUnsupportedCapabilities(
    final void Function()? callback,
  ) {
    _onWorldwideRoadMapUnsupportedCapabilitiesCallback = callback;
  }

  /// Notifies that the current API token was rejected.
  ///
  /// This indicates that network requests requiring the API token will fail until a
  /// valid token is provided. Check token availability or contact MagicLane support.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with no arguments when the API token is rejected.
  ///
  /// ## See also:
  ///
  /// - [SdkSettings.appAuthorization] — Manage the API token used by the SDK.
  void registerOnApiTokenRejected(final void Function()? callback) {
    _onApiTokenRejectedCallback = callback;
  }

  /// Notifies that the current API token was updated.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with no arguments when the API token is updated.
  ///
  /// ## See also:
  ///
  /// - [SdkSettings.appAuthorization] — Manage the API token used by the SDK.
  void registerOnApiTokenUpdated(final void Function()? callback) {
    _onApiTokenUpdatedCallback = callback;
  }

  /// Notifies that social login state changed.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called with a single boolean argument: `true` when the
  ///   user is logged in, `false` otherwise.
  void registerOnLoginStatusUpdated(
    final void Function(bool isLoggedIn)? callback,
  ) {
    _onLoginStatusUpdatedCallback = callback;
  }

  @override
  void nativeClear() {
    // No native-side cleanup required for this listener.
  }

  @override
  void clearListeners() {
    _onConnectionStatusUpdatedCallback = null;
    _onConnectionStatusUpdated2Callback = null;
    _onTopicNotificationsStatusUpdatedCallback = null;
    _onWorldwideRoadMapSupportDisabledCallback = null;
    _onWorldwideRoadMapSupportStatusCallback = null;
    _onWorldwideRoadMapSupportEnabledCallback = null;
    _onResourcesReadyToDeployCallback = null;
    _onOnlineCacheSizeChangeCallback = null;
    _onWorldwideRoadMapVersionUpdatedCallback = null;
    _onAvailableContentUpdateCallback = null;
    _onExpiredContentCallback = null;
    _onWorldwideRoadMapRefreshedCallback = null;
    _onWorldwideRoadMapUnsupportedCapabilitiesCallback = null;
    _onApiTokenRejectedCallback = null;
    _onApiTokenUpdatedCallback = null;
    _onLoginStatusUpdatedCallback = null;
    _onAutoUpdateComplete = null;
  }

  @override
  void handleEvent(final Map<dynamic, dynamic> arguments) {
    final String eventSubtype = arguments['event_subtype'];

    switch (eventSubtype) {
      case 'onConnectionStatusUpdated':
        if (_onConnectionStatusUpdatedCallback != null) {
          _onConnectionStatusUpdatedCallback!(arguments['connected']);
        }

      case 'onConnectionStatusUpdated2':
        if (_onConnectionStatusUpdated2Callback != null) {
          _onConnectionStatusUpdated2Callback!(
            ServiceGroupType.values[arguments['svc']],
            arguments['connected'],
          );
        }

      case 'onTopicNotificationsStatusUpdated':
        if (_onTopicNotificationsStatusUpdatedCallback != null) {
          _onTopicNotificationsStatusUpdatedCallback!(arguments['available']);
        }

      case 'onWorldwideRoadMapSupportDisabled':
        if (_onWorldwideRoadMapSupportDisabledCallback != null) {
          _onWorldwideRoadMapSupportDisabledCallback!(
            Reason.values[arguments['reason']],
          );
        }

      case 'onWorldwideRoadMapSupportStatus':
        if (_onWorldwideRoadMapSupportStatusCallback != null) {
          _onWorldwideRoadMapSupportStatusCallback!(
            ContentStoreStatus.values[arguments['state']],
          );
        }
        _onWorldwideRoadMapSupportStatusCallbackAutoUpdate(
          ContentStoreStatus.values[arguments['state']],
        );

      case 'onWorldwideRoadMapSupportEnabled':
        if (_onWorldwideRoadMapSupportEnabledCallback != null) {
          _onWorldwideRoadMapSupportEnabledCallback!();
        }

      case 'onResourcesReadyToDeploy':
        if (_onResourcesReadyToDeployCallback != null) {
          _onResourcesReadyToDeployCallback!();
        }

      case 'onOnlineCacheSizeChange':
        if (_onOnlineCacheSizeChangeCallback != null) {
          _onOnlineCacheSizeChangeCallback!(arguments['size']);
        }

      case 'onWorldwideRoadMapVersionUpdated':
        if (_onWorldwideRoadMapVersionUpdatedCallback != null) {
          _onWorldwideRoadMapVersionUpdatedCallback!();
        }

      case 'onAvailableContentUpdate':
        if (_onAvailableContentUpdateCallback != null) {
          _onAvailableContentUpdateCallback!(
            ContentTypeExtension.fromId(arguments['type']),
            ContentStoreStatus.values[arguments['state']],
          );
        }
        _onAvailableContentUpdateCallbackAutoUpdate(
          ContentTypeExtension.fromId(arguments['type']),
          ContentStoreStatus.values[arguments['state']],
        );

      case 'onExpiredContent':
        if (_onExpiredContentCallback != null) {
          _onExpiredContentCallback!(
            ContentTypeExtension.fromId(arguments['type']),
            arguments['expiredContent']
                .map<ExpiredContent>(
                  (dynamic e) =>
                      ExpiredContent.fromJson(e as Map<String, dynamic>),
                )
                .toList(),
          );
        }

      case 'onWorldwideRoadMapRefreshed':
        if (_onWorldwideRoadMapRefreshedCallback != null) {
          _onWorldwideRoadMapRefreshedCallback!();
        }

      case 'onWorldwideRoadMapUnsupportedCapabilities':
        if (_onWorldwideRoadMapUnsupportedCapabilitiesCallback != null) {
          _onWorldwideRoadMapUnsupportedCapabilitiesCallback!();
        }

      case 'onApiTokenRejected':
        if (_onApiTokenRejectedCallback != null) {
          _onApiTokenRejectedCallback!();
        }

      case 'onApiTokenUpdated':
        if (_onApiTokenUpdatedCallback != null) {
          _onApiTokenUpdatedCallback!();
        }

      case 'onLoginStatusUpdated':
        if (_onLoginStatusUpdatedCallback != null) {
          _onLoginStatusUpdatedCallback!(arguments['loggedIn']);
        }

      default:
        gemSdkLogger.log(
          Level.WARNING,
          'Unknown event subtype: $eventSubtype in OffboardListener',
        );
    }
  }

  /// Verifies that application resources update is allowed. Returning true will allow the SDK to download and prepare the latest resources
  ///
  /// Only available on iOS and Web platforms. On Android, this property always returns true and has no effect.
  /// Auto update of resources is always enabled on Android.
  ///
  /// ## Returns
  ///
  /// - true if the resources update is allowed, false otherwise
  ///
  /// ## Also see:
  ///
  /// - [AutoUpdateSettings.isAutoUpdateForResourcesEnabled] - Settings for auto update of resources passed at the SDK initialization
  bool get isAutoUpdateForResourcesEnabled {
    if (Debug.androidVersion == -1) {
      final OperationResult resultString = objectMethod(
        id,
        'OffboardListener',
        'isResourcesUpdateAllowed',
      );

      return resultString['result'];
    } else {
      return true;
    }
  }

  /// Sets the resources update allowed flag
  ///
  /// Only available on iOS and Web platforms. On Android, this property has no effect.
  /// Auto update of resources is always enabled on Android.
  ///
  /// ## Parameters
  ///
  /// - [value]: True if the resources update is allowed, false otherwise.
  ///
  /// ## Also see:
  ///
  /// - [AutoUpdateSettings.isAutoUpdateForResourcesEnabled] - Settings for auto update of resources passed at the SDK initialization
  set isAutoUpdateForResourcesEnabled(bool value) {
    if (Debug.androidVersion == -1) {
      objectMethod(
        id,
        'OffboardListener',
        'setIsResourcesUpdateAllowed',
        args: value,
      );
    } else {
      return;
    }
  }

  /// Whether the update for the road maps is enabled
  ///
  /// ## Also see:
  ///
  /// - [AutoUpdateSettings.isAutoUpdateForRoadMapEnabled] - Settings for auto update of road maps passed at the SDK initialization
  bool isAutoUpdateForRoadMapEnabled = true;

  /// Whether the update for the map styles high resolution is enabled
  ///
  /// ## Also see:
  ///
  /// - [AutoUpdateSettings.isAutoUpdateForViewStyleHighResEnabled] - Settings for auto update of high resolution map styles passed at the SDK initialization
  bool isAutoUpdateForViewStyleHighResEnabled = true;

  /// Whether the update for the map styles low resolution is enabled
  ///
  /// ## Also see:
  ///
  /// - [AutoUpdateSettings.isAutoUpdateForViewStyleLowResEnabled] - Settings for auto update of low resolution map styles passed at the SDK initialization
  bool isAutoUpdateForViewStyleLowResEnabled = true;

  /// Whether the update for the human voices is enabled
  ///
  /// ## Also see:
  ///
  /// - [AutoUpdateSettings.isAutoUpdateForHumanVoiceEnabled] - Settings for auto update of human voices passed at the SDK initialization
  bool isAutoUpdateForHumanVoiceEnabled = false;

  /// Whether the update for the computer voices is enabled
  ///
  /// ## Also see:
  ///
  /// - [AutoUpdateSettings.isAutoUpdateForComputerVoiceEnabled] - Settings for auto update of computer voices passed at the SDK initialization
  bool isAutoUpdateForComputerVoiceEnabled = false;

  /// Whether the update for the car models is enabled
  ///
  /// ## Also see:
  ///
  /// - [AutoUpdateSettings.isAutoUpdateForCarModelEnabled] - Settings for auto update of car models passed at the SDK initialization
  bool isAutoUpdateForCarModelEnabled = false;

  void Function(ContentType type, GemError error)? _onAutoUpdateComplete;

  /// Sets the callback for auto update complete
  ///
  /// ## Example
  ///
  /// ```dart
  /// SdkSettings.offBoardListener.registerOnAutoUpdateComplete((ContentType type, GemError error) {
  ///     if (error == GemError.success) {
  ///         print("The update process finished successfully for $type");
  ///     } else {
  ///         print("The update process failed for $type! The error code is $error");
  ///     }
  /// });
  /// ```
  ///
  /// ## Also see:
  ///
  /// - [AutoUpdateSettings.onAutoUpdateComplete] - Settings for auto update complete callback passed at the SDK initialization
  void registerOnAutoUpdateComplete(
    void Function(ContentType type, GemError error)? onAutoUpdateComplete,
  ) {
    _onAutoUpdateComplete = onAutoUpdateComplete;
  }

  /// Sets the auto update settings
  ///
  /// ## Parameters
  ///
  /// - [autoUpdateSettings]: Auto update settings.
  ///
  /// ## Also see:
  ///
  /// - [AutoUpdateSettings] - Settings for auto update passed at the SDK initialization
  set autoUpdateSettings(AutoUpdateSettings autoUpdateSettings) {
    isAutoUpdateForResourcesEnabled =
        autoUpdateSettings.isAutoUpdateForResourcesEnabled;
    isAutoUpdateForRoadMapEnabled =
        autoUpdateSettings.isAutoUpdateForRoadMapEnabled;
    isAutoUpdateForViewStyleHighResEnabled =
        autoUpdateSettings.isAutoUpdateForViewStyleHighResEnabled;
    isAutoUpdateForViewStyleLowResEnabled =
        autoUpdateSettings.isAutoUpdateForViewStyleLowResEnabled;
    isAutoUpdateForHumanVoiceEnabled =
        autoUpdateSettings.isAutoUpdateForHumanVoiceEnabled;
    isAutoUpdateForComputerVoiceEnabled =
        autoUpdateSettings.isAutoUpdateForComputerVoiceEnabled;
    isAutoUpdateForCarModelEnabled =
        autoUpdateSettings.isAutoUpdateForCarModelEnabled;
    _onAutoUpdateComplete = autoUpdateSettings.onAutoUpdateComplete;
  }

  void _onAvailableContentUpdateCallbackAutoUpdate(
    final ContentType type,
    final ContentStoreStatus status,
  ) {
    gemSdkLogger.finest(
      '[SdkDebug][LoadNativeAutoUpdate] Got update status $status for $type',
    );
    if (status == ContentStoreStatus.upToDate) {
      gemSdkLogger.info(
        '[SdkDebug][LoadNativeAutoUpdate] No update for type $type.',
      );
      return;
    }
    if (!_isUpdateAllowedForType(type)) {
      gemSdkLogger.info(
        '[SdkDebug][LoadNativeAutoUpdate] Update available and disabled for type $type.',
      );
      return;
    }

    final (ContentUpdater, GemError) result = ContentStore.createContentUpdater(
      type,
    );
    final GemError createError = result.$2;
    final ContentUpdater otherContentUpdater = result.$1;

    if (createError != GemError.success && createError != GemError.exist) {
      gemSdkLogger.severe(
        '[SdkDebug][LoadNativeAutoUpdate] Create updater for type $type failed with erorr code $createError.',
      );
      return;
    }

    otherContentUpdater.update(
      true,
      onStatusUpdated: (final ContentUpdaterStatus status) {
        gemSdkLogger.finest(
          '[SdkDebug][LoadNativeAutoUpdate] On status updated for type $type changed with status $status.',
        );

        if (status == ContentUpdaterStatus.fullyReady ||
            status == ContentUpdaterStatus.partiallyReady) {
          otherContentUpdater.apply();
        }
      },
      onComplete: (final GemError error) {
        gemSdkLogger.info(
          '[SdkDebug][LoadNativeAutoUpdate] Updated completed for $type with error $error.',
        );
        _onAutoUpdateComplete?.call(type, error);
      },
    );
  }

  void _onWorldwideRoadMapSupportStatusCallbackAutoUpdate(
    final ContentStoreStatus status,
  ) {
    gemSdkLogger.info(
      '[SdkDebug][LoadNativeAutoUpdate] Got update status $status for roadMap',
    );
    if (status == ContentStoreStatus.upToDate) {
      gemSdkLogger.info(
        '[SdkDebug][LoadNativeAutoUpdate] No update for type roadMap.',
      );
      return;
    }
    if (!_isUpdateAllowedForType(ContentType.roadMap)) {
      gemSdkLogger.info(
        '[SdkDebug][LoadNativeAutoUpdate] Update available and disabled for type roadMap.',
      );
      return;
    }

    final (ContentUpdater, GemError) result = ContentStore.createContentUpdater(
      ContentType.roadMap,
    );
    final GemError createError = result.$2;
    final ContentUpdater roadMapUpdater = result.$1;

    if (createError != GemError.success && createError != GemError.exist) {
      gemSdkLogger.info(
        '[SdkDebug][LoadNativeAutoUpdate] Create updater for type roadMap failed with erorr code $createError.',
      );
      return;
    }

    roadMapUpdater.update(
      true,
      onStatusUpdated: (final ContentUpdaterStatus status) {
        gemSdkLogger.info(
          '[SdkDebug][LoadNativeAutoUpdate] On status updated for type roadMap changed with status $status.',
        );
        if (status == ContentUpdaterStatus.fullyReady ||
            status == ContentUpdaterStatus.partiallyReady) {
          roadMapUpdater.apply();
        }
      },
      onComplete: (final GemError error) {
        gemSdkLogger.info(
          '[SdkDebug][LoadNativeAutoUpdate] Updated completed for roadMap with error $error.',
        );
        _onAutoUpdateComplete?.call(ContentType.roadMap, error);
      },
    );
  }

  bool _isUpdateAllowedForType(final ContentType type) {
    switch (type) {
      case ContentType.roadMap:
        return isAutoUpdateForRoadMapEnabled;
      case ContentType.viewStyleHighRes:
        return isAutoUpdateForViewStyleHighResEnabled;
      case ContentType.viewStyleLowRes:
        return isAutoUpdateForViewStyleLowResEnabled;
      case ContentType.humanVoice:
        return isAutoUpdateForHumanVoiceEnabled;
      case ContentType.computerVoice:
        return isAutoUpdateForComputerVoiceEnabled;
      case ContentType.carModel:
        return isAutoUpdateForCarModelEnabled;
      case ContentType.unknown:
        return false;
    }
  }
}
