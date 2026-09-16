// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Values that represent position data quality.
///
/// ## Also see:
///
/// - [GemPosition.fixQuality] - The position quality of a [GemPosition].
///
/// {@category Sensor Data Source}
enum PositionQuality {
  /// Position cannot or should not be processed (for instance, invalid coordinates).
  invalid,

  /// Position resulted from inertial extrapolation; there is a GPS outage (e.g. tunnel).
  inertial,

  /// Position is valid but cannot be trusted because of bad GPS accuracy (e.g. urban canyon).
  low,

  /// Position is valid and can be trusted (is recent and has good accuracy).
  high,
}

/// @nodoc
extension PositionQualityExtension on PositionQuality {
  int get id {
    switch (this) {
      case PositionQuality.invalid:
        return 0;
      case PositionQuality.inertial:
        return 1;
      case PositionQuality.low:
        return 2;
      case PositionQuality.high:
        return 3;
    }
  }

  static PositionQuality fromId(final int id) {
    switch (id) {
      case 0:
        return PositionQuality.invalid;
      case 1:
        return PositionQuality.inertial;
      case 2:
        return PositionQuality.low;
      case 3:
        return PositionQuality.high;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
