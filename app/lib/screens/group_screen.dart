import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';
import '../models/chat_message.dart';
import '../models/squad_member.dart';
import '../models/squad_pandal_stop.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/squad_chat_service.dart';
import '../services/squad_service.dart';
import '../utils/haversine.dart';
import '../widgets/puja_icons.dart';
import '../widgets/squad_compass_overlay.dart';
import '../widgets/squad_pandal_picker_sheet.dart';
import '../widgets/user_profile_sheet.dart';
import '../widgets/vote_avatar_stack.dart';
import '../widgets/group_manager_sheet.dart';
import 'main_navigation_screen.dart';
import 'squad_chat_screen.dart';
import 'squad_settings_screen.dart';

/// Redesigned Screen for Durga Puja Hopping Groups.
/// Structure: Pinned Header (Code + Member Strip + Tabs) + 3 Tabs (Trail, People, Chat).
/// Adheres strictly to GROUP_AND_CHAT_UI_REDESIGN design principles:
/// - One screen, one job
/// - Each action appears once
/// - Show state, not instructions
/// - Battery shown only when low (< 20%)
/// - Contextual "Check route" chips between stops
class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  Timer? _freshnessTimer;

  @override
  void initState() {
    super.initState();
    _freshnessTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _freshnessTimer?.cancel();
    super.dispose();
  }

  void _shareInvite(BuildContext context, SquadService squadService) {
    if (!squadService.hasActiveSquad) return;
    final code = squadService.squadCode;
    final name = (squadService.squadName ?? 'My Group').replaceAll(RegExp(r',\s*s\b'), "'s");

    const webBaseUrl = 'https://kolkata-puja-2026.web.app';
    final deepLinkUrl = '$webBaseUrl/join?code=$code';

    SharePlus.instance.share(
      ShareParams(
        title: 'Join "$name" on Uma',
        text: 'Join my Durga Puja Hopping Group "$name" on Uma App!\n\n'
            '🔑 Group Code: $code\n'
            '📍 Meet-up Point: ${squadService.meetupPointName}\n\n'
            '🚀 Tap to open & auto-join:\n'
            '$deepLinkUrl\n\n'
            '(Or open Uma app → Hopping Group → Enter Code: $code)',
        subject: 'Join "$name" on Uma',
      ),
    );
  }

  void _createGroup(BuildContext context, SquadService squadService) {
    final nameController = TextEditingController();
    final meetupController = TextEditingController();
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Hopping Group'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Group Name',
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
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            onPressed: () async {
              final name = nameController.text.trim();
              final meetup = meetupController.text.trim();
              if (name.isNotEmpty) {
                Navigator.pop(ctx);
                await squadService.createSquad(
                  name,
                  meetup.isEmpty ? 'Kolkata Central' : meetup,
                );
                final code = squadService.squadCode;
                if (context.mounted) {
                  if (code != null && squadService.lastError == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: theme.colorScheme.primary,
                        content: Text('Created group! Invite code: $code'),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.semanticAlert,
                        content: Text(squadService.lastError ?? 'Failed to create group'),
                      ),
                    );
                  }
                }
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Hopping Group'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Enter Group Code',
            hintText: 'e.g. PUJAX4K9',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            onPressed: () async {
              final code = controller.text.trim().toUpperCase();
              if (code.isNotEmpty) {
                Navigator.pop(ctx);
                final success = await squadService.joinSquad(code);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: success ? theme.colorScheme.primary : AppColors.semanticAlert,
                      content: Text(
                        success
                            ? 'Joined group $code!'
                            : (squadService.lastError ?? 'Failed to join group $code'),
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

  void _handleMenu(BuildContext context, String value, SquadService squadService) {
    if (value == 'settings') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SquadSettingsScreen()),
      );
    } else if (value == 'leave') {
      _confirmLeaveSquad(context, squadService);
    }
  }

  void _confirmLeaveSquad(BuildContext context, SquadService squadService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Group?'),
        content: const Text('You will no longer share your live trail or receive alerts from this group.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.semanticAlert),
            onPressed: () async {
              Navigator.pop(ctx);
              final left = await squadService.leaveSquad();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(left ? 'Left group' :
                      (squadService.lastError ?? 'Could not leave group'))),
                );
              }
            },
            child: const Text('Leave'),
          ),
        ],
      ),
    );
  }

  void _openAssistantWithGroupContext(BuildContext context, SquadService squadService) {
    HapticFeedback.selectionClick();
    DefaultTabController.maybeOf(context)?.animateTo(2);
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
          action: SnackBarAction(label: 'OK', onPressed: () {}),
        ),
      );
    }
  }

  void _showCompanionDetails(BuildContext context, SquadMember m) {
    final theme = Theme.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 36,
                backgroundColor: m.avatarColor.withValues(alpha: 0.3),
                backgroundImage: m.photoUrl != null && m.photoUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(m.photoUrl!)
                    : null,
                child: (m.photoUrl == null || m.photoUrl!.isEmpty)
                    ? Text(m.initials, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: m.avatarColor))
                    : null,
              ),
              const SizedBox(height: 14),
              Text(m.name, style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(m.status, style: const TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 20),
              // Compass to member
              if (!m.isUser && m.shareLocation && m.isOnline)
                _buildCompassToMember(context, m),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Chip(
                    avatar: Icon(
                      m.batteryLevel < 20 ? Icons.battery_alert : Icons.battery_std,
                      size: 16,
                      color: m.batteryLevel < 20 ? AppColors.semanticAlert : null,
                    ),
                    label: Text('Battery: ${m.batteryLevel}%'),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    avatar: Icon(Icons.circle, size: 10, color: m.isOnline ? AppColors.semanticLive : Colors.grey),
                    label: Text(m.isOnline ? 'Online' : 'Offline'),
                  ),
                ],
              ),
              if (m.hasPhone) ...[
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.semanticLive,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: const Icon(Icons.phone),
                    label: Text('Call ${m.name}'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _callCompanion(context, m);
                    },
                  ),
                ),
              ],
              if (!m.isUser && m.shareLocation && m.isOnline) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                      foregroundColor: theme.colorScheme.primary,
                    ),
                    icon: const Icon(Icons.explore_rounded),
                    label: const Text('Open AR Compass'),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _openARCompass(context, m);
                    },
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompassToMember(BuildContext context, SquadMember m) {
    final theme = Theme.of(context);
    final userPos = LocationService.instance.currentPositionSync;
    if (userPos == null) return const SizedBox.shrink();
    
    final dist = haversineMeters(
      userPos.latitude, userPos.longitude,
      m.latitude, m.longitude,
    );
    final bearing = Geolocator.bearingBetween(
      userPos.latitude, userPos.longitude,
      m.latitude, m.longitude,
    );
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Transform.rotate(
                angle: (bearing - (LocationService.instance.currentHeading ?? 0)) * 3.14159 / 180,
                child: Icon(
                  Icons.navigation_rounded,
                  size: 32,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${formatDistance(dist)} away',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${bearing.round()}° from North',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Point phone toward ${m.name} — arrow shows direction',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _openARCompass(BuildContext context, SquadMember m) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.7,
        maxChildSize: 1.0,
        expand: false,
        builder: (context, scrollController) => Scaffold(
          backgroundColor: Colors.transparent,
          body: Stack(
            children: [
              // Full-screen AR compass
              SquadCompassOverlay(
                squadMembers: Provider.of<SquadService>(context, listen: false).members,
                onMemberTap: (member) {
                  Navigator.pop(context);
                  _showCompanionDetails(context, member);
                },
              ),
              // Close button
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: CircleAvatar(
                      backgroundColor: Colors.black.withValues(alpha: 0.6),
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPowerProfileDescription(PowerProfile profile) {
    switch (profile) {
      case PowerProfile.normal:
        return 'High accuracy, updates after roughly 2 m of movement';
      case PowerProfile.pandalHopping:
        return 'High accuracy, updates after roughly 10 m of movement';
      case PowerProfile.emergency:
        return 'Updates after roughly 50 m of movement';
    }
  }

  String _getPowerProfileShortName(PowerProfile profile) {
    switch (profile) {
      case PowerProfile.normal:
        return 'Normal';
      case PowerProfile.pandalHopping:
        return 'Pandal Hopping';
      case PowerProfile.emergency:
        return 'Emergency';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final squadService = Provider.of<SquadService>(context);

    if (!squadService.hasActiveSquad) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Hopping Group'),
          actions: [
            _groupManagerButton(context, squadService),
            IconButton(
              icon: const Icon(Icons.smart_toy_outlined),
              tooltip: 'Route assistant',
              onPressed: () {
                HapticFeedback.selectionClick();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Join or create a hopping squad to chat with Puja Bot!'),
                  ),
                );
              },
            ),
          ],
        ),
        body: _buildNoGroupView(context, theme, squadService),
      );
    }

    final rawName = squadService.squadName ?? 'Hopping Group';
    final squadName = rawName.replaceAll(RegExp(r',\s*s\b'), "'s");

    return DefaultTabController(
      key: ValueKey(squadService.squadId),
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            squadName,
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          actions: [
            _groupManagerButton(context, squadService),
            Builder(
              builder: (innerCtx) => IconButton(
                tooltip: 'Route assistant',
                icon: const Icon(Icons.smart_toy_outlined),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  _openAssistantWithGroupContext(innerCtx, squadService);
                },
              ),
            ),
            PopupMenuButton<String>(
              tooltip: 'More options',
              onSelected: (val) => _handleMenu(context, val, squadService),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'settings', child: Text('Group settings')),
                PopupMenuItem(value: 'leave', child: Text('Leave group')),
              ],
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(132),
            child: Column(
              children: [
                _buildGroupCodeBar(context, squadService, isDark),
                _buildMemberStrip(context, squadService, isDark),
                TabBar(
                  indicatorColor: AppColors.accentGold,
                  labelColor: AppColors.accentGold,
                  unselectedLabelColor: isDark ? Colors.white60 : Colors.black54,
                  indicatorWeight: 2.5,
                  tabs: [
                    const Tab(text: 'Trail'),
                    const Tab(text: 'People'),
                    Tab(child: _buildChatTabLabel(context, squadService)),
                  ],
                ),
              ],
            ),
          ),
        ),
        body: Column(
          children: [
            if (squadService.lastError != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: AppColors.semanticAlert.withValues(alpha: 0.12),
                child: Text(squadService.lastError!,
                    style: const TextStyle(fontSize: 12, color: AppColors.semanticAlert)),
              ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildTrailTab(context, theme, isDark, squadService),
                  _buildPeopleTab(context, theme, isDark, squadService),
                  SquadChatScreen(
                    key: ValueKey('chat_${squadService.squadId}'),
                    squadId: squadService.squadId ?? '',
                    squadName: squadName,
                    embedded: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- PINNED HEADER BARS ---

  Widget _groupManagerButton(BuildContext context, SquadService service) => IconButton(
    tooltip: 'My groups', icon: const Icon(Icons.groups_outlined),
    onPressed: () => showModalBottomSheet(
      context: context, isScrollControlled: true, useSafeArea: true,
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.85),
      builder: (_) => ChangeNotifierProvider<SquadService>.value(
        value: service,
        child: GroupManagerSheet(
          onCreate: () => _createGroup(context, service),
          onJoin: () => _joinGroup(context, service),
        ),
      ),
    ),
  );

  Widget _buildGroupCodeBar(BuildContext context, SquadService squadService, bool isDark) {
    final code = squadService.squadCode ?? '';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Text(
            'Code',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            code,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.accentGold : const Color(0xFF5A1E1E),
                ),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Copy code',
            icon: const Icon(Icons.copy_rounded, size: 18),
            visualDensity: VisualDensity.compact,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Group code copied to clipboard')),
              );
            },
          ),
          FilledButton.tonalIcon(
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              visualDensity: VisualDensity.compact,
            ),
            icon: const Icon(Icons.share, size: 16),
            label: const Text('Share', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            onPressed: () => _shareInvite(context, squadService),
          ),
        ],
      ),
    );
  }

  Widget _buildMemberStrip(BuildContext context, SquadService squadService, bool isDark) {
    final members = squadService.members;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Row(
        children: [
          SizedBox(
            height: 28,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...members.take(4).map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 5),
                    child: CircleAvatar(
                      radius: 13,
                      backgroundColor: m.avatarColor.withValues(alpha: 0.3),
                      backgroundImage: m.photoUrl != null && m.photoUrl!.isNotEmpty
                          ? CachedNetworkImageProvider(m.photoUrl!)
                          : null,
                      child: (m.photoUrl == null || m.photoUrl!.isEmpty)
                          ? Text(
                              m.initials,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: m.avatarColor,
                              ),
                            )
                          : null,
                    ),
                  );
                }),
                InkWell(
                  onTap: () => _shareInvite(context, squadService),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? Colors.white24 : Colors.black26,
                        width: 1.2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.add, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _shareInvite(context, squadService),
              child: Text(
                '${members.length} ${members.length == 1 ? "member" : "members"} · Invite friends',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 6),
          _buildSyncIndicator(context, squadService, isDark),
        ],
      ),
    );
  }

  Widget _buildSyncIndicator(BuildContext context, SquadService squadService, bool isDark) {
    final state = squadService.syncState;
    final (label, icon, color) = switch (state) {
      SquadSyncState.live => ('Live', Icons.cloud_done_rounded, AppColors.semanticLive),
      SquadSyncState.cached => ('Offline', Icons.cloud_off_rounded, AppColors.semanticAlert),
      SquadSyncState.connecting => ('Connecting', Icons.sync_rounded, AppColors.accentGold),
      SquadSyncState.unavailable => ('Demo', Icons.cloud_off_rounded, Colors.grey),
      SquadSyncState.error => ('Sync issue', Icons.sync_problem_rounded, AppColors.semanticAlert),
    };
    return Tooltip(
      message: switch (state) {
        SquadSyncState.live => 'Group updates confirmed by the server',
        SquadSyncState.cached => 'Showing saved group data; updates may not reach friends yet',
        SquadSyncState.connecting => 'Waiting for a server-confirmed group update',
        SquadSyncState.unavailable => 'Cloud sync is unavailable in this build',
        SquadSyncState.error => 'Could not receive group updates. Check your connection.',
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.18 : 0.10),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
        ]),
      ),
    );
  }

  Widget _buildChatTabLabel(BuildContext context, SquadService squadService) {
    final squadId = squadService.squadId ?? '';
    return StreamBuilder<List<ChatMessage>>(
      stream: squadId.isNotEmpty
          ? SquadChatService.instance.messagesStream(squadId)
          : null,
      builder: (context, snapshot) {
        final count = snapshot.hasData ? snapshot.data!.length : 0;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Chat'),
            if (count > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  // --- TAB 1: TRAIL TAB ---

  Widget _buildTrailTab(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    SquadService squadService,
  ) {
    if (squadService.isHoppingActive) {
      return _buildLiveTrail(context, theme, isDark, squadService);
    }

    final stops = squadService.chosenPandals;
    if (stops.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.alt_route_rounded, size: 44, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'No stops yet',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'Add pandals everyone wants to visit and vote on favorites.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white54 : Colors.black54),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add pandals'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  SquadPandalPickerSheet.show(context, squadService);
                },
              ),
            ],
          ),
        ),
      );
    }

    return _buildPlanningTrail(context, theme, isDark, squadService);
  }

  Widget _buildPlanningTrail(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    SquadService squadService,
  ) {
    final stops = squadService.chosenPandals;
    final currentUserId = AuthService.instance.currentUser?.uid ?? 'guest';
    SquadPandalStop.setCurrentUserId(currentUserId);

    return Column(
      children: [
        // Planning header: Trail count + Optimize order button
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Text(
                'Trail (${stops.length})',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
              const Spacer(),
              if (stops.length > 1)
                TextButton.icon(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    foregroundColor: AppColors.accentGold,
                  ),
                  icon: const Icon(Icons.auto_fix_high_rounded, size: 15),
                  label: const Text('Optimize order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  onPressed: squadService.isPlanMutationPending ? null : () async {
                    HapticFeedback.lightImpact();
                    final saved = await squadService.optimizeSquadRoute();
                    if (context.mounted && saved) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Suggested stop order saved for the group.')),
                      );
                    }
                  },
                ),
            ],
          ),
        ),

        // Reorderable list of stops
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            itemCount: stops.length,
            onReorderItem: (oldIndex, newIndex) {
              squadService.reorderSquadPandals(oldIndex, newIndex);
            },
            itemBuilder: (context, index) {
              final stop = stops[index];
              final hasVoted = stop.currentUserVoted;
              final voterMembers = stop.getVoterMembers(squadService.members);
              final isLast = index == stops.length - 1;

              return Column(
                key: ValueKey(stop.id),
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardSurface : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white12 : Colors.black12,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Drag handle + Stop number
                        ReorderableDragStartListener(
                          index: index,
                          child: Icon(Icons.drag_indicator_rounded, color: Colors.grey.shade500, size: 20),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // Pandal Name & Zone
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                stop.pandalName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${stop.zone} · Added by ${stop.suggestedByName}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Voter Avatars
                        if (voterMembers.isNotEmpty) ...[
                          VoteAvatarStack(
                            voters: voterMembers,
                            currentUserId: currentUserId,
                            maxVisible: 3,
                            avatarSize: 20,
                          ),
                          const SizedBox(width: 6),
                        ],

                        // Thumbs up vote button
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            squadService.toggleVotePandal(stop.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: hasVoted
                                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  hasVoted ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                                  size: 14,
                                  color: hasVoted ? theme.colorScheme.primary : (isDark ? Colors.white54 : Colors.black54),
                                ),
                                if (stop.voteCount > 0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '${stop.voteCount}',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                      color: hasVoted ? theme.colorScheme.primary : (isDark ? Colors.white70 : Colors.black87),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                        // Remove stop
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(minWidth: 26, minHeight: 26),
                          icon: Icon(Icons.close_rounded, size: 16, color: isDark ? Colors.white38 : Colors.black38),
                          tooltip: 'Remove stop',
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            squadService.removePandalFromSquad(stop.id);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Contextual "Check route" chip between stops
                  if (!isLast) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            height: 14,
                            width: 1.5,
                            color: isDark ? Colors.white24 : Colors.black12,
                          ),
                          const SizedBox(width: 8),
                          ActionChip(
                            avatar: const Icon(Icons.auto_awesome, size: 13, color: AppColors.accentGold),
                            label: Text(
                              'Ask bot about ${stops[index + 1].pandalName}',
                              style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w500),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            visualDensity: VisualDensity.compact,
                            side: BorderSide(color: isDark ? Colors.white12 : Colors.black12),
                            onPressed: () {
                              HapticFeedback.lightImpact();
                              DefaultTabController.maybeOf(context)?.animateTo(2);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),

        // Bottom Action Bar: [ + Add pandals ] & [ Start hopping ▶ ]
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black12)),
          ),
          child: Row(
            children: [
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  side: BorderSide(color: theme.colorScheme.primary, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add pandals'),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  SquadPandalPickerSheet.show(context, squadService);
                },
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text(
                    'Start hopping ▶',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  ),
                  onPressed: squadService.isPlanMutationPending ? null : () async {
                    HapticFeedback.lightImpact();
                    final started = await squadService.startSquadHopping();
                    if (context.mounted && started) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Live squad hopping started!')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLiveTrail(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    SquadService squadService,
  ) {
    final currentTarget = squadService.currentHoppingTarget;
    final activeIndex = squadService.activeHoppingStopIndex;
    final total = squadService.chosenPandals.length;
    final stops = squadService.chosenPandals;
    final members = squadService.members;
    final companionCount = squadService.companionMembers.length;

    // Separation text
    String separationSummary = 'Group members nearby';
    if (companionCount > 0) {
      final userMember = members.where((m) => m.isUser).firstOrNull;
      if (userMember != null) {
        SquadMember? furthest;
        double maxDist = 0;
        int nearbyCount = 1; // user is always nearby
        var unknownCount = 0;
        for (final comp in squadService.companionMembers) {
          if (comp.markerState == MemberMarkerState.old ||
              comp.markerState == MemberMarkerState.offline ||
              comp.markerState == MemberMarkerState.notSharing) {
            unknownCount++;
            continue;
          }
          final dist = haversineMeters(userMember.latitude, userMember.longitude, comp.latitude, comp.longitude);
          if (dist > maxDist) {
            maxDist = dist;
            furthest = comp;
          }
          if (dist < 200) {
            nearbyCount++;
          }
        }
        if (unknownCount > 0) {
          separationSummary = '$unknownCount member location${unknownCount == 1 ? '' : 's'} unavailable or old';
        } else if (maxDist > 150 && furthest != null) {
          separationSummary = 'People: $nearbyCount of ${members.length} nearby · ${furthest.name} is ${formatDistance(maxDist)} behind';
        } else {
          separationSummary = 'People: all ${members.length} nearby';
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // NEXT STOP BANNER (Leading Component)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1418) : const Color(0xFFFFF7F8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.7), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'NEXT STOP · ${activeIndex + 1} OF $total',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: (squadService.syncState == SquadSyncState.live
                              ? AppColors.semanticLive : AppColors.accentGold)
                          .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle,
                            color: squadService.syncState == SquadSyncState.live
                                ? AppColors.semanticLive : AppColors.accentGold,
                            size: 7),
                        const SizedBox(width: 4),
                        Text(
                          squadService.syncState == SquadSyncState.live
                              ? 'LIVE HOPPING' : 'HOPPING',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: squadService.syncState == SquadSyncState.live
                                ? AppColors.semanticLive : AppColors.accentGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                currentTarget?.pandalName ?? 'Hopping Completed! 🎉',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              if (currentTarget != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${currentTarget.zone} · ${currentTarget.area ?? 'Open route for directions'}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                ),
              ],
              const SizedBox(height: 14),
              // Navigation and actual arrival are the primary actions.
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accentGold,
                        foregroundColor: Colors.black87,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.map_rounded, size: 16),
                      label: const Text('Open route', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        MainNavigationScreen.switchTab(context, 0);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    ),
                    icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                    label: const Text('We are here', style: TextStyle(fontSize: 12.5)),
                    onPressed: squadService.isPlanMutationPending ? null : () async {
                      HapticFeedback.selectionClick();
                      await squadService.advanceToNextPandalStop();
                    },
                  ),
                ],
              ),
              Row(children: [
                TextButton.icon(
                  icon: const Icon(Icons.skip_next_rounded, size: 16),
                  label: const Text('Skip stop'),
                  onPressed: squadService.isPlanMutationPending
                      ? null : () => squadService.skipCurrentPandalStop(),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.stop_circle_outlined, size: 16),
                  label: const Text('End hopping'),
                  onPressed: squadService.isPlanMutationPending
                      ? null : () => squadService.endSquadHopping(),
                ),
              ]),
            ],
          ),
        ),

        const SizedBox(height: 12),
        // Separation Text
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.group_outlined, size: 16, color: AppColors.accentGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  separationSummary,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        Text(
          'Remaining Trail',
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),

        // Remaining stops
        ...stops.asMap().entries.map((entry) {
          final idx = entry.key;
          final stop = entry.value;
          final isCurrent = idx == activeIndex;
          final isPast = stop.isVisited || idx < activeIndex;

          return Container(
            margin: const EdgeInsets.symmetric(vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isCurrent
                  ? AppColors.accentGold.withValues(alpha: 0.1)
                  : (isDark ? AppColors.cardSurface : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isCurrent
                    ? AppColors.accentGold
                    : (isDark ? Colors.white12 : Colors.black12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isPast
                        ? const Color(0xFF00C853)
                        : (isCurrent ? AppColors.accentGold : Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: isPast
                        ? const Icon(Icons.check_rounded, color: Colors.white, size: 14)
                        : Text(
                            '${idx + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isCurrent ? Colors.black87 : Colors.white,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stop.pandalName,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                          decoration: isPast ? TextDecoration.lineThrough : null,
                          color: isPast ? Colors.grey : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                      Text(
                        stop.zone,
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                      ),
                    ],
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'HERE NEXT',
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w900, color: Colors.black87),
                    ),
                  ),
              ],
            ),
          );
        }),
      ],
    );
  }

  // --- TAB 2: PEOPLE TAB ---

  Widget _buildPeopleTab(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    SquadService squadService,
  ) {
    final members = squadService.members;
    final userMember = members.where((m) => m.isUser).firstOrNull;
    final alert = squadService.activeSeparationAlert;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Live GPS Sharing Toggle + Pandal Hopping Mode
        Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardSurface : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
              ),
              child: Row(
                children: [
                  Icon(
                    squadService.isSharingLocation ? Icons.location_on : Icons.location_off,
                    color: squadService.isSharingLocation ? AppColors.semanticLive : Colors.grey,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      squadService.isSharingLocation
                          ? 'Sharing live GPS with group'
                          : 'Live GPS paused',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Switch.adaptive(
                    value: squadService.isSharingLocation,
                    activeThumbColor: AppColors.semanticLive,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      squadService.toggleLocationSharing(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (squadService.isSharingLocation && !squadService.isLocationTracking) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.semanticAlert.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(children: [
                  const Icon(Icons.location_disabled_rounded, color: AppColors.semanticAlert, size: 18),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('GPS is not updating. Friends may see an old location.',
                      style: TextStyle(fontSize: 11.5))),
                  TextButton(onPressed: squadService.retryLocationTracking, child: const Text('Retry')),
                ]),
              ),
              const SizedBox(height: 8),
            ],
            // Pandal Hopping Mode (Battery Saver)
            Consumer<LocationService>(
              builder: (context, locService, _) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardSurface : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.battery_saver_rounded,
                      color: locService.powerProfile == PowerProfile.pandalHopping
                          ? AppColors.accentGold
                          : Colors.grey,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pandal Hopping Mode',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          Text(
                            _getPowerProfileDescription(locService.powerProfile),
                            style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<PowerProfile>(
                      initialValue: locService.powerProfile,
                      onSelected: (profile) async {
                        HapticFeedback.selectionClick();
                        await locService.setPowerProfile(profile);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: PowerProfile.normal,
                          child: Row(children: [Icon(Icons.brightness_high, size: 18), SizedBox(width: 8), Text('Normal (Full GPS)')]),
                        ),
                        const PopupMenuItem(
                          value: PowerProfile.pandalHopping,
                          child: Row(children: [Icon(Icons.battery_saver, size: 18, color: Colors.amber), SizedBox(width: 8), Text('Pandal Hopping (Battery Saver)')]),
                        ),
                        const PopupMenuItem(
                          value: PowerProfile.emergency,
                          child: Row(children: [Icon(Icons.battery_unknown, size: 18, color: Colors.red), SizedBox(width: 8), Text('Emergency (Minimal GPS)')]),
                        ),
                      ],
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: locService.powerProfile == PowerProfile.pandalHopping
                              ? AppColors.accentGold.withValues(alpha: 0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: locService.powerProfile == PowerProfile.pandalHopping
                                ? AppColors.accentGold
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getPowerProfileShortName(locService.powerProfile),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: locService.powerProfile == PowerProfile.pandalHopping
                                    ? Colors.black87
                                    : (isDark ? Colors.white70 : Colors.black54),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.expand_more, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        // Separation Alert Banner (only when triggered)
        if (alert != null) ...[
          const SizedBox(height: 12),
          Card(
            color: AppColors.semanticAlert.withValues(alpha: 0.15),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.semanticAlert),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: AppColors.semanticAlert, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${alert.memberName} is ${formatDistance(alert.distanceMeters.toDouble())} away',
                      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      squadService.focusMember(alert.memberId);
                      MainNavigationScreen.switchTab(context, 0);
                    },
                    child: const Text('Locate'),
                  ),
                ],
              ),
            ),
          ),
        ],

        const SizedBox(height: 16),

        // If just you
        if (members.length <= 1)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardSurface : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
            ),
            child: Column(
              children: [
                Text(
                  'Just you so far.',
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(
                  'Invite friends to share live locations and stick together in Kolkata crowds.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                ),
                const SizedBox(height: 14),
                FilledButton.tonalIcon(
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Invite friends'),
                  onPressed: () => _shareInvite(context, squadService),
                ),
              ],
            ),
          )
        else ...[
          Text(
            'Members (${members.length})',
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, fontSize: 13.5),
          ),
          const SizedBox(height: 8),
          ...members.map((m) => _buildMemberTile(context, m, userMember, isDark, squadService)),
        ],
      ],
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    SquadMember m,
    SquadMember? userMember,
    bool isDark,
    SquadService squadService,
  ) {
    String? subtitleText;
    if (!m.isUser) {
      final hasFreshLocation = m.markerState == MemberMarkerState.fresh ||
          m.markerState == MemberMarkerState.stale;
      if (userMember != null && hasFreshLocation) {
        final dist = haversineMeters(userMember.latitude, userMember.longitude, m.latitude, m.longitude);
        subtitleText = '${formatDistance(dist)} away · ${m.lastSeenText}';
      } else {
        subtitleText = switch (m.markerState) {
          MemberMarkerState.notSharing => 'Location sharing paused',
          MemberMarkerState.offline => 'Offline · last seen ${m.lastSeenText}',
          _ => 'Last location ${m.lastSeenText} · may be outdated',
        };
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardSurface : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: m.avatarColor.withValues(alpha: 0.3),
              backgroundImage: m.photoUrl != null && m.photoUrl!.isNotEmpty
                  ? CachedNetworkImageProvider(m.photoUrl!)
                  : null,
              child: (m.photoUrl == null || m.photoUrl!.isEmpty)
                  ? Text(m.initials, style: TextStyle(fontWeight: FontWeight.bold, color: m.avatarColor))
                  : null,
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: switch (m.markerState) {
                    MemberMarkerState.fresh => AppColors.semanticLive,
                    MemberMarkerState.stale => AppColors.accentGold,
                    _ => Colors.grey,
                  },
                  shape: BoxShape.circle,
                  border: Border.all(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, width: 1.5),
                ),
              ),
            ),
          ],
        ),
        title: Text(
          m.isUser ? '${m.name} (You)' : m.name,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
        ),
        subtitle: subtitleText != null
            ? Text(
                subtitleText,
                style: TextStyle(fontSize: 11.5, color: isDark ? Colors.white54 : Colors.black54),
              )
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Compass button (shows direction to member)
            if (!m.isUser &&
                (m.markerState == MemberMarkerState.fresh || m.markerState == MemberMarkerState.stale))
              SquadCompassButton(
                squadMembers: squadService.members,
                onPressed: () => _openARCompass(context, m),
                showDistance: true,
              ),
            // SHOW BATTERY ONLY WHEN BELOW 20%
            if (m.batteryLevel < 20) ...[
              const Icon(Icons.battery_alert, size: 16, color: AppColors.semanticAlert),
              const SizedBox(width: 4),
              Text(
                '${m.batteryLevel}%',
                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.semanticAlert),
              ),
              const SizedBox(width: 8),
            ],
            if (m.hasPhone && !m.isUser)
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                icon: const Icon(Icons.phone_rounded, color: AppColors.semanticLive, size: 18),
                tooltip: 'Call',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _callCompanion(context, m);
                },
              ),
            const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
          ],
        ),
        onTap: () {
          HapticFeedback.selectionClick();
          if (m.isUser) {
            UserProfileSheet.show(context);
          } else {
            _showCompanionDetails(context, m);
          }
        },
      ),
    ),
  );
}

  // --- NO GROUP VIEW ---

  Widget _buildNoGroupView(BuildContext context, ThemeData theme, SquadService squadService) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (squadService.lastError != null) ...[
          Card(
            color: AppColors.semanticAlert.withValues(alpha: 0.12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(squadService.lastError!,
                  style: const TextStyle(color: AppColors.semanticAlert)),
            ),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: PujaIcon.dhaki(size: 64, color: theme.colorScheme.primary),
              ),
              const SizedBox(height: 24),
              Text(
                'Hop Together, Never Get Lost',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Form a hopping group with friends and family. Coordinate stops, track live locations on the map, and get alerts in dense crowds.',
                style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'Create New Group',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _createGroup(context, squadService),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                    foregroundColor: theme.colorScheme.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(
                    'Join with Group Code',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  onPressed: () => _joinGroup(context, squadService),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
