import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../config/theme.dart';
import '../models/squad_member.dart';
import '../services/auth_service.dart';
import '../services/squad_service.dart';
import '../utils/haversine.dart';
import '../utils/responsive.dart';
import '../widgets/google_logo.dart';
import '../widgets/user_profile_sheet.dart';
import 'main_navigation_screen.dart';

/// Screen for creating/joining hopping squads, viewing live member locations,
/// adjusting meetup points, and dispatching crowd separation alerts.
class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key});

  void _shareInvite(BuildContext context, SquadService squadService) {
    if (!squadService.hasActiveSquad) return;
    final code = squadService.squadCode;
    SharePlus.instance.share(
      ShareParams(
        text: 'Join my Durga Puja Hopping Squad "${squadService.squadName}" on Pujo Parikrama App!\n\n'
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
              final squadName = nameController.text.trim().isEmpty ? 'My Puja Squad' : nameController.text.trim();
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
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Squad?'),
        content: Text('Are you sure you want to leave "${squadService.squadName}"?'),
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

  void _triggerSeparationSOS(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.red.shade900,
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
            SizedBox(width: 8),
            Text('Separation Alert (SOS)', style: TextStyle(color: Colors.white)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final squadService = Provider.of<SquadService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hopping Squad (Groups)'),
        actions: [
          IconButton(
            tooltip: 'My Profile',
            icon: Consumer<AuthService>(
              builder: (ctx, auth, _) {
                final photo = auth.currentUserModel?.photoUrl;
                if (photo != null && photo.isNotEmpty) {
                  return Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: PujaColors.festivalGold, width: 1.5),
                    ),
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: photo,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => const Icon(Icons.account_circle, color: PujaColors.festivalGold),
                      ),
                    ),
                  );
                }
                return const Icon(Icons.account_circle_outlined);
              },
            ),
            onPressed: () => UserProfileSheet.show(context),
          ),
          IconButton(
            tooltip: 'Invite Squad',
            icon: const Icon(Icons.share_rounded),
            onPressed: squadService.hasActiveSquad ? () => _shareInvite(context, squadService) : null,
          ),
          PopupMenuButton<String>(
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
    final isDark = theme.brightness == Brightness.dark;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildProfileHeaderCard(context, theme, isDark),
        const SizedBox(height: 12),
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
                  child: const Icon(Icons.group_add_rounded, size: 64, color: PujaColors.durgaRed),
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
    final members = squadService.members;
    final userMember = members.where((m) => m.isUser).firstOrNull;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User Profile Header Card
        _buildProfileHeaderCard(context, theme, isDark),

        // Squad Code Banner
        Card(
          color: isDark ? PujaColors.nightCard : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            squadService.squadName ?? 'My Squad',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${members.length} members hopping together',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isDark ? Colors.white60 : Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: PujaColors.crimsonVelvet.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: PujaColors.festivalGold.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            squadService.squadCode ?? '',
                            style: TextStyle(
                              color: isDark ? PujaColors.goldBright : PujaColors.crimsonVelvet,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 6),
                          InkWell(
                            onTap: () {
                              Clipboard.setData(ClipboardData(text: squadService.squadCode ?? ''));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Code copied to clipboard!')),
                              );
                            },
                            child: Icon(
                              Icons.copy,
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
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    children: [
                      OutlinedButton.icon(
                        icon: Icon(Icons.share, size: context.dynamicIcon(18)),
                        label: Text('Invite Friends', style: TextStyle(fontSize: context.dynamicFont(13))),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _shareInvite(context, squadService);
                        },
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        icon: Icon(Icons.sos, color: Colors.red, size: context.dynamicIcon(18)),
                        label: Text('Separation Alert', style: TextStyle(color: Colors.red, fontSize: context.dynamicFont(13))),
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          _triggerSeparationSOS(context);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Designated Meet-up Point Card
        Card(
          color: isDark ? PujaColors.nightSurface : PujaColors.goldSoft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: PujaColors.festivalGold.withValues(alpha: 0.4),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PujaColors.festivalGold.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.meeting_room_rounded, color: PujaColors.festivalGold, size: context.dynamicIcon(22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Designated Meet-up Point',
                        style: TextStyle(fontSize: context.dynamicFont(12), fontWeight: FontWeight.bold, color: PujaColors.festivalGold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        squadService.meetupPointName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: context.dynamicFont(14),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit, size: context.dynamicIcon(20)),
                  tooltip: 'Change Meetup Point',
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    _setMeetupPoint(context, squadService);
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Live Location Sharing & Battery Optimization
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          squadService.isSharingLocation ? Icons.location_on : Icons.location_off,
                          color: squadService.isSharingLocation ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Share Live GPS Location',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Switch(
                      value: squadService.isSharingLocation,
                      onChanged: (val) => squadService.toggleLocationSharing(val),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  squadService.isSharingLocation
                      ? 'Squad members can see your live marker and relative distance on their map.'
                      : 'Live location paused. Others only see your last check-in.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.battery_saver, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('Crowd Battery Saver Mode'),
                      ],
                    ),
                    Switch(
                      value: squadService.isBatterySaver,
                      onChanged: (val) => squadService.toggleBatterySaver(val),
                    ),
                  ],
                ),
                Text(
                  'Reduces GPS polling rate to conserve battery over long hopping nights.',
                  style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Squad Friends At-A-Glance
        _buildSquadFriendsAtAGlance(context, theme, isDark, squadService, userMember),
        const SizedBox(height: 18),

        // Squad Members Header with Quick Map Jump
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              squadService.companionMembers.isEmpty
                  ? 'Squad Members (1 Host, 0 Companions)'
                  : 'Squad Members (${members.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                visualDensity: VisualDensity.compact,
              ),
              icon: const Icon(Icons.map_rounded, size: 16),
              label: const Text('View on Map'),
              onPressed: () {
                HapticFeedback.lightImpact();
                MainNavigationScreen.switchTab(context, 0);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),

        // User / Host Tile
        if (userMember != null)
          _buildMemberTile(context, userMember, userMember, theme, isDark, squadService),

        // Companions or Empty State
        if (squadService.companionMembers.isEmpty)
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isDark ? Colors.white12 : Colors.black12,
                width: 1,
              ),
            ),
            color: isDark ? PujaColors.nightCard.withValues(alpha: 0.6) : Colors.grey.shade50,
            margin: const EdgeInsets.only(top: 8),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: PujaColors.festivalGold.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.group_add_outlined,
                      size: 36,
                      color: PujaColors.festivalGold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No Companions Yet',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Your squad starts with only you as host. Share squad code "${squadService.squadCode}" with your friends and family so they can join and share their real device GPS coordinates.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      FilledButton.icon(
                        icon: const Icon(Icons.share, size: 16),
                        label: const Text('Invite Companions'),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          _shareInvite(context, squadService);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        else
          ...squadService.companionMembers
              .map((member) => _buildMemberTile(context, member, userMember, theme, isDark, squadService)),
      ],
    );
  }

  Widget _buildMemberTile(
    BuildContext context,
    SquadMember member,
    SquadMember? userMember,
    ThemeData theme,
    bool isDark,
    SquadService squadService,
  ) {
    final distanceText = member.isUser || userMember == null
        ? '0 m (Here)'
        : formatDistance(
            haversineMeters(
              userMember.latitude,
              userMember.longitude,
              member.latitude,
              member.longitude,
            ),
          );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: member.isUser ? PujaColors.festivalGold : member.avatarColor,
                  width: member.isUser ? 2.0 : 1.5,
                ),
              ),
              child: ClipOval(
                child: member.photoUrl != null && member.photoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: member.photoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (ctx, url) => CircleAvatar(
                          backgroundColor: member.avatarColor.withValues(alpha: 0.2),
                          foregroundColor: member.avatarColor,
                          child: Text(
                            member.initials,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.dynamicFont(17)),
                          ),
                        ),
                        errorWidget: (ctx, url, err) => CircleAvatar(
                          backgroundColor: member.avatarColor.withValues(alpha: 0.2),
                          foregroundColor: member.avatarColor,
                          child: Text(
                            member.initials,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.dynamicFont(17)),
                          ),
                        ),
                      )
                    : CircleAvatar(
                        backgroundColor: member.avatarColor.withValues(alpha: 0.2),
                        foregroundColor: member.avatarColor,
                        child: Text(
                          member.initials,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.dynamicFont(14)),
                        ),
                      ),
              ),
            ),
            Positioned(
              right: -1,
              bottom: -1,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                member.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: member.isUser ? FontWeight.bold : FontWeight.w600,
                  fontSize: context.dynamicFont(14),
                ),
              ),
            ),
            if (member.isHost) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'HOST',
                  style: TextStyle(fontSize: context.dynamicFont(10), fontWeight: FontWeight.bold, color: Colors.amber),
                ),
              ),
            ],
          ],
        ),
        subtitle: Row(
          children: [
            Expanded(
              child: Text(
                '${member.status} • $distanceText',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: context.dynamicFont(12)),
              ),
            ),
            Text(
              '🔋${member.batteryLevel}%',
              style: TextStyle(
                fontSize: context.dynamicFont(11),
                color: member.batteryLevel < 20 ? Colors.red : (isDark ? Colors.white60 : Colors.black54),
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(Icons.navigation_outlined, color: PujaColors.durgaRed, size: context.dynamicIcon(20)),
          tooltip: 'Locate on Map',
          onPressed: () {
            HapticFeedback.selectionClick();
            squadService.focusMember(member.id);
            MainNavigationScreen.switchTab(context, 0);
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeaderCard(BuildContext context, ThemeData theme, bool isDark) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.currentUserModel;
    final photoUrl = user?.photoUrl;
    final displayName = user?.displayName ?? 'Hopper Guest';
    final email = user?.email ?? 'Parikrama Traveler';
    final isGoogle = authService.isGoogleUser;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: PujaColors.festivalGold.withValues(alpha: 0.35),
          width: 1.2,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.selectionClick();
          UserProfileSheet.show(context);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Google DP
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: PujaColors.festivalGold,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: PujaColors.festivalGold.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: photoUrl != null && photoUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: photoUrl,
                          fit: BoxFit.cover,
                          placeholder: (c, u) => Container(
                            color: PujaColors.festivalGold.withValues(alpha: 0.2),
                            child: const Icon(Icons.person, color: PujaColors.festivalGold),
                          ),
                          errorWidget: (c, u, e) => Container(
                            color: PujaColors.festivalGold.withValues(alpha: 0.2),
                            child: Center(
                              child: Text(
                                user?.initials ?? 'HP',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: PujaColors.festivalGold),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: PujaColors.festivalGold.withValues(alpha: 0.2),
                          child: Center(
                            child: Text(
                              user?.initials ?? 'HP',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: PujaColors.festivalGold),
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              // User details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isGoogle) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const GoogleLogo(size: 11),
                                const SizedBox(width: 4),
                                Text(
                                  'Google',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? const Color(0xFF8AB4F8) : const Color(0xFF1A73E8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      email,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Profile button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  side: BorderSide(color: PujaColors.festivalGold.withValues(alpha: 0.5)),
                ),
                icon: const Icon(Icons.person_outline_rounded, size: 16),
                label: const Text('Profile', style: TextStyle(fontSize: 12)),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  UserProfileSheet.show(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSquadFriendsAtAGlance(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    SquadService squadService,
    SquadMember? userMember,
  ) {
    final companions = squadService.companionMembers;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.flash_on_rounded, color: PujaColors.festivalGold, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Squad Friends At-A-Glance',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
            if (companions.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${companions.length} Online',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (companions.isEmpty)
          Card(
            color: isDark ? PujaColors.nightCard.withValues(alpha: 0.7) : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: PujaColors.festivalGold.withValues(alpha: 0.25),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: PujaColors.festivalGold.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_add_alt_1_rounded, color: PujaColors.festivalGold, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'No Companions Active',
                          style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Share your squad code to invite friends and see their live GPS locations on the map.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: companions.length,
              separatorBuilder: (ctx, i) => const SizedBox(width: 10),
              itemBuilder: (ctx, index) {
                final friend = companions[index];
                final dist = userMember != null
                    ? formatDistance(
                        haversineMeters(
                          userMember.latitude,
                          userMember.longitude,
                          friend.latitude,
                          friend.longitude,
                        ),
                      )
                    : 'Nearby';

                return InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    squadService.focusMember(friend.id);
                    MainNavigationScreen.switchTab(context, 0);
                  },
                  child: Container(
                    width: 108,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    decoration: BoxDecoration(
                      color: isDark ? PujaColors.nightCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: PujaColors.festivalGold.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: PujaColors.festivalGold, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: PujaColors.festivalGold.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: friend.photoUrl != null && friend.photoUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: friend.photoUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (c, u) => CircleAvatar(
                                          backgroundColor: friend.avatarColor.withValues(alpha: 0.2),
                                          child: Text(friend.initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                        errorWidget: (c, u, e) => CircleAvatar(
                                          backgroundColor: friend.avatarColor.withValues(alpha: 0.2),
                                          child: Text(friend.initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                        ),
                                      )
                                    : CircleAvatar(
                                        backgroundColor: friend.avatarColor.withValues(alpha: 0.2),
                                        child: Text(friend.initials, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      ),
                              ),
                            ),
                            Positioned(
                              right: -1,
                              bottom: -1,
                              child: Container(
                                width: 11,
                                height: 11,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF00E676),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                                    width: 1.8,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          friend.name.split(' ')[0],
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: PujaColors.festivalGold.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            dist,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: PujaColors.festivalGold),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
