import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/puja_day_theme_service.dart';
import '../utils/responsive.dart';
import '../widgets/google_logo.dart';
import '../widgets/puja_icons.dart';

/// Alias for WelcomeScreen reflecting the login/authentication functionality
typedef LoginScreen = WelcomeScreen;

/// Premium Welcome & Login screen for Pujo Parikrama.
///
/// Features the divine Maa Durga eyes motif background illustration (`login_bg_eyes.webp`),
/// defensive legibility scrim, calm upper zone with grand Bengali-styled title & countdown,
/// and the obsidian glassmorphic login card nestled cleanly in the lower dark band.
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _calculateTime());
    PujaDayThemeService.instance.addListener(_onThemeChanged);

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
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

  void _onThemeChanged() {
    if (mounted) setState(() {});
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
    PujaDayThemeService.instance.removeListener(_onThemeChanged);
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _enterAsGuest() async {
    setState(() => _isLoading = true);
    await AuthService.instance.signInAsGuest();
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.of(context).pushReplacementNamed('/greeting');
  }

  Future<void> _enterWithGoogle() async {
    setState(() => _isLoading = true);
    final result = await AuthService.instance.signInWithGoogleDetailed();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      Navigator.of(context).pushReplacementNamed('/greeting');
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
    final activeDay = PujaDayThemeService.instance.currentDay;

    final days = _timeUntilPuja.inDays;
    final hours = _timeUntilPuja.inHours % 24;
    final minutes = _timeUntilPuja.inMinutes % 60;
    final seconds = _timeUntilPuja.inSeconds % 60;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Crisp white battery/wifi/clock icons on pure black
        statusBarBrightness: Brightness.dark,      // iOS dark mode status bar
        systemNavigationBarColor: Color(0xFF0E0B0C),
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFF0E0B0C),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // 1. Background illustration: Maa Durga Eyes motif (Image 1)
            Image.asset(
              'assets/images/login_bg_eyes.webp',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF0E0B0C),
              ),
            ),

            // 2. Defensive legibility scrim (stops 0.58 to 1.0 leaving the divine eyes fully radiant)
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC0E0B0C)],
                  stops: [0.58, 1.0],
                ),
              ),
            ),

            // 3. Subtle top status bar scrim for battery/clock/title legibility
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 100,
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF0E0B0C).withValues(alpha: 0.85),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 1.0],
                    ),
                  ),
                ),
              ),
            ),

            // 4. Foreground Content mapped into calm upper zone and dark lower zone
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double eyeGap = (constraints.maxHeight - (isCompact ? 410 : 475)).clamp(12.0, 360.0);
                  return SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 440),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            children: [
                              SizedBox(height: isCompact ? 10 : 16),

                                  // Header Group (Grand Title & Pujo Parikrama)
                                  RepaintBoundary(
                                    child: FadeTransition(
                                      opacity: _headerFade,
                                      child: SlideTransition(
                                        position: _headerSlide,
                                        child: Column(
                                          children: [
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
                                                'Durga Puja',
                                                style: TextStyle(
                                                  fontFamily: 'Samarkan',
                                                  fontSize: isCompact ? 46 : 56,
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
                                              'Uma',
                                              style: TextStyle(
                                                fontFamily: 'Samarkan',
                                                fontSize: isCompact ? 16 : 19,
                                                letterSpacing: 1.5,
                                                color: PujaColors.festivalGold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 8),

                                  // Live Countdown Capsule (Sleek glassmorphic bar in upper calm zone)
                                  FadeTransition(
                                    opacity: _countdownFade,
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF141414).withValues(alpha: 0.70),
                                          borderRadius: BorderRadius.circular(16),
                                          border: Border.all(
                                            color: activeDay.primaryAccent.withValues(alpha: 0.35),
                                            width: 0.9,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            _buildCountdownItem(days.toString(), 'DAYS', activeDay.primaryAccent),
                                            _buildDivider(),
                                            _buildCountdownItem(hours.toString().padLeft(2, '0'), 'HOURS', activeDay.primaryAccent),
                                            _buildDivider(),
                                            _buildCountdownItem(minutes.toString().padLeft(2, '0'), 'MINS', activeDay.primaryAccent),
                                            _buildDivider(),
                                            _buildCountdownItem(seconds.toString().padLeft(2, '0'), 'SECS', activeDay.primaryAccent),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Eye gap opens up the canvas for Maa Durga's divine eyes in the illustration
                                  SizedBox(height: eyeGap),

                                  // Login Action Card nestled into the dark lower band of Image 1
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
                                                color: const Color(0xFF0D0D0D).withValues(alpha: 0.76),
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
                                                                PujaIcon.shankha(size: 24, color: PujaColors.festivalGold),
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
                                                          Flexible(
                                                            child: Text(
                                                              'Continue with Google',
                                                              style: GoogleFonts.plusJakartaSans(
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 14,
                                                                color: Colors.white,
                                                                letterSpacing: 0.1,
                                                              ),
                                                              maxLines: 1,
                                                              overflow: TextOverflow.ellipsis,
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
                                                      Flexible(
                                                        child: Text(
                                                          'Offline First • Zero Friction • Instant Access',
                                                          style: GoogleFonts.plusJakartaSans(
                                                            fontSize: 10.5,
                                                            fontWeight: FontWeight.w500,
                                                            color: Colors.white.withValues(alpha: 0.42),
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow.ellipsis,
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

                                SizedBox(height: isCompact ? 12 : 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountdownItem(String value, String label, [Color? accentColor]) {
    final color = accentColor ?? PujaColors.festivalGold;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: context.dynamicFont(15.5),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: context.dynamicFont(8),
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
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
}
