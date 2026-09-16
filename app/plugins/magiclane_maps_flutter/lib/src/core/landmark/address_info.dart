// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:flutter/foundation.dart';

import 'package:magiclane_maps_flutter/src/core/common/bitfield_native.dart'
    if (dart.library.js_interop) 'package:magiclane_maps_flutter/src/core/common/bitfield_web.dart';

/// Address fields available on an [AddressInfo].
///
/// Each enum value identifies a specific component of a postal address
/// (for example `city`, `streetNumber`, `postalCode`). Use these values
/// with [AddressInfo.getField] and [AddressInfo.setField] to read or modify
/// individual address components.
///
/// ## See also:
///
/// - [AddressInfo] - Structured address information for a landmark.
///
/// {@category Landmarks}
enum AddressField {
  /// Address field denoting an address extension, e.g. flat (apt, unit) number.
  extension,

  /// Address field denoting a building floor.
  buildingFloor,

  /// Address field denoting a building name.
  buildingName,

  /// Address field denoting a building room.
  buildingRoom,

  /// Address field denoting a building zone.
  buildingZone,

  /// Address field denoting a street/road name.
  streetName,

  /// Address field denoting a street number.
  streetNumber,

  /// Address field denoting a ZIP or postal code.
  postalCode,

  /// Address field denoting a settlement.
  settlement,

  /// Address field denoting a town or city name.
  city,

  /// Address field denoting a county, which is an intermediate entity between a state and a city.
  county,

  /// Address field denoting a state or province.
  state,

  /// Abbreviation for state.
  stateCode,

  /// Address field denoting a country.
  country,

  /// Address field denoting a country as a three-letter ISO 3166-1 alpha-3 code.
  countryCode,

  /// Address field denoting a municipal district.
  district,

  /// Address field denoting the first street in an intersection.
  crossing1,

  /// Address field denoting the second street in an intersection.
  crossing2,

  /// Address field denoting the road segment.
  segmentName,

  /// Last item of this enumeration
  addrLast,
}

/// @nodoc
extension AddressFieldExtension on AddressField {
  int get id {
    switch (this) {
      case AddressField.extension:
        return 0;
      case AddressField.buildingFloor:
        return 1;
      case AddressField.buildingName:
        return 2;
      case AddressField.buildingRoom:
        return 3;
      case AddressField.buildingZone:
        return 4;
      case AddressField.streetName:
        return 5;
      case AddressField.streetNumber:
        return 6;
      case AddressField.postalCode:
        return 7;
      case AddressField.settlement:
        return 8;
      case AddressField.city:
        return 9;
      case AddressField.county:
        return 10;
      case AddressField.state:
        return 11;
      case AddressField.stateCode:
        return 12;
      case AddressField.country:
        return 13;
      case AddressField.countryCode:
        return 14;
      case AddressField.district:
        return 15;
      case AddressField.crossing1:
        return 16;
      case AddressField.crossing2:
        return 17;
      case AddressField.segmentName:
        return 18;
      case AddressField.addrLast:
        return 19;
    }
  }

  static AddressField fromId(final int id) {
    switch (id) {
      case 0:
        return AddressField.extension;
      case 1:
        return AddressField.buildingFloor;
      case 2:
        return AddressField.buildingName;
      case 3:
        return AddressField.buildingRoom;
      case 4:
        return AddressField.buildingZone;
      case 5:
        return AddressField.streetName;
      case 6:
        return AddressField.streetNumber;
      case 7:
        return AddressField.postalCode;
      case 8:
        return AddressField.settlement;
      case 9:
        return AddressField.city;
      case 10:
        return AddressField.county;
      case 11:
        return AddressField.state;
      case 12:
        return AddressField.stateCode;
      case 13:
        return AddressField.country;
      case 14:
        return AddressField.countryCode;
      case 15:
        return AddressField.district;
      case 16:
        return AddressField.crossing1;
      case 17:
        return AddressField.crossing2;
      case 18:
        return AddressField.segmentName;
      case 19:
        return AddressField.addrLast;

      default:
        throw ArgumentError('Invalid id');
    }
  }

  static AddressField fromString(final String str) {
    switch (str) {
      case 'extension':
        return AddressField.extension;
      case 'buildingFloor':
        return AddressField.buildingFloor;
      case 'buildingName':
        return AddressField.buildingName;
      case 'buildingRoom':
        return AddressField.buildingRoom;
      case 'buildingZone':
        return AddressField.buildingZone;
      case 'streetName':
        return AddressField.streetName;
      case 'streetNumber':
        return AddressField.streetNumber;
      case 'postalCode':
        return AddressField.postalCode;
      case 'settlement':
        return AddressField.settlement;
      case 'city':
        return AddressField.city;
      case 'county':
        return AddressField.county;
      case 'state':
        return AddressField.state;
      case 'stateCode':
        return AddressField.stateCode;
      case 'country':
        return AddressField.country;
      case 'countryCode':
        return AddressField.countryCode;
      case 'district':
        return AddressField.district;
      case 'crossing1':
        return AddressField.crossing1;
      case 'crossing2':
        return AddressField.crossing2;
      case 'segment':
        return AddressField.segmentName;
      case 'addrLast':
        return AddressField.addrLast;

      default:
        throw ArgumentError('Invalid string');
    }
  }

