// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// List of alarms referenced to geographic coordinates.
///
/// Represents a generic collection of alarm items (for example overlay item or landmark
/// alarms) that are referenced to a geographic coordinate. Implementations provide access
/// to the list contents, the reference coordinates used for distance calculations and
/// utility methods such as retrieving the distance to a specific item.
///
/// Implementations include [OverlayItemAlarmsList] and [LandmarkAlarmsList].
///
/// ## See also:
///
/// - [OverlayItemAlarmsList] - Alarms list for overlay items.
/// - [LandmarkAlarmsList] - Alarms list for landmarks.
///
/// {@category Alarms}
abstract class AlarmsList<T> {
  /// Reference coordinates used for distance calculations.
  ///
  /// The coordinates returned by this getter are used as the origin when computing
  /// the distance from each alarm item. Implementations typically return the current
  /// device reference position used by the [AlarmService].
  ///
  /// ## Returns
  ///
  /// - [Coordinates]: The reference coordinates for the alarm list.
  Coordinates get referenceCoordinates;

  /// Distance in meters from the [referenceCoordinates] to the specified item.
  ///
  /// If [index] is outside the valid range the method returns `0`.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the alarm item.
  ///
  /// ## Returns
  ///
  /// - `int`: Distance in meters to the item, or `0` when [index] is out of range.
  int getDistance(final int index);

  /// Number of items in the alarms list.
  ///
  /// ## Returns
  ///
  /// - `int`: The number of alarm items currently in the list.
  int get size;

  /// Items contained in the alarms list.
  ///
  /// The list elements are of generic type `T`, for example [OverlayItemPosition]
  /// for [OverlayItemAlarmsList] or [LandmarkPosition] for [LandmarkAlarmsList].
  ///
  /// ## Returns
  ///
  /// - `List<T>`: The alarm items.
  List<T> get items;
}

/// Alarms list referencing overlay items by geographic coordinates.
///
/// Concrete implementation of [AlarmsList] that provides access to overlay item
/// alarm positions and related utilities. Use instances returned by the
/// [AlarmService.overlayItemAlarms] or [AlarmService.overlayItemAlarmsPassedOver]
/// properties to inspect incoming or passed-over overlay item alarms.
///
/// ## See also:
///
/// - [AlarmService.overlayItemAlarms] - Retrieve active overlay item alarms.
/// - [OverlayItemPosition] - Represents an overlay item and its distance information.
///
/// {@category Alarms}
class OverlayItemAlarmsList extends GemAutoreleaseObject
    implements AlarmsList<OverlayItemPosition> {
  @internal
  OverlayItemAlarmsList.init(super.id);

  @override
  Coordinates get referenceCoordinates {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItemAlarmsList',
      'getReferenceCoordinates',
    );

    return Coordinates.fromJson(resultString['result']);
  }

  @override
  int getDistance(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItemAlarmsList',
      'getDistance',
      args: index,
    );

    return resultString['result'];
  }

  @override
  int get size {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItemAlarmsList',
      'size',
    );
    return resultString['result'];
  }

  @override
  List<OverlayItemPosition> get items {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItemAlarmsList',
      'getItems',
    );

    final OverlayItemPositionList list = OverlayItemPositionList.init(
      resultString['result'],
    );
    return list.toList();
  }
}

/// Alarms list referencing landmarks by geographic coordinates.
///
/// Concrete implementation of [AlarmsList] that returns landmark positions and
/// exposes distance information relative to the alarm reference coordinates. Use
/// instances returned by [AlarmService.landmarkAlarms] or
/// [AlarmService.landmarkAlarmsPassedOver] to inspect incoming or passed-over
/// landmark alarms.
///
/// ## See also:
///
/// - [AlarmService.landmarkAlarms] - Retrieve active landmark alarms.
/// - [LandmarkPosition] - Represents a landmark and its distance information.
///
/// {@category Alarms}
class LandmarkAlarmsList extends GemAutoreleaseObject
    implements AlarmsList<LandmarkPosition> {
  @internal
  LandmarkAlarmsList.init(super.id);

  @override
  Coordinates get referenceCoordinates {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkAlarmsList',
      'getReferenceCoordinates',
    );

    return Coordinates.fromJson(resultString['result']);
  }

  @override
  int getDistance(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkAlarmsList',
      'getDistance',
      args: index,
    );

    return resultString['result'];
  }

  @override
  int get size {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkAlarmsList',
      'size',
    );

    return resultString['result'];
  }

  @override
  List<LandmarkPosition> get items {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkAlarmsList',
      'getItems',
    );

    final LandmarkPositionList list = LandmarkPositionList.init(
      resultString['result'],
    );
    return list.toList();
  }
}

