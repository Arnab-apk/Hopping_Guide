import 'package:flutter/material.dart';

/// A consistent, accessible filter control for discovery screens.
class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.avatar,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = selected
        ? colors.onPrimaryContainer
        : colors.onSurfaceVariant;
    return Tooltip(
      message: label,
      child: FilterChip(
        selected: selected,
        onSelected: onSelected,
        avatar: avatar,
        label: Text(
          label,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.ellipsis,
        ),
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: IconThemeData(size: 18, color: foreground),
        showCheckmark: false,
        backgroundColor: colors.surfaceContainerLow,
        selectedColor: colors.primaryContainer,
        side: BorderSide(
          color: selected
              ? colors.primary.withValues(alpha: .3)
              : colors.outlineVariant,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
      ),
    );
  }
}
