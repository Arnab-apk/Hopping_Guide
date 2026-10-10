import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../services/navigation_session.dart';

class NavigationOverlay extends StatelessWidget {
  const NavigationOverlay({
    super.key,
    required this.session,
    required this.onStart,
    required this.onEnd,
    required this.onRecenter,
  });
  final NavigationSession session;
  final VoidCallback onStart, onEnd, onRecenter;
  static const card = Color(0xFF1F1F23),
      text = Color(0xFFF2F2F3),
      muted = Color(0xFF8C8C93);

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Stack(
      children: [
        if (session.active)
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: _card(
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0x14FFFFFF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Transform.rotate(
                      angle: session.arrowRotation * math.pi / 180,
                      child: Icon(
                        session.state == NavigationState.arrived
                            ? Icons.flag_rounded
                            : Icons.arrow_upward_rounded,
                        color: const Color(0xFFE0443E),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          session.title,
                          style: const TextStyle(
                            color: text,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (session.state != NavigationState.arrived)
                          Text(
                            'in ${navigationDistance(session.guidance?.step.type == 'depart' ? 0 : session.guidance?.distanceToTurnMeters ?? 0)}',
                            style: const TextStyle(color: muted, fontSize: 14),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: session.live
                          ? const Color(0xFF1C3A2F)
                          : const Color(0xFF3A2F1C),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      session.live ? '● Live' : 'Searching…',
                      style: TextStyle(
                        fontSize: 12,
                        color: session.live
                            ? const Color(0xFF3ECF8E)
                            : const Color(0xFFF2B632),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (session.active && !session.following)
          Positioned(
            right: 16,
            bottom: 136,
            child: IconButton.filled(
              tooltip: 'Recenter',
              onPressed: onRecenter,
              style: IconButton.styleFrom(
                backgroundColor: card,
                foregroundColor: const Color(0xFF2F6FE4),
                minimumSize: const Size(48, 48),
              ),
              icon: const Icon(Icons.my_location),
            ),
          ),
        Positioned(
          bottom: 12,
          left: 16,
          right: 16,
          child: _card(
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${session.etaMinutes} min',
                            style: const TextStyle(
                              color: text,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${(session.remainingMeters / 1000).toStringAsFixed(1)} km left',
                            style: const TextStyle(color: muted, fontSize: 14),
                          ),
                          Text(
                            'to ${session.route?.destinationTitle ?? 'Destination'}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: muted, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (session.hasPreview)
                      FilledButton(
                        onPressed: session.starting ? null : onStart,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE0443E),
                        ),
                        child: Text(session.starting ? 'Starting…' : 'Start'),
                      )
                    else
                      TextButton(
                        onPressed: onEnd,
                        style: TextButton.styleFrom(
                          backgroundColor: const Color(0x26E0443E),
                          foregroundColor: const Color(0xFFF0877F),
                          minimumSize: const Size(64, 48),
                        ),
                        child: const Text('End'),
                      ),
                    if (session.hasPreview)
                      IconButton(
                        tooltip: 'Close route preview',
                        onPressed: onEnd,
                        icon: const Icon(Icons.close, color: muted),
                      ),
                  ],
                ),
                if (session.active)
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      tooltip: session.engine.voiceEnabled
                          ? 'Mute voice guidance'
                          : 'Enable voice guidance',
                      onPressed: session.engine.toggleVoiceGuidance,
                      icon: Icon(
                        session.engine.voiceEnabled
                            ? Icons.volume_up
                            : Icons.volume_off,
                        color: muted,
                      ),
                    ),
                  ),
                if (session.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      session.error!,
                      style: const TextStyle(
                        color: Color(0xFFF0877F),
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: Colors.black45, blurRadius: 16, offset: Offset(0, 6)),
      ],
    ),
    child: child,
  );
}
