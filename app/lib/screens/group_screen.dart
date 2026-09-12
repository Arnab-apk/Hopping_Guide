import 'package:flutter/material.dart';

/// P0: create/join a group via shareable code or deep link, then share live
/// location with members. The background location service (hardest, most
/// failure-prone piece — give it a dedicated owner, per the plan) belongs in
/// Week 3.
class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My group')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Groups + live location — wired in Week 3.\n\n'
            'Create/join by code, share position to Realtime DB, render live pins.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
