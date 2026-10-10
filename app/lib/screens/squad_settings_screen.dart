import '../widgets/app_text_edit_dialog.dart';
import '../widgets/app_notice.dart';

import 'package:flutter/material.dart';
import '../widgets/app_page_intro.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/squad_service.dart';
import '../utils/haversine.dart';

/// Dedicated configuration screen for Durga Puja Hopping Group settings.
/// Houses edit group name, meet-up landmark, separation alert threshold,
/// guest Google account linking, and leave group.
class SquadSettingsScreen extends StatelessWidget {
  const SquadSettingsScreen({super.key});

  void _editSquadName(BuildContext context, SquadService squadService) {
    showDialog(
      context: context,
      builder: (_) => AppTextEditDialog(
        title: 'Edit Group Name',
        label: 'Group name',
        initialValue: squadService.squadName ?? 'My Group',
        hint: 'e.g. Bagbazar Pandal Crawlers',
        onSave: squadService.updateSquadName,
      ),
    );
  }

  void _editMeetupPoint(BuildContext context, SquadService squadService) {
    showDialog(
      context: context,
      builder: (_) => AppTextEditDialog(
        title: 'Designated Meet-up Point',
        label: 'Landmark or gate',
        initialValue: squadService.meetupPointName,
        hint: 'e.g. Under Gariahat Flyover clock',
        onSave: (name) => squadService.setMeetupPoint(name),
      ),
    );
  }

  void _configureAlertDistance(
    BuildContext context,
    SquadService squadService,
  ) {
    final current = squadService.separationThresholdMeters;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.6),
            width: 1,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
        title: Text(
          'Separation Alert Distance',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        children: [100, 250, 500, 1000].map((meters) {
          final isSelected = current == meters;
          return ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? theme.colorScheme.primary : null,
            ),
            title: Text('$meters m ${meters == 500 ? '(Standard)' : ''}'),
            subtitle: Text(
              meters <= 250
                  ? 'High sensitivity — dense pandal crowds'
                  : meters <= 500
                  ? 'Standard pandal hopping zone'
                  : 'Wide area — neighborhood parikrama',
              style: const TextStyle(fontSize: 12),
            ),
            onTap: () {
              HapticFeedback.selectionClick();
              squadService.setSeparationThreshold(meters);
              Navigator.pop(ctx);
              showAppSuccessNotice(
                context,
                'Separation alert threshold set to $meters m',
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _linkGoogleAccount(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final res = await AuthService.instance.upgradeGuestToGoogle();
    if (!context.mounted) return;
    if (res.isSuccess) {
      showAppSuccessNotice(
        context,
        '🎉 Account upgraded to Google! Your group is preserved.',
      );
    } else if (!res.isCancelled) {
      showAppErrorNotice(
        context,
        res.errorMessage ?? 'Failed to upgrade account',
      );
    }
  }

  Future<void> _confirmLeaveSquad(
    BuildContext context,
    SquadService squadService,
  ) async {
    final rawName = squadService.squadName ?? 'Group';
    final cleanName = rawName.replaceAll(RegExp(r',\s*s\b'), "'s");
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.6),
            width: 1,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.exit_to_app_rounded,
                size: 20,
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Leave Group?'),
          ],
        ),
        content: Text('Are you sure you want to leave "$cleanName"?'),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.selectionClick();
              Navigator.pop(ctx, false);
            },
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx, true);
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      final left = await squadService.leaveSquad();
      if (context.mounted) {
        if (left) Navigator.pop(context); // return to main group screen
        if (left) {
          showAppInfoNotice(context, 'You left the group.');
        } else {
          showAppErrorNotice(
            context,
            squadService.lastError ?? 'Could not leave the group.',
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final squadService = Provider.of<SquadService>(context);
    AuthService? auth;
    try {
      auth = context.watch<AuthService>();
    } catch (_) {
      auth = null;
    }
    final authUser =
        auth?.currentUserModel ?? AuthService.instance.currentUserModel;
    final isGuest = authUser?.isGuest ?? false;

    final squadName = (squadService.squadName ?? 'My Group').replaceAll(
      RegExp(r',\s*s\b'),
      "'s",
    );
    final meetupPoint = squadService.meetupPointName;
    final alertDistance = formatDistance(
      squadService.separationThresholdMeters.toDouble(),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Group Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          const AppPageIntro(title: 'Stay together',
            description: 'Manage your group, meet-up point and separation alerts.',
            icon: Icons.tune_rounded),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Group name'),
            subtitle: Text(squadName),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              HapticFeedback.selectionClick();
              _editSquadName(context, squadService);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.place_outlined),
            title: const Text('Designated meet-up point'),
            subtitle: Text(meetupPoint),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              HapticFeedback.selectionClick();
              _editMeetupPoint(context, squadService);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.straighten_outlined),
            title: const Text('Separation alert distance'),
            subtitle: Text(alertDistance),
            trailing: const Icon(Icons.chevron_right, size: 18),
            onTap: () {
              HapticFeedback.selectionClick();
              _configureAlertDistance(context, squadService);
            },
          ),
          if (isGuest) ...[
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.login, color: AppColors.accentGold),
              title: const Text('Link Google account'),
              subtitle: const Text('Keep your group across devices'),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _linkGoogleAccount(context),
            ),
          ],
          const Divider(height: 24),
          ListTile(
            leading: const Icon(
              Icons.exit_to_app,
              color: AppColors.semanticAlert,
            ),
            title: const Text(
              'Leave group',
              style: TextStyle(
                color: AppColors.semanticAlert,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () {
              HapticFeedback.lightImpact();
              _confirmLeaveSquad(context, squadService);
            },
          ),
        ],
      ),
    );
  }
}
