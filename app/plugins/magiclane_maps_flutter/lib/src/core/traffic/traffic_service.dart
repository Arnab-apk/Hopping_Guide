// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/routing.dart';
import 'package:magiclane_maps_flutter/src/core/private/lists.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Provides access to traffic-related services and user roadblock management.
///
/// This static API exposes operations to add, remove and query user-defined
/// roadblocks, retrieve traffic service preferences and transfer statistics,
/// and obtain online service restrictions for a geographic position.
///
/// ## See also:
///
/// - [TrafficPreferences] - Traffic service preferences
/// - [TrafficEvent] - Traffic event representation
/// - [TrafficOnlineRestrictions] - Online traffic service restrictions
///
/// {@category Traffic & Roadblocks}
abstract class TrafficService {
  /// Traffic service preferences accessor.
  ///
  /// Returns the current [TrafficPreferences] instance which exposes settings
  /// used to configure how traffic data and roadblocks are handled by the
  /// SDK (for example enabling/disabling traffic data or selecting online
  /// vs offline usage).
  ///
  /// ## Returns
  ///
  /// - The [TrafficPreferences] instance.
  static TrafficPreferences get preferences {
    final OperationResult resultString = staticMethod(
      'TrafficService',
      'preferences',
    );

    return TrafficPreferences.init(resultString['result']);
  }

  /// Retrieves online traffic service restrictions for a position.
  ///
  /// This method queries the SDK's online traffic checks for the provided
  /// [coords] and returns the set of [TrafficOnlineRestrictions] describing any
  /// conditions that prevent or limit online traffic functionality (for
  /// example: no connection, missing provider data, or a disabled setting).
  ///
  /// ## Parameters
  ///
  /// - [coords]: The geographic position to evaluate.
  ///
  /// ## Returns
  ///
  /// - A `Set<TrafficOnlineRestrictions>` describing the active restrictions at
  ///   the given position; empty when there are no restrictions.
  static Set<TrafficOnlineRestrictions> getOnlineServiceRestrictions(
    Coordinates coords,
  ) {
    final OperationResult resultString = staticMethod(
      'TrafficService',
      'getOnlineServiceRestrictions',
      args: coords,
    );

    final int mask = resultString['result'];
    final Set<TrafficOnlineRestrictions> result = <TrafficOnlineRestrictions>{};
    for (final TrafficOnlineRestrictions value
        in TrafficOnlineRestrictions.values) {
      if (mask & value.id != 0) {
        result.add(value);
      }
    }
    return result;
  }

  /// Data transfer statistics for the traffic service.
  ///
  /// Returns a [TransferStatistics] object containing counters and metrics
  /// about network usage performed by the traffic service. This information
  /// can be used for diagnostics or to display usage to end users.
  ///
  /// ## Returns
  ///
  /// - The [TransferStatistics] instance.
  static TransferStatistics get transferStatistics {
    final OperationResult resultString = staticMethod(
      'TrafficService',
      'getTransferStatistics',
    );

    return TransferStatistics.init(resultString['result']);
  }

  /// Adds a user-defined persistent roadblock using a list of coordinates.
  ///
  /// If [coords] contains a single coordinate a point roadblock is defined,
  /// which may create two roadblock records (one per direction) when matched
  /// to bidirectional roads.
  /// If [coords] contains multiple points a path
  /// roadblock is created covering the route from the first to the last
  /// coordinate.
  ///
  /// ## Parameters
  ///
  /// - [coords]: A list of [Coordinates] defining the roadblock geometry.
  /// - [startTime]: The UTC start time when the roadblock becomes active.
  /// - [expireTime]: The UTC expiry time when the roadblock is removed.
  /// - [transportMode]: The [RouteTransportMode] affected by the roadblock.
  /// - [id]: A unique identifier for the user roadblock. This id can later
  ///   be used to retrieve or delete the roadblock via [TrafficEvent.description].
  ///
  /// ## Returns
  ///
  /// - A tuple `([TrafficEvent]?, [GemError])` where the first element is the
  ///   created [TrafficEvent] on success, and the second element is a
  ///   [GemError] code. On failure the event will be `null` and the error
  ///   explains the cause. Possible error codes include:
  ///   - [GemError.activation]: Roadblocks are disabled in [TrafficPreferences].
  ///   - [GemError.exist]: A roadblock with the same id already exists.
  ///   - [GemError.invalidInput]: One or more parameters are invalid.
  ///   - [GemError.notFound]: No suitable street match or map data missing.
  ///   - [GemError.inUse]: The provided id is already in use.
  ///   - [GemError.noRoute]: The coordinates cannot define a valid route.
  ///
  /// ## Also see:
  ///
  /// - [addAntiPersistentRoadblockByArea] to create an anti-area roadblock that
  /// whitelists an area instead of blocking it.
  /// - [addPersistentRoadblockByArea] to create roadblocks defined by
  /// geographic areas.
  static (TrafficEvent?, GemError) addPersistentRoadblockByCoordinates({
    required List<Coordinates> coords,
    required DateTime startTime,
    required DateTime expireTime,
    required RouteTransportMode transportMode,
    required String id,
  }) {
    final OperationResult resultString = staticMethod(
      'TrafficService',
      'addPersistentRoadblockCoords',
      args: <String, dynamic>{
        'coord': coords,
        'startUTC': startTime.millisecondsSinceEpoch,
        'expireUTC': expireTime.millisecondsSinceEpoch,
        'transportMode': transportMode.id,
        'id': id,
      },
    );

    final GemError error = GemErrorExtension.fromCode(
      resultString['result']['second'],
    );
    if (error != GemError.success) {
      return (null, error);
    }

    return (TrafficEvent.init(resultString['result']['first']), error);
  }

