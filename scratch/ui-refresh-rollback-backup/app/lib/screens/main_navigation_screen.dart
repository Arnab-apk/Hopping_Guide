import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/gemkit_config.dart';
import '../services/navigation_session.dart';
import '../widgets/app_tutorial_dialog.dart';
import '../widgets/incoming_group_call_listener.dart';
import 'map_screen.dart';
import 'map_screen_gemkit.dart';
import 'pandal_list_screen.dart';
import 'routes_screen.dart';
import 'group_screen.dart';
import 'helplines_screen.dart';

/// Main navigation shell housing the 5 core tabs:
/// Map, Pandals Directory, Curated Routes, Groups, and Helplines.
/// Keeps each tab mounted to preserve map state and scroll position.
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    this.initialIndex = 0,
    this.onMapReady,
  });

  final int initialIndex;
  final VoidCallback? onMapReady;

  /// Global notifier allowing external callers (deep links, notifications) to switch tabs
  static final ValueNotifier<int?> tabSwitchNotifier = ValueNotifier<int?>(
    null,
  );

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
  // Keep the map ready for the startup coordinator and incoming destinations.
  final Set<int> _mountedTabs = {0};

  late final List<Widget> _screens = [
    ValueListenableBuilder<bool>(
      valueListenable: GemKitConfig.isMagicLaneActive,
      builder: (context, useMagicLane, _) {
        if (useMagicLane && GemKitConfig.isConfigured) {
          return MapScreenGemKit(
            onMapCreated: (_) => widget.onMapReady?.call(),
          );
        }
        return MapScreen(onMapReady: widget.onMapReady);
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
    _currentIndex = widget.initialIndex.clamp(0, _screens.length - 1);
    _mountedTabs.add(_currentIndex);
    MainNavigationScreen.tabSwitchNotifier.addListener(
      _handleExternalTabSwitch,
    );
    if (widget.onMapReady == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        AppTutorialDialog.checkAndShow(context);
      });
    }
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
        _mountedTabs.add(tab);
      }
    }
  }

  @override
  void dispose() {
    MainNavigationScreen.tabSwitchNotifier.removeListener(
      _handleExternalTabSwitch,
    );
    super.dispose();
  }

  void _onTabSelected(int idx) {
    if (_currentIndex != idx) {
      HapticFeedback.selectionClick();
      setState(() {
        _currentIndex = idx;
        _mountedTabs.add(idx);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return IncomingGroupCallListener(
      child: Scaffold(
        // Preserve screen state while changing tabs.
        body: IndexedStack(
          index: _currentIndex,
          children: [
            for (var i = 0; i < _screens.length; i++)
              TickerMode(
                enabled: i == _currentIndex,
                child: _mountedTabs.contains(i)
                    ? _screens[i]
                    : const SizedBox.shrink(),
              ),
          ],
        ),
        bottomNavigationBar: ListenableBuilder(
          listenable: NavigationSession.instance,
          builder: (context, _) => NavigationSession.instance.active
              ? const SizedBox.shrink()
              : DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Theme.of(context).colorScheme.outline,
                        width: 2,
                      ),
                    ),
                  ),
                  child: NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _onTabSelected,
                    destinations: const [
                      NavigationDestination(
                        icon: ExcludeSemantics(child: Icon(Icons.map_outlined)),
                        selectedIcon: ExcludeSemantics(
                          child: Icon(Icons.map_rounded),
                        ),
                        label: 'Map',
                      ),
                      NavigationDestination(
                        icon: ExcludeSemantics(
                          child: Icon(Icons.temple_hindu_outlined),
                        ),
                        selectedIcon: ExcludeSemantics(
                          child: Icon(Icons.temple_hindu_rounded),
                        ),
                        label: 'Pandals',
                      ),
                      NavigationDestination(
                        icon: ExcludeSemantics(
                          child: Icon(Icons.route_outlined),
                        ),
                        selectedIcon: ExcludeSemantics(
                          child: Icon(Icons.route_rounded),
                        ),
                        label: 'Routes',
                      ),
                      NavigationDestination(
                        icon: ExcludeSemantics(
                          child: Icon(Icons.groups_outlined),
                        ),
                        selectedIcon: ExcludeSemantics(
                          child: Icon(Icons.groups_rounded),
                        ),
                        label: 'Group',
                      ),
                      NavigationDestination(
                        icon: ExcludeSemantics(
                          child: Icon(Icons.health_and_safety_outlined),
                        ),
                        selectedIcon: ExcludeSemantics(
                          child: Icon(Icons.health_and_safety_rounded),
                        ),
                        label: 'Helpline',
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}
