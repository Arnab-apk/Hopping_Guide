// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Known sense data types.
///
/// Each value corresponds to a specific [SenseData] type that can be
/// retrieved from a [DataSource].
///
/// On web only [position] and [improvedPosition] are produced, as the browser
/// exposes no raw device sensors.
///
/// {@category Sensor Data Source}
enum DataType {
  /// Acceleration data.
  acceleration,

  /// Attitude data.
  attitude,

  /// Battery data.
  battery,

  /// Camera data.
  camera,

  /// Compass data.
  compass,

  /// Magnetic field data.
  magneticField,

  /// Orientation data.
  orientation,

  /// Position data.
  position,

  /// Improved position data.
  improvedPosition,

  /// Rotation rate data.
  rotationRate,

  /// Temperature data.
  temperature,

  /// Notification data.
  notification,

  /// Mount information data.
  mountInformation,

  /// Heart rate data.
  heartRate,

  /// NMEA chunk data.
  ///
  /// Android-only.
  nmeaChunk,

  /// Unknown data type.
  unknown,

  /// Same as [rotationRate].
  gyroscope,
}

/// @nodoc
extension DataTypeExtension on DataType {
  int get id {
    switch (this) {
      case DataType.acceleration:
        return 0;
      case DataType.attitude:
        return 2;
      case DataType.battery:
        return 3;
      case DataType.camera:
        return 4;
      case DataType.compass:
        return 5;
      case DataType.magneticField:
        return 6;
      case DataType.orientation:
        return 7;
      case DataType.position:
        return 8;
      case DataType.improvedPosition:
        return 9;
      case DataType.rotationRate:
      case DataType.gyroscope: // Alias
        return 10;
      case DataType.temperature:
        return 11;
      case DataType.notification:
        return 12;
      case DataType.mountInformation:
        return 13;
      case DataType.heartRate:
        return 14;
      case DataType.nmeaChunk:
        return 15;
      case DataType.unknown:
        return 16;
    }
  }

