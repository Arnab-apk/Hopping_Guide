import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../repositories/local_pandal_repository.dart';
import '../services/custom_hopping_trail_service.dart';
import '../services/location_service.dart';
import '../utils/responsive.dart';

/// Interactive modal dialog allowing users to specify their starting location,
/// hopping style, time budget, and travel mode to generate a custom itinerary.
class CustomTrailPlannerDialog extends StatefulWidget {
  const CustomTrailPlannerDialog({
    super.key,
    this.initialLocation,
    this.initialLocationLabel,
    this.onTrailStarted,
  });

  final LatLng? initialLocation;
  final String? initialLocationLabel;
  final VoidCallback? onTrailStarted;

  static Future<void> show(
    BuildContext context, {
    LatLng? initialLocation,
    String? initialLocationLabel,
    VoidCallback? onTrailStarted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomTrailPlannerDialog(
        initialLocation: initialLocation,
        initialLocationLabel: initialLocationLabel,
        onTrailStarted: onTrailStarted,
      ),
    );
  }

  @override
  State<CustomTrailPlannerDialog> createState() => _CustomTrailPlannerDialogState();
}

class _CustomTrailPlannerDialogState extends State<CustomTrailPlannerDialog> {
  final LocalAssetPandalRepository _repo = LocalAssetPandalRepository();

  List<Pandal> _allPandals = [];
  bool _isLoadingPandals = true;

  // Selected Preferences
  late LatLng _selectedLocation;
  late String _selectedLocationLabel;
  HoppingStyle _selectedStyle = HoppingStyle.heritage;
  int _selectedTimeMinutes = 120; // 2 hours default
  HoppingTransitMode _selectedTransit = HoppingTransitMode.walking;

  // Preview generated trail
  ActiveCustomTrail? _previewTrail;
  bool _isGenerating = false;

  // Popular Kolkata Starting Hubs
  static const List<Map<String, dynamic>> _popularHubs = [
    {'name': 'Shyambazar / Hatibagan', 'lat': 22.5995, 'lng': 88.3712},
    {'name': 'College Street / Central', 'lat': 22.5744, 'lng': 88.3629},
    {'name': 'Gariahat / South Kolkata', 'lat': 22.5186, 'lng': 88.3653},
    {'name': 'Salt Lake / FD Block', 'lat': 22.5867, 'lng': 88.4178},
    {'name': 'Behala / Taratala', 'lat': 22.4988, 'lng': 88.3182},
    {'name': 'Dum Dum Park / Lake Town', 'lat': 22.6072, 'lng': 88.4068},
  ];

  @override
  void initState() {
    super.initState();
    final livePos = LocationService.instance.currentPositionSync;
    if (widget.initialLocation != null) {
      _selectedLocation = widget.initialLocation!;
      _selectedLocationLabel = widget.initialLocationLabel ?? 'Selected Map Point';
    } else if (livePos != null) {
      _selectedLocation = LatLng(livePos.latitude, livePos.longitude);
      _selectedLocationLabel = 'Current GPS Location';
    } else {
      _selectedLocation = LocationService.defaultKolkataCenter;
      _selectedLocationLabel = 'Central Kolkata';
    }

    _loadPandals();
  }

