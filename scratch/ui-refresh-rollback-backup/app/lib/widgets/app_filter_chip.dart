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
        ? colors.onSecondaryContainer
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
        showCheckmark: true,
        checkmarkColor: foreground,
        backgroundColor: colors.surfaceContainerLow,
        selectedColor: colors.secondaryContainer,
        side: BorderSide(color: colors.outline, width: selected ? 2 : 1.5),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
      ),
    );
  }
}
