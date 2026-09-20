import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'services/theme_service.dart';
import 'services/auth_service.dart';
import 'screens/app_root_coordinator.dart';
import 'screens/group_screen.dart';
import 'screens/helplines_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/map_screen.dart';
import 'screens/pandal_detail_screen.dart';
import 'screens/pandal_list_screen.dart';
import 'screens/routes_screen.dart';
import 'screens/welcome_screen.dart';

/// Root application widget supporting Light and Dark modes and deep-link routing.
class KolkataPujaApp extends StatelessWidget {
  const KolkataPujaApp({super.key, this.navigatorKey});

  final GlobalKey<NavigatorState>? navigatorKey;

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService?>();
    final authService = context.watch<AuthService?>();
    final isLoggedIn = authService?.isAuthenticated ?? false;

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Uma',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      darkTheme: appDarkTheme,
      themeMode: themeService?.themeMode ?? ThemeMode.dark,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        final uri = Uri.tryParse(name);

        // Handle /pandal/:id or /pandal?id=:id
        if (uri != null) {
          if (uri.pathSegments.isNotEmpty && uri.pathSegments.first == 'pandal') {
            final id = uri.pathSegments.length > 1 ? uri.pathSegments[1] : uri.queryParameters['id'];
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => PandalDetailScreen(pandalId: id),
            );
          }

          // Handle /main?tab=X or arguments {'tab': X}
          if (uri.path == '/main' || uri.path == 'main') {
            int tabIndex = 0;
            if (settings.arguments is Map && (settings.arguments as Map).containsKey('tab')) {
              tabIndex = ((settings.arguments as Map)['tab'] as num?)?.toInt() ?? 0;
            } else if (uri.queryParameters.containsKey('tab')) {
              tabIndex = int.tryParse(uri.queryParameters['tab']!) ?? 0;
            }
            return MaterialPageRoute(
              settings: settings,
              builder: (_) => MainNavigationScreen(initialIndex: tabIndex),
            );
          }
        }

        return null;
      },
      routes: {
        '/': (context) => isLoggedIn ? const AppRootCoordinator() : const WelcomeScreen(),
        '/splash': (context) => isLoggedIn ? const AppRootCoordinator() : const WelcomeScreen(),
        '/greeting': (context) => const AppRootCoordinator(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const WelcomeScreen(),
        '/main': (context) => const MainNavigationScreen(),
        '/map': (context) => const MapScreen(),
        '/list': (context) => const PandalListScreen(),
        '/detail': (context) => const PandalDetailScreen(),
        '/routes': (context) => const RoutesScreen(),
        '/group': (context) => const GroupScreen(),
        '/auth': (context) => const WelcomeScreen(),
        '/helplines': (context) => const HelplinesScreen(),
      },
    );
  }
}
