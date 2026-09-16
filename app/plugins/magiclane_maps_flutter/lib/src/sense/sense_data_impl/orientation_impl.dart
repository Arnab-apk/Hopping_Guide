// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/sense_data_impl.dart';
import 'package:meta/meta.dart';

/// @nodoc
class OrientationImpl extends SenseDataImpl implements Orientation {
  OrientationImpl({
    required super.type,
    required super.acquisitionTime,
    required this.face,
    required this.orientation,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory OrientationImpl.fromJson(final Map<String, dynamic> json) {
    return OrientationImpl(
      type: DataTypeExtension.fromId(json['senseDataType']),
      acquisitionTime: DateTime.fromMillisecondsSinceEpoch(
        json['acquisitionTimestamp'],
        isUtc: true,
      ),
      face: FaceTypeExtension.fromId(json['faceType']),
      orientation: OrientationTypeExtension.fromId(json['orientation']),
    );
  }

  @override
  FaceType face;

  @override
  OrientationType orientation;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['senseDataType'] = type.id;
    json['acquisitionTimestamp'] = acquisitionTime.millisecondsSinceEpoch;

    json['faceType'] = face.id;
    json['orientation'] = orientation.id;

    return json;
  }

  @override
  bool operator ==(covariant final Orientation other) {
    return face == other.face &&
        orientation == other.orientation &&
        acquisitionTime.millisecondsSinceEpoch ==
            other.acquisitionTime.millisecondsSinceEpoch;
  }

  @override
  int get hashCode {
    return face.hashCode ^ orientation.hashCode ^ acquisitionTime.hashCode;
  }
}
