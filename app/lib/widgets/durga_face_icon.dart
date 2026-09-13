import 'package:flutter/material.dart';
import '../config/theme.dart';

/// Scalable, crisp vector icon depicting the traditional Bengali face of Maa Durga (দুর্গামুখ).
/// Features:
/// 1. Ornate three-peaked crown (Mukut / মুকুট)
/// 2. Vertical Third Eye (Trinayana / ত্রিনয়ন)
/// 3. Sacred Crimson Bindi (সিঁদুরের টিপ)
/// 4. Traditional winged almond eyes (পটলচেরা চোখ) with pupils
/// 5. Traditional nose ring (Nath / নথ) with dangling bead
/// 6. Serene divine smile
class DurgaFaceIcon extends StatelessWidget {
  final double size;
  final Color color;
  final Color? bindiColor;
  final bool showCrown;
  final bool showNath;

  const DurgaFaceIcon({
    super.key,
    this.size = 24.0,
    this.color = PujaColors.goldBright,
    this.bindiColor,
    this.showCrown = true,
    this.showNath = true,
  });

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          size: Size(size, size),
          painter: _DurgaFacePainter(
            color: color,
            bindiColor: bindiColor ?? const Color(0xFFD50000),
            showCrown: showCrown,
            showNath: showNath,
          ),
        ),
      ),
    );
  }
}

class _DurgaFacePainter extends CustomPainter {
  final Color color;
  final Color bindiColor;
  final bool showCrown;
  final bool showNath;

