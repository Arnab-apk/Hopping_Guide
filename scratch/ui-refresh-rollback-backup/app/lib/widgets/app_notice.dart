import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';

/// One readable, dismissible floating notice at a time; preserve any recovery action.
void showAppSnackBar(BuildContext context, SnackBar notice) {
  if (!context.mounted) return;
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger == null) return;

  final theme = Theme.of(context);

  final background =
      notice.backgroundColor ?? theme.colorScheme.surfaceContainerLow;
  final foreground =
      ThemeData.estimateBrightnessForColor(background) == Brightness.dark
      ? Colors.white
      : const Color(0xFF1F1F1F);

  final media = MediaQuery.of(context);
  final available =
      media.size.height - media.viewInsets.bottom - media.padding.vertical;

  messenger.clearSnackBars();
  HapticFeedback.lightImpact();

  messenger.showSnackBar(
    SnackBar(
      content: Semantics(
        liveRegion: true,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: math.max(48, available * .28)),
          child: SingleChildScrollView(
            child: DefaultTextStyle.merge(
              style: GoogleFonts.plusJakartaSans(
                color: foreground,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              child: notice.content,
            ),
          ),
        ),
      ),
      backgroundColor: background,
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.fromLTRB(
        math.max(16, (media.size.width - 560) / 2),
        0,
        math.max(16, (media.size.width - 560) / 2),
        16,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outline, width: 2),
      ),
      elevation: 0,
      showCloseIcon: true,
      closeIconColor: foreground.withValues(alpha: 0.8),
      action: notice.action,
      actionOverflowThreshold: .3,
      duration: notice.duration.inMilliseconds < 1500
          ? const Duration(milliseconds: 3200)
          : notice.duration,
      persist: notice.persist,
      onVisible: notice.onVisible,
      dismissDirection: DismissDirection.horizontal,
    ),
  );
}

/// Rich helper for displaying a Success feedback notification.
void showAppSuccessNotice(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(milliseconds: 3200),
}) {
  _showRichNotice(
    context,
    message: message,
    icon: Icons.check_circle_rounded,
    iconColor: const Color(0xFF4ADE80), // Emerald Green
    iconBgColor: const Color(0xFF10281C),
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );
}

/// Rich helper for displaying an Error notification.
void showAppErrorNotice(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  _showRichNotice(
    context,
    message: message,
    icon: Icons.error_outline_rounded,
    iconColor: const Color(0xFFF87171), // Coral Red
    iconBgColor: const Color(0xFF351318),
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );
}

/// Rich helper for displaying an Info notification.
void showAppInfoNotice(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(milliseconds: 3200),
}) {
  _showRichNotice(
    context,
    message: message,
    icon: Icons.info_outline_rounded,
    iconColor: const Color(0xFF60A5FA), // Sky Blue
    iconBgColor: const Color(0xFF132238),
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );
}

/// Rich helper for displaying a Warning notification.
void showAppWarningNotice(
  BuildContext context,
  String message, {
  String? actionLabel,
  VoidCallback? onAction,
  Duration duration = const Duration(seconds: 4),
}) {
  _showRichNotice(
    context,
    message: message,
    icon: Icons.warning_amber_rounded,
    iconColor: PujaColors.festivalGold, // Sacred Gold
    iconBgColor: const Color(0xFF2C220E),
    actionLabel: actionLabel,
    onAction: onAction,
    duration: duration,
  );
}

void _showRichNotice(
  BuildContext context, {
  required String message,
  required IconData icon,
  required Color iconColor,
  required Color iconBgColor,
  String? actionLabel,
  VoidCallback? onAction,
  required Duration duration,
}) {
  if (!context.mounted) return;
  final theme = Theme.of(context);
  final fg = theme.colorScheme.onSurface;

  showAppSnackBar(
    context,
    SnackBar(
      backgroundColor: theme.colorScheme.surfaceContainerLow,
      duration: duration,
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconBgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.plusJakartaSans(
                color: fg,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
      action: actionLabel != null && onAction != null
          ? SnackBarAction(
              label: actionLabel,
              textColor: theme.colorScheme.primary,
              onPressed: () {
                HapticFeedback.selectionClick();
                onAction();
              },
            )
          : null,
    ),
  );
}
