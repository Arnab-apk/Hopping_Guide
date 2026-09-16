// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/sense.dart';
import 'package:magiclane_maps_flutter/src/core/common/gem_error.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// Provides access to recorded logs and their metadata on the device.
///
/// [RecorderBookmarks] lets you list, inspect, export, import and manage
/// recorded `.gm` and `.mp4` files stored in a logs directory.
///
/// Do not instantiate directly; use [create] to obtain an instance bound to a
/// specific folder.
///
/// ## See also:
///
/// - [LogMetadata] for per-log metadata access.
///
/// {@category Sensor Data Source}
class RecorderBookmarks extends GemAutoreleaseObject {
  // ignore: unused_element
  RecorderBookmarks._() : super(-1);

  RecorderBookmarks.init(super.id);

  /// Creates a [RecorderBookmarks] instance for the provided folder path.
  ///
  /// The returned instance is bound to the directory that contains `.gm`
  /// and `.mp4` log files. If creating the instance fails (for example when
  /// the path is invalid), the method returns `null`.
  ///
  /// ## Parameters
  ///
  /// - [path]: The absolute path to the folder containing recordings.
  ///
  /// ## Returns
  ///
  /// - A [RecorderBookmarks] instance bound to [path], or `null` on error.
  static RecorderBookmarks? create(final String path) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'RecorderBookmarks', 'args': path}),
    );
    final dynamic decodedVal = jsonDecode(resultString);

    if (decodedVal['gemApiError'] != 0) {
      return null;
    }
    return RecorderBookmarks.init(decodedVal['result']);
  }

  /// Retrieves metadata for a specific log file.
  ///
  /// ## Parameters
  ///
  /// - [logPath]: The path to the log file for which metadata is requested.
  ///
  /// ## Returns
  ///
  /// - A [LogMetadata] instance when the file exists and metadata could be
  ///   read, or `null` if the file does not exist or an error occurred.
  LogMetadata? getLogMetadata(final String logPath) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderBookmarks',
      'getMetadata',
      args: logPath,
    );

    final int id = resultString['result'];

    if (id == -1) {
      return null;
    }

    return LogMetadata(resultString['result']);
  }

  /// Returns a list of logs that are marked as protected.
  ///
  /// Protected logs are excluded from automatic deletion policies.
  ///
  /// ## Returns
  ///
  /// - A `List<String>` containing the file paths of protected logs.
  ///
  /// ## See also:
  ///
  /// - [markLogProtected] — Marks a log as protected.
  List<String> get protectedLogsList {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderBookmarks',
      'getProtectedLogsList',
    );
    return resultString['result'].cast<String>();
  }

  /// Lists all `.gm` and `.mp4` log files in the bound folder.
  ///
  /// The list can be sorted by [sortOrder] and [sortType]. By default the
  /// method returns logs sorted by date in ascending order.
  ///
  /// ## Parameters
  ///
  /// - [sortOrder]: The [FileSortOrder] to use (defaults to `asc`).
  /// - [sortType]: The [FileSortType] to use (defaults to `date`).
  ///
  /// ## Returns
  ///
  /// - A `List<String>` with the sorted log file paths.
  List<String> getLogsList({
    final FileSortOrder sortOrder = FileSortOrder.asc,
    final FileSortType sortType = FileSortType.date,
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderBookmarks',
      'getLogsList',
      args: <String, int>{'sortOrder': sortOrder.id, 'sortType': sortType.id},
    );
    return resultString['result'].cast<String>();
  }

  /// Marks a GM log as protected to prevent automatic deletion.
  ///
  /// This flag stops the system from removing the file during cleanup or
  /// retention-based pruning. Only GM logs are supported by this operation.
  ///
  /// ## Parameters
  ///
  /// - [logPath]: The path to the GM file to mark as protected.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] when the operation succeeds.
  /// - [GemError.general] when the operation fails.
  ///
  /// ## See also:
  ///
  /// - [protectedLogsList] — Retrieves the list of protected logs.
  GemError markLogProtected(final String logPath) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderBookmarks',
      'markLogProtected',
      args: logPath,
    );
    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Marks a GM log as uploaded.
  ///
  /// Use this to indicate that the log has been successfully transmitted to
  /// a server; uploader components or UI can then avoid re-uploading it.
  ///
  /// ## Parameters
  ///
  /// - [logPath]: The path to the GM file to mark as uploaded.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] when the operation succeeds.
  /// - [GemError.general] when the operation fails.
  ///
  /// ## See also:
  ///
  /// - `isUploaded` — Checks whether a log is marked as uploaded.
  GemError markLogUploaded(final String logPath) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderBookmarks',
      'markLogUploaded',
      args: logPath,
    );
    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Deletes the specified log file from the filesystem.
  /// Does not delete protected logs.
  ///
  /// ## Parameters
  ///
  /// - [logPath]: The path to the file to delete.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] when the file was removed.
  /// - [GemError.general] when the operation failed.
  GemError deleteLog(final String logPath) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderBookmarks',
      'deleteLog',
      args: logPath,
    );
    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Returns the duration of an MP4 log file, in seconds.
  ///
  /// ## Parameters
  ///
  /// - [logPath]: The path to the MP4 file.
  ///
  /// ## Returns
  ///
  /// - The duration of the log in seconds.
  int getLogDurationInSeconds(final String logPath) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderBookmarks',
      'getLogDurationInSeconds',
      args: logPath,
    );

    return resultString['result'];
  }

  /// Exports a recorded log to a different file format (for example GPX or
  /// CSV).
  ///
  /// When [exportedFileName] is omitted the original log name is used. The
  /// operation returns a [GemError] that indicates whether the export
  /// succeeded or failed.
  ///
  /// ## Parameters
  ///
  /// - [logPath]: The source log path to export.
  /// - [type]: The [FileType] representing the export format.
  /// - [exportedFileName]: Optional custom output filename (without path).
  ///
  /// ## Returns
  ///
  /// - [GemError.success] on success.
  /// - [GemError.exist] if the exported file already exists.
  /// - [GemError.general] on general failure.
  ///
  /// ## See also:
  ///
  /// - [importLog] — Imports a log file (GPX, NMEA, KML) and stores it in GM format.
  GemError exportLog(
    final String logPath,
    final FileType type, {
    final String? exportedFileName,
  }) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderBookmarks',
      'exportLog',
      args: <String, Object?>{
        'logPath': logPath,
        'type': type.id,
        'exportedFileName': exportedFileName,
      },
    );
    return GemErrorExtension.fromCode(resultString['result']);
  }

  /// Imports a log file (GPX, NMEA, KML) and stores it in the logs folder
  /// in GM format.
  ///
  /// If [importedFileName] is omitted the source filename is used. The
  /// returned [GemError] indicates the outcome of the import.
  ///
  /// ## Parameters
  ///
  /// - [logPath]: The path to the file to import.
  /// - [importedFileName]: Optional name to store the imported log as.
  ///
  /// ## Returns
  ///
  /// - [GemError.success] when import succeeds.
  /// - [GemError.exist] if a file with the target name already exists.
  /// - [GemError.notSupported] if the source format is unsupported.
  /// - [GemError.general] on other failures.
  ///
  /// ## See also:
  ///
  /// - [exportLog] — Exports a recorded log to a different file format (for example GPX or CSV).
  GemError importLog(final String logPath, {final String? importedFileName}) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'RecorderBookmarks',
      'importLog',
      args: <String, Object?>{
        'logPath': logPath,
        'importedFileName': importedFileName,
      },
    );

    return GemErrorExtension.fromCode(resultString['result']);
  }
}
