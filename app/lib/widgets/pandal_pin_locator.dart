import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Minimalist, high-performance vector map pin locator for pandals.
/// Directly implements the user's signature design:
/// - Sleek crimson-red teardrop map pin silhouette
/// - Concentric golden bezel ring
/// - Deep velvet maroon interior medallion
/// - Stylized golden Maa Durga Trinayana (eyes & third eye) emblem
/// - Seamless support for default, selected, visited, and trail states
class PandalPinLocator extends StatelessWidget {
  const PandalPinLocator({
    super.key,
    this.width = 34.0,
    this.height = 44.0,
    this.isSelected = false,
    this.isVisited = false,
    this.trailIndex,
    this.isCurrentTrailStop = false,
    this.clusterCount,
    this.pulseAnimation,
  });

  final double width;
  final double height;
  final bool isSelected;
  final bool isVisited;
  final int? trailIndex;
  final bool isCurrentTrailStop;
  final int? clusterCount;
  final Animation<double>? pulseAnimation;

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = isSelected ? (width * 1.25) : width;
    final effectiveHeight = isSelected ? (height * 1.25) : height;

    Widget pinWidget = RepaintBoundary(
      child: CustomPaint(
        size: Size(effectiveWidth, effectiveHeight),
        painter: _PandalPinPainter(
          isSelected: isSelected,
          isVisited: isVisited,
          trailIndex: trailIndex,
          isCurrentTrailStop: isCurrentTrailStop,
          clusterCount: clusterCount,
        ),
      ),
    );

    if (isSelected && pulseAnimation != null) {
      return AnimatedBuilder(
        animation: pulseAnimation!,
        builder: (context, child) {
          final pulse = pulseAnimation!.value;
          return Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              // Radiating golden aura pulse behind pin head
              Positioned(
                top: (effectiveWidth / 2) - (effectiveWidth * 0.65) - (8 * pulse),
                child: Container(
                  width: (effectiveWidth * 1.3) + (16 * pulse),
                  height: (effectiveWidth * 1.3) + (16 * pulse),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PujaColors.festivalGold.withValues(
                      alpha: 0.38 * (1.0 - pulse),
                    ),
                  ),
                ),
              ),
              pinWidget,
            ],
          );
        },
      );
    }

    return pinWidget;
  }
}

class _PandalPinPainter extends CustomPainter {
  final bool isSelected;
  final bool isVisited;
  final int? trailIndex;
  final bool isCurrentTrailStop;
  final int? clusterCount;

  _PandalPinPainter({
    required this.isSelected,
    required this.isVisited,
    this.trailIndex,
    this.isCurrentTrailStop = false,
    this.clusterCount,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final r = w / 2.0;
    final center = Offset(r, r);

    // 1. PIN TEARDROP BODY PATH
    final pinPath = Path();

    // The tip is at (r, h - 1.5)
    final tip = Offset(r, h - 1.2);

    // Tangent angle calculation from tip to top circle
    final d = (h - 1.2) - r;
    if (d > r) {
      final angle = math.asin(r / d);
      final leftTangentAngle = math.pi - angle;
      final rightTangentAngle = angle;

      final leftTouch = Offset(
        center.dx + r * math.cos(leftTangentAngle),
        center.dy + r * math.sin(leftTangentAngle),
      );
      final rightTouch = Offset(
        center.dx + r * math.cos(rightTangentAngle),
        center.dy + r * math.sin(rightTangentAngle),
      );

      pinPath.moveTo(tip.dx, tip.dy);
      // Smooth curve to left tangent
      pinPath.lineTo(leftTouch.dx, leftTouch.dy);
      // Arc around the top circle
      pinPath.arcTo(
        Rect.fromCircle(center: center, radius: r),
        leftTangentAngle,
        2 * math.pi - 2 * (math.pi / 2 - angle),
        false,
      );
      // Line back down to tip
      pinPath.lineTo(rightTouch.dx, rightTouch.dy);
      pinPath.close();
    } else {
      // Fallback simple teardrop if aspect ratio is squarish
      pinPath.addOval(Rect.fromCircle(center: center, radius: r));
    }

    // Drop Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isSelected ? 0.45 : 0.32)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 5.0 : 3.5);
    canvas.save();
    canvas.translate(0, isSelected ? 3.0 : 2.0);
    canvas.drawPath(pinPath, shadowPaint);
    canvas.restore();

    // 2. PIN FILL WITH VIBRANT DURGA RED GRADIENT
    final redGradient = LinearGradient(
      colors: isCurrentTrailStop
          ? [const Color(0xFFFF1744), const Color(0xFFD50000)]
          : (isVisited
              ? [const Color(0xFFC2185B), const Color(0xFF880E4F)]
              : (isSelected
                  ? [const Color(0xFFFF1744), const Color(0xFFB71C1C)]
                  : [const Color(0xFFE53935), const Color(0xFF8A0014)])),
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final fillPaint = Paint()
      ..shader = redGradient.createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, fillPaint);

    // Subtle outer pin highlight stroke
    final pinStrokePaint = Paint()
      ..color = isSelected
          ? Colors.white.withValues(alpha: 0.9)
          : const Color(0xFFFFD54F).withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.5 : 1.0;
    canvas.drawPath(pinPath, pinStrokePaint);

    // 3. CONCENTRIC GOLDEN BEZEL RING
    final goldRingRadius = r * 0.80;
    final goldPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFFFECB3),
          Color(0xFFFFD54F),
          Color(0xFFFFA000),
          Color(0xFFFFECB3),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: goldRingRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.085; // Scales proportionally
    canvas.drawCircle(center, goldRingRadius, goldPaint);

    // 4. INNER VELVET CRIMSON MEDALLION
    final innerRadius = goldRingRadius - (goldPaint.strokeWidth / 2);
    final innerPaint = Paint()
      ..color = isSelected ? const Color(0xFF5A000A) : const Color(0xFF6B000D)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerPaint);

