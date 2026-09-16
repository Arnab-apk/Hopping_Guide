import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/pandal_user_state_service.dart';
import '../services/squad_service.dart';
import '../services/theme_service.dart';
import 'google_account_chooser_dialog.dart';
import 'google_logo.dart';

/// Comprehensive User Profile Bottom Sheet for Kolkata Puja Parikrama.
/// Displays the user's authentic Google Profile Picture (DP), verified email badge,
/// pandal-hopping statistics, active squad status, theme toggle, and account actions.
class UserProfileSheet extends StatelessWidget {
  const UserProfileSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        curve: Curves.easeOutCubic,
        duration: Duration(milliseconds: 320),
      ),
      builder: (context) => const UserProfileSheet(),
    );
  }

  void _editDisplayName(BuildContext context, AppUser user) {
    final controller = TextEditingController(text: user.displayName ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Display Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Your Name',
            hintText: 'Enter your display name',
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
                AuthService.instance.updateProfile(displayName: newName);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _chooseGoogleAvatar(BuildContext context, AppUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E20) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Choose Google DP Avatar',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: AuthService.avatarPresets.map((url) {
                  final isSelected = user.photoUrl == url;
                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      AuthService.instance.updateProfile(photoUrl: url);
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? PujaColors.festivalGold
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                      child: CircleAvatar(
                        radius: 26,
                        backgroundImage: NetworkImage(url),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final authUser = context.select<AuthService?, AppUser?>(
      (auth) => auth?.currentUserModel,
    );
    final userState = context.watch<PandalUserStateService?>();
    final squadService = context.watch<SquadService?>();
    final themeService = context.watch<ThemeService?>();

    final isGuest = authUser?.isGuest ?? true;
    final userName = authUser?.displayName ?? (isGuest ? 'Guest Hopper' : 'Google Hopper');
    final userEmail = authUser?.email ?? (isGuest ? 'Guest Mode (Offline)' : 'hopper@gmail.com');
    final photoUrl = authUser?.photoUrl;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141416) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 32,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 6, bottom: 16),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Top Title & Close
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'My Profile',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Large Google Profile Picture (DP) with Golden Ring
              Center(
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const SweepGradient(
                          colors: [
                            PujaColors.festivalGold,
                            PujaColors.durgaRed,
                            PujaColors.goldBright,
                            PujaColors.festivalGold,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: PujaColors.festivalGold.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: isDark
                            ? const Color(0xFF242426)
                            : const Color(0xFFECEFF1),
                        backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                            ? NetworkImage(photoUrl)
                            : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? Text(
                                authUser?.initials ?? 'G',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              )
                            : null,
                      ),
                    ),

                    // Camera/Edit Avatar Badge
                    GestureDetector(
                      onTap: () {
                        if (authUser != null) {
                          _chooseGoogleAvatar(context, authUser);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: PujaColors.festivalGold,
                          border: Border.all(
                            color: isDark ? const Color(0xFF141416) : Colors.white,
                            width: 2.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 15,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Display Name & Edit Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    userName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () {
                      if (authUser != null) {
                        _editDisplayName(context, authUser);
                      }
                    },
                    child: Icon(
                      Icons.edit_rounded,
                      size: 16,
                      color: PujaColors.festivalGold,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Email & Verified Badge
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isGuest
                      ? (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06))
                      : const Color(0xFF4285F4).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isGuest
                        ? Colors.transparent
                        : const Color(0xFF4285F4).withValues(alpha: 0.4),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isGuest) ...[
                      const GoogleLogo(size: 13),
                      const SizedBox(width: 6),
                    ] else ...[
                      Icon(
                        Icons.person_outline_rounded,
                        size: 14,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      userEmail,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isGuest
                            ? (isDark ? Colors.white60 : Colors.black54)
                            : const Color(0xFF4285F4),
                      ),
                    ),
                    if (!isGuest) ...[
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.verified_rounded,
                        size: 14,
                        color: Color(0xFF4285F4),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // --- Hopper Parikrama Stats Grid ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E22)
                      : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.insights_rounded,
                          size: 16,
                          color: PujaColors.festivalGold,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Pujo Parikrama Stats',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        // Pandals Hopped
                        Expanded(
                          child: _buildStatItem(
                            isDark: isDark,
                            icon: Icons.temple_hindu_rounded,
                            iconColor: PujaColors.durgaRed,
                            title: '${userState?.visitedCount ?? 0}',
                            label: 'Pandals Hopped',
                            sublabel: 'Out of 387',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 48,
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                        // Wishlist Saved
                        Expanded(
                          child: _buildStatItem(
                            isDark: isDark,
                            icon: Icons.favorite_rounded,
                            iconColor: const Color(0xFFFF4081),
                            title: '${userState?.favoriteCount ?? 0}',
                            label: 'Bookmarked',
                            sublabel: 'Wishlist',
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 48,
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                        // Squad Status
                        Expanded(
                          child: _buildStatItem(
                            isDark: isDark,
                            icon: Icons.groups_rounded,
                            iconColor: const Color(0xFF00B0FF),
                            title: squadService?.hasActiveSquad == true
                                ? '${squadService?.members.length}'
                                : 'None',
                            label: squadService?.hasActiveSquad == true
                                ? 'In Squad'
                                : 'No Squad',
                            sublabel: squadService?.squadCode ?? 'Join one',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // --- Account Switcher / Google Action ---
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E22)
                      : const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: [
                      if (isGuest)
                        ListTile(
                          leading: const GoogleLogo(size: 24),
                          title: const Text(
                            'Sign In with Google',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                          subtitle: const Text(
                            'Sync your Google DP on squad map & backup hopping history',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                          onTap: () async {
                            Navigator.pop(context);
                            final result = await AuthService.instance.signInWithGoogleDetailed();
                            if (!result.success && !result.isCancelled && context.mounted) {
                              await GoogleAccountChooserDialog.show(context);
                            }
                          },
                        )
                      else
                        ListTile(
                          leading: const GoogleLogo(size: 24),
                          title: const Text(
                            'Switch Google Account',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                          subtitle: const Text(
                            'Change active profile or switch Google DP',
                            style: TextStyle(fontSize: 12),
                          ),
                          trailing: const Icon(Icons.swap_horiz_rounded, size: 20),
                          onTap: () async {
                            Navigator.pop(context);
                            await GoogleAccountChooserDialog.show(context);
                          },
                        ),

                      const Divider(height: 1),

                      // Theme Toggle Tile
                      ListTile(
                        leading: Icon(
                          themeService?.isDarkMode == true
                              ? Icons.dark_mode_rounded
                              : Icons.light_mode_rounded,
                          color: PujaColors.festivalGold,
                          size: 22,
                        ),
                        title: const Text(
                          'Night / OLED Dark Mode',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        trailing: Switch.adaptive(
                          value: themeService?.isDarkMode ?? true,
                          activeTrackColor: PujaColors.festivalGold,
                          onChanged: (_) {
                            HapticFeedback.selectionClick();
                            themeService?.toggleTheme();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // --- Sign Out / Leave Button ---
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF5252),
                    side: const BorderSide(color: Color(0xFFFF5252), width: 1.2),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: Text(
                    isGuest ? 'Reset Guest Session' : 'Sign Out of Google',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  onPressed: () async {
                    HapticFeedback.heavyImpact();
                    Navigator.pop(context);
                    await AuthService.instance.signOut();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacementNamed('/welcome');
                    }
                  },
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String label,
    required String sublabel,
  }) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 20),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        Text(
          sublabel,
          style: TextStyle(
            fontSize: 9.5,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }
}
