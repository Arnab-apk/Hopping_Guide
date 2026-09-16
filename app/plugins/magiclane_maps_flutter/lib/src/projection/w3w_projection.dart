// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'dart:convert';

import 'package:magiclane_maps_flutter/magiclane_maps_flutter.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';

/// What3Words (W3W) projection representation.
///
/// Wraps a three-word address representation (What3Words) used to
/// reference locations via string tokens.
///
/// [ProjectionService.convert] works with W3WProjection only if the
/// W3WProjection object has a valid token that can be obtained from what3words.com.
///
/// {@category Projections}
class W3WProjection extends Projection {
  /// Creates a [W3WProjection] from a three-words token.
  ///
  /// ## Parameters
  ///
  /// - [threeWords]: (String) The three-words token identifying the location.
  factory W3WProjection(String threeWords) {
    return W3WProjection._create(threeWords);
  }
  W3WProjection.init(super.id) : super.init();

  static W3WProjection _create(String token) {
    final String resultString = GemKitPlatform.instance.callCreateObject(
      jsonEncode(<String, dynamic>{
        'class': 'Projection_W3W',
        'args': <String, dynamic>{'token': token},
      }),
    );
    final dynamic decodedVal = jsonDecode(resultString);
    final W3WProjection retVal = W3WProjection.init(decodedVal['result']);
    return retVal;
  }

  /// Set the What3Words API token used by this projection instance.
  ///
  /// ## Parameters
  ///
  /// - [token]: (String) Token obtained from What3Words services.
  set token(String token) {
    objectMethod(pointerId, 'Projection_W3W', 'setToken', args: token);
  }

  /// Set the three-words string that represents the location.
  ///
  /// ## Parameters
  ///
  /// - [words]: (String) Three words identifying a location.
  set words(String words) {
    objectMethod(pointerId, 'Projection_W3W', 'setWords', args: words);
  }

  /// The three-word address.
  ///
  /// ## Returns
  ///
  /// - (String) The three-word identifier for this W3W projection.
  String get words {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_W3W',
      'getWords',
    );

    return resultString['result'];
  }

  /// The stored What3Words token.
  ///
  /// ## Returns
  ///
  /// - (String) The token string associated with this projection.
  String get token {
    final OperationResult resultString = objectMethod(
      pointerId,
      'Projection_W3W',
      'getToken',
    );

    return resultString['result'];
  }
}
