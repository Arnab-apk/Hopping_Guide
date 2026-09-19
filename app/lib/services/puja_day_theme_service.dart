import 'package:flutter/material.dart';

/// The sacred Tithis & Days of Durga Puja, each with custom cultural greetings,
/// symbolic festival colors, divine aura gradients, and day-specific taglines.
enum PujaDayTheme {
  countdown,
  mahalaya,
  panchami,
  sasthi,
  saptami,
  asthami,
  nabami,
  dashami;

  String get shortLabel => switch (this) {
    PujaDayTheme.countdown => 'Auto',
    PujaDayTheme.mahalaya => 'Mahalaya',
    PujaDayTheme.panchami => 'Panchami',
    PujaDayTheme.sasthi => 'Sasthi',
    PujaDayTheme.saptami => 'Saptami',
    PujaDayTheme.asthami => 'Asthami',
    PujaDayTheme.nabami => 'Nabami',
    PujaDayTheme.dashami => 'Dashami',
  };

  String get bengaliGreeting => switch (this) {
    PujaDayTheme.countdown => 'শারদীয়া দুর্গোৎসব ২০২৬',
    PujaDayTheme.mahalaya => 'শুভ মহালয়া',
    PujaDayTheme.panchami => 'শুভ পঞ্চমী',
    PujaDayTheme.sasthi => 'শুভ ষষ্ঠী',
    PujaDayTheme.saptami => 'শুভ সপ্তমী',
    PujaDayTheme.asthami => 'শুভ মহাষ্টমী',
    PujaDayTheme.nabami => 'শুভ নবমী',
    PujaDayTheme.dashami => 'শুভ বিজয়া দশমী',
  };

  String get englishGreeting => switch (this) {
    PujaDayTheme.countdown => 'Durga Puja 2026',
    PujaDayTheme.mahalaya => 'Subho Mahalaya',
    PujaDayTheme.panchami => 'Subho Panchami',
    PujaDayTheme.sasthi => 'Subho Sasthi',
    PujaDayTheme.saptami => 'Subho Saptami',
    PujaDayTheme.asthami => 'Subho Maha Asthami',
    PujaDayTheme.nabami => 'Subho Nabami',
    PujaDayTheme.dashami => 'Subho Bijoya Dashami',
  };

  String get fullGreeting => switch (this) {
    PujaDayTheme.countdown => 'শারদীয়া দুর্গোৎসব ২০২৬ • Countdown',
    _ => '$bengaliGreeting • $englishGreeting',
  };

  String get tagline => switch (this) {
    PujaDayTheme.countdown => 'Where Tradition Meets Divine Shakti',
    PujaDayTheme.mahalaya => 'Agomoni — The Awakening of Divine Shakti',
    PujaDayTheme.panchami => 'Anandamoyee Agomon — Festivities Begin Across Bengal',
    PujaDayTheme.sasthi => 'Kalparambha & Bodhon — Goddess Welcomed into Pandals',
    PujaDayTheme.saptami => 'Kola Bou Snan & Divine Prana Pratishtha Puja',
    PujaDayTheme.asthami => 'Sacred Kumari Puja & Divine Sandhi Puja',
    PujaDayTheme.nabami => 'Maha Aarti, Dhunuchi Naach & Grand Parikrama',
    PujaDayTheme.dashami => 'Sindoor Khela, Bisorjon & Asche Bochor Abar Hobe',
  };

  Color get primaryAccent => switch (this) {
    PujaDayTheme.countdown => const Color(0xFFDCA830), // Classic Festival Gold
    PujaDayTheme.mahalaya => const Color(0xFF9FA8DA), // Mystic Indigo Silver
    PujaDayTheme.panchami => const Color(0xFFFF9800), // Vibrant Saffron Marigold
    PujaDayTheme.sasthi => const Color(0xFFE53935), // Radiant Crimson
    PujaDayTheme.saptami => const Color(0xFF43A047), // Sacred Emerald Nabapatrika
    PujaDayTheme.asthami => const Color(0xFFFF1744), // Divine Sindoor Red
    PujaDayTheme.nabami => const Color(0xFFAB47BC), // Royal Midnight Purple
    PujaDayTheme.dashami => const Color(0xFFFF5252), // Sindoor Khela Vermilion
  };

