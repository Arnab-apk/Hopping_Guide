import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../repositories/local_pandal_repository.dart';
import '../services/custom_hopping_trail_service.dart';
import '../services/location_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';

enum _BuilderStep {
  startingPoint,
  choosePandals,
  review,
}

/// Interactive 3-step modal dialog allowing users to:
/// 1. Choose Starting Point (Live GPS location or popular Kolkata hubs)
/// 2. Pick specific pandals from a searchable list
/// 3. Review & generate the shortest Hamiltonian path via on-device Held-Karp optimization
class CustomTrailPlannerDialog extends StatefulWidget {
  const CustomTrailPlannerDialog({
    super.key,
    this.initialLocation,
    this.initialLocationLabel,
    this.pandals,
    this.onTrailStarted,
  });

  final LatLng? initialLocation;
  final String? initialLocationLabel;
  final List<Pandal>? pandals;
  final VoidCallback? onTrailStarted;

  static Future<void> show(
    BuildContext context, {
    LatLng? initialLocation,
    String? initialLocationLabel,
    List<Pandal>? pandals,
    VoidCallback? onTrailStarted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomTrailPlannerDialog(
        initialLocation: initialLocation,
        initialLocationLabel: initialLocationLabel,
        pandals: pandals,
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

  _BuilderStep _currentStep = _BuilderStep.startingPoint;

  // Step 1: Selected Starting Point
  late LatLng _selectedLocation;
  late String _selectedLocationLabel;
  bool _useLiveGps = true;

  // Step 2: Selected Pandals
  final Set<String> _selectedPandalIds = <String>{};
  String _searchQuery = '';
  KolkataZone? _selectedZoneFilter;
  final TextEditingController _searchController = TextEditingController();

  // Step 3: Generating state
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
      _useLiveGps = false;
    } else if (livePos != null) {
      _selectedLocation = LatLng(livePos.latitude, livePos.longitude);
      _selectedLocationLabel = 'My Live Location';
      _useLiveGps = true;
    } else {
      _selectedLocation = LocationService.defaultKolkataCenter;
      _selectedLocationLabel = 'Shyambazar / Hatibagan';
      _useLiveGps = false;
    }

    if (widget.pandals != null && widget.pandals!.isNotEmpty) {
      _allPandals = widget.pandals!;
      _isLoadingPandals = false;
    } else {
      _loadPandals();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  List<Pandal> get _filteredPandals {
    return _allPandals.where((p) {
      if (_selectedZoneFilter != null && p.zone != _selectedZoneFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final nameMatch = p.name.toLowerCase().contains(q);
        final areaMatch = p.area?.toLowerCase().contains(q) ?? false;
        final themeMatch = p.theme.toLowerCase().contains(q);
        if (!nameMatch && !areaMatch && !themeMatch) return false;
      }
      return true;
    }).toList();
  }

  List<Pandal> get _selectedPandalsList {
    return _allPandals.where((p) => _selectedPandalIds.contains(p.id)).toList();
  }

  void _togglePandalSelection(String pandalId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedPandalIds.contains(pandalId)) {
        _selectedPandalIds.remove(pandalId);
      } else {
        _selectedPandalIds.add(pandalId);
      }
    });
  }

