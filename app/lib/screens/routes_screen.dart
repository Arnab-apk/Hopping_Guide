import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../repositories/local_pandal_repository.dart';
import '../repositories/pandal_repository.dart';
import '../services/custom_hopping_trail_service.dart';
import '../widgets/animated_fade_slide.dart';
import '../widgets/pandal_detail_sheet.dart';
import '../widgets/puja_icons.dart';
import 'main_navigation_screen.dart';

enum RouteCategoryFilter {
  all(label: 'All', icon: Icons.explore_outlined),
  north(label: 'North', icon: Icons.temple_hindu_outlined),
  south(label: 'South', icon: Icons.stars_outlined),
  bonedi(label: 'Bonedi Bari', icon: Icons.history_edu_outlined),
  east(label: 'Salt Lake / East', icon: Icons.auto_awesome_outlined),
  express(label: 'Express', icon: Icons.directions_walk_outlined);

  const RouteCategoryFilter({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

class HoppingRoute {
  const HoppingRoute({
    required this.id,
    required this.title,
    required this.bengaliTitle,
    required this.subtitle,
    required this.duration,
    required this.distance,
    required this.bestTime,
    required this.pandalIds,
    required this.icon,
    required this.zoneTag,
    required this.category,
    this.pujaIconType,
  });

  final String id;
  final String title;
  final String bengaliTitle;
  final String subtitle;
  final String duration;
  final String distance;
  final String bestTime;
  final List<String> pandalIds;
  final IconData icon;
  final String zoneTag;
  final RouteCategoryFilter category;
  final PujaIconType? pujaIconType;
}

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key, this.repository});

  final PandalRepository? repository;

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  late final PandalRepository _repo;
  Map<String, Pandal> _pandalMap = {};
  bool _isLoading = true;
  bool _isGuideExpanded = false;
  String? _expandedRouteId;

