import 'package:flutter/material.dart';

import '../screens/group_video_call_screen.dart';

/// A labelled call entry point with a generous touch target.
class GroupVideoCallButton extends StatelessWidget {
  const GroupVideoCallButton({
    super.key,
    required this.squadId,
    required this.squadName,
  });

  final String squadId;
  final String squadName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 48),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          icon: const Icon(Icons.video_call_rounded),
          label: const Text('Group video call', textAlign: TextAlign.center),
          onPressed: () => GroupVideoCallScreen.open(
            context,
            squadId: squadId,
            squadName: squadName,
          ),
        ),
      ),
    );
  }
}
