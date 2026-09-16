// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Base interface for log marks, which can be either [SoundMark] or [TextMark].
///
/// {@category Sensor Data Source}
abstract class LogMark {}

/// Represents a time interval in a recording where sound was captured.
///
/// A [SoundMark] identifies the start and end offsets (in milliseconds) of a
/// section of a log that contains recorded audio and the geographic
/// [Coordinates] associated with that interval.
///
/// Soundmarks are generated automatically during audio recording sessions.
/// Play the `.mp4` file with an external media player to play the audio content
/// from the [start] to the [end] offsets.
///
/// ## See also:
///
/// - [TextMark] — Textual annotations at specific timestamps in the log.
/// - [LogMetadata.soundMarks] — Retrieve sound marks from a log's metadata.
///
/// {@category Sensor Data Source}
class SoundMark implements LogMark {
  /// Creates a [SoundMark] with the specified start and end offsets and coordinates.
  ///
  /// API users typically do not create [SoundMark] instances directly.
  ///
  /// ## Parameters
  ///
  /// - [start]: Start offset in milliseconds (relative to the beginning of the log).
  /// - [end]: End offset in milliseconds (relative to the beginning of the log).
  /// - [coordinates]: [Coordinates] where the sound was recorded.
  SoundMark(this.start, this.end, this.coordinates);

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory SoundMark.fromJson(final Map<String, dynamic> json) {
    return SoundMark(
      json['startOffsetMillis'],
      json['endOffsetMillis'],
      Coordinates.fromJson(json['coordinates']),
    );
  }

  /// Start offset in milliseconds (between 0 and log length).
  int start;

  /// End offset in milliseconds (between 0 and log length).
  int end;

  /// Coordinates associated with the sound interval.
  Coordinates coordinates;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'startOffsetMillis': start,
      'endOffsetMillis': end,
      'coordinates': coordinates.toJson(),
    };
  }
}

/// Represents a textual annotation at a specific moment in a recording.
///
/// A [TextMark] stores an offset timestamp, geographic [Coordinates], and a
/// textual `report` describing the moment. Text marks are useful for bookmarks,
/// notes, or labeling events during a recording session.
///
/// Text marks are added by calling the [Recorder.addTextMark] method while
/// recording.
///
/// ## See also:
///
/// - [SoundMark] — time intervals associated with recorded audio.
/// - [LogMetadata.textMarks] — retrieve text marks from a log's metadata.
/// - [Recorder.addTextMark] — add text marks during recording.
///
/// {@category Sensor Data Source}
class TextMark implements LogMark {
  /// Creates a [TextMark] with the specified offset, coordinates, and report.
  ///
  /// API users typically do not create [TextMark] instances directly.
  ///
  /// ## Parameters
  ///
  /// - [offset]: Timestamp (in milliseconds) of the text mark within the log.
  /// - [coordinates]: [Coordinates] where the text mark was created.
  /// - [report]: The textual note or annotation associated with the mark.
  TextMark(this.offset, this.coordinates, this.report);

  /// Deserializes a JSON-compatible map to create an instance.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The expected map structure may change without notice.
  @internal
  factory TextMark.fromJson(final Map<String, dynamic> json) {
    return TextMark(
      json['offsetMillis'],
      Coordinates.fromJson(json['coordinates']),
      json['report'],
    );
  }

  /// The timestamp (in milliseconds) of the text mark within the log.
  int offset;

  /// The geographical coordinates where the text mark was recorded.
  Coordinates coordinates;

  /// A textual note or annotation associated with the mark.
  String report;

  /// Serializes this instance to a JSON-compatible map.
  ///
  /// Used internally, not intended for direct use by consumers.
  /// The map structure may change without notice.
  @internal
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'offsetMillis': offset,
      'coordinates': coordinates.toJson(),
      'report': report,
    };
  }
}
