import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:geolocator/geolocator.dart';
import '../models/squad_member.dart';
import '../services/location_service.dart';
import '../utils/haversine.dart';

/// AR-style compass overlay showing direction to squad members
/// Displays as a floating widget on map screen
class SquadCompassOverlay extends StatefulWidget {
  const SquadCompassOverlay({
    super.key,
    required this.squadMembers,
    required this.onMemberTap,
    this.compact = false,
  });

  final List<SquadMember> squadMembers;
  final void Function(SquadMember) onMemberTap;
  final bool compact;

  @override
  State<SquadCompassOverlay> createState() => _SquadCompassOverlayState();
}

class _SquadCompassOverlayState extends State<SquadCompassOverlay>
    with TickerProviderStateMixin {
  StreamSubscription<CompassEvent>? _compassSub;
  double _deviceHeading = 0; // 0 = North, degrees clockwise
  double? _userHeading; // GPS heading when moving
  Timer? _updateTimer;
  
  late final AnimationController _pulseController;
  late final AnimationController _rotateController;
  
  // Member to highlight (closest or selected)
  SquadMember? _highlightedMember;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _rotateController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _startCompass();
    _startPeriodicUpdate();
  }

  void _startCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (event.heading != null && !event.heading!.isNaN) {
        setState(() {
          _deviceHeading = event.heading!;
        });
      }
    });
  }

  void _startPeriodicUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateHighlightedMember();
      _updateUserHeading();
    });
  }

  void _updateUserHeading() {
    final pos = LocationService.instance.currentPositionSync;
    if (pos != null && pos.speed > 1.0) { // Moving > 3.6 km/h
      setState(() {
        _userHeading = pos.heading;
      });
    }
  }

  void _updateHighlightedMember() {
    final userPos = LocationService.instance.currentPositionSync;
    if (userPos == null) return;

    SquadMember? closest;
    double minDist = double.infinity;

    for (final member in widget.squadMembers) {
      if (!member.shareLocation || !member.isOnline) continue;
      if (member.latitude == 0 && member.longitude == 0) continue;
      
      final dist = haversineMeters(
        userPos.latitude, userPos.longitude,
        member.latitude, member.longitude,
      );
      if (dist < minDist) {
        minDist = dist;
        closest = member;
      }
    }

    if (closest != _highlightedMember) {
      setState(() {
        _highlightedMember = closest;
      });
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _updateTimer?.cancel();
    _pulseController.dispose();
    _rotateController.dispose();
    super.dispose();
  }

  /// Get effective heading (GPS when moving fast, else compass)
  double get _effectiveHeading {
    if (_userHeading != null) return _userHeading!;
    return _deviceHeading;
  }

  @override
  Widget build(BuildContext context) {
    final visibleMembers = widget.squadMembers
        .where((m) => m.shareLocation && m.isOnline && m.latitude != 0 && m.longitude != 0)
        .toList();

    if (visibleMembers.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: false,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseController, _rotateController]),
        builder: (context, _) {
          return CustomPaint(
            size: Size.infinite,
            painter: _CompassPainter(
              deviceHeading: _effectiveHeading,
              members: visibleMembers,
              highlightedMember: _highlightedMember,
              pulseValue: _pulseController.value,
              compact: widget.compact,
              onMemberTap: widget.onMemberTap,
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for the AR compass
class _CompassPainter extends CustomPainter {
  _CompassPainter({
    required this.deviceHeading,
    required this.members,
    required this.highlightedMember,
    required this.pulseValue,
    required this.compact,
    required this.onMemberTap,
  });

  final double deviceHeading;
  final List<SquadMember> members;
  final SquadMember? highlightedMember;
  final double pulseValue;
  final bool compact;
  final void Function(SquadMember) onMemberTap;

  static const double _radius = 120;
  static const double _compactRadius = 80;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = compact ? _compactRadius : _radius;

    // Draw compass rose (background)
    _drawCompassRose(canvas, center, radius);

    // Draw member direction indicators
    for (final member in members) {
      _drawMemberIndicator(canvas, center, radius, member);
    }

    // Draw center "you" marker
    _drawCenterMarker(canvas, center);
  }

  void _drawCompassRose(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Cardinal directions
    for (int i = 0; i < 4; i++) {
      final angle = (i * 90 - deviceHeading) * math.pi / 180;
      final outer = radius + 10;
      final inner = radius - 5;
      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        paint,
      );
    }

    // N/E/S/W labels
    if (!compact) {
      final textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      
      for (int i = 0; i < 4; i++) {
        final dir = ['N', 'E', 'S', 'W'][i];
        final angle = (i * 90 - deviceHeading) * math.pi / 180;
        final pos = center + Offset(math.cos(angle) * (radius + 22), math.sin(angle) * (radius + 22));
        
        textPainter.text = TextSpan(
          text: dir,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 4, color: Colors.black)],
          ),
        );
        textPainter.layout();
        textPainter.paint(canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
      }
    }
  }

  void _drawMemberIndicator(Canvas canvas, Offset center, double radius, SquadMember member) {
    final userPos = LocationService.instance.currentPositionSync;
    if (userPos == null) return;

    final bearing = Geolocator.bearingBetween(
      userPos.latitude, userPos.longitude,
      member.latitude, member.longitude,
    );
    
    final dist = haversineMeters(
      userPos.latitude, userPos.longitude,
      member.latitude, member.longitude,
    );

    // Angle relative to device heading (0 = straight ahead)
    final relativeAngle = (bearing - deviceHeading) * math.pi / 180;
    
    final isHighlighted = highlightedMember?.id == member.id;
    final pulse = isHighlighted ? (1 + 0.3 * math.sin(pulseValue * 2 * math.pi)) : 1.0;

    // Distance-based radius (closer = inner ring, farther = outer ring)
    double indicatorRadius;
    if (dist < 100) indicatorRadius = radius * 0.3;
    else if (dist < 300) indicatorRadius = radius * 0.5;
    else if (dist < 800) indicatorRadius = radius * 0.7;
    else indicatorRadius = radius * 0.95;

    indicatorRadius *= pulse;

    final indicatorCenter = center + Offset(
      math.cos(relativeAngle) * indicatorRadius,
      math.sin(relativeAngle) * indicatorRadius,
    );

    // Draw line from center to indicator
    final linePaint = Paint()
      ..color = _getMemberColor(member).withValues(alpha: 0.4)
      ..strokeWidth = isHighlighted ? 3 : 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(center, indicatorCenter, linePaint);

    // Draw member avatar circle
    final avatarRadius = compact ? 18.0 : 24.0;
    final avatarPaint = Paint()..color = _getMemberColor(member);
    canvas.drawCircle(indicatorCenter, avatarRadius * pulse, avatarPaint);

    // White border
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(indicatorCenter, avatarRadius * pulse, borderPaint);

    // Initials
    final initials = _getInitials(member.name);
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.text = TextSpan(
      text: initials,
      style: TextStyle(
        color: Colors.white,
        fontSize: compact ? 10 : 13,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();
    textPainter.paint(canvas, indicatorCenter - Offset(textPainter.width / 2, textPainter.height / 2));

    // Distance label (outside ring)
    if (!compact) {
      final distLabel = _formatDistance(dist);
      final labelPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      labelPainter.text = TextSpan(
        text: distLabel,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 10,
          fontWeight: FontWeight.w500,
          shadows: [Shadow(blurRadius: 3, color: Colors.black)],
        ),
      );
      labelPainter.layout();
      
      final labelPos = indicatorCenter + Offset(
        math.cos(relativeAngle) * 18,
        math.sin(relativeAngle) * 18,
      );
      labelPainter.paint(canvas, labelPos - Offset(labelPainter.width / 2, labelPainter.height / 2));
    }

    // Battery indicator (tiny)
    if (!compact) {
      _drawBatteryIndicator(canvas, indicatorCenter, avatarRadius + 8, member.batteryLevel);
    }
  }

  void _drawCenterMarker(Canvas canvas, Offset center) {
    // Pulsing center dot
    final pulseRadius = 8 + 4 * math.sin(pulseValue * 2 * math.pi);
    final paint = Paint()
      ..color = const Color(0xFFFFD700) // Festival Gold
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, pulseRadius, paint);

    // White center
    final whitePaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, 3, whitePaint);
  }

  void _drawBatteryIndicator(Canvas canvas, Offset center, double radius, int batteryLevel) {
    final paint = Paint()
      ..color = batteryLevel > 20 ? Colors.green : Colors.red
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, paint);
  }

  Color _getMemberColor(SquadMember member) {
    // Generate consistent color from member ID
    final hash = member.id.hashCode;
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.7, 0.9).toColor();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, math.min(2, name.length)).toUpperCase();
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }

  @override
  bool shouldRepaint(covariant _CompassPainter oldDelegate) {
    return oldDelegate.deviceHeading != deviceHeading ||
        oldDelegate.members != members ||
        oldDelegate.highlightedMember != highlightedMember ||
        oldDelegate.pulseValue != pulseValue;
  }

  @override
  bool hitTest(Offset position) {
    // Allow tap through to map for non-indicator areas
    return false;
  }
}

