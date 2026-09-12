import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';
import '../repositories/supplementary_repository.dart';
import '../utils/responsive.dart';

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
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency & Safety'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PujaColors.durgaRed))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header Alert Banner
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: PujaColors.crimsonVelvet.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: PujaColors.festivalGold.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.health_and_safety, color: PujaColors.festivalGold, size: context.dynamicIcon(28)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Kolkata Emergency Services (100% Offline Accessible)',
                          style: TextStyle(
                            fontSize: context.dynamicFont(14),
                            fontWeight: FontWeight.w800,
                            color: isDark ? PujaColors.goldBright : PujaColors.crimsonVelvet,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Direct Helplines',
                  style: TextStyle(fontSize: context.dynamicFont(18), fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),

                ..._helplines.map((h) => _buildHelplineCard(h, isDark)),

                const SizedBox(height: 24),

                Text(
                  'Festival Medical & Crowd First-Aid',
                  style: TextStyle(fontSize: context.dynamicFont(18), fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),

                ..._guides.map((g) => _buildSafetyCard(g, isDark)),
              ],
            ),
    );
  }

  Widget _buildHelplineCard(Helpline h, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: PujaColors.festivalGold.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: PujaColors.crimsonVelvet.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: PujaColors.festivalGold.withValues(alpha: 0.3),
            ),
          ),
          child: Icon(Icons.phone, color: PujaColors.festivalGold, size: context.dynamicIcon(20)),
        ),
        title: Text(
          h.label,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: context.dynamicFont(15)),
        ),
        subtitle: Text(
          'Dial ${h.number}',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: context.dynamicFont(13)),
        ),
        trailing: ElevatedButton(
          onPressed: () {
            HapticFeedback.heavyImpact();
            _callNumber(h.number);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: PujaColors.crimsonVelvet,
            foregroundColor: PujaColors.goldBright,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: PujaColors.festivalGold.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Text('Call', style: TextStyle(fontWeight: FontWeight.w800, fontSize: context.dynamicFont(13))),
        ),
      ),
    );
  }

  Widget _buildSafetyCard(SafetyGuide guide, bool isDark) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services_outlined, size: context.dynamicIcon(18), color: PujaColors.crowdLow),
                const SizedBox(width: 8),
                Text(
                  guide.title,
                  style: TextStyle(fontSize: context.dynamicFont(16), fontWeight: FontWeight.w800),
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
                    const Text('• ', style: TextStyle(fontWeight: FontWeight.w800)),
                    Expanded(
                      child: Text(
                        step,
                        style: TextStyle(
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
