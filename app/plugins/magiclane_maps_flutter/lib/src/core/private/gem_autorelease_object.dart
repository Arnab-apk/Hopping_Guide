// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/src/core/common/gem_object_interface.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// This class is the base class for all objects that are automatically released
/// from C++ when no longer used in Dart.
///
/// This class should not be instantiated directly.
/// The API user is not expected to use this class directly.
///
/// @nodoc
class GemAutoreleaseObject {
  GemAutoreleaseObject(this._pointerId) {
    registerAutoReleaseObject(pointerId);
  }
  bool hasRegisteredAutoReleaseObject = false;
  bool _disposed = false;
  // ignore: unused_field
  late GemObject _gemObject;

  /// The timestamp when the dart object was created
  ///
  /// Used to make sure the correct object is released
  final int _timestamp = DateTime.now().millisecondsSinceEpoch;

  /// The pointer ID of the native object
  ///
  /// Used to identify the object in the native pool
  final int _pointerId;

  /// The pointer ID of the native object
  ///
  /// Used to identify the object in the native pool
  /// Should not be used directly by the API user
  int get pointerId => _pointerId;

  /// Registers an object for auto release.
  ///
  /// When the object is not used anymore, it will be released automatically from C++.
  /// Should not be used directly by the API user.
  void registerAutoReleaseObject(final int pointerId) {
    if (hasRegisteredAutoReleaseObject) {
      return;
    }
    hasRegisteredAutoReleaseObject = true;
    _gemObject = GemKitPlatform.instance.registerWeakRelease(
      this,
      pointerId,
      _timestamp,
    );
  }

  /// Disposes the native object.
  ///
  /// The object can be disposed manually to free up resources immediately.
  /// Can be invoked by the API user when the object is no longer needed.
  /// Double dispose is a no-op.
  ///
  /// This step is not normally required, as the object will be released automatically
  /// when no longer used in Dart.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    GemKitPlatform.instance.callDeleteObject(
      jsonEncode(<String, Object>{'class': 'Any', 'id': _pointerId}),
    );
  }
}
