// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/core/private/event_handler.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/loggers/app_logger.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/sense_data_impl.dart';
import 'package:meta/meta.dart';

/// Receives events and sensor data from a [DataSource].
///
/// Use a [DataSourceListener] to react to data-source events such as:
/// - playing status changes,
/// - interruptions to data flow (sensor stopped, app backgrounded, etc.),
/// - new sensor data arrivals, and
/// - progress updates during playback.
///
/// Create an instance with the factory and supply the callbacks you need. The
/// listener can then be registered with a [DataSource] for specific
/// [DataType] using [DataSource.addListener] and removed with
/// [DataSource.removeListener] or [DataSource.removeListenerAllDataTypes].
///
/// For position data sources, consider using [PositionService] which provides
/// built-in support for registering listeners and managing position updates.
///
/// ## See also:
///
/// - [DataSource] — Source of events and data.
/// - [PositionService] - Service providing position data, with the ability to
/// register for position updates.
///
/// {@category Sensor Data Source}
class DataSourceListener extends EventHandler {
  /// Creates a new [DataSourceListener] and optionally registers the provided callbacks.
  ///
  /// The factory returns a ready-to-use listener. Any non-null callback will be
  /// registered on the returned instance.
  ///
  /// ## Parameters
  ///
  /// - [onPlayingStatusChanged]: Called when a data type's playing status changes. Arguments:
  ///   - `dataType`: The [DataType] whose status changed.
  ///   - `status`: The new [PlayingStatus].
  /// - [onDataInterruptionEvent]: Called when data for a data type is interrupted. Arguments:
  ///   - `dataType`: The [DataType] affected by the interruption.
  ///   - `reason`: The [DataInterruptionReason] for the interruption.
  ///   - `ended`: `true` when the interruption ended, `false` when it started.
  /// - [onNewData]: Called when new [SenseData] is available. Arguments:
  ///   - `data`: The received [SenseData] instance.
  /// - [onProgressChanged]: Called when playback progress changes. Arguments:
  ///   - `progress`: Integer progress value.
  ///
  factory DataSourceListener({
    final void Function(DataType dataType, PlayingStatus status)?
    onPlayingStatusChanged,
    final void Function(
      DataType dataType,
      DataInterruptionReason reason,
      bool ended,
    )?
    onDataInterruptionEvent,
    final void Function(SenseData data)? onNewData,
    final void Function(int)? onProgressChanged,
  }) {
    final DataSourceListener listener = DataSourceListener._create();
    if (onPlayingStatusChanged != null) {
      listener.registerOnPlayingStatusChanged(onPlayingStatusChanged);
    }
    if (onDataInterruptionEvent != null) {
      listener.registerOnDataInterruptionEvent(onDataInterruptionEvent);
    }
    if (onNewData != null) {
      listener.registerOnNewData(onNewData);
    }
    if (onProgressChanged != null) {
      listener.registerOnProgressChanged(onProgressChanged);
    }
    return listener;
  }

  @internal
  DataSourceListener.init(this.id);
  void Function(DataType dataType, PlayingStatus status)?
  _onPlayingStatusChanged;
  void Function(DataType dataType, DataInterruptionReason reason, bool ended)?
  _onDataInterruptionEvent;
  void Function(SenseData data)? _onNewData;
  void Function(int)? _onProgressChanged;

  int id;

  /// Register a callback invoked when a data type's playing status changes.
  ///
  /// ## Parameters
  ///
  /// - [onPlayingStatusChanged]: Callback receiving:
  ///   - `dataType`: The [DataType] whose status changed.
  ///   - `status`: The new [PlayingStatus].
  void registerOnPlayingStatusChanged(
    final void Function(DataType dataType, PlayingStatus status)?
    onPlayingStatusChanged,
  ) {
    _onPlayingStatusChanged = onPlayingStatusChanged;
  }

  /// Register a callback that is invoked when data for a data type is interrupted.
  ///
  /// ## Parameters
  ///
  /// - [onDataInterruptionEvent]: Callback receiving:
  ///   - `dataType`: The [DataType] affected by the interruption.
  ///   - `reason`: The [DataInterruptionReason] explaining why the data was interrupted.
  ///   - `ended`: `true` if the interruption ended, `false` if it started.
  void registerOnDataInterruptionEvent(
    final void Function(
      DataType dataType,
      DataInterruptionReason reason,
      bool ended,
    )?
    onDataInterruptionEvent,
  ) {
    _onDataInterruptionEvent = onDataInterruptionEvent;
  }

  /// Register a callback invoked when new [SenseData] arrives.
  ///
  /// ## Parameters
  ///
  /// - [onNewData]: Callback receiving a single argument:
  ///   - `data`: The [SenseData] instance that was produced by the data source.
  ///
  /// ## Also see:
  ///
  /// - [PositionService] - Service providing position data, with the ability to
  /// register for position updates.
  void registerOnNewData(final void Function(SenseData data)? onNewData) {
    _onNewData = onNewData;
  }

  /// Register a callback invoked when playback or processing progress updates.
  ///
  /// Only applicable for [DataSource] instances that support progress tracking.
  ///
  /// ## Parameters
  ///
  /// - [onProgressChanged]: Callback receiving a single argument:
  ///   - `progress`: Integer progress value.
  void registerOnProgressChanged(
    final void Function(int progress)? onProgressChanged,
  ) {
    _onProgressChanged = onProgressChanged;
  }

