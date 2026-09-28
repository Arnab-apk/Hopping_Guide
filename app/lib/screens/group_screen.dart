import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';
import '../models/chat_message.dart';
import '../models/squad_member.dart';
import '../models/squad_pandal_stop.dart';
import '../services/auth_service.dart';
import '../services/squad_chat_service.dart';
import '../services/squad_service.dart';
import '../services/websocket_client.dart';
import '../utils/haversine.dart';
import '../widgets/puja_icons.dart';
import '../widgets/squad_pandal_picker_sheet.dart';
import '../widgets/user_profile_sheet.dart';
import '../widgets/vote_avatar_stack.dart';
import 'main_navigation_screen.dart';
import 'squad_chat_screen.dart';
import 'squad_settings_screen.dart';

/// Radically simplified Screen for Durga Puja Hopping Squads.
/// Follows the restrained, muted rose/mauve and dark maroon palette (`AppColors`).
/// Main screen focuses strictly on daily-use actions:
/// 1. Squad Identity (name, code, member count, ONE invite button)
/// 2. Live GPS Sharing Toggle (single row, safety-critical)
/// 3. Squad Members (host row, companion rows, minimal empty guidance)
/// 4. Squad Chosen Pandals & Live Hopping (with collaborative voting & My Selections filter)
/// 5. Squad Chat & Media (unmoderated preview, one-tap navigation)
/// Configuration and settings live exclusively in [SquadSettingsScreen] accessed via the AppBar.
class GroupScreen extends StatefulWidget {
  const GroupScreen({super.key});

  @override
  State<GroupScreen> createState() => _GroupScreenState();
}

class _GroupScreenState extends State<GroupScreen> {
  bool _showMySelectionsOnly = false;

