import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../config/theme.dart';
import '../models/route_polyline_segment.dart';
import '../services/routing_service.dart';

List<Polyline> buildHighlightedRoutePolylines(
  WalkingRoute route,
  bool isDark, {
  bool navigation = false,
}) {
  if (route.points.isEmpty) return const [];
  if (navigation && route.isWalk && !route.isFallback) {
    return [
      Polyline(
        points: route.points,
        strokeWidth: 9,
        color: const Color(0x990B1B3D),
      ),
      Polyline(
        points: route.points,
        strokeWidth: 6,
        color: const Color(0xFF2F6FE4),
      ),
    ];
  }

  // If multi-segment transit route (pedestrian walk + metro tracks + train tracks)
  if (route.segments.isNotEmpty) {
    final polylines = <Polyline>[];
    for (final seg in route.segments) {
      if (seg.points.length < 2) continue;

      if (seg.type == RouteSegmentType.metro) {
        final color = seg.color;
        // Glowing underlay
        polylines.add(
          Polyline(
            points: seg.points,
            strokeWidth: 9.0,
            color: color.withValues(alpha: 0.35),
            pattern: seg.isFallback ? StrokePattern.dashed(segments: const [6,4]) : const StrokePattern.solid(),
          ),
        );
        // Solid Metro Line following real tracks
        polylines.add(
          Polyline(points: seg.points, strokeWidth: 5.5, color: color,
            pattern: seg.isFallback ? StrokePattern.dashed(segments: const [6,4]) : const StrokePattern.solid()),
        );
      } else if (seg.type == RouteSegmentType.train) {
        final color = seg.color;
        // Glowing underlay
        polylines.add(
          Polyline(
            points: seg.points,
            strokeWidth: 9.0,
            color: color.withValues(alpha: 0.35),
            pattern: seg.isFallback ? StrokePattern.dashed(segments: const [6,4]) : const StrokePattern.solid(),
          ),
        );
        // Solid Suburban Railway line following track curves
        polylines.add(
          Polyline(points: seg.points, strokeWidth: 5.5, color: color,
            pattern: seg.isFallback ? StrokePattern.dashed(segments: const [6,4]) : const StrokePattern.solid()),
        );
      } else {
        // Walk / Pedestrian connector
        final walkColor = isDark
            ? const Color(0xFF00E5FF)
            : PujaColors.durgaRed;
        polylines.add(
          Polyline(
            points: seg.points,
            strokeWidth: 7.0,
            color: walkColor.withValues(alpha: 0.28),
          ),
        );
        polylines.add(
          Polyline(
            points: seg.points,
            strokeWidth: 4.2,
            color: walkColor,
            pattern: StrokePattern.dashed(segments: const [7, 4]),
          ),
        );
      }
    }
    return polylines;
  }

  // Default single road / walk polyline
  final defaultColor = isDark ? const Color(0xFF00E5FF) : PujaColors.durgaRed;
  return [
    Polyline(
      points: route.points,
      strokeWidth: 7.5,
      color: defaultColor.withValues(alpha: 0.35),
    ),
    Polyline(points: route.points, strokeWidth: 4.2, color: defaultColor),
  ];
}
