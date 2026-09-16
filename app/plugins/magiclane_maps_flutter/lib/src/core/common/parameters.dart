// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Types of parameter values supported by the SDK.
///
/// The [ValueType] enum describes the concrete type stored inside a
/// [GemParameter]. Use it to determine how to interpret the parameter
/// [GemParameter.value] when reading parameters returned by SDK APIs.
///
/// Values:
/// - [invalid]: Placeholder for an invalid or unset value.
/// - [bool]: Boolean value.
/// - [int]: 64-bit integer value.
/// - [real]: Floating point (double) value.
/// - [string]: Text string value.
/// - [list]: Nested list of parameters ([ParameterList]).
///
/// {@category Common}
enum ValueType {
  /// Invalid type.
  invalid,

  /// Bool value.
  bool,

  /// 64 bit int value.
  int,

  /// Double value
  real,

  /// String value
  string,

  /// List value
  list,
}

/// @nodoc
extension ValueTypeExtension on ValueType {
  int get id {
    switch (this) {
      case ValueType.invalid:
        return 0;
      case ValueType.bool:
        return 1;
      case ValueType.int:
        return 2;
      case ValueType.real:
        return 3;
      case ValueType.string:
        return 4;
      case ValueType.list:
        return 5;
    }
  }

  static ValueType fromId(final int id) {
    switch (id) {
      case 0:
        return ValueType.invalid;
      case 1:
        return ValueType.bool;
      case 2:
        return ValueType.int;
      case 3:
        return ValueType.real;
      case 4:
        return ValueType.string;
      case 5:
        return ValueType.list;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// A single typed parameter used across the SDK.
///
/// A [GemParameter] holds a triple: a unique [key], a typed [value], and an
/// optional localized [name]. The [type] property indicates how to interpret
/// [value] (see [ValueType]). Parameters frequently appear inside
/// [ParameterList] and [SearchableParameterList] containers returned by
/// various SDK APIs (for example content metadata or overlay preview data).
///
/// Use [asJson] to obtain a deeply structured representation suitable for
/// serialization or for sending to platform code. Use [toJson] when a compact
/// bridge-friendly representation is required (lists are represented by
/// pointer ids in that case).
///
/// {@category Common}
class GemParameter {
  /// Constructs a parameter object with optional fields.
  ///
  /// The constructor stores the provided values directly. Callers should
  /// ensure [type], [key] and [value] are consistent. Typical usage is to
  /// build parameters before passing them to SDK APIs or to deserialize them
  /// via [GemParameter.fromJson].
  GemParameter({this.type, this.value, this.name, this.key});

  /// Creates a boolean [GemParameter].
  ///
  /// ## Parameters
  ///
  /// - [key]: Unique parameter identifier.
  /// - [value]: Boolean value to store.
  /// - [name]: Optional localized display name.
  ///
  /// ## Returns
  ///
  /// - A new [GemParameter] with [type] set to [ValueType.bool].
  factory GemParameter.withBool({
    required final String key,
    required final bool value,
    final String? name,
  }) {
    return GemParameter(
      key: key,
      type: ValueType.bool,
      value: value,
      name: name,
    );
  }

  /// Creates an integer [GemParameter].
  ///
  /// ## Parameters
  ///
  /// - [key]: Unique parameter identifier.
  /// - [value]: Integer value to store.
  /// - [name]: Optional localized display name.
  ///
  /// ## Returns
  ///
  /// - A new [GemParameter] with [type] set to [ValueType.int].
  factory GemParameter.withInt({
    required final String key,
    required final int value,
    final String? name,
  }) {
    return GemParameter(
      key: key,
      type: ValueType.int,
      value: value,
      name: name,
    );
  }

  /// Creates a real (double) [GemParameter].
  ///
  /// ## Parameters
  ///
  /// - [key]: Unique parameter identifier.
  /// - [value]: Double value to store.
  /// - [name]: Optional localized display name.
  ///
  /// ## Returns
  ///
  /// - A new [GemParameter] with [type] set to [ValueType.real].
  factory GemParameter.withReal({
    required final String key,
    required final double value,
    final String? name,
  }) {
    return GemParameter(
      key: key,
      type: ValueType.real,
      value: value,
      name: name,
    );
  }

  /// Creates a string [GemParameter].
  ///
  /// ## Parameters
  ///
  /// - [key]: Unique parameter identifier.
  /// - [value]: String value to store.
  /// - [name]: Optional localized display name.
  ///
  /// ## Returns
  ///
  /// - A new [GemParameter] with [type] set to [ValueType.string].
  factory GemParameter.withString({
    required final String key,
    required final String value,
    final String? name,
  }) {
    return GemParameter(
      key: key,
      type: ValueType.string,
      value: value,
      name: name,
    );
  }

  /// Creates a list-valued [GemParameter].
  ///
  /// The [value] must be a [ParameterList] instance. This form is used when a
  /// parameter logically contains a nested list of parameters.
  ///
  /// ## Parameters
  ///
  /// - [key]: Unique parameter identifier.
  /// - [value]: [ParameterList] containing nested parameters.
  /// - [name]: Optional localized display name.
  ///
  /// ## Returns
  ///
  /// - A new [GemParameter] with [type] set to [ValueType.list].
  factory GemParameter.withList({
    required final String key,
    required final ParameterList value,
    final String? name,
  }) {
    return GemParameter(
      key: key,
      type: ValueType.list,
      value: value,
      name: name,
    );
  }

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory GemParameter.fromJson(final Map<String, dynamic> json) {
    final ValueType type = ValueTypeExtension.fromId(json['type']);
    dynamic value = json['value'];

    if (type == ValueType.list) {
      value = ParameterList.init(json['value']);
    }

    return GemParameter(
      type: ValueTypeExtension.fromId(json['type']),
      value: value,
      name: json['name'],
      key: json['key'],
    );
  }

  /// The parameter type.
  ValueType? type;

  /// The parameter value.
  dynamic value;

  /// The parameter name.
  String? name;

  /// The parameter key.
  String? key;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    if (type != null) {
      json['type'] = type!.id;
    }
    if (value != null) {
      if (type == ValueType.list) {
        json['value'] = (value as ParameterList).pointerId;
      } else {
        json['value'] = value;
      }
    }
    if (name != null) {
      json['name'] = name;
    }
    if (key != null) {
      json['key'] = key;
    }
    return json;
  }

  /// Returns the parameters as a deeply structured JSON object (the lists
  /// contained within will be expanded).
  ///
  /// Includes the [GemParameter.key], [GemParameter.value], and, if
  /// available, [GemParameter.name]. The [GemParameter.value] is formatted
  /// according to its [GemParameter.type].
  ///
  /// Returns null if [GemParameter.key], [GemParameter.value], or
  /// [GemParameter.type] are null.
  Map<String, dynamic>? asJson() {
    if (type == null || value == null || key == null) {
      return null;
    }
    if (type == ValueType.invalid) {
      return null;
    }

    return <String, dynamic>{
      'key': key,
      if (name != null) 'name': name,
      'value': value is! ParameterList ? value : value.asJson(),
    };
  }

  @override
  bool operator ==(covariant final GemParameter other) {
    if (identical(this, other)) {
      return true;
    }

    return other.type == type &&
        other.value == value &&
        other.name == name &&
        other.key == key;
  }

  @override
  int get hashCode {
    return value.hashCode ^ name.hashCode ^ key.hashCode;
  }
}

/// Searchable parameters list.
///
/// [ParameterList] is a container of [GemParameter] instances.
/// Use [toList] to obtain a Dart [List<GemParameter>], or
/// [asJson] to obtain a deeply structured JSON representation.
///
/// {@category Common}
class ParameterList extends GemList<GemParameter> {
  /// Create a new [ParameterList] object.
  factory ParameterList() {
    return ParameterList._create();
  }

  @internal
  ParameterList.init(final dynamic id, {final String? className})
    : super(
        id,
        className ?? 'ParameterList',
        (final dynamic data) => GemParameter.fromJson(data),
      ) {
    registerAutoReleaseObject(id);
  }

  static ParameterList _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'ParameterList'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return ParameterList.init(decodedVal['result']);
  }

  /// Adds a new parameter to the list.
  ///
  /// If the [parameter] does not provide a [GemParameter.name],
  /// the [GemParameter.key] will be used instead.
  ///
  /// ## Parameters
  ///
  /// - [parameter]: The [GemParameter] to add.
  void add(final GemParameter parameter) {
    objectMethod(
      super.pointerId,
      'ParameterList',
      'push_back',
      args: parameter.toJson(),
    );
  }

  @override
  List<GemParameter> toList({final bool growable = true}) {
    final OperationResult result = objectMethod(
      super.pointerId,
      'ParameterList',
      'toList',
    );

    return (result['result'] as List<dynamic>)
        .map((dynamic e) => GemParameter.fromJson(e))
        .toList(growable: growable);
  }

  /// Returns the parameters as a deeply structured JSON list.
  ///
  /// Each entry includes the [GemParameter.key], [GemParameter.value], and,
  /// if available, [GemParameter.name]. The [GemParameter.value] is formatted
  /// according to its [GemParameter.type]. Only parameters with non-null
  /// [GemParameter.key], [GemParameter.value], and [GemParameter.type] are
  /// included in the returned list.
  ///
  /// ## Returns
  ///
  /// - A [List] of maps suitable for serialization or inspection.
  List<Map<String, dynamic>> asJson() {
    final List<Map<String, dynamic>> json = <Map<String, dynamic>>[];
    for (final GemParameter param in this) {
      final Map<String, dynamic>? parsedParam = param.asJson();
      if (parsedParam != null) {
        json.add(parsedParam);
      }
    }

    return json;
  }
}

/// Searchable parameters list.
///
/// [SearchableParameterList] extends [ParameterList] adding convenience search
/// helpers to find parameters by their [GemParameter.key].
///
/// Use [find], [findAll] and [findParameter] to retrieve parameter values or
/// display names by key.
///
/// {@category Common}
class SearchableParameterList extends ParameterList {
  /// Create a new [SearchableParameterList] object.
  ///
  /// ## Parameters
  ///
  /// - [parameterList]: Optional parameter list used to initialize the
  ///   searchable list. If omitted an empty list is created.
  factory SearchableParameterList({final ParameterList? parameterList}) {
    return SearchableParameterList._create(0, parameterList: parameterList);
  }

