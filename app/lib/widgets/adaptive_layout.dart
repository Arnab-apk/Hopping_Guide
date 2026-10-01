/// Adaptive layout helpers for responsive design across phone, tablet, foldable, and desktop.
/// Provides breakpoint system, layout builders, and responsive utilities.
library adaptive_layout;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Material 3 inspired breakpoints for adaptive layouts.
class AppBreakpoints {
  AppBreakpoints._();

  // Breakpoint values (width in dp)
  static const double xs = 0;      // Phone portrait
  static const double sm = 600;    // Phone landscape / small tablet
  static const double md = 840;    // Tablet portrait
  static const double lg = 1200;   // Tablet landscape / desktop
  static const double xl = 1600;   // Large desktop

  /// Current breakpoint enum for semantic usage.
  static Breakpoint fromWidth(double width) {
    if (width < sm) return Breakpoint.xs;
    if (width < md) return Breakpoint.sm;
    if (width < lg) return Breakpoint.md;
    if (width < xl) return Breakpoint.lg;
    return Breakpoint.xl;
  }

  /// Whether the current width is at least the given breakpoint.
  static bool isAtLeast(double width, Breakpoint breakpoint) {
    return width >= _breakpointValue(breakpoint);
  }

  static double _breakpointValue(Breakpoint breakpoint) {
    switch (breakpoint) {
      case Breakpoint.xs:
        return xs;
      case Breakpoint.sm:
        return sm;
      case Breakpoint.md:
        return md;
      case Breakpoint.lg:
        return lg;
      case Breakpoint.xl:
        return xl;
    }
  }
}

/// Semantic breakpoint names.
enum Breakpoint { xs, sm, md, lg, xl }

/// Device form factor detection.
enum DeviceFormFactor {
  phone,
  tablet,
  foldable,
  desktop,
  watch,
}

/// Extension for responsive values based on breakpoint.
extension ResponsiveValue<T> on T {
  /// Returns a value based on the current breakpoint.
  T responsive(BuildContext context, {
    T? xs,
    T? sm,
    T? md,
    T? lg,
    T? xl,
  }) {
    final width = MediaQuery.of(context).size.width;
    final breakpoint = AppBreakpoints.fromWidth(width);

    switch (breakpoint) {
      case Breakpoint.xs:
        return xs ?? this;
      case Breakpoint.sm:
        return sm ?? xs ?? this;
      case Breakpoint.md:
        return md ?? sm ?? xs ?? this;
      case Breakpoint.lg:
        return lg ?? md ?? sm ?? xs ?? this;
      case Breakpoint.xl:
        return xl ?? lg ?? md ?? sm ?? xs ?? this;
    }
  }
}

/// Responsive builder that provides breakpoint and constraints.
class AdaptiveBuilder extends StatelessWidget {
  const AdaptiveBuilder({
    super.key,
    required this.builder,
    this.breakpoints = const [],
  });

  final Widget Function(BuildContext, Breakpoint, BoxConstraints) builder;
  final List<Breakpoint> breakpoints;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final breakpoint = AppBreakpoints.fromWidth(width);
        return builder(context, breakpoint, constraints);
      },
    );
  }
}

/// Adaptive scaffold that switches between navigation patterns.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    super.key,
    required this.body,
    this.navigationBar,
    this.navigationRail,
    this.drawer,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.bottomSheet,
  });

  final Widget body;
  final Widget? navigationBar;
  final Widget? navigationRail;
  final Widget? drawer;
  final Widget? floatingActionButton;
  final FloatingActionButtonLocation? floatingActionButtonLocation;
  final Widget? bottomSheet;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBuilder(
      builder: (context, breakpoint, constraints) {
        final isTabletOrLarger = breakpoint != Breakpoint.xs;

        if (isTabletOrLarger && navigationRail != null) {
          return Scaffold(
            drawer: drawer,
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
            bottomSheet: bottomSheet,
            body: Row(
              children: [
                navigationRail!,
                const VerticalDivider(width: 1, thickness: 1),
                Expanded(child: body),
              ],
            ),
          );
        }

        return Scaffold(
          drawer: drawer,
          bottomNavigationBar: navigationBar,
          floatingActionButton: floatingActionButton,
          floatingActionButtonLocation: floatingActionButtonLocation,
          bottomSheet: bottomSheet,
          body: body,
        );
      },
    );
  }
}

