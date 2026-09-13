import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/theme.dart';
import '../utils/responsive.dart';

class TutorialStep {
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final Color iconColor;
  final List<String> highlights;

  const TutorialStep({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.iconColor,
    required this.highlights,
  });
}

/// Interactive First-Time User Tutorial Dialog with Next, Previous, and Finish buttons.
class AppTutorialDialog extends StatefulWidget {
  const AppTutorialDialog({super.key});

  static const String _seenPrefKey = 'has_seen_app_tutorial_v1';

  /// Automatically launches the tutorial if the user has not seen it yet.
  static Future<void> checkAndShow(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeen = prefs.getBool(_seenPrefKey) ?? false;
    if (!hasSeen && context.mounted) {
      // Small delay to ensure the parent screen has completed its initial build
      Future.delayed(const Duration(milliseconds: 600), () {
        if (context.mounted) {
          show(context);
        }
      });
    }
  }

  /// Explicitly opens the tutorial (e.g. from a help button).
  static void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AppTutorialDialog(),
    );
  }

  @override
  State<AppTutorialDialog> createState() => _AppTutorialDialogState();
}

class _AppTutorialDialogState extends State<AppTutorialDialog> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<TutorialStep> _steps = const [
    TutorialStep(
      title: 'Interactive Puja Map',
      subtitle: '117 Pandals Across Kolkata & Suburbs',
      description:
          'Pan and pinch to navigate 117 Durga Puja pandals. Tap any marker to view real-time crowd levels, theme names, and nearest metro stations.',
      icon: Icons.map_rounded,
      iconColor: PujaColors.festivalGold,
      highlights: [
        'Filter by Regions (North, South, Nadia, Hooghly)',
        'GPS Auto-Centering on your location',
        'Live Crowd Level Badges (Low to Extreme)',
      ],
    ),
    TutorialStep(
      title: 'Pandals Directory & Tracker',
      subtitle: 'Search, Bookmark & Mark Visited',
      description:
          'Search pandals by name, locality, or artistic concept. Tap the heart to bookmark favorites, and mark pandals as hopped to track your festive journey.',
      icon: Icons.temple_hindu_rounded,
      iconColor: PujaColors.durgaRedLight,
      highlights: [
        '❤️ Favorite list saved offline',
        '✅ "Mark as Visited" Hopping counter',
        '📍 Live GPS distance to each pandal',
      ],
    ),
    TutorialStep(
      title: 'Curated Walking Routes',
      subtitle: 'Optimized Itineraries for Pandal Crawlers',
      description:
          'Explore time-tested heritage walks like the North Kolkata Traditional Walk, South Kolkata Grand Circuit, and Bonedi Bari Aristocratic Trail.',
      icon: Icons.alt_route_rounded,
      iconColor: PujaColors.festivalGold,
      highlights: [
        'Estimated walking distance & duration',
        'Best visiting hours (morning vs late night)',
        'Step-by-step pandal stop sequence',
      ],
    ),
    TutorialStep(
      title: 'Private Hopping Squads',
      subtitle: 'Stay Connected in Mega Crowds',
      description:
          'Create a private squad with family or friends and share your 6-character code. Set a meet-up point and send SOS alerts if anyone gets separated.',
      icon: Icons.group_rounded,
      iconColor: PujaColors.metroBlue,
      highlights: [
        '➕ "Create Squad" or 🔑 "Join with Code"',
        '🚩 Set & edit designated meet-up points',
        '🚨 Separation SOS alert notification',
      ],
    ),
    TutorialStep(
      title: '24/7 Emergency & Helplines',
      subtitle: 'Direct One-Tap Police & Medical Dialing',
      description:
          'Instant access to official Kolkata Police Lalbazar Control Room, 112 Emergency, Medical Ambulances, Women Safety, and Child Helplines.',
      icon: Icons.health_and_safety_rounded,
      iconColor: PujaColors.durgaRed,
      highlights: [
        'One-tap calling directly from app',
        'Copy phone numbers with one touch',
        'Women helpline (1090) & Police SOS',
      ],
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishTutorial() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppTutorialDialog._seenPrefKey, true);
    if (mounted) {
      final nav = Navigator.maybeOf(context);
      if (nav != null && nav.canPop()) {
        nav.pop();
      }
    }
  }

  void _nextPage() {
    HapticFeedback.selectionClick();
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishTutorial();
    }
  }

  void _previousPage() {
    HapticFeedback.selectionClick();
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isLast = _currentPage == _steps.length - 1;
    final isFirst = _currentPage == 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C090D) : Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: PujaColors.festivalGold.withValues(alpha: 0.45),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Bar: Step indicator + Skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: PujaColors.festivalGold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: PujaColors.festivalGold.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      'Tutorial • ${_currentPage + 1} of ${_steps.length}',
                      style: GoogleFonts.plusJakartaSans(
                        color: PujaColors.festivalGold,
                        fontWeight: FontWeight.w700,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _finishTutorial,
                    child: Text(
                      'Skip',
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // PageView content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _steps.length,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                itemBuilder: (context, index) {
                  final step = _steps[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Glowing Icon Halo
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: step.iconColor.withValues(alpha: 0.14),
                              border: Border.all(
                                color: step.iconColor.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: step.iconColor.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Icon(
                              step.icon,
                              size: context.dynamicIcon(38),
                              color: step.iconColor,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Title
                          Text(
                            step.title,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: context.dynamicFont(20),
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),

                          // Subtitle
                          Text(
                            step.subtitle,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: context.dynamicFont(12),
                              fontWeight: FontWeight.w600,
                              color: PujaColors.festivalGold,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Description
                          Text(
                            step.description,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: context.dynamicFont(12.5),
                              height: 1.42,
                              color: isDark ? Colors.white70 : Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Feature Highlights
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.black.withValues(alpha: 0.35)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: isDark ? 0.08 : 0.15),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: step.highlights
                                  .map(
                                    (h) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 14,
                                            color: PujaColors.festivalGold,
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              h,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: context.dynamicFont(11.5),
                                                fontWeight: FontWeight.w600,
                                                color: isDark ? Colors.white70 : Colors.black87,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Page Indicator Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _steps.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  height: 6,
                  width: _currentPage == i ? 22 : 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? PujaColors.festivalGold
                        : (isDark ? Colors.white24 : Colors.black12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Navigation Controls: [ Previous ]  [ Next / Finish ]
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
              child: Row(
                children: [
                  // Previous button
                  if (!isFirst)
                    Expanded(
                      flex: 1,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          side: BorderSide(
                            color: isDark ? Colors.white24 : Colors.grey.shade300,
                          ),
                        ),
                        onPressed: _previousPage,
                        child: Text(
                          'Previous',
                          style: GoogleFonts.plusJakartaSans(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    )
                  else
                    const Spacer(flex: 1),

                  const SizedBox(width: 12),

                  // Next / Finish button
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: isLast ? PujaColors.festivalGold : PujaColors.durgaRed,
                        foregroundColor: isLast ? Colors.black : Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _nextPage,
                      icon: Icon(
                        isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                        size: 18,
                      ),
                      label: Text(
                        isLast ? 'Finish & Explore' : 'Next',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
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
