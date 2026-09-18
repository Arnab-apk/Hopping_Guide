import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../models/place.dart';
import '../services/location_service.dart';
import '../services/pandal_user_state_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import 'puja_icons.dart';

/// Unified Place Card supporting both Pandals and Food Spots.
/// Uses Material 3 tonal elevation, soft outlineVariant borders, Google typography,
/// and responsive touch feedback.
class PlaceCard extends StatelessWidget {
  const PlaceCard({
    super.key,
    required this.place,
    required this.onTap,
    this.onMapTap,
    this.distanceKm,
  });

  final Place place;
  final VoidCallback onTap;
  final VoidCallback? onMapTap;
  final double? distanceKm;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isFav = context.select<PandalUserStateService?, bool>(
      (s) => s?.isFavorite(place.id) ?? false,
    );
    final isVis = place.isPandal &&
        context.select<PandalUserStateService?, bool>(
          (s) => s?.isVisited(place.id) ?? false,
        );

    // Real distance formatted string
    final distanceLabel = distanceKm != null
        ? '${distanceKm!.toStringAsFixed(1)} km'
        : context.select<LocationService?, String?>(
            (loc) => loc?.formatDistance(place.latitude, place.longitude),
          );

    return RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 0,
        color: colorScheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isVis
                ? colorScheme.primary.withValues(alpha: 0.65)
                : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.65),
            width: isVis ? 1.5 : 1.0,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Top Action Row: Category/Zone pill + Visited indicator + Favorite button
                Row(
                  children: [
                    if (place.isPandal) ...[
                      if (place.zone != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            place.zone!.label,
                            style: GoogleFonts.plusJakartaSans(
                              color: colorScheme.onSecondaryContainer,
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
                            color: Colors.green.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              PujaIcon.shankha(size: context.dynamicIcon(18), color: Colors.green),
                              const SizedBox(width: 4),
                              Text(
                                'Hopped',
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.green,
                                  fontSize: context.dynamicFont(10.5),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ] else ...[
                      // Food spot icon & type
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.restaurant_rounded,
                          color: colorScheme.onSecondaryContainer,
                          size: context.dynamicIcon(18),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          place.type ?? 'Culinary Stop',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100),
                          ),
                        ),
                      ),
                      if (place.priceRange != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          place.priceRange!,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ],
                    const Spacer(),
                    IconButton(
                      iconSize: context.dynamicIcon(26),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        context.read<PandalUserStateService?>()?.toggleFavorite(place.id);
                      },
                      icon: isFav
                          ? PujaIcon.kalash(
                              size: context.dynamicIcon(26),
                              color: PujaColors.festivalGold,
                            )
                          : Icon(
                              Icons.bookmark_border_rounded,
                              color: colorScheme.onSurfaceVariant,
                              size: context.dynamicIcon(26),
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // 2. Place Name
                Text(
                  place.name,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: context.dynamicFont(17.5),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    color: colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: 4),

                // 3. Category Specific Line (Theme for Pandal, Must-Try for Food)
                if (place.isPandal && place.theme != null && place.theme!.isNotEmpty)
                  Text(
                    place.theme!,
                    style: GoogleFonts.plusJakartaSans(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: context.dynamicFont(13.5),
                      fontWeight: FontWeight.w400,
                      height: 1.28,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  )
                else if (place.isFoodSpot && place.mustTry != null && place.mustTry!.isNotEmpty)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF2E1C12) : const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      '🍲 Must Try: ${place.mustTry}',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFFFFAB40) : const Color(0xFFD84315),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),
                Divider(height: 1, color: colorScheme.outlineVariant.withValues(alpha: 0.35)),
                const SizedBox(height: 8),

                // 4. Footer: Metro/Timings/Nearby, Real Distance & Rating
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    children: [
                      if (place.isPandal) ...[
                        if (place.nearestMetro != null && place.nearestMetro!.isNotEmpty) ...[
                          Icon(Icons.directions_subway_rounded, size: context.dynamicIcon(15), color: PujaColors.metroBlue),
                          const SizedBox(width: 4),
                          Text(
                            place.nearestMetro!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: context.dynamicFont(11.5),
                              fontWeight: FontWeight.w600,
                              color: PujaColors.metroBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ] else if (place.timings != null && place.timings!.isNotEmpty) ...[
                          Icon(Icons.schedule_rounded, size: context.dynamicIcon(15), color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            place.timings!,
                            style: GoogleFonts.plusJakartaSans(fontSize: context.dynamicFont(11.5), color: colorScheme.onSurfaceVariant),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ] else ...[
                        // Food spot nearby pandal context
                        if (place.nearbyPandal != null && place.nearbyPandal!.isNotEmpty) ...[
                          Icon(Icons.location_on_outlined, size: context.dynamicIcon(15), color: colorScheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text(
                            'Near ${place.nearbyPandal}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: context.dynamicFont(11.5),
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],

                      if (distanceLabel != null) ...[
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.near_me_rounded, size: context.dynamicIcon(11), color: colorScheme.primary),
                              const SizedBox(width: 3),
                              Text(
                                distanceLabel,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: context.dynamicFont(10.5),
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      if (place.rating != null && place.rating! > 0) ...[
                        const SizedBox(width: 10),
                        Row(
                          children: [
                            Icon(Icons.star_rounded, size: context.dynamicIcon(15), color: PujaColors.festivalGold),
                            const SizedBox(width: 2),
                            Text(
                              place.rating!.toStringAsFixed(1),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: context.dynamicFont(11.5),
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ],

                      if (place.isFoodSpot) ...[
                        const SizedBox(width: 10),
                        TextButton.icon(
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon: const Icon(Icons.map_outlined, size: 14, color: PujaColors.festivalGold),
                          label: const Text(
                            'Map',
                            style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: PujaColors.festivalGold),
                          ),
                          onPressed: onMapTap ?? onTap,
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

/// Backward compatibility wrapper for PandalCard that wraps PlaceCard.
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
    return PlaceCard(
      place: Place.fromPandal(pandal),
      onTap: onTap,
      distanceKm: distanceKm,
    );
  }
}
