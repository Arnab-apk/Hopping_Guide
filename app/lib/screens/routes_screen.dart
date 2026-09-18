import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../repositories/local_pandal_repository.dart';
import '../services/custom_hopping_trail_service.dart';
import '../widgets/pandal_detail_sheet.dart';
import '../widgets/puja_icons.dart';
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
  final Color color;
  final IconData icon;
  final PujaIconType? pujaIconType;
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
      color: PujaColors.festivalGold,
      icon: Icons.temple_buddhist,
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
      color: PujaColors.festivalGold,
      icon: Icons.stars_rounded,
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
      color: PujaColors.festivalGold,
      icon: Icons.palette_rounded,
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
      color: PujaColors.festivalGold,
      icon: Icons.history_edu_rounded,
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
      color: PujaColors.festivalGold,
      icon: Icons.auto_awesome_rounded,
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
      color: PujaColors.festivalGold,
      icon: Icons.explore_rounded,
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
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isExpanded
              ? route.color.withValues(alpha: 0.6)
              : Theme.of(context).colorScheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6),
          width: isExpanded ? 1.4 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: route.color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: route.color.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: route.pujaIconType != null
                            ? PujaIcon(route.pujaIconType!, size: 34, color: route.color)
                            : Icon(route.icon, color: route.color, size: 28),
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
                        icon: PujaIcon.shankha(size: 22, color: PujaColors.goldBright),
                        label: const Text('Start Circuit on Map'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PujaColors.crimsonVelvet,
                          foregroundColor: PujaColors.goldBright,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
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
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: isDark ? 0.4 : 0.6),
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
