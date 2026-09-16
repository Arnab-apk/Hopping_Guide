// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// Path import supported formats
///
/// {@category Sensor Data Source}
enum FileType {
  /// NMEA file format, commonly used for GPS data exchange.
  nmea,

  /// GPX file format, an XML-based format for exchanging GPS data.
  gpx,

  /// KML file format, used for geographic data representation in XML.
  kml,

  /// GeoJSON format for encoding a variety of geographic data structures.
  geoJson,

  /// CSV file format, used for representing tabular data in a comma-separated values format.
  csv,

  /// Dead reckoning CSV file format, used for representing tabular data in a comma-separated values format.
  dr,

  /// FIT file format, commonly used for fitness-related data storage.
  fit,

  /// TCX file format, commonly used for tracking training activities in XML format.
  tcx,
}

/// @nodoc
extension FileTypeExtension on FileType {
  int get id {
    switch (this) {
      case FileType.nmea:
        return 0;
      case FileType.gpx:
        return 1;
      case FileType.kml:
        return 2;
      case FileType.geoJson:
        return 3;
      case FileType.csv:
        return 4;
      case FileType.dr:
        return 5;
      case FileType.fit:
        return 6;
      case FileType.tcx:
        return 7;
    }
  }

  static FileType fromId(final int id) {
    switch (id) {
      case 0:
        return FileType.nmea;
      case 1:
        return FileType.gpx;
      case 2:
        return FileType.kml;
      case 3:
        return FileType.geoJson;
      case 4:
        return FileType.csv;
      case 5:
        return FileType.dr;
      case 6:
        return FileType.fit;
      case 7:
        return FileType.tcx;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Enum for easily accessible hardware information on Android and iOS
///
/// {@category Sensor Data Source}
enum HardwareSpecification {
  /// Device model, e.g., "Pixel 6", "iPhone 14 Pro"
  deviceModel,

  /// Manufacturer, e.g., "Google", "Apple", "Samsung"
  manufacturer,

  /// Operating system version, e.g., "Android 14", "iOS 17.2"
  osVersion,

  /// Total physical memory (in MB), e.g., 8192
  totalRAM,

  /// Available RAM at the time of logging (in MB)
  freeRAM,

  /// Total storage space (in GB), e.g., 128
  storageTotal,

  /// Free storage space available on the device (in GB), e.g., 43.2
  storageFree,

  /// Storage type, e.g., "UFS 3.1", "eMMC"
  storageType,

  /// CPU information, e.g., "Snapdragon 8 Gen 1, 8 cores"
  cpuInfo,

  /// GPU information, e.g., "Adreno 730", "Apple GPU (5-core)"
  gpuInfo,

  /// Screen resolution, e.g., "2400x1080"
  screenResolution,

  /// Screen density (dpi), e.g., 440
  screenDensity,

  /// Screen refresh rate (Hz), e.g., 60, 120
  refreshRate,

  /// Battery level in percentage, e.g., 87
  batteryLevel,

  /// Whether the device is charging, true/false
  isCharging,

  /// Current battery state, e.g., "Charging", "Full", "Unplugged"
  batteryState,

  /// Thermal status of the device, e.g., "Normal", "Warning", "Critical"
  thermalStatus,

  /// Number of cameras available on the device
  cameraCount,

  /// Camera capabilities summary, e.g., "12MP main, 4K@60fps, OIS"
  cameraCapabilities,

  /// Availability of key sensors: "accelerometer, gyroscope, magnetometer, etc"
  sensorAvailability,

  /// List of supported ABIs (e.g., "arm64-v8a", "armeabi-v7a")
  supportedABIs,

  /// Unique fingerprint for the build e.g., "Magic Earth 7.1.25.17.F7E936D9.2F9D5083"
  buildFingerprint,

  /// Current device locale, e.g., "en-US", "ro-RO"
  locale,
}

/// @nodoc
extension HardwareSpecificationExtension on HardwareSpecification {
  int get id {
    switch (this) {
      case HardwareSpecification.deviceModel:
        return 0;
      case HardwareSpecification.manufacturer:
        return 1;
      case HardwareSpecification.osVersion:
        return 2;
      case HardwareSpecification.totalRAM:
        return 3;
      case HardwareSpecification.freeRAM:
        return 4;
      case HardwareSpecification.storageTotal:
        return 5;
      case HardwareSpecification.storageFree:
        return 6;
      case HardwareSpecification.storageType:
        return 7;
      case HardwareSpecification.cpuInfo:
        return 8;
      case HardwareSpecification.gpuInfo:
        return 9;
      case HardwareSpecification.screenResolution:
        return 10;
      case HardwareSpecification.screenDensity:
        return 11;
      case HardwareSpecification.refreshRate:
        return 12;
      case HardwareSpecification.batteryLevel:
        return 13;
      case HardwareSpecification.isCharging:
        return 14;
      case HardwareSpecification.batteryState:
        return 15;
      case HardwareSpecification.thermalStatus:
        return 16;
      case HardwareSpecification.cameraCount:
        return 17;
      case HardwareSpecification.cameraCapabilities:
        return 18;
      case HardwareSpecification.sensorAvailability:
        return 19;
      case HardwareSpecification.supportedABIs:
        return 20;
      case HardwareSpecification.buildFingerprint:
        return 21;
      case HardwareSpecification.locale:
        return 22;
    }
  }

  static HardwareSpecification fromId(final int id) {
    switch (id) {
      case 0:
        return HardwareSpecification.deviceModel;
      case 1:
        return HardwareSpecification.manufacturer;
      case 2:
        return HardwareSpecification.osVersion;
      case 3:
        return HardwareSpecification.totalRAM;
      case 4:
        return HardwareSpecification.freeRAM;
      case 5:
        return HardwareSpecification.storageTotal;
      case 6:
        return HardwareSpecification.storageFree;
      case 7:
        return HardwareSpecification.storageType;
      case 8:
        return HardwareSpecification.cpuInfo;
      case 9:
        return HardwareSpecification.gpuInfo;
      case 10:
        return HardwareSpecification.screenResolution;
      case 11:
        return HardwareSpecification.screenDensity;
      case 12:
        return HardwareSpecification.refreshRate;
      case 13:
        return HardwareSpecification.batteryLevel;
      case 14:
        return HardwareSpecification.isCharging;
      case 15:
        return HardwareSpecification.batteryState;
      case 16:
        return HardwareSpecification.thermalStatus;
      case 17:
        return HardwareSpecification.cameraCount;
      case 18:
        return HardwareSpecification.cameraCapabilities;
      case 19:
        return HardwareSpecification.sensorAvailability;
      case 20:
        return HardwareSpecification.supportedABIs;
      case 21:
        return HardwareSpecification.buildFingerprint;
      case 22:
        return HardwareSpecification.locale;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Values that represent file sorting types.
///
/// {@category Sensor Data Source}
enum FileSortType {
  /// Sort files by name.
  name,

  /// Sort files by type (e.g., file extension).
  type,

  /// Sort files by date (e.g., modification date).
  date,

  /// Sort files by name and date.
  nameDate,

  /// Sort files by path and date.
  pathDate,

  /// Sort files by path in lexicographical order.
  pathLexicographical,
}

/// @nodoc
extension FileSortTypeExtension on FileSortType {
  int get id {
    switch (this) {
      case FileSortType.name:
        return 0;
      case FileSortType.type:
        return 1;
      case FileSortType.date:
        return 2;
      case FileSortType.nameDate:
        return 3;
      case FileSortType.pathDate:
        return 4;
      case FileSortType.pathLexicographical:
        return 5;
    }
  }

  static FileSortType fromId(final int id) {
    switch (id) {
      case 0:
        return FileSortType.name;
      case 1:
        return FileSortType.type;
      case 2:
        return FileSortType.date;
      case 3:
        return FileSortType.nameDate;
      case 4:
        return FileSortType.pathDate;
      case 5:
        return FileSortType.pathLexicographical;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Values that represent file sorting orders.
///
/// {@category Sensor Data Source}
enum FileSortOrder {
  /// No specific sorting order is applied.
  no,

  /// Sort files in ascending order (e.g., A-Z, oldest to newest).
  asc,

  /// Sort files in descending order (e.g., Z-A, newest to oldest).
  desc,
}

/// @nodoc
extension FileSortOrderExtension on FileSortOrder {
  int get id {
    switch (this) {
      case FileSortOrder.no:
        return 0;
      case FileSortOrder.asc:
        return 1;
      case FileSortOrder.desc:
        return 2;
    }
  }

  static FileSortOrder fromId(final int id) {
    switch (id) {
      case 0:
        return FileSortOrder.no;
      case 1:
        return FileSortOrder.asc;
      case 2:
        return FileSortOrder.desc;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Enumerates different states of a recorder.
///
/// {@category Sensor Data Source}
enum RecorderStatus {
  /// Recording is stopped.
  stopped,

  /// Recording is stopping.
  stopping,

  /// Recording is starting.
  starting,

  /// Recording is paused
  paused,

  /// Recording is pausing
  pausing,

  /// Recording is resuming
  resuming,

  /// Recording is in progress.
  recording,

  /// Recording is restarting.
  restarting,
}

/// @nodoc
extension RecorderStatusExtension on RecorderStatus {
  int get id {
    switch (this) {
      case RecorderStatus.stopped:
        return 0;
      case RecorderStatus.stopping:
        return 1;
      case RecorderStatus.starting:
        return 2;
      case RecorderStatus.paused:
        return 3;
      case RecorderStatus.pausing:
        return 4;
      case RecorderStatus.resuming:
        return 5;
      case RecorderStatus.recording:
        return 6;
      case RecorderStatus.restarting:
        return 7;
    }
  }

  static RecorderStatus fromId(final int id) {
    switch (id) {
      case 0:
        return RecorderStatus.stopped;
      case 1:
        return RecorderStatus.stopping;
      case 2:
        return RecorderStatus.starting;
      case 3:
        return RecorderStatus.paused;
      case 4:
        return RecorderStatus.pausing;
      case 5:
        return RecorderStatus.resuming;
      case 6:
        return RecorderStatus.recording;
      case 7:
        return RecorderStatus.restarting;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}

/// Enumeration representing different modes of transportation.
///
/// Used in recording configurations to specify the transport mode.
/// It is different from navigation transport modes.
///
/// {@category Sensor Data Source}
enum RecordingTransportMode {
  /// Unknown transport mode, used when the mode is not specified or recognized.
  unknown,

  /// Transport mode for cars.
  car,

  /// Transport mode for trucks.
  truck,

  /// Transport mode for pedestrians, representing walking.
  pedestrian,

  /// Transport mode for pedestrians, representing hiking.
  hike,

  /// Transport mode for bicycles in general.
  bike,

  /// Transport mode for road bikes, typically used on paved roads.
  roadBike,

  ///Transport mode for cross bikes, used on mixed terrain.
  crossBike,

  /// Transport mode for city bikes, designed for urban commuting.
  cityBike,

  /// Transport mode for mountain bikes, used on rough, off-road terrain.
  mountainBike,
}

/// @nodoc
extension RecordingTransportModeExtension on RecordingTransportMode {
  int get id {
    switch (this) {
      case RecordingTransportMode.unknown:
        return 0;
      case RecordingTransportMode.car:
        return 1;
      case RecordingTransportMode.truck:
        return 2;
      case RecordingTransportMode.pedestrian:
        return 3;
      case RecordingTransportMode.hike:
        return 4;
      case RecordingTransportMode.bike:
        return 5;
      case RecordingTransportMode.roadBike:
        return 6;
      case RecordingTransportMode.crossBike:
        return 7;
      case RecordingTransportMode.cityBike:
        return 8;
      case RecordingTransportMode.mountainBike:
        return 9;
    }
  }

  static RecordingTransportMode fromId(final int id) {
    switch (id) {
      case 0:
        return RecordingTransportMode.unknown;
      case 1:
        return RecordingTransportMode.car;
      case 2:
        return RecordingTransportMode.truck;
      case 3:
        return RecordingTransportMode.pedestrian;
      case 4:
        return RecordingTransportMode.hike;
      case 5:
        return RecordingTransportMode.bike;
      case 6:
        return RecordingTransportMode.roadBike;
      case 7:
        return RecordingTransportMode.crossBike;
      case 8:
        return RecordingTransportMode.cityBike;
      case 9:
        return RecordingTransportMode.mountainBike;
      default:
        throw ArgumentError('Invalid id');
    }
  }
}
