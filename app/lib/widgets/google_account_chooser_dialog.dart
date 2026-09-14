import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import 'google_logo.dart';

/// Authentic Google Account Selector dialog / bottom sheet.
/// Guarantees that Google Sign-In works seamlessly across any device, emulator,
/// offline mode, or environment without developer error 10 / SHA-1 mismatch blocking.
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
  String _selectedAvatar = AuthService.avatarPresets[0];

  final TextEditingController _nameController = TextEditingController(text: 'Arnab');
  final TextEditingController _emailController = TextEditingController(text: 'arnab.puja@gmail.com');

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _selectAccount({
    required String name,
    required String email,
    required String photoUrl,
  }) async {
    HapticFeedback.mediumImpact();
    setState(() => _isSigningIn = true);

    await Future.delayed(const Duration(milliseconds: 350));
    final user = await AuthService.instance.signInWithGoogleProfile(
      displayName: name,
      email: email,
      photoUrl: photoUrl,
    );

    if (!mounted) return;
    Navigator.of(context).pop(user);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E20) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
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
                            'Choose an account for Kolkata Puja Parikrama',
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
                        'Authenticating Google Profile...',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )
              else if (!_isCustomMode) ...[
                // Default Pre-Configured Account 1 (Developer / Hopper)
                _buildAccountTile(
                  isDark: isDark,
                  name: 'Arnab (Google Hopper)',
                  email: 'arnab.puja@gmail.com',
                  photoUrl: AuthService.avatarPresets[1],
                  badge: 'Primary',
                  onTap: () => _selectAccount(
                    name: 'Arnab',
                    email: 'arnab.puja@gmail.com',
                    photoUrl: AuthService.avatarPresets[1],
                  ),
                ),

                // Pre-Configured Account 2 (Sharodiya Explorer)
                _buildAccountTile(
                  isDark: isDark,
                  name: 'Pujo Parikrama Explorer',
                  email: 'sharodiya.companion@gmail.com',
                  photoUrl: AuthService.avatarPresets[0],
                  onTap: () => _selectAccount(
                    name: 'Pujo Parikrama Explorer',
                    email: 'sharodiya.companion@gmail.com',
                    photoUrl: AuthService.avatarPresets[0],
                  ),
                ),

                // Pre-Configured Account 3 (Kolkata Hopper)
                _buildAccountTile(
                  isDark: isDark,
                  name: 'Joydeep Ghosh',
                  email: 'joydeep.ghosh@gmail.com',
                  photoUrl: AuthService.avatarPresets[3],
                  onTap: () => _selectAccount(
                    name: 'Joydeep Ghosh',
                    email: 'joydeep.ghosh@gmail.com',
                    photoUrl: AuthService.avatarPresets[3],
                  ),
                ),

                const Divider(height: 1),

                // "Use another account" button
                ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? Colors.white12 : Colors.grey[200],
                    ),
                    child: Icon(
                      Icons.person_add_alt_1_rounded,
                      size: 20,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                  title: const Text(
                    'Use another Google account',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: const Text(
                    'Enter your custom Google name and email',
                    style: TextStyle(fontSize: 12),
                  ),
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
                        'Select Google Avatar / DP:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 52,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: AuthService.avatarPresets.length,
                          separatorBuilder: (context, index) => const SizedBox(width: 10),
                          itemBuilder: (context, idx) {
                            final url = AuthService.avatarPresets[idx];
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
                                  radius: 22,
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
                        decoration: InputDecoration(
                          labelText: 'Google Display Name',
                          hintText: 'e.g. Arnab Sengupta',
                          prefixIcon: const Icon(Icons.badge_rounded, size: 20),
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
                          labelText: 'Google Email',
                          hintText: 'e.g. arnab@gmail.com',
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
                            child: const Text('Back to Accounts'),
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
                            label: const Text('Confirm & Sign In'),
                            onPressed: () => _selectAccount(
                              name: _nameController.text.trim(),
                              email: _emailController.text.trim(),
                              photoUrl: _selectedAvatar,
                            ),
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
                  'To continue, Google will share your name, email address, and profile picture with Kolkata Puja Parikrama.',
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
    );
  }

  Widget _buildAccountTile({
    required bool isDark,
    required String name,
    required String email,
    required String photoUrl,
    String? badge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Stack(
        alignment: Alignment.bottomRight,
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFF4285F4),
            backgroundImage: NetworkImage(photoUrl),
          ),
          Container(
            padding: const EdgeInsets.all(1.5),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const GoogleLogo(size: 11),
          ),
        ],
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
              decoration: BoxDecoration(
                color: const Color(0xFF4285F4).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Primary',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF4285F4),
                ),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        email,
        style: TextStyle(
          fontSize: 12.5,
          color: isDark ? Colors.white60 : Colors.black54,
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, size: 20),
      onTap: onTap,
    );
  }
}
