// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/landmark_store.dart';
import 'package:magiclane_maps_flutter/map.dart';
import 'package:magiclane_maps_flutter/position.dart';
import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/sense/sense_data_impl/gem_position_impl.dart';
import 'package:meta/meta.dart';

/// Provides monitoring and notification for navigation-related alarm events.
///
/// The [AlarmService] manages a variety of alarm types including speed limit violations,
/// landmark proximity alerts, overlay item notifications (such as safety cameras and social reports),
/// geographic boundary crossings, tunnel entry/exit events, and day/night mode transitions.
/// Configure the service with an [AlarmListener] to receive callbacks for these events.
///
/// Multiple [AlarmService] and [AlarmListener] instances can operate simultaneously, enabling
/// concurrent monitoring of different events or areas.
///
/// Make sure to keep a reference to both the [AlarmService] and [AlarmListener] instances
/// for as long as you want to receive alarm notifications. If either instance is garbage
/// collected, alarm callbacks will stop being triggered.
///
/// ## Example
///
/// ```dart
/// AlarmService? alarmService;
///
/// // Create an alarm listener with callbacks
/// AlarmListener alarmListener = AlarmListener(
///   onHighSpeed: (limit, insideCityArea) {
///     print('Speed limit exceeded: $limit m/s');
///   },
///   onLandmarkAlarmsUpdated: () {
///     LandmarkAlarmsList landmarkAlarms = alarmService!.landmarkAlarms;
///     print('Approaching ${landmarkAlarms.items.first.landmark.name}');
///   },
/// );
///
/// // Create the alarm service
/// alarmService = AlarmService(alarmListener);
///
/// // Trigger alarms within 200m and monitor even without active navigation
/// alarmService.alarmDistance = 200;
/// alarmService.monitorWithoutRoute = true;
/// ```
///
/// ## See also:
///
/// - [AlarmListener] - For configuring alarm event callbacks.
/// - [OverlayItemAlarmsList] - For managing overlay item alarm lists.
/// - [LandmarkAlarmsList] - For managing landmark alarm lists.
///
/// {@category Alarms}
class AlarmService extends GemAutoreleaseObject {
  /// Creates an [AlarmService] instance that notifies the provided [listener] of alarm events.
  ///
  /// The [listener] must remain in memory for the duration of the monitoring period. If the
  /// [AlarmService] or [AlarmListener] is garbage collected, callbacks will not be triggered.
  ///
  /// ## Parameters
  ///
  /// - [listener]: The [AlarmListener] that receives alarm event notifications.
  factory AlarmService(final AlarmListener listener) {
    return AlarmService._create(listener);
  }

  @internal
  AlarmService.init(super.id);
  dynamic get _pointerId => super.pointerId;

  /// Updates the alarm listener for this service.
  ///
  /// The listener can be changed at any time to dynamically reconfigure which callbacks
  /// receive alarm event notifications. Only one listener is active per [AlarmService] instance.
  ///
  /// ## Parameters
  ///
  /// - [listener]: The new [AlarmListener] to receive alarm events.
  set alarmListener(final AlarmListener listener) {
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    objectMethod(
      _pointerId,
      'AlarmService',
      'setAlarmListener',
      args: listener.id,
    );
  }

  /// Distance threshold in meters for triggering landmark and overlay item alarms.
  ///
  /// Alarms are triggered when the device approaches within this distance of a monitored
  /// landmark or overlay item. The default threshold depends on the SDK configuration.
  ///
  /// Use [landmarkAlarms] and [overlayItemAlarms] for retrieving active alarms or check the
  /// values provided in the [AlarmListener] callbacks.
  ///
  /// ## Returns
  ///
  /// - `double`: Distance in meters.
  double get alarmDistance {
    final OperationResult result = objectMethod(
      _pointerId,
      'AlarmService',
      'getAlarmDistance',
    );

    return result['result'];
  }

  /// Sets the distance threshold in meters for triggering landmark and overlay item alarms.
  ///
  /// ## Parameters
  ///
  /// - [distance]: Distance in meters. Alarms will trigger when within this proximity to monitored items.
  set alarmDistance(final double distance) {
    objectMethod(
      _pointerId,
      'AlarmService',
      'setAlarmDistance',
      args: distance,
    );
  }