  static DataType fromId(final int id) {
    switch (id) {
      case 0:
        return DataType.acceleration;
      case 2:
        return DataType.attitude;
      case 3:
        return DataType.battery;
      case 4:
        return DataType.camera;
      case 5:
        return DataType.compass;
      case 6:
        return DataType.magneticField;
      case 7:
        return DataType.orientation;
      case 8:
        return DataType.position;
      case 9:
        return DataType.improvedPosition;
      case 10:
        return DataType.rotationRate;
      case 11:
        return DataType.temperature;
      case 12:
        return DataType.notification;
      case 13:
        return DataType.mountInformation;
      case 14:
        return DataType.heartRate;
      case 15:
        return DataType.nmeaChunk;
      case 16:
        return DataType.unknown;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// The data source type.
///
/// {@category Sensor Data Source}
enum DataSourceType {
  /// The type of data source is unknown.
  unknown,

  /// Data is obtained from sensors or any other live source.
  live,

  /// Data is obtained from playing a previously recorded log file or through simulation.
  playback,
}

/// @nodoc
extension DataSourceTypeExtension on DataSourceType {
  int get id {
    switch (this) {
      case DataSourceType.unknown:
        return 0;
      case DataSourceType.live:
        return 1;
      case DataSourceType.playback:
        return 2;
    }
  }

  static DataSourceType fromId(final int id) {
    switch (id) {
      case 0:
        return DataSourceType.unknown;
      case 1:
        return DataSourceType.live;
      case 2:
        return DataSourceType.playback;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Estimated Video Data Rates by Resolution (used for size estimation)
/// Values are approximate and based on platform-specific analysis:
/// - All sizes are expressed in **bytes per second**
/// - MB/min approximations included for clarity
///
/// Resolution           | Approx. Size (Bytes/sec) | Approx. Size (MB/min)
/// ---------------------|--------------------------|------------------------
/// SD_480p              | 210,000                  | ~12 MB/min
/// HD_720p (Apple)      | 1,048,576                | ~60 MB/min - reported from iOS Camera App settings
/// HD_720p (Android)    | 629,760                  | ~37 MB/min - computed by analyzing our existing video logs and choosing the biggest one + 10%
/// HD_720p (Other)      | 1,048,576                | ~60 MB/min - just use the biggest value, Apple
/// FullHD_1080p         | 3,774,874                | ~130 MB/min
///
/// Note: 1 MB = 1,048,576 bytes (binary MB), used for consistency across platforms.
///
/// Display resolutions.
///
/// {@category Sensor Data Source}
enum Resolution {
  /// No resolution.
  unknown,

  /// 640 × 480 resolution (SD 480p).
  sd480p,

  /// 1280 × 720 resolution (HD 720p).
  hd720p,

  /// 1920 × 1080 resolution (Full HD 1080p).
  fullHD1080p,

  /// 2560 × 1440 resolution (WQHD 1440p).
  wqhd1440p,

  /// 3840 × 2160 resolution (UHD 4K 2160p).
  uhd4K2160p,

  /// 7680 × 4320 resolution (UHD 8K 4320p).
  uhd8K4320p,
}

/// @nodoc
extension ResolutionExtension on Resolution {
  int get id {
    switch (this) {
      case Resolution.unknown:
        return 0;
      case Resolution.sd480p:
        return 1;
      case Resolution.hd720p:
        return 2;
      case Resolution.fullHD1080p:
        return 3;
      case Resolution.wqhd1440p:
        return 4;
      case Resolution.uhd4K2160p:
        return 5;
      case Resolution.uhd8K4320p:
        return 6;
    }
  }

  static Resolution fromId(final int id) {
    switch (id) {
      case 0:
        return Resolution.unknown;
      case 1:
        return Resolution.sd480p;
      case 2:
        return Resolution.hd720p;
      case 3:
        return Resolution.fullHD1080p;
      case 4:
        return Resolution.wqhd1440p;
      case 5:
        return Resolution.uhd4K2160p;
      case 6:
        return Resolution.uhd8K4320p;
      default:
        throw ArgumentError('Invalid id');
    }
  }

  String serialize() {
    switch (this) {
      case Resolution.unknown:
        return '0';
      case Resolution.sd480p:
        return '1';
      case Resolution.hd720p:
        return '2';
      case Resolution.fullHD1080p:
        return '3';
      case Resolution.wqhd1440p:
        return '4';
      case Resolution.uhd4K2160p:
        return '5';
      case Resolution.uhd8K4320p:
        return '6';
    }
  }

  static Resolution? fromString(final String? resolution) {
    if (resolution == null) {
      return null;
    }
    switch (resolution) {
      case '0':
        return Resolution.unknown;
      case '1':
        return Resolution.sd480p;
      case '2':
        return Resolution.hd720p;
      case '3':
        return Resolution.fullHD1080p;
      case '4':
        return Resolution.wqhd1440p;
      case '5':
        return Resolution.uhd4K2160p;
      case '6':
        return Resolution.uhd8K4320p;
      default:
        return null;
    }
  }
}

/// Data origin.
///
/// {@category Sensor Data Source}
enum Origin {
  ///  The origin of the data is unknown.
  unknown,

  /// The data is sourced from an internal data source.
  gm,

  ///  The data is sourced from a custom data source defined by an external party.
  external,
}

/// @nodoc
extension OriginExtension on Origin {
  int get id {
    switch (this) {
      case Origin.unknown:
        return 0;
      case Origin.gm:
        return 1;
      case Origin.external:
        return 2;
    }
  }

  static Origin fromId(final int id) {
    switch (id) {
      case 0:
        return Origin.unknown;
      case 1:
        return Origin.gm;
      case 2:
        return Origin.external;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Represents the playing status of a data source.
///
/// {@category Sensor Data Source}
enum PlayingStatus {
  /// Unknown playing status
  unknown,

  /// Data source is stopped
  stopped,

  /// Data source is paused
  paused,

  /// Data source is playing
  playing,
}

/// @nodoc
extension PlayingStatusExtension on PlayingStatus {
  /// Maps the enum to an integer ID.
  int get id {
    switch (this) {
      case PlayingStatus.unknown:
        return 0;
      case PlayingStatus.stopped:
        return 1;
      case PlayingStatus.paused:
        return 2;
      case PlayingStatus.playing:
        return 3;
    }
  }

  static PlayingStatus fromId(final int id) {
    switch (id) {
      case 0:
        return PlayingStatus.unknown;
      case 1:
        return PlayingStatus.stopped;
      case 2:
        return PlayingStatus.paused;
      case 3:
        return PlayingStatus.playing;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Values that represent type of unit for acceleration data.
///
/// {@category Sensor Data Source}
enum UnitOfMeasurementAcceleration {
  // Gravitational force (g)
  g,

  // Meters per second squared (m/s²).
  metersPerSecondSquared,
}

/// @nodoc
extension UnitOfMeasurementAccelerationExtension
    on UnitOfMeasurementAcceleration {
  int get id {
    switch (this) {
      case UnitOfMeasurementAcceleration.g:
        return 0;
      case UnitOfMeasurementAcceleration.metersPerSecondSquared:
        return 1;
    }
  }

  static UnitOfMeasurementAcceleration fromId(final int id) {
    switch (id) {
      case 0:
        return UnitOfMeasurementAcceleration.g;
      case 1:
        return UnitOfMeasurementAcceleration.metersPerSecondSquared;

      default:
        throw ArgumentError('Invalid id');
    }
  }
}