  void _shareInvite(BuildContext context, SquadService squadService) {
    if (!squadService.hasActiveSquad) return;
    final code = squadService.squadCode;
    final name = (squadService.squadName ?? 'My Group').replaceAll(RegExp(r',\s*s\b'), "'s");
    
    // Use web URL that works across all platforms:
    // - Android: Opens app directly via App Links (intent filter in AndroidManifest)
    // - iOS: Opens app via Universal Links (when configured)
    // - Web: Opens web app which handles deep link and shows "Open in App" button
    // - Fallback: Custom URI scheme for direct app opening
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
        // Also provide the URL separately for better sharing UX
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
              final rawName = nameController.text.trim().isEmpty ? 'My Puja Group' : nameController.text.trim();
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Join Group by Code'),
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

    final squadCode = squadService.squadCode ?? '';
    final squadName = (squadService.squadName ?? 'Group Chat').replaceAll(RegExp(r',\s*s\b'), "'s");

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hopping Group'),
        actions: [
          if (squadService.hasActiveSquad) ...[
            IconButton(
              icon: StreamBuilder<List<ChatMessage>>(
                stream: squadCode.isNotEmpty
                    ? SquadChatService.instance.messagesStream(squadCode)
                    : null,
                builder: (context, snapshot) {
                  final hasMessages = snapshot.hasData && snapshot.data!.isNotEmpty;
                  return Badge(
                    isLabelVisible: hasMessages,
                    backgroundColor: theme.colorScheme.primary,
                    child: const Icon(Icons.chat_bubble_outline),
                  );
                },
              ),
              tooltip: 'Group Chat',
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SquadChatScreen(
                      squadCode: squadCode,
                      squadName: squadName,
                    ),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Group Settings',
              onPressed: () {
                HapticFeedback.selectionClick();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const SquadSettingsScreen(),
                  ),
                );
              },
            ),
          ],
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
                const SizedBox(height: 12),
                Text(
                  'Form a hopping group with friends and family. See live member pins on the map, set meetup spots, and trigger separation alerts in dense crowds.',
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      'Create New Group',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    icon: const Icon(Icons.login_rounded),
                    label: Text(
                      'Join with Group Code',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
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
    final alert = squadService.activeSeparationAlert;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Realtime Connection Status Pill
        _buildConnectionPill(context, squadService, isDark),
        const SizedBox(height: 12),

        // Separation Alert Banner (only appears when actually triggered)
        if (alert != null) ...[
          _buildSeparationAlertBanner(context, theme, alert, squadService),
          const SizedBox(height: 12),
        ],

        // 1. Squad Identity Card (Name, Code, Member Count, ONE Invite Button)
        _buildSquadIdentityCard(context, theme, isDark, squadService),
        const SizedBox(height: 14),

        // 2. GPS Sharing Toggle Card (Single row, safety-relevant)
        _buildGpsSharingCard(context, theme, isDark, squadService),
        const SizedBox(height: 14),

        // 3. Squad Members Card (Host row, companion list, or minimal guidance text)
        _buildSquadMembersCard(context, theme, isDark, squadService),
        const SizedBox(height: 14),

        // 4. Squad Chosen Pandals & Live Hopping Card
        _buildSquadPandalsCard(context, theme, isDark, squadService),
        const SizedBox(height: 14),

        // 5. Squad Chat & Media Card (Unmoderated preview)
        _buildSquadChatCard(context, theme, isDark, squadService),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildConnectionPill(BuildContext context, SquadService squadService, bool isDark) {
    final state = squadService.wsConnectionState;
    Color dotColor;
    String statusText;
    Color bgColor;

    switch (state) {
      case WebSocketConnectionState.connected:
        dotColor = AppColors.semanticLive;
        statusText = 'Connected';
        bgColor = AppColors.semanticLive.withValues(alpha: 0.18);
        break;
      case WebSocketConnectionState.connecting:
        dotColor = AppColors.accentGold;
        statusText = 'Connecting...';
        bgColor = AppColors.accentGold.withValues(alpha: 0.15);
        break;
      case WebSocketConnectionState.reconnecting:
        dotColor = AppColors.accentGold;
        statusText = 'Reconnecting...';
        bgColor = AppColors.accentGold.withValues(alpha: 0.15);
        break;
      case WebSocketConnectionState.error:
      case WebSocketConnectionState.disconnected:
        dotColor = Colors.grey;
        statusText = 'Offline';
        bgColor = isDark ? const Color(0xFF262626) : const Color(0xFFF5F5F5);
        break;
    }

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dotColor.withValues(alpha: 0.35),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 7),
            Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSeparationAlertBanner(
    BuildContext context,
    ThemeData theme,
    SquadSeparationAlert alert,
    SquadService squadService,
  ) {
    return Card(
      color: AppColors.semanticAlert.withValues(alpha: 0.15),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.semanticAlert, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppColors.semanticAlert, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${alert.memberName} is ${formatDistance(alert.distanceMeters.toDouble())} away',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.semanticAlert,
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                squadService.focusMember(alert.memberId);
                MainNavigationScreen.switchTab(context, 0);
              },
              child: const Text('Locate'),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              tooltip: 'Dismiss',
              onPressed: () => squadService.dismissSeparationAlert(),
            ),
          ],
        ),
      ),
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
      color: isDark ? AppColors.cardSurface : Colors.white,
      elevation: 0,
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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
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
                // Squad Code Pill with subtle gold border
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1414) : const Color(0xFFFDF7F7),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.accentGold,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        code,
                        style: TextStyle(
                          color: isDark ? AppColors.accentGold : const Color(0xFF5A1E1E),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                        icon: const Icon(Icons.copy_rounded, size: 15),
                        tooltip: 'Copy Group Code',
                        color: isDark ? AppColors.accentGold : const Color(0xFF5A1E1E),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: code));
                          HapticFeedback.lightImpact();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Group code copied to clipboard!')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // The ONE Invite Companions button on the page
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: PujaIcon.shankha(size: 20, color: theme.colorScheme.onPrimary),
                label: Text(
                  'Invite Companions',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
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

  // --- CARD 2: LIVE GPS SHARING (Single Row) ---
  Widget _buildGpsSharingCard(BuildContext context, ThemeData theme, bool isDark, SquadService squadService) {
    return Card(
      color: isDark ? AppColors.cardSurface : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (squadService.isSharingLocation ? AppColors.semanticLive : Colors.grey)
                    .withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                squadService.isSharingLocation ? Icons.location_on : Icons.location_off,
                color: squadService.isSharingLocation ? AppColors.semanticLive : Colors.grey,
                size: 20,
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
                        ? 'Broadcasting live pin to group'
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
              activeThumbColor: AppColors.semanticLive,
              activeTrackColor: AppColors.semanticLive.withValues(alpha: 0.3),
              onChanged: (val) {
                HapticFeedback.selectionClick();
                squadService.toggleLocationSharing(val);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- CARD 3: SQUAD MEMBERS (Host row + Companion rows + Minimal Guidance) ---
  Widget _buildSquadMembersCard(BuildContext context, ThemeData theme, bool isDark, SquadService squadService) {
    final members = squadService.members;
    final userMember = members.where((m) => m.isUser).firstOrNull;
    final companions = squadService.companionMembers;

    return Card(
      color: isDark ? AppColors.cardSurface : Colors.white,
      elevation: 0,
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

            // Companions or Minimal Guidance (NO duplicate Invite button)
            if (companions.isEmpty) ...[
              const Divider(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No companions yet — share your group code above to get started',
                    style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
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
                border: Border.all(color: AppColors.accentGold, width: 1.5),
              ),
              child: ClipOval(
                child: userMember.photoUrl != null && userMember.photoUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: userMember.photoUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => CircleAvatar(
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                          child: Text(userMember.initials, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
                        ),
                      )
                    : CircleAvatar(
                        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                        child: Text(userMember.initials, style: TextStyle(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
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
                          color: AppColors.accentGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${userMember.markerStateDot} 0 m (Here) • Tap to view Profile',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppColors.accentGold,
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
                    color: member.isOnline ? AppColors.semanticLive : Colors.grey,
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
                  '${member.markerStateDot} ${member.status} • ${member.lastSeenText}',
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
            distanceText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '🔋${member.batteryLevel}%',
            style: TextStyle(
              fontSize: 11,
              color: member.batteryLevel < 20 ? AppColors.semanticAlert : (isDark ? Colors.white60 : Colors.black54),
            ),
          ),
          // Native dialer Call button
          if (member.hasPhone) ...[
            const SizedBox(width: 2),
            IconButton(
              icon: const Icon(Icons.phone_rounded, color: AppColors.semanticLive, size: 19),
              tooltip: 'Call Companion',
              onPressed: () {
                HapticFeedback.lightImpact();
                _callCompanion(context, member);
              },
            ),
          ],
        ],
      ),
    );
  }

  // --- CARD 4: PANDALS TO HOP TOGETHER & LIVE TRACKING ---
  Widget _buildSquadPandalsCard(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    SquadService squadService,
  ) {
    final allChosen = squadService.chosenPandals;
    final isHopping = squadService.isHoppingActive;
    final activeIndex = squadService.activeHoppingStopIndex;
    final visitedCount = squadService.visitedPandalsCount;
    final currentUserId = AuthService.instance.currentUser?.uid ?? 'guest';

    // Filter for My Selections
    final chosen = _showMySelectionsOnly
        ? allChosen.where((stop) => stop.isVotedBy(currentUserId)).toList()
        : allChosen;

    return Card(
      color: isDark ? AppColors.cardSurface : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isHopping
              ? AppColors.accentGold.withValues(alpha: 0.6)
              : (isDark ? Colors.white12 : Colors.black12),
          width: isHopping ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row: Title · Live Pill / Count · Add Button
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: (isHopping ? AppColors.semanticLive : theme.colorScheme.primary)
                        .withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    isHopping ? Icons.directions_walk_rounded : Icons.temple_hindu_rounded,
                    color: isHopping ? AppColors.semanticLive : theme.colorScheme.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Pandals to Hop Together',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isHopping) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: AppColors.semanticLive.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.semanticLive,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'HOPPING LIVE',
                                    style: TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppColors.semanticLive,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isHopping
                            ? 'Stop ${activeIndex + 1} of ${allChosen.length} • $visitedCount visited'
                            : _showMySelectionsOnly
                                ? chosen.isEmpty
                                    ? 'No pandals selected by you'
                                    : '${chosen.length} of ${allChosen.length} selected by you'
                                : allChosen.isEmpty
                                    ? 'Vote & plan group stops'
                                    : '${allChosen.length} ${allChosen.length == 1 ? "pandal" : "pandals"} selected',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.add_rounded, size: 15),
                  label: const Text('Add', style: TextStyle(fontSize: 12)),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    SquadPandalPickerSheet.show(context, squadService);
                  },
                ),
              ],
            ),
            // My Selections Filter Toggle
            if (!isHopping && allChosen.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showMySelectionsOnly
                                ? Icons.filter_list_rounded
                                : Icons.filter_list_outlined,
                            size: 14,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'My Selections',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      selected: _showMySelectionsOnly,
                      onSelected: (val) {
                        setState(() => _showMySelectionsOnly = val);
                        HapticFeedback.selectionClick();
                      },
                      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.18),
                      checkmarkColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: _showMySelectionsOnly
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                      side: BorderSide(
                        color: _showMySelectionsOnly
                            ? theme.colorScheme.primary
                            : (isDark ? Colors.white24 : Colors.black26),
                      ),
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                  if (_showMySelectionsOnly && chosen.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        'Tap a pandal\u2019s vote button to add it here',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ),
                ],
              ),
            ],

            // Live Hopping HUD Banner (when hopping is active)
            if (isHopping && chosen.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildLiveHoppingCardBanner(context, theme, isDark, squadService),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            // Empty State
            if (chosen.isEmpty)
              _buildEmptyPandalsPrompt(context, theme, isDark, squadService)
            else ...[
              // Action Bar: Hop Together Button + Optimize Route
              if (!isHopping) ...[
                _buildHoppingActionButtons(context, theme, isDark, squadService),
                const SizedBox(height: 12),
              ],

              // List of Chosen Pandals
              ...chosen.asMap().entries.map((entry) {
                final index = entry.key;
                final stop = entry.value;
                return _buildPandalStopTile(
                  context,
                  theme,
                  isDark,
                  squadService,
                  stop,
                  index,
                  isCurrentTarget: isHopping && index == activeIndex,
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLiveHoppingCardBanner(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    SquadService squadService,
  ) {
    final currentTarget = squadService.currentHoppingTarget;
    final progress = squadService.hoppingProgress;
    final activeIndex = squadService.activeHoppingStopIndex;
    final total = squadService.chosenPandals.length;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1418) : const Color(0xFFFFF7F8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT DESTINATION (STOP ${activeIndex + 1}/$total)',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppColors.accentGold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      currentTarget?.pandalName ?? 'Hopping Completed! 🎉',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (currentTarget != null)
                      Text(
                        currentTarget.zone,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentGold,
                  foregroundColor: Colors.black87,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  visualDensity: VisualDensity.compact,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.map_rounded, size: 15),
                label: const Text(
                  'Map',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  MainNavigationScreen.switchTab(context, 0);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 5,
              backgroundColor: isDark ? Colors.white12 : Colors.black12,
              valueColor: const AlwaysStoppedAnimation(AppColors.semanticLive),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFF00C853),
                ),
                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                label: const Text('Next Stop / Visited', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  await squadService.advanceToNextPandalStop();
                },
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  visualDensity: VisualDensity.compact,
                  foregroundColor: const Color(0xFFFF5252),
                ),
                icon: const Icon(Icons.stop_circle_outlined, size: 16),
                label: const Text('End Hop', style: TextStyle(fontSize: 12)),
                onPressed: () async {
                  HapticFeedback.selectionClick();
                  await squadService.endSquadHopping();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Squad hopping ended')),
                    );
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHoppingActionButtons(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    SquadService squadService,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.directions_walk_rounded, size: 18),
            label: Text(
              'Hop Together',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              await squadService.startSquadHopping();
              if (context.mounted) {
                MainNavigationScreen.switchTab(context, 0);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Live squad hopping started! Following route on map.'),
                  ),
                );
              }
            },
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              side: BorderSide(
                color: isDark ? Colors.white24 : Colors.black26,
                width: 1,
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
            label: const Text(
              'Optimize',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            onPressed: () async {
              HapticFeedback.lightImpact();
              await squadService.optimizeSquadRoute();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Route sorted for shortest walking distance!'),
                  ),
                );
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyPandalsPrompt(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    SquadService squadService,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.temple_hindu_outlined,
              size: 28,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'No pandals chosen yet',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Add pandals everyone wants to see. Group members can vote on favorites, auto-optimize the trail, and track live hopping on the map.',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              side: BorderSide(color: theme.colorScheme.primary, width: 1.2),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.add_location_alt_outlined, size: 16),
            label: const Text('Choose Pandals to Visit', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
            onPressed: () {
              HapticFeedback.lightImpact();
              SquadPandalPickerSheet.show(context, squadService);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPandalStopTile(
    BuildContext context,
    ThemeData theme,
    bool isDark,
    SquadService squadService,
    SquadPandalStop stop,
    int index, {
    required bool isCurrentTarget,
  }) {
    final currentUserId = AuthService.instance.currentUser?.uid ?? 'guest';
    // Set current user ID for model's currentUserVoted getter
    SquadPandalStop.setCurrentUserId(currentUserId);
    final hasVoted = stop.currentUserVoted;
    final voterMembers = stop.getVoterMembers(squadService.members);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isCurrentTarget
            ? AppColors.accentGold.withValues(alpha: 0.12)
            : (isDark ? Colors.white.withValues(alpha: 0.03) : Colors.black.withValues(alpha: 0.02)),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentTarget
              ? AppColors.accentGold
              : (isDark ? Colors.white10 : Colors.black12),
          width: isCurrentTarget ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Stop Number or Visited Checkmark
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: stop.isVisited
                  ? const Color(0xFF00C853)
                  : (isCurrentTarget ? AppColors.accentGold : theme.colorScheme.primary.withValues(alpha: 0.15)),
            ),
            child: Center(
              child: stop.isVisited
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 16)
                  : Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isCurrentTarget ? Colors.black87 : theme.colorScheme.primary,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 10),

          // Pandal Name & Zone / Suggestion
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        stop.pandalName,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          decoration: stop.isVisited ? TextDecoration.lineThrough : null,
                          color: stop.isVisited
                              ? (isDark ? Colors.white38 : Colors.black38)
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (stop.isSuggestedByCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'YOURS',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                    if (isCurrentTarget) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.accentGold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'NEXT',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${stop.zone} • Added by ${stop.suggestedByName}',
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

          // Voter Avatars Stack
          if (voterMembers.isNotEmpty) ...[
            VoteAvatarStack(
              voters: voterMembers,
              currentUserId: currentUserId,
              maxVisible: 4,
              avatarSize: 22,
            ),
            const SizedBox(width: 8),
          ],

          // Upvote / Thumbs up Button
          InkWell(
            borderRadius: BorderRadius.circular(16),
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
                borderRadius: BorderRadius.circular(12),
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
                        color: hasVoted ? theme.colorScheme.primary : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(width: 2),

          // Remove Button
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: Icon(
              Icons.close_rounded,
              size: 16,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            tooltip: 'Remove stop',
            onPressed: () {
              HapticFeedback.selectionClick();
              squadService.removePandalFromSquad(stop.id);
            },
          ),
        ],
      ),
    );
  }

  // --- CARD 5: SQUAD CHAT & MEDIA ---
  Widget _buildSquadChatCard(BuildContext context, ThemeData theme, bool isDark, SquadService squadService) {
    final squadCode = squadService.squadCode ?? 'GROUP';
    final squadName = (squadService.squadName ?? 'Group Chat').replaceAll(RegExp(r',\s*s\b'), "'s");

    return Card(
      color: isDark ? AppColors.cardSurface : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1,
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
                  color: theme.colorScheme.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.forum_rounded, color: theme.colorScheme.primary, size: 24),
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
                            'Group Chat & Media',
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
                            color: AppColors.semanticLive.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Live',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.semanticLive,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    // Unmoderated Preview Protection: Generic friendly preview instead of raw unmoderated text
                    StreamBuilder<List<ChatMessage>>(
                      stream: SquadChatService.instance.messagesStream(squadCode),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                          final latest = snapshot.data!.first;
                          final preview = latest.isImage
                              ? '${latest.senderName} shared a photo'
                              : latest.isVideo
                                  ? '${latest.senderName} shared a video'
                                  : 'New message from ${latest.senderName}';
                          return Text(
                            preview,
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
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white38 : Colors.black38,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
