// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Traffic usage type.
///
/// Controls how the SDK applies traffic information during routing and
/// navigation. Choose the appropriate mode depending on whether you want to
/// rely on online traffic updates, offline data only, or disable traffic
/// altogether.
///
/// ## Also see:
///
/// - [TrafficPreferences] — Configure traffic usage preferences.
///
/// {@category Traffic & Roadblocks}
enum TrafficUsage {
  /// No traffic: disable all traffic usage in routing and navigation.
  none,

  /// Online and offline (default): combines server-provided traffic with
  /// available offline data.
  online,

  /// Offline only: rely exclusively on offline traffic data and
  /// user-defined roadblocks.
  offline,
}

/// @nodoc
extension TrafficUsageExtension on TrafficUsage {
  int get id {
    switch (this) {
      case TrafficUsage.none:
        return 0;
      case TrafficUsage.online:
        return 1;
      case TrafficUsage.offline:
        return 2;
    }
  }

  static TrafficUsage fromId(final int id) {
    switch (id) {
      case 0:
        return TrafficUsage.none;
      case 1:
        return TrafficUsage.online;
      case 2:
        return TrafficUsage.offline;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Traffic preferences for the SDK.
///
/// Use this object to configure how the traffic subsystem behaves. Do not
/// instantiate directly — obtain an instance via
/// [TrafficService.preferences].
///
/// The main property is [useTraffic], which controls whether routing and
/// navigation consider traffic information and whether that information may
/// be sourced from online services or only from offline caches and user
/// roadblocks.
///
/// ## Example
///
/// ```dart
/// TrafficService.preferences.useTraffic = TrafficUsage.offline;
/// ```
///
/// ## See also:
///
/// - [TrafficService] — Service related to traffic data and roadblock management.
/// - [TrafficUsage] — Enum describing available traffic usage modes.
///
/// {@category Traffic & Roadblocks}
class TrafficPreferences extends GemAutoreleaseObject {
  // ignore: unused_element
  TrafficPreferences._() : super(-1);

  @internal
  TrafficPreferences.init(super.pointerId);

  /// Current traffic usage mode.
  ///
  /// Controls whether and how traffic data is applied to routing and
  /// navigation. Changing this value takes effect immediately for subsequent
  /// route calculations and traffic-dependent behavior.
  ///
  /// ## Returns
  ///
  /// - [TrafficUsage]: current traffic usage mode.
  TrafficUsage get useTraffic {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficPreferences',
      'getUseTraffic',
    );

    return TrafficUsageExtension.fromId(resultString['result']);
  }

  /// Set the traffic usage mode.
  ///
  /// ## Parameters
  ///
  /// - [useTraffic]: the desired [TrafficUsage] value.
  set useTraffic(final TrafficUsage useTraffic) {
    objectMethod(
      pointerId,
      'TrafficPreferences',
      'setUseTraffic',
      args: useTraffic.id,
    );
  }
}
