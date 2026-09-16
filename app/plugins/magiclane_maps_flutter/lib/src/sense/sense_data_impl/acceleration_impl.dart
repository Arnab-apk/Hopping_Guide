// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/sense_data_impl.dart';
import 'package:meta/meta.dart';

/// @nodoc
class AccelerationImpl extends SenseDataImpl implements Acceleration {
  AccelerationImpl({
    required super.type,
    required super.acquisitionTime,
    required this.x,
    required this.y,
    required this.z,
    required this.unit,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory AccelerationImpl.fromJson(final Map<String, dynamic> json) {
    return AccelerationImpl(
      type: DataTypeExtension.fromId(json['senseDataType']),
      acquisitionTime: DateTime.fromMillisecondsSinceEpoch(
        json['acquisitionTimestamp'],
        isUtc: true,
      ),
      x: json['x'],
      y: json['y'],
      z: json['z'],
      unit: UnitOfMeasurementAccelerationExtension.fromId(json['unit']),
    );
  }
  @override
  UnitOfMeasurementAcceleration unit;

  @override
  double x;

  @override
  double y;

  @override
  double z;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['senseDataType'] = type.id;
    json['acquisitionTimestamp'] = acquisitionTime.millisecondsSinceEpoch;

    json['x'] = x;
    json['y'] = y;
    json['z'] = z;
    json['unit'] = unit.id;

    return json;
  }

  @override
  bool operator ==(covariant final Acceleration other) {
    return x == other.x &&
        y == other.y &&
        z == other.z &&
        unit == other.unit &&
        acquisitionTime.millisecondsSinceEpoch ==
            other.acquisitionTime.millisecondsSinceEpoch;
  }

  @override
  int get hashCode {
    return x.hashCode ^
        y.hashCode ^
        z.hashCode ^
        unit.hashCode ^
        acquisitionTime.hashCode;
  }
}
