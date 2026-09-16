// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Element of a rendered signpost.
///
/// Represents one semantic element of a signpost (for example a text fragment, pictogram or road shield).
/// Instances are returned from [SignpostDetails.items] and should not be constructed directly. Use the properties
/// on this object to decide rendering, text-to-speech, and accessibility behavior.
///
/// ## See also:
///
/// - [SignpostDetails.items] — obtain the list of items for a signpost.
/// - [SignpostImg] — image for signpost rendering.
///
/// {@category Route}
class SignpostItem extends GemAutoreleaseObject {
  // ignore: unused_element
  SignpostItem._() : super(-1);

  @internal
  SignpostItem.init(super.id) {
    super.registerAutoReleaseObject(super.pointerId);
  }

  /// Column index for layout placement (1-based).
  ///
  /// Not all items will have a column assigned. A returned value of `0` indicates the column is not applicable.
  ///
  /// ## Returns
  ///
  /// - `int`: one-based column index, or `0` when not assigned.
  int get column {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostItem',
      'getColumn',
    );

    return resultString['result'];
  }

  /// Connection information describing the relationship of this item to adjacent sign elements.
  ///
  /// ## Returns
  ///
  /// - [SignpostConnectionInfo]: the connection type for the item.
  SignpostConnectionInfo get connectionInfo {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostItem',
      'getConnectionInfo',
    );

    return SignpostConnectionInfoExtension.fromId(resultString['result']);
  }

  /// Phonetic transcription (phoneme) for the item text, when available.
  ///
  /// Use this value for high-quality text-to-speech rendering when present.
  ///
  /// ## Returns
  ///
  /// - `String`: phoneme string, or an empty string if not assigned.
  String get phoneme {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostItem',
      'getPhoneme',
    );

    return resultString['result'];
  }

  /// Pictogram classification for items of type [SignpostItemType.pictogram].
  ///
  /// Only valid when [type] equals [SignpostItemType.pictogram].
  ///
  /// ## Returns
  ///
  /// - [SignpostPictogramType]: pictogram type identifier.
  SignpostPictogramType get pictogramType {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostItem',
      'getPictogramType',
    );

    return SignpostPictogramTypeExtension.fromId(resultString['result']);
  }

  /// Row index for layout placement (1-based).
  ///
  /// Not all items will have a row assigned. A returned value of `0` indicates the row is not applicable.
  ///
  /// ## Returns
  ///
  /// - `int`: one-based row index, or `0` when not assigned.
  int get row {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostItem',
      'getRow',
    );

    return resultString['result'];
  }

  /// Road shield classification for route-number items.
  ///
  /// Only valid when [type] equals [SignpostItemType.routeNumber].
  ///
  /// ## Returns
  ///
  /// - [RoadShieldType]: the shield type.
  RoadShieldType get shieldType {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostItem',
      'getShieldType',
    );

    return RoadShieldTypeExtension.fromId(resultString['result']);
  }

  /// Display text for the item, when present.
  ///
  /// ## Returns
  ///
  /// - `String`: text content for the item, or an empty string if not assigned.
  String get text {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostItem',
      'getText',
    );

    return resultString['result'];
  }

  /// Semantic type of the signpost item.
  ///
  /// The type indicates whether the item is text, a pictogram, a route number, etc., and controls which
  /// additional properties are valid.
  ///
  /// ## Returns
  ///
  /// - [SignpostItemType]: the item type.
  SignpostItemType get type {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostItem',
      'getType',
    );

    return SignpostItemTypeExtension.fromId(resultString['result']);
  }

  /// Whether the item is ambiguous and should be avoided for TTS output.
  ///
  /// When `true`, the item may not be suitable for text-to-speech and callers should prefer unambiguous
  /// alternatives when generating spoken instructions.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when the item is ambiguous; otherwise `false`.
  bool get hasAmbiguity {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostItem',
      'hasAmbiguity',
    );

    return resultString['result'];
  }

  /// Whether the shield has the same level as the parent road.
  ///
  /// This flag is meaningful for road code items and indicates if the shield's importance matches the road the
  /// signpost is attached to.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when the shield level matches the parent road; otherwise `false`.
  bool get hasSameShieldLevel {
    final OperationResult resultString = objectMethod(
      pointerId,
      'SignpostItem',
      'hasSameShieldLevel',
    );

    return resultString['result'];
  }
}