  static String toActualString(AddressField field) {
    switch (field) {
      case AddressField.extension:
        return 'extension';
      case AddressField.buildingFloor:
        return 'buildingFloor';
      case AddressField.buildingName:
        return 'buildingName';
      case AddressField.buildingRoom:
        return 'buildingRoom';
      case AddressField.buildingZone:
        return 'buildingZone';
      case AddressField.streetName:
        return 'streetName';
      case AddressField.streetNumber:
        return 'streetNumber';
      case AddressField.postalCode:
        return 'postalCode';
      case AddressField.settlement:
        return 'settlement';
      case AddressField.city:
        return 'city';
      case AddressField.county:
        return 'county';
      case AddressField.state:
        return 'state';
      case AddressField.stateCode:
        return 'stateCode';
      case AddressField.country:
        return 'country';
      case AddressField.countryCode:
        return 'countryCode';
      case AddressField.district:
        return 'district';
      case AddressField.crossing1:
        return 'crossing1';
      case AddressField.crossing2:
        return 'crossing2';
      case AddressField.segmentName:
        return 'segment';
      case AddressField.addrLast:
        return 'addrLast';
    }
  }
}

/// Contains structured address information for a [Landmark].
///
/// An [AddressInfo] stores a set of named address components (for example
/// street, city, postal code and country). Use [getField] to read a specific
/// component, [setField] to modify it, and [format] to produce a
/// human-readable representation. Instances are lightweight wrappers around
/// an underlying platform object and are created via the public constructor
/// or returned from other APIs such as [Landmark.address].
///
/// Changes made to an [AddressInfo] do not automatically propagate to the
/// associated [Landmark]. To apply changes, set the modified [AddressInfo]
/// back on the landmark via [Landmark.address].
///
/// ## See also:
///
/// - [Landmark.address] — Obtain the address information for a landmark.
/// - [AddressField] — Enumation of address fields that can be read or modified.
///
/// {@category Landmarks}
class AddressInfo {
  /// Creates a new empty AddressInfo instance.
  ///
  /// The new instance contains no address fields initially; use
  /// [setField] to populate it.
  AddressInfo();

  /// Deserializes a JSON-compatible list to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected list structure may change without notice.
  @internal
  factory AddressInfo.fromJson(final Map<String, dynamic> json) {
    final List<dynamic> jsonList = json['fields'];
    final AddressInfo retVal = AddressInfo();

    for (int i = 0; i < jsonList.length; i++) {
      final AddressField field = AddressFieldExtension.fromId(i);
      final String value = jsonList[i];
      if (value.isEmpty) {
        continue;
      }
      retVal.setField(value, field);
    }

    return retVal;
  }

  /// Serializes this instance to a JSON-compatible list.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The list structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final List<String> json = List<String>.filled(
      AddressField.values.length,
      '',
    );

    for (int i = 0; i < AddressField.addrLast.id; i++) {
      final String? value = getField(AddressFieldExtension.fromId(i));
      if (value != null) {
        json[i] = value;
      }
    }

    return <String, dynamic>{'fields': json};
  }

  final Map<AddressField, String?> _addressMap = <AddressField, String?>{};

  /// Returns the address formatted as a single, human-readable line.
  ///
  /// The method builds a concise, display-friendly address by selecting the
  /// relevant address components, trimming whitespace, omitting null or empty
  /// values, collapsing adjacent duplicates, and joining the remaining parts
  /// with a readable separator (", "). The ordering of components follows a
  /// common mailing/display convention.
  ///
  /// ## Parameters
  ///
  /// - [excludeFields] (optional): A list of address field identifiers to omit
  ///   from the formatted output. Null or an empty list means "do not exclude any fields".
  /// - [includeFields] (optional): A list of address field identifiers to
  ///   include in the output. When provided, only the fields in this list are
  ///   considered; [excludeFields] is ignored. An empty list will result in an
  ///   empty string.
  ///
  /// ## Returns
  ///
  /// - `String`: The formatted address.
  String format({
    final List<AddressField>? excludeFields,
    final List<AddressField>? includeFields,
  }) {
    final StringBuffer buffer = StringBuffer();

    final PlatformBitField<AddressField> bitfield =
        PlatformBitField<AddressField>(AddressField.addrLast.id + 1);

    for (final AddressField field in includeFields ?? AddressField.values) {
      bitfield[field] = true;
    }

    for (final AddressField field in excludeFields ?? <AddressField>[]) {
      bitfield[field] = false;
    }

    for (final AddressField field in AddressField.values) {
      if (!bitfield[field]) {
        continue;
      }

      final String? value = getField(field);
      String? prevValue;
      if (field.id > 0) {
        prevValue = getField(AddressFieldExtension.fromId(field.id - 1));
      }

      if (value != null && value.isNotEmpty && value != prevValue) {
        buffer.write(value);
        buffer.write(', ');
      }
    }

    final String result = buffer.toString();
    if (result.endsWith(', ')) {
      return result.substring(0, result.length - 2);
    } else {
      return result;
    }
  }

  /// Get address field name.
  ///
  /// ## Parameters
  ///
  /// - [field]: Address field requested.
  ///
  /// ## Returns
  ///
  /// - Field value if it exists, otherwise null.
  String? getField(final AddressField field) {
    return _addressMap[field];
  }

  /// Set address field name.
  ///
  /// ## Parameters
  ///
  /// - [str]: New value of the address field.
  /// - [field]: Address field requested.
  void setField(final String str, final AddressField field) {
    _addressMap[field] = str;
  }

  @override
  bool operator ==(covariant final AddressInfo other) {
    if (identical(this, other)) {
      return true;
    }

    return mapEquals(_addressMap, other._addressMap);
  }

  @override
  int get hashCode {
    int hash = 0;
    for (final MapEntry<AddressField, String?> entry in _addressMap.entries) {
      final AddressField key = entry.key;
      final String? value = entry.value;
      hash = hash ^ value.hashCode ^ key.hashCode;
    }

    return hash;
  }
}
