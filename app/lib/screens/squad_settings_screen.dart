import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../services/auth_service.dart';
import '../services/squad_service.dart';
import '../utils/haversine.dart';

/// Dedicated configuration screen for Durga Puja Hopping Squad settings.
/// Houses edit squad name, meet-up landmark, separation alert threshold,
/// guest Google account linking, and leave squad.
class SquadSettingsScreen extends StatelessWidget {
  const SquadSettingsScreen({super.key});

  void _editSquadName(BuildContext context, SquadService squadService) {
    final current = (squadService.squadName ?? 'My Squad').replaceAll(RegExp(r',\s*s\b'), "'s");
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Squad Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Squad Name',
            hintText: 'e.g. Bagbazar Pandal Crawlers',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.chipMuted,
            ),
            onPressed: () {
              final newName = controller.text.trim();
              if (newName.isNotEmpty) {
                squadService.updateSquadName(newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editMeetupPoint(BuildContext context, SquadService squadService) {
    final controller = TextEditingController(text: squadService.meetupPointName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Designated Meet-up Point'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Landmark / Gate',
            hintText: 'e.g. Under Gariahat Flyover clock',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.chipMuted,
            ),
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                squadService.setMeetupPoint(controller.text.trim());
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Meet-up point updated to ${squadService.meetupPointName}')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _configureAlertDistance(BuildContext context, SquadService squadService) {
    final current = squadService.separationThresholdMeters;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Separation Alert Distance'),
        children: [100, 250, 500, 1000].map((meters) {
          final isSelected = current == meters;
          return ListTile(
            leading: Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppColors.chipMuted : null,
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
              squadService.setSeparationThreshold(meters);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Separation alert threshold set to $meters m')),
              );
            },
          );
        }).toList(),
      ),
    );
  }

  Future<void> _linkGoogleAccount(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final res = await AuthService.instance.upgradeGuestToGoogle();
    if (res.isSuccess) {
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('🎉 Account upgraded to Google! Your squad is preserved.'),
          backgroundColor: AppColors.semanticLive,
        ),
      );
    } else if (!res.isCancelled) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(res.errorMessage ?? 'Failed to upgrade account'),
          backgroundColor: AppColors.semanticAlert,
        ),
      );
    }
  }

  Future<void> _confirmLeaveSquad(BuildContext context, SquadService squadService) async {
    final rawName = squadService.squadName ?? 'Squad';
    final cleanName = rawName.replaceAll(RegExp(r',\s*s\b'), "'s");
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Squad?'),
        content: Text('Are you sure you want to leave "$cleanName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.semanticAlert),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await squadService.leaveSquad();
      if (context.mounted) {
        Navigator.pop(context); // return to main squad screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You left the squad.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final squadService = Provider.of<SquadService>(context);
    final authUser = context.watch<AuthService?>()?.currentUserModel ?? AuthService.instance.currentUserModel;
    final isGuest = authUser?.isGuest ?? false;

    final squadName = (squadService.squadName ?? 'My Squad').replaceAll(RegExp(r',\s*s\b'), "'s");
    final meetupPoint = squadService.meetupPointName;
    final alertDistance = formatDistance(squadService.separationThresholdMeters.toDouble());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Squad Settings'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Squad name'),
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
              subtitle: const Text('Keep your squad across devices'),
              trailing: const Icon(Icons.chevron_right, size: 18),
              onTap: () => _linkGoogleAccount(context),
            ),
          ],
          const Divider(height: 24),
          ListTile(
            leading: const Icon(Icons.exit_to_app, color: AppColors.semanticAlert),
            title: const Text(
              'Leave squad',
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
