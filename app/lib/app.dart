import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/theme.dart';
import 'services/theme_service.dart';
import 'screens/group_screen.dart';
import 'screens/helplines_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/map_screen.dart';
import 'screens/pandal_detail_screen.dart';
import 'screens/pandal_list_screen.dart';
import 'screens/routes_screen.dart';
import 'screens/welcome_screen.dart';

/// Root application widget supporting Light and Dark modes.
class KolkataPujaApp extends StatelessWidget {
  const KolkataPujaApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService?>();
    return MaterialApp(
      title: 'Pujo Parikrama',
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
      routes: {
        '/': (context) => const WelcomeScreen(),
        '/welcome': (context) => const WelcomeScreen(),
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
