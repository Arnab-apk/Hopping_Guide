import 'package:flutter/material.dart';

import 'screens/map_screen.dart';
import 'screens/pandal_list_screen.dart';
import 'screens/pandal_detail_screen.dart';
import 'screens/group_screen.dart';
import 'screens/auth_screen.dart';
import 'config/theme.dart';

/// Root widget. Routes follow the P0 feature scope from the architecture doc.
class KolkataPujaApp extends StatelessWidget {
  const KolkataPujaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kolkata Puja',
      debugShowCheckedModeBanner: false,
      theme: appTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const MapScreen(),
        '/list': (context) => const PandalListScreen(),
        '/detail': (context) => const PandalDetailScreen(),
        '/group': (context) => const GroupScreen(),
        '/auth': (context) => const AuthScreen(),
      },
    );
  }
}
