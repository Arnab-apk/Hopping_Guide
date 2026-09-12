import 'package:flutter/material.dart';

/// P0: pandal detail — name, area, theme, timings, photo, description.
/// Receives a pandal id via route arg (or modal) and loads from Firestore.
class PandalDetailScreen extends StatelessWidget {
  const PandalDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pandal detail')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Pandal detail — wired in Week 2.\n\n'
            'Photo, theme, timings, description, nearest metro (P1).',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
