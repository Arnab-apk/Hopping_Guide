// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Service for downloading offline map tiles for one or more geographic areas.
///
/// Use this service to initiate downloads of map tiles for offline viewing.
/// Manage the downloaded map data and monitor transfer statistics.
///
/// This service does not manage map data storage. Downloaded tiles cannot be used
/// for search, navigation or routing. See the [ContentStore] for managing
/// offline map data.
///
/// {@category Maps & 3D Scenes}
class MapDownloaderService extends GemAutoreleaseObject {
  /// Creates a new [MapDownloaderService] instance.
  ///
  /// Use the default constructor to obtain a service instance that can start
  /// downloads and provide transfer statistics.
  factory MapDownloaderService() {
    return MapDownloaderService._create();
  }
  // ignore: unused_element
  MapDownloaderService._() : super(-1);

  @internal
  MapDownloaderService.init(super.id);

  static MapDownloaderService _create() {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, String>{'class': 'MapDownloaderService'}),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final MapDownloaderService retVal = MapDownloaderService.init(
      decodedVal['result'],
    );
    return retVal;
  }

  @Deprecated('Use maxSquareKm getter and setter instead.')
  int get getMaxSquareKm => maxSquareKm;

  @Deprecated('Use maxSquareKm getter and setter instead.')
  set setMaxSquareKm(int value) => maxSquareKm = value;

  /// Returns the maximum area size (in square kilometers) allowed for downloads.
  ///
  /// If a requested download area exceeds this value, [startDownload] will
  /// fail with an appropriate [GemError].
  ///
  /// ## Returns
  ///
  /// - (`int`) Maximum permitted area in square kilometers for a single
  ///   download request.
  ///
  /// ## See also:
  ///
  /// - [maxSquareKm] — Set the maximum area size allowed for downloads.
  int get maxSquareKm {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapDownloaderService',
      'getMaxSquareKm',
    );

    return resultString['result'] as int;
  }

  /// Sets the maximum area size (in square kilometers) allowed for downloads.
  ///
  /// Use this setter to limit how large a requested download area can be. If a
  /// subsequent [startDownload] request exceeds this value it will not start
  /// and the completion callback will receive [GemError.outOfRange].
  ///
  /// ## Parameters
  ///
  /// - [value]: (`int`) The maximum area size in square kilometers.
  set maxSquareKm(int value) {
    objectMethod(
      pointerId,
      'MapDownloaderService',
      'setMaxSquareKm',
      args: value,
    );
  }

  /// Starts downloading map tiles for the specified geographic area(s).
  ///
  /// Completion is reported through the [onComplete] callback with
  /// a [GemError] indicating the final status. If the operation cannot be
  /// started an error will be delivered to [onComplete] and the method returns
  /// `null`.
  ///
  /// ## Parameters
  ///
  /// - [areas]: (`List<RectangleGeographicArea>`) A list of one or more
  ///   geographic rectangles to download tiles for.
  /// - [onComplete]: (`void Function(GemError err)`) Callback invoked when the
  ///   operation finishes. The callback receives a [GemError] with one of the
  ///   following meaningful values:
  ///   - [GemError.success] — Download completed successfully.
  ///   - [GemError.outOfRange] — One or more requested areas exceed the
  ///     configured [maxSquareKm].
  ///   - [GemError.cancel] — The download was cancelled by calling
  ///     [cancelDownload].
  ///   - [GemError.upToDate] — The requested area is already cached and no
  ///     download was necessary.
  ///
  /// ## Returns
  ///
  /// - (`ProgressListener?`) A [ProgressListener] instance that can be used to
  ///   monitor progress and register additional callbacks, or `null` if the
  ///   operation could not be started.
  ///
  /// ## Example
  ///
  /// ```dart
  /// final service = MapDownloaderService();
  /// service.maxSquareKm = 300;
  ///
  /// service.startDownload([area], (err) {
  ///   if (err == GemError.success) {
  ///     print('Download started successfully.');
  ///   } else {
  ///     print('Failed to start download: $err');
  ///   }
  /// });
  /// ```
  ///
  /// ## See also:
  ///
  /// - [cancelDownload] — Cancel a running download.
  ProgressListener? startDownload(
    List<RectangleGeographicArea> areas,
    final void Function(GemError err) onComplete,
  ) {
    final EventDrivenProgressListener progListener =
        EventDrivenProgressListener();

    final OperationResult resultString = objectMethod(
      pointerId,
      'MapDownloaderService',
      'startDownload',
      args: <String, Object>{
        'areasCoordinates': areas,
        'progressListener': progListener.id,
      },
    );

    // ignore: unnecessary_type_check
    if (resultString.data is Map && resultString.containsKey('gemApiError')) {
      final int errorCode = resultString['gemApiError'] as int;
      final GemError error = GemErrorExtension.fromCode(errorCode);
      if (error != GemError.success) {
        onComplete(error);
        return null;
      }
    }

    progListener.registerOnCompleteWithData((
      final int err,
      final String hint,
      final Map<dynamic, dynamic> json,
    ) {
      if (err == 0) {
        onComplete(GemErrorExtension.fromCode(0));
      } else {
        onComplete(GemErrorExtension.fromCode(err));
      }
    });

    GemKitPlatform.instance.registerEventHandler(progListener.id, progListener);
    return progListener;
  }

  /// Cancels an ongoing download operation.
  ///
  /// The cancellation is asynchronous; the final completion state will be
  /// reported via the progress listener's completion callback (and will
  /// typically result in [GemError.cancel] being delivered to the
  /// [onComplete] callback passed to [startDownload]).
  void cancelDownload() {
    objectMethod(pointerId, 'MapDownloaderService', 'cancelDownload');
  }

  /// Returns transfer statistics for data exchanged by this service.
  ///
  /// Returns a [TransferStatistics] object containing counters and metrics
  /// about network usage performed by the traffic service. This information
  /// can be used for diagnostics or to display usage to end users.
  ///
  /// ## Returns
  ///
  /// - ([TransferStatistics]) Object containing `download`, `upload` and
  ///   `requests` properties summarising data transfer for this service.
  TransferStatistics get transferStatistics {
    final OperationResult resultString = objectMethod(
      pointerId,
      'MapDownloaderService',
      'getTransferStatistics',
    );

    return TransferStatistics.init(resultString['result']);
  }
}
