// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:magiclane_maps_flutter/src/core/private/gem_autorelease_object.dart';
import 'package:magiclane_maps_flutter/src/gem_kit_platform_interface.dart';
import 'package:meta/meta.dart';

/// Public transport route.
///
/// Represents a computed public transport route and exposes public-transit specific
/// information such as fare, service frequency and ticket purchase details. Obtain
/// a [PTRoute] by converting a computed [Route] using [Route.toPTRoute] when the
/// route's transport mode is public transit.
///
/// ## See also:
///
/// - [Route.toPTRoute] - convert a computed route to a [PTRoute]
/// - [PTRouteSegment] - segments specific to public transit routes.
///
/// {@category Route}
class PTRoute extends RouteBase {
  @internal
  PTRoute.init(super.id) : super.init();

  /// Public transport fare for the route.
  ///
  /// Returns a localized fare string when available. This getter is nullable and
  /// returns `null` when no fare information is provided by the data source.
  ///
  /// ## Returns
  ///
  /// - [String?]: A localized fare description or `null` if unavailable.
  String? get publicTransportFare {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRoute',
      'getPTFare',
    );

    final dynamic result = resultString['result'];

    return (result == null || result is! String || result.isEmpty)
        ? null
        : result;
  }

  /// Frequency indicator for the public transport route.
  ///
  /// ## Returns
  ///
  /// - `int`: The reported frequency value for this route.
  int get publicTransportFrequency {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRoute',
      'getPTFrequency',
    );

    return resultString['result'];
  }

  /// Whether the computed public-transit solution respects all provided preferences.
  ///
  /// Returns `true` when the route satisfies constraints such as accessibility,
  /// maximum walking distance, and other routing preferences supplied to the
  /// routing engine.
  ///
  /// ## Returns
  ///
  /// - `bool`: `true` when all preferences are met, otherwise `false`.
  bool get publicTransportRespectsAllConditions {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRoute',
      'getPTRespectsAllConditions',
    );

    return resultString['result'];
  }

  /// Number of buy-ticket information entries available for this route.
  ///
  /// Use [getBuyTicketInformation] to retrieve each [PTBuyTicketInformation] by
  /// index.
  ///
  /// ## Returns
  ///
  /// - `int`: Number of available [PTBuyTicketInformation] records.
  ///
  /// ## See also:
  ///
  /// - [getBuyTicketInformation] - retrieve buy-ticket information by index.
  int get countBuyTicketInformation {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRoute',
      'getCountBuyTicketInformation',
    );

    return resultString['result'];
  }

  /// Retrieve buy-ticket information by index.
  ///
  /// ## Parameters
  ///
  /// - [index]: Zero-based index of the buy-ticket information to retrieve.
  ///
  /// ## Returns
  ///
  /// - [PTBuyTicketInformation]: The buy-ticket information object, or `null`
  ///   when the index is out of bounds.
  ///
  /// ## See also:
  ///
  /// - [countBuyTicketInformation] - get the number of available buy-ticket information entries.
  PTBuyTicketInformation? getBuyTicketInformation(final int index) {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTRoute',
      'getBuyTicketInformation',
      args: index,
    );

    if (resultString['result'] == -1) {
      return null;
    }

    return PTBuyTicketInformation(resultString['result']);
  }
}

/// Buy-ticket information for a public transport route.
///
/// Holds a URL and references to the parts of the route solution affected by
/// the ticket offer. Instances are returned by [PTRoute.getBuyTicketInformation].
///
/// {@category Route}
class PTBuyTicketInformation extends GemAutoreleaseObject {
  PTBuyTicketInformation(super.id);

  /// URL where a ticket can be purchased for this route/offer.
  ///
  /// ## Returns
  ///
  /// - `String`: A URL string for buying tickets related to this entry.
  String get buyTicketURL {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTBuyTicketInformation',
      'getBuyTicketURL',
    );

    return resultString['result'];
  }

  /// Indexes of the route solution parts affected by this ticket offer.
  ///
  /// ## Returns
  ///
  /// - `List<int>`: Zero-based indexes identifying affected parts of the route solution.
  List<int> get solutionPartIndexes {
    final OperationResult resultString = objectMethod(
      pointerId,
      'PTBuyTicketInformation',
      'getSolutionPartIndexes',
    );

    return List<int>.from(resultString['result']);
  }
}
