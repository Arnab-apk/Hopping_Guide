import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../config/theme.dart';
import '../models/food_spot.dart';
import '../models/metro_station.dart';
import '../models/pandal.dart';
import '../widgets/crowd_badge.dart';

enum LeafletPinCategory {
  pandal,
  restaurant,
  metro,
  cluster,
  custom,
}

/// Authentic Leaflet.js-style vector map pin marker.
/// Renders the iconic teardrop pin silhouette with sharp bottom tip,
/// ground drop shadow, metallic bezel, and themed inner medallion.
class LeafletMarkerPin extends StatelessWidget {
  const LeafletMarkerPin({
    super.key,
    required this.category,
    this.width = 34.0,
    this.height = 44.0,
    this.size,
    this.isSelected = false,
    this.isVisited = false,
    this.trailIndex,
    this.isCurrentTrailStop = false,
    this.clusterCount,
    this.accentColor,
    this.pinColor,
    this.customIcon,
    this.isRailway = false,
    this.pulseAnimation,
  });

  final LeafletPinCategory category;
  final double width;
  final double height;
  final double? size;
  final bool isSelected;
  final bool isVisited;
  final int? trailIndex;
  final bool isCurrentTrailStop;
  final int? clusterCount;
  final Color? accentColor;
  final Color? pinColor;
  final IconData? customIcon;
  final bool isRailway;
  final Animation<double>? pulseAnimation;

  /// Convenience constructor for Puja Pandals
  factory LeafletMarkerPin.pandal({
    Key? key,
    double width = 34.0,
    double height = 44.0,
    double? size,
    bool isSelected = false,
    bool isVisited = false,
    int? trailIndex,
    bool isCurrentTrailStop = false,
    int? clusterCount,
    Animation<double>? pulseAnimation,
  }) {
    final baseW = size ?? width;
    final baseH = size != null ? (size * 1.28) : height;
    return LeafletMarkerPin(
      key: key,
      category: clusterCount != null && clusterCount > 1
          ? LeafletPinCategory.cluster
          : LeafletPinCategory.pandal,
      width: baseW,
      height: baseH,
      size: size,
      isSelected: isSelected,
      isVisited: isVisited,
      trailIndex: trailIndex,
      isCurrentTrailStop: isCurrentTrailStop,
      clusterCount: clusterCount,
      pulseAnimation: pulseAnimation,
    );
  }

  /// Convenience constructor for Restaurants / Food Spots
  factory LeafletMarkerPin.restaurant({
    Key? key,
    double width = 34.0,
    double height = 44.0,
    bool isSelected = false,
    Animation<double>? pulseAnimation,
  }) {
    return LeafletMarkerPin(
      key: key,
      category: LeafletPinCategory.restaurant,
      width: width,
      height: height,
      isSelected: isSelected,
      pulseAnimation: pulseAnimation,
    );
  }

  /// Convenience constructor for Metro & Railway Stations
  factory LeafletMarkerPin.metro({
    Key? key,
    double width = 34.0,
    double height = 44.0,
    bool isSelected = false,
    Color? lineColor,
    bool isRailway = false,
    Animation<double>? pulseAnimation,
  }) {
    return LeafletMarkerPin(
      key: key,
      category: LeafletPinCategory.metro,
      width: width,
      height: height,
      isSelected: isSelected,
      accentColor: lineColor,
      isRailway: isRailway,
      pulseAnimation: pulseAnimation,
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseW = size ?? width;
    final baseH = size != null ? (size! * 1.28) : height;
    final effectiveWidth = isSelected ? (baseW * 1.22) : baseW;
    final effectiveHeight = isSelected ? (baseH * 1.22) : baseH;

    final pin = RepaintBoundary(
      child: CustomPaint(
        size: Size(effectiveWidth, effectiveHeight),
        painter: _LeafletPinPainter(
          category: category,
          isSelected: isSelected,
          isVisited: isVisited,
          trailIndex: trailIndex,
          isCurrentTrailStop: isCurrentTrailStop,
          clusterCount: clusterCount,
          accentColor: pinColor ?? accentColor,
          isRailway: isRailway,
          customIcon: customIcon,
        ),
      ),
    );

    if (isSelected && pulseAnimation != null) {
      return AnimatedBuilder(
        animation: pulseAnimation!,
        builder: (context, _) {
          final pulse = pulseAnimation!.value;
          final haloColor = category == LeafletPinCategory.restaurant
              ? const Color(0xFFFF9800)
              : (category == LeafletPinCategory.metro
                  ? (accentColor ?? const Color(0xFF1976D2))
                  : PujaColors.festivalGold);

          return Stack(
            alignment: Alignment.topCenter,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: (effectiveWidth / 2) - (effectiveWidth * 0.6) - (8 * pulse),
                child: Container(
                  width: (effectiveWidth * 1.2) + (16 * pulse),
                  height: (effectiveWidth * 1.2) + (16 * pulse),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: haloColor.withValues(alpha: 0.35 * (1.0 - pulse)),
                  ),
                ),
              ),
              pin,
            ],
          );
        },
      );
    }

    return pin;
  }
}