  RouteCategoryFilter _selectedFilter = RouteCategoryFilter.all;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final List<HoppingRoute> _curatedRoutes = const [
    HoppingRoute(
      id: 'north_heritage',
      title: 'North Kolkata Heritage Walk',
      bengaliTitle: 'উত্তর কলকাতার সাবেকি পরিক্রমা',
      subtitle: 'Oldest traditional barowari idols, clay artists of Kumartuli & vintage lighting',
      duration: '3h 30m',
      distance: '4.8 km',
      bestTime: 'Morning 7 AM - 11 AM or Post Midnight',
      icon: Icons.temple_buddhist,
      zoneTag: 'North Kolkata',
      category: RouteCategoryFilter.north,
      pujaIconType: PujaIconType.dhunuchiPriest,
      pandalIds: [
        'hatibagan_sarbojanin',
        'kasi_bose_lane',
        'nalin_sarkar_street',
        'nabin_pally',
        'kumortuli_park_sarbojanin',
        'ahiritola',
        'bagbazar_sarbajanin',
      ],
    ),
    HoppingRoute(
      id: 'south_classics',
      title: 'South Kolkata Grand Circuit',
      bengaliTitle: 'দক্ষিণ কলকাতার মহাউৎসব',
      subtitle: 'Blockbuster crowd-pullers, architectural replicas, and open family parks',
      duration: '4h 15m',
      distance: '5.8 km',
      bestTime: 'Afternoon 2 PM - 6 PM or Late Night',
      icon: Icons.stars_rounded,
      zoneTag: 'South Kolkata',
      category: RouteCategoryFilter.south,
      pujaIconType: PujaIconType.durgaSunTrishul,
      pandalIds: [
        'ballygunge_cultural',
        'ekdalia_evergreen',
        'singhi_park',
        'maddox_square',
        'deshapriya_park',
        'tridhara',
      ],
    ),
    HoppingRoute(
      id: 'south_west_themes',
      title: 'South-West Thematic Wonder Trail',
      bengaliTitle: 'দক্ষিণ-পশ্চিম থিম পরিক্রমা',
      subtitle: 'Award-winning conceptual art installations, social messages & creative lighting',
      duration: '3h 45m',
      distance: '4.9 km',
      bestTime: 'Evening 6 PM - 10 PM',
      icon: Icons.palette_rounded,
      zoneTag: 'South-West',
      category: RouteCategoryFilter.south,
      pujaIconType: PujaIconType.trishulDiya,
      pandalIds: [
        'suruchi_sangha',
        'chetla_agrani',
        'mudiali_club',
        'shib_mandir',
        'badamtala',
        'behala_natun_dal',
      ],
    ),
    HoppingRoute(
      id: 'bonedi_bari',
      title: 'Zamindar & Bonedi Bari Trail',
      bengaliTitle: 'বনেদি বাড়ির পুজো পরিক্রমা',
      subtitle: 'Century-old aristocratic household traditions, courtyard Ekchala Pratima (Est. 1757)',
      duration: '2h 45m',
      distance: '3.6 km',
      bestTime: 'Early Morning (Best lighting & no rush)',
      icon: Icons.history_edu_rounded,
      zoneTag: 'Heritage / Bonedi',
      category: RouteCategoryFilter.bonedi,
      pujaIconType: PujaIconType.kalash,
      pandalIds: [
        'chatu_babu_latu_babus_thakur_bari',
        'sovabazar_rajbari',
        'shimla_street',
        'college_square',
        'santosh_mitra_square',
      ],
    ),
    HoppingRoute(
      id: 'saltlake_vip_marvels',
      title: 'Salt Lake & VIP Road Modern Marvels',
      bengaliTitle: 'সল্টলেক ও ভিআইপি রোড চমক',
      subtitle: 'Grand palaces, Burj Khalifa-style light spectacles & modern architectural marvels',
      duration: '3h 15m',
      distance: '6.4 km',
      bestTime: 'Night 8 PM - 2 AM',
      icon: Icons.auto_awesome_rounded,
      zoneTag: 'Salt Lake & VIP',
      category: RouteCategoryFilter.east,
      pujaIconType: PujaIconType.ashtabhujaDevi,
      pandalIds: [
        'sree_bhumi_sporting_club',
        'lake_town_adibashi_brinda',
        'dum_dum_park_tarun_sangha',
        'dum_dum_park_bharat_chakra',
        'fd_block_durga_puja',
      ],
    ),
    HoppingRoute(
      id: 'beginners_express',
      title: "First-Timer's Essential Express",
      bengaliTitle: 'নবীন দর্শনার্থীদের দ্রুত পরিক্রমা',
      subtitle: 'The best introductory circuit with direct Metro connectivity and minimal walking',
      duration: '3h 00m',
      distance: '4.2 km',
      bestTime: 'Morning 8 AM - 12 PM',
      icon: Icons.explore_rounded,
      zoneTag: 'Metro Express',
      category: RouteCategoryFilter.express,
      pujaIconType: PujaIconType.durgaEyes,
      pandalIds: [
        'bagbazar_sarbajanin',
        'kumortuli_park_sarbojanin',
        'college_square',
        'maddox_square',
        'ekdalia_evergreen',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? LocalAssetPandalRepository();
    _loadAllPandals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllPandals() async {
    final list = await _repo.all();
    if (!mounted) return;
    setState(() {
      _pandalMap = {for (final p in list) p.id: p};
      _isLoading = false;
    });
  }

  List<HoppingRoute> _getFilteredRoutes() {
    var routes = _curatedRoutes;

    // Filter by category
    if (_selectedFilter != RouteCategoryFilter.all) {
      routes = routes.where((r) => r.category == _selectedFilter).toList();
    }

    // Filter by search query
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      routes = routes.where((r) {
        final titleMatch = r.title.toLowerCase().contains(query);
        final bengaliMatch = r.bengaliTitle.toLowerCase().contains(query);
        final subtitleMatch = r.subtitle.toLowerCase().contains(query);
        final zoneMatch = r.zoneTag.toLowerCase().contains(query);
        // Also check if any pandal name in the route matches
        final pandalMatch = r.pandalIds.any((id) {
          final p = _pandalMap[id];
          return p != null &&
              (p.name.toLowerCase().contains(query) ||
                  (p.nearestMetro != null && p.nearestMetro!.toLowerCase().contains(query)));
        });
        return titleMatch || bengaliMatch || subtitleMatch || zoneMatch || pandalMatch;
      }).toList();
    }

    return routes;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final displayRoutes = _getFilteredRoutes();

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Curated Routes'),
      ),
      body: Column(
        children: [
          // 1. Search Bar with Instant Matching & Material 3 Theme Styling
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              controller: _searchController,
              hintText: 'Search routes, stops, or areas...',
              leading: Icon(
                Icons.search_rounded,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              trailing: _searchQuery.isNotEmpty
                  ? [
                      IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      ),
                    ]
                  : null,
              onChanged: (val) {
                setState(() => _searchQuery = val);
              },
            ),
          ),

          // 2. Horizontal Filter Chips Row (Mirroring Pandals Screen)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: RouteCategoryFilter.values.map((filter) {
                final isSelected = _selectedFilter == filter;
                final label = filter == RouteCategoryFilter.all
                    ? 'All (${_curatedRoutes.length})'
                    : filter.label;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: isSelected,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFilter = filter);
                    },
                    avatar: Icon(
                      filter.icon,
                      size: 16,
                      color: isSelected
                          ? colorScheme.onSecondaryContainer
                          : colorScheme.onSurfaceVariant,
                    ),
                    label: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? colorScheme.onSecondaryContainer
                            : colorScheme.onSurface,
                      ),
                    ),
                    showCheckmark: false,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const Divider(height: 1),

          // Section Header matching Material 3 typography
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Row(
              children: [
                Text(
                  'Curated Circuits',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '${displayRoutes.length} available',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          // 3. Routes List View
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
                : displayRoutes.isEmpty
                    ? _buildEmptyState(colorScheme, isDark)
                    : ListView(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: [
                          ...displayRoutes.asMap().entries.map((entry) {
                            final index = entry.key;
                            final route = entry.value;
                            return AnimatedFadeSlide(
                              key: ValueKey(route.id),
                              delay: Duration(milliseconds: index < 6 ? index * 30 : 0),
                              child: _buildRouteCard(route, colorScheme, isDark),
                            );
                          }),

                          const SizedBox(height: 6),

                          // Transit & Hopping Tips Collapsible Card
                          _buildFirstTimersGuideCard(colorScheme, isDark),

                          const SizedBox(height: 24),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.route_outlined,
                size: 40,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No circuits found',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing your search term or select another category filter.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = RouteCategoryFilter.all;
                });
              },
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: Text(
                'Reset Filters',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteCard(HoppingRoute route, ColorScheme colorScheme, bool isDark) {
    final pandalsInRoute = route.pandalIds
        .map((id) => _pandalMap[id])
        .whereType<Pandal>()
        .toList();
    final isExpanded = _expandedRouteId == route.id;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpanded
              ? colorScheme.primary.withValues(alpha: 0.65)
              : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.45 : 0.65),
          width: isExpanded ? 1.4 : 1.0,
        ),
      ),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() {
            _expandedRouteId = isExpanded ? null : route.id;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top metadata pills row (matches PlaceCard structure)
              Row(
                children: [
                  // Zone/Region Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      route.zoneTag,
                      style: GoogleFonts.plusJakartaSans(
                        color: colorScheme.onSecondaryContainer,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  // Stops count badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${route.pandalIds.length} stops',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 2. Main Title Row with Tonal Icon Badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: route.pujaIconType != null
                          ? PujaIcon(
                              route.pujaIconType!,
                              size: 26,
                              color: colorScheme.onSecondaryContainer,
                            )
                          : Icon(
                              route.icon,
                              color: colorScheme.onSecondaryContainer,
                              size: 22,
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          route.title,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: colorScheme.onSurface,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          route.bengaliTitle,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.directions_walk_rounded,
                              size: 13,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${route.duration} • ${route.distance}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 22,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Subtitle
              Text(
                route.subtitle,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  height: 1.35,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                maxLines: isExpanded ? null : 2,
                overflow: isExpanded ? null : TextOverflow.ellipsis,
              ),

              // 3. Expanded Circuit Details
              if (isExpanded) ...[
                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
                ),
                const SizedBox(height: 12),

                // Best Time Advice
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time_filled_rounded,
                        size: 15,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Best time: ${route.bestTime}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Circuit Stops Header
                Text(
                  'Circuit Stops (${pandalsInRoute.length})',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),

                // Stops List
                ...List.generate(pandalsInRoute.length, (idx) {
                  final p = pandalsInRoute[idx];
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      HapticFeedback.selectionClick();
                      PandalDetailSheet.show(context, p);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: colorScheme.primaryContainer,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${idx + 1}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              p.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (p.nearestMetro != null && p.nearestMetro!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: PujaColors.metroBlue.withValues(alpha: 0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.subway_rounded,
                                    size: 11,
                                    color: PujaColors.metroBlue,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    p.nearestMetro!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10.5,
                                      color: PujaColors.metroBlue,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // Start Circuit on Map Button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                  child: SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () => _startCircuit(route, pandalsInRoute),
                      icon: PujaIcon.shankha(
                        size: 20,
                        color: colorScheme.onPrimary,
                      ),
                      label: Text(
                        'Start Circuit on Map',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _startCircuit(HoppingRoute route, List<Pandal> pandalsInRoute) {
    HapticFeedback.lightImpact();
    if (pandalsInRoute.isNotEmpty) {
      final firstPandal = pandalsInRoute.first;
      final distNum = double.tryParse(route.distance.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 4.0;
      final trail = ActiveCustomTrail(
        id: 'circuit_${route.id}',
        style: HoppingStyle.express,
        timeBudgetMinutes: 180,
        transitMode: HoppingTransitMode.walking,
        startingLocation: LatLng(firstPandal.lat, firstPandal.lng),
        startingAddress: firstPandal.name,
        stops: pandalsInRoute,
        totalDistanceKm: distNum,
        totalEstimatedMinutes: 180,
        startedAt: DateTime.now(),
      );
      CustomHoppingTrailService.instance.startTrail(trail);
      MainNavigationScreen.switchTab(context, 0);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🗺️ Following "${route.title}"! Stop 1: ${pandalsInRoute.first.name}'),
          backgroundColor: PujaColors.durgaRed,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildFirstTimersGuideCard(ColorScheme colorScheme, bool isDark) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isGuideExpanded = !_isGuideExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.tips_and_updates_outlined,
                      color: colorScheme.onSecondaryContainer,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hopping & Metro Tips',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    _isGuideExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isGuideExpanded) ...[
            Divider(
              height: 1,
              color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.55),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildGuideBullet(
                    icon: Icons.subway_rounded,
                    color: PujaColors.metroBlue,
                    title: 'Metro Runs Till 4 AM',
                    body:
                        'Blue Line runs past midnight up to 4:00 AM on Saptami, Ashtami, & Nabami. Use Green Line for Howrah Maidan & Salt Lake.',
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildGuideBullet(
                    icon: Icons.access_time_filled_rounded,
                    color: const Color(0xFFFF9100),
                    title: 'Best Hopping Windows',
                    body:
                        'Morning (5-9 AM) has zero queues. Late night (11 PM - 4 AM) has electric lighting and the true Kolkata puja atmosphere.',
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildGuideBullet(
                    icon: Icons.hiking_rounded,
                    color: const Color(0xFF00C853),
                    title: 'Footwear & Comfort',
                    body:
                        'Expect 10,000+ steps. Slip-on sandals are best as you remove shoes at heritage household thakur-dalans.',
                    colorScheme: colorScheme,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGuideBullet({
    required IconData icon,
    required Color color,
    required String title,
    required String body,
    required ColorScheme colorScheme,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 2),
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  height: 1.4,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
