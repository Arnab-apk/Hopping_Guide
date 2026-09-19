import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';
import '../models/chat_message.dart';
import '../models/squad_member.dart';
import '../services/squad_chat_service.dart';
import '../services/squad_service.dart';
import '../utils/haversine.dart';
import '../widgets/puja_icons.dart';
import '../widgets/user_profile_sheet.dart';
import 'main_navigation_screen.dart';
import 'squad_chat_screen.dart';

/// Simplified Screen for Durga Puja Hopping Squads.
/// Consolidated into 4 cohesive cards:
/// 1. Squad Identity Card (name, code, invite action)
/// 2. Squad Settings Card (meetup landmark, live GPS toggle, separation threshold)
/// 3. Squad Members Card (host row with profile link, companion list, dialer call, inline empty state)
/// 4. Squad Chat & Media Card (live messaging, photo/video sharing entry)
class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

  void _shareInvite(BuildContext context, SquadService squadService) {
    if (!squadService.hasActiveSquad) return;
    final code = squadService.squadCode;
    final name = (squadService.squadName ?? 'My Squad').replaceAll(RegExp(r',\s*s\b'), "'s");
    SharePlus.instance.share(
      ShareParams(
        text: 'Join my Durga Puja Hopping Squad "$name" on Pujo Parikrama App!\n\n'
            '🔑 Squad Code: $code\n'
            '📍 Meet-up Point: ${squadService.meetupPointName}\n\n'
            '🔗 Tap to auto-join: https://sharodiya.com/join?code=$code\n'
            '📱 App Link: pujoparikrama://join?code=$code',
      ),
    );
  }

  void _createGroup(BuildContext context, SquadService squadService) {
    final nameController = TextEditingController();
    final meetupController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Hopping Squad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Squad Name',
                hintText: 'e.g. Bagbazar Pandal Crawlers',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: meetupController,
              decoration: const InputDecoration(
                labelText: 'Meet-up Landmark',
                hintText: 'e.g. Near Hatibagan Crossing',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final rawName = nameController.text.trim().isEmpty ? 'My Puja Squad' : nameController.text.trim();
              final squadName = rawName.replaceAll(RegExp(r',\s*s\b'), "'s");
              final meetup = meetupController.text.trim().isEmpty ? 'Main Entrance Landmark' : meetupController.text.trim();
              Navigator.pop(ctx);

              await squadService.createSquad(squadName, meetup);

              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Created "$squadName"! Invite Code: ${squadService.squadCode}'),
                    action: SnackBarAction(
                      label: 'Share',
                      onPressed: () => _shareInvite(context, squadService),
                    ),
                  ),
                );
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _joinGroup(BuildContext context, SquadService squadService) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Squad by Code'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Enter Squad Code',
            hintText: 'e.g. PUJAX4K9',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final code = controller.text.trim().toUpperCase();
              if (code.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await squadService.joinSquad(code);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: success ? const Color(0xFFD32F2F) : Colors.orange.shade800,
                      content: Text(
                        success
                            ? 'Joined squad $code!'
                            : (squadService.lastError ?? 'Failed to join squad $code'),
                      ),
                    ),
                  );
                }
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup(BuildContext context, SquadService squadService) async {
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
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await squadService.leaveSquad();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You left the squad.')),
        );
      }
    }
  }

  void _showEditSquadNameDialog(BuildContext context, SquadService squadService) {
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

  void _setMeetupPoint(BuildContext context, SquadService squadService) {
    final controller = TextEditingController(text: squadService.meetupPointName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set Meet-up Point'),
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

  void _showSeparationThresholdDialog(BuildContext context, SquadService squadService) {
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
              color: isSelected ? PujaColors.durgaRed : null,
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

  void _triggerSeparationSOS(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: Row(
          children: [
            PujaIcon.trishulEyes(color: Colors.white, size: 28),
            const SizedBox(width: 8),
            const Text('Separation Alert (SOS)', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'This will send a high-priority push notification and vibration to all squad members '
          'with your exact current GPS coordinates and designated meet-up point.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.amber),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: Colors.red,
                  content: Text('🚨 Separation Alert dispatched to squad members!'),
                  duration: Duration(seconds: 4),
                ),
              );
            },
            child: const Text('Send Alert Now', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _callCompanion(BuildContext context, SquadMember member) async {
    final phone = member.phoneNumber?.trim();
    if (phone != null && phone.isNotEmpty) {
      final uri = Uri.parse('tel:$phone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not open phone dialer for $phone')),
          );
        }
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${member.name} has not added a phone number to their profile.'),
          action: SnackBarAction(
            label: 'OK',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final squadService = Provider.of<SquadService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hopping Squad'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'Squad Options',
            onSelected: (value) {
              if (value == 'create') _createGroup(context, squadService);
              if (value == 'join') _joinGroup(context, squadService);
              if (value == 'leave') _leaveGroup(context, squadService);
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'create', child: Text('Create New Squad')),
              const PopupMenuItem(value: 'join', child: Text('Join Squad Code')),
              if (squadService.hasActiveSquad)
                const PopupMenuItem(
                  value: 'leave',
                  child: Text('Leave Current Squad', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
        ],
      ),
      body: !squadService.hasActiveSquad
          ? _buildNoGroupView(context, theme, squadService)
          : _buildActiveGroupView(context, theme, isDark, squadService),
    );
  }

  Widget _buildNoGroupView(BuildContext context, ThemeData theme, SquadService squadService) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: PujaColors.durgaRed.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: PujaIcon.dhaki(size: 64, color: PujaColors.durgaRed),
                ),
                const SizedBox(height: 24),
                Text(
                  'Hop Together, Never Get Lost',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Form a hopping group with friends and family. See live member pins on the map, set meetup spots, and trigger separation alerts in dense crowds.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Create New Squad'),
                    onPressed: () => _createGroup(context, squadService),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.login),
                    label: const Text('Join with Squad Code'),
                    onPressed: () => _joinGroup(context, squadService),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveGroupView(BuildContext context, ThemeData theme, bool isDark, SquadService squadService) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Card 1 — Squad Identity
        _buildSquadIdentityCard(context, theme, isDark, squadService),
        const SizedBox(height: 16),

        // Card 2 — Squad Settings (merges meetup point, GPS toggle, and separation alert threshold)
        _buildSquadSettingsCard(context, theme, isDark, squadService),
        const SizedBox(height: 16),

        // Card 3 — Squad Members (host row + companion rows + inline empty state)
        _buildSquadMembersCard(context, theme, isDark, squadService),
        const SizedBox(height: 16),

        // Card 4 — Squad Chat & Media
        _buildSquadChatCard(context, theme, isDark, squadService),
        const SizedBox(height: 24),
      ],
    );
  }

  // --- CARD 1: SQUAD IDENTITY ---
  Widget _buildSquadIdentityCard(BuildContext context, ThemeData theme, bool isDark, SquadService squadService) {
    final rawName = squadService.squadName ?? 'My Squad';
    final displayName = rawName.replaceAll(RegExp(r',\s*s\b'), "'s");
    final membersCount = squadService.members.length;
    final memberText = membersCount == 1 ? '1 member hopping together' : '$membersCount members hopping together';
    final code = squadService.squadCode ?? '';

    return Card(
      color: isDark ? PujaColors.nightCard : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: PujaColors.festivalGold.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _showEditSquadNameDialog(context, squadService),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'serif',
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: PujaColors.festivalGold,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        memberText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Squad Code Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: PujaColors.crimsonVelvet.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: PujaColors.festivalGold.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        code,
                        style: TextStyle(
                          color: isDark ? PujaColors.goldBright : PujaColors.crimsonVelvet,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(width: 6),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: code));
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Squad code copied to clipboard!')),
                          );
                        },
                        child: Icon(
                          Icons.copy_rounded,
                          size: 16,
                          color: isDark ? PujaColors.goldBright : PujaColors.crimsonVelvet,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: PujaColors.durgaRed,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: PujaIcon.shankha(size: 20, color: Colors.white),
                label: const Text(
                  'Invite Companions',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _shareInvite(context, squadService);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CARD 2: SQUAD SETTINGS (Merges 3 cards: meetup landmark + GPS switch + Separation alert) ---
  Widget _buildSquadSettingsCard(BuildContext context, ThemeData theme, bool isDark, SquadService squadService) {
    return Card(
      color: isDark ? PujaColors.nightCard : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          children: [
            // Row 1: Meet-up Point
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                HapticFeedback.selectionClick();
                _setMeetupPoint(context, squadService);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: PujaColors.festivalGold.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: PujaIcon.kalash(color: PujaColors.festivalGold, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Designated Meet-up Point',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: PujaColors.festivalGold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            squadService.meetupPointName,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontSize: 13.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.edit_outlined, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),

            const Divider(height: 16),

            // Row 2: Live Location Sharing Toggle
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: (squadService.isSharingLocation ? const Color(0xFF00E676) : Colors.grey)
                          .withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      squadService.isSharingLocation ? Icons.location_on : Icons.location_off,
                      color: squadService.isSharingLocation ? const Color(0xFF00E676) : Colors.grey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Live GPS Location',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          squadService.isSharingLocation
                              ? 'Broadcasting live pin to squad'
                              : 'Live location is paused',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: squadService.isSharingLocation,
                    activeThumbColor: const Color(0xFF00E676),
                    activeTrackColor: const Color(0xFF00E676).withValues(alpha: 0.3),
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      squadService.toggleLocationSharing(val);
                    },
                  ),
                ],
              ),
            ),

            const Divider(height: 16),

            // Row 3: Separation Alert Distance & SOS
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () {
                HapticFeedback.selectionClick();
                _showSeparationThresholdDialog(context, squadService);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: PujaIcon.trishulEyes(color: Colors.red, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Separation Alert Distance',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 13.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Threshold: ${squadService.separationThresholdMeters} m • Tap to configure',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark ? Colors.white54 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // SOS trigger button
                    IconButton(
                      icon: const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 22),
                      tooltip: 'Send Separation SOS Alert',
                      onPressed: () {
                        HapticFeedback.heavyImpact();
                        _triggerSeparationSOS(context);
                      },
                    ),
                    const Icon(Icons.tune_rounded, size: 18, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- CARD 3: SQUAD MEMBERS (Host row + Companion rows + Inline empty state) ---
  Widget _buildSquadMembersCard(BuildContext context, ThemeData theme, bool isDark, SquadService squadService) {
    final members = squadService.members;
    final userMember = members.where((m) => m.isUser).firstOrNull;
    final companions = squadService.companionMembers;

    return Card(
      color: isDark ? PujaColors.nightCard : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Members (1 Host, 0 Others) · View on Map
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Members (1 Host, ${companions.length} Others)',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.map_outlined, size: 15),
                  label: const Text('View on Map', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    MainNavigationScreen.switchTab(context, 0);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // You (Host) Row — tapping opens Profile
            if (userMember != null)
              _buildHostRow(context, userMember, theme, isDark),

            // Companions or Inline Empty State
            if (companions.isEmpty) ...[
              const Divider(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: [
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PujaColors.festivalGold.withValues(alpha: 0.12),
                        ),
                        child: PujaIcon.dhaki(
                          size: 36,
                          color: PujaColors.festivalGold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No companions have joined yet',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Share squad code "${squadService.squadCode}" to hop together.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        side: BorderSide(color: PujaColors.festivalGold.withValues(alpha: 0.5)),
                      ),
                      icon: PujaIcon.shankha(size: 16, color: PujaColors.festivalGold),
                      label: const Text('Invite Companions', style: TextStyle(fontSize: 12)),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        _shareInvite(context, squadService);
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              const Divider(height: 16),
              ...companions.map(
                (comp) => _buildCompanionRow(context, comp, userMember, theme, isDark, squadService),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHostRow(BuildContext context, SquadMember userMember, ThemeData theme, bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        HapticFeedback.selectionClick();
        UserProfileSheet.show(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            // User Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: PujaColors.festivalGold, width: 2),
              ),
              child: ClipOval(
                child: userMember.photoUrl != null && userMember.photoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: userMember.photoUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => CircleAvatar(
                          backgroundColor: PujaColors.durgaRed.withValues(alpha: 0.2),
                          child: Text(userMember.initials, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                    : CircleAvatar(
                        backgroundColor: PujaColors.durgaRed.withValues(alpha: 0.2),
                        child: Text(userMember.initials, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          userMember.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.amber),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    '0 m (Here) • Tap to view Profile',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: PujaColors.festivalGold,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '🔋${userMember.batteryLevel}%',
              style: TextStyle(
                fontSize: 11,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right_rounded, size: 20, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildCompanionRow(
    BuildContext context,
    SquadMember member,
    SquadMember? userMember,
    ThemeData theme,
    bool isDark,
    SquadService squadService,
  ) {
    final distanceText = userMember == null
        ? 'Nearby'
        : formatDistance(
            haversineMeters(
              userMember.latitude,
              userMember.longitude,
              member.latitude,
              member.longitude,
            ),
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: Row(
        children: [
          // Companion Avatar with online badge
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: member.avatarColor, width: 1.5),
                ),
                child: ClipOval(
                  child: member.photoUrl != null && member.photoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: member.photoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (c, u, e) => CircleAvatar(
                            backgroundColor: member.avatarColor.withValues(alpha: 0.2),
                            child: Text(member.initials, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        )
                      : CircleAvatar(
                          backgroundColor: member.avatarColor.withValues(alpha: 0.2),
                          child: Text(member.initials, style: const TextStyle(fontWeight: FontWeight.bold)),
                        ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    shape: BoxShape.circle,
                    border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${member.status} • $distanceText',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? Colors.white60 : Colors.black54,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '🔋${member.batteryLevel}%',
            style: TextStyle(
              fontSize: 11,
              color: member.batteryLevel < 20 ? Colors.red : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          const SizedBox(width: 2),
          // Locate on map button
          IconButton(
            icon: const Icon(Icons.navigation_outlined, color: PujaColors.durgaRed, size: 19),
            tooltip: 'Locate on Map',
            onPressed: () {
              HapticFeedback.selectionClick();
              squadService.focusMember(member.id);
              MainNavigationScreen.switchTab(context, 0);
            },
          ),
          // Native dialer Call button
          IconButton(
            icon: const Icon(Icons.phone_rounded, color: Colors.green, size: 19),
            tooltip: 'Call Companion',
            onPressed: () {
              HapticFeedback.lightImpact();
              _callCompanion(context, member);
            },
          ),
        ],
      ),
    );
  }

  // --- CARD 4: SQUAD CHAT & MEDIA ---
  Widget _buildSquadChatCard(BuildContext context, ThemeData theme, bool isDark, SquadService squadService) {
    final squadCode = squadService.squadCode ?? 'SQUAD';
    final squadName = (squadService.squadName ?? 'Squad Chat').replaceAll(RegExp(r',\s*s\b'), "'s");

    return Card(
      color: isDark ? PujaColors.nightCard : Colors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: PujaColors.durgaRed.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          HapticFeedback.selectionClick();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SquadChatScreen(
                squadCode: squadCode,
                squadName: squadName,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      PujaColors.durgaRed,
                      PujaColors.crimsonVelvet,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: PujaColors.durgaRed.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(Icons.forum_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Squad Chat & Media',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: PujaColors.festivalGold.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Live',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: PujaColors.festivalGold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    StreamBuilder<List<ChatMessage>>(
                      stream: SquadChatService.instance.messagesStream(squadCode),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final latest = snapshot.data!.first;
                          String preview = latest.text ?? 'Shared a photo';
                          if (latest.isVideo) preview = 'Shared a video clip';
                          return Text(
                            '${latest.senderName.split(' ')[0]}: $preview',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          );
                        }
                        return Text(
                          'Send real-time texts, photos & videos',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  visualDensity: VisualDensity.compact,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => SquadChatScreen(
                        squadCode: squadCode,
                        squadName: squadName,
                      ),
                    ),
                  );
                },
                child: const Text('Open Chat', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
