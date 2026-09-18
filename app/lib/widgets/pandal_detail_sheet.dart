import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../config/theme.dart';
import '../models/pandal.dart';
import '../screens/map_screen.dart';
import '../services/location_service.dart';
import '../services/pandal_user_state_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import 'crowd_badge.dart';
import 'puja_icons.dart';

/// Minimalist, beautifully proportioned Pandal Detail Sheet.
/// Features clean typography, consolidated transit card, inline distance badge,
/// smooth micro-actions, and integrated in-app walking route.
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

  void _sharePandal() {
    SharePlus.instance.share(
      ShareParams(
        text: '🌟 Explore ${pandal.name} (${pandal.zone.label}) during Durga Puja 2026!\n'
            '📍 Location: https://maps.google.com/?q=${pandal.latitude},${pandal.longitude}\n'
            '🚇 Nearest Metro: ${pandal.nearestMetro ?? "Available on Map"}\n'
            'Discovered via Pujo Parikrama App.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isFav = context.select<PandalUserStateService?, bool>(
      (s) => s?.isFavorite(pandal.id) ?? false,
    );
    final isVis = context.select<PandalUserStateService?, bool>(
      (s) => s?.isVisited(pandal.id) ?? false,
    );
    final distanceLabel = context.select<LocationService?, String?>(
      (loc) => loc?.formatDistance(pandal.latitude, pandal.longitude),
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141415) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar: Zone & Crowd on Left, Action Circles on Right
                    Row(
                      children: [
                        // Zone Tag
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8.5, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: PujaColors.durgaRed.withValues(alpha: isDark ? 0.22 : 0.08),
                            borderRadius: BorderRadius.circular(7),
                            border: Border.all(
                              color: PujaColors.durgaRed.withValues(alpha: isDark ? 0.35 : 0.20),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            pandal.zone.label.toUpperCase(),
                            style: const TextStyle(
                              color: PujaColors.durgaRed,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CrowdBadge(crowdLevel: pandal.crowdLevel),
                        const Spacer(),

                        // Action Buttons: Favorite, Share, Close
                        _buildCircleButton(
                          tooltip: isFav ? 'Remove favorite' : 'Add favorite',
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            context.read<PandalUserStateService?>()?.toggleFavorite(pandal.id);
                          },
                          child: AnimatedScale(
                            scale: isFav ? 1.2 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutBack,
                            child: isFav
                                ? PujaIcon.kalash(
                                    size: 26,
                                    color: PujaColors.festivalGold,
                                  )
                                : Icon(
                                    Icons.bookmark_border_rounded,
                                    color: isDark ? Colors.white70 : Colors.black54,
                                    size: 24,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildCircleButton(
                          tooltip: 'Share pandal',
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _sharePandal();
                          },
                          child: Icon(
                            Icons.share_outlined,
                            color: isDark ? Colors.white70 : Colors.black54,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        _buildCircleButton(
                          tooltip: 'Close',
                          isDark: isDark,
                          onTap: () {
                            HapticFeedback.selectionClick();
                            Navigator.of(context).pop();
                          },
                          child: Icon(
                            Icons.close_rounded,
                            color: isDark ? Colors.white70 : Colors.black54,
                            size: 18,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Pandal Name
                    Text(
                      pandal.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: context.dynamicFont(19),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                        height: 1.2,
                        color: isDark ? Colors.white : const Color(0xFF1A1A1A),
                      ),
                    ),

                    const SizedBox(height: 5),

                    // Inline Subtitle: Area & Distance
                    Row(
                      children: [
                        if (pandal.area != null && pandal.area!.isNotEmpty) ...[
                          Text(
                            pandal.area!,
                            style: TextStyle(
                              fontSize: context.dynamicFont(13),
                              fontWeight: FontWeight.w500,
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                        if (distanceLabel != null) ...[
                          if (pandal.area != null && pandal.area!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ),
                          const Icon(
                            Icons.near_me_rounded,
                            size: 12,
                            color: PujaColors.durgaRed,
                          ),
                          const SizedBox(width: 3.5),
                          Text(
                            '$distanceLabel away',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PujaColors.durgaRed,
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Consolidated Quick Stats Bar (Rating, Hours, Entry)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1D1D20) : const Color(0xFFF7F7F9),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          if (pandal.rating != null && pandal.rating! > 0) ...[
                            Expanded(
                              flex: 2,
                              child: _buildStatItem(
                                icon: Icons.star_rounded,
                                iconColor: PujaColors.festivalGold,
                                value: pandal.rating!.toStringAsFixed(1),
                                label: 'Rating',
                                isDark: isDark,
                                context: context,
                              ),
                            ),
                            _buildStatDivider(isDark),
                          ],
                          Expanded(
                            flex: 4,
                            child: _buildStatItem(
                              icon: Icons.schedule_rounded,
                              iconColor: isDark ? Colors.white54 : Colors.black45,
                              value: _formatTimings(pandal.timings),
                              label: 'Visiting Hours',
                              isDark: isDark,
                              context: context,
                            ),
                          ),
                          if (pandal.entryFee != null && pandal.entryFee!.isNotEmpty) ...[
                            _buildStatDivider(isDark),
                            Expanded(
                              flex: 3,
                              child: _buildStatItem(
                                icon: Icons.confirmation_number_outlined,
                                iconColor: isDark ? Colors.white54 : Colors.black45,
                                value: pandal.entryFee!,
                                label: 'Entry',
                                isDark: isDark,
                                context: context,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Visited / Hopped Pill (Minimalist Action)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          HapticFeedback.mediumImpact();
                          final state = context.read<PandalUserStateService?>();
                          await state?.toggleVisited(pandal.id);
                          if (context.mounted) {
                            final nowVisited = state?.isVisited(pandal.id) ?? false;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  nowVisited
                                      ? '🎉 Marked ${pandal.name} as Visited!'
                                      : 'Removed ${pandal.name} from Visited list.',
                                ),
                                duration: const Duration(seconds: 2),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          height: 38,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: isVis
                                ? (isDark ? Colors.green.withValues(alpha: 0.16) : const Color(0xFFE8F5E9))
                                : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF5F5F7)),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isVis
                                  ? Colors.green.withValues(alpha: 0.45)
                                  : (isDark ? Colors.white12 : Colors.black12),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              isVis
                                  ? PujaIcon.shankha(size: 22, color: Colors.green)
                                  : Icon(
                                      Icons.radio_button_unchecked_rounded,
                                      color: (isDark ? Colors.white54 : Colors.black45),
                                      size: 20,
                                    ),
                              const SizedBox(width: 7),
                              Text(
                                isVis ? 'Visited & Hopped! (Tap to unmark)' : 'Mark as Visited / Hopped',
                                style: TextStyle(
                                  fontSize: context.dynamicFont(12.5),
                                  fontWeight: isVis ? FontWeight.w700 : FontWeight.w600,
                                  color: isVis
                                      ? (isDark ? Colors.greenAccent : const Color(0xFF2E7D32))
                                      : (isDark ? Colors.white70 : Colors.black87),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Theme & Concept Section
                    Row(
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: 13,
                          color: PujaColors.festivalGold,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'THEME & ARTISTIC CONCEPT',
                          style: TextStyle(
                            fontSize: context.dynamicFont(10.5),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      pandal.theme,
                      style: TextStyle(
                        fontSize: context.dynamicFont(13.5),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (pandal.description.isNotEmpty && pandal.description != pandal.theme) ...[
                      const SizedBox(height: 4),
                      Text(
                        pandal.description,
                        style: TextStyle(
                          fontSize: context.dynamicFont(12.5),
                          height: 1.45,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Transit & Accessibility (Unified Single Card)
                    Row(
                      children: [
                        const Icon(
                          Icons.directions_transit_rounded,
                          size: 13,
                          color: PujaColors.metroBlue,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'TRANSIT & ACCESSIBILITY',
                          style: TextStyle(
                            fontSize: context.dynamicFont(10.5),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1A1A1C) : const Color(0xFFF8F8FA),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.black.withValues(alpha: 0.05),
                          width: 0.8,
                        ),
                      ),
                      child: Column(
                        children: [
                          if (pandal.nearestMetro != null && pandal.nearestMetro!.isNotEmpty) ...[
                            _buildTransitRow(
                              context: context,
                              icon: Icons.directions_subway_rounded,
                              iconColor: PujaColors.metroBlue,
                              label: 'Nearest Metro Station',
                              value: pandal.nearestMetro!,
                              isDark: isDark,
                            ),
                          ],
                          if (pandal.circularRailway != null && pandal.circularRailway!.isNotEmpty) ...[
                            if (pandal.nearestMetro != null && pandal.nearestMetro!.isNotEmpty)
                              _buildTransitRowDivider(isDark),
                            _buildTransitRow(
                              context: context,
                              icon: Icons.train_rounded,
                              iconColor: PujaColors.railwayPurple,
                              label: 'Circular Railway / Suburban',
                              value: pandal.circularRailway!,
                              isDark: isDark,
                            ),
                          ],
                          if (pandal.nearestMetro != null || pandal.circularRailway != null)
                            _buildTransitRowDivider(isDark),
                          _buildTransitRow(
                            context: context,
                            icon: Icons.place_outlined,
                            iconColor: PujaColors.durgaRed,
                            label: 'GPS Coordinates',
                            value: '${pandal.latitude.toStringAsFixed(4)}, ${pandal.longitude.toStringAsFixed(4)}',
                            isDark: isDark,
                            trailing: Icon(
                              Icons.copy_rounded,
                              size: 14,
                              color: isDark ? Colors.white38 : Colors.black38,
                            ),
                            onTap: () {
                              Clipboard.setData(ClipboardData(
                                text: '${pandal.latitude}, ${pandal.longitude}',
                              ));
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Coordinates copied to clipboard'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Primary Route Action CTA
                    Container(
                      width: double.infinity,
                      height: 46,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFFC62828), // Durga Red Light
                            Color(0xFF8E0010), // Durga Red Dark / Crimson
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFC62828).withValues(alpha: 0.30),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(13),
                          onTap: () {
                            HapticFeedback.heavyImpact();
                            Navigator.of(context).pop();
                            MapScreen.routeToPandal(context, pandal);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              PujaIcon.shankha(
                                color: PujaColors.goldBright,
                                size: 24,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                'Get Turn-by-Turn Directions',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: context.dynamicFont(14),
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
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

  static Widget _buildCircleButton({
    required Widget child,
    required VoidCallback onTap,
    required bool isDark,
    required String tooltip,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(17),
          onTap: onTap,
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.05),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                width: 0.8,
              ),
            ),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }

  static Widget _buildStatItem({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required bool isDark,
    required BuildContext context,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: iconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: context.dynamicFont(12.5),
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: context.dynamicFont(10),
            fontWeight: FontWeight.w500,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
        ),
      ],
    );
  }

  static String _formatTimings(String raw) {
    if (raw.isEmpty) return 'Open 24h';
    return raw
        .replaceAll(':00 AM', ' AM')
        .replaceAll(':00 PM', ' PM')
        .replaceAll(':00am', ' am')
        .replaceAll(':00pm', ' pm')
        .replaceAll(' - ', '–')
        .trim();
  }

  static Widget _buildStatDivider(bool isDark) {
    return Container(
      width: 0.8,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: isDark ? Colors.white12 : Colors.black12,
    );
  }

  static Widget _buildTransitRow({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final rowContent = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.5),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: isDark ? 0.20 : 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(icon, size: 14, color: iconColor),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: context.dynamicFont(10),
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: context.dynamicFont(12),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 6),
            trailing,
          ],
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: rowContent,
        ),
      );
    }
    return rowContent;
  }

  static Widget _buildTransitRowDivider(bool isDark) {
    return Divider(
      height: 7,
      thickness: 0.6,
      color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
    );
  }
}
