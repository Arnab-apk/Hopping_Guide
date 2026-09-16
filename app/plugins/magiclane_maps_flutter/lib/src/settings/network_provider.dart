// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Network access customization and notification hooks.
///
/// [NetworkProvider] exposes helpers to query the current connectivity state and to register
/// platform callbacks that notify about connectivity events (for example when a connection
/// finishes or fails). Most APIs are implemented via platform channels; some callback
/// registration features are only supported on Android.
///
/// ## See also:
///
/// - [SdkSettings.offBoardListener] - Receive notifications about off-board events.
///
/// {@category Settings}
abstract class NetworkProvider {
  /// Checks if the device is connected to any network.
  static Future<bool> isConnected() async {
    final bool? result = await GemKitPlatform.instance
        .getChannel(mapId: -1)
        .invokeMethod<bool>(
          'networkProviderCall',
          jsonEncode(<String, String>{'action': 'isConnected'}),
        );
    return result!;
  }

  /// Checks if the device is connected to a WiFi network.
  static Future<bool> isWifiConnected() async {
    final bool? result = await GemKitPlatform.instance
        .getChannel(mapId: -1)
        .invokeMethod<bool>(
          'networkProviderCall',
          jsonEncode(<String, String>{'action': 'isWifiConnected'}),
        );
    return result!;
  }

  /// Checks if the device is connected to a mobile data network.
  static Future<bool> isMobileDataConnected() async {
    final bool? result = await GemKitPlatform.instance
        .getChannel(mapId: -1)
        .invokeMethod(
          'networkProviderCall',
          jsonEncode(<String, String>{'action': 'isMobileDataConnected'}),
        );
    return result!;
  }

  /// Refreshes the device network state.
  static Future<void> refreshNetwork() async {
    await GemKitPlatform.instance
        .getChannel(mapId: -1)
        .invokeMethod(
          'networkProviderCall',
          jsonEncode(<String, String>{'action': 'refreshNetwork'}),
        );
  }
}
