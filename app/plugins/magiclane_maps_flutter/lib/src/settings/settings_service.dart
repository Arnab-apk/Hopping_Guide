// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Service for storing persistent key/value application settings.
///
/// This object provides a simple typed key-value store persisted to a
/// platform-specific location. Values are stored inside a named "group" (the
/// default is `DEFAULT`) which can be changed with [beginGroup]/[endGroup].
///
/// Supported types: `String`, `bool`, `int` (32-bit), large `int` (64-bit),
/// and `double`. Changes are buffered and written to disk either automatically
/// or immediately when [flush] is called.
///
/// When multiple keys need to be retrieved or stored, the list-based methods
/// (e.g., [getStringList], [setIntList]) can be used for efficiency. Their
/// behavior is similar to the single-value methods, with the addition of
/// handling lists of keys and default values instead of single keys and default values.
///
/// ## Example
///
/// ```dart
/// final settings = SettingsService();
/// settings.setString('username', 'alice');
/// settings.setInt('launchCount', 1);
/// settings.flush(); // ensure values are persisted
/// final name = settings.getString('username', defaultValue: 'guest');
/// ```
///
/// {@category Settings}
class SettingsService extends GemAutoreleaseObject {
  /// Creates or opens a SettingsService at the given [path].
  ///
  /// If [path] is omitted the SDK will choose a platform-default storage
  /// location.
  ///
  /// ## Parameters
  ///
  /// - [path]: Optional filesystem path to the settings file.
  factory SettingsService({String? path}) {
    return _create(path: path);
  }
  SettingsService.init(super.id);

  /// The file system path where this [SettingsService] stores its values.
  ///
  /// ## Returns
  ///
  /// - The absolute path as a `String`.
  String get path {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SettingsService',
      'getPath',
    );

