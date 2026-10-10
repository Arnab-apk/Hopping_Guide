import 'package:flutter/material.dart';

Future<bool> offerTrailNavigation(
  BuildContext context,
  String nextStop,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Your trail is ready'),
        content: Text(
          'Get turn-by-turn directions toward $nextStop. '
          'The itinerary includes station access, train or metro rides, and the final walk to the pandal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Later'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.navigation),
            label: const Text('Get directions'),
          ),
        ],
      ),
    ) ??
    false;
