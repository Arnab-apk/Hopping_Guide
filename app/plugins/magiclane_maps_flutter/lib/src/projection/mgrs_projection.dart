// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Military Grid Reference System (MGRS) projection representation.
///
/// The MGRS (Military Grid Reference System) projection is a coordinate system
/// used by the military for precise location identification.
/// It combines the UTM and UPS coordinate systems to provide a grid reference
/// system that is easy to use in the field.
///
/// {@category Projections}
class MGRSProjection extends Projection {
  /// Creates an [MGRSProjection].
  ///
  /// ## Parameters
  ///
  /// - [easting]: (double) Easting coordinate.
  /// - [northing]: (double) Northing coordinate.
  /// - [zone]: (String) Grid zone designator.
  /// - [letters]: (String) 100k grid square letters.
  factory MGRSProjection({
    required double easting,
    required double northing,
    required String zone,
    required String letters,
  }) {
    return MGRSProjection._create(easting, northing, zone, letters);
  }
  MGRSProjection.init(super.id) : super.init();

  static MGRSProjection _create(
    double x,
    double y,
    String zone,
    String letters,
  ) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'Projection_MGRS',
        'args': <String, dynamic>{
          'easting': x,
          'northing': y,
          'zone': zone,
          'letters': letters,
        },
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final MGRSProjection retVal = MGRSProjection.init(decodedVal['result']);
    return retVal;
  }

  /// Update MGRS coordinate fields.
  ///
  /// ## Parameters
  ///
  /// - [easting]: (int) The easting coordinate.
  /// - [northing]: (int) The northing coordinate.
  /// - [zone]: (String) The grid zone designator.
  /// - [letters]: (String) The 100k grid square letters.
  void setFields({
    required int easting,
    required int northing,
    required String zone,
    required String letters,
  }) {
    objectMethod(
      pointerId,
      'Projection_MGRS',
      'set',
      args: <String, dynamic>{
        'easting': easting,
        'northing': northing,
        'zone': zone,
        'letters': letters,
      },
    );
  }

  /// 100k grid square letters.
  ///
  /// ## Returns
  ///
  /// - (String) The letters that identify the 100k square.
  String get letters {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_MGRS',
      'getSq100kIdentifier',
    );

    return resultString['result'];
  }

  /// Easting coordinate.
  ///
  /// ## Returns
  ///
  /// - (int) The easting value.
  int get easting {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_MGRS',
      'getEasting',
    );

    return resultString['result'];
  }

  /// Northing coordinate.
  ///
  /// ## Returns
  ///
  /// - (int) The northing value.
  int get northing {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_MGRS',
      'getNorthing',
    );

    return resultString['result'];
  }

  /// Grid zone designator.
  ///
  /// ## Returns
  ///
  /// - (String) The zone string for this MGRS coordinate.
  String get zone {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_MGRS',
      'getZone',
    );

    return resultString['result'];
  }
}
