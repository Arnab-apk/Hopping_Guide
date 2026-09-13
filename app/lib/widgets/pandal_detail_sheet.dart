import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../services/location_service.dart';
import '../services/pandal_user_state_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import 'crowd_badge.dart';

/// Rich Pandal Detail Sheet with real navigation, favorite & visited tracker,
/// live GPS distance, and social sharing.
class PandalDetailSheet extends StatelessWidget {
  const PandalDetailSheet({super.key, required this.pandal});

  final Pandal pandal;

  static void show(BuildContext context, Pandal pandal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        curve: Curves.easeOutCubic,
        duration: Duration(milliseconds: 320),
        reverseCurve: Curves.easeInCubic,
      ),
      builder: (context) => PandalDetailSheet(pandal: pandal),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    // Launch Google Maps navigation
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${pandal.latitude},${pandal.longitude}',
    );
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external maps app.')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error launching navigation.')),
        );
      }
    }
  }

  void _sharePandal() {
    SharePlus.instance.share(
      ShareParams(
        text: '🌟 Explore ${pandal.name} (${pandal.zone.label}) during Durga Puja 2026!\n'
            '📍 Location: https://maps.google.com/?q=${pandal.latitude},${pandal.longitude}\n'
            '🚇 Nearest Metro: ${pandal.nearestMetro ?? "Available on Map"}\n'
            'Discovered via Kolkata Puja App.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userState = context.watch<PandalUserStateService?>();
    final locationService = context.watch<LocationService?>();

    final isFav = userState?.isFavorite(pandal.id) ?? false;
    final isVis = userState?.isVisited(pandal.id) ?? false;
    final distanceLabel = locationService?.formatDistance(pandal.latitude, pandal.longitude);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black45,
            blurRadius: 25,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(999),
            ),
          ),

          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zone & Badges row
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: PujaColors.durgaRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pandal.zone.label,
                          style: const TextStyle(
                            color: PujaColors.durgaRed,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CrowdBadge(crowdLevel: pandal.crowdLevel),
                      const Spacer(),

                      // Favorite toggle with animated bounce
                      IconButton(
                        tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                        icon: AnimatedScale(
                          scale: isFav ? 1.25 : 1.0,
                          duration: const Duration(milliseconds: 240),
                          curve: Curves.easeOutBack,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              key: ValueKey(isFav),
                              color: isFav ? Colors.red : Colors.grey,
                              size: context.dynamicIcon(22),
                            ),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          userState?.toggleFavorite(pandal.id);
                        },
                      ),

                      // Share button
                      IconButton(
                        tooltip: 'Share Pandal',
                        icon: Icon(Icons.share_outlined, size: context.dynamicIcon(22)),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _sharePandal();
                        },
                      ),

                      // Close button
                      IconButton(
                        tooltip: 'Close',
                        icon: Icon(Icons.close, size: context.dynamicIcon(22)),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Pandal Name
                  Text(
                    pandal.name,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                      height: 1.22,
                    ),
                  ),

                  if (pandal.area != null && pandal.area!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      pandal.area!,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],

                  // Live GPS distance badge
                  if (distanceLabel != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: PujaColors.durgaRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: PujaColors.durgaRed.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.near_me, size: 14, color: PujaColors.durgaRed),
                          const SizedBox(width: 6),
                          Text(
                            '$distanceLabel away from your current location',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: PujaColors.durgaRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Rating, Timing & Status Bar
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.06),
                        width: 1,
                      ),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          if (pandal.rating != null && pandal.rating! > 0) ...[
                            Column(
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.star, color: PujaColors.festivalGold, size: context.dynamicIcon(18)),
                                    const SizedBox(width: 4),
                                    Text(
                                      pandal.rating!.toStringAsFixed(1),
                                      style: TextStyle(fontSize: context.dynamicFont(15), fontWeight: FontWeight.w800),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text('Rating', style: TextStyle(fontSize: context.dynamicFont(11), color: Colors.grey)),
                              ],
                            ),
                            const SizedBox(width: 24),
                          ],
                          Column(
                            children: [
                              Icon(Icons.schedule, color: Colors.grey, size: context.dynamicIcon(18)),
                              const SizedBox(height: 2),
                              Text(
                                pandal.timings,
                                style: TextStyle(fontSize: context.dynamicFont(12), fontWeight: FontWeight.w700),
                              ),
                              Text('Visiting Hours', style: TextStyle(fontSize: context.dynamicFont(11), color: Colors.grey)),
                            ],
                          ),
                          if (pandal.entryFee != null && pandal.entryFee!.isNotEmpty) ...[
                            const SizedBox(width: 24),
                            Column(
                              children: [
                                Icon(Icons.confirmation_num_outlined, color: Colors.grey, size: context.dynamicIcon(18)),
                                const SizedBox(height: 2),
                                Text(
                                  pandal.entryFee!,
                                  style: TextStyle(fontSize: context.dynamicFont(12), fontWeight: FontWeight.w700),
                                ),
                                Text('Entry', style: TextStyle(fontSize: context.dynamicFont(11), color: Colors.grey)),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Mark as Visited / Hopped Action Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isVis ? Colors.green.withValues(alpha: 0.12) : Colors.transparent,
                        foregroundColor: isVis ? Colors.green : (isDark ? Colors.white : Colors.black87),
                        side: BorderSide(
                          color: isVis ? Colors.green : (isDark ? Colors.white24 : Colors.grey.shade400),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      icon: Icon(
                        isVis ? Icons.check_circle : Icons.radio_button_unchecked,
                        color: isVis ? Colors.green : Colors.grey,
                        size: context.dynamicIcon(20),
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isVis ? 'Visited & Hopped! (Tap to unmark)' : 'Mark as Visited / Hopped',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.dynamicFont(14)),
                        ),
                      ),
                      onPressed: () async {
                        HapticFeedback.mediumImpact();
                        await userState?.toggleVisited(pandal.id);
                        if (context.mounted) {
                          final nowVisited = userState?.isVisited(pandal.id) ?? false;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                nowVisited
                                    ? '🎉 Marked ${pandal.name} as Visited!'
                                    : 'Removed ${pandal.name} from Visited list.',
                              ),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Theme / Concept Description
                  Text(
                    'Theme & Artistic Concept',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: context.dynamicFont(15.5),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    pandal.theme,
                    style: TextStyle(
                      fontSize: context.dynamicFont(14),
                      height: 1.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),

                  if (pandal.description.isNotEmpty && pandal.description != pandal.theme) ...[
                    const SizedBox(height: 12),
                    Text(
                      pandal.description,
                      style: TextStyle(
                        fontSize: context.dynamicFont(13),
                        height: 1.5,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ],

                  const SizedBox(height: 20),

                  // Transit & Metro Information
                  Text(
                    'Transit & Accessibility',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: context.dynamicFont(15.5),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 10),

                  if (pandal.nearestMetro != null && pandal.nearestMetro!.isNotEmpty)
                    _buildTransitItem(
                      context: context,
                      icon: Icons.directions_subway,
                      iconColor: PujaColors.metroBlue,
                      title: 'Nearest Metro Station',
                      value: pandal.nearestMetro!,
                      isDark: isDark,
                    ),

                  if (pandal.circularRailway != null && pandal.circularRailway!.isNotEmpty)
                    _buildTransitItem(
                      context: context,
                      icon: Icons.train_outlined,
                      iconColor: Colors.deepPurple,
                      title: 'Circular Railway / Suburban',
                      value: pandal.circularRailway!,
                      isDark: isDark,
                    ),

                  _buildTransitItem(
                    context: context,
                    icon: Icons.place_outlined,
                    iconColor: PujaColors.durgaRed,
                    title: 'GPS Coordinates',
                    value: '${pandal.latitude.toStringAsFixed(4)}, ${pandal.longitude.toStringAsFixed(4)}',
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),

                  // Navigation CTA
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: PujaColors.crimsonVelvet,
                        foregroundColor: PujaColors.goldBright,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: PujaColors.festivalGold.withValues(alpha: 0.45),
                            width: 1.2,
                          ),
                        ),
                        elevation: 4,
                      ),
                      icon: Icon(Icons.navigation_outlined, size: context.dynamicIcon(20)),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Get Turn-by-Turn Directions',
                          style: TextStyle(fontSize: context.dynamicFont(15), fontWeight: FontWeight.w800),
                        ),
                      ),
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        _openDirections(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildTransitItem({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: context.dynamicIcon(18), color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: context.dynamicFont(11),
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: context.dynamicFont(13),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
