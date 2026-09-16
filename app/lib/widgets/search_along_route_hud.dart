import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../config/pandal_theme_tokens.dart';
import '../models/food_spot.dart';
import '../utils/spatial_corridor.dart';

/// A Material 3 / Mobbin-styled horizontal corridor strip docking over the map
/// during active walking navigation.
///
/// Discovers and highlights curated food spots within a 300-meter buffer along
/// the active walking polyline, calculating round-trip detour duration.
class SearchAlongRouteHUD extends StatelessWidget {
  final List<LatLng> activePolyline;
  final List<FoodSpot> allFoodSpots;
  final Function(FoodSpot) onSelectFoodSpot;
  final VoidCallback onClearRoute;

  const SearchAlongRouteHUD({
    super.key,
    required this.activePolyline,
    required this.allFoodSpots,
    required this.onSelectFoodSpot,
    required this.onClearRoute,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = Theme.of(context).extension<PandalOfflineThemeTokens>() ??
        const PandalOfflineThemeTokens();

    final matches = SpatialCorridor.findAlongPolyline<FoodSpot>(
      polyline: activePolyline,
      items: allFoodSpots,
      getCoordinates: (spot) => LatLng(spot.latitude, spot.longitude),
      maxCorridorMeters: 300.0,
    );

    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: tokens.surfaceCard.withValues(alpha: 0.92),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: tokens.borderSubtle),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.alt_route_rounded, size: 14, color: tokens.festivalGold),
                    const SizedBox(width: 6),
                    Text(
                      'ALONG TRAIL CORRIDOR (${matches.length} SPOTS)',
                      style: TextStyle(
                        color: tokens.festivalGold,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: onClearRoute,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: tokens.surfaceElevated,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.close_rounded, size: 12, color: Colors.white70),
                            SizedBox(width: 2),
                            Text('Exit', style: TextStyle(color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (matches.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      itemCount: matches.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final match = matches[index];
                        return GestureDetector(
                          onTap: () => onSelectFoodSpot(match.item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: tokens.surfaceElevated,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: tokens.borderSubtle),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.restaurant_rounded, size: 12, color: Colors.amberAccent),
                                const SizedBox(width: 6),
                                Text(
                                  match.item.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+${match.estimatedDetourMinutes}m detour',
                                  style: TextStyle(
                                    color: tokens.offlineFg,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Compatibility alias for [SearchAlongRouteHUD].
typedef SearchAlongRouteHud = SearchAlongRouteHUD;
