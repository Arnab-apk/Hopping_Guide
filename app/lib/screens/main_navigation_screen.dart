import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/gemkit_config.dart';
import '../widgets/app_tutorial_dialog.dart';
import '../widgets/puja_icons.dart';
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
  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.onMapReady,
  });

  final int initialIndex;
  final VoidCallback? onMapReady;

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
          return MapScreenGemKit(
            onMapCreated: (_) => widget.onMapReady?.call(),
          );
        }
        return MapScreen(
          onMapReady: widget.onMapReady,
        );
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
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = idx);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // Ultra-smooth zero-latency tab switching with state, scroll position, and map tiles preserved
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabSelected,
        destinations: [
          NavigationDestination(
            icon: PujaIcon.durgaEyes(
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            selectedIcon: PujaIcon.durgaEyes(
              size: 32,
              color: theme.colorScheme.primary,
            ),
            label: 'Map',
          ),
          NavigationDestination(
            icon: PujaIcon.durgaFace(
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            selectedIcon: PujaIcon.durgaFace(
              size: 32,
              color: theme.colorScheme.primary,
            ),
            label: 'Pandals',
          ),
          NavigationDestination(
            icon: PujaIcon.ashtabhujaVariant(
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            selectedIcon: PujaIcon.ashtabhujaVariant(
              size: 32,
              color: theme.colorScheme.primary,
            ),
            label: 'Routes',
          ),
          NavigationDestination(
            icon: PujaIcon.dhaki(
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            selectedIcon: PujaIcon.dhaki(
              size: 32,
              color: theme.colorScheme.primary,
            ),
            label: 'Squads',
          ),
          NavigationDestination(
            icon: PujaIcon.trishulEyes(
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            selectedIcon: PujaIcon.trishulEyes(
              size: 32,
              color: theme.colorScheme.primary,
            ),
            label: 'Helpline',
          ),
        ],
      ),
    );
  }
}

