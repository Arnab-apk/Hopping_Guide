// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// British National Grid (BNG) projection representation.
///
/// The BNG (British National Grid) projection is a coordinate system
/// used in Great Britain for mapping and navigation. It provides a grid
/// reference system that allows for precise location identification within the country.
///
/// {@category Projections}
class BNGProjection extends Projection {
  /// Creates a new [BNGProjection].
  ///
  /// ## Parameters
  ///
  /// - [easting]: (double) Easting coordinate.
  /// - [northing]: (double) Northing coordinate.
  factory BNGProjection({required double easting, required double northing}) {
    return BNGProjection._create(easting, northing);
  }
  BNGProjection.init(super.id) : super.init();

  static BNGProjection _create(double easting, double northing) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'Projection_BNG',
        'args': <String, dynamic>{'easting': easting, 'northing': northing},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final BNGProjection retVal = BNGProjection.init(decodedVal['result']);
    return retVal;
  }

  /// Update the easting and northing for this BNG point.
  ///
  /// ## Parameters
  ///
  /// - [easting]: (double) The new easting value.
  /// - [northing]: (double) The new northing value.
  void setFields({required double easting, required double northing}) {
    objectMethod(
      pointerId,
      'Projection_BNG',
      'set',
      args: <String, dynamic>{'easting': easting, 'northing': northing},
    );
  }

  /// Set the alphanumeric grid reference string for this BNG point.
  ///
  /// ## Parameters
  ///
  /// - [gridReference]: (String) The grid reference value.
  set gridReference(String gridReference) {
    objectMethod(
      pointerId,
      'Projection_BNG',
      'setGridReference',
      args: gridReference,
    );
  }

  /// Alphanumeric grid reference.
  ///
  /// ## Returns
  ///
  /// - (String) The BNG grid reference for this point.
  String get gridReference {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_BNG',
      'getGridReference',
    );

    return resultString['result'];
  }

  /// Easting coordinate.
  ///
  /// ## Returns
  ///
  /// - (double) The easting value.
  double get easting {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_BNG',
      'getEasting',
    );

    return resultString['result'];
  }

  /// Northing coordinate.
  ///
  /// ## Returns
  ///
  /// - (double) The northing value.
  double get northing {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_BNG',
      'getNorthing',
    );

    return resultString['result'];
  }
}