    // 5. CENTER CONTENT: CLUSTER COUNT, TRAIL STOP, OR DURGA TRINAYANA EMBLEM
    if (clusterCount != null && clusterCount! > 1) {
      // Cluster count mode
      final text = clusterCount! > 999
          ? '${(clusterCount! / 1000).toStringAsFixed(1)}k'
          : '${clusterCount!}';
      final span = TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFFFFECB3),
          fontSize: innerRadius * 1.05,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.5,
        ),
      );
      final tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
      );
    } else if (trailIndex != null && trailIndex! >= 0) {
      // Custom Hopping Trail order index
      final text = '${trailIndex! + 1}';
      final span = TextSpan(
        text: text,
        style: TextStyle(
          color: const Color(0xFFFFECB3),
          fontSize: innerRadius * 1.15,
          fontWeight: FontWeight.w900,
        ),
      );
      final tp = TextPainter(
        text: span,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(
        canvas,
        Offset(center.dx - tp.width / 2, center.dy - tp.height / 2),
      );
    } else {
      // SACRED DURGA TRINAYANA & WINGED EYES (Iconic design from user's pin)
      _drawDurgaEyesMotif(canvas, center, innerRadius);
    }

    // 6. VISITED DARSHAN BADGE
    if (isVisited) {
      final badgeCenter = Offset(center.dx + goldRingRadius * 0.72, center.dy - goldRingRadius * 0.72);
      final badgePaint = Paint()
        ..color = const Color(0xFF00E676)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(badgeCenter, w * 0.14, badgePaint);

      final checkPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      final checkPath = Path()
        ..moveTo(badgeCenter.dx - 2.5, badgeCenter.dy)
        ..lineTo(badgeCenter.dx - 0.5, badgeCenter.dy + 2.2)
        ..lineTo(badgeCenter.dx + 3.0, badgeCenter.dy - 2.0);
      canvas.drawPath(checkPath, checkPaint);
    }
  }

  void _drawDurgaEyesMotif(Canvas canvas, Offset center, double radius) {
    // Scales to fit comfortably within radius
    final s = radius / 20.0;

    final goldStroke = Paint()
      ..color = const Color(0xFFFFECB3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.35 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final goldFill = Paint()
      ..color = const Color(0xFFFFECB3)
      ..style = PaintingStyle.fill;

    final redBindi = Paint()
      ..color = const Color(0xFFFF1744)
      ..style = PaintingStyle.fill;

    // --- Vertical Third Eye (Trinayana / ত্রিনয়ন) ---
    final triTop = center.dy - (11.0 * s);
    final triBottom = center.dy - (2.5 * s);
    final triMidY = (triTop + triBottom) / 2;

    final triPath = Path()
      ..moveTo(center.dx, triTop)
      ..quadraticBezierTo(center.dx + (4.0 * s), triMidY, center.dx, triBottom)
      ..quadraticBezierTo(center.dx - (4.0 * s), triMidY, center.dx, triTop)
      ..close();
    canvas.drawPath(triPath, goldStroke);
    // Third eye pupil
    canvas.drawCircle(Offset(center.dx, triMidY), 1.3 * s, goldFill);

    // --- Sacred Crimson Tilak / Bindi ---
    canvas.drawCircle(Offset(center.dx, triBottom + (2.0 * s)), 1.4 * s, redBindi);

    // --- Symmetrical Winged Eyes (পটলচেরা কাজলটানা চোখ) ---
    final eyeY = center.dy + (2.0 * s);
    final eyeSpan = 13.0 * s;
    final eyeInner = 2.8 * s;

    // Left Eye
    final leftInner = Offset(center.dx - eyeInner, eyeY);
    final leftOuter = Offset(center.dx - eyeSpan, eyeY - (0.5 * s));
    final leftWing = Offset(center.dx - eyeSpan - (2.6 * s), eyeY - (2.5 * s));

    final leftUpper = Path()
      ..moveTo(leftInner.dx, leftInner.dy)
      ..quadraticBezierTo(center.dx - (7.5 * s), eyeY - (4.5 * s), leftOuter.dx, leftOuter.dy)
      ..quadraticBezierTo(leftOuter.dx - (1.2 * s), leftOuter.dy - (1.0 * s), leftWing.dx, leftWing.dy);
    canvas.drawPath(leftUpper, goldStroke);

    final leftLower = Path()
      ..moveTo(leftInner.dx, leftInner.dy)
      ..quadraticBezierTo(center.dx - (7.5 * s), eyeY + (3.2 * s), leftOuter.dx, leftOuter.dy);
    canvas.drawPath(leftLower, goldStroke);

    // Left Pupil
    canvas.drawCircle(Offset(center.dx - (7.5 * s), eyeY - (0.3 * s)), 1.5 * s, goldFill);

    // Right Eye
    final rightInner = Offset(center.dx + eyeInner, eyeY);
    final rightOuter = Offset(center.dx + eyeSpan, eyeY - (0.5 * s));
    final rightWing = Offset(center.dx + eyeSpan + (2.6 * s), eyeY - (2.5 * s));

    final rightUpper = Path()
      ..moveTo(rightInner.dx, rightInner.dy)
      ..quadraticBezierTo(center.dx + (7.5 * s), eyeY - (4.5 * s), rightOuter.dx, rightOuter.dy)
      ..quadraticBezierTo(rightOuter.dx + (1.2 * s), rightOuter.dy - (1.0 * s), rightWing.dx, rightWing.dy);
    canvas.drawPath(rightUpper, goldStroke);

    final rightLower = Path()
      ..moveTo(rightInner.dx, rightInner.dy)
      ..quadraticBezierTo(center.dx + (7.5 * s), eyeY + (3.2 * s), rightOuter.dx, rightOuter.dy);
    canvas.drawPath(rightLower, goldStroke);

    // Right Pupil
    canvas.drawCircle(Offset(center.dx + (7.5 * s), eyeY - (0.3 * s)), 1.5 * s, goldFill);

    // --- Downward Tilak / Trishul Stem Flourish ---
    final stemY = triBottom + (3.5 * s);
    final stemEnd = center.dy + (8.5 * s);
    final stemPath = Path()
      ..moveTo(center.dx, stemY)
      ..lineTo(center.dx, stemEnd)
      ..moveTo(center.dx - (1.8 * s), stemEnd - (1.5 * s))
      ..quadraticBezierTo(center.dx, stemEnd + (1.5 * s), center.dx + (1.8 * s), stemEnd - (1.5 * s));
    canvas.drawPath(stemPath, goldStroke);
  }

  @override
  bool shouldRepaint(covariant _PandalPinPainter oldDelegate) {
    return oldDelegate.isSelected != isSelected ||
        oldDelegate.isVisited != isVisited ||
        oldDelegate.trailIndex != trailIndex ||
        oldDelegate.isCurrentTrailStop != isCurrentTrailStop ||
        oldDelegate.clusterCount != clusterCount;
  }
}