/// Two-pane layout for master-detail on tablets.
class TwoPaneLayout extends StatelessWidget {
  const TwoPaneLayout({
    super.key,
    required this.primaryPane,
    required this.secondaryPane,
    this.minPrimaryWidth = 320,
    this.maxPrimaryWidth = 480,
    this.primaryPaneWidth,
    this.divider = const VerticalDivider(width: 1, thickness: 1),
    this.showSecondaryInitially = true,
  });

  final Widget primaryPane;
  final Widget secondaryPane;
  final double minPrimaryWidth;
  final double maxPrimaryWidth;
  final double? primaryPaneWidth;
  final Widget divider;
  final bool showSecondaryInitially;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBuilder(
      builder: (context, breakpoint, constraints) {
        final isTabletOrLarger = breakpoint != Breakpoint.xs;

        if (!isTabletOrLarger) {
          // On phone, show only primary with navigation to secondary
          return primaryPane;
        }

        final availableWidth = constraints.maxWidth;
        final primaryWidth = primaryPaneWidth ??
            (availableWidth * 0.4).clamp(minPrimaryWidth, maxPrimaryWidth);

        return Row(
          children: [
            SizedBox(
              width: primaryWidth,
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: primaryPane,
              ),
            ),
            divider,
            Expanded(
              child: ColoredBox(
                color: Theme.of(context).colorScheme.surface,
                child: secondaryPane,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Responsive grid that adapts columns based on width.
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.xsColumns = 1,
    this.smColumns = 2,
    this.mdColumns = 3,
    this.lgColumns = 4,
    this.xlColumns = 5,
    this.spacing = 16,
    this.runSpacing = 16,
    this.aspectRatio,
    this.childAspectRatio,
  });

  final List<Widget> children;
  final int xsColumns;
  final int smColumns;
  final int mdColumns;
  final int lgColumns;
  final int xlColumns;
  final double spacing;
  final double runSpacing;
  final double? aspectRatio;
  final double? childAspectRatio;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBuilder(
      builder: (context, breakpoint, constraints) {
        final columns = switch (breakpoint) {
          Breakpoint.xs => xsColumns,
          Breakpoint.sm => smColumns,
          Breakpoint.md => mdColumns,
          Breakpoint.lg => lgColumns,
          Breakpoint.xl => xlColumns,
        };

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: childAspectRatio ?? aspectRatio ?? 1.0,
          ),
          itemCount: children.length,
          itemBuilder: (_, index) => children[index],
        );
      },
    );
  }
}

/// Responsive list that switches to grid on larger screens.
class AdaptiveList extends StatelessWidget {
  const AdaptiveList({
    super.key,
    required this.itemBuilder,
    required this.itemCount,
    this.listItemBuilder,
    this.gridItemBuilder,
    this.xsAsList = true,
    this.smAsList = true,
    this.spacing = 8,
    this.runSpacing = 8,
    this.gridColumns = 2,
    this.separator,
    this.padding,
  });

  final Widget Function(BuildContext, int) itemBuilder;
  final int itemCount;
  final Widget Function(BuildContext, int)? listItemBuilder;
  final Widget Function(BuildContext, int)? gridItemBuilder;
  final bool xsAsList;
  final bool smAsList;
  final double spacing;
  final double runSpacing;
  final int gridColumns;
  final Widget? separator;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBuilder(
      builder: (context, breakpoint, constraints) {
        final isList = switch (breakpoint) {
          Breakpoint.xs => xsAsList,
          Breakpoint.sm => smAsList,
          _ => false,
        };

        if (isList) {
          return ListView.separated(
            padding: padding,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            separatorBuilder: (_, __) => separator ?? SizedBox(height: spacing),
            itemBuilder: (context, index) =>
                listItemBuilder?.call(context, index) ?? itemBuilder(context, index),
          );
        }

        return GridView.builder(
          padding: padding,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridColumns,
            crossAxisSpacing: spacing,
            mainAxisSpacing: runSpacing,
            childAspectRatio: 1.0,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) =>
              gridItemBuilder?.call(context, index) ?? itemBuilder(context, index),
        );
      },
    );
  }
}

/// Responsive padding that scales with screen size.
class ResponsivePadding extends StatelessWidget {
  const ResponsivePadding({
    super.key,
    required this.child,
    this.xs = const EdgeInsets.all(16),
    this.sm = const EdgeInsets.all(20),
    this.md = const EdgeInsets.all(24),
    this.lg = const EdgeInsets.all(32),
    this.xl = const EdgeInsets.all(40),
  });