  @internal
  SearchableParameterList.init(super.id)
    : super.init(className: 'SearchableParameterList');

  /// Search for first occurrence of a parameter identifier and get the
  /// localized display name of the parameter.
  ///
  /// ## Parameters
  ///
  /// - [key]: Parameter key as string.
  ///
  /// ## Returns
  ///
  /// - The localized name of the parameter if found, or an empty string when
  ///   no parameter with the given key exists.
  String find(final String key) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SearchableParameterList',
      'find',
      args: key,
    );
    return resultString['result'];
  }

  /// Search for all occurrences of a parameter identifier in the list.
  ///
  /// ## Parameters
  ///
  /// - [key]: Parameter key as string.
  ///
  /// ## Returns
  ///
  /// - A [ParameterList] containing all matching parameters. The returned
  ///   list is empty when there are no matches.
  ParameterList findAll(final String key) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SearchableParameterList',
      'findAll',
      args: key,
    );
    return ParameterList.init(resultString['result']);
  }

  /// Search for the first occurrence of a parameter identifier and return
  /// the full [GemParameter].
  ///
  /// ## Parameters
  ///
  /// - [key]: Parameter key as string.
  ///
  /// ## Returns
  ///
  /// - The matching [GemParameter]. If the key is not found the returned
  ///   parameter will have an empty [GemParameter.key].
  GemParameter findParameter(final String key) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SearchableParameterList',
      'findParameter',
      args: key,
    );
    return GemParameter.fromJson(resultString['result']);
  }

  static SearchableParameterList _create(
    final int mapId, {
    final ParameterList? parameterList,
  }) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'SearchableParameterList',
        if (parameterList != null) 'args': parameterList.pointerId,
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return SearchableParameterList.init(decodedVal['result']);
  }

  @override
  void dispose() => GemKitPlatform.instance.callDeleteObject(
    jsonEncode(<String, dynamic>{
      'class': 'SearchableParameterList',
      'id': pointerId,
    }),
  );
}
