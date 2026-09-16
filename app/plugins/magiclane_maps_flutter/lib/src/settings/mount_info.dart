// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Information about a storage mount point used by the application.
///
/// Provides details about storage locations including total capacity, free space,
/// and whether the path is internal storage or used for online caching. Instances
/// are returned by [Debug.getAppIOInfo] to help monitor storage usage.
///
/// ## See also:
///
/// - [Debug.getAppIOInfo] - For retrieving list of storage mount points.
///
/// {@category Settings}
class MountInfo {
  /// Creates a mount info instance with storage details.
  ///
  /// API users typically do not create instances directly.
  ///
  /// ## Parameters
  ///
  /// - [path]: The path to the mount point.
  /// - [freeSpace]: The free space in bytes.
  /// - [totalSpace]: The total space in bytes.
  /// - [internalPath]: Whether this is an internal storage path.
  /// - [onlineCachePath]: Whether this path is used for online caching.
  MountInfo({
    required this.path,
    required this.freeSpace,
    required this.totalSpace,
    required this.internalPath,
    required this.onlineCachePath,
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory MountInfo.fromJson(Map<String, dynamic> json) {
    return MountInfo(
      path: json['path'],
      freeSpace: json['freeSpace'],
      totalSpace: json['totalSpace'],
      internalPath: json['internalPath'],
      onlineCachePath: json['onlineCachePath'],
    );
  }

  /// The path to the mount point.
  String path;

  /// The free space available in bytes.
  int freeSpace;

  /// The total storage capacity in bytes.
  int totalSpace;

  /// Whether this is an internal storage path.
  bool internalPath;

  /// Whether this path is used for online caching.
  bool onlineCachePath;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'path': path,
      'freeSpace': freeSpace,
      'totalSpace': totalSpace,
      'internalPath': internalPath,
      'onlineCachePath': onlineCachePath,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is MountInfo &&
        other.path == path &&
        other.freeSpace == freeSpace &&
        other.totalSpace == totalSpace &&
        other.internalPath == internalPath &&
        other.onlineCachePath == onlineCachePath;
  }

  @override
  int get hashCode {
    return Object.hash(
      path,
      freeSpace,
      totalSpace,
      internalPath,
      onlineCachePath,
    );
  }
}
