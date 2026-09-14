import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../widgets/durga_eyes_formation.dart';
import '../widgets/durga_face_icon.dart';
import '../widgets/google_logo.dart';

/// Premium, non-scrollable Welcome & Login screen for Pujo Parikrama.
/// Features a pure dark OLED background, the divine eyes of Maa Durga prominently
/// visible with an animated Chokkhu Daan stroke-formation effect, an ambient breathing
/// pupil glow, countdown capsule, authentic Google Sign-In, and instant guest entry.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _timeUntilPuja;
  late final AnimationController _entranceController;
  late final Animation<double> _eyesFormation;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _countdownFade;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  bool _isLoading = false;

  // Target: Durga Puja 2026 Maha Shasthi (mid October 2026)
  final DateTime _pujaDate = DateTime(2026, 10, 16, 6, 0, 0);

  @override
  void initState() {
    super.initState();
    _calculateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _calculateTime());

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _eyesFormation = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.70, curve: Curves.easeOutQuart),
    );

    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.10, 0.50, curve: Curves.easeOutCubic),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.10, 0.55, curve: Curves.easeOutCubic),
    ));

    _countdownFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.35, 0.70, curve: Curves.easeOutCubic),
    );

    _cardFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.40, 0.88, curve: Curves.easeOutCubic),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.40, 1.0, curve: Curves.easeOutCubic),
    ));

    _entranceController.forward();
  }

  void _calculateTime() {
    final now = DateTime.now();
    setState(() {
      _timeUntilPuja = _pujaDate.isAfter(now)
          ? _pujaDate.difference(now)
          : Duration.zero;
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _enterAsGuest() async {
    setState(() => _isLoading = true);
    await AuthService.instance.signInAsGuest();
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacementNamed('/main');
  }

  Future<void> _enterWithGoogle() async {
    setState(() => _isLoading = true);
    final result = await AuthService.instance.signInWithGoogleDetailed();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.of(context).pushReplacementNamed('/main');
    } else if (result.isCancelled) {
      // User dismissed the Google account prompt
    } else {
      // Real Google Sign-In failed; notify user of the exact error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: PujaColors.durgaRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            result.errorMessage ?? 'Google Sign-In failed. Please verify your Firebase SHA-1 setup.',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 740;

    final days = _timeUntilPuja.inDays;
    final hours = _timeUntilPuja.inHours % 24;
    final minutes = _timeUntilPuja.inMinutes % 60;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Crisp white battery/wifi/clock icons on pure black
        statusBarBrightness: Brightness.dark,      // iOS dark mode status bar
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: Colors.black, // Pure complete dark background
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Pure Black Background Base
            Container(color: Colors.black),

            // 2. Dedicated Status Bar Shield Gradient
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.95),
                        Colors.black.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Subtle Ambient Golden/Crimson Aura in Background
            Positioned(
              top: size.height * 0.16,
              left: size.width * 0.10,
              right: size.width * 0.10,
              height: 240,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        PujaColors.festivalGold.withValues(alpha: 0.16),
                        const Color(0xFF800020).withValues(alpha: 0.08),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 4. Main Scrollable Content (Seamless, non-overflowing)
            SafeArea(
              top: true,
              bottom: true,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: ScrollConfiguration(
                    behavior: const ScrollBehavior().copyWith(overscroll: false),
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 4),

                          // Header Group (Title & Sacred Badge)
                          RepaintBoundary(
                            child: FadeTransition(
                              opacity: _headerFade,
                              child: SlideTransition(
                                position: _headerSlide,
                                child: Column(
                                  children: [
                                    // Bengali Sacred Pill Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(alpha: 0.7),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: PujaColors.festivalGold.withValues(alpha: 0.5),
                                          width: 1.1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: PujaColors.festivalGold.withValues(alpha: 0.18),
                                            blurRadius: 10,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.auto_awesome, color: PujaColors.festivalGold, size: 14),
                                          const SizedBox(width: 7),
                                          Text(
                                            'শারদীয়া দুর্গোৎসব ২০২৬',
                                            style: GoogleFonts.plusJakartaSans(
                                              color: PujaColors.festivalGold,
                                              fontWeight: FontWeight.w700,
                                              fontSize: 12,
                                              letterSpacing: 0.4,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),

                                    // Grand Title with Golden Shimmer
                                    ShaderMask(
                                      shaderCallback: (bounds) => const LinearGradient(
                                        colors: [
                                          Color(0xFFFFFFFF),
                                          Color(0xFFFFF3D6),
                                          Color(0xFFFFD54F),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ).createShader(bounds),
                                      child: Text(
                                        'Pujo Parikrama',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: isCompact ? 28 : 34,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.6,
                                          color: Colors.white,
                                          shadows: [
                                            Shadow(
                                              color: PujaColors.festivalGold.withValues(alpha: 0.7),
                                              blurRadius: 16,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Where Tradition Meets Divine Shakti',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.plusJakartaSans(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: context.dynamicFont(12),
                                        letterSpacing: 0.2,
                                        fontWeight: FontWeight.w500,
                                        shadows: const [
                                          Shadow(color: Colors.black87, blurRadius: 6),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 6),

                          // 5. MAA DURGA'S DIVINE EYES (Prominently visible with formation animation)
                          // Tapping the eyes replays the sacred stroke formation
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _entranceController.forward(from: 0.0);
                            },
                            child: DurgaEyesFormation(
                              formationProgress: _eyesFormation,
                              height: isCompact ? 180 : 225,
                              width: double.infinity,
                              showImage: true,
                            ),
                          ),

                          const SizedBox(height: 6),

                          // 6. Live Countdown Capsule (Sleek, low-profile glassmorphic bar)
                          FadeTransition(
                            opacity: _countdownFade,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141414).withValues(alpha: 0.65),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: PujaColors.festivalGold.withValues(alpha: 0.28),
                                    width: 0.9,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildCountdownItem(days.toString(), 'DAYS'),
                                    _buildDivider(),
                                    _buildCountdownItem(hours.toString().padLeft(2, '0'), 'HOURS'),
                                    _buildDivider(),
                                    _buildCountdownItem(minutes.toString().padLeft(2, '0'), 'MINS'),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // 7. Login Action Card (Obsidian glassmorphism nestled below the eyes)
                          RepaintBoundary(
                            child: FadeTransition(
                              opacity: _cardFade,
                              child: SlideTransition(
                                position: _cardSlide,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(22),
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF0D0D0D).withValues(alpha: 0.72),
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: PujaColors.festivalGold.withValues(alpha: 0.35),
                                          width: 1.1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.6),
                                            blurRadius: 22,
                                            offset: const Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            'Begin Your Parikrama',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: context.dynamicFont(16.5),
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Discover 380+ Verified Pandals, real-time crowd status, walking paths & live metro routes.',
                                            textAlign: TextAlign.center,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: context.dynamicFont(11.8),
                                              color: Colors.white.withValues(alpha: 0.72),
                                              height: 1.35,
                                            ),
                                          ),
                                          const SizedBox(height: 16),

                                          // 1. Primary Action: Enter as Guest
                                          SizedBox(
                                            height: 48,
                                            child: FilledButton(
                                              style: FilledButton.styleFrom(
                                                backgroundColor: PujaColors.durgaRed,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(13),
                                                  side: BorderSide(
                                                    color: PujaColors.festivalGold.withValues(alpha: 0.5),
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                              onPressed: _isLoading
                                                  ? null
                                                  : () {
                                                      HapticFeedback.lightImpact();
                                                      _enterAsGuest();
                                                    },
                                              child: _isLoading
                                                  ? const SizedBox(
                                                      height: 18,
                                                      width: 18,
                                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                    )
                                                  : Row(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        const Icon(Icons.explore_rounded, size: 19, color: PujaColors.festivalGold),
                                                        const SizedBox(width: 9),
                                                        Text(
                                                          'Enter as Guest',
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 14.5,
                                                            letterSpacing: 0.2,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                            ),
                                          ),

                                          const SizedBox(height: 11),

                                          // Professional "OR" Divider
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Divider(
                                                  color: Colors.white.withValues(alpha: 0.15),
                                                  thickness: 0.8,
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                                child: Text(
                                                  'OR',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w700,
                                                    letterSpacing: 1.4,
                                                    color: Colors.white.withValues(alpha: 0.45),
                                                  ),
                                                ),
                                              ),
                                              Expanded(
                                                child: Divider(
                                                  color: Colors.white.withValues(alpha: 0.15),
                                                  thickness: 0.8,
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 11),

                                          // 2. Secondary Action: Continue with Google
                                          SizedBox(
                                            height: 48,
                                            child: OutlinedButton(
                                              style: OutlinedButton.styleFrom(
                                                backgroundColor: const Color(0xFF181818).withValues(alpha: 0.8),
                                                foregroundColor: Colors.white,
                                                side: BorderSide(
                                                  color: Colors.white.withValues(alpha: 0.2),
                                                  width: 1.1,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(13),
                                                ),
                                              ),
                                              onPressed: _isLoading
                                                  ? null
                                                  : () {
                                                      HapticFeedback.lightImpact();
                                                      _enterWithGoogle();
                                                    },
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const GoogleLogo(size: 19),
                                                  const SizedBox(width: 11),
                                                  Text(
                                                    'Continue with Google',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontWeight: FontWeight.w600,
                                                      fontSize: 14,
                                                      color: Colors.white,
                                                      letterSpacing: 0.1,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),

                                          const SizedBox(height: 11),

                                          // Trust & Privacy Note
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.offline_pin_rounded,
                                                size: 12,
                                                color: Colors.white.withValues(alpha: 0.42),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Offline First • Zero Friction • Instant Access',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 10.5,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.white.withValues(alpha: 0.42),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Feature Highlights Pill
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 5,
                            children: [
                              _buildFeatureBadge(
                                null,
                                '380+ Pandals',
                                customIcon: DurgaFaceIcon(
                                  size: context.dynamicIcon(13),
                                  color: PujaColors.festivalGold,
                                  bindiColor: const Color(0xFFFF1744),
                                ),
                              ),
                              _buildFeatureBadge(Icons.subway_rounded, 'Metro Routes'),
                              _buildFeatureBadge(Icons.shield_outlined, 'Crowd SOS'),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownItem(String value, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: PujaColors.festivalGold,
              fontSize: context.dynamicFont(17),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: context.dynamicFont(9),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 18,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withValues(alpha: 0.18),
    );
  }

  Widget _buildFeatureBadge(IconData? icon, String text, {Widget? customIcon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          customIcon ??
              Icon(icon!, size: context.dynamicIcon(11.5), color: PujaColors.festivalGold),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: context.dynamicFont(11),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