  /// Adds a user-defined persistent roadblock covering a geographic area.
  ///
  /// ## Parameters
  ///
  /// - [area]: The [GeographicArea] affected by the roadblock.
  /// - [startTime]: The UTC start time for the roadblock.
  /// - [expireTime]: The UTC expiry time for the roadblock.
  /// - [transportMode]: The [RouteTransportMode] affected by the roadblock.
  /// - [id]: A unique identifier for the user roadblock.
  ///
  /// ## Returns
  ///
  /// - A tuple `([TrafficEvent]?, [GemError])` where the first element is the
  ///   created [TrafficEvent] on success, and the second element is a
  ///   [GemError] code. On failure the event will be `null` and the error
  ///   explains the cause. Possible error codes include:
  ///   - [GemError.activation]: Roadblocks are disabled in [TrafficPreferences].
  ///   - [GemError.exist]: A roadblock with the same id already exists.
  ///   - [GemError.invalidInput]: One or more parameters are invalid.
  ///   - [GemError.notFound]: No suitable street match or map data missing.
  ///   - [GemError.inUse]: The provided id is already in use.
  ///
  /// ## Also see:
  ///
  /// - [addAntiPersistentRoadblockByArea] to create an anti-area roadblock that
  /// whitelists an area instead of blocking it.
  /// - [addPersistentRoadblockByCoordinates] to create roadblocks defined by
  /// coordinates.
  static (TrafficEvent?, GemError) addPersistentRoadblockByArea({
    required GeographicArea area,
    required DateTime startTime,
    required DateTime expireTime,
    required RouteTransportMode transportMode,
    required String id,
  }) {
    final OperationResult resultString = staticMethod(
      'TrafficService',
      'addPersistentRoadblockArea',
      args: <String, dynamic>{
        'area': area,
        'startUTC': startTime.millisecondsSinceEpoch,
        'expireUTC': expireTime.millisecondsSinceEpoch,
        'transportMode': transportMode.id,
        'id': id,
      },
    );

    final GemError error = GemErrorExtension.fromCode(
      resultString['result']['second'],
    );
    if (error != GemError.success) {
      return (null, error);
    }

    return (TrafficEvent.init(resultString['result']['first']), error);
  }

  /// Adds a user-defined persistent anti-area roadblock.
  ///
  /// An anti-area roadblock applies to the world except for the provided
  /// [area]. Use this to define a global restriction excluding a smaller
  /// polygonal or circular area.
  ///
  /// ## Parameters
  ///
  /// - [area]: The [GeographicArea] that will **NOT** be affected (the anti-area).
  /// - [startTime]: The UTC start time for the anti-area roadblock.
  /// - [expireTime]: The UTC expiry time for the anti-area roadblock.
  /// - [transportMode]: The [RouteTransportMode] affected by this rule.
  /// - [id]: A unique identifier for the user roadblock.
  ///
  /// ## Returns
  ///
  /// - A tuple `([TrafficEvent]?, [GemError])` where the first element is the
  ///   created [TrafficEvent] on success, and the second element is a
  ///   [GemError] code. On failure the event will be `null` and the error
  ///   explains the cause. Possible error codes include:
  ///   - [GemError.activation]: Roadblocks are disabled in [TrafficPreferences].
  ///   - [GemError.exist]: A roadblock with the same id already exists.
  ///   - [GemError.invalidInput]: One or more parameters are invalid.
  ///   - [GemError.notFound]: No suitable street match or map data missing.
  ///   - [GemError.inUse]: The provided id is already in use.
  static (TrafficEvent?, GemError) addAntiPersistentRoadblockByArea({
    required GeographicArea area,
    required DateTime startTime,
    required DateTime expireTime,
    required RouteTransportMode transportMode,
    required String id,
  }) {
    final OperationResult resultString = staticMethod(
      'TrafficService',
      'addPersistentAntiRoadblockArea',
      args: <String, dynamic>{
        'area': area,
        'startUTC': startTime.millisecondsSinceEpoch,
        'expireUTC': expireTime.millisecondsSinceEpoch,
        'transportMode': transportMode.id,
        'id': id,
      },
    );

    final GemError error = GemErrorExtension.fromCode(
      resultString['result']['second'],
    );
    if (error != GemError.success) {
      return (null, error);
    }

    return (TrafficEvent.init(resultString['result']['first']), error);
  }

