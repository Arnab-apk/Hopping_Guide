// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/sense_data_impl.dart';
import 'package:meta/meta.dart';

/// @nodoc
class HeartRateImpl extends SenseDataImpl implements HeartRate {
  HeartRateImpl({
    required super.type,
    required super.acquisitionTime,
    required this.heartRate,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory HeartRateImpl.fromJson(final Map<String, dynamic> json) {
    return HeartRateImpl(
      type: DataTypeExtension.fromId(json['senseDataType']),
      acquisitionTime: DateTime.fromMillisecondsSinceEpoch(
        json['acquisitionTimestamp'],
        isUtc: true,
      ),
      heartRate: json['heartRate'],
    );
  }

  @override
  int heartRate;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['senseDataType'] = type.id;
    json['acquisitionTimestamp'] = acquisitionTime.millisecondsSinceEpoch;

    json['heartRate'] = heartRate;

    return json;
  }

  @override
  bool operator ==(covariant final HeartRate other) {
    return heartRate == other.heartRate &&
        acquisitionTime.millisecondsSinceEpoch ==
            other.acquisitionTime.millisecondsSinceEpoch;
  }

  @override
  int get hashCode {
    return heartRate.hashCode ^ acquisitionTime.hashCode;
  }
}
