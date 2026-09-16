// SPDX-FileCopyrightText: 2025-2026 Magic Lane International B.V. <info@magiclane.com>
// SPDX-License-Identifier: LicenseRef-MagicLane-Proprietary
//
// For the latest licensing terms and conditions, see https://www.magiclane.com/web/terms-and-conditions#terms-of-service.
// For further information use the contact form at https://www.magiclane.com/web/contact.

import 'package:magiclane_maps_flutter/core.dart';
import 'package:meta/meta.dart';

/// Public transport agency information.
///
/// Holds identifying metadata for a transit agency: numeric id, display
/// name and an optional website URL.
///
/// Is provided as part of [PTStopInfo.agencies].
///
/// ## Also see:
///
/// - [PTStopInfo.agencies] — The list of agencies for a stop info.
/// - [PTTrip.agency] — The agency operating a specific trip.
///
/// {@category Maps & 3D Scenes}
class PTAgency {
  /// Create a [PTAgency].
  ///
  /// API users do not typically create instances of this class directly.
  /// Get instances from [PTStopInfo.agencies].
  ///
  /// ## Parameters
  ///
  /// - [id]: (int) Numeric agency identifier.
  /// - [name]: (String) Agency display name.
  /// - [url]: (String?) Optional agency website URL.
  PTAgency({required this.id, required this.name, this.url});

  /// Builds a [PTAgency] from a [GemParameter].
  factory PTAgency._build(List<GemParameter> param) {
    final Map<String, dynamic> map = <String, dynamic>{};

    for (final GemParameter el in param) {
      map[el.key!] = el.value;
    }

    return PTAgency(
      id: map['agency_id'] as int,
      name: map['agency_name'] as String,
      url: map['agency_url'] as String?, // This can be null
    );
  }

  /// Numeric agency identifier.
  final int id;

  /// The agency display name.
  final String name;

  /// Optional agency website URL.
  final String? url;

  /// Builds a list of [PTAgency] from a list of [GemParameter].
  ///
  /// API users should not call this method directly.
  @internal
  static List<PTAgency> buildAgencies(List<GemParameter> paramList) {
    final List<PTAgency> agencies = <PTAgency>[];

    for (final GemParameter param in paramList) {
      final ParameterList agencyParam = param.value;
      agencies.add(PTAgency._build(agencyParam.toList()));
    }

    return agencies;
  }
}
