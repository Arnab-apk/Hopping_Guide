// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Exception thrown when GemKit is not initialized
///
/// Use [GemKit.initialize] to initialize the GemKit before calling SDK methods
///
/// {@category Common}
class GemKitUninitializedException implements Exception {
  static const String message =
      "Native SDK not initialized! Please add the call 'await GemKit.initialize() ' in the main function, before calling 'runApp'";

  @override
  String toString() => message;
}

/// Exception thrown when an object is not alive
///
/// Used for debugging purposes
///
/// {@category Common}
class ObjectNotAliveException implements Exception {
  ObjectNotAliveException({required this.id, required this.json});
  final dynamic id;
  final Map<String, dynamic> json;

  @override
  String toString() => 'Object with id $id is not alive. Json: $json';
}

/// Exception thrown when a call is made on an object that depends on a disposed map.
///
/// {@category Common}
class MapDisposedException implements Exception {
  MapDisposedException({required this.id, required this.json});
  final dynamic id;
  final Map<String, dynamic> json;

  @override
  String toString() =>
      'Parent map controller with id $id is disposed. This object is no longer valid. Json: $json';
}

/// Exception thrown when a parameter with a given key value does not have the expected format.
///
/// {@category Common}
class InvalidParameterFormat implements Exception {
  InvalidParameterFormat(this.key);
  final String key;

  @override
  String toString() => 'Parameter with key $key has an invalid format.';
}
