// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Abstract interface for tracking progress of asynchronous operations.
///
/// Use implementations of [ProgressListener] to receive progress updates,
/// status changes and completion notifications for long-running SDK
/// operations such as routing, downloads, content updates and searches.
///
/// Implementations are provided by the SDK (for example `EventDrivenProgressListener`) and
/// returned by async methods that start long-running work.
///
/// This class should not directly be instantiated by consumers.
/// Instead, use SDK-provided methods that return progress listeners.
///
/// {@category Common}
abstract class ProgressListener {
  /// Register a callback invoked when the operation completes.
  ///
  /// The callback receives three arguments describing the completion:
  /// - [err]: Integer error code (0 for success).
  /// - [hint]: Human-readable hint or brief message about the result.
  /// - [json]: Additional structured data provided by the operation.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function called when the operation has completed.
  ///     - [err] (int): Result error code.
  ///     - [hint] (String): Informational hint about the completion.
  ///     - [json] (`Map<dynamic, dynamic>`): Optional additional data.
  void registerOnCompleteWithData(
    final void Function(int err, String hint, Map<dynamic, dynamic> json)
    callback,
  );

  /// Register a callback to receive progress updates.
  ///
  /// Progress values are integers in the range `[0, progressMultiplier]`. The
  /// SDK internally uses a floating point value in the `[0.0, 1.0]` interval
  /// and scales it using [progressMultiplier] before issuing notifications.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function invoked for progress updates with a single
  ///   integer parameter representing the current progress value.
  void registerOnProgress(final void Function(int progress) callback);

  /// Register a callback invoked when the operation status changes.
  ///
  /// The SDK reports status changes as integer codes. Consumers should map
  /// these codes to meaningful enums or values as appropriate for the
  /// operation.
  ///
  /// ## Parameters
  ///
  /// - [callback]: Function invoked with the new status code as an integer.
  void registerOnNotifyStatusChanged(final void Function(int status) callback);

  /// The multiplier used to scale internal floating-point progress values.
  ///
  /// The SDK represents fractional progress internally as a floating point
  /// number in the closed interval `[0.0, 1.0]`. Before sending progress
  /// updates to Dart callbacks the SDK multiplies that value by
  /// [progressMultiplier] and rounds to an integer. The default multiplier is
  /// 100, which yields progress values that resemble percentages.
  ///
  /// ## Returns
  ///
  /// - The integer multiplier used by the SDK when emitting progress values.
  int get progressMultiplier;

  /// Interval (in milliseconds) between progress notifications.
  ///
  /// The default value is 200 (5 updates per second). Callers may adjust the
  /// interval via the setter to reduce or increase notification frequency.
  ///
  /// ## Returns
  ///
  /// - Integer interval in milliseconds used for progress notifications.
  int get notifyProgressInterval;

  /// Sets the interval between progress notifications in milliseconds.
  ///
  /// The provided value must be a non-negative integer.
  ///
  /// ## Parameters
  ///
  /// - [ms]: Interval in milliseconds (non-negative).
  set notifyProgressInterval(final int ms);

  /// Used by the SDK to notify about a progress change.
  ///
  /// Should not be called directly by consumers.
  ///
  /// ## Also see:
  ///
  /// - [registerOnProgress] - Register a callback to receive progress updates.
  @internal
  void notifyProgress(final int progress);

  /// Notify the listener about a status change. Internal API.
  ///
  /// Should not be called directly by consumers.
  ///
  /// ## Also see:
  ///
  /// - [registerOnNotifyStatusChanged] - Register a callback for status changes.
  @internal
  void notifyStatusChanged(final int status);

  /// Internal notification used when an operation starts.
  ///
  /// Should not be called directly by consumers.
  @internal
  void notifyStart(final bool hasProgress);

  /// Internal notification invoked when an operation completes.
  ///
  /// Should not be called directly by consumers.
  ///
  /// ## Also see:
  ///
  /// - [registerOnCompleteWithData] - Register a callback to receive completion notifications.
  @internal
  void notifyCompleteWithData(
    final int err,
    final String hint,
    final Map<dynamic, dynamic> json,
  ) {
    notifyComplete(err, hint);
  }

  /// Internal notification invoked when an operation completes.
  ///
  /// Should not be called directly by consumers.
  @internal
  void notifyComplete(final int err, final String hint);

  int _pointerId = 0;

  /// Unique identifier for this listener (native pointer id).
  ///
  /// Used internally by the SDK to correlate native events with this
  dynamic get id => _pointerId;

  /// Unique identifier for this listener (native pointer id).
  ///
  /// Used internally by the SDK to correlate native events with this
  set id(final dynamic id) => _pointerId = id;
}