  static DataSourceListener _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, Object>{
        'class': 'DataSourceListener',
        'args': <String, dynamic>{},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return DataSourceListener.init(decodedVal['result']);
  }

  @override
  void nativeClear() {}

  @override
  void clearListeners() {
    _onPlayingStatusChanged = null;
    _onDataInterruptionEvent = null;
    _onNewData = null;
    _onProgressChanged = null;
  }

  @override
  void handleEvent(final Map<dynamic, dynamic> arguments) {
    final String eventSubtype = arguments['event_subtype'];

    switch (eventSubtype) {
      case 'onPlayingStatusChanged':
        if (_onPlayingStatusChanged != null) {
          _onPlayingStatusChanged!(
            DataTypeExtension.fromId(arguments['type']),
            PlayingStatus.values[arguments['status']],
          );
        }
      case 'onDataInterruptionEvent':
        if (_onDataInterruptionEvent != null) {
          _onDataInterruptionEvent!(
            DataTypeExtension.fromId(arguments['type']),
            DataInterruptionReasonExtension.fromId(arguments['reason']),
            arguments['ended'],
          );
        }
      case 'onNewData':
        if (_onNewData != null) {
          _onNewData!(senseFromJson(arguments['data']));
        }
      case 'onProgressChanged':
        if (_onProgressChanged != null) {
          _onProgressChanged!(arguments['progress']);
        }
      default:
        gemSdkLogger.log(
          Level.WARNING,
          'Unknown event subtype: ${arguments['eventType']} in DataSourceListener',
        );
    }
  }
}

/// Reasons why a data source may be interrupted.
///
/// Use these values when responding to interruption events delivered via
/// [DataSourceListener.registerOnDataInterruptionEvent]. They describe why a
/// particular [DataType] stopped producing data or why the data flow changed.
///
/// {@category Sensor Data Source}
enum DataInterruptionReason {
  /// The reason for the data interruption is unknown.
  unknown,

  /// The sensor that generates the data has stopped operating.
  sensorStopped,

  /// The application has been sent to the background, interrupting data collection.
  appSentToBackground,

  /// The position data source has changed (e.g., from GPS to Network).
  locationProvidersChanged,

  /// The configuration of the sensor has changed.
  sensorConfigurationChanged,

  /// The device orientation has changed, affecting sensor data.
  deviceOrientationChanged,

  /// The sensor is currently in use by another client.
  inUseByAnotherClient,

  /// Data collection is not available due to multiple foreground applications.
  notAvailableWithMultipleForegroundApps,

  /// Data is not available due to system resource pressure.
  notAvailableDueToSystemPressure,

  /// Data collection is not available while the application is in the background.
  notAvailableInBackground,

  /// The audio device is currently in use by another client.
  audioDeviceInUseByAnotherClient,

  /// The video device is currently in use by another client.
  videoDeviceInUseByAnotherClient,
}

/// @nodoc
extension DataInterruptionReasonExtension on DataInterruptionReason {
  static DataInterruptionReason fromId(final int id) {
    switch (id) {
      case 0:
        return DataInterruptionReason.unknown;
      case 1:
        return DataInterruptionReason.sensorStopped;
      case 2:
        return DataInterruptionReason.appSentToBackground;
      case 3:
        return DataInterruptionReason.locationProvidersChanged;
      case 4:
        return DataInterruptionReason.sensorConfigurationChanged;
      case 5:
        return DataInterruptionReason.deviceOrientationChanged;
      case 6:
        return DataInterruptionReason.inUseByAnotherClient;
      case 7:
        return DataInterruptionReason.notAvailableWithMultipleForegroundApps;
      case 8:
        return DataInterruptionReason.notAvailableDueToSystemPressure;
      case 9:
        return DataInterruptionReason.notAvailableInBackground;
      case 10:
        return DataInterruptionReason.audioDeviceInUseByAnotherClient;
      case 11:
        return DataInterruptionReason.videoDeviceInUseByAnotherClient;
      default:
        throw ArgumentError('Invalid id');
    }
  }

  int get id {
    switch (this) {
      case DataInterruptionReason.unknown:
        return 0;
      case DataInterruptionReason.sensorStopped:
        return 1;
      case DataInterruptionReason.appSentToBackground:
        return 2;
      case DataInterruptionReason.locationProvidersChanged:
        return 3;
      case DataInterruptionReason.sensorConfigurationChanged:
        return 4;
      case DataInterruptionReason.deviceOrientationChanged:
        return 5;
      case DataInterruptionReason.inUseByAnotherClient:
        return 6;
      case DataInterruptionReason.notAvailableWithMultipleForegroundApps:
        return 7;
      case DataInterruptionReason.notAvailableDueToSystemPressure:
        return 8;
      case DataInterruptionReason.notAvailableInBackground:
        return 9;
      case DataInterruptionReason.audioDeviceInUseByAnotherClient:
        return 10;
      case DataInterruptionReason.videoDeviceInUseByAnotherClient:
        return 11;
    }
  }
}
