/// Skeleton loaders and shimmer placeholders for perceived performance.
/// Provides consistent loading states across the app with branded shimmer colors.
library skeleton_loaders;

import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../config/theme.dart';

/// Base skeleton widget with customizable shape and shimmer.
class Skeleton extends StatelessWidget {
  const Skeleton({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    this.margin,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final EdgeInsetsGeometry? margin;
  final Color? baseColor;
  final Color? highlightColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final effectiveBaseColor = baseColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.black.withValues(alpha: 0.06));
    final effectiveHighlightColor = highlightColor ??
        (isDark
            ? Colors.white.withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.3));

    final child = Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: effectiveBaseColor,
        borderRadius: shape == BoxShape.rectangle
            ? BorderRadius.circular(borderRadius)
            : null,
        shape: shape,
      ),
    );

    if (!enabled) return child;

    return Shimmer.fromColors(
      baseColor: effectiveBaseColor,
      highlightColor: effectiveHighlightColor,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }
}

/// Skeleton for pandal list cards.
class PandalCardSkeleton extends StatelessWidget {
  const PandalCardSkeleton({super.key, this.showImage = true});

  final bool showImage;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image placeholder
          if (showImage)
            const Skeleton(
              height: 160,
              width: double.infinity,
              borderRadius: 0,
            ),
          // Content placeholder
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Zone badge + title row
                Row(
                  children: [
                    const Skeleton(
                      width: 70,
                      height: 20,
                      borderRadius: 6,
                      shape: BoxShape.rectangle,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Skeleton(height: 22, borderRadius: 4),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Subtitle / location
                const Skeleton(width: 120, height: 16, borderRadius: 4),
                const SizedBox(height: 12),
                // Meta row: distance, crowd, rating
                Row(
                  children: [
                    const Skeleton(width: 80, height: 16, borderRadius: 4),
                    const SizedBox(width: 12),
                    const Skeleton(width: 60, height: 16, borderRadius: 4),
                    const SizedBox(width: 12),
                    const Skeleton(width: 50, height: 16, borderRadius: 4),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton for the pandal detail sheet.
class PandalDetailSkeleton extends StatelessWidget {
  const PandalDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Drag handle
        const Center(
          child: Skeleton(
            width: 36,
            height: 4,
            margin: EdgeInsets.only(top: 10, bottom: 8),
            borderRadius: 2,
          ),
        ),
        // Header section
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zone badge + actions
              Row(
                children: [
                  const Skeleton(width: 80, height: 24, borderRadius: 8),
                  const Spacer(),
                  Row(
                    children: List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Skeleton(width: 40, height: 40, shape: BoxShape.circle),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Title
              const Skeleton(width: double.infinity, height: 28, borderRadius: 4),
              const SizedBox(height: 8),
              // Subtitle / area
              const Skeleton(width: 180, height: 18, borderRadius: 4),
              const SizedBox(height: 16),
              // Meta chips row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  4,
                  (i) => const Skeleton(width: 100, height: 32, borderRadius: 16),
                ),
              ),
              const SizedBox(height: 20),
              // Description section
              const Skeleton(width: 100, height: 18, borderRadius: 4),
              const SizedBox(height: 8),
              Column(
                children: List.generate(
                  3,
                  (i) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: const Skeleton(width: double.infinity, height: 16, borderRadius: 4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: Skeleton(height: 48, borderRadius: 16),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Skeleton(height: 48, borderRadius: 16),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Skeleton for the map screen overlay elements.
class MapScreenSkeleton extends StatelessWidget
    implements PreferredSizeWidget {
  const MapScreenSkeleton({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // App bar skeleton
        Container(
          height: kToolbarHeight + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          child: const Row(
            children: [
              SizedBox(width: 16),
              Skeleton(width: 120, height: 24, borderRadius: 4),
              Spacer(),
              Skeleton(width: 40, height: 40, shape: BoxShape.circle),
              SizedBox(width: 8),
              Skeleton(width: 40, height: 40, shape: BoxShape.circle),
              SizedBox(width: 16),
            ],
          ),
        ),
        // Search bar skeleton
        const Padding(
          padding: EdgeInsets.all(16),
          child: Skeleton(height: 56, borderRadius: 28),
        ),
        // Category chips skeleton
        const SizedBox(
          height: 48,
          child: Center(
            child: Skeleton(width: 200, height: 32, borderRadius: 16),
          ),
        ),
      ],
    );
  }
}

/// Skeleton for route cards.
class RouteCardSkeleton extends StatelessWidget {
  const RouteCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon + title
            Row(
              children: [
                const Skeleton(width: 48, height: 48, shape: BoxShape.circle),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Skeleton(width: 150, height: 20, borderRadius: 4),
                      const SizedBox(height: 4),
                      const Skeleton(width: 100, height: 14, borderRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Stats row
            Row(
              children: List.generate(
                3,
                (i) => Expanded(
                  child: Column(
                    children: [
                      const Skeleton(width: 40, height: 24, borderRadius: 4),
                      const SizedBox(height: 2),
                      const Skeleton(width: 60, height: 12, borderRadius: 4),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Action button
            const Skeleton(width: double.infinity, height: 44, borderRadius: 12),
          ],
        ),
      ),
    );
  }
}

/// Skeleton for group/squad screen.
class GroupScreenSkeleton extends StatelessWidget {
  const GroupScreenSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header
        const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(child: Skeleton(width: 150, height: 24, borderRadius: 4)),
              SizedBox(width: 12),
              Skeleton(width: 120, height: 40, borderRadius: 20),
            ],
          ),
        ),
        // Squad list or empty state
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 3,
            itemBuilder: (_, __) => Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Skeleton(width: 56, height: 56, shape: BoxShape.circle),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Skeleton(width: 120, height: 20, borderRadius: 4),
                          const SizedBox(height: 4),
                          const Skeleton(width: 80, height: 14, borderRadius: 4),
                        ],
                      ),
                    ),
                    const Skeleton(width: 80, height: 36, borderRadius: 18),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Skeleton for search autocomplete results.
class SearchAutocompleteSkeleton extends StatelessWidget {
  const SearchAutocompleteSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (_, __) => ListTile(
        leading: const Skeleton(width: 40, height: 40, shape: BoxShape.circle),
        title: const Skeleton(width: 150, height: 18, borderRadius: 4),
        subtitle: const Skeleton(width: 100, height: 14, borderRadius: 4),
        trailing: const Skeleton(width: 24, height: 24, shape: BoxShape.circle),
      ),
    );
  }
}

/// Skeleton for profile/user avatar.
class AvatarSkeleton extends StatelessWidget {
  const AvatarSkeleton({super.key, this.radius = 20});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return Skeleton(
      width: radius * 2,
      height: radius * 2,
      shape: BoxShape.circle,
    );
  }
}

/// Skeleton for bottom navigation bar during load.
class BottomNavSkeleton extends StatelessWidget {
  const BottomNavSkeleton({super.key, this.itemCount = 5});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(
          itemCount,
          (i) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Skeleton(width: 24, height: 24, shape: BoxShape.circle),
              const SizedBox(height: 4),
              const Skeleton(width: 40, height: 12, borderRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// Multi-purpose content skeleton for generic lists.
class ContentSkeleton extends StatelessWidget {
  const ContentSkeleton({
    super.key,
    this.itemCount = 5,
    this.itemBuilder,
    this.separator,
  });

  final int itemCount;
  final Widget Function(int index)? itemBuilder;
  final Widget? separator;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => separator ?? const SizedBox(height: 8),
      itemBuilder: (_, index) =>
          itemBuilder?.call(index) ?? const PandalCardSkeleton(),
    );
  }
}

/// Shimmer wrapper with custom colors for brand consistency.
class BrandedShimmer extends StatelessWidget {
  const BrandedShimmer({
    super.key,
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.direction = ShimmerDirection.ltr,
    this.period = const Duration(milliseconds: 1500),
  });

  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final ShimmerDirection direction;
  final Duration period;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: baseColor ??
          (isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.05)),
      highlightColor: highlightColor ??
          (isDark
              ? Colors.white.withValues(alpha: 0.12)
              : theme.colorScheme.primary.withValues(alpha: 0.15)),
      direction: direction,
      period: period,
      child: child,
    );
  }
}