  /// Whether alarms are triggered when navigating without an active route.
  ///
  /// When `true`, landmark and overlay item alarms are triggered while freely exploring the map.
  /// When `false`, alarms are only triggered during active navigation or simulation on a route.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` if monitoring without route is enabled, otherwise `false`.
  ///
  /// ## Also see:
  ///
  /// - [NavigationService] - Manage active navigation sessions.
  bool get monitorWithoutRoute {
    final OperationResult result = objectMethod(
      _pointerId,
      'AlarmService',
      'getMonitorWithoutRoute',
    );

    return result['result'];
  }

  /// Enables or disables alarm triggering when navigating without an active route.
  ///
  /// ## Parameters
  ///
  /// - [value]: `true` to enable alarming without a route, `false` to disable.
  set monitorWithoutRoute(final bool value) {
    objectMethod(
      _pointerId,
      'AlarmService',
      'setMonitorWithoutRoute',
      args: value,
    );
  }

  /// Active overlay item alarms sorted by distance from the reference position.
  ///
  /// Returns the list of overlay items (such as safety cameras or social reports) that are
  /// approaching within the configured [alarmDistance]. When all alarms become inactive the
  /// list is empty ([OverlayItemAlarmsList.size] == 0).
  ///
  /// ## Returns
  ///
  /// - [OverlayItemAlarmsList]: List of active overlay item alarms.
  OverlayItemAlarmsList get overlayItemAlarms {
    final OperationResult result = objectMethod(
      _pointerId,
      'AlarmService',
      'getOverlayItemAlarms',
    );

    return OverlayItemAlarmsList.init(result['result']);
  }

  /// Overlay item alarms that have been passed over.
  ///
  /// Returns the list of overlay items that were recently passed by the device. Items in
  /// this list do not have a predefined sort order. To identify the most recently passed item,
  /// compare with previous snapshots of this list.
  ///
  /// ## Returns
  ///
  /// - [OverlayItemAlarmsList]: List of passed-over overlay item alarms.
  OverlayItemAlarmsList get overlayItemAlarmsPassedOver {
    final OperationResult result = objectMethod(
      _pointerId,
      'AlarmService',
      'getOverlayItemAlarmsPassedOver',
    );

    return OverlayItemAlarmsList.init(result['result']);
  }

  /// Active landmark alarms sorted by distance from the reference position.
  ///
  /// Returns the list of landmarks approaching within the configured [alarmDistance]. When
  /// all alarms become inactive the list is empty ([LandmarkAlarmsList.size] == 0).
  ///
  /// ## Returns
  ///
  /// - [LandmarkAlarmsList]: List of active landmark alarms.
  LandmarkAlarmsList get landmarkAlarms {
    final OperationResult result = objectMethod(
      _pointerId,
      'AlarmService',
      'getLandmarkAlarms',
    );

    return LandmarkAlarmsList.init(result['result']);
  }

  /// Landmark alarms that have been passed over.
  ///
  /// Returns the list of landmarks that were recently passed by the device. Items in this
  /// list do not have a predefined sort order. To identify the most recently passed landmark,
  /// compare with previous snapshots of this list.
  ///
  /// ## Returns
  ///
  /// - [LandmarkAlarmsList]: List of passed-over landmark alarms.
  LandmarkAlarmsList get landmarkAlarmsPassedOver {
    final OperationResult result = objectMethod(
      _pointerId,
      'AlarmService',
      'getLandmarkAlarmsPassedOver',
    );

    return LandmarkAlarmsList.init(result['result']);
  }

  /// Sets the overspeed threshold for triggering high-speed alarms.
  ///
  /// The [AlarmListener.onHighSpeed] callback is triggered when the current speed exceeds the
  /// road speed limit by at least the configured threshold. Thresholds can be configured
  /// separately for city areas (lower speed limit zones) and non-city areas.
  ///
  /// ## Parameters
  ///
  /// - [threshold]: Overspeed threshold in meters per second.
  /// - [insideCityArea]: `true` to configure the threshold for city areas, `false` for non-city areas.
  ///
  /// ## Also see:
  ///
  /// - [AlarmListener.registerOnHighSpeed] - Register for high-speed alarm callbacks.
  /// - [GemImprovedPosition] - Provides speed and road speed limit information.
  void setOverSpeedThreshold({
    required final double threshold,
    required final bool insideCityArea,
  }) {
    objectMethod(
      _pointerId,
      'AlarmService',
      'setOverSpeedThreshold',
      args: <String, Object>{
        'threshold': threshold,
        'insideCityArea': insideCityArea,
      },
    );
  }

