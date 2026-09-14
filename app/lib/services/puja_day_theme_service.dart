import 'package:flutter/material.dart';

/// The sacred Tithis & Days of Durga Puja, each with custom cultural greetings,
/// symbolic festival colors, divine aura gradients, and day-specific taglines.
enum PujaDay {
  countdown,
  mahalaya,
  panchami,
  sasthi,
  saptami,
  asthami,
  nabami,
  dashami;

  String get shortLabel => switch (this) {
    PujaDay.countdown => 'Auto',
    PujaDay.mahalaya => 'Mahalaya',
    PujaDay.panchami => 'Panchami',
    PujaDay.sasthi => 'Sasthi',
    PujaDay.saptami => 'Saptami',
    PujaDay.asthami => 'Asthami',
    PujaDay.nabami => 'Nabami',
    PujaDay.dashami => 'Dashami',
  };

  String get bengaliGreeting => switch (this) {
    PujaDay.countdown => 'শারদীয়া দুর্গোৎসব ২০২৬',
    PujaDay.mahalaya => 'শুভ মহালয়া',
    PujaDay.panchami => 'শুভ পঞ্চমী',
    PujaDay.sasthi => 'শুভ ষষ্ঠী',
    PujaDay.saptami => 'শুভ সপ্তমী',
    PujaDay.asthami => 'শুভ মহাষ্টমী',
    PujaDay.nabami => 'শুভ নবমী',
    PujaDay.dashami => 'শুভ বিজয়া দশমী',
  };

  String get englishGreeting => switch (this) {
    PujaDay.countdown => 'Durga Puja 2026',
    PujaDay.mahalaya => 'Subho Mahalaya',
    PujaDay.panchami => 'Subho Panchami',
    PujaDay.sasthi => 'Subho Sasthi',
    PujaDay.saptami => 'Subho Saptami',
    PujaDay.asthami => 'Subho Maha Asthami',
    PujaDay.nabami => 'Subho Nabami',
    PujaDay.dashami => 'Subho Bijoya Dashami',
  };

  String get fullGreeting => switch (this) {
    PujaDay.countdown => 'শারদীয়া দুর্গোৎসব ২০২৬ • Countdown',
    _ => '$bengaliGreeting • $englishGreeting',
  };

  String get tagline => switch (this) {
    PujaDay.countdown => 'Where Tradition Meets Divine Shakti',
    PujaDay.mahalaya => 'Agomoni — The Awakening of Divine Shakti',
    PujaDay.panchami => 'Anandamoyee Agomon — Festivities Begin Across Bengal',
    PujaDay.sasthi => 'Kalparambha & Bodhon — Goddess Welcomed into Pandals',
    PujaDay.saptami => 'Kola Bou Snan & Divine Prana Pratishtha Puja',
    PujaDay.asthami => 'Sacred Kumari Puja & Divine Sandhi Puja',
    PujaDay.nabami => 'Maha Aarti, Dhunuchi Naach & Grand Parikrama',
    PujaDay.dashami => 'Sindoor Khela, Bisorjon & Asche Bochor Abar Hobe',
  };

  Color get primaryAccent => switch (this) {
    PujaDay.countdown => const Color(0xFFDCA830), // Classic Festival Gold
    PujaDay.mahalaya => const Color(0xFF9FA8DA), // Mystic Indigo Silver
    PujaDay.panchami => const Color(0xFFFF9800), // Vibrant Saffron Marigold
    PujaDay.sasthi => const Color(0xFFE53935), // Radiant Crimson
    PujaDay.saptami => const Color(0xFF43A047), // Sacred Emerald Nabapatrika
    PujaDay.asthami => const Color(0xFFFF1744), // Divine Sindoor Red
    PujaDay.nabami => const Color(0xFFAB47BC), // Royal Midnight Purple
    PujaDay.dashami => const Color(0xFFFF5252), // Sindoor Khela Vermilion
  };

