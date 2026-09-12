import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';
import '../utils/responsive.dart';
import 'map_screen.dart';
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

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;

  final List<Widget> _screens = const [
    MapScreen(),
    PandalListScreen(),
    RoutesScreen(),
    GroupScreen(),
    HelplinesScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabSelected(int idx) {
    if (_currentIndex != idx) {
      // Tactile delight: subtle haptic click
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = idx);
    }
  }

  Widget _buildNavIcon({
    required IconData outlineIcon,
    required IconData filledIcon,
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
        child: Icon(
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
      // Ultra-smooth cross-fade transition between screens
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _screens[_currentIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? PujaColors.crimsonVelvet : Colors.white,
          border: Border(
            top: BorderSide(
              color: PujaColors.festivalGold.withValues(alpha: isDark ? 0.35 : 0.25),
              width: 1.2,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black54 : PujaColors.crimsonVelvet.withValues(alpha: 0.12),
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
            selectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w900,
              fontSize: isSmall ? 10 : 11.5,
              letterSpacing: 0.3,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: isSmall ? 9.5 : 11,
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
                  outlineIcon: Icons.temple_hindu_outlined,
                  filledIcon: Icons.temple_hindu,
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

