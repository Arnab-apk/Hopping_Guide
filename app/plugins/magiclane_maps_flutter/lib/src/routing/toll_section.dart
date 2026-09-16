// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Represents a tolled portion of a route.
///
/// A [TollSection] models a contiguous segment of a route where tolls apply.
/// Distances are measured in meters from the start of the route. Each
/// instance may include an estimated monetary cost and the currency code used
/// for that cost. When cost information is not available the [cost] is 0.0 and
/// [currency] is an empty string.
///
/// Obtain toll sections from a computed route via [RouteBase.tollSections] or
/// from a specific segment via [RouteSegmentBase.tollSections].
///
/// API users should not create instances of this class directly.
///
/// ## See also:
///
/// - [RouteBase.tollSections] - Retrieve toll sections for a complete route.
/// - [RouteSegmentBase.tollSections] - Retrieve toll sections for a segment.
/// - [RoutePreferences] - Configure route calculation preferences including toll avoidance.
/// - [RouteBase.getCoordinateOnRoute] - Get coordinates along the route at specific distances.
///
/// {@category Routing}
class TollSection {
  /// Creates a [TollSection].
  ///
  /// Constructs a toll section describing the tolled portion between two
  /// distances measured from the route start. All parameters are optional and
  /// will default to a zero/empty value when not provided.
  ///
  /// API users should not create instances of this class directly.
  ///
  /// ## Parameters
  ///
  /// - [startDistanceM]: Distance in meters from the route start where the
  ///   toll section begins. Defaults to `0`.
  /// - [endDistanceM]: Distance in meters from the route start where the
  ///   toll section ends. Defaults to `0`.
  /// - [cost]: The toll cost for this section in the specified currency.
  ///   Defaults to `0.0` when cost data is not available.
  /// - [currency]: ISO currency code for [cost] (e.g., `EUR`, `USD`). Empty
  ///   string when currency is not provided.
  TollSection({
    this.startDistanceM = 0,
    this.endDistanceM = 0,
    this.cost = 0.0,
    this.currency = '',
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory TollSection.fromJson(final Map<String, dynamic> json) {
    return TollSection(
      startDistanceM: json['startDistanceM'],
      endDistanceM: json['endDistanceM'],
      cost: json['cost'],
      currency: json['currency'],
    );
  }

  /// Distance (meters) from the route start where this toll section begins.
  ///
  /// ## See also:
  ///
  /// - [RouteBase.getCoordinateOnRoute] - Get coordinates along the route at specific distances.
  /// - [endDistanceM] - Distance where the toll section ends.
  int startDistanceM;

  /// Distance (meters) from the route start where this toll section ends.
  ///
  /// ## See also:
  ///
  /// - [RouteBase.getCoordinateOnRoute] - Get coordinates along the route at specific distances.
  /// - [startDistanceM] - Distance where the toll section begins.
  int endDistanceM;

  /// Estimated toll cost for this section in [currency].
  ///
  /// When cost information is not available, this value is `0.0`.
  double cost;

  /// ISO currency code for [cost] (for example `EUR`, `USD`).
  ///
  /// Empty string indicates cost/currency information not available.
  String currency;

  @override
  bool operator ==(covariant final TollSection other) {
    if (identical(this, other)) {
      return true;
    }

    return other.startDistanceM == startDistanceM &&
        other.endDistanceM == endDistanceM &&
        other.cost == cost &&
        other.currency == currency;
  }

  @override
  int get hashCode {
    return startDistanceM.hashCode ^
        endDistanceM.hashCode ^
        cost.hashCode ^
        currency.hashCode;
  }
}
