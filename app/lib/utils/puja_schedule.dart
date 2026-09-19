import 'package:flutter/material.dart';

/// Design tokens matching the modern dark aesthetic for the greeting splash.
class NeoTokens {
  NeoTokens._();
  static const Color accentGold = Color(0xFFDCA830);
  static const Color goldBright = Color(0xFFFFD54F);
  static const Color bgDark = Color(0xFF0E0B0C);
}

/// Data model representing a single day in the Durga Puja schedule.
class PujaDay {
  final DateTime date;
  final String name;
  final String? subtitle;
  final String description;

  const PujaDay({
    required this.date,
    required this.name,
    this.subtitle,
    required this.description,
  });
}

/// Official 10-day (12-entry) schedule for Durga Puja 2026.
///
/// Maha Saptami spans both Oct 17 and Oct 18 per the traditional calendar,
/// and Maha Ashtami is Oct 19 (including the critical Sandhi Puja).
final List<PujaDay> pujaSchedule2026 = [
  PujaDay(
    date: DateTime(2026, 10, 10),
    name: 'Mahalaya',
    description: 'The start of Devi Paksha — tarpan rituals and the inviting of Goddess Durga.',
  ),
  PujaDay(
    date: DateTime(2026, 10, 11),
    name: 'Pratipada',
    description: 'Day 1 of Navratri — Ghatasthapana.',
  ),
  PujaDay(
    date: DateTime(2026, 10, 12),
    name: 'Dwitiya',
    description: 'Devi Brahmacharini puja.',
  ),
  PujaDay(
    date: DateTime(2026, 10, 13),
    name: 'Tritiya',
    description: 'Devi Chandraghanta puja.',
  ),
  PujaDay(
    date: DateTime(2026, 10, 14),
    name: 'Maha Chaturthi',
    description: 'Pandal structures open for their first viewing.',
  ),
  PujaDay(
    date: DateTime(2026, 10, 15),
    name: 'Maha Panchami',
    description: 'Preparations conclude; traditional welcoming rituals begin.',
  ),
  PujaDay(
    date: DateTime(2026, 10, 16),
    name: 'Maha Shashthi',
    subtitle: 'Bodhon',
    description: "The formal festival kickoff — Bodhon unveils the idol's face.",
  ),
  PujaDay(
    date: DateTime(2026, 10, 17),
    name: 'Maha Saptami',
    description: 'Bathing of the Kola Bou / Nabapatrika snan before sunrise.',
  ),
  PujaDay(
    date: DateTime(2026, 10, 18),
    name: 'Maha Saptami',
    description: 'Saptami rituals continue through the second day.',
  ),
  PujaDay(
    date: DateTime(2026, 10, 19),
    name: 'Maha Ashtami',
    description: 'Peak devotion — Anjali, Kumari Puja, and the critical Sandhi Puja.',
  ),
  PujaDay(
    date: DateTime(2026, 10, 20),
    name: 'Maha Navami',
    description: 'The dhunuchi naach carries the night toward Dashami.',
  ),
  PujaDay(
    date: DateTime(2026, 10, 21),
    name: 'Vijaya Dashami',
    description: 'Sindoor Khela, and the idol immersion — Visarjan.',
  ),
];

/// Testable clock wrapping [DateTime.now].
///
/// Supports an optional [_debugOverride] that is strictly gated by an `assert` block,
/// ensuring it is completely stripped from release builds while enabling automated testing
/// and in-app QA date previewing.
class AppClock {
  static DateTime? _debugOverride;

  /// Only ever set outside of release builds.
  static void debugSetOverride(DateTime? date) {
    assert(() {
      _debugOverride = date;
      return true;
    }());
  }

  /// Current time, or the debug override if set.
  static DateTime now() => _debugOverride ?? DateTime.now();
}

/// Returns the matching [PujaDay] for today, or `null` if outside Oct 10–21, 2026.
PujaDay? getTodaysPujaDay() {
  final today = AppClock.now();
  final todayDateOnly = DateTime(today.year, today.month, today.day);
  for (final day in pujaSchedule2026) {
    if (day.date.year == todayDateOnly.year &&
        day.date.month == todayDateOnly.month &&
        day.date.day == todayDateOnly.day) {
      return day;
    }
  }
  return null;
}

/// Builds the personalized greeting string for the user.
///
/// In-schedule: "Shubho {Day Name} ({Subtitle}), {User}"
/// Pre-Mahalaya: "Welcome back, {User} — {N} days to Mahalaya"
/// Post-Dashami: "Welcome back, {User} — see you next Durga Puja!"
String buildGreeting(PujaDay? day, String userName) {
  final cleanName = userName.trim().isEmpty ? 'Pujo Hopper' : userName.trim();
  if (day != null) {
    final subtitlePart = day.subtitle != null ? " (${day.subtitle})" : "";
    return 'Shubho ${day.name}$subtitlePart, $cleanName';
  }

  final today = AppClock.now();
  final todayDateOnly = DateTime(today.year, today.month, today.day);
  final mahalaya = pujaSchedule2026.first.date;
  final mahalayaDateOnly = DateTime(mahalaya.year, mahalaya.month, mahalaya.day);
  final daysUntilMahalaya = mahalayaDateOnly.difference(todayDateOnly).inDays;

  if (daysUntilMahalaya > 0) {
    return 'Welcome back, $cleanName — $daysUntilMahalaya days to Mahalaya';
  }
  return 'Welcome back, $cleanName — see you next Durga Puja!';
}
