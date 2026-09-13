import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../services/location_service.dart';
import '../services/pandal_user_state_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import 'crowd_badge.dart';

class PandalCard extends StatelessWidget {
  const PandalCard({
    super.key,
    required this.pandal,
    required this.onTap,
    this.distanceKm,
  });

  final Pandal pandal;
  final VoidCallback onTap;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final isFav = context.select<PandalUserStateService?, bool>(
      (s) => s?.isFavorite(pandal.id) ?? false,
    );
    final isVis = context.select<PandalUserStateService?, bool>(
      (s) => s?.isVisited(pandal.id) ?? false,
    );

    // Real distance formatted string - only updates if distance label actually changes
    final distanceLabel = distanceKm != null
        ? '${distanceKm!.toStringAsFixed(1)} km'
        : context.select<LocationService?, String?>(
            (loc) => loc?.formatDistance(pandal.latitude, pandal.longitude),
          );

    return RepaintBoundary(
      child: Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: isDark ? 1 : 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isVis
              ? Colors.green.withValues(alpha: 0.6)
              : (isDark
                  ? PujaColors.festivalGold.withValues(alpha: 0.3)
                  : PujaColors.festivalGold.withValues(alpha: 0.25)),
          width: isVis ? 1.5 : 1.2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Action Row: Zone + Visited indicator + Crowd badge + Favorite heart
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: PujaColors.crimsonVelvet.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: PujaColors.festivalGold.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      pandal.zone.label,
                      style: TextStyle(
                        color: isDark ? PujaColors.goldBright : PujaColors.durgaRed,
                        fontSize: context.dynamicFont(11.5),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isVis) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, size: context.dynamicIcon(13), color: Colors.green),
                          const SizedBox(width: 4),
                          Text(
                            'Hopped',
                            style: TextStyle(
                              color: Colors.green,
                              fontSize: context.dynamicFont(10.5),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const Spacer(),
                  CrowdBadge(crowdLevel: pandal.crowdLevel),
                  const SizedBox(width: 6),
                  InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.read<PandalUserStateService?>()?.toggleFavorite(pandal.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        isFav ? Icons.favorite : Icons.favorite_border,
                        color: isFav ? Colors.red : Colors.grey.shade400,
                        size: context.dynamicIcon(22),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // Pandal Name
              Text(
                pandal.name,
                style: TextStyle(
                  fontSize: context.dynamicFont(16.0),
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 4),

              // Theme / Category
              Text(
                pandal.theme,
                style: TextStyle(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontSize: context.dynamicFont(12.5),
                  fontWeight: FontWeight.w400,
                  height: 1.25,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Metro, Real Distance & Rating footer wrapped in FittedBox for zero clipping
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  children: [
                    if (pandal.nearestMetro != null && pandal.nearestMetro!.isNotEmpty) ...[
                      Icon(Icons.directions_subway, size: context.dynamicIcon(15), color: PujaColors.metroBlue),
                      const SizedBox(width: 4),
                      Text(
                        pandal.nearestMetro!,
                        style: TextStyle(
                          fontSize: context.dynamicFont(11.5),
                          fontWeight: FontWeight.w600,
                          color: PujaColors.metroBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else ...[
                      Icon(Icons.schedule, size: context.dynamicIcon(15), color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        pandal.timings,
                        style: TextStyle(fontSize: context.dynamicFont(11.5), color: Colors.grey),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    if (distanceLabel != null) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isDark ? PujaColors.nightSurface : PujaColors.goldSoft,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: PujaColors.festivalGold.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.near_me_outlined, size: context.dynamicIcon(11), color: PujaColors.durgaRed),
                            const SizedBox(width: 3),
                            Text(
                              distanceLabel,
                              style: TextStyle(
                                fontSize: context.dynamicFont(10.5),
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white70 : PujaColors.crimsonVelvet,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (pandal.rating != null && pandal.rating! > 0) ...[
                      const SizedBox(width: 10),
                      Row(
                        children: [
                          Icon(Icons.star, size: context.dynamicIcon(14), color: PujaColors.festivalGold),
                          const SizedBox(width: 2),
                          Text(
                            pandal.rating!.toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: context.dynamicFont(11.5),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}
