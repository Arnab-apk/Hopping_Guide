// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Road information value object.
///
/// Simple value object describing a road label used in route and instruction contexts. It packages the
/// human-readable road name together with the shield classification used to select an icon or rendering style
/// for UI displays and signposting.
///
/// ## See also:
///
/// - [RouteInstructionBase.roadInfo] — How road information is exposed on instructions.
///
/// {@category Common}
class RoadInfo {
  /// Creates a new instance of [RoadInfo].
  ///
  /// API consumers should not call this constructor directly.
  /// Obtain instances from [NavigationInstruction], [RouteInstructionBase], or similar classes instead.
  RoadInfo({required String roadname, required RoadShieldType shieldtype})
    : _roadname = roadname,
      _shieldtype = shieldtype;

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory RoadInfo.fromJson(Map<String, dynamic> json) {
    return RoadInfo(
      roadname: json['roadname'] as String,
      shieldtype: RoadShieldType.values[json['shieldtype'] as int],
    );
  }

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The output map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'roadname': _roadname,
      'shieldtype': _shieldtype.index,
    };
  }

  final String _roadname;
  final RoadShieldType _shieldtype;

  /// The human-readable name of the road (for example `A1`, `Main St`).
  String get roadname => _roadname;

  /// The road shield classification used to select an icon or style for the road label.
  RoadShieldType get shieldtype => _shieldtype;
}