  _DurgaFacePainter({
    required this.color,
    required this.bindiColor,
    required this.showCrown,
    required this.showNath,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    canvas.save();
    canvas.scale(size.width / 100.0, size.height / 100.0);

    // Ensure stroke width maps to 1.3 - 1.8 logical pixels across any scale
    final targetLogicalStroke = (size.width < 22) ? 1.4 : (size.width < 32 ? 1.6 : 2.0);
    final strokeWidthIn100 = targetLogicalStroke / (size.width / 100.0);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidthIn100
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final bindiPaint = Paint()
      ..color = bindiColor
      ..style = PaintingStyle.fill;

    final isCompact = size.width < 22;

    // 1. CROWN (Mukut / মুকুট)
    if (showCrown && !isCompact) {
      final crownPath = Path();
      crownPath.moveTo(50, 6);
      crownPath.quadraticBezierTo(44, 14, 38, 22);
      crownPath.quadraticBezierTo(28, 15, 22, 18);
      crownPath.quadraticBezierTo(24, 24, 26, 27);
      crownPath.lineTo(74, 27);
      crownPath.quadraticBezierTo(76, 24, 78, 18);
      crownPath.quadraticBezierTo(72, 15, 62, 22);
      crownPath.quadraticBezierTo(56, 14, 50, 6);
      crownPath.close();

      canvas.drawPath(crownPath, strokePaint);
      canvas.drawCircle(const Offset(50, 18), 2.5, fillPaint);
    } else if (showCrown && isCompact) {
      // Streamlined crown arc for tiny markers
      final crownPath = Path();
      crownPath.moveTo(28, 22);
      crownPath.quadraticBezierTo(50, 8, 72, 22);
      canvas.drawPath(crownPath, strokePaint);
      canvas.drawCircle(const Offset(50, 14), 2.2, fillPaint);
    }

    // 2. THIRD EYE (Trinayana / ত্রিনয়ন)
    final triPath = Path();
    final triTop = showCrown ? 28.0 : 16.0;
    final triBottom = showCrown ? 44.0 : 32.0;
    final triMidY = (triTop + triBottom) / 2;

    triPath.moveTo(50, triTop);
    triPath.quadraticBezierTo(56, triMidY, 50, triBottom);
    triPath.quadraticBezierTo(44, triMidY, 50, triTop);
    triPath.close();
    canvas.drawPath(triPath, strokePaint);

    // Third eye pupil
    canvas.drawCircle(Offset(50, triMidY), 2.0, fillPaint);

    // 3. SACRED CRIMSON BINDI (সিঁদুরের টিপ)
    final bindiY = showCrown ? 50.5 : 40.0;
    canvas.drawCircle(Offset(50, bindiY), isCompact ? 4.8 : 4.2, bindiPaint);

    // 4. EYEBROWS (ধনুকের মতো ভ্রূ)
    final browY = showCrown ? 49.5 : 39.0;
    final leftBrow = Path();
    leftBrow.moveTo(42, browY);
    leftBrow.quadraticBezierTo(29, browY - 5.5, 14, browY + 1.5);
    canvas.drawPath(leftBrow, strokePaint);

    final rightBrow = Path();
    rightBrow.moveTo(58, browY);
    rightBrow.quadraticBezierTo(71, browY - 5.5, 86, browY + 1.5);
    canvas.drawPath(rightBrow, strokePaint);

    // 5. ALMOND EYES WITH WINGED KOHL (পটলচেরা কাজলটানা চোখ)
    final eyeCenterY = showCrown ? 58.0 : 48.0;

    // Left Eye
    final leftEyeUpper = Path();
    leftEyeUpper.moveTo(42, eyeCenterY);
    leftEyeUpper.quadraticBezierTo(29, eyeCenterY - 5.5, 15, eyeCenterY - 1.5);
    // Wing flick
    leftEyeUpper.quadraticBezierTo(12, eyeCenterY - 4.0, 8, eyeCenterY - 6.0);
    canvas.drawPath(leftEyeUpper, strokePaint);

    final leftEyeLower = Path();
    leftEyeLower.moveTo(42, eyeCenterY);
    leftEyeLower.quadraticBezierTo(29, eyeCenterY + 4.5, 15, eyeCenterY - 1.5);
    canvas.drawPath(leftEyeLower, strokePaint);

    // Left Pupil
    canvas.drawCircle(Offset(28, eyeCenterY), 2.8, fillPaint);

    // Right Eye
    final rightEyeUpper = Path();
    rightEyeUpper.moveTo(58, eyeCenterY);
    rightEyeUpper.quadraticBezierTo(71, eyeCenterY - 5.5, 85, eyeCenterY - 1.5);
    // Wing flick
    rightEyeUpper.quadraticBezierTo(88, eyeCenterY - 4.0, 92, eyeCenterY - 6.0);
    canvas.drawPath(rightEyeUpper, strokePaint);

    final rightEyeLower = Path();
    rightEyeLower.moveTo(58, eyeCenterY);
    rightEyeLower.quadraticBezierTo(71, eyeCenterY + 4.5, 85, eyeCenterY - 1.5);
    canvas.drawPath(rightEyeLower, strokePaint);

    // Right Pupil
    canvas.drawCircle(Offset(72, eyeCenterY), 2.8, fillPaint);

    // 6. NOSE & TRADITIONAL NOSE RING (নোলক / নথ)
    final noseTipY = showCrown ? 69.0 : 59.0;
    final nosePath = Path();
    nosePath.moveTo(50, eyeCenterY + 2);
    nosePath.lineTo(50, noseTipY);
    nosePath.quadraticBezierTo(51.5, noseTipY + 2.5, 54, noseTipY);
    canvas.drawPath(nosePath, strokePaint);

    if (showNath) {
      // Nath ring on the left side of the nose
      final nathCenter = Offset(41.5, noseTipY + 2.0);
      final nathRadius = isCompact ? 8.5 : 7.0;
      canvas.drawCircle(nathCenter, nathRadius, strokePaint);

      // Hanging pearl dot
      canvas.drawCircle(Offset(nathCenter.dx - 1.5, nathCenter.dy + nathRadius + 2.2), 2.2, fillPaint);
    }

    // 7. SERENE DIVINE LIPS (হাসিমুখ)
    if (!isCompact) {
      final lipsY = showCrown ? 82.0 : 72.0;
      final lipsUpper = Path();
      lipsUpper.moveTo(39, lipsY);
      lipsUpper.quadraticBezierTo(45, lipsY - 2.5, 50, lipsY);
      lipsUpper.quadraticBezierTo(55, lipsY - 2.5, 61, lipsY);
      canvas.drawPath(lipsUpper, strokePaint);

      final lipsLower = Path();
      lipsLower.moveTo(41, lipsY + 0.5);
      lipsLower.quadraticBezierTo(50, lipsY + 5.5, 59, lipsY + 0.5);
      canvas.drawPath(lipsLower, strokePaint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DurgaFacePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.bindiColor != bindiColor ||
        oldDelegate.showCrown != showCrown ||
        oldDelegate.showNath != showNath;
  }
}
