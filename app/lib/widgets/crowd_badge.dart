import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/theme.dart';
import '../utils/responsive.dart';

/// Material 3 Status Capsule indicating crowd density (inspired by Google Maps busy-ness indicator).
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
        bgColor = PujaColors.crowdLow.withValues(alpha: 0.12);
        fgColor = PujaColors.crowdLow;
        text = 'Low Crowd';
        icon = Icons.check_circle_rounded;
        break;
      case 'high':
        bgColor = PujaColors.crowdHigh.withValues(alpha: 0.12);
        fgColor = PujaColors.crowdHigh;
        text = 'Heavy Crowd';
        icon = Icons.warning_amber_rounded;
        break;
      case 'medium':
      default:
        bgColor = PujaColors.crowdMedium.withValues(alpha: 0.12);
        fgColor = PujaColors.crowdMedium;
        text = 'Moderate';
        icon = Icons.groups_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: fgColor.withValues(alpha: 0.25), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.dynamicIcon(13.0), color: fgColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: fgColor,
              fontSize: context.dynamicFont(11),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
