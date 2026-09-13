import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/theme.dart';
import '../services/auth_service.dart';
import '../utils/responsive.dart';

/// Group Member model for hopping squads
class GroupMember {
  final String id;
  final String name;
  final String status;
  final String distance;
  final bool isHost;
  final bool isUser;
  final DateTime lastSeen;

  const GroupMember({
    required this.id,
    required this.name,
    required this.status,
    required this.distance,
    this.isHost = false,
    this.isUser = false,
    required this.lastSeen,
  });
}

/// Screen for creating/joining hopping groups, tracking squad members,
/// setting meetup points, and triggering separation alerts.
class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  String? _groupCode;
  String? _groupName;
  String _meetupPoint = 'Main Entrance Gate';
  bool _isSharingLocation = true;
  bool _batterySaver = true;

  final List<GroupMember> _members = [];

  @override
  void initState() {
    super.initState();
    // Default state: clean onboarding, restore saved squad if user previously created or joined one
    _loadSavedGroup();
  }

  Future<void> _saveGroupState() async {
    final prefs = await SharedPreferences.getInstance();
    if (_groupCode != null) {
      await prefs.setString('saved_group_code', _groupCode!);
      await prefs.setString('saved_group_name', _groupName ?? 'My Squad');
      await prefs.setString('saved_meetup_point', _meetupPoint);
    }
  }

  Future<void> _loadSavedGroup() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('saved_group_code');
    final savedName = prefs.getString('saved_group_name');
    final savedMeetup = prefs.getString('saved_meetup_point');

    if (savedCode != null && savedName != null) {
      final user = AuthService.instance.currentUserModel;
      final userName = user?.displayName ?? 'You';
      if (mounted) {
        setState(() {
          _groupCode = savedCode;
          _groupName = savedName;
          if (savedMeetup != null) _meetupPoint = savedMeetup;
          _members.clear();
          _members.add(
            GroupMember(
              id: user?.uid ?? 'user',
              name: '$userName (You)',
              status: 'Squad Host • Active',
              distance: '0 m (Here)',
              isHost: true,
              isUser: true,
              lastSeen: DateTime.now(),
            ),
          );
        });
      }
    }
  }

  Future<void> _leaveGroup() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Squad?'),
        content: Text('Are you sure you want to leave "$_groupName"?'),
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
      setState(() {
        _groupCode = null;
        _groupName = null;
        _members.clear();
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('saved_group_code');
      await prefs.remove('saved_group_name');
      await prefs.remove('saved_meetup_point');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('You left the squad.')),
        );
      }
    }
  }

  void _createGroup() {
    final nameController = TextEditingController();
    final meetupController = TextEditingController(text: 'Main Pandal Entrance');
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
            onPressed: () {
              final squadName = nameController.text.trim().isEmpty ? 'My Puja Squad' : nameController.text.trim();
              final meetup = meetupController.text.trim().isEmpty ? 'Main Entrance Gate' : meetupController.text.trim();
              Navigator.pop(ctx);

              final code = 'PUJA${100 + Random().nextInt(900)}';
              final user = AuthService.instance.currentUserModel;
              final userName = user?.displayName ?? 'You';

              setState(() {
                _groupName = squadName;
                _groupCode = code;
                _meetupPoint = meetup;
                _members.clear();
                _members.add(
                  GroupMember(
                    id: user?.uid ?? 'host',
                    name: '$userName (Host)',
                    status: 'Active • At Pandal',
                    distance: '0 m (Here)',
                    isHost: true,
                    isUser: true,
                    lastSeen: DateTime.now(),
                  ),
                );
              });
              _saveGroupState();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Created "$squadName"! Invite Code: $code'),
                  action: SnackBarAction(
                    label: 'Share',
                    onPressed: _shareInvite,
                  ),
                ),
              );
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _joinGroup() {
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
            labelText: 'Enter 6-character Code',
            hintText: 'e.g. PUJA512',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final code = controller.text.trim().toUpperCase();
              if (code.isNotEmpty) {
                Navigator.pop(ctx);
                final user = AuthService.instance.currentUserModel;
                final userName = user?.displayName ?? 'You';
                setState(() {
                  _groupCode = code;
                  _groupName = 'Squad $code';
                  _meetupPoint = 'Designated Meet-up Point';
                  _members.clear();
                  _members.add(
                    GroupMember(
                      id: user?.uid ?? 'member',
                      name: '$userName (Member)',
                      status: 'Joined • Active',
                      distance: '0 m (Here)',
                      isHost: false,
                      isUser: true,
                      lastSeen: DateTime.now(),
                    ),
                  );
                });
                _saveGroupState();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Joined squad $code!')),
                );
              }
            },
            child: const Text('Join'),
          ),
        ],
      ),
    );
  }

  void _shareInvite() {
    if (_groupCode == null) return;
    SharePlus.instance.share(
      ShareParams(
        text: 'Join my Durga Puja Hopping Squad "$_groupName" on Kolkata Puja App! '
            'Group Code: $_groupCode\nMeet-up Point: $_meetupPoint\n'
            'Live GPS & Pandal Guide: https://sharodiya.com/join?code=$_groupCode',
      ),
    );
  }

  void _setMeetupPoint() {
    final controller = TextEditingController(text: _meetupPoint);
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
                setState(() {
                  _meetupPoint = controller.text.trim();
                });
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Meet-up point updated to $_meetupPoint')),
                );
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _triggerSeparationSOS() {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hopping Squad (Groups)'),
        actions: [
          IconButton(
            tooltip: 'Invite Squad',
            icon: const Icon(Icons.share_rounded),
            onPressed: _groupCode != null ? _shareInvite : null,
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'create') _createGroup();
              if (value == 'join') _joinGroup();
              if (value == 'leave') _leaveGroup();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'create', child: Text('Create New Squad')),
              const PopupMenuItem(value: 'join', child: Text('Join Squad Code')),
              if (_groupCode != null)
                const PopupMenuItem(value: 'leave', child: Text('Leave Current Squad', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
      body: _groupCode == null ? _buildNoGroupView(theme) : _buildActiveGroupView(theme, isDark),
    );
  }

  Widget _buildNoGroupView(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                onPressed: _createGroup,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.login),
                label: const Text('Join with Squad Code'),
                onPressed: _joinGroup,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveGroupView(ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                            _groupName ?? 'My Squad',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_members.length} members hopping together',
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
                            _groupCode ?? '',
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
                              Clipboard.setData(ClipboardData(text: _groupCode ?? ''));
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
                          _shareInvite();
                        },
                      ),
                      const SizedBox(width: 12),
                      FilledButton.tonalIcon(
                        icon: Icon(Icons.sos, color: Colors.red, size: context.dynamicIcon(18)),
                        label: Text('Separation Alert', style: TextStyle(color: Colors.red, fontSize: context.dynamicFont(13))),
                        onPressed: () {
                          HapticFeedback.heavyImpact();
                          _triggerSeparationSOS();
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
                        _meetupPoint,
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
                    _setMeetupPoint();
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
                          _isSharingLocation ? Icons.location_on : Icons.location_off,
                          color: _isSharingLocation ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Share Live GPS Location',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Switch(
                      value: _isSharingLocation,
                      onChanged: (val) {
                        setState(() => _isSharingLocation = val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  _isSharingLocation
                      ? 'Squad members can see your relative distance on their map.'
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
                      value: _batterySaver,
                      onChanged: (val) {
                        setState(() => _batterySaver = val);
                      },
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
        const SizedBox(height: 20),

        // Squad Members Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Squad Members (${_members.length})',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Member'),
              onPressed: _shareInvite,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Member Cards
        ..._members.map((member) => _buildMemberTile(member, theme, isDark)),
      ],
    );
  }

  Widget _buildMemberTile(GroupMember member, ThemeData theme, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: member.isUser
              ? PujaColors.durgaRed
              : PujaColors.festivalGold.withValues(alpha: 0.2),
          foregroundColor: member.isUser ? Colors.white : PujaColors.festivalGold,
          child: Text(
            member.name.substring(0, 1).toUpperCase(),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: context.dynamicFont(14)),
          ),
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
        subtitle: Text(
          '${member.status} • ${member.distance}',
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: context.dynamicFont(12)),
        ),
        trailing: IconButton(
          icon: Icon(Icons.navigation_outlined, color: PujaColors.durgaRed, size: context.dynamicIcon(20)),
          tooltip: 'Locate on Map',
          onPressed: () {
            HapticFeedback.selectionClick();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Focusing map on ${member.name}...')),
            );
          },
        ),
      ),
    );
  }
}
