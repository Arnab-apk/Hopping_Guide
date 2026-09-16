// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Stores contact information associated with a [Landmark].
///
/// A [ContactInfo] holds a list of contact fields (for example phone
/// numbers, email addresses or URLs). Multiple values of the same
/// [ContactInfoFieldType] are allowed.
///
/// Modifying a [ContactInfo] instance is local to the object; to persist changes on a [Landmark], reassign the
/// modified instance to [Landmark.contactInfo].
///
/// ## See also:
///
/// - [Landmark.contactInfo] — Obtain the contact information for a landmark.
/// - [ContactInfoFieldType] — Types of contact fields that can be stored.
///
/// {@category Landmarks}
/// {@category Snapshot Types}
class ContactInfo extends GemAutoreleaseObject {
  /// Creates a new, empty [ContactInfo].
  factory ContactInfo() {
    return ContactInfo._create();
  }

  @internal
  ContactInfo.init(super.id);

  /// Adds a new field to this contact info instance.
  ///
  /// The new field will be appended to the internal list. Use
  /// [fieldsCount] to determine the new index.
  ///
  /// ## Parameters
  ///
  /// - [type]: The field type (for example phone, email or url).
  /// - [value]: The field value (for example a phone number or email address).
  /// - [name]: A short display name for the field (used by UI components).
  void addField({
    required final ContactInfoFieldType type,
    required final String value,
    required final String name,
  }) {
    objectMethod(
      pointerId,
      'ContactInfo',
      'addField',
      args: <String, dynamic>{'type': type.id, 'value': value, 'name': name},
    );
  }

  /// Number of fields stored in this contact info.
  ///
  /// ## Returns
  ///
  /// - `int`: The current number of fields.
  int get fieldsCount {
    final OperationResult result = objectMethod(
      pointerId,
      'ContactInfo',
      'getFieldsCount',
    );
    return result['result'];
  }

  /// Returns the display name (short description) for the field at [index].
  ///
  /// The returned string depends on the SDK language setting and is
  /// typically used for UI presentation. When no field exists at [index]
  /// the method returns `null`.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the requested field.
  ///
  /// ## Returns
  ///
  /// - `String?`: The localized field name or `null` when the index is
  ///   invalid or the field name is empty.
  ///
  /// ## Also see:
  ///
  /// - [fieldsCount] — Get the total number of fields.
  String? getFieldName(final int index) {
    final OperationResult result = objectMethod(
      pointerId,
      'ContactInfo',
      'getFieldName',
      args: index,
    );
    final String name = result['result'];
    return name.isNotEmpty ? name : null;
  }

  /// Returns the value for the field at [index].
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the requested field.
  ///
  /// ## Returns
  ///
  /// - `String?`: The field value, or `null` when the index is invalid or
  ///   the value is empty.
  ///
  /// ## Also see:
  ///
  /// - [fieldsCount] — Get the total number of fields.
  String? getFieldValue(final int index) {
    final OperationResult result = objectMethod(
      pointerId,
      'ContactInfo',
      'getFieldValue',
      args: index,
    );

    final String value = result['result'];
    return value.isNotEmpty ? value : null;
  }

  /// Returns the [ContactInfoFieldType] for the field at [index].
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the requested field.
  ///
  /// ## Returns
  ///
  /// - `ContactInfoFieldType?`: The field type, or `null` when the index is
  ///   invalid or the native conversion fails.
  ///
  /// ## Also see:
  ///
  /// - [fieldsCount] — Get the total number of fields.
  ContactInfoFieldType? getFieldType(final int index) {
    final OperationResult result = objectMethod(
      pointerId,
      'ContactInfo',
      'getFieldType',
      args: index,
    );

    try {
      return ContactInfoFieldTypeExtension.fromId(result['result']);
    } catch (e) {
      return null;
    }
  }

  /// Sets or updates a contact field at [index].
  ///
  /// If [index] is negative the call does nothing. If [index] is within the
  /// current range the field is updated; when [index] is beyond the current
  /// field count a new field is appended (behavior mirrors the native API).
  ///
  /// ## Parameters
  ///
  /// - [index]: Index of the field to set or update.
  /// - [type]: The field type to store.
  /// - [value]: The field value to store.
  /// - [name]: Display name for the field.
  void setField({
    required final int index,
    required final ContactInfoFieldType type,
    required final String value,
    required final String name,
  }) {
    if (index < 0) {
      return;
    }
    if (index < fieldsCount) {
      objectMethod(
        pointerId,
        'ContactInfo',
        'setField',
        args: <String, dynamic>{
          'index': index,
          'type': type.id,
          'value': value,
          'name': name,
        },
      );
    } else {
      addField(type: type, value: value, name: name);
    }
  }

  /// Removes the field at [index].
  ///
  /// If no field exists at [index] the method is a no-op.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the field to remove.
  ///
  /// ## Also see:
  ///
  /// - [fieldsCount] — Get the total number of fields.
  void removeField(final int index) {
    objectMethod(pointerId, 'ContactInfo', 'removeField', args: index);
  }

  static ContactInfo _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'ContactInfo'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    return ContactInfo.init(decodedVal['result']);
  }
}

/// Types of contact fields that can be stored in [ContactInfo].
///
/// {@category Landmarks}
enum ContactInfoFieldType {
  /// Phone number
  phone,

  /// Email address
  email,

  /// URL
  url,

  /// Booking URL
  bookingUrl,

  /// Opening hours
  openingHours,

  /// Last field
  last,
}

/// @nodoc
extension ContactInfoFieldTypeExtension on ContactInfoFieldType {
  int get id {
    switch (this) {
      case ContactInfoFieldType.phone:
        return 0;
      case ContactInfoFieldType.email:
        return 1;
      case ContactInfoFieldType.url:
        return 2;
      case ContactInfoFieldType.bookingUrl:
        return 3;
      case ContactInfoFieldType.openingHours:
        return 4;
      case ContactInfoFieldType.last:
        return 5;
    }
  }

  static ContactInfoFieldType fromId(final int id) {
    switch (id) {
      case 0:
        return ContactInfoFieldType.phone;
      case 1:
        return ContactInfoFieldType.email;
      case 2:
        return ContactInfoFieldType.url;
      case 3:
        return ContactInfoFieldType.bookingUrl;
      case 4:
        return ContactInfoFieldType.openingHours;
      case 5:
        return ContactInfoFieldType.last;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