  /// Gets the configured overspeed threshold for high-speed alarms.
  ///
  /// ## Parameters
  ///
  /// - [insideCityArea]: `true` to retrieve the city area threshold, `false` for non-city.
  ///
  /// ## Returns
  ///
  /// - `double`: Overspeed threshold in meters per second.
  double getOverSpeedThreshold(final bool insideCityArea) {
    final OperationResult result = objectMethod(
      _pointerId,
      'AlarmService',
      'getOverSpeedThreshold',
      args: insideCityArea,
    );

    return result['result'];
  }

  /// Current reference position used for alarm calculations.
  ///
  /// During navigation or simulation this returns the position along the route. Otherwise
  /// it returns the device's live position. This position serves as the origin for distance
  /// calculations to landmarks and overlay items.
  ///
  /// ## Returns
  ///
  /// - [GemPosition]?: The current reference position, or `null` if unavailable.
  ///
  /// ## Also see:
  ///
  /// - [PositionService] - For obtaining the device's position.
  /// - [trackedPositionSource] - Data source used for tracking the reference position.
  GemPosition? get referencePosition {
    final OperationResult retVal = objectMethod(
      _pointerId,
      'AlarmService',
      'getReferencePosition',
      args: DataType.position.id,
    );
    final GemError gemApiError = GemErrorExtension.fromCode(
      retVal['gemApiError'],
    );

    if (gemApiError != GemError.success) {
      return null;
    }

    final dynamic res = retVal['result'];
    if (res != null) {
      return GemPositionImpl.fromJson(res);
    }
    return null;
  }

  /// Collection of landmark stores to monitor for proximity alarms.
  ///
  /// Add [LandmarkStore] instances to this collection to enable proximity alarms for the
  /// landmarks they contain. Multiple stores can be monitored simultaneously.
  ///
  /// ## Returns
  ///
  /// - [LandmarkStoreCollection]: The collection managing monitored landmark stores.
  LandmarkStoreCollection get landmarks {
    final OperationResult result = objectMethod(
      _pointerId,
      'AlarmService',
      'lmks',
    );

    return LandmarkStoreCollection.init(result['result'], -1);
  }

  /// Collection of overlays to monitor for proximity alarms.
  ///
  /// Add overlay IDs (such as [CommonOverlayId.socialReports] or [CommonOverlayId.safety])
  /// to this collection to enable proximity alarms for overlay items. Overlay categories
  /// can also be added individually for finer control.
  ///
  /// A [GemMap] must be active for overlay alarms to function correctly. Also, a
  /// map style containing the specified overlays must be loaded.
  ///
  /// ## Returns
  ///
  /// - [OverlayMutableCollection]: The collection managing monitored overlays.
  OverlayMutableCollection get overlays {
    final OperationResult result = objectMethod(
      _pointerId,
      'AlarmService',
      'overlays',
    );

    return OverlayMutableCollection.init(result['result']);
  }

  /// Adds a geographic area to monitor for boundary crossing events.
  ///
  /// The [AlarmListener.registerOnBoundaryCrossed] callback is triggered when the device enters
  /// or exits the monitored area. Multiple areas can be monitored simultaneously.
  ///
  /// ## Parameters
  ///
  /// - [area]: The [GeographicArea] to monitor (rectangle, circle or polygon).
  /// - [id]: Optional unique identifier for the area. Used to identify which area was crossed in callbacks.
  ///
  /// ## See also:
  ///
  /// - [AlarmListener.registerOnBoundaryCrossed] - Register for boundary crossing callbacks.
  /// - [unmonitorArea] - Remove a geographic area from monitoring.
  void monitorArea(final GeographicArea area, {final String id = ''}) {
    objectMethod(
      _pointerId,
      'AlarmService',
      'monitorArea',
      args: <String, dynamic>{'area': area, 'id': id},
    );
  }

