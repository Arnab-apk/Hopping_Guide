import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';
import '../repositories/supplementary_repository.dart';
import '../utils/responsive.dart';
import '../widgets/puja_icons.dart';

/// Material 3 Emergency & Safety Screen matching Google application aesthetics.
class HelplinesScreen extends StatefulWidget {
  const HelplinesScreen({super.key});

  @override
  State<HelplinesScreen> createState() => _HelplinesScreenState();
}

class _HelplinesScreenState extends State<HelplinesScreen> {
  final SupplementaryRepository _repo = SupplementaryRepository();
  List<Helpline> _helplines = [];
  List<SafetyGuide> _guides = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final results = await Future.wait([
      _repo.getHelplines(),
      _repo.getSafetyGuides(),
    ]);
    if (!mounted) return;
    setState(() {
      _helplines = results[0] as List<Helpline>;
      _guides = results[1] as List<SafetyGuide>;
      _isLoading = false;
    });
  }

  Future<void> _callNumber(String number) async {
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot initiate call to $number')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency & Safety'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Alert Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colorScheme.secondaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: PujaIcon.trishulDiya(color: colorScheme.onSecondaryContainer, size: 28),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Kolkata Emergency Services',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: context.dynamicFont(14),
                                fontWeight: FontWeight.w700,
                                color: colorScheme.onSurface,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '100% Offline Accessible & Toll-Free',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: context.dynamicFont(12),
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                Text(
                  'Direct Helplines',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: context.dynamicFont(17),
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                ..._helplines.map((h) => _buildHelplineCard(h, isDark, colorScheme)),

                const SizedBox(height: 24),

                Text(
                  'Festival Medical & Crowd First-Aid',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: context.dynamicFont(17),
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 10),

                ..._guides.map((g) => _buildSafetyCard(g, isDark, colorScheme)),
              ],
            ),
    );
  }

  Widget _buildHelplineCard(Helpline h, bool isDark, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6),
          width: 1.0,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: _getHelplineIcon(h.label, colorScheme.onSecondaryContainer),
        ),
        title: Text(
          h.label,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: context.dynamicFont(14.5),
            color: colorScheme.onSurface,
          ),
        ),
        subtitle: Text(
          'Dial ${h.number}',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w500,
            fontSize: context.dynamicFont(13),
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: FilledButton(
          onPressed: () {
            HapticFeedback.heavyImpact();
            _callNumber(h.number);
          },
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
          child: Text(
            'Call',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, fontSize: context.dynamicFont(13)),
          ),
        ),
      ),
    );
  }

  Widget _getHelplineIcon(String label, Color color) {
    final lower = label.toLowerCase();
    if (lower.contains('police')) {
      return PujaIcon.gada(color: color, size: 30);
    } else if (lower.contains('fire')) {
      return PujaIcon.trishulDiya(color: color, size: 30);
    } else if (lower.contains('women')) {
      return PujaIcon.ashtabhujaDevi(color: color, size: 30);
    } else if (lower.contains('medical') || lower.contains('ambulance')) {
      return PujaIcon.kalash(color: color, size: 30);
    } else {
      return PujaIcon.shankha(color: color, size: 30);
    }
  }

  Widget _getSafetyGuideIcon(String title, Color color, double size) {
    final lower = title.toLowerCase();
    if (lower.contains('heat')) {
      return PujaIcon.kalash(color: color, size: size);
    } else if (lower.contains('faint')) {
      return PujaIcon.durgaEyes(color: color, size: size);
    } else if (lower.contains('burn')) {
      return PujaIcon.trishulDiya(color: color, size: size);
    } else {
      return PujaIcon.trishulEyes(color: color, size: size);
    }
  }

  Widget _buildSafetyCard(SafetyGuide guide, bool isDark, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6),
          width: 1.0,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _getSafetyGuideIcon(guide.title, PujaColors.crowdLow, context.dynamicIcon(26)),
                const SizedBox(width: 8),
                Text(
                  guide.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: context.dynamicFont(15.5),
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...guide.content.map(
              (step) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: TextStyle(fontWeight: FontWeight.w800, color: colorScheme.onSurfaceVariant)),
                    Expanded(
                      child: Text(
                        step,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: context.dynamicFont(13),
                          color: isDark ? Colors.white70 : Colors.black87,
                          height: 1.4,
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
    );
  }
}
