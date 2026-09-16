// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Lambert 93 (LAM) projection representation.
///
/// The LAM (Lambert) projection is a conic map projection that is commonly used
/// for large-scale mapping in regions with an east-west orientation.
///
/// It provides a way to represent geographic features accurately while minimizing distortion.
///
/// {@category Projections}
class LAMProjection extends Projection {
  /// Creates a new [LAMProjection].
  ///
  /// ## Parameters
  ///
  /// - [x]: (double) The x coordinate.
  /// - [y]: (double) The y coordinate.
  factory LAMProjection({required double x, required double y}) {
    return LAMProjection._create(x, y);
  }
  LAMProjection.init(super.id) : super.init();

  static LAMProjection _create(double x, double y) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'Projection_LAM',
        'args': <String, dynamic>{'x': x, 'y': y},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final LAMProjection retVal = LAMProjection.init(decodedVal['result']);
    return retVal;
  }

  /// Update the LAM x/y coordinates for this projection.
  ///
  /// ## Parameters
  ///
  /// - [x]: (double) New x coordinate.
  /// - [y]: (double) New y coordinate.
  void setFields({required double x, required double y}) {
    objectMethod(
      pointerId,
      'Projection_LAM',
      'set',
      args: <String, dynamic>{'x': x, 'y': y},
    );
  }

  /// X coordinate.
  ///
  /// ## Returns
  ///
  /// - (double) The x value for this LAM projection.
  double get x {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_LAM',
      'getX',
    );

    return resultString['result'];
  }

  /// Y coordinate.
  ///
  /// ## Returns
  ///
  /// - (double) The y value for this LAM projection.
  double get y {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_LAM',
      'getY',
    );

    return resultString['result'];
  }
}
