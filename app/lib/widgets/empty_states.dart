/// Illustrative empty states with primary actions for better UX.
/// Provides consistent empty/error/offline states across the app.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';

/// Pre-defined empty state types.
enum EmptyStateType {
  /// No pandals found for search/filter
  noPandals,

  /// No food spots found
  noFoodSpots,

  /// No routes available
  noRoutes,

  /// No squad/group members
  noSquad,

  /// No favorites saved
  noFavorites,

  /// No visited pandals
  noVisited,

  /// Search returned no results
  noSearchResults,

  /// Offline mode
  offline,

  /// Network error
  networkError,

  /// Generic empty
  generic,

  /// Location permission needed
  locationPermission,

  /// No notifications
  noNotifications,
}

/// Configuration for an empty state.
class EmptyStateConfig {
  const EmptyStateConfig({
    required this.type,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.icon,
    this.lottieAsset,
    this.illustrationColor,
    this.showAction = true,
    this.showSecondaryAction = false,
    this.compact = false,
  });

  final EmptyStateType type;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final IconData? icon;
  final String? lottieAsset;
  final Color? illustrationColor;
  final bool showAction;
  final bool showSecondaryAction;
  final bool compact;

  /// Default configurations for each type.
  static EmptyStateConfig defaults(EmptyStateType type) {
    switch (type) {
      case EmptyStateType.noPandals:
        return EmptyStateConfig(
          type: type,
          title: 'No Pandals Found',
          message: 'Try adjusting your filters or search in a different area.',
          actionLabel: 'Clear Filters',
          icon: Icons.temple_hindu_outlined,
        );
      case EmptyStateType.noFoodSpots:
        return EmptyStateConfig(
          type: type,
          title: 'No Food Spots Nearby',
          message:
              'Explore the map to discover local delicacies around pandals.',
          actionLabel: 'Explore Map',
          icon: Icons.restaurant_outlined,
        );
      case EmptyStateType.noRoutes:
        return EmptyStateConfig(
          type: type,
          title: 'No Curated Routes Yet',
          message: 'Create your own hopping trail or check back for community routes.',
          actionLabel: 'Create Trail',
          icon: Icons.route_outlined,
        );
      case EmptyStateType.noSquad:
        return EmptyStateConfig(
          type: type,
          title: 'No Group Yet',
          message: 'Create a squad to hop pandals together with friends.',
          actionLabel: 'Create Squad',
          icon: Icons.group_outlined,
        );
      case EmptyStateType.noFavorites:
        return EmptyStateConfig(
          type: type,
          title: 'No Favorites Saved',
          message: 'Tap the heart on any pandal to save it here.',
          actionLabel: 'Explore Pandals',
          icon: Icons.favorite_outline,
        );
      case EmptyStateType.noVisited:
        return EmptyStateConfig(
          type: type,
          title: 'No Visited Pandals',
          message: 'Your visited pandals will appear here after you mark them.',
          actionLabel: 'Start Hopping',
          icon: Icons.check_circle_outline,
        );
      case EmptyStateType.noSearchResults:
        return EmptyStateConfig(
          type: type,
          title: 'No Results Found',
          message: 'Try a different search term or browse categories.',
          actionLabel: 'Clear Search',
          icon: Icons.search_off_outlined,
        );
      case EmptyStateType.offline:
        return EmptyStateConfig(
          type: type,
          title: 'You\'re Offline',
          message: 'Some features may be limited. Cached data is shown.',
          actionLabel: 'Retry',
          icon: Icons.wifi_off_outlined,
          secondaryActionLabel: 'Use Cached Data',
        );
      case EmptyStateType.networkError:
        return EmptyStateConfig(
          type: type,
          title: 'Something Went Wrong',
          message: 'Unable to load data. Please check your connection.',
          actionLabel: 'Try Again',
          icon: Icons.cloud_off_outlined,
        );
      case EmptyStateType.locationPermission:
        return EmptyStateConfig(
          type: type,
          title: 'Location Access Needed',
          message: 'Enable location to see nearby pandals and get directions.',
          actionLabel: 'Open Settings',
          icon: Icons.location_off_outlined,
        );
      case EmptyStateType.noNotifications:
        return EmptyStateConfig(
          type: type,
          title: 'No Notifications Yet',
          message: 'You\'ll see squad invites and updates here.',
          icon: Icons.notifications_none_outlined,
        );
      case EmptyStateType.generic:
        return EmptyStateConfig(
          type: type,
          title: 'Nothing Here Yet',
          message: 'Content will appear when available.',
          icon: Icons.inbox_outlined,
        );
    }
  }
}

