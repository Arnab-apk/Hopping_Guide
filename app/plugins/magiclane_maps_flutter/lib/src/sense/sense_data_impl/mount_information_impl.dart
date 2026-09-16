import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/sense_data_impl.dart';
import 'package:meta/meta.dart';

/// @nodoc
class MountInformationImpl extends SenseDataImpl implements MountInformation {
  MountInformationImpl({
    required super.type,
    required super.acquisitionTime,
    required this.isMountedForCameraUse,
    required this.isPortraitMode,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory MountInformationImpl.fromJson(final Map<String, dynamic> json) {
    return MountInformationImpl(
      type: DataTypeExtension.fromId(json['senseDataType']),
      acquisitionTime: DateTime.fromMillisecondsSinceEpoch(
        json['acquisitionTimestamp'],
        isUtc: true,
      ),
      isMountedForCameraUse: json['mountedForCameraUse'],
      isPortraitMode: json['isPortraitMode'],
    );
  }

  @override
  bool isMountedForCameraUse;

  @override
  bool isPortraitMode;

  @override
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['senseDataType'] = type.id;
    json['acquisitionTimestamp'] = acquisitionTime.millisecondsSinceEpoch;

    json['mountedForCameraUse'] = isMountedForCameraUse;
    json['isPortraitMode'] = isPortraitMode;

    return json;
  }

  @override
  bool operator ==(covariant final MountInformation other) {
    return isMountedForCameraUse == other.isMountedForCameraUse &&
        isPortraitMode == other.isPortraitMode &&
        acquisitionTime.millisecondsSinceEpoch ==
            other.acquisitionTime.millisecondsSinceEpoch;
  }

  @override
  int get hashCode {
    return isMountedForCameraUse.hashCode ^
        isPortraitMode.hashCode ^
        acquisitionTime.hashCode;
  }
}
