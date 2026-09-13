import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';
import '../widgets/google_logo.dart';

/// Premium, non-scrollable Welcome & Login screen for Pujo Parikrama.
/// Features high-res Maa Durga artwork, dedicated Android notification bar
/// protection (crisp white system icons, no overlap), ultra-smooth 60/120fps
/// animations, authentic Google Sign-In with vector logo, and instant guest entry.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with SingleTickerProviderStateMixin {
  late Timer _timer;
  late Duration _timeUntilPuja;
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
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
      duration: const Duration(milliseconds: 750),
    );

    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.70, curve: Curves.easeOutCubic),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.75, curve: Curves.easeOutCubic),
    ));

    _cardFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 0.90, curve: Curves.easeOutCubic),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.25, 1.0, curve: Curves.easeOutCubic),
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
      // User cancelled account selection; stay on welcome screen smoothly
    } else {
      // Descriptive error with guest fallback option
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          backgroundColor: PujaColors.nightSurface,
          content: Text(
            'Google Sign-In: ${result.errorMessage ?? "Sign-in cancelled or service unavailable."}',
            style: const TextStyle(color: Colors.white, fontSize: 12.5),
          ),
          action: SnackBarAction(
            label: 'Enter as Guest',
            textColor: PujaColors.goldBright,
            onPressed: _enterAsGuest,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 720;

    final days = _timeUntilPuja.inDays;
    final hours = _timeUntilPuja.inHours % 24;
    final minutes = _timeUntilPuja.inMinutes % 60;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Crisp white battery/wifi/clock icons on dark wallpaper
        statusBarBrightness: Brightness.dark,      // iOS dark mode status bar
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: PujaColors.nightBg,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Theme Wallpaper with RepaintBoundary for 60/120fps animation performance
            RepaintBoundary(
              child: Image.asset(
                'assets/images/durga_minimal_1.jpg',
                fit: BoxFit.cover,
                alignment: const Alignment(0, -0.3),
                errorBuilder: (context, error, stackTrace) => Container(
                  color: PujaColors.nightBg,
                  child: const Center(
                    child: Icon(Icons.temple_hindu, size: 80, color: PujaColors.festivalGold),
                  ),
                ),
              ),
            ),

            // 2. Dedicated Status Bar Shield Gradient (Guarantees battery & net symbols are never obscured)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.88),
                        Colors.black.withValues(alpha: 0.45),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Cinematic Ambient Vignette (Keeps Durga artwork visible through the glass card)
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.12),
                    const Color(0xFF140306).withValues(alpha: 0.32),
                    Colors.black.withValues(alpha: 0.75),
                  ],
                  stops: const [0.0, 0.28, 0.65, 1.0],
                ),
              ),
            ),

            // 4. Subtle Golden Radial Aura (Positioned safely below status bar)
            Positioned(
              top: 50,
              left: size.width * 0.15,
              right: size.width * 0.15,
              height: 180,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        PujaColors.festivalGold.withValues(alpha: 0.28),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 5. Main Content (Locked, non-bouncing, no finger-drag scrolling)
            SafeArea(
              top: true,
              bottom: true,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: ScrollConfiguration(
                      behavior: const ScrollBehavior().copyWith(overscroll: false),
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (!isCompact) const SizedBox(height: 8),

                            // Header Group with smooth hardware-accelerated fade/slide
                            RepaintBoundary(
                              child: FadeTransition(
                                opacity: _headerFade,
                                child: SlideTransition(
                                  position: _headerSlide,
                                  child: Column(
                                    children: [
                                      // Bengali Sacred Pill Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.55),
                                          borderRadius: BorderRadius.circular(30),
                                          border: Border.all(
                                            color: PujaColors.festivalGold.withValues(alpha: 0.6),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: PujaColors.festivalGold.withValues(alpha: 0.2),
                                              blurRadius: 12,
                                              spreadRadius: 1,
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.auto_awesome, color: PujaColors.festivalGold, size: 15),
                                            const SizedBox(width: 8),
                                            Text(
                                              'শারদীয়া দুর্গোৎসব ২০২৬',
                                              style: GoogleFonts.plusJakartaSans(
                                                color: PujaColors.festivalGold,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 12.5,
                                                letterSpacing: 0.4,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // Grand Title with Glowing Mask
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
                                            fontSize: isCompact ? 30 : 36,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.6,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                color: PujaColors.festivalGold.withValues(alpha: 0.7),
                                                blurRadius: 18,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Where Tradition Meets Divine Shakti',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: Colors.white.withValues(alpha: 0.9),
                                          fontSize: context.dynamicFont(13),
                                          letterSpacing: 0.2,
                                          fontWeight: FontWeight.w500,
                                          shadows: const [
                                            Shadow(color: Colors.black54, blurRadius: 6),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 14),

                                      // Live Countdown Capsule (Glassmorphic)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(18),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF1E0C0C).withValues(alpha: 0.55),
                                            borderRadius: BorderRadius.circular(18),
                                            border: Border.all(
                                              color: PujaColors.festivalGold.withValues(alpha: 0.35),
                                              width: 1,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),

                            // Professional Action Card (Translucent & Minimalistic)
                            RepaintBoundary(
                              child: FadeTransition(
                                opacity: _cardFade,
                                child: SlideTransition(
                                  position: _cardSlide,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(24),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 22),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1A050B).withValues(alpha: 0.42),
                                          borderRadius: BorderRadius.circular(24),
                                          border: Border.all(
                                            color: PujaColors.festivalGold.withValues(alpha: 0.35),
                                            width: 1.2,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 0.4),
                                              blurRadius: 20,
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
                                                fontSize: context.dynamicFont(17.5),
                                                fontWeight: FontWeight.w800,
                                                color: Colors.white,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 5),
                                            Text(
                                              'Discover 4,300+ Pandals, real-time crowd status, walking paths & live metro routes.',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: context.dynamicFont(12.5),
                                                color: Colors.white.withValues(alpha: 0.72),
                                                height: 1.35,
                                              ),
                                            ),
                                            const SizedBox(height: 20),

                                            // 1. Primary Action: Enter as Guest
                                            SizedBox(
                                              height: 50,
                                              child: FilledButton(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: PujaColors.durgaRed,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
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
                                                        height: 20,
                                                        width: 20,
                                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                                      )
                                                    : Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          const Icon(Icons.explore_rounded, size: 20, color: PujaColors.festivalGold),
                                                          const SizedBox(width: 10),
                                                          Text(
                                                            'Enter as Guest',
                                                            style: GoogleFonts.plusJakartaSans(
                                                              fontWeight: FontWeight.w700,
                                                              fontSize: 15,
                                                              letterSpacing: 0.2,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),

                                            const SizedBox(height: 14),

                                            // Professional "OR" Divider
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Divider(
                                                    color: Colors.white.withValues(alpha: 0.16),
                                                    thickness: 0.8,
                                                  ),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                                  child: Text(
                                                    'OR',
                                                    style: GoogleFonts.plusJakartaSans(
                                                      fontSize: 10.5,
                                                      fontWeight: FontWeight.w700,
                                                      letterSpacing: 1.4,
                                                      color: Colors.white.withValues(alpha: 0.45),
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Divider(
                                                    color: Colors.white.withValues(alpha: 0.16),
                                                    thickness: 0.8,
                                                  ),
                                                ),
                                              ],
                                            ),

                                            const SizedBox(height: 14),

                                            // 2. Secondary Action: Continue with Google (Authentic Google vector G, human-designed)
                                            SizedBox(
                                              height: 50,
                                              child: OutlinedButton(
                                                style: OutlinedButton.styleFrom(
                                                  backgroundColor: const Color(0xFF1E1E1E).withValues(alpha: 0.72),
                                                  foregroundColor: Colors.white,
                                                  side: BorderSide(
                                                    color: Colors.white.withValues(alpha: 0.22),
                                                    width: 1.2,
                                                  ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
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
                                                    const GoogleLogo(size: 20),
                                                    const SizedBox(width: 12),
                                                    Text(
                                                      'Continue with Google',
                                                      style: GoogleFonts.plusJakartaSans(
                                                        fontWeight: FontWeight.w600,
                                                        fontSize: 14.5,
                                                        color: Colors.white,
                                                        letterSpacing: 0.1,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),

                                            const SizedBox(height: 14),

                                            // Trust & Privacy Note
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                Icon(
                                                  Icons.offline_pin_rounded,
                                                  size: 13,
                                                  color: Colors.white.withValues(alpha: 0.45),
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  'Offline First • Zero Friction • Instant Access',
                                                  style: GoogleFonts.plusJakartaSans(
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w500,
                                                    color: Colors.white.withValues(alpha: 0.45),
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
                            const SizedBox(height: 16),

                            // Feature Highlights Pill
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                _buildFeatureBadge(Icons.temple_hindu, '4,300+ Pandals'),
                                _buildFeatureBadge(Icons.subway_rounded, 'Metro Routes'),
                                _buildFeatureBadge(Icons.shield_outlined, 'Crowd SOS'),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
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
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: PujaColors.festivalGold,
              fontSize: context.dynamicFont(21),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: context.dynamicFont(10),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 22,
      width: 1,
      color: Colors.white.withValues(alpha: 0.2),
    );
  }

  Widget _buildFeatureBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.dynamicIcon(12), color: PujaColors.festivalGold),
          const SizedBox(width: 4),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: context.dynamicFont(11.5),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
