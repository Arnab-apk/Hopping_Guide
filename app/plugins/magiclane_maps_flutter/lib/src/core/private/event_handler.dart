// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:async';

/// Interface for receiving events from the SDK.
///
/// The API user should not use this interface directly.
/// Use the provided listeners implementing this interface instead.
///
/// Concrete subclasses must implement [handleEvent], [nativeClear], and
/// [clearListeners]. Subclasses that `extends EventHandler` inherit the
/// default [dispose] template, which calls [nativeClear] before
/// [clearListeners]. Subclasses that `implements EventHandler` must
/// reimplement [dispose] using the same call order.
///
/// @nodoc
abstract class EventHandler {
  /// Method called when an event is dispatched from the native side.
  ///
  /// Should not be called by the user.
  void handleEvent(final Map<dynamic, dynamic> arguments);

  /// Releases bridge/native-side resources tied to this listener — for
  /// example, an unregister call against a global service or a Dart-side
  /// event-handler detach.
  ///
  /// Called by [dispose] before [clearListeners] so the event source is
  /// stopped before local references are severed: any straggler event that
  /// arrives in the window between the two calls still finds live callbacks
  /// and is delivered as it would have been, rather than silently no-oping
  /// against null fields mid-teardown.
  ///
  /// Listeners with no native-side state may leave the body empty.
  void nativeClear();

  /// Nulls all registered callback fields so the captured closures (and the
  /// objects they reference, such as widgets or controllers) become eligible
  /// for garbage collection.
  ///
  /// Called by [dispose] after [nativeClear].
  void clearListeners();

  /// Tears down this listener.
  ///
  /// The default implementation orchestrates [nativeClear] then
  /// [clearListeners]. Subclasses with extra teardown work, or those that
  /// `implements EventHandler` (and therefore cannot inherit this body),
  /// must override this and preserve the same call order.
  FutureOr<void> dispose() {
    nativeClear();
    clearListeners();
  }
}
