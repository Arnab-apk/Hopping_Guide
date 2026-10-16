import 'package:flutter/material.dart';

/// Uma's print-inspired finish. Keep geometry steady during pressed states.
ThemeData neoTheme(ThemeData base) {
  final dark = base.brightness == Brightness.dark;
  final colors = base.colorScheme.copyWith(
    surface: dark ? const Color(0xFF191719) : const Color(0xFFFFF9E9),
    secondaryContainer: dark
        ? const Color(0xFF51451C)
        : const Color(0xFFFFDA62),
    onSecondaryContainer: dark
        ? const Color(0xFFFFE8A0)
        : const Color(0xFF282118),
    outline: dark ? const Color(0xFFE4D9CC) : const Color(0xFF30252A),
  );
  final ink = colors.outline;
  final shape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(8),
    side: BorderSide(color: ink, width: 2),
  );
  ButtonStyle finish(ButtonStyle? style, {bool shadow = true}) {
    return (style ?? const ButtonStyle()).copyWith(
      shape: WidgetStatePropertyAll(shape),
      elevation: const WidgetStatePropertyAll(0),
      side: WidgetStateProperty.resolveWith(
        (states) => BorderSide(
          color: states.contains(WidgetState.disabled)
              ? colors.outlineVariant
              : ink,
          width: states.contains(WidgetState.focused) ? 3 : 2,
        ),
      ),
      backgroundBuilder: shadow
          ? (context, states, child) => CustomPaint(
              painter: states.contains(WidgetState.disabled) || states.contains(WidgetState.pressed)
                ? null : _OffsetShadow(dark ? Colors.black : ink),
              child: child,
            )
          : null,
    );
  }

  return base.copyWith(
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    canvasColor: colors.surface,
    textTheme: base.textTheme.copyWith(
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    ),
    appBarTheme: base.appBarTheme.copyWith(
      backgroundColor: colors.surface,
      titleTextStyle: base.appBarTheme.titleTextStyle?.copyWith(
        fontWeight: FontWeight.w800,
      ),
      shape: Border(bottom: BorderSide(color: ink, width: 1.5)),
    ),
    cardTheme: base.cardTheme.copyWith(shape: shape, elevation: 0),
    filledButtonTheme: FilledButtonThemeData(
      style: finish(base.filledButtonTheme.style),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: finish(base.elevatedButtonTheme.style),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: finish(base.outlinedButtonTheme.style, shadow: false),
    ),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style?.copyWith(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    ),
    navigationBarTheme: base.navigationBarTheme.copyWith(
      indicatorColor: colors.secondaryContainer,
      indicatorShape: shape,
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          size: 24,
          color: states.contains(WidgetState.selected)
              ? colors.onSecondaryContainer
              : colors.onSurfaceVariant,
        ),
      ),
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: ink, width: 1.5),
      selectedColor: colors.secondaryContainer,
      secondarySelectedColor: colors.secondaryContainer,
      secondaryLabelStyle: base.textTheme.labelLarge?.copyWith(
        color: colors.onSecondaryContainer,
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: base.segmentedButtonTheme.style?.copyWith(
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        side: WidgetStatePropertyAll(BorderSide(color: ink, width: 1.5)),
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.secondaryContainer
              : colors.surfaceContainerLow,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? colors.onSecondaryContainer
              : colors.onSurface,
        ),
      ),
    ),
    inputDecorationTheme: base.inputDecorationTheme.copyWith(
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: ink, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: colors.primary, width: 3),
      ),
    ),
    searchBarTheme: base.searchBarTheme.copyWith(
      shape: WidgetStatePropertyAll(shape),
      side: WidgetStatePropertyAll(BorderSide(color: ink, width: 1.5)),
    ),
    dialogTheme: base.dialogTheme.copyWith(shape: shape),
    popupMenuTheme: base.popupMenuTheme.copyWith(shape: shape),
    bottomSheetTheme: base.bottomSheetTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        side: BorderSide(color: ink, width: 2),
      ),
    ),
    floatingActionButtonTheme: base.floatingActionButtonTheme.copyWith(
      shape: shape,
      elevation: 0,
    ),
    snackBarTheme: base.snackBarTheme.copyWith(shape: shape, elevation: 0),
  );
}

/// Paint only outside the control, preserving Material's fill and ink feedback.
class _OffsetShadow extends CustomPainter {
  const _OffsetShadow(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final shape = RRect.fromRectAndRadius(rect, const Radius.circular(8));
    final shadow = Path()..addRRect(shape.shift(const Offset(3, 3)));
    final face = Path()..addRRect(shape);
    canvas.drawPath(Path.combine(PathOperation.difference, shadow, face), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_OffsetShadow oldDelegate) => color != oldDelegate.color;
}