class _LeafletPinPainter extends CustomPainter {
  _LeafletPinPainter({
    required this.category,
    required this.isSelected,
    required this.isVisited,
    this.trailIndex,
    this.isCurrentTrailStop = false,
    this.clusterCount,
    this.accentColor,
    this.isRailway = false,
    this.customIcon,
  });

  final LeafletPinCategory category;
  final bool isSelected;
  final bool isVisited;
  final int? trailIndex;
  final bool isCurrentTrailStop;
  final int? clusterCount;
  final Color? accentColor;
  final bool isRailway;
  final IconData? customIcon;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    final r = w / 2.0;
    final center = Offset(r, r);
    final tip = Offset(r, h - 1.2);

    // 1. PIN TEARDROP BODY PATH (Authentic Leaflet geometry)
    final pinPath = Path();
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
      pinPath.lineTo(leftTouch.dx, leftTouch.dy);
      pinPath.arcTo(
        Rect.fromCircle(center: center, radius: r),
        leftTangentAngle,
        2 * math.pi - 2 * (math.pi / 2 - angle),
        false,
      );
      pinPath.lineTo(rightTouch.dx, rightTouch.dy);
      pinPath.close();
    } else {
      pinPath.addOval(Rect.fromCircle(center: center, radius: r));
    }

    // 2. GROUND DROP SHADOW (Leaflet marker shadow)
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: isSelected ? 0.42 : 0.30)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, isSelected ? 4.5 : 3.0);
    canvas.save();
    canvas.translate(0, isSelected ? 3.0 : 2.0);
    canvas.drawPath(pinPath, shadowPaint);
    canvas.restore();

    // 3. COLOR GRADIENT PER CATEGORY
    List<Color> gradientColors;
    switch (category) {
      case LeafletPinCategory.pandal:
        if (isCurrentTrailStop) {
          gradientColors = [const Color(0xFFFF1744), const Color(0xFFD50000)];
        } else if (isVisited) {
          gradientColors = [const Color(0xFF00C853), const Color(0xFF007E33)];
        } else if (isSelected) {
          gradientColors = [const Color(0xFFFF1744), const Color(0xFFB71C1C)];
        } else {
          gradientColors = [const Color(0xFFE53935), const Color(0xFF8A0014)];
        }
        break;

      case LeafletPinCategory.restaurant:
        gradientColors = isSelected
            ? [const Color(0xFFFFB300), const Color(0xFFE65100)]
            : [const Color(0xFFFFA000), const Color(0xFFD84315)];
        break;

      case LeafletPinCategory.metro:
        final base = accentColor ?? const Color(0xFF1976D2);
        gradientColors = [
          base.withValues(alpha: 0.95),
          HSLColor.fromColor(base).withLightness((HSLColor.fromColor(base).lightness * 0.7).clamp(0.0, 1.0)).toColor(),
        ];
        break;

      case LeafletPinCategory.cluster:
        gradientColors = [PujaColors.crimsonVelvet, const Color(0xFF4A0008)];
        break;

      case LeafletPinCategory.custom:
        final base = accentColor ?? const Color(0xFF455A64);
        gradientColors = [
          base,
          HSLColor.fromColor(base).withLightness((HSLColor.fromColor(base).lightness * 0.7).clamp(0.0, 1.0)).toColor(),
        ];
        break;
    }

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors,
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;
    canvas.drawPath(pinPath, fillPaint);

    // 4. OUTER METALLIC HIGHLIGHT STROKE
    final outerStrokePaint = Paint()
      ..color = isSelected
          ? Colors.white
          : (category == LeafletPinCategory.restaurant
              ? const Color(0xFFFFE082)
              : (category == LeafletPinCategory.metro
                  ? Colors.white.withValues(alpha: 0.85)
                  : const Color(0xFFFFD54F).withValues(alpha: 0.65)))
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 1.6 : 1.1;
    canvas.drawPath(pinPath, outerStrokePaint);

    // 5. CONCENTRIC METALLIC / GOLD BEZEL RING
    final bezelRadius = r * 0.78;
    final bezelPaint = Paint()
      ..shader = LinearGradient(
        colors: category == LeafletPinCategory.metro
            ? [Colors.white, const Color(0xFFE0E0E0), Colors.white]
            : [
                const Color(0xFFFFECB3),
                const Color(0xFFFFD54F),
                const Color(0xFFFFA000),
                const Color(0xFFFFECB3),
              ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromCircle(center: center, radius: bezelRadius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.08;
    canvas.drawCircle(center, bezelRadius, bezelPaint);

    // 6. INNER MEDALLION DISC
    final innerRadius = bezelRadius - (bezelPaint.strokeWidth / 2);
    Color innerColor;
    switch (category) {
      case LeafletPinCategory.pandal:
        innerColor = isVisited ? const Color(0xFF004D20) : const Color(0xFF5A000A);
        break;
      case LeafletPinCategory.restaurant:
        innerColor = const Color(0xFF5D2400);
        break;
      case LeafletPinCategory.metro:
        innerColor = isRailway ? const Color(0xFF3E1052) : const Color(0xFF083363);
        break;
      case LeafletPinCategory.cluster:
        innerColor = const Color(0xFF4A0008);
        break;
      case LeafletPinCategory.custom:
        innerColor = (accentColor ?? const Color(0xFF455A64)).withValues(alpha: 0.90);
        break;
    }
    final innerPaint = Paint()
      ..color = innerColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerPaint);

    // 7. CENTER EMBLEM CONTENT
    if (customIcon != null || category == LeafletPinCategory.custom) {
      _drawIcon(canvas, center, customIcon ?? Icons.place_rounded, innerRadius * 1.15, Colors.white);
    } else if (clusterCount != null && clusterCount! > 1) {
      _drawCenteredText(
        canvas,
        center,
        clusterCount! > 999
            ? '${(clusterCount! / 1000).toStringAsFixed(1)}k'
            : '$clusterCount',
        innerRadius * 1.05,
        const Color(0xFFFFECB3),
      );
    } else if (trailIndex != null && trailIndex! >= 0) {
      _drawCenteredText(
        canvas,
        center,
        '${trailIndex! + 1}',
        innerRadius * 1.15,
        const Color(0xFFFFECB3),
      );
    } else {
      switch (category) {
        case LeafletPinCategory.pandal:
          _drawDurgaTrinayana(canvas, center, innerRadius);
          break;
        case LeafletPinCategory.restaurant:
          _drawRestaurantCutlery(canvas, center, innerRadius);
          break;
        case LeafletPinCategory.metro:
          if (isRailway) {
            _drawTrainEmblem(canvas, center, innerRadius);
          } else {
            _drawCenteredText(canvas, center, 'M', innerRadius * 1.25, Colors.white, isBold: true);
          }
          break;
        case LeafletPinCategory.cluster:
        case LeafletPinCategory.custom:
          break;
      }
    }

    // 8. VISITED DARSHAN CHECK BADGE
    if (isVisited && category == LeafletPinCategory.pandal) {
      final badgeCenter = Offset(center.dx + bezelRadius * 0.72, center.dy - bezelRadius * 0.72);
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

  void _drawCenteredText(
    Canvas canvas,
    Offset center,
    String text,
    double fontSize,
    Color color, {
    bool isBold = false,
  }) {
    final span = TextSpan(
      text: text,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: isBold ? FontWeight.w900 : FontWeight.w800,
        letterSpacing: -0.3,
      ),
    );
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  void _drawDurgaTrinayana(Canvas canvas, Offset center, double radius) {
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

    // Third eye
    final triTop = center.dy - (11.0 * s);
    final triBottom = center.dy - (2.5 * s);
    final triMidY = (triTop + triBottom) / 2;
    final triPath = Path()
      ..moveTo(center.dx, triTop)
      ..quadraticBezierTo(center.dx + (4.0 * s), triMidY, center.dx, triBottom)
      ..quadraticBezierTo(center.dx - (4.0 * s), triMidY, center.dx, triTop)
      ..close();
    canvas.drawPath(triPath, goldStroke);
    canvas.drawCircle(Offset(center.dx, triMidY), 1.2 * s, goldFill);

    // Sacred Tilak
    canvas.drawCircle(Offset(center.dx, triBottom + (2.0 * s)), 1.3 * s, redBindi);

    // Eyes
    final eyeY = center.dy + (2.0 * s);
    final eyeSpan = 13.0 * s;
    final eyeInner = 2.8 * s;

    // Left eye
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
    canvas.drawCircle(Offset(center.dx - (7.5 * s), eyeY - (0.3 * s)), 1.5 * s, goldFill);

    // Right eye
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
    canvas.drawCircle(Offset(center.dx + (7.5 * s), eyeY - (0.3 * s)), 1.5 * s, goldFill);

    // Trishul stem
    final stemY = triBottom + (3.5 * s);
    final stemEnd = center.dy + (8.5 * s);
    final stemPath = Path()
      ..moveTo(center.dx, stemY)
      ..lineTo(center.dx, stemEnd);
    canvas.drawPath(stemPath, goldStroke);
  }

  void _drawRestaurantCutlery(Canvas canvas, Offset center, double radius) {
    final s = radius / 14.0;
    final whitePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * s
      ..strokeCap = StrokeCap.round;

    final fillWhite = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    // Fork (Left)
    final forkX = center.dx - (4.0 * s);
    final forkTop = center.dy - (8.0 * s);
    final forkBottom = center.dy + (8.0 * s);
    canvas.drawLine(Offset(forkX, center.dy - (1.0 * s)), Offset(forkX, forkBottom), whitePaint);
    canvas.drawLine(Offset(forkX - (2.5 * s), center.dy - (1.0 * s)), Offset(forkX + (2.5 * s), center.dy - (1.0 * s)), whitePaint);
    canvas.drawLine(Offset(forkX - (2.0 * s), forkTop), Offset(forkX - (2.0 * s), center.dy - (1.0 * s)), whitePaint);
    canvas.drawLine(Offset(forkX, forkTop), Offset(forkX, center.dy - (1.0 * s)), whitePaint);
    canvas.drawLine(Offset(forkX + (2.0 * s), forkTop), Offset(forkX + (2.0 * s), center.dy - (1.0 * s)), whitePaint);

    // Knife (Right)
    final knifeX = center.dx + (4.0 * s);
    final knifeTop = center.dy - (8.0 * s);
    final knifeBottom = center.dy + (8.0 * s);
    canvas.drawLine(Offset(knifeX, center.dy), Offset(knifeX, knifeBottom), whitePaint);
    final bladePath = Path()
      ..moveTo(knifeX, center.dy)
      ..lineTo(knifeX, knifeTop)
      ..quadraticBezierTo(knifeX + (3.0 * s), knifeTop + (4.0 * s), knifeX, center.dy)
      ..close();
    canvas.drawPath(bladePath, fillWhite);
  }

  void _drawTrainEmblem(Canvas canvas, Offset center, double radius) {
    final s = radius / 12.0;
    final trainPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3 * s
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    final rect = Rect.fromCenter(center: Offset(center.dx, center.dy - (1.0 * s)), width: 12 * s, height: 14 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, Radius.circular(2.5 * s)), trainPaint);

    final winRect = Rect.fromCenter(center: Offset(center.dx, center.dy - (3.5 * s)), width: 9 * s, height: 4.5 * s);
    canvas.drawRRect(RRect.fromRectAndRadius(winRect, Radius.circular(1.2 * s)), fillPaint);

    canvas.drawCircle(Offset(center.dx - (3.5 * s), center.dy + (2.5 * s)), 1.2 * s, fillPaint);
    canvas.drawCircle(Offset(center.dx + (3.5 * s), center.dy + (2.5 * s)), 1.2 * s, fillPaint);

    canvas.drawLine(Offset(center.dx - (5.0 * s), center.dy + (6.5 * s)), Offset(center.dx + (5.0 * s), center.dy + (6.5 * s)), trainPaint);
  }

  void _drawIcon(Canvas canvas, Offset center, IconData icon, double size, Color color) {
    final span = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: size,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: color,
      ),
    );
    final tp = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant _LeafletPinPainter oldDelegate) {
    return oldDelegate.category != category ||
        oldDelegate.isSelected != isSelected ||
        oldDelegate.isVisited != isVisited ||
        oldDelegate.trailIndex != trailIndex ||
        oldDelegate.isCurrentTrailStop != isCurrentTrailStop ||
        oldDelegate.clusterCount != clusterCount ||
        oldDelegate.accentColor != accentColor ||
        oldDelegate.isRailway != isRailway ||
        oldDelegate.customIcon != customIcon;
  }
}

