// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/src/core/common/auto_update_settings.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Magic Lane SDK global functions.
///
/// Initialize and release the Magic Lane SDK using this class.
/// Call [GemKit.initialize] before using any other SDK functionality.
///
/// {@category Common}
class GemKit {
  /// Initialize the Magic Lane Flutter SDK.
  ///
  /// All Magic Lane SDK objects must be used only after a successful call to this function
  ///
  /// ## Parameters
  ///
  /// - [appAuthorization]: Application token that enables the SDK. Required for evaluation SDKs.
  /// The map will have a watermark and some features might not work as expected without this parameter.
  /// - [allowInternetConnection]: Allow the SDK to use internet connection for map data, routing, traffic, etc.
  /// Default is `true`.
  /// - [autoUpdateSettings]: Auto update settings specifying what types of resources should be updated automatically.
  /// - [onSdkException]: Callback invoked when an SDK exception occurs.
  static Future<void> initialize({
    final String? appAuthorization,
    final bool allowInternetConnection = true,
    final AutoUpdateSettings autoUpdateSettings = const AutoUpdateSettings(),
    final void Function(SdkEvent, String)? onSdkException,
    final int? aVar,
  }) => GemKitPlatform.instance.loadNative(
    appAuthorization: appAuthorization,
    autoUpdateSettings: autoUpdateSettings,
    allowInternetConnection: allowInternetConnection,
    onSdkException: onSdkException,
    aVar: aVar,
  );

  /// Release the Magic Lane SDK. After this call all remained SDK objects cannot be used.
  static Future<void> release() async {
    await GemKitPlatform.disposeGemSdk();
  }
}

/// Event which can be triggered at SDK initializaiton
///
/// Can be used with [GemKit.initialize]'s callback.
///
/// {@category Common}
enum SdkEvent {
  /// Default exception: not available
  notAvailable,

  /// Delivered when breakpad completed with success
  breakpadSuccess,

  /// Delivered when breakpad completed with failure
  breakpadFailure,

  /// Delivered when activation is required
  activationMandatory,
}

/// @nodoc
extension SdkEventExtension on SdkEvent {
  int get id {
    switch (this) {
      case SdkEvent.notAvailable:
        return 0;
      case SdkEvent.breakpadSuccess:
        return 1;
      case SdkEvent.breakpadFailure:
        return 2;
      case SdkEvent.activationMandatory:
        return 3;
    }
  }

  static SdkEvent fromId(int value) {
    switch (value) {
      case 0:
        return SdkEvent.notAvailable;
      case 1:
        return SdkEvent.breakpadSuccess;
      case 2:
        return SdkEvent.breakpadFailure;
      case 3:
        return SdkEvent.activationMandatory;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
