// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/position/gem_position.dart';
import 'package:magiclane_maps_flutter/src/position/gem_position_listener_impl.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/gem_position_impl.dart';

/// Provides access to device and custom position data and playback controls.
///
/// The [PositionService] exposes static helpers to obtain the current device
/// position, register continuous position listeners, and manage the position
/// data source (live GPS, playback logs, or custom external sources). Use
/// listeners created with [addPositionListener] or
/// [addImprovedPositionListener] to receive continuous updates.
///
/// Raw positions are direct GPS fixes (latitude, longitude, altitude, speed, bearing,
/// accuracy, timestamp) with no map context. See [GemPosition] for details. The
/// [addPositionListener] method provides these raw position updates.
///
/// Improved (map-matched) positions are post‑processed, smoothed and snapped to the road
/// network or known paths, may include road metadata (road id, speed limit, modifiers).
/// See [GemImprovedPosition] for details. The [addImprovedPositionListener] method provides
/// these improved position updates.
///
/// For one-off reads use the [position] and [improvedPosition] getters. Playback controls
/// are available via [playback] when the active [DataSource] supports it.
///
/// Data can come from the device GPS (live) or from custom/log data sources.
///
/// **VERY IMPORTANT:** Make sure the application has the required location
/// permissions before setting the live data source. See the
/// [permission_handler package](https://pub.dev/packages/permission_handler)
/// for more details on requesting location permissions in Flutter. Platform
/// specific setup is required on Android and iOS to request location permissions.
///
/// ## Example
///
/// ```dart
/// final locationPermissionStatus = await Permission.locationWhenInUse.request();
/// if (locationPermissionStatus == PermissionStatus.granted) {
///   GemError setLiveDataSourceError = PositionService.setLiveDataSource();
///   if (setLiveDataSourceError == GemError.success) {
///     print("Live data source set successfully");
///   } else {
///     print("Failed to set live data source: $setLiveDataSourceError");
///   }
///
///   PositionService.addImprovedPositionListener((GemPosition position) {
///     // Handle improved position updates
///   });
/// } else {
///   print("Location permission denied");
/// }
/// ```
///
/// ## See also:
///
/// - [GemPositionListener] - Listener returned by addPositionListener methods.
/// - [DataSource] - Represents an external or playback data source.
/// - [Playback] - Controls log/simulation playback when available.
///
/// {@category Position}
abstract class PositionService {
  /// Registers a callback to receive raw position updates from the active data source.
  ///
  /// The provided callback is invoked whenever a new raw [GemPosition] is
  /// available from the configured position data source (live GPS or an
  /// external source). The returned [GemPositionListener] can be passed to
  /// [removeListener] to stop receiving updates.
  ///
  /// ## Parameters
  ///
  /// - [positionUpdatedCallback]: Callback invoked with the latest [GemPosition].
  ///
  /// ## Returns
  ///
  /// - The registered [GemPositionListener] which can be used to unregister.
  ///
  /// ## Also see:
  ///
  /// - [addImprovedPositionListener] - For receiving map-matched position updates.
  /// - [removeListener] - To unregister a previously registered listener.
  /// - [GemPosition] - The raw position data object.
  static GemPositionListener addPositionListener(
    final void Function(GemPosition position) positionUpdatedCallback,
  ) {
    final GemPositionListenerImpl posListener = GemPositionListenerImpl(
      onNewPosition: positionUpdatedCallback,
    );
    final String result = GemKitPlatform.instance
        .callObjectMethod(<String, Object>{
          'id': 0,
          'class': 'PositionService',
          'method': 'registerSenseDataListener',
          'senseDataType': DataType.position.id,
        });

    posListener.id = jsonDecode(result)['result'];
    GemKitPlatform.instance.registerEventHandler(posListener.id, posListener);
    return posListener;
  }