  /// Removes a geographic area from monitoring.
  ///
  /// Pass the same [GeographicArea] instance provided to [monitorArea] to stop monitoring
  /// that area. Boundary crossing events will no longer be triggered for this area.
  ///
  /// ## Parameters
  ///
  /// - [area]: The [GeographicArea] to stop monitoring.
  ///
  /// ## See also:
  ///
  /// - [monitorArea] - Add a geographic area to monitor.
  /// - [AlarmListener.registerOnBoundaryCrossed] - Register for boundary crossing callbacks.
  void unmonitorArea(final GeographicArea area) {
    objectMethod(
      _pointerId,
      'AlarmService',
      'unmonitorArea',
      args: area.toJson(),
    );
  }

  /// Removes multiple geographic areas from monitoring by their IDs.
  ///
  /// ## Parameters
  ///
  /// - [ids]: List of area identifier strings originally provided to [monitorArea].
  ///
  /// ## See also:
  ///
  /// - [monitorArea] - Add a geographic area to monitor.
  void unmonitorAreasByIds(List<String> ids) {
    objectMethod(_pointerId, 'AlarmService', 'unmonitorAreasByIds', args: ids);
  }

  /// Removes all monitored geographic areas.
  ///
  /// Boundary crossing events will no longer be triggered for any previously monitored areas.
  ///
  /// ## See also:
  ///
  /// - [monitorArea] - Add a geographic area to monitor.
  void unmonitorAllAreas() {
    objectMethod(_pointerId, 'AlarmService', 'unmonitorAllAreas');
  }

  /// All currently monitored geographic areas.
  ///
  /// ## Returns
  ///
  /// - `List<AlarmMonitoredArea>`: List of monitored areas with their [GeographicArea] definitions and identifiers.
  ///
  /// ## See also:
  ///
  /// - [monitorArea] - Add a geographic area to monitor.
  /// - [unmonitorArea] - Remove a geographic area from monitoring.
  List<AlarmMonitoredArea> get monitoredAreas {
    final OperationResult result = objectMethod(
      _pointerId,
      'AlarmService',
      'getMonitoredAreas',
    );

    final List<dynamic> res = result['result'];
    return res
        .map((final dynamic item) => AlarmMonitoredArea.fromJson(item))
        .toList();
  }

  /// Monitored areas containing the current reference position.
  ///
  /// For this list to be non-empty the device must be inside at least one monitored area
  /// and must move or change position within that area.
  ///
  /// ## Returns
  ///
  /// - `List<AlarmMonitoredArea>`: List of areas the device is currently inside.
  ///
  /// ## See also:
  ///
  /// - [monitorArea] - Add a geographic area to monitor.
  /// - [unmonitorArea] - Remove a geographic area from monitoring.
  List<AlarmMonitoredArea> get insideAreas {
    final OperationResult result = objectMethod(
      _pointerId,
      'AlarmService',
      'getInsideAreas',
    );

    final List<dynamic> res = result['result'];
    return res
        .map((final dynamic item) => AlarmMonitoredArea.fromJson(item))
        .toList();
  }

  /// Monitored areas not containing the current reference position.
  ///
  /// ## Returns
  ///
  /// - `List<AlarmMonitoredArea>`: List of areas the device is currently outside.
  ///
  /// ## See also:
  ///
  /// - [monitorArea] - Add a geographic area to monitor.
  /// - [unmonitorArea] - Remove a geographic area from monitoring.
  List<AlarmMonitoredArea> get outsideAreas {
    final OperationResult result = objectMethod(
      _pointerId,
      'AlarmService',
      'getOutsideAreas',
    );

    final List<dynamic> res = result['result'];
    return res
        .map((final dynamic item) => AlarmMonitoredArea.fromJson(item))
        .toList();
  }

  /// Data source used for tracking the reference position.
  ///
  /// ## Returns
  ///
  /// - [DataSource]: The active data source providing position updates.
  ///
  /// ## See also:
  ///
  /// - [referencePosition] - Current reference position used for alarm calculations.
  /// - [PositionService] - For obtaining the device's position.
  DataSource get trackedPositionSource {
    final OperationResult result = objectMethod(
      _pointerId,
      'AlarmService',
      'getTrackedPositionSource',
    );

    return DataSource.init(result['result']);
  }

