// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/sense_data_impl.dart';
import 'package:meta/meta.dart';

/// @nodoc
class NmeaChunkImpl extends SenseDataImpl implements NmeaChunk {
  NmeaChunkImpl({
    required super.type,
    required super.acquisitionTime,
    required this.nmeaChunk,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory NmeaChunkImpl.fromJson(final Map<String, dynamic> json) {
    return NmeaChunkImpl(
      type: DataTypeExtension.fromId(json['senseDataType']),
      acquisitionTime: DateTime.fromMillisecondsSinceEpoch(
        json['acquisitionTimestamp'],
        isUtc: true,
      ),
      nmeaChunk: json['nmeaChunk'],
    );
  }

  @override
  String nmeaChunk;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['senseDataType'] = type.id;
    json['acquisitionTimestamp'] = acquisitionTime.millisecondsSinceEpoch;

    json['nmeaChunk'] = nmeaChunk;

    return json;
  }

  @override
  bool operator ==(covariant final NmeaChunk other) {
    return nmeaChunk == other.nmeaChunk &&
        acquisitionTime.millisecondsSinceEpoch ==
            other.acquisitionTime.millisecondsSinceEpoch;
  }

  @override
  int get hashCode {
    return nmeaChunk.hashCode ^ acquisitionTime.hashCode;
  }
}
