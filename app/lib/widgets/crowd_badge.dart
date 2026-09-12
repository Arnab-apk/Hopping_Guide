import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../utils/responsive.dart';

class CrowdBadge extends StatelessWidget {
  const CrowdBadge({super.key, required this.crowdLevel});

  final String? crowdLevel;

  @override
  Widget build(BuildContext context) {
    final level = (crowdLevel ?? 'medium').toLowerCase();

    Color bgColor;
    Color fgColor;
    String text;
    IconData icon;

    switch (level) {
      case 'low':
        bgColor = PujaColors.crowdLow.withValues(alpha: 0.15);
        fgColor = PujaColors.crowdLow;
        text = 'Low Crowd';
        icon = Icons.check_circle_outline;
        break;
      case 'high':
        bgColor = PujaColors.crowdHigh.withValues(alpha: 0.15);
        fgColor = PujaColors.crowdHigh;
        text = 'Heavy Crowd';
        icon = Icons.error_outline;
        break;
      case 'medium':
      default:
        bgColor = PujaColors.crowdMedium.withValues(alpha: 0.15);
        fgColor = PujaColors.crowdMedium;
        text = 'Moderate';
        icon = Icons.people_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fgColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.dynamicIcon(13.5), color: fgColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: fgColor,
              fontSize: context.dynamicFont(11.5),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
