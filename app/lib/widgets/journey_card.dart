import 'package:flutter/material.dart';

import '../services/journey_session.dart';
import '../services/multimodal_routing_service.dart';

class JourneyCard extends StatelessWidget {
  const JourneyCard({
    super.key,
    required this.session,
    required this.onDirections,
    required this.onTransitArrival,
    required this.onDetails,
    required this.onClose,
  });
  final JourneySession session;
  final VoidCallback onDirections, onTransitArrival, onDetails, onClose;

  @override
  Widget build(BuildContext context) {
    final leg = session.leg!;
    final walk = leg is WalkLeg;
    final exit = leg is MetroLeg
        ? leg.exitStation.name
        : leg is TrainLeg
        ? leg.exitStation.name
        : '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Next: ${session.target!.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Close journey',
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Text(
              leg.instructions,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            if (!walk)
              const Text(
                'Estimated journey · check station service information',
                style: TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: walk ? onDirections : onTransitArrival,
                  icon: Icon(walk ? Icons.navigation : Icons.train),
                  label: Text(
                    walk ? 'Turn-by-turn directions' : 'I’m at $exit',
                  ),
                ),
                TextButton(
                  onPressed: onDetails,
                  child: const Text('Full itinerary'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
