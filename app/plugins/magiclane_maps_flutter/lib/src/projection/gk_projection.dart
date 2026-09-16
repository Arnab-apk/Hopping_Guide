// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/projections.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Grid (Gauss-Krüger) projection representation.
///
/// The Gauss-Kruger projection is a cylindrical map projection that is
/// commonly used for large-scale mapping in regions with a north-south orientation.
/// It divides the Earth into zones, each with its own coordinate system, allowing
/// for accurate representation of geographic features.
///
/// The Gauss-Kruger projection is currently supported only for countries that use Bessel ellipsoid.
/// Trying to convert to and from Gauss-Kruger projection for other countries will
/// result in a GemError.notSupported error.
///
/// ## See also:
///
/// - [ProjectionService] — Utilities to convert between projection types.
///
/// {@category Projections}
class GKProjection extends Projection {
  /// Creates a new [GKProjection].
  ///
  /// ## Parameters
  ///
  /// - [x]: (double) The horizontal (easting) coordinate.
  /// - [y]: (double) The vertical (northing) coordinate.
  /// - [zone]: (int) The GK zone number.
  factory GKProjection({
    required double x,
    required double y,
    required int zone,
  }) {
    return GKProjection._create(x, y, zone);
  }
  GKProjection.init(super.id) : super.init();

  static GKProjection _create(double x, double y, int zone) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'Projection_GK',
        'args': <String, dynamic>{'x': x, 'y': y, 'zone': zone},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final GKProjection retVal = GKProjection.init(decodedVal['result']);
    return retVal;
  }

  /// Update the coordinate fields of this GK point.
  ///
  /// ## Parameters
  ///
  /// - [x]: (double) The new horizontal (easting) coordinate.
  /// - [y]: (double) The new vertical (northing) coordinate.
  /// - [zone]: (int) The GK zone.
  void setFields({required double x, required double y, required int zone}) {
    objectMethod(
      pointerId,
      'Projection_GK',
      'set',
      args: <String, dynamic>{'x': x, 'y': y, 'zone': zone},
    );
  }

  /// Easting (horizontal) coordinate.
  ///
  /// ## Returns
  ///
  /// - (double) The easting value for this projection.
  double get easting {
    final OperationResult result = objectMethod(
      pointerId,
      'Projection_GK',
      'getEasting',
    );

    return result['result'];
  }

  /// Northing (vertical) coordinate.
  ///
  /// ## Returns
  ///
  /// - (double) The northing value for this projection.
  double get northing {
    final OperationResult result = objectMethod(
      pointerId,
      'Projection_GK',
      'getNorthing',
    );

    return result['result'];
  }

  /// GK zone number.
  ///
  /// ## Returns
  ///
  /// - (int) The zone associated with this projection.
  int get zone {
    final OperationResult result = objectMethod(
      pointerId,
      'Projection_GK',
      'getZone',
    );

    return result['result'];
  }
}
