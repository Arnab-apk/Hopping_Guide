// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:flutter/foundation.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/position/gem_position.dart';

/// Position update callback interface for real-time location tracking.
///
/// This abstract class defines a callback interface that receives position updates
/// from the Maps SDK. Position listeners are created internally by the [PositionService]
/// when you register position update callbacks using [PositionService.addPositionListener]
/// or [PositionService.addImprovedPositionListener].
///
/// This is a callback interface managed by the SDK. You cannot instantiate
/// it directly. Instead, register position callbacks with [PositionService], which returns
/// a [GemPositionListener] instance that can be used to remove the listener later.
///
/// The interface provides two types of position notifications:
/// - **Basic position updates** ([notifyOnNewPosition]): Raw GPS coordinates, speed,
///   accuracy, and other basic location data from the device sensors.
/// - **Improved position updates** ([notifyOnNewImprovedPosition]): Map-matched positions
///   that include additional context such as current road information, speed limits,
///   road modifiers, and address details.
///
/// See also:
/// - [PositionService.addPositionListener] for registering basic position callbacks
/// - [PositionService.addImprovedPositionListener] for registering enhanced position callbacks
/// - [GemPosition] for basic position data structure
/// - [GemImprovedPosition] for enhanced position data structure
///
/// {@category Position}
abstract class GemPositionListener extends EventHandler {
  int id = 0;

  /// Basic position update callback invoked by the SDK.
  ///
  /// This method is used internally and should not be called directly.
  /// Use the [PositionService.addPositionListener] method to register a callback function
  /// that will be invoked automatically when new position data is available.
  @internal
  void notifyOnNewPosition(final GemPosition pos);

  /// Enhanced position update callback invoked by the SDK.
  ///
  /// This method is used internally and should not be called directly.
  /// Use the [PositionService.addImprovedPositionListener] method to register a callback function
  /// that will be invoked automatically when new improved position data is available.
  @internal
  void notifyOnNewImprovedPosition(final GemImprovedPosition pos);
}