/// Authentic Leaflet.js interactive popup speech-bubble card.
/// Anchored directly over the selected marker pin with a downward triangular tip.
class LeafletMapPopup extends StatelessWidget {
  const LeafletMapPopup({
    super.key,
    this.pandal,
    this.foodSpot,
    this.metroStation,
    this.distanceKm,
    this.isDark,
    this.onClose,
    this.onDirections,
    this.onDetails,
    this.onToggleHopped,
    this.isHopped = false,
  }) : assert(pandal != null || foodSpot != null || metroStation != null);

  /// Convenience constructor for Puja Pandals
  factory LeafletMapPopup.pandal({
    Key? key,
    required Pandal pandal,
    double? distanceKm,
    bool isDark = false,
    bool isHopped = false,
    VoidCallback? onClose,
    VoidCallback? onDirections,
    VoidCallback? onDetails,
    VoidCallback? onToggleHopped,
  }) {
    return LeafletMapPopup(
      key: key,
      pandal: pandal,
      distanceKm: distanceKm,
      isDark: isDark,
      isHopped: isHopped,
      onClose: onClose,
      onDirections: onDirections,
      onDetails: onDetails,
      onToggleHopped: onToggleHopped,
    );
  }

  /// Convenience constructor for Restaurants / Food Spots
  factory LeafletMapPopup.restaurant({
    Key? key,
    required FoodSpot spot,
    double? distanceKm,
    bool isDark = false,
    VoidCallback? onClose,
    VoidCallback? onDirections,
    VoidCallback? onDetails,
  }) {
    return LeafletMapPopup(
      key: key,
      foodSpot: spot,
      distanceKm: distanceKm,
      isDark: isDark,
      onClose: onClose,
      onDirections: onDirections,
      onDetails: onDetails,
    );
  }

