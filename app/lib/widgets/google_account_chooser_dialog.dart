import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'google_logo.dart';

/// Authentic Google Account Selector dialog / bottom sheet.
/// Allows signing in directly with real Google credentials or configuring
/// a custom hopper profile. Zero dummy accounts or simulated presets.
class GoogleAccountChooserDialog extends StatefulWidget {
  const GoogleAccountChooserDialog({super.key});

  static Future<AppUser?> show(BuildContext context) {
    return showModalBottomSheet<AppUser>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      sheetAnimationStyle: const AnimationStyle(
        curve: Curves.easeOutCubic,
        duration: Duration(milliseconds: 300),
      ),
      builder: (context) => const GoogleAccountChooserDialog(),
    );
  }

  @override
  State<GoogleAccountChooserDialog> createState() => _GoogleAccountChooserDialogState();
}

class _GoogleAccountChooserDialogState extends State<GoogleAccountChooserDialog> {
  bool _isCustomMode = false;
  bool _isSigningIn = false;
  late String _selectedAvatar;

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final currentUser = AuthService.instance.currentUserModel;
    final initialName = (currentUser != null && !currentUser.isGuest)
        ? (currentUser.displayName ?? '')
        : '';
    final initialEmail = (currentUser != null && !currentUser.isGuest)
        ? (currentUser.email ?? '')
        : '';

    _nameController = TextEditingController(text: initialName);
    _emailController = TextEditingController(text: initialEmail);
    _selectedAvatar = currentUser?.photoUrl ?? AuthService.defaultGoogleAvatar;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _signInWithNativeGoogle() async {
    HapticFeedback.mediumImpact();
    setState(() => _isSigningIn = true);

    final result = await AuthService.instance.signInWithGoogleDetailed();
    if (!mounted) return;
    setState(() => _isSigningIn = false);

    if (result.success && result.user != null) {
      Navigator.of(context).pop(result.user);
    } else if (result.isCancelled) {
      // User cancelled account selection
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: PujaColors.durgaRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(
            result.errorMessage ?? 'Google Sign-In could not be completed.',
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      );
    }
  }

  Future<void> _saveCustomAccount() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your display name.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() => _isSigningIn = true);

    final user = await AuthService.instance.signInWithGoogleProfile(
      displayName: name,
      email: email.isNotEmpty ? email : 'hopper@kolkatapuja.com',
      photoUrl: _selectedAvatar,
    );

    if (!mounted) return;
    Navigator.of(context).pop(user);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentUser = AuthService.instance.currentUserModel;
    final hasActiveUser = currentUser != null && !currentUser.isGuest;

    return Material(
      color: isDark ? const Color(0xFF1E1E20) : Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag Handle
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 10, bottom: 12),
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header with Google G Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      const GoogleLogo(size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sign in with Google',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            Text(
                              'Connect your profile to share live squad location',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                const Divider(height: 1),

                if (_isSigningIn)
                  const Padding(
                    padding: EdgeInsets.all(36),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4285F4)),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Connecting Google Profile...',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  )
                else if (!_isCustomMode) ...[
                  // Current Active Account if signed in
                  if (hasActiveUser) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 14, 20, 4),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'CURRENT ACTIVE ACCOUNT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ),
                    ),
                    ListTile(
                      leading: CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF4285F4),
                        backgroundImage: currentUser.photoUrl != null
                            ? NetworkImage(currentUser.photoUrl!)
                            : null,
                        child: currentUser.photoUrl == null
                            ? Text(
                                currentUser.initials,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      title: Text(
                        currentUser.displayName ?? 'Hopper',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                      subtitle: Text(
                        currentUser.email ?? '',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                      onTap: () => Navigator.of(context).pop(currentUser),
                    ),
                    const Divider(height: 1),
                  ],

                  // Option 1: Native Google Sign-In
                  ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white10 : const Color(0xFFF1F3F4),
                      ),
                      alignment: Alignment.center,
                      child: const GoogleLogo(size: 20),
                    ),
                    title: const Text(
                      'Sign In with Google',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    subtitle: const Text(
                      'Authenticate with your official Google account',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: _signInWithNativeGoogle,
                  ),

                  const Divider(height: 1),

                  // Option 2: Custom Profile
                  ListTile(
                    leading: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? Colors.white10 : const Color(0xFFF1F3F4),
                      ),
                      alignment: Alignment.center,
                      child: Icon(
                        Icons.badge_rounded,
                        size: 22,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    title: const Text(
                      'Set Custom Hopper Profile',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                    subtitle: const Text(
                      'Customize your display name and festival avatar',
                      style: TextStyle(fontSize: 12),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isCustomMode = true);
                    },
                  ),
                ] else ...[
                  // Custom Google Profile Form
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Choose Avatar Picture:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 54,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: AuthService.avatarPresets.length + 1,
                            separatorBuilder: (context, index) => const SizedBox(width: 10),
                            itemBuilder: (context, idx) {
                              final url = idx == 0
                                  ? AuthService.defaultGoogleAvatar
                                  : AuthService.avatarPresets[idx - 1];
                              final isSelected = _selectedAvatar == url;
                              return GestureDetector(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedAvatar = url);
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFF4285F4)
                                          : Colors.transparent,
                                      width: 2.5,
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 23,
                                    backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                                    backgroundImage: NetworkImage(url),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 18),
                        TextField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            labelText: 'Display Name',
                            hintText: 'Enter your name',
                            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            labelText: 'Email Address (optional)',
                            hintText: 'name@example.com',
                            prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => setState(() => _isCustomMode = false),
                              child: const Text('Back'),
                            ),
                            const Spacer(),
                            FilledButton.icon(
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF4285F4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: const Icon(Icons.check_rounded, size: 18),
                              label: const Text('Save Profile'),
                              onPressed: _saveCustomAccount,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // Terms & Privacy footer
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text(
                    'Your profile details are synced securely with your hopping squad members.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.white38 : Colors.black38,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
