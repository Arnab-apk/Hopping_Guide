// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Represents a mapped driving event detected during a driving session.
///
/// Use instances returned by [DriverBehaviourAnalysis.drivingEvents] to inspect
/// the type, time and location of discrete driving incidents (for example,
/// harsh braking or cornering).
///
/// This class is created by the SDK and should
/// not be instantiated directly by consumers.
///
/// ## See also:
///
/// - [DrivingEvent] - Enum defining types of driving events.
/// - [DriverBehaviourAnalysis.drivingEvents] - Retrieves the list of all detected events in a session.
///
/// {@category Driver Behaviour}
class MappedDrivingEvent extends GemAutoreleaseObject {
  // ignore: unused_element
  MappedDrivingEvent._() : super(-1);

  @internal
  MappedDrivingEvent.init(super.pointerId);

  /// Timestamp of the event in milliseconds since Unix epoch (UTC).
  ///
  /// ## Returns
  ///
  /// - The event timestamp in milliseconds since epoch.
  ///
  /// ## See also:
  ///
  /// - [timestamp] - Date and time of the event in UTC as a [DateTime] object.
  int get time {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MappedDrivingEvent',
      'getTime',
    );

    return resultString['result'];
  }

  /// Date and time of the event in UTC.
  ///
  /// ## Returns
  ///
  /// - The event [DateTime] in UTC.
  DateTime get timestamp =>
      DateTime.fromMillisecondsSinceEpoch(time, isUtc: true);

  /// Location of the event as [Coordinates].
  ///
  /// ## Returns
  ///
  /// - The event location as [Coordinates].
  Coordinates get coordinates =>
      Coordinates(latitude: latitudeDeg, longitude: longitudeDeg);

  /// Latitude of the event location in decimal degrees.
  ///
  /// Values are in the range `[-90.0, 90.0]`.
  ///
  /// ## Returns
  ///
  /// - The latitude in decimal degrees.
  ///
  /// ## See also:
  ///
  /// - [coordinates] - Location of the event as [Coordinates].
  double get latitudeDeg {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MappedDrivingEvent',
      'getLatitudeDeg',
    );

    return resultString['result'];
  }

  /// Longitude of the event location in decimal degrees.
  ///
  /// Values are in the range `[-180.0, 180.0]`.
  ///
  /// ## Returns
  ///
  /// - The longitude in decimal degrees.
  ///
  /// ## See also:
  ///
  /// - [coordinates] - Location of the event as [Coordinates].
  double get longitudeDeg {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MappedDrivingEvent',
      'getLongitudeDeg',
    );

    return resultString['result'];
  }

  /// Detected event type for this mapped driving event.
  ///
  /// ## Returns
  ///
  /// - A [DrivingEvent] value describing the detected incident.
  DrivingEvent get eventType {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MappedDrivingEvent',
      'getEventType',
    );

    return DrivingEventExtension.fromId(resultString['result']);
  }
}

/// Driving event types detected during a driving session.
///
/// Each value represents a discrete driving incident that the Driver Behaviour
/// subsystem can detect (for example, harsh braking or cornering). Use the
/// values returned in [MappedDrivingEvent.eventType] to interpret the type of
/// incident recorded at a specific time and location.
///
/// ## See also:
///
/// - [MappedDrivingEvent] - Represents a detected driving event with location and timestamp.
/// - [DriverBehaviourAnalysis.drivingEvents] - Retrieves the list of all detected events in a session.
///
/// {@category Driver Behaviour}
enum DrivingEvent {
  /// No event detected.
  noEvent,

  /// Trip start event indicating the beginning of a driving session.
  startingTrip,

  /// Trip finish event indicating the end of a driving session.
  finishingTrip,

  /// Resting or pause period during the trip.
  resting,

  /// Rapid acceleration detected.
  harshAcceleration,

  /// Sudden hard braking detected.
  harshBraking,

  /// Aggressive cornering maneuver detected.
  cornering,

  /// Sudden lane change or swerving detected.
  swerving,

  /// Following another vehicle too closely.
  tailgating,

  /// Failure to observe traffic signs (e.g., running a stop sign).
  ignoringSigns,
}

/// @nodoc
extension DrivingEventExtension on DrivingEvent {
  int get id {
    switch (this) {
      case DrivingEvent.noEvent:
        return 0;
      case DrivingEvent.startingTrip:
        return 1;
      case DrivingEvent.finishingTrip:
        return 2;
      case DrivingEvent.resting:
        return 3;
      case DrivingEvent.harshAcceleration:
        return 4;
      case DrivingEvent.harshBraking:
        return 5;
      case DrivingEvent.cornering:
        return 6;
      case DrivingEvent.swerving:
        return 7;
      case DrivingEvent.tailgating:
        return 8;
      case DrivingEvent.ignoringSigns:
        return 9;
    }
  }

  static DrivingEvent fromId(final int id) {
    switch (id) {
      case 0:
        return DrivingEvent.noEvent;
      case 1:
        return DrivingEvent.startingTrip;
      case 2:
        return DrivingEvent.finishingTrip;
      case 3:
        return DrivingEvent.resting;
      case 4:
        return DrivingEvent.harshAcceleration;
      case 5:
        return DrivingEvent.harshBraking;
      case 6:
        return DrivingEvent.cornering;
      case 7:
        return DrivingEvent.swerving;
      case 8:
        return DrivingEvent.tailgating;
      case 9:
        return DrivingEvent.ignoringSigns;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