  /// Registers a callback to receive improved position updates from the active data source.
  ///
  /// The provided callback is invoked whenever a new improved [GemImprovedPosition] is
  /// available from the configured position data source (live GPS or an
  /// external source). The returned [GemPositionListener] can be passed to
  /// [removeListener] to stop receiving updates.
  ///
  /// ## Parameters
  ///
  /// - [positionUpdatedCallback]: Callback invoked with the latest [GemImprovedPosition].
  ///
  /// ## Returns
  ///
  /// - The registered [GemPositionListener] which can be used to unregister.
  ///
  /// ## Also see:
  ///
  /// - [addPositionListener] - For receiving raw position updates.
  /// - [removeListener] - To unregister a previously registered listener.
  /// - [GemImprovedPosition] - The improved position data object.
  static GemPositionListener addImprovedPositionListener(
    final void Function(GemImprovedPosition position) positionUpdatedCallback,
  ) {
    final GemPositionListenerImpl posListener = GemPositionListenerImpl(
      onNewImprovedPosition: positionUpdatedCallback,
    );
    final String result = GemKitPlatform.instance
        .callObjectMethod(<String, Object>{
          'id': 0,
          'class': 'PositionService',
          'method': 'registerSenseDataListener',
          'senseDataType': DataType.improvedPosition.id,
        });

    posListener.id = jsonDecode(result)['result'];
    GemKitPlatform.instance.registerEventHandler(posListener.id, posListener);
    return posListener;
  }

  /// Unregisters a previously registered position listener.
  ///
  /// Removes the listener so the associated callback will no longer receive
  /// position updates. After calling this method the listener is no longer
  /// active and its resources are released on the native side.
  ///
  /// ## Parameters
  ///
  /// - [listener]: The [GemPositionListener] returned by
  ///   [addPositionListener] or [addImprovedPositionListener] to remove.
  static void removeListener(final GemPositionListener listener) {
    GemKitPlatform.instance.unregisterEventHandler(listener.id);
    staticMethod(
      'PositionService',
      'unregisterSenseDataListener',
      args: listener.id,
    );
  }

  /// Returns the most recent raw position sample, or null if unavailable.
  ///
  /// This getter performs a synchronous call to the underlying engine to
  /// retrieve the latest available [GemPosition]. If the internal operation
  /// reports an error the getter returns null.
  ///
  /// ## Returns
  ///
  /// - The latest [GemPosition] if available, otherwise `null`.
  static GemPosition? get position {
    final OperationResult retVal = staticMethod(
      'PositionService',
      'getPosition',
      args: DataType.position.id,
    );

    final GemError gemApiError = GemErrorExtension.fromCode(
      retVal['gemApiError'],
    );

    if (gemApiError != GemError.success) {
      return null;
    }

    final dynamic result = retVal['result'];
    if (result != null) {
      return GemPositionImpl.fromJson(result);
    }
    return null;
  }

  /// Returns the most recent map-matched (improved) position, or null.
  ///
  /// If no improved position is available this getter returns `null`.
  ///
  /// ## Returns
  ///
  /// - The latest [GemImprovedPosition] if available, otherwise `null`.
  static GemImprovedPosition? get improvedPosition {
    final OperationResult retVal = staticMethod(
      'PositionService',
      'getPosition',
      args: DataType.improvedPosition.id,
    );
    final GemError gemApiError = GemErrorExtension.fromCode(
      retVal['gemApiError'],
    );

    if (gemApiError != GemError.success) {
      return null;
    }

    final dynamic result = retVal['result'];
    if (result != null) {
      return GemImprovedPositionImpl.fromJson(result);
    }
    return null;
  }

  /// Sets the [PositionService] to use the device's live GPS data source.
  ///
  /// Call this after the app has the required location permission. Setting
  /// the live data source instructs the SDK to use the device GPS as the
  /// primary provider for [position] updates and listener callbacks. Calling
  /// this method more than once can return [GemError.exist].
  ///
  /// ## Returns
  ///
  /// - [GemError.success] when the live source was selected successfully.
  /// - [GemError.invalidInput] when the live data source could not be
  ///   created (for example missing permissions or no available provider).
  /// - [GemError.exist] if a data source is already active.
  ///
  /// ## Also see:
  ///
  /// - [removeDataSource] - To remove the active data source.
  /// - [setExternalDataSource] - To set a custom external data source.`
  static GemError setLiveDataSource() {
    final String resultString = GemKitPlatform.instance
        .callObjectMethod(<String, Object>{
          'id': 0,
          'class': 'PositionService',
          'method': 'selectPositionDataSource',
          'senseDataSourceType': 'live',
        });
    final dynamic result = jsonDecode(resultString);
    final int errCode = result['gemApiError'];
    return GemErrorExtension.fromCode(errCode);
  }

