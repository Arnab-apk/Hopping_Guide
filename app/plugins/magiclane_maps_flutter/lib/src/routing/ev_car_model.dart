// SPDX-FileCopyrightText: 2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// An electric vehicle car model used for EV route calculations.
///
/// Contains vehicle specifications relevant to EV routing such as battery
/// capacity, charging ports, range, efficiency, and fast charge capability.
/// Instances are obtained from [RoutingService.getEVCarModels].
///
/// {@category Routing}
class EVCarModel extends GemAutoreleaseObject {
  // ignore: unused_element
  EVCarModel._() : super(-1);

  @internal
  EVCarModel.init(super.id);

  /// The unique identifier of the car model.
  int get id {
    final OperationResult result = objectMethod(
      super.pointerId,
      'EVCarModelFlutter',
      'id',
    );
    return result['result'];
  }

  /// The name of the car model.
  String get name {
    final OperationResult result = objectMethod(
      super.pointerId,
      'EVCarModelFlutter',
      'name',
    );
    return result['result'];
  }

  /// The usable battery capacity in Wh.
  double get batteryCapacity {
    final OperationResult result = objectMethod(
      super.pointerId,
      'EVCarModelFlutter',
      'batteryCapacity',
    );
    return result['result'];
  }

  /// The maximum weight available on the vehicle towbar.
  int get towbarPossible {
    final OperationResult result = objectMethod(
      super.pointerId,
      'EVCarModelFlutter',
      'towbarPossible',
    );
    return result['result'];
  }

  /// Supported charging ports, a combination of one or more charging connector types.
  int get ports {
    final OperationResult result = objectMethod(
      super.pointerId,
      'EVCarModelFlutter',
      'ports',
    );
    return result['result'];
  }

  /// The vehicle range in meters.
  int get vehicleRange {
    final OperationResult result = objectMethod(
      super.pointerId,
      'EVCarModelFlutter',
      'vehicleRange',
    );
    return result['result'];
  }

  /// The energy consumption in Wh/km.
  int get efficiency {
    final OperationResult result = objectMethod(
      super.pointerId,
      'EVCarModelFlutter',
      'efficiency',
    );
    return result['result'];
  }

  /// How many km can be charged in one hour (10-80% interval).
  int get fastCharge {
    final OperationResult result = objectMethod(
      super.pointerId,
      'EVCarModelFlutter',
      'fastCharge',
    );
    return result['result'];
  }
}
