import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

/// A keyboard-safe editor with inline validation, polished Material 3 styling, and an awaited save state.
class AppTextEditDialog extends StatefulWidget {
  const AppTextEditDialog({
    super.key,
    required this.title,
    required this.label,
    required this.initialValue,
    required this.onSave,
    this.hint,
    this.description,
    this.keyboardType = TextInputType.text,
    this.allowEmpty = false,
    this.maxLength = 80,
    this.validator,
  });
  final String title, label, initialValue;
  final String? hint, description;
  final TextInputType keyboardType;
  final bool allowEmpty;
  final int maxLength;
  final String? Function(String)? validator;
  final FutureOr<void> Function(String) onSave;

  @override
  State<AppTextEditDialog> createState() => _AppTextEditDialogState();
}

class _AppTextEditDialogState extends State<AppTextEditDialog> {
  late final _controller = TextEditingController(text: widget.initialValue);
  final _form = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    HapticFeedback.lightImpact();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_controller.text.trim());
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error = 'Could not save. Check your connection and try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
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
                Icons.edit_rounded,
                size: 20,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.title,
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
              if (widget.description != null) ...[
                Text(
                  widget.description!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13.5,
                    height: 1.45,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _controller,
                autofocus: true,
                enabled: !_saving,
                keyboardType: widget.keyboardType,
                textInputAction: TextInputAction.done,
                maxLength: widget.maxLength,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
                onFieldSubmitted: (_) => _save(),
                decoration: InputDecoration(
                  labelText: widget.label,
                  hintText: widget.hint,
                  counterStyle: GoogleFonts.plusJakartaSans(fontSize: 11),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty && !widget.allowEmpty) {
                    return 'Enter ${widget.label.toLowerCase()}.';
                  }
                  return widget.validator?.call(text);
                },
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
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
                    Navigator.of(context).pop(false);
                  },
            child: const Text('Cancel'),
          ),
          if (widget.allowEmpty && widget.initialValue.isNotEmpty)
            TextButton(
              onPressed: _saving
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      _controller.clear();
                      _save();
                    },
              child: const Text('Clear'),
            ),
          FilledButton(
            onPressed: _saving ? null : _save,
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
                : const Text('Save'),
          ),
        ],
      ),
    );
  }
}
