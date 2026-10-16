import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';

import '../models/pandal.dart';
import '../models/place.dart';
import '../models/pandal_photo.dart';
import 'pandal_photo_gallery.dart';
import '../services/location_service.dart';
import '../services/pandal_user_state_service.dart';
import '../utils/animation_constants.dart';
import '../utils/constants.dart';

/// Shared discovery card with readable metadata and independent save/map actions.
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
    final colors = theme.colorScheme;
    final userState = context.read<PandalUserStateService?>();
    final isFav = context.select<PandalUserStateService?, bool>(
      (state) => state?.isFavorite(place.id) ?? false,
    );
    final isVis =
        place.isPandal &&
        context.select<PandalUserStateService?, bool>(
          (state) => state?.isVisited(place.id) ?? false,
        );
    final distanceLabel = distanceKm != null
        ? '${distanceKm!.toStringAsFixed(1)} km'
        : context.select<LocationService?, String?>(
            (loc) => loc?.formatDistance(place.latitude, place.longitude),
          );

    final card = RepaintBoundary(
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: colors.surfaceContainerLow,
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isVis ? colors.primary : colors.outline,
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                Widget metadata(
                  String label, {
                  IconData? icon,
                  bool category = false,
                  double? maxWidth,
                }) => _PlaceMetadata(
                  label: label,
                  icon: icon,
                  maxWidth: maxWidth ?? constraints.maxWidth,
                  background: category
                      ? colors.secondaryContainer
                      : colors.surfaceContainerHigh,
                  foreground: category
                      ? colors.onSecondaryContainer
                      : colors.onSurfaceVariant,
                );
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (place.isPandal &&
                        PandalPhoto.isSupportedUrl(place.imageUrl ?? '')) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: PandalPhotoImage(
                            photo: PandalPhoto(url: place.imageUrl!),
                            pandalName: place.name,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                metadata(
                                  place.isPandal
                                      ? (place.zone?.label ?? 'Pandal')
                                      : (place.type ?? 'Culinary Stop'),
                                  category: true,
                                  maxWidth: (constraints.maxWidth - 56).clamp(
                                    0.0,
                                    double.infinity,
                                  ),
                                ),
                                if (isVis)
                                  metadata(
                                    'Hopped',
                                    icon: Icons.check_circle_outline_rounded,
                                    category: true,
                                    maxWidth: (constraints.maxWidth - 56).clamp(
                                      0.0,
                                      double.infinity,
                                    ),
                                  ),
                                if (place.isFoodSpot &&
                                    place.priceRange != null)
                                  Text(
                                    place.priceRange!,
                                    style: theme.textTheme.labelLarge,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Semantics(
                          toggled: isFav,
                          child: IconButton(
                            tooltip: isFav
                                ? 'Remove from favorites'
                                : 'Add to favorites',
                            constraints: const BoxConstraints(
                              minWidth: 48,
                              minHeight: 48,
                            ),
                            icon: Icon(
                              isFav
                                  ? Icons.bookmark_rounded
                                  : Icons.bookmark_border_rounded,
                              color: isFav
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                            onPressed: userState == null
                                ? null
                                : () {
                                    HapticFeedback.selectionClick();
                                    userState.toggleFavorite(place.id);
                                  },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      place.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                        color: colors.onSurface,
                      ),
                    ),
                    if (place.isPandal && place.theme?.isNotEmpty == true) ...[
                      const SizedBox(height: 8),
                      Text(
                        place.theme!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                          height: 1.45,
                        ),
                      ),
                    ],
                    if (place.isFoodSpot &&
                        place.mustTry?.isNotEmpty == true) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ExcludeSemantics(
                              child: Icon(
                                Icons.restaurant_rounded,
                                size: 20,
                                color: colors.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Must Try: ${place.mustTry}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: colors.onPrimaryContainer,
                                  fontWeight: FontWeight.w600,
                                  height: 1.45,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Divider(height: 1, color: colors.outlineVariant),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        if (place.isPandal) ...[
                          if (place.nearestMetro?.isNotEmpty == true)
                            metadata(
                              place.nearestMetro!,
                              icon: Icons.directions_subway_rounded,
                            )
                          else if (place.timings?.isNotEmpty == true)
                            metadata(
                              place.timings!,
                              icon: Icons.schedule_rounded,
                            ),
                        ] else if (place.nearbyPandal?.isNotEmpty == true)
                          metadata(
                            'Near ${place.nearbyPandal}',
                            icon: Icons.location_on_outlined,
                          ),
                        if (distanceLabel != null)
                          metadata(distanceLabel, icon: Icons.near_me_outlined),
                        if (place.rating != null && place.rating! > 0)
                          Semantics(
                            label:
                                'Rating ${place.rating!.toStringAsFixed(1)} out of 5',
                            excludeSemantics: true,
                            child: metadata(
                              place.rating!.toStringAsFixed(1),
                              icon: Icons.star_outline_rounded,
                            ),
                          ),
                        if (place.isFoodSpot)
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              minimumSize: const Size(48, 48),
                            ),
                            onPressed: onMapTap ?? onTap,
                            icon: const Icon(Icons.map_outlined, size: 20),
                            label: const Text('Map'),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    if (place.rawPandal != null && !MediaQuery.disableAnimationsOf(context)) {
      return card.animate(
        effects: [
          FadeEffect(
            duration: AppDurations.emphasis,
            curve: AppCurves.standardEaseOut,
          ),
          SlideEffect(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
            duration: AppDurations.emphasis,
            curve: AppCurves.standardEaseOut,
          ),
        ],
      );
    }
    return card;
  }
}

/// Metadata reflows at large text sizes instead of overflowing the card.
class _PlaceMetadata extends StatelessWidget {
  const _PlaceMetadata({
    required this.label,
    required this.maxWidth,
    required this.background,
    required this.foreground,
    this.icon,
  });
  final String label;
  final double maxWidth;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: maxWidth),
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            ExcludeSemantics(child: Icon(icon, size: 16, color: foreground)),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Backward compatibility wrapper for callers that hold a Pandal.
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
  Widget build(BuildContext context) => PlaceCard(
    place: Place.fromPandal(pandal),
    onTap: onTap,
    distanceKm: distanceKm,
  );
}