  /// Enables the safety camera overlay for display and alarm monitoring.
  ///
  /// Requires the safety camera overlay to be available in the current map style.
  /// Also needs a [GemMap] to be active for proper functioning.
  ///
  /// ## Returns
  ///
  /// - [GemError.success]: Overlay enabled successfully.
  /// - [GemError.notFound]: Overlay not found in the current map style.
  static GemError enableSafetyCamera() {
    return OverlayService.enableOverlay(CommonOverlayId.safety.id);
  }

  /// Disables the safety camera overlay.
  ///
  ///
  /// ## Returns
  ///
  /// - [GemError.success]: Overlay disabled successfully.
  /// - [GemError.notFound]: Overlay not found in the current map style.
  static GemError disableSafetyCamera() {
    return OverlayService.disableOverlay(CommonOverlayId.safety.id);
  }

  /// Checks whether the safety camera overlay is enabled.
  ///
  /// Requires the safety camera overlay to be available in the current map style.
  /// Also needs a [GemMap] to be active for proper functioning.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` if the overlay is enabled, otherwise `false`.
  static bool get isSafetyCameraEnabled {
    return OverlayService.isOverlayEnabled(CommonOverlayId.safety.id);
  }

  /// Enables the social reports overlay for display and alarm monitoring.
  ///
  /// Requires the safety camera overlay to be available in the current map style.
  /// Also needs a [GemMap] to be active for proper functioning.
  ///
  /// ## Returns
  ///
  /// - [GemError.success]: Overlay enabled successfully.
  /// - [GemError.notFound]: Overlay not found in the current map style.
  static GemError enableSocialReports() {
    return OverlayService.enableOverlay(CommonOverlayId.socialReports.id);
  }

  /// Disables the social reports overlay.
  ///
  /// ## Returns
  ///
  /// - [GemError.success]: Overlay disabled successfully.
  /// - [GemError.notFound]: Overlay not found in the current map style.
  static GemError disableSocialReports() {
    return OverlayService.disableOverlay(CommonOverlayId.socialReports.id);
  }

  /// Checks whether the social reports overlay is enabled.
  ///
  /// Requires the safety camera overlay to be available in the current map style.
  /// Also needs a [GemMap] to be active for proper functioning.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` if the overlay is enabled, otherwise `false`.
  static bool get isSocialReportsEnabled {
    return OverlayService.isOverlayEnabled(CommonOverlayId.socialReports.id);
  }

  /// Enables the social reports overlay for a specific category.
  ///
  /// Requires the safety camera overlay to be available in the current map style.
  /// Also needs a [GemMap] to be active for proper functioning.
  ///
  /// ## Parameters
  ///
  /// - [categoryId]: The overlay category identifier.
  ///
  /// ## Returns
  ///
  /// - [GemError.success]: Category enabled successfully.
  /// - [GemError.notFound]: Overlay or category not found.
  static GemError enableSocialReportsWithCategory(int categoryId) {
    return OverlayService.enableOverlay(
      CommonOverlayId.socialReports.id,
      categUid: categoryId,
    );
  }

  /// Disables the social reports overlay for a specific category.
  ///
  /// ## Parameters
  ///
  /// - [categoryId]: The overlay category identifier.
  ///
  /// ## Returns
  ///
  /// - [GemError.success]: Category disabled successfully.
  /// - [GemError.notFound]: Overlay or category not found.
  static GemError disableSocialReportsWithCategory(int categoryId) {
    return OverlayService.disableOverlay(
      CommonOverlayId.socialReports.id,
      categUid: categoryId,
    );
  }

  /// Checks whether the social reports overlay is enabled for a specific category.
  ///
  /// Requires the safety camera overlay to be available in the current map style.
  /// Also needs a [GemMap] to be active for proper functioning.
  ///
  /// ## Parameters
  ///
  /// - [categoryId]: The overlay category identifier.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` if the category is enabled, otherwise `false`.
  static bool isSocialReportsEnabledWithCategory(int categoryId) {
    return OverlayService.isOverlayEnabled(
      CommonOverlayId.socialReports.id,
      categUid: categoryId,
    );
  }

  static AlarmService _create(final AlarmListener listener) {
    GemKitPlatform.instance.registerEventHandler(listener.id, listener);

    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'AlarmService',
        'args': listener.id,
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final AlarmService retVal = AlarmService.init(decodedVal['result']);
    return retVal;
  }
}
