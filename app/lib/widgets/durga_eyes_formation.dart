import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Interactive formation and living divine aura of Maa Durga's Eyes (চক্ষুদান).
///
/// Features:
/// 1. Pure dark aesthetic (#000000) with divine golden and crimson highlights.
/// 2. Stroke-by-stroke path animation of the traditional Bengali almond eyes,
///    eyebrows, third eye (Trinayana), and sacred red bindi.
/// 3. Seamless cross-fade to the ultra-detailed photorealistic Maa Durga eyes image.
/// 4. Continuous gentle ambient breathing pulse of the pupils and third eye aura.
/// 5. Floating sacred golden embers drifting in the dark void.
class DurgaEyesFormation extends StatefulWidget {
  final Animation<double> formationProgress;
  final double height;
  final double width;
  final bool showImage;

  const DurgaEyesFormation({
    super.key,
    required this.formationProgress,
    this.height = 230,
    this.width = double.infinity,
    this.showImage = true,
  });

  @override
  State<DurgaEyesFormation> createState() => _DurgaEyesFormationState();
}

class _DurgaEyesFormationState extends State<DurgaEyesFormation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  final List<_EmberParticle> _embers = [];
  final math.Random _random = math.Random(42);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _pulseAnimation = CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOutSine,
    );

    // Seed floating golden embers
    for (int i = 0; i < 24; i++) {
      _embers.add(_EmberParticle(
        x: _random.nextDouble(),
        y: _random.nextDouble(),
        size: 1.2 + _random.nextDouble() * 2.4,
        speed: 0.003 + _random.nextDouble() * 0.007,
        alpha: 0.2 + _random.nextDouble() * 0.6,
        phase: _random.nextDouble() * math.pi * 2,
      ));
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([widget.formationProgress, _pulseAnimation]),
      builder: (context, _) {
        final progress = widget.formationProgress.value;
        final pulse = _pulseAnimation.value;

        // Image blend kicks in as the strokes establish (0.35 -> 1.0)
        final imageOpacity = (progress >= 0.35)
            ? ((progress - 0.35) / 0.65).clamp(0.0, 1.0)
            : 0.0;

        return SizedBox(
          height: widget.height,
          width: widget.width,
          child: Stack(
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              // 1. Ambient Golden Radiance Behind the Eyes
              if (progress > 0.15)
                Positioned.fill(
                  child: Opacity(
                    opacity: ((progress - 0.15) / 0.85).clamp(0.0, 0.45 + (pulse * 0.15)),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.1),
                          radius: 0.65,
                          colors: [
                            PujaColors.festivalGold.withValues(alpha: 0.35),
                            const Color(0xFFD32F2F).withValues(alpha: 0.12),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),

              // 2. Photorealistic High-Res Eyes Layer (Seamlessly blended into dark void)
              if (widget.showImage && imageOpacity > 0.01)
                Positioned.fill(
                  child: Opacity(
                    opacity: imageOpacity,
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                            Colors.black,
                            Colors.transparent,
                          ],
                          stops: [0.0, 0.08, 0.90, 1.0],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.asset(
                        'assets/images/durga_eyes_black.jpg',
                        fit: BoxFit.cover,
                        alignment: const Alignment(0, -0.06),
                        errorBuilder: (_, _, _) => const SizedBox.shrink(),
                      ),
                    ),
                  ),
                ),

              // 3. Dynamic Vector Stroke-by-Stroke Drawing of the Eyes & Bindi (Dissolves as photo reveals)
              CustomPaint(
                size: Size(widget.width, widget.height),
                painter: _DurgaEyesVectorPainter(
                  formationProgress: progress,
                  pulseValue: pulse,
                  embers: _embers,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _EmberParticle {
  double x;
  double y;
  final double size;
  final double speed;
  final double alpha;
  final double phase;

  _EmberParticle({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.alpha,
    required this.phase,
  });

  void update() {
    y -= speed;
    if (y < 0.0) {
      y = 1.0;
      x = (x + 0.1) % 1.0;
    }
  }
}

class _DurgaEyesVectorPainter extends CustomPainter {
  final double formationProgress;
  final double pulseValue;
  final List<_EmberParticle> embers;

  _DurgaEyesVectorPainter({
    required this.formationProgress,
    required this.pulseValue,
    required this.embers,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final cx = size.width / 2;
    final cy = size.height * 0.52;
    final scale = math.min(size.width / 380, size.height / 220);

    // Update & draw golden embers floating around
    if (formationProgress > 0.2) {
      final emberPaint = Paint()..style = PaintingStyle.fill;
      for (final ember in embers) {
        ember.update();
        final currentAlpha = (ember.alpha * formationProgress * (0.6 + 0.4 * math.sin(ember.phase + pulseValue * 3)))
            .clamp(0.0, 1.0);
        emberPaint.color = PujaColors.goldBright.withValues(alpha: currentAlpha);
        canvas.drawCircle(
          Offset(ember.x * size.width, ember.y * size.height),
          ember.size * scale,
          emberPaint,
        );
      }
    }

    // Dissolve factor for vector strokes as the photorealistic image reaches full vibrancy (0.40 -> 0.70)
    final strokeDissolve = (formationProgress < 0.40)
        ? 1.0
        : (1.0 - ((formationProgress - 0.40) / 0.30)).clamp(0.0, 1.0);

    // 1. THIRD EYE (Trinayana) & RED BINDI (Forms first: 0.0 -> 0.4, then dissolves into photo)
    final bindiProgress = (formationProgress / 0.4).clamp(0.0, 1.0);
    if (bindiProgress > 0.01 && strokeDissolve > 0.01) {
      final bindiY = cy - 22 * scale;
      final bindiRadius = 8.5 * scale * Curves.easeOutBack.transform(bindiProgress);

      // Crimson Bindi Outer Halo
      final haloPaint = Paint()
        ..color = const Color(0xFFFF1744).withValues(alpha: (0.35 * bindiProgress + 0.15 * pulseValue) * strokeDissolve)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
      canvas.drawCircle(Offset(cx, bindiY), bindiRadius * 1.8, haloPaint);

      // Sacred Red Bindi Solid
      final bindiPaint = Paint()
        ..color = const Color(0xFFD50000).withValues(alpha: strokeDissolve)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, bindiY), bindiRadius, bindiPaint);

      // Gold dot in center of bindi
      final goldDotPaint = Paint()
        ..color = PujaColors.goldBright.withValues(alpha: 0.9 * bindiProgress * strokeDissolve)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, bindiY), bindiRadius * 0.28, goldDotPaint);

      // Third Eye (Trinayana) vertically above bindi
      final trinayanaProgress = ((formationProgress - 0.1) / 0.35).clamp(0.0, 1.0);
      if (trinayanaProgress > 0.05) {
        final triCy = cy - 54 * scale;
        final triHeight = 24 * scale * trinayanaProgress;
        final triWidth = 11 * scale * trinayanaProgress;

        final triPath = Path();
        triPath.moveTo(cx, triCy - triHeight);
        triPath.quadraticBezierTo(cx + triWidth, triCy, cx, triCy + triHeight);
        triPath.quadraticBezierTo(cx - triWidth, triCy, cx, triCy - triHeight);
        triPath.close();

        // Glowing outline for Trinayana
        final triGlow = Paint()
          ..color = PujaColors.festivalGold.withValues(alpha: (0.5 + 0.3 * pulseValue) * trinayanaProgress * strokeDissolve)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2 * scale
          ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);
        canvas.drawPath(triPath, triGlow);

        final triStroke = Paint()
          ..color = PujaColors.goldBright.withValues(alpha: 0.9 * trinayanaProgress * strokeDissolve)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4 * scale;
        canvas.drawPath(triPath, triStroke);

        // Center golden pupil for third eye
        final triPupil = Paint()
          ..color = const Color(0xFFFFD700).withValues(alpha: 0.85 * trinayanaProgress * strokeDissolve)
          ..style = PaintingStyle.fill;
        canvas.drawCircle(Offset(cx, triCy), 3.2 * scale * trinayanaProgress, triPupil);
      }
    }

    // 2. TRADITIONAL ALMOND EYES & EYEBROWS (Forms: 0.2 -> 0.65, dissolves into photo by 0.70)
    final eyesProgress = ((formationProgress - 0.2) / 0.7).clamp(0.0, 1.0);
    if (eyesProgress > 0.01 && strokeDissolve > 0.01) {
      final strokePaint = Paint()
        ..color = PujaColors.goldBright.withValues(alpha: 0.9 * strokeDissolve)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2 * scale
        ..strokeCap = StrokeCap.round;

      final glowStrokePaint = Paint()
        ..color = PujaColors.festivalGold.withValues(alpha: 0.5 * strokeDissolve)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.5 * scale
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 4);

      // Eye dimensions relative to center
      final eyeOffsetX = 56 * scale;
      final eyeWidth = 58 * scale;
      final eyeHeight = 18 * scale;

      // Draw Left Eye & Right Eye paths symmetrically
      _drawEye(
        canvas: canvas,
        cx: cx - eyeOffsetX - (eyeWidth / 2),
        cy: cy,
        width: eyeWidth,
        height: eyeHeight,
        scale: scale,
        progress: eyesProgress,
        isLeft: true,
        paint: strokePaint,
        glowPaint: glowStrokePaint,
      );

      _drawEye(
        canvas: canvas,
        cx: cx + eyeOffsetX + (eyeWidth / 2),
        cy: cy,
        width: eyeWidth,
        height: eyeHeight,
        scale: scale,
        progress: eyesProgress,
        isLeft: false,
        paint: strokePaint,
        glowPaint: glowStrokePaint,
      );
    }

    // 3. LIVING PUPIL & THIRD EYE LUMINESCENCE (Active once photorealistic eyes materialize)
    if (formationProgress > 0.65) {
      final breatheProgress = ((formationProgress - 0.65) / 0.35).clamp(0.0, 1.0);
      final breatheAlpha = (0.28 + 0.32 * pulseValue) * breatheProgress;

      // Left and right pupil coordinates in BoxFit.cover alignment(0, -0.06)
      final photoPupilY = cy + 10 * scale;
      final photoPupilOffsetX = 80 * scale;

      final pupilGlowPaint = Paint()
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      // Golden breathing halo over pupils
      pupilGlowPaint.color = const Color(0xFFFFD54F).withValues(alpha: breatheAlpha * 0.45);
      canvas.drawCircle(Offset(cx - photoPupilOffsetX, photoPupilY), 12 * scale, pupilGlowPaint);
      canvas.drawCircle(Offset(cx + photoPupilOffsetX, photoPupilY), 12 * scale, pupilGlowPaint);

      // Inner intense core pulse
      final corePaint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFFE082),
          Colors.white,
          pulseValue,
        )!.withValues(alpha: breatheAlpha * 0.7)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx - photoPupilOffsetX, photoPupilY), 3.2 * scale, corePaint);
      canvas.drawCircle(Offset(cx + photoPupilOffsetX, photoPupilY), 3.2 * scale, corePaint);

      // Third eye subtle breathing aura
      final triAura = Paint()
        ..color = PujaColors.festivalGold.withValues(alpha: breatheAlpha * 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(cx, cy - 62 * scale), 8 * scale, triAura);
    }
  }

  void _drawEye({
    required Canvas canvas,
    required double cx,
    required double cy,
    required double width,
    required double height,
    required double scale,
    required double progress,
    required bool isLeft,
    required Paint paint,
    required Paint glowPaint,
  }) {
    // 1. Upper eyelid curve with prominent Bengali wing
    final upperPath = Path();
    final innerX = isLeft ? cx + width * 0.48 : cx - width * 0.48;
    final outerX = isLeft ? cx - width * 0.62 : cx + width * 0.62;
    final peakY = cy - height * 1.05;

    upperPath.moveTo(innerX, cy + height * 0.1);
    upperPath.cubicTo(
      innerX - (isLeft ? width * 0.3 : -width * 0.3), peakY,
      cx, peakY - height * 0.15,
      outerX, cy - height * 0.35,
    );

    // Wing flick at the outer corner
    final wingX = isLeft ? outerX - 12 * scale : outerX + 12 * scale;
    final wingY = cy - height * 0.8;
    upperPath.quadraticBezierTo(outerX, cy - height * 0.5, wingX, wingY);

    _renderAnimatedPath(canvas, upperPath, progress, paint, glowPaint);

    // 2. Lower kohl line
    if (progress > 0.25) {
      final lowerProgress = ((progress - 0.25) / 0.75).clamp(0.0, 1.0);
      final lowerPath = Path();
      lowerPath.moveTo(innerX, cy + height * 0.1);
      lowerPath.quadraticBezierTo(
        cx, cy + height * 0.85,
        outerX, cy - height * 0.25,
      );
      _renderAnimatedPath(canvas, lowerPath, lowerProgress, paint, glowPaint);
    }

    // 3. Eyebrow sweeping gracefully above
    if (progress > 0.35) {
      final browProgress = ((progress - 0.35) / 0.65).clamp(0.0, 1.0);
      final browPath = Path();
      final browInnerX = isLeft ? cx + width * 0.35 : cx - width * 0.35;
      final browOuterX = isLeft ? cx - width * 0.75 : cx + width * 0.75;
      final browPeakY = cy - height * 2.3;

      browPath.moveTo(browInnerX, cy - height * 1.3);
      browPath.quadraticBezierTo(
        cx, browPeakY,
        browOuterX, cy - height * 1.5,
      );

      final browPaint = Paint()
        ..color = const Color(0xFFE5A93C).withValues(alpha: 0.75 * browProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0 * scale
        ..strokeCap = StrokeCap.round;

      _renderAnimatedPath(canvas, browPath, browProgress, browPaint, null);
    }

    // 4. Golden Iris and Pupil radiating with alive pulse
    if (progress > 0.45) {
      final irisProgress = ((progress - 0.45) / 0.55).clamp(0.0, 1.0);
      final irisRadius = 9.5 * scale * irisProgress;

      // Golden ring
      final irisRingPaint = Paint()
        ..color = PujaColors.goldBright.withValues(alpha: 0.7 * irisProgress)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8 * scale;
      canvas.drawCircle(Offset(cx, cy), irisRadius, irisRingPaint);

      // Pupil with breathing golden luminescence
      final pupilPaint = Paint()
        ..color = Color.lerp(
          const Color(0xFFFFD54F),
          const Color(0xFFFFECB3),
          pulseValue,
        )!.withValues(alpha: 0.85 * irisProgress)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx, cy), 4.2 * scale * irisProgress, pupilPaint);

      // Tiny white eye-catch highlight
      final highlightPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.9 * irisProgress)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(cx + 2.5 * scale, cy - 2.5 * scale), 1.5 * scale, highlightPaint);
    }
  }

  void _renderAnimatedPath(
    Canvas canvas,
    Path path,
    double progress,
    Paint paint,
    Paint? glowPaint,
  ) {
    if (progress <= 0.0) return;

    for (final ui.PathMetric metric in path.computeMetrics()) {
      final extractLength = metric.length * progress;
      final extractedPath = metric.extractPath(0.0, extractLength);
      if (glowPaint != null) {
        canvas.drawPath(extractedPath, glowPaint);
      }
      canvas.drawPath(extractedPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _DurgaEyesVectorPainter oldDelegate) {
    return oldDelegate.formationProgress != formationProgress ||
        oldDelegate.pulseValue != pulseValue;
  }
}
