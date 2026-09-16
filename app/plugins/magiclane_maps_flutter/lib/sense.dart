// SPDX-FileCopyrightText: 2023-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

/// # Sense
///
/// Provides APIs for sensor data collection, recording and processing.
///
/// This library covers the main interfaces and classes for working with sensor data, including data sources, listeners, log upload, and recording.
///
/// Keep in mind that most sensors are not supported on web platforms.
///
/// ## Main features
/// - [PositionService] – Service for accessing device position data.
/// - [DataSourceListener] – Listener for sensor data source events.
/// - [LogUploader], [LogUploadListener] – Upload and monitor sensor logs. Used mainly for debugging and analysis.
/// - [Recorder] – Record and manage sensor data.
/// - [SenseData], [DataSource] – Core sensor data and sources.
///
/// ## More details
///
/// - See the [Positioning & Sensors documentation](https://developer.magiclane.com/docs/flutter/guides/category/positioning--sensors) for more information.
library;

export 'src/position/gem_position_listener.dart';
export 'src/position/position_road_modifier.dart';
export 'src/position/position_service.dart';
export 'src/sense/activity_record.dart';
export 'src/sense/data_source_listener.dart';
export 'src/sense/log_mark.dart';
export 'src/sense/log_metadata.dart';
export 'src/sense/log_upload_listener.dart';
export 'src/sense/log_uploader.dart';
export 'src/sense/metrics.dart';
export 'src/sense/playback.dart';
export 'src/sense/position_sensor_configuration.dart';
export 'src/sense/recorder.dart';
export 'src/sense/recorder_bookmarks.dart';
export 'src/sense/recorder_configuration.dart';
export 'src/sense/recorder_data_types.dart';
export 'src/sense/sense_data/acceleration.dart';
export 'src/sense/sense_data/attitude.dart';
export 'src/sense/sense_data/battery.dart';
export 'src/sense/sense_data/camera.dart';
export 'src/sense/sense_data/compass.dart';
export 'src/sense/sense_data/heart_rate.dart';
export 'src/sense/sense_data/magnetic_field.dart';
export 'src/sense/sense_data/mount_information.dart';
export 'src/sense/sense_data/nmea_chunk.dart';
export 'src/sense/sense_data/orientation.dart';
export 'src/sense/sense_data/rotation_rate.dart';
export 'src/sense/sense_data/sense_data.dart';
export 'src/sense/sense_data/temperature.dart';
export 'src/sense/sense_data_factory.dart';
export 'src/sense/sense_data_source.dart';
export 'src/sense/sense_data_types.dart';