  Future<void> _generateAndStartTrail() async {
    final selectedList = _selectedPandalsList;
    if (selectedList.length < 2) return;

    HapticFeedback.heavyImpact();
    setState(() => _isGenerating = true);

    ActiveCustomTrail? trail;
    try {
      // Run deterministic on-device route optimization (Held-Karp dynamic programming)
      trail = CustomHoppingTrailService.instance.generateOptimizedTrail(
        startPos: _selectedLocation,
        startLabel: _selectedLocationLabel,
        selectedPandals: selectedList,
      );

      await CustomHoppingTrailService.instance.startTrail(trail);
    } catch (e) {
      debugPrint('Error starting custom trail: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
      widget.onTrailStarted?.call();
      final totalStops = trail?.totalStops ?? selectedList.length;
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
                  '🗺️ Custom Trail Started! $totalStops stops ordered for shortest path.',
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

          // Header Bar
          _buildHeader(isDark),

          const Divider(height: 1),

          // Step Content
          Expanded(
            child: _isLoadingPandals
                ? const Center(
                    child: CircularProgressIndicator(color: PujaColors.durgaRed),
                  )
                : _buildCurrentStepView(isDark),
          ),

          // Sticky Bottom Bar
          _buildStickyBottomBar(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    String stepTitle;
    String stepSubtitle;

    switch (_currentStep) {
      case _BuilderStep.startingPoint:
        stepTitle = 'Step 1: Starting Point';
        stepSubtitle = 'Choose where your hopping trail begins';
        break;
      case _BuilderStep.choosePandals:
        stepTitle = 'Step 2: Choose Pandals';
        stepSubtitle = '${_selectedPandalIds.length} selected (pick at least 2)';
        break;
      case _BuilderStep.review:
        stepTitle = 'Step 3: Review & Generate';
        stepSubtitle = 'Confirm your stops and calculate shortest path';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
              Icons.route_rounded,
              color: PujaColors.festivalGold,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Custom Trail Builder',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: context.dynamicFont(16.5),
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
                Text(
                  '$stepTitle • $stepSubtitle',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: context.dynamicFont(11.5),
                    color: isDark ? Colors.white60 : Colors.black54,
                    fontWeight: FontWeight.w500,
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
    );
  }

  Widget _buildCurrentStepView(bool isDark) {
    switch (_currentStep) {
      case _BuilderStep.startingPoint:
        return _buildStep1StartingPoint(isDark);
      case _BuilderStep.choosePandals:
        return _buildStep2ChoosePandals(isDark);
      case _BuilderStep.review:
        return _buildStep3Review(isDark);
    }
  }

  // ==========================================
  // STEP 1: STARTING POINT
  // ==========================================
  Widget _buildStep1StartingPoint(bool isDark) {
    final livePos = LocationService.instance.currentPositionSync;

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        Text(
          'Where will you start your puja walk?',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'We optimize your route starting from this location through your chosen pandals.',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            color: isDark ? Colors.white60 : Colors.black54,
          ),
        ),
        const SizedBox(height: 18),

        // Live Location Option
        InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            HapticFeedback.selectionClick();
            if (livePos != null) {
              setState(() {
                _useLiveGps = true;
                _selectedLocation = LatLng(livePos.latitude, livePos.longitude);
                _selectedLocationLabel = 'My Live Location';
              });
            } else {
              setState(() {
                _useLiveGps = true;
                _selectedLocationLabel = 'My Live Location';
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _useLiveGps
                  ? PujaColors.festivalGold.withValues(alpha: isDark ? 0.18 : 0.12)
                  : (isDark ? const Color(0xFF232430) : Colors.grey.shade50),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _useLiveGps
                    ? PujaColors.festivalGold
                    : (isDark ? Colors.white10 : Colors.black12),
                width: _useLiveGps ? 2.0 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: Color(0xFF2979FF),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'My Live Location',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        livePos != null
                            ? 'GPS coordinates active • Direct starting leg'
                            : 'Uses live GPS when walking starts',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: isDark ? Colors.white54 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_useLiveGps)
                  const Icon(
                    Icons.check_circle_rounded,
                    color: PujaColors.festivalGold,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        Text(
          'Or select a popular Kolkata hub:',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 10),

        // Popular Hubs
        ...List.generate(_popularHubs.length, (idx) {
          final hub = _popularHubs[idx];
          final isSelected = !_useLiveGps && _selectedLocationLabel == hub['name'];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _useLiveGps = false;
                  _selectedLocation = LatLng(
                    hub['lat'] as double,
                    hub['lng'] as double,
                  );
                  _selectedLocationLabel = hub['name'] as String;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? PujaColors.durgaRed.withValues(alpha: isDark ? 0.18 : 0.08)
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
                    Icon(
                      Icons.place_rounded,
                      size: 20,
                      color: isSelected
                          ? PujaColors.durgaRed
                          : (isDark ? Colors.white54 : Colors.black45),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        hub['name'] as String,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13.5,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? PujaColors.durgaRed
                              : (isDark ? Colors.white : Colors.black87),
                        ),
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
      ],
    );
  }

  // ==========================================
  // STEP 2: CHOOSE PANDALS
  // ==========================================
  Widget _buildStep2ChoosePandals(bool isDark) {
    final filtered = _filteredPandals;

    return Column(
      children: [
        // Top start point badge
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF242533) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: PujaColors.festivalGold.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.my_location_rounded, size: 16, color: PujaColors.festivalGold),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Starting from: $_selectedLocationLabel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: () => setState(() => _currentStep = _BuilderStep.startingPoint),
                child: Text(
                  'Change',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: PujaColors.durgaRed,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Search Bar
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            controller: _searchController,
            onChanged: (val) => setState(() => _searchQuery = val.trim()),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: isDark ? Colors.white : Colors.black87,
            ),
            decoration: InputDecoration(
              hintText: 'Search pandals by name, area, theme...',
              hintStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              prefixIcon: const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF22232E) : Colors.grey.shade100,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Zone Filters
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              FilterChip(
                label: const Text('All Zones'),
                selected: _selectedZoneFilter == null,
                onSelected: (_) => setState(() => _selectedZoneFilter = null),
                selectedColor: PujaColors.festivalGold.withValues(alpha: 0.25),
                labelStyle: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: _selectedZoneFilter == null ? FontWeight.w700 : FontWeight.w500,
                  color: _selectedZoneFilter == null
                      ? PujaColors.festivalGold
                      : (isDark ? Colors.white70 : Colors.black87),
                ),
              ),
              const SizedBox(width: 6),
              ...[
                KolkataZone.northKolkata,
                KolkataZone.centralKolkata,
                KolkataZone.southKolkata,
                KolkataZone.saltLake,
                KolkataZone.newTown,
              ].map((zone) {
                final isSelected = _selectedZoneFilter == zone;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(zone.shortLabel),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        _selectedZoneFilter = isSelected ? null : zone;
                      });
                    },
                    selectedColor: PujaColors.festivalGold.withValues(alpha: 0.25),
                    labelStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? PujaColors.festivalGold
                          : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),

        // Pandals list with checkboxes
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    'No pandals match your search.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: isDark ? Colors.white54 : Colors.black45,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  physics: const BouncingScrollPhysics(),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final pandal = filtered[index];
                    final isSelected = _selectedPandalIds.contains(pandal.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => _togglePandalSelection(pandal.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? PujaColors.festivalGold.withValues(alpha: isDark ? 0.22 : 0.12)
                                : (isDark ? const Color(0xFF22232E) : Colors.grey.shade50),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSelected
                                  ? PujaColors.festivalGold
                                  : (isDark ? Colors.white10 : Colors.black12),
                              width: isSelected ? 1.8 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Checkbox / Added toggle
                              Transform.scale(
                                scale: 1.1,
                                child: Checkbox(
                                  value: isSelected,
                                  activeColor: PujaColors.festivalGold,
                                  checkColor: Colors.black87,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  onChanged: (_) => _togglePandalSelection(pandal.id),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pandal.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13.5,
                                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            pandal.area ?? pandal.zoneLabel,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11.5,
                                              color: isDark ? Colors.white54 : Colors.black54,
                                            ),
                                          ),
                                        ),
                                        if (pandal.rating != null) ...[
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.star_rounded,
                                            size: 13,
                                            color: PujaColors.festivalGold,
                                          ),
                                          const SizedBox(width: 2),
                                          Text(
                                            '${pandal.rating}',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: PujaColors.festivalGold,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: PujaColors.festivalGold,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Added',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  // ==========================================
  // STEP 3: REVIEW & GENERATE
  // ==========================================
  Widget _buildStep3Review(bool isDark) {
    final selectedList = _selectedPandalsList;

    return ListView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      children: [
        // Banner
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: PujaColors.festivalGold.withValues(alpha: isDark ? 0.16 : 0.10),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: PujaColors.festivalGold.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.alt_route_rounded, color: PujaColors.festivalGold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Held-Karp Route Optimization',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Starting at "$_selectedLocationLabel", our on-device algorithm will compute the exact shortest walking path to visit all ${selectedList.length} pandals.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Pandals (${selectedList.length})',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: () => setState(() => _currentStep = _BuilderStep.choosePandals),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add More'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                foregroundColor: PujaColors.durgaRed,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Review list items with remove button
        ...List.generate(selectedList.length, (idx) {
          final pandal = selectedList[idx];

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF22232E) : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
              ),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: PujaColors.festivalGold.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${idx + 1}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: PujaColors.festivalGold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pandal.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          pandal.area ?? pandal.zoneLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                    color: Colors.redAccent,
                    tooltip: 'Remove stop',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() {
                        _selectedPandalIds.remove(pandal.id);
                        if (_selectedPandalIds.length < 2) {
                          _currentStep = _BuilderStep.choosePandals;
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ==========================================
  // STICKY BOTTOM ACTION BAR
  // ==========================================
  Widget _buildStickyBottomBar(bool isDark) {
    final bottomPadding = MediaQuery.of(context).padding.bottom + 12;

    switch (_currentStep) {
      case _BuilderStep.startingPoint:
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 10, 20, bottomPadding),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: PujaColors.durgaRed,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(
                'Next: Choose Pandals',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              onPressed: () {
                HapticFeedback.selectionClick();
                setState(() => _currentStep = _BuilderStep.choosePandals);
              },
            ),
          ),
        );

      case _BuilderStep.choosePandals:
        final count = _selectedPandalIds.length;
        final canContinue = count >= 2;

        return Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F202B) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
          ),
          child: Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => setState(() => _currentStep = _BuilderStep.startingPoint),
                child: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$count pandals selected',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      canContinue ? 'Ready to optimize' : 'Select at least 2',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: canContinue
                            ? PujaColors.festivalGold
                            : (isDark ? Colors.white54 : Colors.black45),
                        fontWeight: canContinue ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: canContinue ? PujaColors.durgaRed : Colors.grey.shade400,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: canContinue
                    ? () {
                        HapticFeedback.selectionClick();
                        setState(() => _currentStep = _BuilderStep.review);
                      }
                    : null,
                child: Text(
                  'Continue',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w800,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ],
          ),
        );

      case _BuilderStep.review:
        return Container(
          padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPadding),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F202B) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
          ),
          child: Row(
            children: [
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => setState(() => _currentStep = _BuilderStep.choosePandals),
                child: const Text('Edit'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFFF1744),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isGenerating
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.play_arrow_rounded, size: 22),
                  label: Text(
                    _isGenerating ? 'Optimizing...' : 'Generate My Custom Trail',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 13.5,
                    ),
                  ),
                  onPressed: _isGenerating ? null : _generateAndStartTrail,
                ),
              ),
            ],
          ),
        );
    }
  }
}
