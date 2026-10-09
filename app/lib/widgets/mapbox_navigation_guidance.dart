import 'package:flutter/material.dart';

import '../services/live_tracking_enhancements.dart';
import '../services/routing_service.dart';

/// Maneuvers and remaining walking time, refreshed independently of the map.
class MapboxNavigationGuidance extends StatelessWidget {
  const MapboxNavigationGuidance({super.key, required this.route});
  final WalkingRoute route;

  @override
  Widget build(BuildContext context) {
    if (route.steps.isEmpty || route.isFallback || !route.isWalk) {
      return const SizedBox.shrink();
    }
    final tracking = LiveTrackingEngine.instance;
    return ListenableBuilder(
      listenable: tracking,
      builder: (context, _) {
        final active = identical(tracking.activeRoute, route);
        final guidance = active ? tracking.guidance : null;
        final arrived = guidance?.arrived == true;
        final offRoute = guidance != null && guidance.deviationMeters > 30;
        final instruction = arrived
            ? 'You have arrived'
            : offRoute
            ? 'Return to the route · updating directions'
            : guidance?.step.type == 'arrive'
            ? 'Continue to ${route.destinationTitle}'
            : guidance?.step.instruction ?? 'Walking directions ready';
        final modifier = guidance?.step.modifier ?? '';
        final icon = arrived
            ? Icons.flag_rounded
            : guidance?.step.type == 'arrive'
            ? Icons.straight_rounded
            : modifier.contains('left')
            ? Icons.turn_left_rounded
            : modifier.contains('right')
            ? Icons.turn_right_rounded
            : Icons.straight_rounded;
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      instruction,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (active)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: tracking.voiceEnabled
                          ? 'Mute voice guidance'
                          : 'Enable voice guidance',
                      onPressed: tracking.toggleVoiceGuidance,
                      icon: Icon(
                        tracking.voiceEnabled
                            ? Icons.volume_up_rounded
                            : Icons.volume_off_rounded,
                        size: 20,
                      ),
                    ),
                ],
              ),
              Text(
                guidance == null
                    ? 'Directions by Mapbox · Preview'
                    : arrived
                    ? 'Directions by Mapbox'
                    : '${guidance.distanceToTurnMeters.round()} m to turn · ${(guidance.remainingSeconds / 60).ceil()} min left · Mapbox',
                style: Theme.of(context).textTheme.labelSmall,
              ),
              if (active && tracking.navigationError != null)
                Text(
                  tracking.navigationError!,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
            ],
          ),
        );
      },
    );
  }
}
