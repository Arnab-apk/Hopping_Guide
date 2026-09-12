import 'package:flutter/material.dart';

/// P0: browse/filter pandals by zone, sorted by distance from device GPS.
/// TODO(Week 2): wire PandalRepository + LocationService; render a list of
/// [PandalCard]s with a zone filter chip bar and nearest-first sorting.
class PandalListScreen extends StatelessWidget {
  const PandalListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pandals')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Pandal list — wired in Week 2.\n\n'
            'Zone filter + nearest-first sort live here.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