/// Main empty state widget with illustration and actions.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.config, this.customIllustration});

  final EmptyStateConfig config;
  final Widget? customIllustration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaults = EmptyStateConfig.defaults(config.type);

    final effectiveTitle = config.title ?? defaults.title!;
    final effectiveMessage = config.message ?? defaults.message!;
    final effectiveActionLabel = config.actionLabel ?? defaults.actionLabel;
    final effectiveIcon = config.icon ?? defaults.icon;
    final effectiveLottie = config.lottieAsset ?? defaults.lottieAsset;
    final effectiveColor =
        config.illustrationColor ??
        defaults.illustrationColor ??
        theme.colorScheme.primary;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration
                _buildIllustration(
                  context,
                  effectiveColor,
                  effectiveIcon,
                  effectiveLottie,
                ),
                SizedBox(height: config.compact ? 16 : 24),
                // Title
                Text(
                  effectiveTitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: config.compact ? 18 : 22,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: config.compact ? 8 : 12),
                // Message
                Text(
                  effectiveMessage,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: config.compact ? 14 : 15,
                    fontWeight: FontWeight.w400,
                    color: theme.colorScheme.onSurfaceVariant,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                // Actions
                if (config.showAction && effectiveActionLabel != null) ...[
                  SizedBox(height: config.compact ? 16 : 24),
                  _buildActions(context),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(
    BuildContext context,
    Color color,
    IconData? icon,
    String? lottieAsset,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (customIllustration != null) {
      return customIllustration!;
    }

    if (lottieAsset != null) {
      return SizedBox(
        width: config.compact ? 80 : 120,
        height: config.compact ? 80 : 120,
        child: Lottie.asset(lottieAsset, fit: BoxFit.contain, repeat: true),
      );
    }

    return Container(
      width: config.compact ? 72 : 96,
      height: config.compact ? 72 : 96,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.15 : 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon ?? Icons.inbox_outlined,
        size: config.compact ? 32 : 44,
        color: color,
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final defaults = EmptyStateConfig.defaults(config.type);
    final actionLabel = config.actionLabel ?? defaults.actionLabel;
    final secondaryActionLabel =
        config.secondaryActionLabel ?? defaults.secondaryActionLabel;

    final actions = <Widget>[];

    // Primary action
    if (actionLabel != null) {
      actions.add(
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: config.onAction,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(actionLabel),
          ),
        ),
      );
    }

    // Secondary action
    if (config.showSecondaryAction && secondaryActionLabel != null) {
      actions.add(const SizedBox(height: 12));
      actions.add(
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: config.onSecondaryAction ?? defaults.onSecondaryAction,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(secondaryActionLabel),
          ),
        ),
      );
    }

    return Column(children: actions);
  }
}

/// Convenience constructors for common empty states.
class EmptyStates {
  EmptyStates._();

  /// No pandals found.
  static Widget noPandals({
    String? message,
    VoidCallback? onClearFilters,
    Key? key,
  }) => EmptyState(
    key: key,
    config: EmptyStateConfig(
      type: EmptyStateType.noPandals,
      message: message,
      actionLabel: 'Clear Filters',
      onAction: onClearFilters,
    ),
  );

  /// No food spots.
  static Widget noFoodSpots({
    String? message,
    VoidCallback? onExploreMap,
    Key? key,
  }) => EmptyState(
    key: key,
    config: EmptyStateConfig(
      type: EmptyStateType.noFoodSpots,
      message: message,
      actionLabel: 'Explore Map',
      onAction: onExploreMap,
    ),
  );

  /// No routes.
  static Widget noRoutes({
    String? message,
    VoidCallback? onCreateTrail,
    Key? key,
  }) => EmptyState(
    key: key,
    config: EmptyStateConfig(
      type: EmptyStateType.noRoutes,
      message: message,
      actionLabel: 'Create Trail',
      onAction: onCreateTrail,
    ),
  );

  /// No squad.
  static Widget noSquad({
    String? message,
    VoidCallback? onCreateSquad,
    Key? key,
  }) => EmptyState(
    key: key,
    config: EmptyStateConfig(
      type: EmptyStateType.noSquad,
      message: message,
      actionLabel: 'Create Squad',
      onAction: onCreateSquad,
    ),
  );

  /// No favorites.
  static Widget noFavorites({
    String? message,
    VoidCallback? onExplore,
    Key? key,
  }) => EmptyState(
    key: key,
    config: EmptyStateConfig(
      type: EmptyStateType.noFavorites,
      message: message,
      actionLabel: 'Explore Pandals',
      onAction: onExplore,
    ),
  );

