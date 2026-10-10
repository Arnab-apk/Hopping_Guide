import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import '../models/navigation_step.dart';
import '../utils/haversine.dart';

class MapboxRoutingException extends StateError {
  MapboxRoutingException(super.message, {this.statusCode, this.code});
  final int? statusCode;
  final String? code;
}

class MapboxRouteData {
  const MapboxRouteData(
    this.points,
    this.steps,
    this.distanceMeters,
    this.durationSeconds,
  );
  final List<LatLng> points;
  final List<NavigationStep> steps;
  final double distanceMeters;
  final double durationSeconds;
}

/// Directions v5, using pedestrian paths and visiting stops in supplied order.
class MapboxDirectionsService {
  MapboxDirectionsService({required this.client, required String accessToken})
    : _accessToken = accessToken.trim();
  final http.Client client;
  final String _accessToken;
  bool get isConfigured => _accessToken.isNotEmpty;

  Future<MapboxRouteData> walking(List<LatLng> waypoints) =>
      directions(waypoints);
  Future<MapboxRouteData> driving(List<LatLng> waypoints) =>
      directions(waypoints, driving: true);
  Future<MapboxRouteData> directions(
    List<LatLng> waypoints, {
    bool driving = false,
  }) async {
    if (!isConfigured) {
      throw MapboxRoutingException('Walking navigation is not configured.');
    }
    if (waypoints.length < 2) {
      throw ArgumentError('At least two stops are required');
    }
    for (final point in waypoints) {
      if (!point.latitude.isFinite ||
          !point.longitude.isFinite ||
          point.latitude.abs() > 90 ||
          point.longitude.abs() > 180) {
        throw ArgumentError('Invalid route coordinates');
      }
    }
    final points = <LatLng>[];
    final steps = <NavigationStep>[];
    double distance = 0, duration = 0;
    // Mapbox permits 25 coordinates per request. Share a boundary stop so
    // longer trails retain every stop and never become a disconnected route.
    for (var start = 0; start < waypoints.length - 1; start += 24) {
      final end = (start + 25).clamp(0, waypoints.length);
      final part = await _request(
        waypoints.sublist(start, end),
        driving: driving,
      );
      final overlap = points.isNotEmpty && points.last == part.points.first;
      final offset = points.length - (overlap ? 1 : 0);
      points.addAll(overlap ? part.points.skip(1) : part.points);
      steps.addAll(
        part.steps
            .where(
              (step) =>
                  !(start > 0 && step.type == 'depart') &&
                  !(end < waypoints.length && step.type == 'arrive'),
            )
            .map(
              (step) => step.withPointIndex(
                step.pointIndex + offset,
                legOffset: start,
              ),
            ),
      );
      distance += part.distanceMeters;
      duration += part.durationSeconds;
    }
    return MapboxRouteData(points, steps, distance, duration);
  }

  Future<MapboxRouteData> _request(
    List<LatLng> waypoints, {
    bool driving = false,
  }) async {
    final coordinates = waypoints
        .map((p) => '${p.longitude},${p.latitude}')
        .join(';');
    final uri = Uri.https(
      'api.mapbox.com',
      '/directions/v5/mapbox/${driving ? 'driving-traffic' : 'walking'}/$coordinates',
      {
        'access_token': _accessToken,
        'steps': 'true',
        'geometries': 'geojson',
        'overview': 'full',
        'language': 'en',
        'alternatives': 'false',
        'continue_straight': 'false',
      },
    );
    http.Response response;
    try {
      response = await client
          .get(uri, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
    } on TimeoutException {
      throw MapboxRoutingException(
        'Street directions timed out. Please try again.',
      );
    } catch (_) {
      // ClientException can contain the entire URI, including the token.
      throw MapboxRoutingException(
        'Could not reach street directions. Check your connection.',
      );
    }
    if (response.statusCode != 200) {
      final message = switch (response.statusCode) {
        401 || 403 => 'Street directions access was denied. Please check the Mapbox token configuration.',
        429 =>
          'Street directions are busy. Please wait a moment and try again.',
        _ => 'Street directions are temporarily unavailable. Please try again.',
      };
      throw MapboxRoutingException(message, statusCode: response.statusCode);
    }
    try {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      if (data['code'] != 'Ok') {
        throw MapboxRoutingException(
          'No street route was found between these stops.',
          code: data['code'] as String?,
        );
      }
      final route = (data['routes'] as List).first as Map<String, dynamic>;
      final coordinates = (route['geometry'] as Map)['coordinates'] as List;
      final points = coordinates.map((value) {
        final pair = value as List;
        final lat = (pair[1] as num).toDouble(),
            lon = (pair[0] as num).toDouble();
        if (!lat.isFinite ||
            !lon.isFinite ||
            lat.abs() > 90 ||
            lon.abs() > 180) {
          throw const FormatException('Invalid route geometry');
        }
        return LatLng(lat, lon);
      }).toList();
      if (points.length < 2) throw const FormatException('Empty route');
      final distance = (route['distance'] as num).toDouble();
      final duration = (route['duration'] as num).toDouble();
      if (!distance.isFinite ||
          !duration.isFinite ||
          distance < 0 ||
          duration < 0) {
        throw const FormatException('Invalid route totals');
      }
      final steps = <NavigationStep>[];
      var cursor = 0;
      var legIndex = 0;
      for (final leg in route['legs'] as List) {
        for (final raw in (leg as Map)['steps'] as List) {
          final step = raw as Map;
          final maneuver = step['maneuver'] as Map;
          final location = maneuver['location'] as List;
          var best = cursor;
          var bestDistance = double.infinity;
          for (var i = cursor; i < points.length; i++) {
            final d = haversineMeters(
              (location[1] as num).toDouble(),
              (location[0] as num).toDouble(),
              points[i].latitude,
              points[i].longitude,
            );
            if (d < bestDistance) {
              best = i;
              bestDistance = d;
            }
            if (d < 0.1) break;
          }
          cursor = best;
          steps.add(
            NavigationStep(
              instruction: maneuver['instruction'] as String,
              pointIndex: best,
              distanceMeters: (step['distance'] as num).toDouble(),
              durationSeconds: (step['duration'] as num).toDouble(),
              type: maneuver['type'] as String,
              modifier: maneuver['modifier'] as String?,
              roadName: step['name'] as String? ?? '',
              legIndex: legIndex,
              exit: (maneuver['exit'] as num?)?.toInt(),
            ),
          );
        }
        legIndex++;
      }
      if (steps.isEmpty) throw const FormatException('Missing maneuvers');
      return MapboxRouteData(points, steps, distance, duration);
    } on MapboxRoutingException {
      rethrow;
    } catch (_) {
      throw MapboxRoutingException(
        'Street directions returned an incomplete route. Please try again.',
      );
    }
  }
}
