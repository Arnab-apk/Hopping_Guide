// SPDX-FileCopyrightText: 2024-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:magiclane_maps_flutter/src/markers/marker_collection.dart';
import 'package:magiclane_maps_flutter/weather.dart';

/// Provides debugging utilities for memory monitoring, logging, and SDK configuration.
///
/// The [Debug] class offers static methods for monitoring memory usage, controlling log output,
/// configuring routing and navigation behavior, and retrieving SDK diagnostics. Key features include:
///
/// - Memory monitoring: Track used, free, and maximum memory consumption
/// - Logging system: Send logs to Magic Lane servers for crash analysis
/// - Debug flags: Control console output for object creation, method calls, and listeners
/// - Routing/Navigation modifiers: Alter algorithm behavior for testing
/// - Storage information: Monitor mount points and disk space
///
/// ## See also:
///
/// - [GemLoggingLevel] - For console log verbosity levels.
/// - [GemDumpSdkLevel] - For crash report log verbosity levels.
///
/// {@category Settings}
abstract class Debug {
  /// Writes a log message to the SDK logging system for crash analysis.
  ///
  /// Logs are automatically written to a file accessible via [sdkLogDumpPath] and sent to
  /// Magic Lane servers in case of crashes. Use [setSdkDumpLevel] to control the verbosity
  /// of logs included in crash reports.
  ///
  /// ## Parameters
  ///
  /// - [level]: Severity level of the log message.
  /// - [module]: Module name where the log originates. Defaults to 'Application'.
  /// - [function]: Function name where the log is issued.
  /// - [file]: Source file name where the log is issued.
  /// - [line]: Line number in the source file. Defaults to 0.
  /// - [message]: Log message content.
  ///
  /// ## See also:
  ///
  /// - [sdkLogDumpPath] - For retrieving the log file path.
  /// - [setSdkDumpLevel] - For configuring log verbosity.
  /// - [GemDumpSdkLevel] - For available log severity levels.
  static void log({
    required GemDumpSdkLevel level,
    String module = 'Application',
    String function = '',
    String file = '',
    int line = 0,
    required String message,
  }) {
    staticMethod(
      'Debug',
      'log',
      args: <String, Object>{
        'level': level.id,
        'pszModule': module,
        'pszFunction': function,
        'pszFile': file,
        'line': line,
        'str': message,
      },
      logPrivacyLevel: LogPrivacyLevel.noLog,
    );
  }

  /// Returns the memory currently used by the SDK engine.
  ///
  /// Useful for monitoring memory consumption and detecting potential memory leaks
  /// during development.
  ///
  /// ## Returns
  ///
  /// - The memory used by the engine in bytes.
  ///
  /// ## See also:
  ///
  /// - [getTotalMemory] - For total system memory.
  /// - [getFreeMemory] - For available system memory.
  /// - [getMaxUsedMemory] - For peak memory usage.
  @Deprecated('Use usedMemory getter instead')
  static int getUsedMemory() {
    final OperationResult resultString = staticMethod('Debug', 'getUsedMemory');
    return resultString['result'];
  }

  /// Returns the memory currently used by the SDK engine.
  ///
  /// Useful for monitoring memory consumption and detecting potential memory leaks
  /// during development.
  ///
  /// ## Returns
  ///
  /// - The memory used by the engine in bytes.
  ///
  /// ## See also:
  ///
  /// - [totalMemory] - For total system memory.
  /// - [freeMemory] - For available system memory.
  /// - [maxUsedMemory] - For peak memory usage.
  static int get usedMemory {
    final OperationResult resultString = staticMethod('Debug', 'getUsedMemory');
    return resultString['result'];
  }

