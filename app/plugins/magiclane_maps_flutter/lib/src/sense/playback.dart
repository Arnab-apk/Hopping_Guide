// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/sense_data_impl.dart';

/// Controls a playback-enabled [DataSource], for example a log file or a
/// simulated route replay.
///
/// The [Playback] interface exposes operations to pause, resume, seek, and
/// adjust playback speed. It applies only to data sources of
///
/// [DataSourceType.playback] and is not compatible with live or custom
/// data sources. Use the `playback` getter on a [DataSource] to obtain an
/// instance when available.
///
/// ## See also:
///
/// - [DataSource] - Represents a source of data for playback.
///
/// {@category Sensor Data Source}
class Playback extends GemAutoreleaseObject {
  // ignore: unused_element
  Playback._() : super(-1);

  Playback.init(super.id);

  /// Pauses playback.
  ///
  /// The operation stops the progression of the playback. Call [resume]
  /// to continue playback from the current position.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success.
  /// - [GemError.engineNotInitialized] if the data source is not available.
  /// - [GemError.upToDate] if the operation failed because the state is
  ///   already up-to-date.
  ///
  /// ## See also:
  ///
  /// - [resume] - Resumes playback after a pause.
  GemError pause() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PlaybackContainer',
      'pause',
    );
    final int retVal = resultString['result'];
    return GemErrorExtension.fromCode(retVal);
  }

  /// Resumes playback.
  ///
  /// Continues playback from the current position after a prior [pause]
  /// call.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success.
  /// - [GemError.engineNotInitialized] if the data source is not available.
  /// - [GemError.upToDate] if the operation failed because the state is
  ///   already up-to-date.
  ///
  /// ## See also:
  ///
  /// - [pause] - Pauses the playback.
  GemError resume() {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PlaybackContainer',
      'resume',
    );
    final int retVal = resultString['result'];
    return GemErrorExtension.fromCode(retVal);
  }

  /// Advances playback by a single frame.
  ///
  /// Only meaningful for data sources that contain video content; for other
  /// types this is a no-op.
  void step() {
    objectMethod(pointerId, 'PlaybackContainer', 'step');
  }

  /// Returns the current playback state.
  ///
  /// The returned [PlayingStatus] indicates whether the playback is
  /// playing, paused, stopped, or unknown.
  PlayingStatus get state {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PlaybackContainer',
      'getState',
    );
    final int retVal = resultString['result'];
    return PlayingStatusExtension.fromId(retVal);
  }

  /// The current playback speed multiplier.
  ///
  /// Relevant for route-based data sources. The multiplier is applied to the
  /// playback timeline (for example, `2.0` plays at double speed). The value
  /// must be within the range `[minSpeedMultiplier, maxSpeedMultiplier]`.
  ///
  /// ## Returns
  ///
  /// The current speed multiplier.
  ///
  /// ## See also:
  ///
  /// - [setSpeedMultiplier] - Sets a new playback speed multiplier.
  /// - [minSpeedMultiplier] - Minimum allowed speed multiplier.
  /// - [maxSpeedMultiplier] - Maximum allowed speed multiplier.
  double get speedMultiplier {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PlaybackContainer',
      'getSpeedMultiplier',
    );
    return resultString['result'];
  }

  /// Sets the playback speed multiplier.
  ///
  /// ## Parameters
  ///
  /// - [speedMultiplier]: The new speed multiplier to apply. Must be within
  ///   the allowed range for this playback (see [minSpeedMultiplier] and
  ///   [maxSpeedMultiplier]).
  ///
  /// ## Also see:
  ///
  /// - [speedMultiplier] - Current speed multiplier.
  /// - [minSpeedMultiplier] - Minimum allowed speed multiplier.
  /// - [maxSpeedMultiplier] - Maximum allowed speed multiplier.
  GemError setSpeedMultiplier(final double speedMultiplier) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PlaybackContainer',
      'setSpeedMultiplier',
      args: speedMultiplier,
    );
    final int retVal = resultString['result'];
    return GemErrorExtension.fromCode(retVal);
  }

  /// The maximum allowed playback speed multiplier for this data source.
  ///
  /// Use this value as an upper bound when calling [setSpeedMultiplier].
  ///
  /// ## See also:
  ///
  /// - [setSpeedMultiplier] - Sets a new playback speed multiplier.
  /// - [speedMultiplier] - Current speed multiplier.
  double get maxSpeedMultiplier {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PlaybackContainer',
      'getMaxSpeedMultiplier',
    );
    return resultString['result'];
  }

  /// The minimum allowed playback speed multiplier for this data source.
  ///
  /// Use this value as a lower bound when calling [setSpeedMultiplier].
  ///
  /// ## See also:
  ///
  /// - [setSpeedMultiplier] - Sets a new playback speed multiplier.
  /// - [speedMultiplier] - Current speed multiplier.
  double get minSpeedMultiplier {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PlaybackContainer',
      'getMinSpeedMultiplier',
    );
    return resultString['result'];
  }

  /// The current playback position, in milliseconds from the start of the
  /// log or simulation.
  ///
  /// This value can be used to display progress or to seek by passing a new
  /// value to [setCurrentPosition].
  ///
  /// ## See also:
  ///
  /// - [getLatestData] - Accessing the current data during playback.
  int get currentPosition {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PlaybackContainer',
      'getCurrentPosition',
    );
    return resultString['result'];
  }

  /// Sets the current playback position.
  ///
  /// ## Parameters
  ///
  /// - [newPosition]: The new position to set, in milliseconds from the
  ///   beginning of the log or simulation.
  ///
  /// ## Returns
  ///
  /// - The previous playback position in milliseconds.
  ///
  /// ## See also:
  ///
  /// - [currentPosition] - Gets the current playback position.
  int setCurrentPosition(final int newPosition) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PlaybackContainer',
      'setCurrentPosition',
      args: newPosition,
    );
    return resultString['result'];
  }

  /// The total duration of the playback, in milliseconds.
  int get duration {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PlaybackContainer',
      'getDuration',
    );
    return resultString['result'];
  }

  /// Enables or disables continuous looping of the playback.
  ///
  /// ## Parameters
  ///
  /// - [loopMode]: `true` to loop continuously, `false` to disable looping.
  GemError setLoopMode(final bool loopMode) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PlaybackContainer',
      'setLoopMode',
      args: loopMode,
    );
    final int retVal = resultString['result'];
    return GemErrorExtension.fromCode(retVal);
  }

  /// Retrieves the latest produced [SenseData] of the requested [type].
  ///
  /// Returns the most recent sample for the given data type produced by the
  /// playback data source. If no data is available or an error occurs, this
  /// method returns `null`.
  ///
  /// ## Parameters
  ///
  /// - [type]: The [DataType] to request (for example, `DataType.position`).
  ///
  /// ## Returns
  ///
  /// - A [SenseData] instance when data is available, or `null` otherwise.
  SenseData? getLatestData(final DataType type) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PlaybackContainer',
      'getLatestPlaybackData',
      args: type.id,
    );

    if (resultString['gemApiError'] != 0) {
      return null;
    }

    final dynamic result = resultString['result'];
    if (result != null) {
      return senseFromJson(result);
    } else {
      return null;
    }
  }

  /// The file path of the log being played back.
  ///
  /// This is useful for UI, diagnostics, or when exporting playback details.
  String get logPath {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PlaybackContainer',
      'getLogPath',
    );
    return resultString['result'];
  }

  /// The route used by this playback when the data source is a simulation.
  ///
  /// Returns `null` when the playback is not a simulation or when no route is
  /// available.
  Route? get route {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PlaybackContainer',
      'getRoute',
    );
    final int retVal = resultString['result'];
    if (retVal == -1) {
      return null;
    }
    return Route.init(retVal);
  }
}
