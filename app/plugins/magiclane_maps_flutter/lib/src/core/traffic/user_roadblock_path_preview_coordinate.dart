// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// User roadblock path preview match information.
///
/// Represents a candidate coordinate returned by
/// [TrafficService.getPersistentRoadblockPathPreview]. It contains the
/// coordinate and internal match metadata used by the SDK when suggesting
/// the next roadblock point.
///
/// ## See also:
///
/// - [TrafficService.getPersistentRoadblockPathPreview]
///
/// {@category Traffic & Roadblocks}
class UserRoadblockPathPreviewCoordinate {
  UserRoadblockPathPreviewCoordinate._({
    required this.coordinates,
    required int matchLink,
    required double matchRatio,
  }) : _matchRatio = matchRatio,
       _matchLink = matchLink;

  /// Creates a [UserRoadblockPathPreviewCoordinate] from a [Coordinates].
  /// This should be used for the initial call to [TrafficService.getPersistentRoadblockPathPreview]
  /// in order to start the preview process.
  ///
  /// ## Parameters
  ///
  /// - [coords]: The coordinate to wrap as a preview candidate.
  ///
  /// ## Also see:
  ///
  /// - [TrafficService.getPersistentRoadblockPathPreview] to obtain subsequent preview coordinates.
  factory UserRoadblockPathPreviewCoordinate.fromCoordinates(
    Coordinates coords,
  ) {
    return UserRoadblockPathPreviewCoordinate._(
      coordinates: coords,
      matchLink: 0,
      matchRatio: 0,
    );
  }

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory UserRoadblockPathPreviewCoordinate.fromJson(
    Map<String, dynamic> json,
  ) => UserRoadblockPathPreviewCoordinate._(
    coordinates: Coordinates.fromJson(json['coord']),
    matchLink: json['matchLink'],
    matchRatio: json['matchRatio'],
  );

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() => <String, dynamic>{
    'coord': coordinates,
    'matchLink': _matchLink,
    'matchRatio': _matchRatio,
  };

  /// The preview coordinate.
  ///
  /// Represents the geographic point suggested as the next roadblock match.
  Coordinates coordinates;

  /// Internal match link index.
  ///
  /// Used by the SDK to track the matched link; not intended for public use.
  int _matchLink;

  /// Internal match ratio.
  ///
  /// Used by the SDK as an internal score for matching quality; not
  /// intended for public consumption.
  double _matchRatio;

  @override
  bool operator ==(covariant UserRoadblockPathPreviewCoordinate other) {
    return coordinates == other.coordinates &&
        _matchLink == other._matchLink &&
        _matchRatio == other._matchRatio;
  }

  @override
  int get hashCode => Object.hash(coordinates, _matchLink, _matchRatio);
}
