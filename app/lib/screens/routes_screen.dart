import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../repositories/local_pandal_repository.dart';
import '../services/custom_hopping_trail_service.dart';
import '../widgets/pandal_detail_sheet.dart';
import '../widgets/custom_trail_planner_dialog.dart';
import 'main_navigation_screen.dart';

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
    required this.color,
    required this.icon,
  });

  final String id;
  final String title;
  final String bengaliTitle;
  final String subtitle;
  final String duration;
  final String distance;
  final String bestTime;
  final List<String> pandalIds;
  final Color color;
  final IconData icon;
}

class RoutesScreen extends StatefulWidget {
  const RoutesScreen({super.key});

  @override
  State<RoutesScreen> createState() => _RoutesScreenState();
}

class _RoutesScreenState extends State<RoutesScreen> {
  final LocalAssetPandalRepository _repo = LocalAssetPandalRepository();
  Map<String, Pandal> _pandalMap = {};
  bool _isLoading = true;
  bool _isGuideExpanded = false;
  String? _expandedRouteId;

  final List<HoppingRoute> _curatedRoutes = const [
    HoppingRoute(
      id: 'north_heritage',
      title: 'North Kolkata Heritage Walk',
      bengaliTitle: 'উত্তর কলকাতার সাবেকি পরিক্রমা',
      subtitle: 'Oldest traditional barowari idols, clay artists of Kumartuli & vintage lighting',
      duration: '3h 30m',
      distance: '4.8 km',
      bestTime: 'Morning 7 AM - 11 AM or Post Midnight',
      color: PujaColors.durgaRed,
      icon: Icons.temple_buddhist,
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
      color: PujaColors.festivalGold,
      icon: Icons.stars_rounded,
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
      color: Color(0xFF00B0FF),
      icon: Icons.palette_rounded,
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
      color: PujaColors.railwayPurple,
      icon: Icons.history_edu_rounded,
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
      color: Color(0xFFFF9100),
      icon: Icons.auto_awesome_rounded,
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
      color: Color(0xFF00E676),
      icon: Icons.explore_rounded,
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
    _loadAllPandals();
  }

  Future<void> _loadAllPandals() async {
    final list = await _repo.all();
    if (!mounted) return;
    setState(() {
      _pandalMap = {for (final p in list) p.id: p};
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pandal-Hopping Routes'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PujaColors.durgaRed))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              children: [
                // Minimalist Headline
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 12, top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Curated Circuits',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: isDark ? Colors.white : PujaColors.crimsonVelvet,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Optimized walking routes & transit-friendly trails',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Sleek AI Custom Trail Action Card
                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => CustomTrailPlannerDialog.show(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark ? PujaColors.nightCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: PujaColors.festivalGold.withValues(alpha: isDark ? 0.35 : 0.4),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: PujaColors.festivalGold.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: PujaColors.festivalGold,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'AI Custom Trail Planner',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14.5,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Create your own route by time and vibe',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: isDark ? Colors.white38 : Colors.black38,
                          size: 14,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Curated Routes List
                ..._curatedRoutes.map(
                  (route) => _buildRouteCard(route, isDark),
                ),

                const SizedBox(height: 10),

                // Minimalist Collapsible Transit Tips
                _buildFirstTimersGuideCard(isDark),

                const SizedBox(height: 20),
              ],
            ),
    );
  }

  Widget _buildRouteCard(HoppingRoute route, bool isDark) {
    final pandalsInRoute = route.pandalIds
        .map((id) => _pandalMap[id])
        .whereType<Pandal>()
        .toList();
    final isExpanded = _expandedRouteId == route.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? PujaColors.nightCard : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isExpanded
              ? route.color.withValues(alpha: 0.5)
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06)),
          width: isExpanded ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _expandedRouteId = isExpanded ? null : route.id;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: route.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(route.icon, color: route.color, size: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            route.title,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            route.bengaliTitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white54 : Colors.black45,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${route.duration} • ${route.distance} • ${route.pandalIds.length} stops',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: route.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Quick Action Button
                    InkWell(
                      borderRadius: BorderRadius.circular(999),
                      onTap: () => _startCircuit(route, pandalsInRoute),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: PujaColors.durgaRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.play_arrow_rounded, color: PujaColors.durgaRed, size: 16),
                            SizedBox(width: 2),
                            Text(
                              'Map',
                              style: TextStyle(
                                color: PujaColors.durgaRed,
                                fontWeight: FontWeight.w700,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: isDark ? Colors.white38 : Colors.black38,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route.subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 14, color: route.color),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Best time: ${route.bestTime}',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Circuit Stops (${pandalsInRoute.length})',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(pandalsInRoute.length, (idx) {
                      final p = pandalsInRoute[idx];
                      return InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          PandalDetailSheet.show(context, p);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  color: route.color.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: route.color,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (p.nearestMetro != null && p.nearestMetro!.isNotEmpty)
                                Text(
                                  p.nearestMetro!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: PujaColors.metroBlue,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 38,
                      child: ElevatedButton.icon(
                        onPressed: () => _startCircuit(route, pandalsInRoute),
                        icon: const Icon(Icons.map_rounded, size: 16),
                        label: const Text('Start Circuit on Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PujaColors.crimsonVelvet,
                          foregroundColor: PujaColors.goldBright,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
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
          backgroundColor: PujaColors.crimsonVelvet,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildFirstTimersGuideCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? PujaColors.nightCard : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isGuideExpanded = !_isGuideExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates_outlined,
                    color: PujaColors.festivalGold,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hopping & Metro Tips',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Icon(
                    _isGuideExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: isDark ? Colors.white38 : Colors.black38,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isGuideExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildGuideBullet(
                    icon: Icons.subway_rounded,
                    color: PujaColors.metroBlue,
                    title: 'Metro Runs Till 4 AM',
                    body: 'Blue Line runs past midnight up to 4:00 AM on Saptami, Ashtami, & Nabami. Use Green Line for Howrah Maidan & Salt Lake.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildGuideBullet(
                    icon: Icons.access_time_filled_rounded,
                    color: const Color(0xFFFF9100),
                    title: 'Best Hopping Windows',
                    body: 'Morning (5-9 AM) has zero queues. Late night (11 PM - 4 AM) has electric lighting and the true Kolkata puja atmosphere.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 10),
                  _buildGuideBullet(
                    icon: Icons.hiking_rounded,
                    color: const Color(0xFF00C853),
                    title: 'Footwear & Comfort',
                    body: 'Expect 10,000+ steps. Slip-on sandals are best as you remove shoes at heritage household thakur-dalans.',
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
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: isDark ? Colors.white70 : Colors.black87.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