  Future<void> _loadPandals() async {
    try {
      final list = await _repo.all();
      if (mounted) {
        setState(() {
          _allPandals = list;
          _isLoadingPandals = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingPandals = false);
    }
  }

  void _generateTrail() {
    if (_allPandals.isEmpty) return;
    HapticFeedback.mediumImpact();
    setState(() => _isGenerating = true);

    final trail = CustomHoppingTrailService.instance.generateTrail(
      startPos: _selectedLocation,
      startLabel: _selectedLocationLabel,
      style: _selectedStyle,
      timeBudgetMinutes: _selectedTimeMinutes,
      transitMode: _selectedTransit,
      allPandals: _allPandals,
    );

    setState(() {
      _previewTrail = trail;
      _isGenerating = false;
    });
  }

  Future<void> _startActiveTrail() async {
    if (_previewTrail == null) return;
    HapticFeedback.heavyImpact();

    await CustomHoppingTrailService.instance.startTrail(_previewTrail!);

    if (mounted) {
      Navigator.of(context).pop();
      widget.onTrailStarted?.call();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: PujaColors.durgaRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          content: Row(
            children: [
              const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '🚀 Hopping Trail Started! Auto-Visit active within 80m.',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191A22) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4.5,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: PujaColors.festivalGold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: PujaColors.festivalGold.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: PujaColors.festivalGold,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _previewTrail != null
                            ? 'Generated Hopping Trail'
                            : 'AI Hopping Trail Planner',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: context.dynamicFont(17),
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        _previewTrail != null
                            ? '${_previewTrail!.totalStops} best pandals curated for your time'
                            : 'Personalized route based on time & vibe',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: context.dynamicFont(12),
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // Body Content (Wizard vs Preview)
          Expanded(
            child: _isLoadingPandals
                ? const Center(
                    child: CircularProgressIndicator(color: PujaColors.durgaRed),
                  )
                : (_previewTrail != null ? _buildPreviewView(isDark) : _buildPlannerForm(isDark)),
          ),

          // Footer Action
          _buildBottomAction(isDark),
        ],
      ),
    );
  }

  /// The interactive question form
  Widget _buildPlannerForm(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Starting Location
          _buildSectionHeader(
            icon: Icons.my_location_rounded,
            title: 'Starting Point',
            subtitle: _selectedLocationLabel,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF232430) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: PujaColors.festivalGold.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on_rounded, color: Color(0xFFFF1744), size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _selectedLocationLabel,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                PopupMenuButton<Map<String, dynamic>>(
                  tooltip: 'Change Starting Hub',
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  itemBuilder: (ctx) => _popularHubs
                      .map(
                        (hub) => PopupMenuItem(
                          value: hub,
                          child: Text(
                            hub['name'] as String,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13),
                          ),
                        ),
                      )
                      .toList(),
                  onSelected: (hub) {
                    setState(() {
                      _selectedLocation = LatLng(
                        hub['lat'] as double,
                        hub['lng'] as double,
                      );
                      _selectedLocationLabel = hub['name'] as String;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 2. Hopping Style / Vibe
          _buildSectionHeader(
            icon: Icons.palette_outlined,
            title: 'Hopping Style & Vibe',
            subtitle: 'What kind of pandals do you want to experience?',
          ),
          const SizedBox(height: 10),
          ...HoppingStyle.values.map((style) {
            final isSelected = _selectedStyle == style;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _selectedStyle = style);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? (isDark
                            ? PujaColors.durgaRed.withValues(alpha: 0.22)
                            : PujaColors.durgaRed.withValues(alpha: 0.08))
                        : (isDark ? const Color(0xFF22232E) : Colors.grey.shade50),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? PujaColors.durgaRed
                          : (isDark ? Colors.white10 : Colors.black12),
                      width: isSelected ? 1.8 : 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        style.iconEmoji,
                        style: const TextStyle(fontSize: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${style.title} (${style.bengaliTitle})',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13.5,
                                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                color: isSelected
                                    ? PujaColors.durgaRed
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              style.description,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle_rounded,
                          color: PujaColors.durgaRed,
                          size: 20,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),

          // 3. Time in Hand
          _buildSectionHeader(
            icon: Icons.timer_outlined,
            title: 'Time in Hand',
            subtitle: 'How many hours can you dedicate today?',
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildTimeChip(label: '1 Hour', minutes: 60, subtitle: '2-3 stops'),
              const SizedBox(width: 8),
              _buildTimeChip(label: '2 Hours', minutes: 120, subtitle: '4-5 stops'),
              const SizedBox(width: 8),
              _buildTimeChip(label: '3 Hours', minutes: 180, subtitle: '6-7 stops'),
              const SizedBox(width: 8),
              _buildTimeChip(label: '5 Hours', minutes: 300, subtitle: 'Grand Tour'),
            ],
          ),
          const SizedBox(height: 20),

          // 4. Transit Preference
          _buildSectionHeader(
            icon: Icons.directions_walk_rounded,
            title: 'Travel Preference',
            subtitle: 'How will you navigate between pandals?',
          ),
          const SizedBox(height: 10),
          Row(
            children: HoppingTransitMode.values.map((mode) {
              final isSel = _selectedTransit == mode;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(mode.label),
                    selected: isSel,
                    onSelected: (val) {
                      if (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedTransit = mode);
                      }
                    },
                    selectedColor: PujaColors.festivalGold.withValues(alpha: 0.22),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                      color: isSel
                          ? PujaColors.festivalGold
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip({required String label, required int minutes, required String subtitle}) {
    final isSel = _selectedTimeMinutes == minutes;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTimeMinutes = minutes);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSel
                ? PujaColors.festivalGold.withValues(alpha: 0.2)
                : (isDark ? const Color(0xFF22232E) : Colors.grey.shade100),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSel ? PujaColors.festivalGold : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                  color: isSel ? PujaColors.festivalGold : (isDark ? Colors.white : Colors.black87),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  color: isDark ? Colors.white54 : Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Itinerary preview after generation
  Widget _buildPreviewView(bool isDark) {
    final trail = _previewTrail!;

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // Summary Metrics Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF2A2234), const Color(0xFF1E1F29)]
                  : [PujaColors.festivalGold.withValues(alpha: 0.15), Colors.white],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: PujaColors.festivalGold.withValues(alpha: 0.4),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricItem(
                icon: Icons.temple_hindu_rounded,
                value: '${trail.totalStops}',
                label: 'Pandals',
              ),
              Container(width: 1, height: 28, color: Colors.white24),
              _buildMetricItem(
                icon: Icons.access_time_rounded,
                value: '~${trail.totalEstimatedMinutes}m',
                label: 'Estimated',
              ),
              Container(width: 1, height: 28, color: Colors.white24),
              _buildMetricItem(
                icon: Icons.route_rounded,
                value: '${trail.totalDistanceKm} km',
                label: 'Distance',
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Text(
          'Your Optimized Pandal Sequence:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),

        // Timeline of stops
        ...List.generate(trail.stops.length, (index) {
          final pandal = trail.stops[index];
          final isLast = index == trail.stops.length - 1;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Milestone Line & Number badge
              Column(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: index == 0 ? PujaColors.durgaRed : PujaColors.festivalGold,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (index == 0 ? PujaColors.durgaRed : PujaColors.festivalGold)
                              .withValues(alpha: 0.3),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        color: index == 0 ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 52,
                      color: PujaColors.festivalGold.withValues(alpha: 0.35),
                    ),
                ],
              ),
              const SizedBox(width: 12),

              // Pandal details card
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF22232F) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark ? Colors.white10 : Colors.black12,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                pandal.name,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                            if (pandal.rating != null) ...[
                              const Icon(Icons.star_rounded, size: 14, color: PujaColors.festivalGold),
                              const SizedBox(width: 2),
                              Text(
                                '${pandal.rating}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11.5,
                                  color: PujaColors.festivalGold,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              pandal.area ?? pandal.zoneLabel,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
                            ),
                            if (pandal.theme.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: PujaColors.festivalGold.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  pandal.theme,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: PujaColors.festivalGold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }),

        // Auto-visit info note
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFF1744).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFF1744).withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, color: Color(0xFFFF1744), size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Auto-Visit will automatically check you into each pandal when you are within 80m, advancing your progress in the notification bar.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem({required IconData icon, required String value, required String label}) {
    return Column(
      children: [
        Icon(icon, size: 18, color: PujaColors.festivalGold),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10.5,
            color: Colors.white60,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: PujaColors.festivalGold),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomAction(bool isDark) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 10, 20, MediaQuery.of(context).padding.bottom + 12),
      child: _previewTrail != null
          ? Row(
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => setState(() => _previewTrail = null),
                  child: const Text('Edit Choices'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF1744),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 22),
                    label: Text(
                      'Start Hopping Trail',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    onPressed: _startActiveTrail,
                  ),
                ),
              ],
            )
          : SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: PujaColors.durgaRed,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: _isGenerating
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.auto_awesome_rounded, size: 20),
                label: Text(
                  _isGenerating ? 'Curating Optimal Route...' : 'Generate My Custom Trail',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                onPressed: _isGenerating ? null : _generateTrail,
              ),
            ),
    );
  }
}