/// Compact compass button for Squad Hub card
class SquadCompassButton extends StatefulWidget {
  const SquadCompassButton({
    super.key,
    required this.squadMembers,
    required this.onPressed,
    this.showDistance = true,
  });

  final List<SquadMember> squadMembers;
  final VoidCallback onPressed;
  final bool showDistance;

  @override
  State<SquadCompassButton> createState() => _SquadCompassButtonState();
}

class _SquadCompassButtonState extends State<SquadCompassButton>
    with SingleTickerProviderStateMixin {
  StreamSubscription<CompassEvent>? _compassSub;
  double _deviceHeading = 0;
  late final AnimationController _pulseController;
  SquadMember? _closestMember;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _compassSub = FlutterCompass.events?.listen((event) {
      if (event.heading != null && !event.heading!.isNaN) {
        setState(() => _deviceHeading = event.heading!);
      }
    });
    _updateClosest();
  }

  void _updateClosest() {
    final userPos = LocationService.instance.currentPositionSync;
    if (userPos == null) return;

    SquadMember? closest;
    double minDist = double.infinity;

    for (final m in widget.squadMembers) {
      if (!m.shareLocation || !m.isOnline) continue;
      final dist = haversineMeters(
        userPos.latitude, userPos.longitude,
        m.latitude, m.longitude,
      );
      if (dist < minDist) {
        minDist = dist;
        closest = m;
      }
    }
    if (closest != _closestMember) {
      setState(() => _closestMember = closest);
    }
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_closestMember == null) {
      return IconButton(
        icon: const Icon(Icons.explore_outlined, color: Colors.white70),
        onPressed: widget.onPressed,
        tooltip: 'No squad members sharing location',
      );
    }

    final userPos = LocationService.instance.currentPositionSync!;
    final bearing = Geolocator.bearingBetween(
      userPos.latitude, userPos.longitude,
      _closestMember!.latitude, _closestMember!.longitude,
    );
    final dist = haversineMeters(
      userPos.latitude, userPos.longitude,
      _closestMember!.latitude, _closestMember!.longitude,
    );
    final relativeAngle = bearing - _deviceHeading;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Compass ring
            Transform.rotate(
              angle: -_deviceHeading * math.pi / 180,
              child: CustomPaint(
                size: const Size(56, 56),
                painter: _CompassButtonPainter(
                  relativeAngle: relativeAngle,
                  pulseValue: _pulseController.value,
                  memberColor: _getMemberColor(_closestMember!),
                ),
              ),
            ),
            // Center avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: _getMemberColor(_closestMember!),
              child: Text(
                _getInitials(_closestMember!.name),
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ),
            // Distance badge
            if (widget.showDistance)
              Positioned(
                bottom: -4,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _formatDistance(dist),
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Color _getMemberColor(SquadMember member) {
    final hash = member.id.hashCode;
    final hue = (hash % 360).toDouble();
    return HSVColor.fromAHSV(1, hue, 0.7, 0.9).toColor();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return name.substring(0, math.min(2, name.length)).toUpperCase();
  }

  String _formatDistance(double meters) {
    if (meters < 1000) return '${meters.round()}m';
    return '${(meters / 1000).toStringAsFixed(1)}km';
  }
}

