// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Network types used when categorizing transfer statistics.
///
/// Use these values to select which network bucket to query on a
/// [TransferStatistics] instance. `free` represents networks with no
/// per-byte charge (for example, unlimited Wi‑Fi or wired connections).
/// `extraCharged` represents networks that may incur per-byte or
/// per-time charges (cellular data, roaming, etc.).
///
/// {@category Common}
enum NetworkType {
  /// Free of charge networks (unlimited WiFi or wired networks).
  free,

  /// Networks that may incur charges for data transfer (mobile/cellular).
  extraCharged,
}

/// @nodoc
extension NetworkTypeExtension on NetworkType {
  int get id {
    switch (this) {
      case NetworkType.free:
        return 0;
      case NetworkType.extraCharged:
        return 1;
    }
  }

  static NetworkType fromId(final int id) {
    switch (id) {
      case 0:
        return NetworkType.free;
      case 1:
        return NetworkType.extraCharged;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Online service types for which a view can expose transfer statistics.
///
/// When requesting transfer statistics from a [GemMapController] you can
/// pick the service type to obtain per-service transfer information.
///
/// ## Also see:
///
/// - [GemMapController.getTransferStatistics] - Retrieve transfer statistics for a specific online service.
///
/// {@category Common}
enum ViewOnlineServiceType {
  /// Map tiles and related map traffic.
  map,

  /// Satellite elevation / topography data.
  satelliteElevation,

  /// Overlay services
  overlays,

  /// External data sources (wiki)
  external,
}

/// @nodoc
extension ViewOnlineServiceTypeExtension on ViewOnlineServiceType {
  int get id {
    switch (this) {
      case ViewOnlineServiceType.map:
        return 0;
      case ViewOnlineServiceType.satelliteElevation:
        return 1;
      case ViewOnlineServiceType.overlays:
        return 2;
      case ViewOnlineServiceType.external:
        return 3;
    }
  }

  static ViewOnlineServiceType fromId(final int id) {
    switch (id) {
      case 0:
        return ViewOnlineServiceType.map;
      case 1:
        return ViewOnlineServiceType.satelliteElevation;
      case 2:
        return ViewOnlineServiceType.overlays;
      case 3:
        return ViewOnlineServiceType.external;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Provides data transfer statistics for a specific online service.
///
/// This object exposes total upload/download/request counters as well as
/// per-network-type breakdowns. Instances are returned by service singletons
/// (for example [ContentStore.transferStatistics], [SdkSettings.transferStatistics])
/// or via [GemMapController.getTransferStatistics].
///
/// Use the getters to read the overall totals and the [getUpload] /
/// [getDownload] / [getRequests] methods to obtain values for a specific
/// [NetworkType].
///
/// ## See also:
/// - [NetworkType] - Network types for transfer statistics breakdown.
/// - [ViewOnlineServiceType] - Online service types for views.
///
/// {@category Common}
class TransferStatistics extends GemAutoreleaseObject {
  // ignore: unused_element
  TransferStatistics._() : super(-1);

  /// Internal constructor for creating a TransferStatistics wrapper with an
  /// existing native pointer id.
  @internal
  TransferStatistics.init(super.id);

  /// Total uploaded data size in bytes.
  ///
  /// ## Returns
  ///
  /// - The overall uploaded data size in bytes.
  int get upload {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'TransferStatistics',
      'getUpload',
    );
    return resultString['result'];
  }

  /// Total downloaded data size in bytes.
  ///
  /// ## Returns
  ///
  /// - The overall downloaded data size in bytes.
  int get download {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'TransferStatistics',
      'getDownload',
    );
    return resultString['result'];
  }

  /// Total number of requests performed by the service.
  ///
  /// ## Returns
  ///
  /// - The overall number of requests.
  int get requests {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'TransferStatistics',
      'getRequests',
    );
    return resultString['result'];
  }

  /// Uploaded data size in bytes for the given network type.
  ///
  /// ## Parameters
  ///
  /// - [networkType]: The network type to query (see [NetworkType]).
  ///
  /// ## Returns
  ///
  /// - The uploaded data size in bytes for `networkType`.
  int getUpload(NetworkType networkType) {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'TransferStatistics',
      'getUploadNetworkType',
      args: networkType.id,
    );
    return resultString['result'];
  }

  /// Downloaded data size in bytes for the given network type.
  ///
  /// ## Parameters
  ///
  /// - [networkType]: The network type to query (see [NetworkType]).
  ///
  /// ## Returns
  ///
  /// - The downloaded data size in bytes for `networkType`.
  int getDownload(NetworkType networkType) {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'TransferStatistics',
      'getDownloadNetworkType',
      args: networkType.id,
    );
    return resultString['result'];
  }

  /// Number of requests for the given network type.
  ///
  /// ## Parameters
  ///
  /// - [networkType]: The network type to query (see [NetworkType]).
  ///
  /// ## Returns
  ///
  /// - The overall number of requests for `networkType`.
  int getRequests(NetworkType networkType) {
    final OperationResult resultString = objectMethod(
      super.pointerId,
      'TransferStatistics',
      'getRequestsNetworkType',
      args: networkType.id,
    );
    return resultString['result'];
  }

  /// Reset all transfer statistics counters to zero.
  ///
  /// Use this method to clear accumulated counters.
  void resetStatistics() {
    objectMethod(super.pointerId, 'TransferStatistics', 'reset');
  }
}
