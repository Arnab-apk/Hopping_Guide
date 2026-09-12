import 'package:flutter/material.dart';

/// Centralized theme. Adjust brand colors here.
ThemeData get appTheme => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFFD32F2F),
      ),
      appBarTheme: const AppBarTheme(centerTitle: true),
    );
