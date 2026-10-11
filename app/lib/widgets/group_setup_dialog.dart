import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/squad_service.dart';
import '../services/location_service.dart';
import 'package:permission_handler/permission_handler.dart';

/// Polished Material 3 dialog for creating or joining a Durga Puja hopping group.
class GroupSetupDialog extends StatefulWidget {
  const GroupSetupDialog({
    super.key,
    required this.service,
    this.join = false,
  });

  final SquadService service;
  final bool join;

  @override
  State<GroupSetupDialog> createState() => _GroupSetupDialogState();
}

class _GroupSetupDialogState extends State<GroupSetupDialog> {
  final _name = TextEditingController();
  final _landmark = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _landmark.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_form.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      if (!LocationService.enableTestMode) {
        await LocationService.requestLocationPermission();
        await [Permission.notification, Permission.microphone, Permission.camera].request();
      }
      var success = false;
      if (widget.join) {
        success = await widget.service.joinSquad(_name.text.trim().toUpperCase());
      } else {
        await widget.service.createSquad(
          _name.text.trim(),
          _landmark.text.trim().isEmpty ? 'Kolkata Central' : _landmark.text.trim(),
        );
        success = widget.service.squadCode != null && widget.service.lastError == null;
      }

      if (!mounted) return;
      if (success) {
        Navigator.pop(context, true);
      } else {
        setState(() {
          _error = widget.service.lastError ??
              (widget.join
                  ? 'Could not join group. Please check the code and try again.'
                  : 'Could not create group. Please try again.');
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not connect. Please check your internet and retry.';
        });
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        scrollable: true,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.6),
            width: 1,
          ),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        actionsPadding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.join ? Icons.group_add_rounded : Icons.groups_rounded,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.join ? 'Join Hopping Group' : 'Create Hopping Group',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        content: Form(
          key: _form,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.join
                    ? 'Enter the 8-character invite code shared by your companions.'
                    : 'Set a recognizable name and starting landmark for your hopping companions.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                autofocus: true,
                enabled: !_saving,
                maxLength: widget.join ? 32 : 80,
                textCapitalization: widget.join
                    ? TextCapitalization.characters
                    : TextCapitalization.words,
                textInputAction:
                    widget.join ? TextInputAction.done : TextInputAction.next,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: widget.join ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: widget.join ? 1.2 : 0.1,
                  color: theme.colorScheme.onSurface,
                ),
                onFieldSubmitted: widget.join ? (_) => _submit() : null,
                validator: (value) => value == null || value.trim().isEmpty
                    ? (widget.join
                        ? 'Enter the group invite code.'
                        : 'Enter a group name.')
                    : null,
                decoration: InputDecoration(
                  prefixIcon: Icon(
                    widget.join ? Icons.vpn_key_rounded : Icons.badge_outlined,
                    size: 20,
                  ),
                  labelText: widget.join ? 'Enter Group Code' : 'Group Name',
                  hintText: widget.join
                      ? 'e.g. PUJAX4K9'
                      : 'e.g. Bagbazar Pandal Crawlers',
                  counterStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
                ),
              ),
              if (!widget.join) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _landmark,
                  enabled: !_saving,
                  maxLength: 120,
                  textInputAction: TextInputAction.done,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface,
                  ),
                  onFieldSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.place_outlined, size: 20),
                    labelText: 'Meet-up Landmark',
                    hintText: 'e.g. Near Hatibagan Crossing',
                    counterStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
                  ),
                ),
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Semantics(
                    liveRegion: true,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 16,
                          color: theme.colorScheme.error,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _error!,
                            style: GoogleFonts.plusJakartaSans(
                              color: theme.colorScheme.error,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                  },
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(widget.join ? 'Join Group' : 'Create Group'),
          ),
        ],
      ),
    );
  }
}
