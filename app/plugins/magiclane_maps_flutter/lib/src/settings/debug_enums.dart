// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Defines verbosity levels for crash report logs sent to Magic Lane servers.
///
/// These levels control how much detail is included in logs automatically sent to Magic Lane
/// in case of crashes. Lower levels (silent, fatal, error) minimize log traffic and exclude
/// private information. Higher levels (debug, verbose) provide detailed diagnostics but are
/// only available in debug SDK builds.
///
/// On Android, all levels are supported. On iOS, only [silent] and [verbose] are supported—
/// any other value defaults to [verbose].
///
/// ## See also:
///
/// - [Debug.setSdkDumpLevel] - For configuring the crash report log level.
/// - [Debug.log] - For writing custom log entries.
/// - [Debug.getSdkLogDumpPath] - For retrieving the log file path.
///
/// {@category Settings}
enum GemDumpSdkLevel {
  /// No logging - completely silent.
  silent,

  /// Fatal errors only - application cannot continue and will crash shortly.
  ///
  /// Low traffic level without private information.
  /// Example: "Can't find icon database", "Thread violation detected".
  fatal,

  /// Non-fatal errors - application can continue despite the error.
  ///
  /// Low traffic level without private information.
  /// Example: "Can't connect to offboard server, retrying in 30 seconds".
  error,

  /// Warnings about potentially harmful situations.
  ///
  /// Low traffic level without private information.
  /// Example: "Network is down, can't perform online search".
  warn,

  /// Informational messages about SDK operations.
  ///
  /// Low/moderate traffic level without private information (no device IMEI,
  /// positions, search strings, etc.).
  /// Example: "Download started", "Connected to offboard".
  info,

  /// Detailed debugging information for development.
  ///
  /// High/moderate traffic level. Only available in debug SDK builds—stripped
  /// in release builds.
  debug,

  /// Highly verbose logging for in-depth debugging.
  ///
  /// High traffic level with maximum detail. Only available in debug SDK builds—
  /// stripped in release builds.
  verbose,
}

/// @nodoc
extension GemDumpSdkLevelExtension on GemDumpSdkLevel {
  int get id {
    switch (this) {
      case GemDumpSdkLevel.silent:
        return 6;
      case GemDumpSdkLevel.fatal:
        return 5;
      case GemDumpSdkLevel.error:
        return 4;
      case GemDumpSdkLevel.warn:
        return 3;
      case GemDumpSdkLevel.info:
        return 2;
      case GemDumpSdkLevel.debug:
        return 1;
      case GemDumpSdkLevel.verbose:
        return 0;
    }
  }

  static GemDumpSdkLevel fromId(int id) {
    switch (id) {
      case 6:
        return GemDumpSdkLevel.silent;
      case 5:
        return GemDumpSdkLevel.fatal;
      case 4:
        return GemDumpSdkLevel.error;
      case 3:
        return GemDumpSdkLevel.warn;
      case 2:
        return GemDumpSdkLevel.info;
      case 1:
        return GemDumpSdkLevel.debug;
      case 0:
        return GemDumpSdkLevel.verbose;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Modifies navigation behavior for debugging and testing purposes.
///
/// These modifiers alter navigation behavior to simulate specific conditions or
/// enable certain strategies. Used primarily for testing and debugging navigation
/// features.
///
/// ## See also:
///
/// - [Debug.setNavigationModifiers] - For applying these modifiers.
/// - [Debug.getNavigationModifiers] - For retrieving active modifiers.
///
/// {@category Settings}
enum NavigationModifiers {
  /// Force invalid GPS location.
  invalidLocation,

  /// Force untrusted GPS location.
  untrustedLocation,

  /// Force no matched link.
  invalidMatchedLink,

  /// Force no matched route link.
  invalidMatchedRouteLink,

  /// Force unblocking UTurn strategy.
  unlockUTurn,

  /// Disable intermediate waypoints in navigation instruction.
  disableIntermediateWaypoints,
}

/// @nodoc
extension NavigationModifiersExtension on NavigationModifiers {
  int get id {
    switch (this) {
      case NavigationModifiers.invalidLocation:
        return 1;
      case NavigationModifiers.untrustedLocation:
        return 2;
      case NavigationModifiers.invalidMatchedLink:
        return 4;
      case NavigationModifiers.invalidMatchedRouteLink:
        return 8;
      case NavigationModifiers.unlockUTurn:
        return 16;
      case NavigationModifiers.disableIntermediateWaypoints:
        return 32;
    }
  }

  static NavigationModifiers fromId(int id) {
    switch (id) {
      case 1:
        return NavigationModifiers.invalidLocation;
      case 2:
        return NavigationModifiers.untrustedLocation;
      case 4:
        return NavigationModifiers.invalidMatchedLink;
      case 8:
        return NavigationModifiers.invalidMatchedRouteLink;
      case 16:
        return NavigationModifiers.unlockUTurn;
      case 32:
        return NavigationModifiers.disableIntermediateWaypoints;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Defines logging levels for SDK debug output to console.
///
/// Controls the verbosity of log messages displayed in the console during development.
/// Higher levels produce more detailed logging. Use [Debug.logLevel] to set the
/// active logging level.
///
/// ## See also:
///
/// - [Debug.logLevel] - For setting/getting the current logging level.
/// - [GemDumpSdkLevel] - For controlling crash report log verbosity.
///
/// {@category Settings}
enum GemLoggingLevel {
  /// Severe
  severe,

  /// Warning
  warning,

  /// Info
  info,

  /// Config
  config,

  /// Fine
  fine,

  /// Finer
  finer,

  /// Finest
  finest,

  /// All
  all,

  /// Off
  off,
}
