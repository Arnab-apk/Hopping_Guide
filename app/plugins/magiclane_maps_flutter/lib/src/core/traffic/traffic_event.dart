// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:typed_data';
import 'dart:ui' show Size;

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/routing.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Represents a traffic event such as congestion, roadworks or closures.
///
/// Represents a single traffic occurrence such as a delay, closure or
/// user-defined roadblock. Instances are provided by the SDK in several
/// contexts:
/// - From map interaction listeners (for example when the user selects a
///   traffic event via the [GemMapController.registerOnCursorSelectionUpdatedTrafficEvents]).
/// - As part of route data via [RouteBase.trafficEvents].
///
/// Do not instantiate this class directly. Use API entry points such as the
/// [GemMapController.registerOnCursorSelectionUpdatedOverlayItems] listener or
/// [RouteBase.trafficEvents] to obtain instances.
///
/// A [TrafficEvent] exposes metadata about the event (description, severity,
/// class), spatial information (reference point, bounding box or area) and
/// timing (start and end timestamps). For user-defined roadblocks the
/// [description] may contain the user-provided id.
///
/// ## See also:
///
/// - [RouteTrafficEvent] — Route-specific traffic event details.
/// - [TrafficService] — Manage persistent user roadblocks and traffic
///   preferences.
///
/// {@category Traffic & Roadblocks}
class TrafficEvent extends GemAutoreleaseObject {
  @internal
  TrafficEvent() : super(-1);

  @internal
  TrafficEvent.init(super.pointerId);

  /// Whether this traffic event represents a roadblock.
  ///
  /// Roadblocks are events that block or heavily restrict traffic on a road
  /// segment or geographic area. This returns `true` for both server-provided
  /// roadblocks and user-defined roadblocks.
  ///
  /// ## Returns
  ///
  /// - [bool]: `true` when the event is a roadblock, otherwise `false`.
  bool get isRoadblock {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'isRoadblock',
    );

