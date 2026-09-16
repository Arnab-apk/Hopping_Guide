// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Universal Transverse Mercator (UTM) projection representation.
///
/// The UTM (Universal Transverse Mercator) projection is a global map
/// projection that divides the world into a series of zones, each with its
/// own coordinate system.
///
/// It provides a way to represent geographic features accurately while minimizing distortion.
///
/// {@category Projections}
class UTMProjection extends Projection {
  /// Creates a new [UTMProjection].
  ///
  /// ## Parameters
  ///
  /// - [x]: (double) X coordinate in UTM meters.
  /// - [y]: (double) Y coordinate in UTM meters.
  /// - [zone]: (int) UTM zone number.
  /// - [hemisphere]: (Hemisphere) Hemisphere (north or south).
  factory UTMProjection({
    required double x,
    required double y,
    required int zone,
    required Hemisphere hemisphere,
  }) {
    return UTMProjection._create(x, y, zone, hemisphere);
  }
  UTMProjection.init(super.id) : super.init();

  static UTMProjection _create(
    double x,
    double y,
    int zone,
    Hemisphere hemisphere,
  ) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'Projection_UTM',
        'args': <String, dynamic>{
          'x': x,
          'y': y,
          'zone': zone,
          'hemisphere': hemisphere.index,
        },
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final UTMProjection retVal = UTMProjection.init(decodedVal['result']);
    return retVal;
  }

  /// Update the UTM coordinate fields for this point.
  ///
  /// ## Parameters
  ///
  /// - [x]: (double) New x coordinate in meters.
  /// - [y]: (double) New y coordinate in meters.
  /// - [zone]: (int) UTM zone.
  /// - [hemisphere]: (Hemisphere) Hemisphere for the coordinate.
  void setFields({
    required double x,
    required double y,
    required int zone,
    required Hemisphere hemisphere,
  }) {
    objectMethod(
      pointerId,
      'Projection_UTM',
      'set',
      args: <String, dynamic>{
        'x': x,
        'y': y,
        'zone': zone,
        'hemisphere': hemisphere.index,
      },
    );
  }

  /// X coordinate (meters).
  ///
  /// ## Returns
  ///
  /// - (double) The x coordinate in meters.
  double get x {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_UTM',
      'getX',
    );

    return resultString['result'];
  }

  /// Y coordinate (meters).
  ///
  /// ## Returns
  ///
  /// - (double) The y coordinate in meters.
  double get y {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_UTM',
      'getY',
    );

    return resultString['result'];
  }

  /// UTM zone number.
  ///
  /// ## Returns
  ///
  /// - (int) The zone value for this UTM projection.
  int get zone {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_UTM',
      'getZone',
    );

    return resultString['result'];
  }

  /// Hemisphere for this UTM coordinate.
  ///
  /// ## Returns
  ///
  /// - (Hemisphere) The hemisphere (north or south).
  Hemisphere get hemisphere {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_UTM',
      'getHemisphere',
    );

    return HemisphereExtension.fromId(resultString['result']);
  }
}

/// The hemisphere type
///
/// ## See also:
///
/// - [UTMProjection.hemisphere] — Specifies the hemisphere for UTM projections.
///
/// {@category Projections}
enum Hemisphere {
  /// Southern Hemisphere
  south,

  /// Northern Hemisphere
  north,
}

/// @nodoc
extension HemisphereExtension on Hemisphere {
  int get id {
    switch (this) {
      case Hemisphere.south:
        return 0;
      case Hemisphere.north:
        return 1;
    }
  }

  static Hemisphere fromId(final int id) {
    switch (id) {
      case 0:
        return Hemisphere.south;
      case 1:
        return Hemisphere.north;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
