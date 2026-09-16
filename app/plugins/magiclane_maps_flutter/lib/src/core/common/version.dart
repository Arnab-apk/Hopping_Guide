// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:meta/meta.dart';

/// Compact major/minor version for content (usually roadmaps).
///
/// Encodes a major/minor pair. It can be compared to other [Version].
///
/// Usually provided by classes such as [ContentStoreItem],
/// [OffBoardListener] and [MapDetails].
///
/// ## See also:
///
/// - [ContentStoreItem] - Obtain version information for content store items.
/// - [OffBoardListener] - Get notified about content updated and other events.
///
/// {@category Common}
class Version implements Comparable<Version> {
  /// Constructor for the [Version] class.
  ///
  /// API users do not normally need to construct instances directly.
  ///
  /// ## Parameters
  ///
  /// - [encodedVersion]: Encoded version number combining major and minor.
  Version({final int encodedVersion = 0}) : _encodedVersion = encodedVersion;

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory Version.fromJson(final Map<String, dynamic> json) {
    final int encodedVersion = json['version'];
    return Version(encodedVersion: encodedVersion);
  }

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  factory Version.fromMajorAndMinor({
    required final int major,
    required final int minor,
  }) {
    return Version(encodedVersion: (minor << 16) | major);
  }

  /// Minor version number
  int get minor => (_encodedVersion >> 16) & 0xFFFF;

  /// Major version number
  int get major => _encodedVersion & 0xFFFF;

  /// Encoded version number
  int _encodedVersion;

  @override
  int compareTo(final Version other) {
    if (major == other.major) {
      return minor.compareTo(other.minor);
    }
    return major.compareTo(other.major);
  }

  @override
  bool operator ==(covariant final Version other) {
    if (identical(this, other)) {
      return true;
    }

    return major == other.major && minor == other.minor;
  }

  /// Check if the version is valid
  ///
  /// A version is valid minor and major are greater than 0
  ///
  /// ## Returns
  ///
  /// - True if the version is valid, false otherwise
  bool get isValid {
    return _encodedVersion != 0;
  }

  @override
  int get hashCode => major.hashCode ^ minor.hashCode;

  @override
  String toString() => '$major.$minor';
}

/// SDK version container.
///
/// Holds SDK version components as small integers plus an optional revision
/// string. Useful for displaying or comparing the embedded SDK version.
///
/// {@category Common}
@Deprecated('Use setApplicationVersion instead.')
class SdkVersion {
  /// Constructor for the SdkVersion class.
  ///
  /// The API user does not normally need to construct instances directly.
  ///
  /// ## Parameters
  ///
  /// - [minor]: Minor SDK version number, such as 2 in version 1.2
  /// - [major]: Major SDK version number, such as 1 in version 1
  /// - [year]: SDK year, decimal 1 or 2 digits
  /// - [week]: The week of the year, decimal 1 or 2 digits
  /// - [revision]: SDK revision string
  @Deprecated('Use setApplicationVersion instead.')
  SdkVersion({
    this.minor = 0,
    this.major = 0,
    this.year = 0,
    this.week = 0,
    this.revision = '',
  });

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @Deprecated('Use setApplicationVersion instead.')
  factory SdkVersion.fromJson(final Map<String, dynamic> json) {
    return SdkVersion(
      minor: json['minor'],
      major: json['major'],
      week: json['week'],
      year: json['year'],
      revision: json['revision'],
    );
  }

  /// Minor SDK version number, such as 2 in version 1.2;
  int minor;

  /// Major SDK version number, such as 1 in version 1.2;
  int major;

  /// SDK year, decimal 1 or 2 digits
  int year;

  /// The week of the year, decimal 1 or 2 digits
  int week;

  /// SDK revision string
  String revision;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{};
    json['minor'] = minor;
    json['major'] = major;
    json['year'] = year;
    json['week'] = week;
    json['revision'] = revision;
    return json;
  }
}