  /// Returns the total system memory available to the device.
  ///
  /// ## Returns
  ///
  /// - The total system memory in bytes.
  ///
  /// ## See also:
  ///
  /// - [getUsedMemory] - For SDK memory usage.
  /// - [getFreeMemory] - For available memory.
  @Deprecated('Use totalMemory getter instead')
  static int getTotalMemory() {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getTotalMemory',
    );
    return resultString['result'];
  }

  /// Returns the total system memory available to the device.
  ///
  /// ## Returns
  ///
  /// - The total system memory in bytes.
  ///
  /// ## See also:
  ///
  /// - [usedMemory] - For SDK memory usage.
  /// - [freeMemory] - For available memory.
  static int get totalMemory {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getTotalMemory',
    );
    return resultString['result'];
  }

  /// Returns the free system memory including swap and kernel cache.
  ///
  /// ## Returns
  ///
  /// - The free system memory in bytes.
  ///
  /// ## See also:
  ///
  /// - [totalMemory] - For total system memory.
  /// - [getUsedMemory] - For SDK memory usage.
  @Deprecated('Use freeMemory getter instead')
  static int getFreeMemory() {
    final OperationResult resultString = staticMethod('Debug', 'getFreeMemory');
    return resultString['result'];
  }

  /// Returns the free system memory including swap and kernel cache.
  ///
  /// ## Returns
  ///
  /// - The free system memory in bytes.
  ///
  /// ## See also:
  ///
  /// - [totalMemory] - For total system memory.
  /// - [usedMemory] - For SDK memory usage.
  static int get freeMemory {
    final OperationResult resultString = staticMethod('Debug', 'getFreeMemory');
    return resultString['result'];
  }

  /// Returns the maximum memory used by the SDK engine since initialization.
  ///
  /// Useful for profiling and identifying peak memory consumption during testing.
  ///
  /// ## Returns
  ///
  /// - The maximum memory used by the engine in bytes.
  ///
  /// ## See also:
  ///
  /// - [usedMemory] - For current memory usage.
  @Deprecated('Use maxUsedMemory getter instead')
  static int getMaxUsedMemory() {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getMaxUsedMemory',
    );
    return resultString['result'];
  }

  /// Returns the maximum memory used by the SDK engine since initialization.
  ///
  /// Useful for profiling and identifying peak memory consumption during testing.
  ///
  /// ## Returns
  ///
  /// - The maximum memory used by the engine in bytes.
  ///
  /// ## See also:
  ///
  /// - [usedMemory] - For current memory usage.
  static int get maxUsedMemory {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getMaxUsedMemory',
    );
    return resultString['result'];
  }

  /// Returns the Android version of the device.
  ///
  /// Returns -1 if the platform is not Android.
  ///
  /// ## Returns
  ///
  /// - The android version as an integer.
  @Deprecated('Use androidVersion getter instead')
  static int getAndroidVersion() {
    return GemKitPlatform.instance.androidVersion;
  }

  /// Returns the Android version of the device.
  ///
  /// Returns -1 if the platform is not Android.
  ///
  /// ## Returns
  ///
  /// - The android version as an integer.
  static int get androidVersion {
    return GemKitPlatform.instance.androidVersion;
  }

  /// Get app I/O info
  ///
  /// ## Returns
  ///
  /// - A list of [MountInfo] structures, each providing details about a different storage mount point used by the application.
  @Deprecated('Use appIOInfo getter instead')
  static List<MountInfo> getAppIOInfo() {
    final OperationResult resultString = staticMethod('Debug', 'getAppIOInfo');
    final List<dynamic> retval = resultString['result'];
    return retval.map((dynamic e) => MountInfo.fromJson(e)).toList();
  }

  /// Get app I/O info
  ///
  /// ## Returns
  ///
  /// - A list of [MountInfo] structures, each providing details about a different storage mount point used by the application.
  static List<MountInfo> get appIOInfo {
    final OperationResult resultString = staticMethod('Debug', 'getAppIOInfo');
    final List<dynamic> retval = resultString['result'];
    return retval.map((dynamic e) => MountInfo.fromJson(e)).toList();
  }

  /// Get default URLs for the specified service.
  ///
  /// ## Parameters
  ///
  /// - [svc] - Service identifier for which URLs are requested.
  ///
  /// ## Returns
  ///
  /// - A list of URLs configured for the specified service.
  static List<String> getDefUrls(ServiceGroupType svc) {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getDefUrls',
      args: svc.id,
    );
    final List<dynamic> retval = resultString['result'];
    return List<String>.from(retval);
  }

  /// Get URLs for the style builder.
  ///
  /// ## Returns
  ///
  /// - A list of URLs configured for the style builder.
  @Deprecated('Use styleBuilderUrls getter instead')
  static List<String> getStyleBuilderUrls() {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getStyleBuilderUrls',
    );
    final List<dynamic> retval = resultString['result'];
    return List<String>.from(retval);
  }

  /// Get URLs for the style builder.
  ///
  /// ## Returns
  ///
  /// - A list of URLs configured for the style builder.
  static List<String> get styleBuilderUrls {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getStyleBuilderUrls',
    );
    final List<dynamic> retval = resultString['result'];
    return List<String>.from(retval);
  }

  /// Get default URLs for the specified service.
  ///
  /// Can be used to override default service URLs.
  /// Useful for testing and using custom data.
  ///
  /// Do not unless instructed by Magic Lane support.
  ///
  /// ## Parameters
  ///
  /// - [svc] - Service identifier for which the URL is to be set.
  /// - [url] - The URL to set for the service.
  static void setCustomUrl(int svc, String url) {
    staticMethod(
      'Debug',
      'setCustomUrl',
      args: <String, Object>{'first': svc, 'second': url},
    );
  }

  /// Retrieve connections for a given route as markers.
  ///
  /// Used mainly for debugging and testing purposes.
  ///
  /// ## Parameters
  ///
  /// - [route]: The route for which connections are to be retrieved.
  ///
  /// ## Returns
  ///
  /// - A collection of markers representing the connections of the route.
  static MarkerCollection? getRouteConnections(Route route) {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getRouteConnections',
      args: route.pointerId,
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return MarkerCollection.init(resultString['result'], 0);
  }

  /// Set modifiers for navigation locations.
  ///
  /// ## Parameters
  ///
  /// - [modifiers]: The modifiers to be used within the navigation.  See [NavigationModifiers] for details.
  static void setNavigationModifiers(Set<NavigationModifiers> modifiers) {
    int packed = 0;
    for (final NavigationModifiers modifier in modifiers) {
      packed |= modifier.id;
    }

    staticMethod('Debug', 'setNavigationModifiers', args: packed);
  }

  /// Retrieve the current navigation location modifiers.
  ///
  /// ## Returns
  ///
  /// - Current set of navigation location modifiers. See [NavigationModifiers] for details.
  @Deprecated('Use navigationModifiers getter instead')
  static Set<NavigationModifiers> getNavigationModifiers() {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getNavigationModifiers',
    );

    final int packed = resultString['result'];
    return NavigationModifiers.values
        .where((NavigationModifiers modifier) => (packed & modifier.id) != 0)
        .toSet();
  }

  /// Retrieve the current navigation location modifiers.
  ///
  /// ## Returns
  ///
  /// - Current set of navigation location modifiers. See [NavigationModifiers] for details.
  static Set<NavigationModifiers> get navigationModifiers {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getNavigationModifiers',
    );

    final int packed = resultString['result'];
    return NavigationModifiers.values
        .where((NavigationModifiers modifier) => (packed & modifier.id) != 0)
        .toSet();
  }

  /// Initiate a check for a better route.
  ///
  /// ## Returns
  ///
  /// - True if a better route is found, false otherwise.
  ///
  /// ## Also see:
  ///
  /// - [NavigationService] - Service managing navigation sessions, including route updates.
  static bool checkBetterRoute() {
    final OperationResult resultString = staticMethod(
      'Debug',
      'checkBetterRoute',
    );

    return resultString['result'] != 0;
  }

  /// Initiate a check for traffic conditions along all routes.
  ///
  /// ## Returns
  ///
  /// - True if traffic conditions suggest a change in the route, false otherwise.
  ///
  /// ## Also see:
  ///
  /// - [NavigationService] - Service managing navigation sessions, including route updates.
  static bool checkTrafficAlongRoutes() {
    final OperationResult resultString = staticMethod(
      'Debug',
      'checkTrafficAlongRoutes',
    );

    return resultString['result'] != 0;
  }

  /// Get the remaining time until the next check for a better route.
  ///
  /// ## Returns
  ///
  /// - Time in seconds until the next check for a better route.
  ///
  /// ## Also see:
  ///
  /// - [NavigationService] - Service managing navigation sessions, including route updates.
  /// - [checkBetterRoute] - Method to initiate a check for a better route.
  @Deprecated('Use timeToBetterRoute getter instead')
  static int timeToBetterRouteSec() {
    final OperationResult resultString = staticMethod(
      'Debug',
      'timeToBetterRouteSec',
    );
    return resultString['result'];
  }

  /// Get the remaining time in seconds until the next check for a better route.
  ///
  /// ## Returns
  ///
  /// - Time in seconds until the next check for a better route.
  ///
  /// ## Also see:
  ///
  /// - [NavigationService] - Service managing navigation sessions, including route updates.
  /// - [checkBetterRoute] - Method to initiate a check for a better route.
  static int get timeToBetterRoute {
    final OperationResult resultString = staticMethod(
      'Debug',
      'timeToBetterRouteSec',
    );
    return resultString['result'];
  }

  /// Get the remaining time until the next check for traffic conditions along all routes.
  ///
  /// ## Returns
  ///
  /// - Time in seconds until the next traffic check along all routes.
  ///
  /// ## Also see:
  ///
  /// - [NavigationService] - Service managing navigation sessions, including route updates.
  /// - [checkTrafficAlongRoutes] - Method to initiate a traffic check along all routes.
  @Deprecated('Use timeToCheckTrafficAlongRoutes getter instead')
  static int timeToCheckTrafficAlongRoutesSec() {
    final OperationResult resultString = staticMethod(
      'Debug',
      'timeToCheckTrafficAlongRoutesSec',
    );
    return resultString['result'];
  }

  /// Get the remaining time in seconds until the next check for traffic conditions along all routes.
  ///
  /// ## Returns
  ///
  /// - Time in seconds until the next traffic check along all routes.
  ///
  /// ## Also see:
  ///
  /// - [NavigationService] - Service managing navigation sessions, including route updates.
  /// - [checkTrafficAlongRoutes] - Method to initiate a traffic check along all routes.
  static int get timeToCheckTrafficAlongRoutes {
    final OperationResult resultString = staticMethod(
      'Debug',
      'timeToCheckTrafficAlongRoutesSec',
    );
    return resultString['result'];
  }

  /// Perform a many-to-many pedestrian routing calculation.
  ///
  /// The API user is advised to use [RoutingService] for routing calculations.
  ///
  /// ## Parameters:
  ///
  /// - [start]: Coordinates of the start point.
  /// - [end]: Coordinates of the end point.
  ///
  /// ## Also see:
  ///
  /// - [RoutingService] - Service managing routing calculations. Recommended for API users.
  static void manyToManyPedestrianCalculation(
    Coordinates start,
    Coordinates end,
  ) {
    staticMethod(
      'Debug',
      'manyToManyPedestrianCalculation',
      args: <String, Coordinates>{'first': start, 'second': end},
    );
  }

  /// Perform a one-to-one pedestrian routing calculation.
  ///
  /// The API user is advised to use [RoutingService] for routing calculations.
  ///
  /// ## Parameters:
  ///
  /// - [start]: Coordinates of the start point.
  /// - [end]: Coordinates of the end point.
  ///
  /// ## Also see:
  ///
  /// - [RoutingService] - Service managing routing calculations. Recommended for API users.
  static void oneToOnePedestrianCalculation(
    Coordinates start,
    Coordinates end,
  ) {
    staticMethod(
      'Debug',
      'oneToOnePedestrianCalculation',
      args: <String, Coordinates>{'first': start, 'second': end},
    );
  }

  /// Retrieve a list of service IDs used within the application.
  ///
  /// ## Returns
  ///
  /// - A list of integer IDs representing the services.
  @Deprecated('Use servicesIds getter instead')
  static List<int> getServicesIds() {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getServicesIds',
    );

    return List<int>.from(resultString['result']);
  }

  /// Retrieve a list of service IDs used within the application.
  ///
  /// ## Returns
  ///
  /// - A list of integer IDs representing the services.
  static List<int> get servicesIds {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getServicesIds',
    );

    return List<int>.from(resultString['result']);
  }

  /// Retrieve the name of a service given its ID.
  ///
  /// ## Parameters:
  ///
  /// - [id] The ID of the service.
  ///
  /// ## Returns
  ///
  /// - The name of the service corresponding to the provided ID.
  static String getServiceName(int id) {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getServiceName',
      args: id,
    );

    return resultString['result'];
  }

  /// Retrieve all weather conditions parsed from all available resources.
  ///
  /// ## Returns
  ///
  /// - A [LocationForecast] object containing all the parsed weather conditions.
  @Deprecated('Use allWeatherConditions getter instead')
  static LocationForecast getAllWeatherConditions() {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getAllWeatherConditions',
    );

    return LocationForecast.fromJson(resultString['result']);
  }

  /// Retrieve all weather conditions parsed from all available resources.
  ///
  /// ## Returns
  ///
  /// - A [LocationForecast] object containing all the parsed weather conditions.
  static LocationForecast get allWeatherConditions {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getAllWeatherConditions',
    );

    return LocationForecast.fromJson(resultString['result']);
  }

  /// Refresh the content store by loading external changes from disk.
  ///
  /// May be unstable and is not recommended for general use.
  static void refreshContentStore() {
    staticMethod('Debug', 'refreshContentStore');
  }

  /// Refresh the content store by loading external changes from disk.
  static void cleanupSocialCache() {
    staticMethod('Debug', 'cleanupSocialCache');
  }

  /// Update maps to the latest version synchronously.
  ///
  /// The API user is advised to use [ContentUpdater] for map updates.
  ///
  /// ## Parameters:
  ///
  /// - [force]: If true, allows partial updates due to space constraints.
  ///
  /// ## Returns
  ///
  /// - An error code indicating the success or failure of the operation. See [GemError] for details.
  static GemError updateMaps(bool force) {
    final OperationResult resultString = staticMethod(
      'Debug',
      'updateMaps',
      args: force,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Check if the current thread is the main thread.
  ///
  /// ## Returns
  ///
  /// - True if the current thread is the main thread, false otherwise.
  @Deprecated('Use mainThread getter instead')
  static bool isMainThread() {
    final OperationResult resultString = staticMethod('Debug', 'isMainThread');
    return resultString['result'];
  }

  /// Check if the current thread is the main thread.
  ///
  /// ## Returns
  ///
  /// - True if the current thread is the main thread, false otherwise.
  static bool get mainThread {
    final OperationResult resultString = staticMethod('Debug', 'isMainThread');
    return resultString['result'];
  }

  /// Replay a previously recorded stream activity log.
  ///
  /// API users are advised to use [DataSource.createLogDataSource] for log replay.
  ///
  /// ## Parameters:
  ///
  /// - [path] The path to the log file to be replayed.
  ///
  /// ## Returns
  ///
  /// - An error code indicating the success or failure of the operation. See [GemError] for details.
  ///
  /// ## See also:
  ///
  /// - [DataSource.createLogDataSource] - Create a data source from a recorded log for replay.
  /// - [Recorder.create] - Create a recorder instance to record new logs.
  static GemError replayStreamActivityLog(String path) {
    final OperationResult resultString = staticMethod(
      'Debug',
      'replayStreamActivityLog',
      args: path,
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Retrieve the maximum zoom ranges allowed on a MapView
  ///
  /// ## Returns
  ///
  /// - The maximum zoom ranges allowed on a MapView.
  @Deprecated('Use mapViewMaxZoomRanges getter instead')
  static int getMapViewMaxZoomRanges() {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getMapViewMaxZoomRanges',
    );
    return resultString['result'];
  }

  /// Retrieve the maximum zoom ranges allowed on a MapView
  ///
  /// ## Returns
  ///
  /// - The maximum zoom ranges allowed on a MapView.
  static int get mapViewMaxZoomRanges {
    final OperationResult resultString = staticMethod(
      'Debug',
      'getMapViewMaxZoomRanges',
    );
    return resultString['result'];
  }

  /// Check if raw position tracker is enabled
  ///
  /// ## Returns
  ///
  /// - True if raw positioning tracker is enabled, false otherwise.
  @Deprecated('Use rawPositionTrackerEnabled getter instead')
  static bool isRawPositionTrackerEnabled() {
    final OperationResult resultString = staticMethod(
      'Debug',
      'isRawPositionTrackerEnabled',
    );
    return resultString['result'];
  }

  /// Check if raw position tracker is enabled
  ///
  /// ## Returns
  ///
  /// - True if raw positioning tracker is enabled, false otherwise.
  static bool get rawPositionTrackerEnabled {
    final OperationResult resultString = staticMethod(
      'Debug',
      'isRawPositionTrackerEnabled',
    );
    return resultString['result'];
  }

  /// If enabled prints create object calls JSONs to the console
  ///
  /// Used for debugging purposes.
  static bool logCreateObject = false;

  /// If enabled prints method object calls JSONs to the console
  ///
  /// Used for debugging purposes.
  static bool logCallObjectMethod = false;

  /// If enabled prints listener messages JSONs to the console
  ///
  /// Used for debugging purposes.
  static bool logListenerMethod = false;

  /// In enabled checks if an object is alive before calling a method on it.
  ///
  /// Used for debugging purposes.
  static bool isObjectAliveCheckEnabled = false;

  /// The number of native objects the SDK currently holds a strong reference to.
  ///
  /// Each tracked Dart wrapper maps to one live native handle. A count that
  /// grows steadily across repeated create/dispose cycles indicates handles
  /// that are neither disposed nor garbage-collected, i.e. a native leak.
  ///
  /// Returns 0 before the SDK is initialized, after it is released, and on web.
  ///
  /// Used for debugging and leak monitoring.
  static int get aliveObjectsCount => GemKitPlatform.instance.aliveObjectsCount;

  static Level _getLevel(GemLoggingLevel loggingLevel) {
    switch (loggingLevel) {
      case GemLoggingLevel.severe:
        return Level.SEVERE;
      case GemLoggingLevel.warning:
        return Level.WARNING;
      case GemLoggingLevel.info:
        return Level.INFO;
      case GemLoggingLevel.config:
        return Level.CONFIG;
      case GemLoggingLevel.fine:
        return Level.FINE;
      case GemLoggingLevel.finer:
        return Level.FINER;
      case GemLoggingLevel.finest:
        return Level.FINEST;
      case GemLoggingLevel.all:
        return Level.ALL;
      case GemLoggingLevel.off:
        return Level.OFF;
    }
  }

  static GemLoggingLevel _getGemLevel(Level level) {
    if (level == Level.SEVERE) {
      return GemLoggingLevel.severe;
    } else if (level == Level.WARNING) {
      return GemLoggingLevel.warning;
    } else if (level == Level.INFO) {
      return GemLoggingLevel.info;
    } else if (level == Level.CONFIG) {
      return GemLoggingLevel.config;
    } else if (level == Level.FINE) {
      return GemLoggingLevel.fine;
    } else if (level == Level.FINER) {
      return GemLoggingLevel.finer;
    } else if (level == Level.FINEST) {
      return GemLoggingLevel.finest;
    } else if (level == Level.ALL) {
      return GemLoggingLevel.all;
    } else if (level == Level.OFF) {
      return GemLoggingLevel.off;
    } else {
      return GemLoggingLevel.off;
    }
  }

  /// Sets the console logging level for SDK debug output.
  ///
  /// Controls verbosity of messages printed to the console during development. Higher
  /// levels produce more detailed output. This is separate from crash report logging
  /// configured via [setSdkDumpLevel].
  ///
  /// ## See also:
  ///
  /// - [logLevel] - For getting the current level.
  /// - [GemLoggingLevel] - For available logging levels.
  /// - [setSdkDumpLevel] - For crash report logging.
  static set logLevel(GemLoggingLevel loggingLevel) {
    Logger.root.level = _getLevel(loggingLevel);
  }

  /// Gets the current console logging level for SDK debug output.
  ///
  /// ## Returns
  ///
  /// - The current console logging level.
  ///
  /// ## See also:
  ///
  /// - [logLevel] - For setting the logging level.
  /// - [GemLoggingLevel] - For available logging levels.
  static GemLoggingLevel get logLevel {
    return _getGemLevel(Logger.root.level);
  }

  /// Sets the verbosity level for crash report logs sent to Magic Lane.
  ///
  /// On Android, all [GemDumpSdkLevel] values are supported. On iOS, only [GemDumpSdkLevel.silent]
  /// and [GemDumpSdkLevel.verbose] are supported—any value other than silent defaults to verbose.
  /// Logs are written to the file accessible via [sdkLogDumpPath].
  ///
  /// ## Parameters
  ///
  /// - [level]: Verbosity level for crash report logging.
  ///
  /// ## See also:
  ///
  /// - [sdkLogDumpPath] - For retrieving the log file path.
  /// - [log] - For writing custom log entries.
  /// - [GemDumpSdkLevel] - For available verbosity levels.
  static Future<void> setSdkDumpLevel(GemDumpSdkLevel level) async {
    await GemKitPlatform.instance
        .getChannel(mapId: -1)
        .invokeMethod(
          'setLogLevel',
          jsonEncode(<String, dynamic>{'level': level.id}),
        );
  }

  /// Retrieves the file path to the SDK crash report log.
  ///
  /// The log file contains detailed information about SDK operations and is automatically
  /// sent to Magic Lane servers in case of crashes. Custom entries can be added using [log],
  /// and verbosity is controlled via [setSdkDumpLevel].
  ///
  /// ## Returns
  ///
  /// - File path to the SDK dump log.
  ///
  /// ## See also:
  ///
  /// - [log] - For writing custom log entries.
  /// - [setSdkDumpLevel] - For configuring log verbosity.
  @Deprecated('Use sdkLogDumpPath getter instead')
  static Future<String> getSdkLogDumpPath() async {
    final String path = await GemKitPlatform.instance
        .getChannel(mapId: -1)
        .invokeMethod(
          'getLogPath',
          jsonEncode(<String, dynamic>{'dummyKey': 'dummyValue'}),
        );
    return path;
  }

  /// Retrieves the file path to the SDK crash report log.
  ///
  /// The log file contains detailed information about SDK operations and is automatically
  /// sent to Magic Lane servers in case of crashes. Custom entries can be added using [log],
  /// and verbosity is controlled via [setSdkDumpLevel].
  ///
  /// ## Returns
  ///
  /// - File path to the SDK dump log.
  ///
  /// ## See also:
  ///
  /// - [log] - For writing custom log entries.
  /// - [setSdkDumpLevel] - For configuring log verbosity.
  static Future<String> get sdkLogDumpPath async {
    final String path = await GemKitPlatform.instance
        .getChannel(mapId: -1)
        .invokeMethod(
          'getLogPath',
          jsonEncode(<String, dynamic>{'dummyKey': 'dummyValue'}),
        );
    return path;
  }
}