  Color get secondaryAccent => switch (this) {
    PujaDay.countdown => const Color(0xFFFFD54F),
    PujaDay.mahalaya => const Color(0xFFE8EAF6),
    PujaDay.panchami => const Color(0xFFFFE082),
    PujaDay.sasthi => const Color(0xFFFFD54F),
    PujaDay.saptami => const Color(0xFFA5D6A7),
    PujaDay.asthami => const Color(0xFFFFD54F),
    PujaDay.nabami => const Color(0xFFFFE082),
    PujaDay.dashami => const Color(0xFFFFD700),
  };

  List<Color> get auraGradient => switch (this) {
    PujaDay.countdown => [
        const Color(0xFFDCA830).withValues(alpha: 0.16),
        const Color(0xFF800020).withValues(alpha: 0.08),
        Colors.transparent,
      ],
    PujaDay.mahalaya => [
        const Color(0xFF3949AB).withValues(alpha: 0.22),
        const Color(0xFF1A237E).withValues(alpha: 0.12),
        Colors.transparent,
      ],
    PujaDay.panchami => [
        const Color(0xFFFF9800).withValues(alpha: 0.22),
        const Color(0xFFE65100).withValues(alpha: 0.10),
        Colors.transparent,
      ],
    PujaDay.sasthi => [
        const Color(0xFFD32F2F).withValues(alpha: 0.22),
        const Color(0xFFFFB300).withValues(alpha: 0.12),
        Colors.transparent,
      ],
    PujaDay.saptami => [
        const Color(0xFF2E7D32).withValues(alpha: 0.22),
        const Color(0xFF1B5E20).withValues(alpha: 0.12),
        Colors.transparent,
      ],
    PujaDay.asthami => [
        const Color(0xFFFF1744).withValues(alpha: 0.25),
        const Color(0xFF880E4F).withValues(alpha: 0.14),
        Colors.transparent,
      ],
    PujaDay.nabami => [
        const Color(0xFF7B1FA2).withValues(alpha: 0.22),
        const Color(0xFF4A148C).withValues(alpha: 0.12),
        Colors.transparent,
      ],
    PujaDay.dashami => [
        const Color(0xFFC2185B).withValues(alpha: 0.24),
        const Color(0xFFFFD700).withValues(alpha: 0.12),
        Colors.transparent,
      ],
  };

  IconData get icon => switch (this) {
    PujaDay.countdown => Icons.auto_awesome,
    PujaDay.mahalaya => Icons.wb_twilight_rounded,
    PujaDay.panchami => Icons.celebration_rounded,
    PujaDay.sasthi => Icons.flare_rounded,
    PujaDay.saptami => Icons.eco_rounded,
    PujaDay.asthami => Icons.local_fire_department_rounded,
    PujaDay.nabami => Icons.nightlife_rounded,
    PujaDay.dashami => Icons.favorite_rounded,
  };
}

/// Dynamic Theme Service managing real-time and simulated Puja Day states.
class PujaDayThemeService extends ChangeNotifier {
  PujaDayThemeService._();
  static final PujaDayThemeService instance = PujaDayThemeService._();

  PujaDay? _simulatedDay;

  PujaDay get currentDay {
    if (_simulatedDay != null) {
      return _simulatedDay!;
    }
    return _detectDayFromDate(DateTime.now());
  }

  PujaDay? get simulatedDay => _simulatedDay;
  bool get isSimulated => _simulatedDay != null;

  void setSimulatedDay(PujaDay? day) {
    _simulatedDay = day;
    notifyListeners();
  }

  static PujaDay _detectDayFromDate(DateTime date) {
    if (date.year == 2026 && date.month == 10) {
      return switch (date.day) {
        10 => PujaDay.mahalaya,
        15 => PujaDay.panchami,
        16 => PujaDay.sasthi,
        17 => PujaDay.saptami,
        18 => PujaDay.asthami,
        19 => PujaDay.nabami,
        20 => PujaDay.dashami,
        _ => date.day > 20 ? PujaDay.dashami : PujaDay.countdown,
      };
    }
    return PujaDay.countdown;
  }
}
