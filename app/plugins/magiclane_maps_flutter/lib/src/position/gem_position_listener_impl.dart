// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';
import 'package:magiclane_maps_flutter/src/position/gem_position.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/gem_position_impl.dart';
import 'package:meta/meta.dart';

/// Implementation of the [GemPositionListener] interface.
///
/// The API users should not use this class directly.
/// Instead, they should use the [GemPositionListener] interface via the
/// [PositionService] to register for position updates.
///
/// @nodoc
@internal
class GemPositionListenerImpl extends GemPositionListener {
  /// Constructor for the Gem Position Listener
  ///
  /// ## Parameters
  ///
  /// - [onNewPosition]: Callback called when a new position is emitted
  /// - [onNewImprovedPosition]: Callback called when a new improved position is emitted
  GemPositionListenerImpl({
    void Function(GemPosition position)? onNewPosition,
    void Function(GemImprovedPosition position)? onNewImprovedPosition,
  }) : _onNewPosition = onNewPosition,
       _onNewImprovedPosition = onNewImprovedPosition;

  /// Callback called when a new position is emitted
  @Deprecated('Use registerOnNewPosition callback instead.')
  void Function(GemPosition position)? get onNewPosition => _onNewPosition;

  /// Setter for onNewPosition callback
  @Deprecated('Use registerOnNewPosition callback instead.')
  set onNewPosition(void Function(GemPosition position)? callback) {
    _onNewPosition = callback;
  }

  /// Callback called when a new improved position is emitted
  @Deprecated('Use registerOnNewPosition callback instead.')
  void Function(GemImprovedPosition position)? get onNewImprovedPosition =>
      _onNewImprovedPosition;

  /// Setter for onNewImprovedPosition callback
  @Deprecated('Use registerOnNewPosition callback instead.')
  set onNewImprovedPosition(
    void Function(GemImprovedPosition position)? callback,
  ) {
    _onNewImprovedPosition = callback;
  }

  void Function(GemPosition position)? _onNewPosition;
  void Function(GemImprovedPosition position)? _onNewImprovedPosition;

  /// Registers the callback for new position updates
  ///
  /// ## Parameters
  ///
  /// - [callback]: The callback function providing the new [GemPosition]
  /// to be invoked on position updates
  void registerOnNewPosition(void Function(GemPosition position)? callback) {
    _onNewPosition = callback;
  }

  /// Registers the callback for new improved position updates
  ///
  /// ## Parameters
  ///
  /// - [callback]: The callback function providing the new [GemImprovedPosition]
  /// to be invoked on improved position updates
  void registerOnNewImprovedPosition(
    void Function(GemImprovedPosition position)? callback,
  ) {
    _onNewImprovedPosition = callback;
  }

  @override
  void notifyOnNewPosition(final GemPosition pos) {
    _onNewPosition?.call(pos);
  }

  @override
  void notifyOnNewImprovedPosition(final GemImprovedPosition pos) {
    _onNewImprovedPosition?.call(pos);
  }

  @internal
  @override
  void handleEvent(final Map<dynamic, dynamic> arguments) {
    if (arguments['eventType'] == 'positionEvent') {
      final Map<String, dynamic> positionJson = arguments['position'];
      final DataType type = DataTypeExtension.fromId(
        positionJson['senseDataType'],
      );
      if (type == DataType.position) {
        notifyOnNewPosition(GemPositionImpl.fromJson(positionJson));
      } else if (type == DataType.improvedPosition) {
        notifyOnNewImprovedPosition(
          GemImprovedPositionImpl.fromJson(positionJson),
        );
      }
    } else {
      gemSdkLogger.log(
        Level.WARNING,
        'Unknown event subtype: ${arguments['eventType']} in GemPositionListener',
      );
    }
  }

  @override
  void nativeClear() {
    staticMethod('PositionService', 'unregisterSenseDataListener', args: id);
  }

  @override
  void clearListeners() {
    _onNewPosition = null;
    _onNewImprovedPosition = null;
  }
}
