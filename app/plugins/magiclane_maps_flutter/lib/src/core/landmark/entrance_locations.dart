// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Represents the entrance points for a [Landmark].
///
/// Each entrance contains a geographic position and an access type (for
/// example vehicle or pedestrian access). Instances are owned by a
/// [Landmark] and must be obtained through that object's [Landmark.entrances]
/// getter — do not construct this class directly.
///
/// Currently experimental and subject to change. Available only for some
/// airports.
///
/// ## See also:
///
/// - [Landmark.entrances] — Obtain the entrance locations for a landmark.
///
/// {@category Landmarks}
@experimental
class EntranceLocations extends GemAutoreleaseObject {
  // ignore: unused_element
  EntranceLocations._() : super(-1);

  @internal
  EntranceLocations.init(super.id);

  /// Number of entrance locations.
  ///
  /// Returns the total number of entrances available on this object. Use
  /// this value together with [getCoordinates] and [getType] to iterate all
  /// entrances.
  ///
  /// ## Returns
  ///
  /// - The number of entrances as an integer.
  int get count {
    final OperationResult resultString = objectMethod(
      pointerId,
      'EntranceLocations',
      'getCount',
    );

    return resultString['result'];
  }

  /// Returns the [Coordinates] for the entrance at the given [index].
  ///
  /// If [index] is outside the valid range for this collection the method
  /// returns `null`.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the entrance to retrieve.
  ///
  /// ## Returns
  ///
  /// - [Coordinates?]: The entrance coordinates, or `null` when [index] is
  ///   out of range.
  ///
  /// ## Also see:
  ///
  /// - [count] — Get the total number of entrances.
  Coordinates? getCoordinates(final int index) {
    if (index > count) {
      return null;
    }

    final OperationResult resultString = objectMethod(
      pointerId,
      'EntranceLocations',
      'getCoordinates',
      args: index,
    );

    return Coordinates.fromJson(resultString['result']);
  }

  /// Returns the [EntranceLocationType] for the entrance at [index].
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the entrance whose type should be
  ///   returned.
  ///
  /// ## Returns
  ///
  /// - [EntranceLocationType]: The access type for the requested entrance.
  ///
  /// ## Also see:
  ///
  /// - [count] — Get the total number of entrances.
  EntranceLocationType getType(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'EntranceLocations',
      'getType',
      args: index,
    );

    return EntranceLocationTypeExtension.fromId(resultString['result']);
  }

  /// Adds a new entrance location to this collection.
  ///
  /// The method requests the platform to persist a new entrance with the
  /// provided [coordinates] and [type]. The operation may fail if the
  /// platform rejects the values or if the underlying object is read-only.
  ///
  /// ## Parameters
  ///
  /// - [coordinates]: Coordinates of the new entrance.
  /// - [type]: Access type for the new entrance.
  ///
  /// ## Returns
  ///
  /// - [bool]: `true` when the entrance was added successfully; `false`
  ///   otherwise.
  bool addEntranceLocation({
    required final Coordinates coordinates,
    required final EntranceLocationType type,
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'EntranceLocations',
      'addEntranceLocation',
      args: <String, dynamic>{
        'entranceType': type.id,
        'coordinates': coordinates,
      },
    );

    return resultString['result'];
  }
}

/// Type of an entrance location.
///
/// {@category Landmarks}
enum EntranceLocationType {
  /// Unknown access type
  unknownAccessType,

  /// Access for vehicles
  vehicleAccess,

  /// Access for pedestrians
  pedestrianAccess,
}

/// @nodoc
extension EntranceLocationTypeExtension on EntranceLocationType {
  int get id {
    switch (this) {
      case EntranceLocationType.unknownAccessType:
        return 0;
      case EntranceLocationType.vehicleAccess:
        return 1;
      case EntranceLocationType.pedestrianAccess:
        return 2;
    }
  }

  static EntranceLocationType fromId(final int id) {
    switch (id) {
      case 0:
        return EntranceLocationType.unknownAccessType;
      case 1:
        return EntranceLocationType.vehicleAccess;
      case 2:
        return EntranceLocationType.pedestrianAccess;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
