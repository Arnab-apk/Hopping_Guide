import 'package:flutter/foundation.dart';

import '../models/pandal.dart';
import 'multimodal_routing_service.dart';
import 'routing_service.dart';

/// Keeps boarding/alighting instructions between individual walking sessions.
class JourneySession extends ChangeNotifier {
  static final instance = JourneySession();
  List<Pandal> stops = const [];
  List<MultimodalRoute> routes = const [];
  int stopIndex = 0;
  int legIndex = 0;
  bool walking = false;
  bool get active => stopIndex < routes.length;
  Pandal? get target => active ? stops[stopIndex] : null;
  MultimodalRoute? get route => active ? routes[stopIndex] : null;
  RouteLeg? get leg => active ? route!.legs[legIndex] : null;

  void load(List<Pandal> targets, List<MultimodalRoute> journeys) {
    if (targets.length != journeys.length ||
        journeys.any((r) => r.legs.isEmpty)) {
      throw ArgumentError('Each stop needs a connected journey.');
    }
    stops = List.unmodifiable(targets);
    routes = List.unmodifiable(journeys);
    stopIndex = legIndex = 0;
    walking = false;
    _skipEmptyWalks();
    notifyListeners();
  }

  WalkingRoute? get walkingRoute {
    final current = leg;
    if (current is! WalkLeg || current.isFallback || current.steps.isEmpty) {
      return null;
    }
    return WalkingRoute(
      points: current.points,
      distanceMeters: current.distanceMeters,
      durationSeconds: current.durationSeconds,
      steps: current.steps,
      customTitle: current.instructions,
      targetPandal: legIndex == route!.legs.length - 1 ? target : null,
      waypoints: [current.startPoint, current.endPoint],
    );
  }

  void beginWalking() {
    walking = true;
    notifyListeners();
  }

  void cancelWalking() {
    walking = false;
    notifyListeners();
  }

  /// Returns the completed pandal only after the final leg of its journey.
  Pandal? advance() {
    if (!active) return null;
    walking = false;
    Pandal? completed;
    legIndex++;
    if (legIndex >= route!.legs.length) {
      completed = target;
      stopIndex++;
      legIndex = 0;
    }
    _skipEmptyWalks();
    notifyListeners();
    return completed;
  }

  void _skipEmptyWalks() {
    while (active &&
        leg is WalkLeg &&
        (leg as WalkLeg).distanceMeters < 10 &&
        legIndex < route!.legs.length - 1) {
      legIndex++;
    }
  }

  void end() {
    walking = false;
    stops = const [];
    routes = const [];
    stopIndex = legIndex = 0;
    notifyListeners();
  }
}