class _CompassButtonPainter extends CustomPainter {
  _CompassButtonPainter({
    required this.relativeAngle,
    required this.pulseValue,
    required this.memberColor,
  });

  final double relativeAngle;
  final double pulseValue;
  final Color memberColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    const radius = 28.0;

    // Outer ring
    final ringPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius, ringPaint);

    // Direction indicator
    final angle = relativeAngle * math.pi / 180;
    final indicatorPaint = Paint()
      ..color = memberColor
      ..style = PaintingStyle.fill;
    
    final tip = center + Offset(math.cos(angle) * radius, math.sin(angle) * radius);
    final base1 = center + Offset(math.cos(angle + 2.5) * 10, math.sin(angle + 2.5) * 10);
    final base2 = center + Offset(math.cos(angle - 2.5) * 10, math.sin(angle - 2.5) * 10);
    
    final path = ui.Path()..moveTo(tip.dx, tip.dy)..lineTo(base1.dx, base1.dy)..lineTo(base2.dx, base2.dy)..close();
    canvas.drawPath(path, indicatorPaint);

    // Pulse ring when aligned (within 15 degrees)
    if (relativeAngle.abs() < 15 || (relativeAngle.abs() > 345)) {
      final pulsePaint = Paint()
        ..color = memberColor.withValues(alpha: 0.3 * pulseValue)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(center, radius + 4 * pulseValue, pulsePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassButtonPainter oldDelegate) {
    return oldDelegate.relativeAngle != relativeAngle ||
        oldDelegate.pulseValue != pulseValue ||
        oldDelegate.memberColor != memberColor;
  }
}