/// A coordinate-referenced wrapper for an [OverlayItem].
///
/// Instances represent the association between an overlay item and a
/// specific coordinate. Usually provided via [AlarmService].
///
/// {@category Maps & 3D Scenes}
class OverlayItemPosition extends GemAutoreleaseObject {
  // ignore: unused_element
  OverlayItemPosition._() : super(-1);

  @internal
  OverlayItemPosition.init(super.id);

  /// Get the associated [OverlayItem].
  ///
  /// ## Returns
  ///
  /// - The [OverlayItem] instance referenced by this position.
  OverlayItem get overlayItem {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItemPosition',
      'getOverlayItem',
    );

    return OverlayItem.init(resultString['result']);
  }

  /// Distance in meters from the reference coordinates to the overlay item.
  ///
  /// The distance is calculated as a straight line distance between two coordinates except when the overlay is related to a route (e.g. an alarm along route)
  /// in which case the distance is calculated along the route
  ///
  /// ## Returns
  ///
  /// - Distance in meters as an [int].
  int get distance {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItemPosition',
      'getDistance',
    );

    return resultString['result'];
  }

  /// Get deviation in meters from reference coordinates to the OverlayItem object.
  ///
  /// The deviation is equal with distance except when the overlay is related to a route (e.g. an alarm along route)
  /// in which case is calculated as a straight line distance between the overlay and the closest point on the route
  ///
  /// ## Returns
  ///
  /// - Distance in meters as an [int].
  int get deviation {
    final OperationResult resultString = objectMethod(
      pointerId,
      'OverlayItemPosition',
      'getDeviation',
    );

    return resultString['result'];
  }
}

/// A landmark together with its distance from a reference coordinates.
///
/// Instances represent the pairing of a [Landmark] object and the computed distance (in meters)
/// from a reference point. Typically returned by [AlarmService] and [AlarmListener] methods.
///
/// This class is managed by the SDK and is not intended for direct instantiation.
///
/// ## Returns
///
/// - [landmark]: The associated [Landmark].
/// - [distance]: Distance in meters from the reference coordinates.
///
/// {@category Landmark Store}
class LandmarkPosition extends GemAutoreleaseObject {
  // ignore: unused_element
  LandmarkPosition._() : super(-1);

  @internal
  LandmarkPosition.init(super.id);

  /// Retrieves the landmark object.
  ///
  /// ## Returns
  ///
  /// - The associated [Landmark] object.
  Landmark get landmark {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkPosition',
      'getLandmark',
    );

    return Landmark.init(resultString['result']);
  }

  /// Retrieves the distance from the reference coordinates to this landmark.
  ///
  /// The distance is calculated as a straight line distance between two coordinates except when the landmark is related to a route (e.g. an alarm along route)
  /// in which case the distance is calculated along the route
  ///
  /// ## Returns
  ///
  /// - Distance in meters as an integer.
  int get distance {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkPosition',
      'getDistance',
    );

    return resultString['result'];
  }

  /// Get deviation in meters from reference coordinates to the landmark object
  ///
  /// The deviation is equal with distance except when the landmark is related to a route (e.g. an alarm along route)
  /// in which case is calculated as a straight line distance between the landmark and the closest point on the route
  ///
  /// ## Returns
  ///
  /// - Distance in meters as an integer.
  int get deviation {
    final OperationResult resultString = objectMethod(
      pointerId,
      'LandmarkPosition',
      'getDeviation',
    );

    return resultString['result'];
  }
}