    return resultString['result'];
  }

  /// Force-write pending changes to permanent storage.
  ///
  /// The [SettingsService] may buffer writes for efficiency; calling [flush]
  /// ensures recent changes are persisted immediately.
  void flush() {
    objectMethod(pointerId, 'SettingsService', 'flush');
  }

  /// Begin a named group for subsequent keys.
  ///
  /// Group names are converted to upper-case. The default group is
  /// `DEFAULT`. Nested groups are not supported; calling [beginGroup]
  /// changes the active group and triggers a [flush].
  ///
  /// ## Parameters
  ///
  /// - [groupName]: The group name to activate.
  ///
  /// ## Also see:
  ///
  /// - [endGroup] - To end the current group.
  /// - [group] - To get the currently active group.
  void beginGroup(String groupName) {
    objectMethod(pointerId, 'SettingsService', 'beginGroup', args: groupName);

    flush();
  }

  /// End the current group and revert to `DEFAULT`.
  ///
  /// ## Also see:
  ///
  /// - [beginGroup] - To start a new group.
  /// - [group] - To get the currently active group.
  void endGroup() {
    objectMethod(pointerId, 'SettingsService', 'endGroup');

    flush();
  }

  /// The name of the currently active group.
  ///
  /// ## Returns
  ///
  /// - The active group name (upper-case). Defaults to `DEFAULT`.
  ///
  /// ## Also see:
  ///
  /// - [beginGroup]: to start a new group.
  /// - [endGroup]: to end the current group.
  String get group {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SettingsService',
      'getGroup',
    );

    return resultString['result'];
  }

  /// Store a `String` value for [key].
  ///
  /// ## Parameters
  ///
  /// - [key]: The key to set.
  /// - [value]: The string value to store.
  ///
  /// ## Also see:
  ///
  /// - [getString]: to retrieve a stored string value.
  void setString(final String key, final String value) {
    objectMethod(
      pointerId,
      'SettingsService',
      'setValueString',
      args: <String, dynamic>{'first': key, 'second': value},
    );
  }

  /// Store a list of string pairs.
  ///
  /// ## Parameters
  ///
  /// - [items]: The list of string pairs to store.
  ///
  /// ## Also see:
  ///
  /// - [getStringList]: to retrieve a stored list of string pairs.
  void setStringList(List<(String, String)> items) {
    final List<Pair<String, String>> pairs = items
        .map(
          (final (String, String) item) =>
              Pair<String, String>(item.$1, item.$2),
        )
        .toList();

    objectMethod(
      pointerId,
      'SettingsService',
      'setValueStringList',
      args: <String, dynamic>{'values': pairs},
    );
  }

  /// Store a `bool` value for [key].
  ///
  /// ## Parameters
  ///
  /// - [key]: The key to set.
  /// - [value]: The boolean value to store.
  ///
  /// ## Also see:
  ///
  /// - [getBool]: to retrieve a stored boolean value.
  void setBool(final String key, final bool value) {
    objectMethod(
      pointerId,
      'SettingsService',
      'setValueBool',
      args: <String, dynamic>{'first': key, 'second': value},
    );
  }

  /// Store a list of boolean pairs.
  ///
  /// ## Parameters
  ///
  /// - [items]: The list of boolean pairs to store.
  ///
  /// ## Also see:
  ///
  /// - [getBoolList]: to retrieve a stored list of boolean pairs.
  void setBoolList(List<(String, bool)> items) {
    final List<Pair<String, bool>> pairs = items
        .map(
          (final (String, bool) item) => Pair<String, bool>(item.$1, item.$2),
        )
        .toList();

    objectMethod(
      pointerId,
      'SettingsService',
      'setValueBoolList',
      args: <String, dynamic>{'values': pairs},
    );
  }

  /// Store a 32-bit `int` value for [key].
  ///
  /// If the value exceeds 32-bit range, use [setLargeInt] instead or
  /// overflow may occur.
  ///
  /// ## Parameters
  ///
  /// - [key]: The key to set.
  /// - [value]: The integer value to store.
  ///
  /// ## Also see:
  ///
  /// - [getInt]: to retrieve a stored integer value.
  void setInt(final String key, final int value) {
    objectMethod(
      pointerId,
      'SettingsService',
      'setValueInt',
      args: <String, dynamic>{'first': key, 'second': value},
    );
  }

  /// Store a list of integer pairs.
  ///
  /// ## Parameters
  ///
  /// - [items]: The list of integer pairs to store.
  ///
  /// ## Also see:
  ///
  /// - [getIntList]: to retrieve a stored list of integer pairs.
  void setIntList(List<(String, int)> items) {
    final List<Pair<String, int>> pairs = items
        .map((final (String, int) item) => Pair<String, int>(item.$1, item.$2))
        .toList();

    objectMethod(
      pointerId,
      'SettingsService',
      'setValueIntList',
      args: <String, dynamic>{'values': pairs},
    );
  }

  /// Store a 64-bit integer value for [key].
  ///
  /// Use this for values that need 64-bit precision.
  ///
  /// ## Parameters
  ///
  /// - [key]: The key to set.
  /// - [value]: The 64-bit integer value to store.
  ///
  /// ## Also see:
  ///
  /// - [getLargeInt]: to retrieve a stored 64-bit integer value.
  void setLargeInt(final String key, final int value) {
    objectMethod(
      pointerId,
      'SettingsService',
      'setValueInt64',
      args: <String, dynamic>{'first': key, 'second': value},
    );
  }

  /// Store a list of 64-bit integer pairs.
  ///
  /// ## Parameters
  ///
  /// - [items]: The list of 64-bit integer pairs to store.
  ///
  /// ## Also see:
  ///
  /// - [getLargeIntList]: to retrieve a stored list of 64-bit integer pairs.
  void setLargeIntList(List<(String, int)> items) {
    final List<Pair<String, int>> pairs = items
        .map((final (String, int) item) => Pair<String, int>(item.$1, item.$2))
        .toList();

    objectMethod(
      pointerId,
      'SettingsService',
      'setValueInt64List',
      args: <String, dynamic>{'values': pairs},
    );
  }

  /// Store a `double` value for [key].
  ///
  /// ## Parameters
  ///
  /// - [key]: The key to set.
  /// - [value]: The double value to store.
  ///
  /// ## Also see:
  ///
  /// - [getDouble]: to retrieve a stored double value.
  void setDouble(final String key, final double value) {
    objectMethod(
      pointerId,
      'SettingsService',
      'setValueDouble',
      args: <String, dynamic>{'first': key, 'second': value},
    );
  }

  /// Store a list of double pairs.
  ///
  /// ## Parameters
  ///
  /// - [items]: The list of double pairs to store.
  ///
  /// ## Also see:
  ///
  /// - [getDoubleList]: to retrieve a stored list of double pairs.
  void setDoubleList(List<(String, double)> items) {
    final List<Pair<String, double>> pairs = items
        .map(
          (final (String, double) item) =>
              Pair<String, double>(item.$1, item.$2),
        )
        .toList();

    objectMethod(
      pointerId,
      'SettingsService',
      'setValueDoubleList',
      args: <String, dynamic>{'values': pairs},
    );
  }

  /// Store multiple key-value pairs of various types in a single operation.
  ///
  /// This method allows setting multiple values of different types (string, bool, int, large int, double) at once, which can be more efficient than multiple individual calls.
  ///
  /// ## Parameters
  ///
  /// - [stringItems]: List of key-value pairs where the value is a `String`.
  /// - [boolItems]: List of key-value pairs where the value is a `bool
  /// - [intItems]: List of key-value pairs where the value is a 32-bit `int`.
  /// - [largeIntItems]: List of key-value pairs where the value is a
  /// 64-bit `int`.
  /// - [doubleItems]: List of key-value pairs where the value is a `double`.
  ///
  /// ## Also see:
  ///
  /// - [getBatch]: to retrieve multiple values of various types in a single operation.
  void setBatch({
    List<(String, String)> stringItems = const <(String, String)>[],
    List<(String, bool)> boolItems = const <(String, bool)>[],
    List<(String, int)> intItems = const <(String, int)>[],
    List<(String, int)> largeIntItems = const <(String, int)>[],
    List<(String, double)> doubleItems = const <(String, double)>[],
  }) {
    final List<Pair<String, String>> stringPairs = stringItems
        .map(
          (final (String, String) item) =>
              Pair<String, String>(item.$1, item.$2),
        )
        .toList();
    final List<Pair<String, bool>> boolPairs = boolItems
        .map(
          (final (String, bool) item) => Pair<String, bool>(item.$1, item.$2),
        )
        .toList();
    final List<Pair<String, int>> intPairs = intItems
        .map((final (String, int) item) => Pair<String, int>(item.$1, item.$2))
        .toList();
    final List<Pair<String, int>> largeIntPairs = largeIntItems
        .map((final (String, int) item) => Pair<String, int>(item.$1, item.$2))
        .toList();
    final List<Pair<String, double>> doublePairs = doubleItems
        .map(
          (final (String, double) item) =>
              Pair<String, double>(item.$1, item.$2),
        )
        .toList();

    objectMethod(
      pointerId,
      'SettingsService',
      'setBatch',
      args: <String, dynamic>{
        'stringValues': <String, dynamic>{'values': stringPairs},
        'boolValues': <String, dynamic>{'values': boolPairs},
        'intValues': <String, dynamic>{'values': intPairs},
        'largeIntValues': <String, dynamic>{'values': largeIntPairs},
        'doubleValues': <String, dynamic>{'values': doublePairs},
      },
    );
  }

  /// Retrieve multiple key-value pairs of various types in a single operation.
  ///
  /// This method allows retrieving multiple values of different types (string, bool, int, large int, double) at once, which can be more efficient than multiple individual calls. For each type, you can specify a list of keys and corresponding default values to return if a key is not found.
  ///
  /// ## Parameters
  ///
  /// - [stringKeys]: List of keys to retrieve string values for.
  /// - [defaultStringValues]: List of default string values to return for missing keys.
  /// - [boolKeys]: List of keys to retrieve boolean values for.
  /// - [defaultBoolValues]: List of default boolean values to return for missing keys.
  /// - [intKeys]: List of keys to retrieve 32-bit integer values for.
  /// - [defaultIntValues]: List of default integer values to return for missing keys.
  /// - [largeIntKeys]: List of keys to retrieve 64-bit integer values for
  /// - [defaultLargeIntValues]: List of default 64-bit integer values to return for missing keys.
  /// - [doubleKeys]: List of keys to retrieve double values for.
  /// - [defaultDoubleValues]: List of default double values to return for missing keys.
  ///
  /// ## Returns
  ///
  /// - A [BatchResult] object containing maps of keys to their corresponding retrieved values for each type.
  BatchResult getBatch({
    List<String> stringKeys = const <String>[],
    List<String>? defaultStringValues,
    List<String> boolKeys = const <String>[],
    List<bool>? defaultBoolValues,
    List<String> intKeys = const <String>[],
    List<int>? defaultIntValues,
    List<String> largeIntKeys = const <String>[],
    List<int>? defaultLargeIntValues,
    List<String> doubleKeys = const <String>[],
    List<double>? defaultDoubleValues,
  }) {
    final OperationResult result = objectMethod(
      pointerId,
      'SettingsService',
      'getBatch',
      args: <String, dynamic>{
        'stringKeys': stringKeys,
        'defaultStringValues':
            defaultStringValues ?? List<String>.filled(stringKeys.length, ''),
        'boolKeys': boolKeys,
        'defaultBoolValues':
            defaultBoolValues ?? List<bool>.filled(boolKeys.length, false),
        'intKeys': intKeys,
        'defaultIntValues':
            defaultIntValues ?? List<int>.filled(intKeys.length, 0),
        'largeIntKeys': largeIntKeys,
        'defaultLargeIntValues':
            defaultLargeIntValues ?? List<int>.filled(largeIntKeys.length, 0),
        'doubleKeys': doubleKeys,
        'defaultDoubleValues':
            defaultDoubleValues ?? List<double>.filled(doubleKeys.length, 0.0),
      },
    );

    final Map<String, dynamic> resultMap =
        (result['result'] as Map<dynamic, dynamic>).cast<String, dynamic>();
    return BatchResult(
      stringValues: _decodeBatchValues<String>(
        resultMap['stringValues'],
        (dynamic value) => value as String,
      ),
      boolValues: _decodeBatchValues<bool>(resultMap['boolValues'], (
        dynamic value,
      ) {
        if (value is bool) {
          return value;
        }
        return (value as int) != 0;
      }),
      intValues: _decodeBatchValues<int>(
        resultMap['intValues'],
        (dynamic value) => (value as num).toInt(),
      ),
      largeIntValues: _decodeBatchValues<int>(
        resultMap['largeIntValues'],
        (dynamic value) => (value as num).toInt(),
      ),
      doubleValues: _decodeBatchValues<double>(
        resultMap['doubleValues'],
        (dynamic value) => (value as num).toDouble(),
      ),
    );
  }

  List<T> _decodeBatchValues<T>(
    dynamic rawValues,
    T Function(dynamic value) decodeValue,
  ) {
    if (rawValues == null) {
      return <T>[];
    }

    if (rawValues is List<dynamic>) {
      return _decodeBatchValueList<T>(rawValues, decodeValue);
    }

    if (rawValues is Map<dynamic, dynamic>) {
      if (rawValues['values'] is List<dynamic>) {
        return _decodeBatchValueList<T>(
          rawValues['values'] as List<dynamic>,
          decodeValue,
        );
      }

      return rawValues.values
          .map<T>((dynamic value) => decodeValue(value))
          .toList();
    }

    return <T>[];
  }

  List<T> _decodeBatchValueList<T>(
    List<dynamic> rawList,
    T Function(dynamic value) decodeValue,
  ) {
    final List<T> decoded = <T>[];

    for (final dynamic item in rawList) {
      if (item is Map<dynamic, dynamic>) {
        decoded.add(decodeValue(item['second']));
      } else {
        decoded.add(decodeValue(item));
      }
    }

    return decoded;
  }

  /// Retrieve a `String` value for [key].
  ///
  /// If the key does not exist the [defaultValue] is returned.
  ///
  /// ## Parameters
  ///
  /// - [key]: The key to look up.
  /// - [defaultValue]: Value returned when the key is missing (defaults to `''`).
  ///
  /// ## Returns
  ///
  /// - The stored string value, or [defaultValue] if not found.
  ///
  /// ## Also see:
  ///
  /// - [setString]: to store a string value.
  String getString(final String key, {String defaultValue = ''}) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SettingsService',
      'getValueString',
      args: <String, dynamic>{'first': key, 'second': defaultValue},
    );

    return resultString['result'];
  }

  /// Retrieve a list of `String` values for [keys].
  ///
  /// If a key does not exist the corresponding value from [defaultValues] is returned.
  ///
  /// ## Parameters
  ///
  /// - [keys]: The list of keys to look up.
  /// - [defaultValues]: List of default values returned when keys are missing. If is provided,
  /// its length must match the length of [keys]. If omitted, empty strings are used as defaults.
  ///
  /// ## Returns
  ///
  /// - The list of stored string values, or corresponding [defaultValues] if not found.
  /// - If [defaultValues] length does not match [keys] length, an empty list is returned and
  ///  [GemError.invalidInput] is set in [ApiErrorService.apiError].
  ///
  /// ## Also see:
  ///
  /// - [setStringList]: to store a list of string values.
  List<String> getStringList(List<String> keys, {List<String>? defaultValues}) {
    if (defaultValues != null && defaultValues.length != keys.length) {
      ApiErrorServiceImpl.apiError = GemError.invalidInput;
      return <String>[];
    }

    final OperationResult resultString = objectMethod(
      pointerId,
      'SettingsService',
      'getValueStringList',
      args: <String, dynamic>{
        'keys': keys,
        'defaultValues': defaultValues ?? List<String>.filled(keys.length, ''),
      },
    );

    final List<dynamic> resultList = resultString['result'];
    return resultList.cast<String>().toList();
  }

  /// Retrieve a `bool` value for [key].
  ///
  /// If the key does not exist the [defaultValue] is returned.
  ///
  /// ## Parameters
  ///
  /// - [key]: The key to look up.
  /// - [defaultValue]: Value returned when the key is missing (defaults to `false`).
  ///
  /// ## Returns
  ///
  /// - The stored boolean value, or [defaultValue] if not found.
  ///
  /// ## Also see:
  ///
  /// - [setBool]: to store a boolean value.
  bool getBool(final String key, {bool defaultValue = false}) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SettingsService',
      'getValueBool',
      args: <String, dynamic>{'first': key, 'second': defaultValue},
    );

    return resultString['result'];
  }

  /// Retrieve a list of `bool` values for [keys].
  ///
  /// If a key does not exist the corresponding value from [defaultValues] is returned.
  ///
  /// ## Parameters
  ///
  /// - [keys]: The list of keys to look up.
  /// - [defaultValues]: List of default values returned when keys are missing. If is
  /// provided, its length must match the length of [keys]. If omitted, false values are used as defaults.
  ///
  /// ## Returns
  ///
  /// - The list of stored boolean values, or corresponding [defaultValues] if not found.
  /// - If [defaultValues] length does not match [keys] length, an empty list is returned and
  ///  [GemError.invalidInput] is set in [ApiErrorService.apiError].
  ///
  /// ## Also see:
  ///
  /// - [setBoolList]: to store a list of boolean values.
  List<bool> getBoolList(List<String> keys, {List<bool>? defaultValues}) {
    if (defaultValues != null && defaultValues.length != keys.length) {
      ApiErrorServiceImpl.apiError = GemError.invalidInput;
      return <bool>[];
    }

    final OperationResult resultString = objectMethod(
      pointerId,
      'SettingsService',
      'getValueBoolList',
      args: <String, dynamic>{
        'keys': keys,
        'defaultValues': defaultValues ?? List<bool>.filled(keys.length, false),
      },
    );

    final List<dynamic> resultList = resultString['result'];
    return resultList.cast<int>().map((int e) => e != 0).toList();
  }

  /// Retrieve a 32-bit `int` value for [key].
  ///
  /// If the key does not exist the [defaultValue] is returned.
  ///
  /// If the value exceeds 32-bit range, use [getLargeInt] instead or
  /// overflow may occur.
  ///
  /// ## Parameters
  ///
  /// - [key]: The key to look up.
  /// - [defaultValue]: Value returned when the key is missing (defaults to `0`).
  ///
  /// ## Returns
  ///
  /// - The stored integer value, or [defaultValue] if not found.
  ///
  /// ## Also see:
  ///
  /// - [setInt]: to store a integer value.
  int getInt(final String key, {int defaultValue = 0}) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SettingsService',
      'getValueInt',
      args: <String, dynamic>{'first': key, 'second': defaultValue},
    );

    return resultString['result'];
  }

  /// Retrieve a list of 32-bit `int` values for [keys].
  ///
  /// If a key does not exist the corresponding value from [defaultValues] is returned.
  ///
  /// ## Parameters
  ///
  /// - [keys]: The list of keys to look up.
  /// - [defaultValues]: List of default values returned when keys are missing. If is
  /// provided, its length must match the length of [keys]. If omitted, zeros are
  /// used as defaults.
  ///
  /// ## Returns
  ///
  /// - The list of stored integer values, or corresponding [defaultValues] if not found.
  /// - If [defaultValues] length does not match [keys] length, an empty list is returned and
  ///  [GemError.invalidInput] is set in [ApiErrorService.apiError].
  ///
  /// ## Also see:
  ///
  /// - [setIntList]: to store a list of integer values.
  List<int> getIntList(List<String> keys, {List<int>? defaultValues}) {
    if (defaultValues != null && defaultValues.length != keys.length) {
      ApiErrorServiceImpl.apiError = GemError.invalidInput;
      return <int>[];
    }

    final OperationResult resultString = objectMethod(
      pointerId,
      'SettingsService',
      'getValueIntList',
      args: <String, dynamic>{
        'keys': keys,
        'defaultValues': defaultValues ?? List<int>.filled(keys.length, 0),
      },
    );

    final List<dynamic> resultList = resultString['result'];
    return resultList.cast<int>().toList();
  }

  /// Retrieve a 64-bit integer value for [key].
  ///
  /// If the key does not exist the [defaultValue] is returned.
  ///
  /// ## Parameters
  ///
  /// - [key]: The key to look up.
  /// - [defaultValue]: Value returned when the key is missing (defaults to `0`).
  ///
  /// ## Returns
  ///
  /// - The stored 64-bit integer value, or [defaultValue] if not found.
  ///
  /// ## Also see:
  ///
  /// - [setLargeInt]: to store a 64-bit integer value.
  int getLargeInt(final String key, {int defaultValue = 0}) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SettingsService',
      'getValueInt64',
      args: <String, dynamic>{'first': key, 'second': defaultValue},
    );

    return resultString['result'];
  }

  /// Retrieve a list of 64-bit integer values for [keys].
  ///
  /// If a key does not exist the corresponding value from [defaultValues] is returned.
  ///
  /// ## Parameters
  ///
  /// - [keys]: The list of keys to look up.
  /// - [defaultValues]: List of default values returned when keys are missing. If is
  /// provided, its length must match the length of [keys]. If omitted, zeros are
  /// used as defaults.
  ///
  /// ## Returns
  ///
  /// - The list of stored 64-bit integer values, or corresponding [defaultValues] if not found.
  /// - If [defaultValues] length does not match [keys] length, an empty list is returned and
  /// [GemError.invalidInput] is set in [ApiErrorService.apiError].
  ///
  /// ## Also see:
  ///
  /// - [setLargeIntList]: to store a list of 64-bit integer values.
  List<int> getLargeIntList(List<String> keys, {List<int>? defaultValues}) {
    if (defaultValues != null && defaultValues.length != keys.length) {
      ApiErrorServiceImpl.apiError = GemError.invalidInput;
      return <int>[];
    }

    final OperationResult resultString = objectMethod(
      pointerId,
      'SettingsService',
      'getValueInt64List',
      args: <String, dynamic>{
        'keys': keys,
        'defaultValues': defaultValues ?? List<int>.filled(keys.length, 0),
      },
    );

    final List<dynamic> resultList = resultString['result'];
    return resultList.cast<int>().toList();
  }

  /// Retrieve a `double` value for [key].
  ///
  /// If the key does not exist the [defaultValue] is returned.
  ///
  /// ## Parameters
  ///
  /// - [key]: The key to look up.
  /// - [defaultValue]: Value returned when the key is missing (defaults to `0.0`).
  ///
  /// ## Returns
  ///
  /// - The stored double value, or [defaultValue] if not found.
  ///
  /// ## Also see:
  ///
  /// - [setDouble]: to store a double value.
  double getDouble(final String key, {double defaultValue = 0.0}) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SettingsService',
      'getValueDouble',
      args: <String, dynamic>{'first': key, 'second': defaultValue},
    );

    return resultString['result'];
  }

  /// Retrieve a list of `double` values for [keys].
  ///
  /// If a key does not exist the corresponding value from [defaultValues] is returned.
  ///
  /// ## Parameters
  ///
  /// - [keys]: The list of keys to look up.
  /// - [defaultValues]: List of default values returned when keys are missing. If is
  /// provided, its length must match the length of [keys]. If omitted, zeros are
  /// used as defaults.
  ///
  /// ## Returns
  ///
  /// - The list of stored double values, or corresponding [defaultValues] if not found.
  /// - If [defaultValues] length does not match [keys] length, an empty list is returned and
  /// [GemError.invalidInput] is set in [ApiErrorService.apiError].
  ///
  /// ## Also see:
  ///
  /// - [setDoubleList]: to store a list of double values.
  List<double> getDoubleList(List<String> keys, {List<double>? defaultValues}) {
    if (defaultValues != null && defaultValues.length != keys.length) {
      ApiErrorServiceImpl.apiError = GemError.invalidInput;
      return <double>[];
    }

    final OperationResult resultString = objectMethod(
      pointerId,
      'SettingsService',
      'getValueDoubleList',
      args: <String, dynamic>{
        'keys': keys,
        'defaultValues': defaultValues ?? List<double>.filled(keys.length, 0.0),
      },
    );

    final List<dynamic> resultList = resultString['result'];
    return resultList.cast<double>().toList();
  }

  /// Remove the specified setting key or keys matching a pattern.
  ///
  /// Use the wildcard `*` to remove all keys matching a pattern.
  ///
  /// ## Parameters
  ///
  /// - [key]: The key or pattern to remove.
  ///
  /// ## Returns
  ///
  /// - The number of keys removed.
  ///
  /// ## Also see:
  ///
  /// - [clear]: to remove all settings.
  int remove(final String key) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SettingsService',
      'remove',
      args: key,
    );

    return resultString['result'];
  }

  /// Remove all settings.
  ///
  /// This clears the complete storage for the current settings file.
  ///
  /// ## Also see:
  ///
  /// - [remove]: to remove specific keys.
  void clear() {
    objectMethod(pointerId, 'SettingsService', 'clear');
  }

  /// Create the native SettingsService instance.
  ///
  /// @nodoc
  static SettingsService _create({String? path}) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{
        'class': 'SettingsService',
        if (path != null) 'args': path,
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final SettingsService retVal = SettingsService.init(decodedVal['result']);
    return retVal;
  }
}

/// Result object for batch retrieval of settings values.
///
/// This class encapsulates the results of a batch retrieval operation,
/// containing values in the same order as the requested keys for each
/// supported type (string, bool, int, large int, double).
///
/// ## Also see:
///
/// - [SettingsService.getBatch]: to retrieve multiple values of various types in a single operation.
class BatchResult {
  /// Creates a BatchResult with the given maps of values.
  ///
  /// ## Parameters
  ///
  /// - [stringValues]: List of string values.
  /// - [boolValues]: List of boolean values.
  /// - [intValues]: List of 32-bit integer values.
  /// - [largeIntValues]: List of 64-bit integer values.
  /// - [doubleValues]: List of double values.
  BatchResult({
    required this.stringValues,
    required this.boolValues,
    required this.intValues,
    required this.largeIntValues,
    required this.doubleValues,
  });

  /// Retrieved string values in request order.
  final List<String> stringValues;

  /// Retrieved boolean values in request order.
  final List<bool> boolValues;

  /// Retrieved 32-bit integer values in request order.
  final List<int> intValues;

  /// Retrieved 64-bit integer values in request order.
  final List<int> largeIntValues;

  /// Retrieved double values in request order.
  final List<double> doubleValues;
}