    return resultString['result'];
  }

  /// Estimated delay introduced by the traffic event.
  ///
  /// The delay is expressed in seconds. When the delay is not available the
  /// SDK returns `-1`.
  ///
  /// ## Returns
  ///
  /// - [int]: estimated delay in seconds, or `-1` when unknown.
  int get delay {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getDelay',
    );

    return resultString['result'];
  }

  /// Length in meters of the affected road segment.
  ///
  /// Returns `-1` when the length is unknown or not applicable (for some
  /// area-based events).
  ///
  /// ## Returns
  ///
  /// - [int]: length in meters, or `-1` when unknown.
  int get length {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getLength',
    );

    return resultString['result'];
  }

  /// Impact zone type for the event.
  ///
  /// Indicates whether the event affects a path (road geometry) or a broader
  /// area.
  ///
  /// ## Returns
  ///
  /// - [TrafficEventImpactZone]: the impact zone classification.
  TrafficEventImpactZone get impactZone {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getImpactZone',
    );

    return TrafficEventImpactZoneExtension.fromId(resultString['result']);
  }

  /// Central reference point for the event.
  ///
  /// ## Returns
  ///
  /// - [Coordinates]: the event reference point (may be `(0,0)` for area
  ///   events).
  ///
  /// ## Also see:
  ///
  /// - [area] — precise geographic area of the event, in case of area-based events.
  Coordinates get referencePoint {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getReferencePoint',
    );

    return Coordinates.fromJson(resultString['result']);
  }

  /// Bounding box that encloses the event geometry.
  ///
  /// Use this when you need a simple rectangle containing the event. For
  /// precise shapes prefer the [area] when available.
  ///
  /// ## Returns
  ///
  /// - [RectangleGeographicArea]: geographic bounding rectangle.
  ///
  /// ## Also see:
  ///
  /// - [area] — precise geographic area of the event, in case of area-based events.
  RectangleGeographicArea get boundingBox {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getBoundingBox',
    );

    return RectangleGeographicArea.fromJson(resultString['result']);
  }

  /// Human readable description of the traffic event.
  ///
  /// For user-defined roadblocks this may contain the user-supplied id or
  /// additional metadata.
  ///
  /// ## Returns
  ///
  /// - [String]: descriptive text (empty string when no description is
  ///   available).
  String get description {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getDescription',
    );

    return resultString['result'];
  }

  /// Classification of the traffic event.
  ///
  /// Provides a high-level categorization (for example `roadworks`,
  /// `accidents`, `delays`).
  ///
  /// ## Returns
  ///
  /// - [TrafficEventClass]: event classification.
  TrafficEventClass get eventClass {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getEventClass',
    );

    return TrafficEventClassExtension.fromId(resultString['result']);
  }

  /// Severity level of the traffic event.
  ///
  /// ## Returns
  ///
  /// - [TrafficEventSeverity]: severity classification.
  TrafficEventSeverity get eventSeverity {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getEventSeverity',
    );

    return TrafficEventSeverityExtension.fromId(resultString['result']);
  }

  /// Retrieves an image representing the traffic event.
  ///
  /// The SDK may return an image useful for UI display. When `null` no image
  /// is available.
  ///
  /// ## Parameters
  ///
  /// - [size]: Desired image size. When omitted the SDK default is used.
  /// - [format]: Preferred image file format.
  ///
  /// ## Returns
  ///
  /// - [Uint8List?]: raw image bytes or `null` when no image is available.
  ///
  /// ## Also see:
  ///
  /// - [img] — image wrapper useful for SDK rendering APIs.
  Uint8List? getImage({final Size? size, final ImageFileFormat? format}) {
    return GemKitPlatform.instance.callGetImage(
      pointerId,
      'TrafficEvent',
      size?.width.toInt() ?? -1,
      size?.height.toInt() ?? -1,
      format?.id ?? -1,
    );
  }

  /// Get the image as a [Img].
  ///
  /// Prefer [Img] when you need SDK-managed metadata (uid, recommended size/aspectRatio, scalability)
  /// or to request raw image bytes; use [getImage] when you only need raw image bytes.
  ///
  /// ## Returns
  ///
  /// - [Img]: image wrapper (may be invalid if no image is available). The
  ///   caller is responsible for validating the `Img` instance.
  ///
  /// ## Also see:
  ///
  /// - [getImage] — retrieve raw image bytes when needed.
  Img get img {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getImg',
    );

    return Img.init(resultString['result']);
  }

  /// URL for a web preview of the traffic event.
  ///
  /// Can be empty when no preview is available (for example for some
  /// user-defined roadblocks).
  ///
  /// ## Returns
  ///
  /// - [String]: preview URL or empty string when not available.
  String get previewUrl {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getPreviewUrl',
    );

    return resultString['result'];
  }

  /// Whether the traffic event was created by the user.
  ///
  /// ## Returns
  ///
  /// - [bool]: `true` when the event is a user-defined roadblock.
  bool get isUserRoadblock {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'isUserRoadblock',
    );

    return resultString['result'];
  }

  /// Transport modes affected by this event.
  ///
  /// Useful to determine whether the event impacts car, pedestrian or
  /// other transport modes.
  ///
  /// ## Returns
  ///
  /// - [RouteTransportMode]: affected transport modes.
  RouteTransportMode get affectedTransportModes {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getAffectedTransportMode',
    );

    final int res = resultString['result'];
    return RouteTransportModeExtension.fromId(res);
  }

  /// Event start time in UTC.
  ///
  /// ## Returns
  ///
  /// - [DateTime?]: UTC start time when available, otherwise `null`.
  DateTime? get startTime {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getStartTime',
    );

    final int milliseconds = resultString['result'];
    if (milliseconds == 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }

  /// Event end time in UTC.
  ///
  /// ## Returns
  ///
  /// - [DateTime?]: UTC end time when available, otherwise `null`.
  DateTime? get endTime {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getEndTime',
    );

    final int milliseconds = resultString['result'];
    if (milliseconds == 0) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(milliseconds, isUtc: true);
  }

  /// Whether a corresponding event exists in the opposite direction.
  ///
  /// ## Returns
  ///
  /// - [bool]: `true` when a sibling event exists in the opposite
  ///   direction, otherwise `false`.
  bool get hasOppositeSibling {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'hasOppositeSibling',
    );

    return resultString['result'];
  }

  /// Asynchronously retrieve traffic preview data for the event.
  ///
  /// The preview data contains a list of `TrafficParameters` with additional
  /// metadata useful for UI and diagnostics.
  ///
  /// ## Parameters
  ///
  /// - [onResult]: Function called when the operation completes. The function is called with:
  ///   - [GemError.success] for `error` and [TrafficParameters] for `data` when preview data is available.
  ///   - [GemError.notSupported] for `error` and `null` for `data` when preview is not available for this event.
  ///   - [GemError.noConnection], [GemError.networkFailed], [GemError.networkTimeout] for `error` and `null` for `data` when network issues prevented retrieval.
  ///   - [GemError.notFound] for `error` and `null` for `data` when no preview data exists for this event.
  ///   - [GemError.general] for `error` and `null` for `data` when the request failed for other reasons.
  ///   - Other values for `error` and `null` for `data` indicate other failures.
  ///
  /// ## Returns
  ///
  /// - [ProgressListener?]: listener that can be used to cancel the
  ///   operation, or `null` when the operation could not be started.
  ///
  /// ## Example
  ///
  /// ```dart
  /// event.getPreviewData(
  ///   (GemError error, TrafficParameters? data) {
  ///     if (error == GemError.success && data != null) {
  ///       print('Preview id: ${data.id}');
  ///       print('Description: ${data.description}');
  ///       print('Delay (s): ${data.delay}');
  ///     } else {
  //       // Handle error cases (not supported, network issues, not found, ...)
  ///       print('Failed to get preview data: $error');
  ///     }
  ///   },
  /// );
  /// ```
  ///
  /// ## Also see:
  ///
  /// - [TrafficParameters] - Class representing traffic preview data.
  /// - [cancelGetPreviewData] - Cancel an active preview data request.
  ProgressListener? getPreviewData(
    void Function(GemError error, TrafficParameters? data) onResult,
  ) {
    final EventDrivenProgressListener listener = EventDrivenProgressListener();
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);
    final SearchableParameterList parameterList = SearchableParameterList();

    listener.registerOnCompleteWithData((int code, _, _) {
      final GemError error = GemErrorExtension.fromCode(code);
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
      if (error != GemError.success) {
        onResult(error, null);
      } else {
        final TrafficParameters trafficParams =
            TrafficParameters.fromParameters(parameterList.toList());
        onResult(error, trafficParams);
      }
    });

    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getPreviewData',
      args: <String, dynamic>{
        'first': parameterList.pointerId,
        'second': listener.id,
      },
    );

    if (resultString['result'] != 0) {
      GemKitPlatform.instance.unregisterEventHandler(listener.id);
      onResult(GemErrorExtension.fromCode(resultString['result']), null);
      return null;
    }

    return listener;
  }

  /// Cancel an active preview data request started with [getPreviewData].
  ///
  /// ## Parameters
  ///
  /// - [listener]: the [ProgressListener] returned by [getPreviewData].
  ///
  /// ## See also:
  ///
  /// - [getPreviewData] - Get preview data for the event.
  void cancelGetPreviewData(ProgressListener listener) {
    objectMethod(
      pointerId,
      'TrafficEvent',
      'cancelGetPreviewData',
      args: listener.id,
    );
  }

  /// Geographic area associated with the event.
  ///
  /// If the impact zone is `path` the returned area is typically the
  /// [boundingBox]. For `area` impact zones the returned value is the more
  /// precise geographic area used to define the event.
  ///
  /// ## Returns
  ///
  /// - [GeographicArea]: geographic area of the event.
  GeographicArea get area {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'getArea',
    );

    return GeographicArea.fromJson(resultString['result']);
  }

  /// Whether an area-based event is an anti-area.
  ///
  /// Valid only for `TrafficEventImpactZone.area` events. An anti-area means
  /// the defined area represents the region that is *not* affected by other area events.
  ///
  /// ## Returns
  ///
  /// - [bool]: `true` when the impact zone is an anti-area, otherwise
  ///   `false`.
  bool get isAntiArea {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'isAntiarea',
    );

    return resultString['result'];
  }

  /// Whether this event is currently active (started).
  ///
  /// ## Returns
  ///
  /// - [bool]: `true` when the event is active, otherwise `false`.
  ///
  /// ## Also see:
  ///
  /// - [PersistentRoadblockListener.registerOnRoadblocksActivated] - Register a callback for when user roadblocks are activated.
  bool get isActive {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'isActive',
    );

    return resultString['result'];
  }

  /// Whether this event is expired (ended).
  ///
  /// ## Returns
  ///
  /// - [bool]: `true` when the event has ended, otherwise `false`.
  ///
  /// ## Also see:
  ///
  /// - [PersistentRoadblockListener.registerOnRoadblocksExpired] - Register a callback for when user roadblocks expire.
  bool get isExpired {
    final OperationResult resultString = objectMethod(
      pointerId,
      'TrafficEvent',
      'isExpired',
    );

    return resultString['result'];
  }
}