  /// Returns the currently configured [DataSource], or null if none is set.
  ///
  /// The returned [DataSource] represents the active position data source
  /// (live GPS, playback log/simulation, or custom external source). If no
  /// data source is configured this method returns `null`.
  ///
  /// ## Returns
  ///
  /// - The active [DataSource] or `null` when no data source is set.
  static DataSource? getDataSource() {
    final OperationResult resultString = staticMethod(
      'PositionService',
      'getDataSource',
    );
    final GemError gemApiError = GemErrorExtension.fromCode(
      resultString['gemApiError'],
    );

    if (gemApiError != GemError.success) {
      return null;
    }

    return DataSource.init(resultString['result']);
  }

  /// Returns a [Playback] controller when the active data source supports it.
  ///
  /// Playback is available for log or simulation data sources and provides
  /// controls such as pause, resume, seek and speed adjustments. Returns
  /// `null` when the current data source does not expose playback.
  ///
  /// ## Returns
  ///
  /// - A [Playback] instance when available, otherwise `null`.
  static Playback? get playback {
    final OperationResult resultString = staticMethod(
      'PositionService',
      'getPlayback',
    );
    final GemError gemApiError = GemErrorExtension.fromCode(
      resultString['gemApiError'],
    );

    if (gemApiError != GemError.success) {
      return null;
    }
    return Playback.init(resultString['result']);
  }

  /// Returns the type of the current position data source.
  ///
  /// The value indicates whether the SDK is using a live GPS, a playback
  /// (log/simulation) source, or a custom external source.
  ///
  /// ## Returns
  ///
  /// - A [DataSourceType] value representing the active source type.
  static DataSourceType get sourceType {
    final OperationResult resultString = staticMethod(
      'PositionService',
      'getSourceType',
    );

    return DataSourceTypeExtension.fromId(resultString['result']);
  }

  /// Removes the active position data source and stops delivering new samples.
  ///
  /// After calling this method the PositionService will not provide new
  /// positions until a new data source is selected (for example via
  /// [setLiveDataSource] or [setExternalDataSource]).
  ///
  /// ## Also see:
  ///
  /// - [setLiveDataSource] - To set the live GPS as data source.
  /// - [setExternalDataSource] - To set a custom external data source.
  static void removeDataSource() {
    GemKitPlatform.instance.callObjectMethod(<String, Object>{
      'id': 0,
      'class': 'PositionService',
      'method': 'selectPositionDataSource',
      'senseDataSourceType': 'none',
    });
  }

  /// Configures a custom external data source for providing position samples.
  ///
  /// Use this to supply positions from a simulation, log file, or external
  /// hardware. The provided [DataSource] will become the active source for
  /// subsequent calls to [position], [improvedPosition] and any registered
  /// listeners. Remember to call [DataSource.start] if the source requires
  /// an explicit start.
  ///
  /// ## Parameters
  ///
  /// - [dataSource]: The [DataSource] instance to set as the active source.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success.
  /// - [GemError.exist] if a data source is already set.
  /// - [GemError.invalidInput] if the provided [dataSource] is invalid.
  ///
  /// ## Also see:
  ///
  /// - [removeDataSource] - To remove the active data source.
  /// - [setLiveDataSource] - To set the live GPS as data source.
  static GemError setExternalDataSource(final DataSource dataSource) {
    final OperationResult resultString = staticMethod(
      'PositionService',
      'setExternalDataSource',
      args: dataSource.pointerId,
    );
    return GemErrorExtension.fromCode(resultString['gemApiError']);
  }

  /// Requests location permission from the platform (web-only helper).
  ///
  /// On web platforms this method asks the browser for location permission
  /// and resolves to `true` when the permission is granted. On native
  /// platforms (Android/iOS) this method is not implemented and platform
  /// specific permission flows (for example using `permission_handler`) must
  /// be used instead.
  ///
  /// ## Returns
  ///
  /// - A [Future<bool>] that completes to `true` when permission is granted
  ///   on web, otherwise `false`.
  ///
  /// ## Throws
  ///
  /// - [UnimplementedError] on Android/iOS.
  static Future<bool> requestLocationPermission() {
    return GemKitPlatform.instance.askForLocationPermission();
  }
}
