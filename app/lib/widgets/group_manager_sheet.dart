import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/squad_service.dart';

class GroupManagerSheet extends StatelessWidget {
  const GroupManagerSheet({
    super.key,
    required this.onCreate,
    required this.onJoin,
  });
  final VoidCallback onCreate;
  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    final service = context.watch<SquadService>();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'My groups',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Location updates are shared only with the selected group.',
            ),
            const SizedBox(height: 16),
            if (service.isGroupOperationPending)
              const LinearProgressIndicator(),
            if (service.groups.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('Create or join your first group.'),
              ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: service.groups.map((group) {
                  final active = group.id == service.squadId;
                  return ListTile(
                    key: ValueKey('group_${group.id}'),
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      active ? Icons.check_circle : Icons.groups_outlined,
                    ),
                    title: Text(
                      group.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${group.code} · ${group.isHost ? "Host" : "Member"}${active ? " · Selected" : ""}',
                    ),
                    onTap: service.isGroupOperationPending
                        ? null
                        : () async {
                            final success = await service.switchGroup(group.id);
                            if (context.mounted && success) {
                              Navigator.pop(context);
                            }
                          },
                    trailing: IconButton(
                      tooltip: 'Leave ${group.name}',
                      icon: const Icon(Icons.logout),
                      onPressed: service.isGroupOperationPending
                          ? null
                          : () async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Leave ${group.name}?'),
                                  content: const Text(
                                    'You will need an invite code to join again.',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx, false),
                                      child: const Text('Cancel'),
                                    ),
                                    FilledButton(
                                      onPressed: () => Navigator.pop(ctx, true),
                                      child: const Text('Leave'),
                                    ),
                                  ],
                                ),
                              );
                              if (confirmed == true) {
                                await service.leaveGroup(group.id);
                              }
                            },
                    ),
                  );
                }).toList(),
              ),
            ),
            if (service.lastError != null)
              Text(
                service.lastError!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: service.isGroupOperationPending
                      ? null
                      : () {
                          Navigator.pop(context);
                          onCreate();
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('Create group'),
                ),
                OutlinedButton.icon(
                  onPressed: service.isGroupOperationPending
                      ? null
                      : () {
                          Navigator.pop(context);
                          onJoin();
                        },
                  icon: const Icon(Icons.group_add_outlined),
                  label: const Text('Join group'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