  /// Convenience constructor for Metro & Railway Stations
  factory LeafletMapPopup.metro({
    Key? key,
    required MetroStation station,
    double? distanceKm,
    bool isDark = false,
    VoidCallback? onClose,
    VoidCallback? onDirections,
    VoidCallback? onDetails,
  }) {
    return LeafletMapPopup(
      key: key,
      metroStation: station,
      distanceKm: distanceKm,
      isDark: isDark,
      onClose: onClose,
      onDirections: onDirections,
      onDetails: onDetails,
    );
  }

  final Pandal? pandal;
  final FoodSpot? foodSpot;
  final MetroStation? metroStation;
  final double? distanceKm;
  final bool? isDark;
  final VoidCallback? onClose;
  final VoidCallback? onDirections;
  final VoidCallback? onDetails;
  final VoidCallback? onToggleHopped;
  final bool isHopped;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveDark = isDark ?? (theme.brightness == Brightness.dark);

    return RepaintBoundary(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. Popup Speech-Bubble Container (Leaflet style)
          Container(
            width: 275,
            decoration: BoxDecoration(
              color: effectiveDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: effectiveDark
                    ? PujaColors.festivalGold.withValues(alpha: 0.28)
                    : Colors.black.withValues(alpha: 0.12),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: effectiveDark ? 0.55 : 0.20),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Header Row: Category Badge + Close '×' Button
                  Row(
                    children: [
                      _buildCategoryBadge(effectiveDark),
                      const Spacer(),
                      InkWell(
                        onTap: onClose,
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(3.0),
                          child: Icon(
                            Icons.close_rounded,
                            size: 18,
                            color: effectiveDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title & Details
                  if (pandal != null) _buildPandalContent(effectiveDark),
                  if (foodSpot != null) _buildFoodSpotContent(effectiveDark),
                  if (metroStation != null) _buildMetroContent(effectiveDark),

                  const SizedBox(height: 10),

                  // Action Buttons (Directions + Details)
                  _buildActionButtons(effectiveDark),
                ],
              ),
            ),
          ),

          // 2. Downward Triangular Pointer Tip (Leaflet popup-tip)
          CustomPaint(
            size: const Size(22, 11),
            painter: _LeafletPopupTipPainter(
              color: effectiveDark ? const Color(0xFF1E1E1E) : Colors.white,
              borderColor: effectiveDark
                  ? PujaColors.festivalGold.withValues(alpha: 0.28)
                  : Colors.black.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBadge(bool isDark) {
    if (pandal != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: PujaColors.durgaRed.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: PujaColors.durgaRed.withValues(alpha: 0.35),
                width: 0.8,
              ),
            ),
            child: Text(
              pandal!.zoneLabel.toUpperCase(),
              style: const TextStyle(
                color: PujaColors.durgaRed,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(width: 6),
          CrowdBadge(crowdLevel: pandal!.crowdLevel),
        ],
      );
    }

    if (foodSpot != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFFE65100).withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: const Color(0xFFE65100).withValues(alpha: 0.35),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🍽️ ', style: TextStyle(fontSize: 10)),
            Text(
              foodSpot!.type.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFE65100),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      );
    }

    // Metro Station
    final isRailway = metroStation!.name.toLowerCase().contains('railway');
    final lineColor = isRailway ? PujaColors.railwayPurple : metroStation!.line.color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: lineColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: lineColor.withValues(alpha: 0.45),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRailway ? Icons.train_rounded : Icons.subway_rounded,
            size: 11,
            color: lineColor,
          ),
          const SizedBox(width: 4),
          Text(
            metroStation!.line.label.toUpperCase(),
            style: TextStyle(
              color: lineColor,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPandalContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          pandal!.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        if (pandal!.theme.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            pandal!.theme,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            if (pandal!.rating != null && pandal!.rating! > 0) ...[
              const Icon(Icons.star_rounded, size: 14, color: PujaColors.festivalGold),
              const SizedBox(width: 2),
              Text(
                pandal!.rating!.toStringAsFixed(1),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (distanceKm != null) ...[
              const Icon(Icons.navigation_rounded, size: 12, color: Color(0xFF2979FF)),
              const SizedBox(width: 2),
              Text(
                '${distanceKm!.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: Color(0xFF2979FF),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              pandal!.timings.isNotEmpty ? pandal!.timings : 'Free entry',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black45,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFoodSpotContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          foodSpot!.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        if (foodSpot!.mustTry != null && foodSpot!.mustTry!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            'Specialty: ${foodSpot!.mustTry}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: isDark ? Colors.amber[200] : const Color(0xFFD84315),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        const SizedBox(height: 6),
        Row(
          children: [
            if (foodSpot!.rating != null) ...[
              const Icon(Icons.star_rounded, size: 14, color: PujaColors.festivalGold),
              const SizedBox(width: 2),
              Text(
                foodSpot!.rating!.toStringAsFixed(1),
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (distanceKm != null) ...[
              const Icon(Icons.navigation_rounded, size: 12, color: Color(0xFF2979FF)),
              const SizedBox(width: 2),
              Text(
                '${distanceKm!.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: Color(0xFF2979FF),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (foodSpot!.nearbyPandal.isNotEmpty)
              Expanded(
                child: Text(
                  'Near ${foodSpot!.nearbyPandal}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isDark ? Colors.white60 : Colors.black45,
                    fontSize: 11,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetroContent(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          metroStation!.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          metroStation!.line.corridor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            if (distanceKm != null) ...[
              const Icon(Icons.navigation_rounded, size: 12, color: Color(0xFF2979FF)),
              const SizedBox(width: 2),
              Text(
                '${distanceKm!.toStringAsFixed(1)} km',
                style: const TextStyle(
                  color: Color(0xFF2979FF),
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
            ],
            Text(
              '${metroStation!.popularPandalsNearby.length} pandals nearby',
              style: TextStyle(
                color: isDark ? Colors.white60 : Colors.black54,
                fontSize: 11.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(bool isDark) {
    return Row(
      children: [
        // Primary Directions Button
        Expanded(
          child: SizedBox(
            height: 32,
            child: ElevatedButton.icon(
              onPressed: onDirections,
              icon: const Icon(Icons.directions_walk_rounded, size: 15),
              label: const Text(
                'Directions',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PujaColors.durgaRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),

        // Secondary Info / Details Button
        if (onDetails != null)
          SizedBox(
            height: 32,
            child: OutlinedButton(
              onPressed: onDetails,
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? Colors.white : Colors.black87,
                side: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.2),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Details',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),

        // Hopped toggle icon button for Pandals
        if (pandal != null && onToggleHopped != null) ...[
          const SizedBox(width: 6),
          SizedBox(
            width: 32,
            height: 32,
            child: IconButton(
              icon: Icon(
                isHopped ? Icons.check_circle_rounded : Icons.check_circle_outline_rounded,
                size: 20,
                color: isHopped ? const Color(0xFF00E676) : (isDark ? Colors.white60 : Colors.black45),
              ),
              tooltip: isHopped ? 'Hopped' : 'Mark as Hopped',
              onPressed: onToggleHopped,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ],
    );
  }
}

class _LeafletPopupTipPainter extends CustomPainter {
  _LeafletPopupTipPainter({required this.color, required this.borderColor});
  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(w / 2, h)
      ..lineTo(w, 0)
      ..close();

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    final strokePaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    final strokePath = Path()
      ..moveTo(0, 0)
      ..lineTo(w / 2, h)
      ..lineTo(w, 0);
    canvas.drawPath(strokePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _LeafletPopupTipPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.borderColor != borderColor;
  }
}

/// Discreet Leaflet attribution badge in the corner of the map.
/// Displays "Leaflet | © OpenStreetMap contributors".
class LeafletAttributionControl extends StatelessWidget {
  const LeafletAttributionControl({super.key, this.isDark});

  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final effectiveDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(
        color: (effectiveDark ? Colors.black87 : Colors.white.withValues(alpha: 0.85)),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: effectiveDark ? Colors.white12 : Colors.black12,
          width: 0.6,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.eco_rounded,
            size: 11,
            color: Color(0xFF4CAF50),
          ),
          const SizedBox(width: 3),
          Text(
            'Leaflet',
            style: TextStyle(
              color: effectiveDark ? Colors.white70 : const Color(0xFF0078A8),
              fontSize: 9.5,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            ' | © OpenStreetMap',
            style: TextStyle(
              color: effectiveDark ? Colors.white54 : Colors.black54,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

/// Iconic Leaflet stacked Zoom Control (+ / −) buttons.
class LeafletZoomControl extends StatelessWidget {
  const LeafletZoomControl({
    super.key,
    required this.onZoomIn,
    required this.onZoomOut,
    this.isDark,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final bool? isDark;

  @override
  Widget build(BuildContext context) {
    final effectiveDark = isDark ?? (Theme.of(context).brightness == Brightness.dark);
    final bgColor = effectiveDark ? const Color(0xFF242424) : Colors.white;
    final fgColor = effectiveDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: effectiveDark ? Colors.white12 : Colors.black12,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: effectiveDark ? 0.4 : 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onZoomIn,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: Icon(Icons.add, size: 18, color: fgColor),
              ),
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: effectiveDark ? Colors.white12 : Colors.black12,
          ),
          InkWell(
            onTap: onZoomOut,
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(6)),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Center(
                child: Icon(Icons.remove, size: 18, color: fgColor),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
