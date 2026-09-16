import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/gemkit_config.dart';
import '../config/theme.dart';
import '../utils/responsive.dart';
import '../widgets/app_tutorial_dialog.dart';
import '../widgets/durga_face_icon.dart';
import 'map_screen.dart';
import 'map_screen_gemkit.dart';
import 'pandal_list_screen.dart';
import 'routes_screen.dart';
import 'group_screen.dart';
import 'helplines_screen.dart';

/// Main navigation shell housing the 5 core tabs:
/// Map, Pandals Directory, Curated Routes, Groups, and Helplines.
/// Features ultra-smooth animated tab switching, spring scale micro-interactions,
/// tactile haptic feedback, and dynamic icon & label scaling.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  final int initialIndex;

  /// Global notifier allowing external callers (deep links, notifications) to switch tabs
  static final ValueNotifier<int?> tabSwitchNotifier = ValueNotifier<int?>(null);

  /// Programmatically switch tab from any descendant screen
  static void switchTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainNavigationScreenState>();
    state?._onTabSelected(index);
  }

  /// Programmatically switch to any tab index from anywhere in the app
  static void switchToTab(int index) {
    tabSwitchNotifier.value = index;
  }

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  late final List<Widget> _screens = [
    ValueListenableBuilder<bool>(
      valueListenable: GemKitConfig.isMagicLaneActive,
      builder: (context, useMagicLane, _) {
        if (useMagicLane && GemKitConfig.isConfigured) {
          return const MapScreenGemKit();
        }
        return const MapScreen();
      },
    ),
    const PandalListScreen(),
    const RoutesScreen(),
    const GroupScreen(),
    const HelplinesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    MainNavigationScreen.tabSwitchNotifier.addListener(_handleExternalTabSwitch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppTutorialDialog.checkAndShow(context);
    });
  }

  void _handleExternalTabSwitch() {
    final target = MainNavigationScreen.tabSwitchNotifier.value;
    if (target != null && target >= 0 && target < _screens.length) {
      if (mounted) {
        _onTabSelected(target);
      }
      MainNavigationScreen.tabSwitchNotifier.value = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map && args.containsKey('tab')) {
      final tab = args['tab'];
      if (tab is int && tab >= 0 && tab < _screens.length) {
        _currentIndex = tab;
      }
    }
  }

  @override
  void dispose() {
    MainNavigationScreen.tabSwitchNotifier.removeListener(_handleExternalTabSwitch);
    super.dispose();
  }

  void _onTabSelected(int idx) {
    if (_currentIndex != idx) {
      // Tactile delight: subtle haptic click
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = idx);
    }
  }

  Widget _buildNavIcon({
    IconData? outlineIcon,
    IconData? filledIcon,
    Widget? customWidget,
    required bool isSelected,
    required BuildContext context,
  }) {
    final iconSize = context.dynamicIcon(22);
    return AnimatedScale(
      scale: isSelected ? 1.14 : 1.0,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: customWidget ??
            Icon(
              isSelected ? filledIcon : outlineIcon,
              key: ValueKey(isSelected),
              size: iconSize,
              color: isSelected ? PujaColors.festivalGold : null,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSmall = context.isSmallScreen;

    return Scaffold(
      // Ultra-smooth zero-latency tab switching with state, scroll position, and map tiles preserved
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? PujaColors.nightCard : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? PujaColors.nightBorder : PujaColors.festivalGold.withValues(alpha: 0.25),
              width: 1.0,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black45 : PujaColors.crimsonVelvet.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: _onTabSelected,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.transparent,
            elevation: 0,
            selectedItemColor: PujaColors.festivalGold,
            unselectedItemColor: isDark ? Colors.white60 : Colors.black54,
            selectedFontSize: isSmall ? 10.5 : 12.0,
            unselectedFontSize: isSmall ? 9.5 : 11.0,
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  outlineIcon: Icons.map_outlined,
                  filledIcon: Icons.map,
                  isSelected: _currentIndex == 0,
                  context: context,
                ),
                label: 'Map',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  customWidget: DurgaFaceIcon(
                    size: context.dynamicIcon(22),
                    color: _currentIndex == 1
                        ? PujaColors.festivalGold
                        : (isDark ? Colors.white60 : Colors.black54),
                    bindiColor: _currentIndex == 1 ? const Color(0xFFFF1744) : const Color(0xFFD50000),
                  ),
                  isSelected: _currentIndex == 1,
                  context: context,
                ),
                label: 'Pandals',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  outlineIcon: Icons.alt_route_outlined,
                  filledIcon: Icons.alt_route,
                  isSelected: _currentIndex == 2,
                  context: context,
                ),
                label: 'Routes',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  outlineIcon: Icons.group_outlined,
                  filledIcon: Icons.group,
                  isSelected: _currentIndex == 3,
                  context: context,
                ),
                label: 'Squads',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(
                  outlineIcon: Icons.health_and_safety_outlined,
                  filledIcon: Icons.health_and_safety,
                  isSelected: _currentIndex == 4,
                  context: context,
                ),
                label: 'Helpline',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