  final Widget child;
  final EdgeInsetsGeometry xs;
  final EdgeInsetsGeometry sm;
  final EdgeInsetsGeometry md;
  final EdgeInsetsGeometry lg;
  final EdgeInsetsGeometry xl;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBuilder(
      builder: (context, breakpoint, _) {
        final padding = switch (breakpoint) {
          Breakpoint.xs => xs,
          Breakpoint.sm => sm,
          Breakpoint.md => md,
          Breakpoint.lg => lg,
          Breakpoint.xl => xl,
        };
        return Padding(padding: padding, child: child);
      },
    );
  }
}

/// Responsive text style that scales appropriately.
class ResponsiveTextStyle extends StatelessWidget {
  const ResponsiveTextStyle({
    super.key,
    required this.child,
    this.xsStyle,
    this.smStyle,
    this.mdStyle,
    this.lgStyle,
    this.xlStyle,
    this.baseStyle,
  });

  final Widget child;
  final TextStyle? xsStyle;
  final TextStyle? smStyle;
  final TextStyle? mdStyle;
  final TextStyle? lgStyle;
  final TextStyle? xlStyle;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBuilder(
      builder: (context, breakpoint, _) {
        final style = switch (breakpoint) {
          Breakpoint.xs => xsStyle ?? baseStyle,
          Breakpoint.sm => smStyle ?? xsStyle ?? baseStyle,
          Breakpoint.md => mdStyle ?? smStyle ?? xsStyle ?? baseStyle,
          Breakpoint.lg => lgStyle ?? mdStyle ?? smStyle ?? xsStyle ?? baseStyle,
          Breakpoint.xl => xlStyle ?? lgStyle ?? mdStyle ?? smStyle ?? xsStyle ?? baseStyle,
        };
        return DefaultTextStyle(
          style: style ?? const TextStyle(),
          child: child,
        );
      },
    );
  }
}

/// Visibility widget that shows/hides based on breakpoint.
class BreakpointVisibility extends StatelessWidget {
  const BreakpointVisibility({
    super.key,
    required this.child,
    this.visibleOn = const [],
    this.hiddenOn = const [],
    this.replacement = const SizedBox.shrink(),
  });

  final Widget child;
  final List<Breakpoint> visibleOn;
  final List<Breakpoint> hiddenOn;
  final Widget replacement;

  @override
  Widget build(BuildContext context) {
    return AdaptiveBuilder(
      builder: (context, breakpoint, _) {
        final shouldShow = visibleOn.isEmpty
            ? !hiddenOn.contains(breakpoint)
            : visibleOn.contains(breakpoint);
        return shouldShow ? child : replacement;
      },
    );
  }
}

/// Extension for context-aware responsive values.
extension AdaptiveContext on BuildContext {
  /// Current breakpoint.
  Breakpoint get breakpoint => AppBreakpoints.fromWidth(MediaQuery.of(this).size.width);

  /// Whether current device is tablet or larger.
  bool get isTabletOrLarger => breakpoint != Breakpoint.xs;

  /// Whether current device is desktop.
  bool get isDesktop => breakpoint == Breakpoint.lg || breakpoint == Breakpoint.xl;

  /// Responsive value shortcut.
  T responsive<T>(T value, {
    T? xs,
    T? sm,
    T? md,
    T? lg,
    T? xl,
  }) =>
      value.responsive(this, xs: xs, sm: sm, md: md, lg: lg, xl: xl);

  /// Responsive padding.
  EdgeInsetsGeometry responsivePadding({
    EdgeInsetsGeometry? xs,
    EdgeInsetsGeometry? sm,
    EdgeInsetsGeometry? md,
    EdgeInsetsGeometry? lg,
    EdgeInsetsGeometry? xl,
  }) {
    final bp = breakpoint;
    if (bp == Breakpoint.xl) return xl ?? lg ?? md ?? sm ?? xs ?? EdgeInsets.zero;
    if (bp == Breakpoint.lg) return lg ?? md ?? sm ?? xs ?? EdgeInsets.zero;
    if (bp == Breakpoint.md) return md ?? sm ?? xs ?? EdgeInsets.zero;
    if (bp == Breakpoint.sm) return sm ?? xs ?? EdgeInsets.zero;
    return xs ?? EdgeInsets.zero;
  }
}