  /// Removes a previously created persistent roadblock by its identifier.
  ///
  /// ## Parameters
  ///
  /// - [id]: The unique identifier of the persistent roadblock to remove.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on successful removal, or [GemError.notFound]
  /// if no matching roadblock exists.
  ///
  /// ## Also see:
  ///
  /// - [removePersistentRoadblockByCoordinates] - Remove a roadblock by its
  ///   reference coordinate.
  /// - [TrafficEvent.description] - Retrieve the id of a user-defined roadblock.
  /// - [removeUserRoadblock] - Remove a roadblock by passing the [TrafficEvent].
  static GemError removePersistentRoadblockById(String id) {
    final OperationResult resultString = staticMethod(
      'TrafficService',
      'removePersistentRoadblockById',
      args: id,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Removes a persistent roadblock identified by its reference coordinate.
  ///
  /// The provided [coords] must match the start coordinate that was used
  /// when the roadblock was originally defined for path-type roadblocks.
  ///
  /// ## Parameters
  ///
  /// - [coords]: The reference [Coordinates] used to identify the roadblock.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on successful removal, or [GemError.notFound]
  /// if no matching roadblock exists.
  ///
  /// ## Also see:
  ///
  /// - [removePersistentRoadblockById] - Remove a roadblock by its unique id.
  /// - [removeUserRoadblock] - Remove a roadblock by passing the [TrafficEvent].
  static GemError removePersistentRoadblockByCoordinates(Coordinates coords) {
    final OperationResult resultString = staticMethod(
      'TrafficService',
      'removePersistentRoadblock',
      args: coords,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Removes all user-defined persistent roadblocks.
  ///
  /// This clears every persistent roadblock created by the application.
  ///
  /// ## Also see:
  ///
  /// - [removePersistentRoadblockById] - Remove a roadblock by its unique id.
  /// - [removePersistentRoadblockByCoordinates] - Remove a roadblock by its reference coordinate.
  static void removeAllPersistentRoadblocks() {
    staticMethod('TrafficService', 'removeAllPersistentRoadblocks');
  }

  /// Retrieves a persistent roadblock by its identifier.
  ///
  /// ## Parameters
  ///
  /// - [id]: The identifier provided when the roadblock was created.
  ///
  /// ## Returns
  ///
  /// - The corresponding [TrafficEvent] if found, or `null` if no matching
  ///   roadblock exists.
  ///
  /// ## Also see:
  ///
  /// - [TrafficEvent.description] - Retrieve the id of a user-defined roadblock.
  static TrafficEvent? getPersistentRoadblock(String id) {
    final OperationResult resultString = staticMethod(
      'TrafficService',
      'getPersistentRoadblock',
      args: id,
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return TrafficEvent.init(resultString['result']);
  }

  /// Returns all persistent user roadblocks managed by the traffic service.
  ///
  /// ## Returns
  ///
  /// - A [List<TrafficEvent>] containing all persistent roadblocks.
  static List<TrafficEvent> get persistentRoadblocks {
    final OperationResult resultString = staticMethod(
      'TrafficService',
      'getPersistentRoadblocks',
    );

    final TrafficEventList eventsList = TrafficEventList.init(
      resultString['result'],
    );
    return eventsList.toList();
  }

  /// Removes a user-defined roadblock, whether persistent or not.
  ///
  /// ## Parameters
  ///
  /// - [event]: The [TrafficEvent] instance that identifies the roadblock to remove.
  ///
  /// ## Also see:
  ///
  /// - [removePersistentRoadblockById] - Remove a roadblock by its unique id.
  /// - [removePersistentRoadblockByCoordinates] - Remove a roadblock by its reference coordinate.
  static void removeUserRoadblock(TrafficEvent event) {
    staticMethod(
      'TrafficService',
      'removeUserRoadblock',
      args: event.pointerId,
    );
  }

  /// Returns a preview of a persistent roadblock path between two coordinates.
  ///
  /// The preview is calculated for the specified [transportMode] and returns
  /// the list of coordinates representing the suggested path, a preview
  /// coordinate to indicate the next likely roadblock match, and a [GemError]
  /// describing success or any failure.
  ///
  /// The [from] parameter should be obtained from a previous call to this method
  /// or created via [UserRoadblockPathPreviewCoordinate.fromCoordinates] for
  /// the initial call.
  ///
  /// At the end of the operation, the returned coordinates can be used to
  /// create a path [TrafficEvent] representing the roadblock via the
  /// [addPersistentRoadblockByCoordinates] method.
  ///
  /// ## Parameters
  ///
  /// - [from]: The starting [UserRoadblockPathPreviewCoordinate].
  /// - [to]: The destination [Coordinates] for the preview.
  /// - [transportMode]: The [RouteTransportMode] used for routing the preview.
  ///
  /// ## Returns
  ///
  /// - A tuple containing:
  ///   - [List<Coordinates>]: The path preview coordinates ordered from `from` to `last`.
  ///   - [UserRoadblockPathPreviewCoordinate]: The suggested preview coordinate.
  ///   - [GemError]: An error code indicating success or failure.
  ///
  /// ## Example
  ///
  /// Create a new [UserRoadblockPathPreviewCoordinate] for the starting point:
  /// ```dart
  /// UserRoadblockPathPreviewCoordinate preview = UserRoadblockPathPreviewCoordinate.fromCoordinates(startCoordinates);
  /// ```
  ///
  /// Call the method to get the subsequent [UserRoadblockPathPreviewCoordinate] based on the previous one:
  /// ```dart
  /// final (coordinates, newPreviewStart, previewError) =
  ///   TrafficService.getPersistentRoadblockPathPreview(
  ///   from: preview,
  ///   to: nextCoordinates,
  ///   transportMode: RouteTransportMode.car,
  /// );
  ///
  /// if (previewError == GemError.success) {
  ///   preview = newPreviewStart;
  /// }
  /// ```
  ///
  /// ## Also see:
  ///
  /// - [addPersistentRoadblockByCoordinates] to create a persistent roadblock
  ///  using the returned coordinates.
  /// - [UserRoadblockPathPreviewCoordinate.fromCoordinates] to create the initial preview coordinate.
  static (List<Coordinates>, UserRoadblockPathPreviewCoordinate, GemError)
  getPersistentRoadblockPathPreview({
    required UserRoadblockPathPreviewCoordinate from,
    required Coordinates to,
    required RouteTransportMode transportMode,
  }) {
    final OperationResult resultString = staticMethod(
      'TrafficService',
      'getPersistentRoadblockPathPreview',
      args: <String, dynamic>{
        'from': from,
        'to': to,
        'transportMode': transportMode.id,
      },
    );

    final List<Coordinates> coordinates =
        (resultString['result']['coords'] as List<dynamic>)
            .map((dynamic e) => Coordinates.fromJson(e))
            .toList();
    final UserRoadblockPathPreviewCoordinate previewCoordinate =
        UserRoadblockPathPreviewCoordinate.fromJson(
          resultString['result']['preview'],
        );
    final GemError error = GemErrorExtension.fromCode(
      resultString['result']['error'],
    );

    return (coordinates, previewCoordinate, error);
  }

  /// Sets a listener to receive updates about persistent roadblocks.
  ///
  /// Notifies when a persistent roadblock is activated or expired.
  ///
  /// ## Parameters
  ///
  /// - [listener]: The [PersistentRoadblockListener] to register. Pass `null` to unregister the current listener.
  ///
  /// ## Also see:
  ///
  /// - [PersistentRoadblockListener] - Interface for receiving roadblock events.
  static set persistentRoadblockListener(
    PersistentRoadblockListener? listener,
  ) {
    if (listener == null) {
      staticMethod(
        'TrafficService',
        'setPersistentRoadblockListener',
        args: -1,
      );
      return;
    }

    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    staticMethod(
      'TrafficService',
      'setPersistentRoadblockListener',
      args: listener.id,
    );
  }
}