  /// No visited.
  static Widget noVisited({
    String? message,
    VoidCallback? onStartHopping,
    Key? key,
  }) => EmptyState(
    key: key,
    config: EmptyStateConfig(
      type: EmptyStateType.noVisited,
      message: message,
      actionLabel: 'Start Hopping',
      onAction: onStartHopping,
    ),
  );

  /// No search results.
  static Widget noSearchResults({
    String? message,
    VoidCallback? onClearSearch,
    Key? key,
  }) => EmptyState(
    key: key,
    config: EmptyStateConfig(
      type: EmptyStateType.noSearchResults,
      message: message,
      actionLabel: 'Clear Search',
      onAction: onClearSearch,
    ),
  );

  /// Offline state.
  static Widget offline({
    String? message,
    VoidCallback? onRetry,
    VoidCallback? onUseCached,
    Key? key,
  }) => EmptyState(
    key: key,
    config: EmptyStateConfig(
      type: EmptyStateType.offline,
      message: message,
      actionLabel: 'Retry',
      onAction: onRetry,
      secondaryActionLabel: 'Use Cached Data',
      onSecondaryAction: onUseCached,
      showSecondaryAction: true,
    ),
  );

  /// Network error.
  static Widget networkError({
    String? message,
    VoidCallback? onRetry,
    Key? key,
  }) => EmptyState(
    key: key,
    config: EmptyStateConfig(
      type: EmptyStateType.networkError,
      message: message,
      actionLabel: 'Try Again',
      onAction: onRetry,
    ),
  );

  /// Location permission needed.
  static Widget locationPermission({
    String? message,
    VoidCallback? onOpenSettings,
    Key? key,
  }) => EmptyState(
    key: key,
    config: EmptyStateConfig(
      type: EmptyStateType.locationPermission,
      message: message,
      actionLabel: 'Open Settings',
      onAction: onOpenSettings,
    ),
  );

  /// Generic empty state.
  static Widget generic({
    String? title,
    String? message,
    IconData? icon,
    String? actionLabel,
    VoidCallback? onAction,
    Key? key,
  }) => EmptyState(
    key: key,
    config: EmptyStateConfig(
      type: EmptyStateType.generic,
      title: title,
      message: message,
      icon: icon,
      actionLabel: actionLabel,
      onAction: onAction,
    ),
  );

  /// Compact version for inline usage.
  static Widget compact(
    EmptyStateType type, {
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
    Key? key,
  }) => EmptyState(
    key: key,
    config: EmptyStateConfig(
      type: type,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
      compact: true,
    ),
  );
}

/// Error state with retry (for list/grid items).
class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    this.message = 'Something went wrong',
    this.onRetry,
    this.compact = false,
    this.icon,
  });

  final String message;
  final VoidCallback? onRetry;
  final bool compact;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(compact ? 12 : 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon ?? Icons.error_outline,
                size: compact ? 24 : 32,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            SizedBox(height: compact ? 8 : 16),
            Text(
              'Oops!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: compact ? 16 : 20,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: compact ? 4 : 8),
            Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                fontSize: compact ? 13 : 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              SizedBox(height: compact ? 12 : 20),
              SizedBox(
                width: compact ? 140 : 180,
                child: FilledButton(
                  onPressed: onRetry,
                  style: FilledButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: compact ? 10 : 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Try Again',
                    style: TextStyle(fontSize: compact ? 13 : 14),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading state with skeleton or spinner.
class LoadingState extends StatelessWidget {
  const LoadingState({
    super.key,
    this.message,
    this.compact = false,
    this.showSkeleton = false,
    this.skeletonItemCount = 3,
  });

  final String? message;
  final bool compact;
  final bool showSkeleton;
  final int skeletonItemCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (showSkeleton) {
      return Column(
        children: List.generate(
          skeletonItemCount,
          (index) => const _SkeletonItem(),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: compact ? 32 : 48,
              height: compact ? 32 : 48,
              child: CircularProgressIndicator(
                strokeWidth: compact ? 3 : 4,
                valueColor: AlwaysStoppedAnimation(theme.colorScheme.primary),
              ),
            ),
            if (message != null) ...[
              SizedBox(height: compact ? 12 : 16),
              Text(
                message!,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: compact ? 13 : 15,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark ? Colors.white10 : Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white10 : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Offline banner for top of screen.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({
    super.key,
    this.message = 'You\'re offline. Showing cached data.',
    this.onDismiss,
    this.onRetry,
  });

  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.errorContainer,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Icon(
                Icons.wifi_off,
                size: 18,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.onErrorContainer,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
              if (onDismiss != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onDismiss,
                  icon: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
