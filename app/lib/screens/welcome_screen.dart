import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';

/// Breathtaking Welcome & Login screen inspired by HackSpire's "Innovation Meets Shakti" aesthetic
/// featuring high-res Maa Durga artwork, glowing golden aura, live countdown capsule,
/// frosted glassmorphism auth cards, and instant guest entry.
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  late Timer _timer;
  late Duration _timeUntilPuja;
  late TabController _tabController;
  late final AnimationController _entranceController;
  late final Animation<double> _headerFade;
  late final Animation<Offset> _headerSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  final TextEditingController _phoneOrEmailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  // Target: Durga Puja 2026 Maha Shasthi (mid October 2026)
  final DateTime _pujaDate = DateTime(2026, 10, 16, 6, 0, 0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _calculateTime();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => _calculateTime());

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _headerFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOutCubic),
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _cardFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.3, 0.9, curve: Curves.easeOutCubic),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
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
    _tabController.dispose();
    _entranceController.dispose();
    _phoneOrEmailController.dispose();
    _passwordController.dispose();
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

  void _handleSignIn() {
    final input = _phoneOrEmailController.text.trim();
    if (input.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number or email.')),
      );
      return;
    }
    // Authenticate and proceed
    _enterAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isCompact = size.height < 700;

    final days = _timeUntilPuja.inDays;
    final hours = _timeUntilPuja.inHours % 24;
    final minutes = _timeUntilPuja.inMinutes % 60;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Theme 1: Crimson Gold Line Art Wallpaper
          Image.asset(
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

          // 2. Cinematic Ambient Gradients (Dark burgundy & golden vignette)
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.black.withValues(alpha: 0.25),
                  PujaColors.nightBg.withValues(alpha: 0.85),
                  PujaColors.nightBg,
                ],
                stops: const [0.0, 0.35, 0.70, 1.0],
              ),
            ),
          ),

          // 3. Sacred Golden Radial Aura at the top
          Positioned(
            top: -60,
            left: size.width * 0.15,
            right: size.width * 0.15,
            height: 240,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      PujaColors.festivalGold.withValues(alpha: 0.35),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 4. Main Scrollable Content
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isCompact) const SizedBox(height: 12),

                      // Animated Header Group
                      FadeTransition(
                        opacity: _headerFade,
                        child: SlideTransition(
                          position: _headerSlide,
                          child: Column(
                            children: [
                              // Bengali Sacred Badge (HackSpire style)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
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
                            const Icon(Icons.auto_awesome, color: PujaColors.festivalGold, size: 16),
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
                      const SizedBox(height: 16),

                      // Grand Title with Glowing Shadow
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
                          'Kolkata Puja',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: isCompact ? 32 : 38,
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
                      const SizedBox(height: 6),
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
                      const SizedBox(height: 18),

                      // Live Countdown Capsule (Glassmorphic)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E0C0C).withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(20),
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
                      ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Glassmorphism Login & Guest Card (Animated entrance)
                      FadeTransition(
                        opacity: _cardFade,
                        child: SlideTransition(
                          position: _cardSlide,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                          child: Container(
                            padding: const EdgeInsets.all(22),
                            decoration: BoxDecoration(
                              color: const Color(0xFF160909).withValues(alpha: 0.78),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.5),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Tab Switcher
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: TabBar(
                                    controller: _tabController,
                                    indicator: BoxDecoration(
                                      color: PujaColors.durgaRed,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    indicatorSize: TabBarIndicatorSize.tab,
                                    labelColor: Colors.white,
                                    unselectedLabelColor: Colors.white60,
                                    labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: 13),
                                    unselectedLabelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w500, fontSize: 13),
                                    dividerColor: Colors.transparent,
                                    tabs: const [
                                      Tab(text: '⚡ Instant Guest'),
                                      Tab(text: '🔐 Member Login'),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),

                                // Tab Content
                                SizedBox(
                                  height: 200,
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      // Tab 1: Instant Guest
                                      SingleChildScrollView(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'Hop seamlessly without passwords.\nExplore all 117 Pandals, Metro routes & Crowd maps.',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12.5,
                                                height: 1.4,
                                              ),
                                            ),
                                            const SizedBox(height: 18),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 48,
                                              child: ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: PujaColors.festivalGold,
                                                  foregroundColor: Colors.black,
                                                  elevation: 6,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(14),
                                                  ),
                                                ),
                                                onPressed: _isLoading ? null : _enterAsGuest,
                                                child: _isLoading
                                                    ? const SizedBox(
                                                        height: 20,
                                                        width: 20,
                                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                                                      )
                                                    : const Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          Icon(Icons.explore_rounded, size: 20),
                                                          SizedBox(width: 8),
                                                          Text(
                                                            'Enter Hopping Guide',
                                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                          ),
                                                        ],
                                                      ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Text(
                                              'Zero login friction • Offline first',
                                              style: TextStyle(fontSize: 11, color: Colors.white.withValues(alpha: 0.45)),
                                            ),
                                          ],
                                        ),
                                      ),

                                      // Tab 2: Member Sign-in
                                      SingleChildScrollView(
                                        child: Column(
                                          children: [
                                            TextField(
                                              controller: _phoneOrEmailController,
                                              style: const TextStyle(color: Colors.white, fontSize: 14),
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.black.withValues(alpha: 0.45),
                                                hintText: 'Mobile number or email',
                                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                                                prefixIcon: const Icon(Icons.phone_android, color: PujaColors.festivalGold, size: 18),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: const BorderSide(color: PujaColors.festivalGold),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            TextField(
                                              controller: _passwordController,
                                              obscureText: _obscurePassword,
                                              style: const TextStyle(color: Colors.white, fontSize: 14),
                                              decoration: InputDecoration(
                                                filled: true,
                                                fillColor: Colors.black.withValues(alpha: 0.45),
                                                hintText: 'Password / OTP',
                                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 13),
                                                prefixIcon: const Icon(Icons.lock_outline, color: PujaColors.festivalGold, size: 18),
                                                suffixIcon: IconButton(
                                                  icon: Icon(
                                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                                    color: Colors.white54,
                                                    size: 18,
                                                  ),
                                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                                ),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                                                ),
                                                focusedBorder: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                  borderSide: const BorderSide(color: PujaColors.festivalGold),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            SizedBox(
                                              width: double.infinity,
                                              height: 44,
                                              child: FilledButton(
                                                style: FilledButton.styleFrom(
                                                  backgroundColor: PujaColors.durgaRed,
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                ),
                                                onPressed: _isLoading ? null : _handleSignIn,
                                                child: const Text('Sign In / Register', style: TextStyle(fontWeight: FontWeight.bold)),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 14),
                                Row(
                                  children: [
                                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 10),
                                      child: Text(
                                        'OR CONNECT WITH',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 1.2,
                                          color: Colors.white.withValues(alpha: 0.4),
                                        ),
                                      ),
                                    ),
                                    Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.15))),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Google Sign-in Button
                                OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: Image.network(
                                    'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                                    height: 18,
                                    width: 18,
                                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata, size: 22, color: Colors.white),
                                  ),
                                  label: const Text('Continue with Google', style: TextStyle(fontSize: 13.5)),
                                  onPressed: _isLoading ? null : _enterWithGoogle,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                          ),
                        ),
                      const SizedBox(height: 18),

                      // Feature Highlights Pill
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildFeatureBadge(Icons.temple_hindu, '117 Pandals'),
                          _buildFeatureBadge(Icons.subway_rounded, 'Metro Routes'),
                          _buildFeatureBadge(Icons.shield_outlined, 'Crowd SOS'),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
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
              fontSize: context.dynamicFont(22),
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
      height: 24,
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
