import 'package:flutter/material.dart';

/// Explains feature availability without blocking access to working features.
class FeatureStatusNotice {
  const FeatureStatusNotice._();

  static void show(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline_rounded),
            SizedBox(width: 8),
            Text('Feature status'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatusRow(
                label: 'Available now',
                details: 'Pandal directory, search, route preview, metro, food spots, and helplines.',
                color: Colors.green,
              ),
              SizedBox(height: 14),
              _StatusRow(
                label: 'Coming soon',
                details: 'Reliable live map tiles, full live navigation progress, and offline map coverage are still being improved.',
                color: Colors.orange,
              ),
              SizedBox(height: 14),
              _StatusRow(
                label: 'Limited for now',
                details: 'Cloud chatbot answers, real-time squad sync, background notifications, and advanced crowd data may fall back or be unavailable.',
                color: Colors.blue,
              ),
              SizedBox(height: 14),
              Text(
                'We will enable these features as they become reliable. '
                'Your saved pandals and basic route information remain available.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.details,
    required this.color,
  });

  final String label;
  final String details;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(Icons.circle, size: 10, color: color),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: details),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