  Color get secondaryAccent => switch (this) {
    PujaDayTheme.countdown => const Color(0xFFFFD54F),
    PujaDayTheme.mahalaya => const Color(0xFFE8EAF6),
    PujaDayTheme.panchami => const Color(0xFFFFE082),
    PujaDayTheme.sasthi => const Color(0xFFFFD54F),
    PujaDayTheme.saptami => const Color(0xFFA5D6A7),
    PujaDayTheme.asthami => const Color(0xFFFFD54F),
    PujaDayTheme.nabami => const Color(0xFFFFE082),
    PujaDayTheme.dashami => const Color(0xFFFFD700),
  };

  List<Color> get auraGradient => switch (this) {
    PujaDayTheme.countdown => [
        const Color(0xFFDCA830).withValues(alpha: 0.16),
        const Color(0xFF800020).withValues(alpha: 0.08),
        Colors.transparent,
      ],
    PujaDayTheme.mahalaya => [
        const Color(0xFF3949AB).withValues(alpha: 0.22),
        const Color(0xFF1A237E).withValues(alpha: 0.12),
        Colors.transparent,
      ],
    PujaDayTheme.panchami => [
        const Color(0xFFFF9800).withValues(alpha: 0.22),
        const Color(0xFFE65100).withValues(alpha: 0.10),
        Colors.transparent,
      ],
    PujaDayTheme.sasthi => [
        const Color(0xFFD32F2F).withValues(alpha: 0.22),
        const Color(0xFFFFB300).withValues(alpha: 0.12),
        Colors.transparent,
      ],
    PujaDayTheme.saptami => [
        const Color(0xFF2E7D32).withValues(alpha: 0.22),
        const Color(0xFF1B5E20).withValues(alpha: 0.12),
        Colors.transparent,
      ],
    PujaDayTheme.asthami => [
        const Color(0xFFFF1744).withValues(alpha: 0.25),
        const Color(0xFF880E4F).withValues(alpha: 0.14),
        Colors.transparent,
      ],
    PujaDayTheme.nabami => [
        const Color(0xFF7B1FA2).withValues(alpha: 0.22),
        const Color(0xFF4A148C).withValues(alpha: 0.12),
        Colors.transparent,
      ],
    PujaDayTheme.dashami => [
        const Color(0xFFC2185B).withValues(alpha: 0.24),
        const Color(0xFFFFD700).withValues(alpha: 0.12),
        Colors.transparent,
      ],
  };

  IconData get icon => switch (this) {
    PujaDayTheme.countdown => Icons.auto_awesome,
    PujaDayTheme.mahalaya => Icons.wb_twilight_rounded,
    PujaDayTheme.panchami => Icons.celebration_rounded,
    PujaDayTheme.sasthi => Icons.flare_rounded,
    PujaDayTheme.saptami => Icons.eco_rounded,
    PujaDayTheme.asthami => Icons.local_fire_department_rounded,
    PujaDayTheme.nabami => Icons.nightlife_rounded,
    PujaDayTheme.dashami => Icons.favorite_rounded,
  };
}

/// Backward compatibility typedef
typedef PujaDayEnum = PujaDayTheme;

/// Dynamic Theme Service managing real-time and simulated Puja Day states.
class PujaDayThemeService extends ChangeNotifier {
  PujaDayThemeService._();
  static final PujaDayThemeService instance = PujaDayThemeService._();

  PujaDayTheme? _simulatedDay;

  PujaDayTheme get currentDay {
    if (_simulatedDay != null) {
      return _simulatedDay!;
    }
    return _detectDayFromDate(DateTime.now());
  }

  PujaDayTheme? get simulatedDay => _simulatedDay;
  bool get isSimulated => _simulatedDay != null;

  void setSimulatedDay(PujaDayTheme? day) {
    _simulatedDay = day;
    notifyListeners();
  }

  static PujaDayTheme _detectDayFromDate(DateTime date) {
    if (date.year == 2026 && date.month == 10) {
      return switch (date.day) {
        10 => PujaDayTheme.mahalaya,
        15 => PujaDayTheme.panchami,
        16 => PujaDayTheme.sasthi,
        17 => PujaDayTheme.saptami,
        18 => PujaDayTheme.asthami,
        19 => PujaDayTheme.nabami,
        20 => PujaDayTheme.dashami,
        _ => date.day > 20 ? PujaDayTheme.dashami : PujaDayTheme.countdown,
      };
    }
    return PujaDayTheme.countdown;
  }
}
