import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'multimodal_routing_service.dart';

/// Explicit station-to-station services. Instants require offsets; serviceDate
/// is the operator's Kolkata operating date, even for post-midnight departures.
class VerifiedTransitRun {
  VerifiedTransitRun.fromJson(Map<String, dynamic> json)
    : service = json['service'] as String,
      from = json['from'] as String,
      to = json['to'] as String,
      serviceDate = json['service_date'] as String,
      departure = _instant(json['departure'] as String),
      arrival = _instant(json['arrival'] as String),
      verifiedAt = _instant(json['verified_at'] as String),
      validUntil = _instant(json['valid_until'] as String),
      source = Uri.parse(json['source_url'] as String) {
    final host = source.host.toLowerCase();
    if (source.scheme != 'https' ||
        !(host == 'indianrailways.gov.in' ||
            host.endsWith('.indianrailways.gov.in')) ||
        !arrival.isAfter(departure) ||
        validUntil.isBefore(departure) ||
        verifiedAt.isAfter(departure) ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(serviceDate) ||
        service.isEmpty ||
        from.isEmpty ||
        to.isEmpty ||
        from == to) {
      throw const FormatException('Invalid verified transit service');
    }
  }

  final String service, from, to, serviceDate;
  final DateTime departure, arrival, verifiedAt, validUntil;
  final Uri source;

  static DateTime _instant(String value) {
    if (!RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(value)) {
      throw const FormatException('Timetable instants require a timezone');
    }
    return DateTime.parse(value).toUtc();
  }

  bool matches(RouteLeg leg) => switch (leg) {
    MetroLeg m =>
      service == 'metro:${m.line.code}' &&
          from == m.entryStation.id &&
          to == m.exitStation.id,
    TrainLeg t =>
      service == 'train:${t.corridorName}' &&
          from == t.entryStation.code &&
          to == t.exitStation.code,
    _ => false,
  };
}

class ReturnHomeCheck {
  const ReturnHomeCheck({required this.runs, this.leaveBy, this.reason});
  final List<VerifiedTransitRun> runs;
  final DateTime? leaveBy;
  final String? reason;
}

class ReturnHomeService {
  static const homeKey = 'return_home_station_v1';
  static const bufferKey = 'return_home_buffer_v1';

  static Future<List<VerifiedTransitRun>> loadTimetable() async {
    final json = jsonDecode(
      await rootBundle.loadString('assets/data/verified_transit_runs.json'),
    ) as Map<String, dynamic>;
    return (json['runs'] as List)
        .map((e) => VerifiedTransitRun.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> save(String stationId, int bufferMinutes) async {
    if (bufferMinutes < 5 || bufferMinutes > 60) {
      throw ArgumentError.value(bufferMinutes, 'bufferMinutes');
    }
    final prefs = await SharedPreferences.getInstance();
    if (!await prefs.setString(homeKey, stationId) ||
        !await prefs.setInt(bufferKey, bufferMinutes)) {
      throw StateError('Could not save return preferences');
    }
  }

  /// Walk backwards through explicit departures, including transfer walks and
  /// a boarding buffer at every boarding. Never infer a service from line hours.
  static ReturnHomeCheck check({
    required MultimodalRoute route,
    required List<VerifiedTransitRun> timetable,
    required String serviceDate,
    required DateTime now,
    Duration buffer = const Duration(minutes: 20),
  }) {
    if (buffer.isNegative) throw ArgumentError.value(buffer, 'buffer');
    if (route.isFallback ||
        route.legs.any((l) => l is WalkLeg && l.isFallback)) {
      return const ReturnHomeCheck(
        runs: [],
        reason: 'Street directions are unavailable. Retry with a connection.',
      );
    }
    if (!route.legs.any((l) => l is MetroLeg || l is TrainLeg)) {
      return const ReturnHomeCheck(
        runs: [],
        reason:
            'This route uses no public transport. Journey time is estimated.',
      );
    }
    DateTime? deadline;
    final selected = <VerifiedTransitRun>[];
    for (final leg in route.legs.reversed) {
      if (leg is MetroLeg || leg is TrainLeg) {
        final options =
            timetable
                .where(
                  (r) =>
                      r.matches(leg) &&
                      r.serviceDate == serviceDate &&
                      !r.verifiedAt.isAfter(now) &&
                      !r.validUntil.isBefore(now) &&
                      (deadline == null || !r.arrival.isAfter(deadline)),
                )
                .toList()
              ..sort((a, b) => b.departure.compareTo(a.departure));
        if (options.isEmpty) {
          return ReturnHomeCheck(
            runs: const [],
            reason:
                'No verified connecting service for ${leg.instructions} on $serviceDate. '
                'Do not rely on this route for the last train.',
          );
        }
        final run = options.first;
        selected.insert(0, run);
        deadline = run.departure.subtract(buffer);
      } else if (deadline != null) {
        deadline = deadline.subtract(
          Duration(seconds: leg.durationSeconds.ceil()),
        );
      }
    }
    return ReturnHomeCheck(
      runs: selected,
      leaveBy: deadline,
      reason: deadline!.isBefore(now)
          ? 'The leave-by time has passed. Choose another return option.'
          : null,
    );
  }
}
