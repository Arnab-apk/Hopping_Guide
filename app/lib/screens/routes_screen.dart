import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../repositories/local_pandal_repository.dart';
import '../services/custom_hopping_trail_service.dart';
import '../utils/responsive.dart';
import '../widgets/pandal_detail_sheet.dart';
import '../widgets/animated_fade_slide.dart';
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
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: PujaColors.durgaRed))
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              children: [
                // Header Banner (Animated entrance)
                AnimatedFadeSlide(
                  duration: const Duration(milliseconds: 380),
                  offset: const Offset(0, -0.08),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [PujaColors.crimsonVelvet, PujaColors.durgaRedDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: PujaColors.festivalGold.withValues(alpha: 0.45),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: PujaColors.crimsonVelvet.withValues(alpha: 0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.alt_route, color: PujaColors.goldBright, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Smart Pandal Circuits',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Carefully organized hopping itineraries designed to minimize crowd waiting times and maximize metro/transit efficiency.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                ),

                const SizedBox(height: 14),

                // AI Custom Trail Generator Banner
                InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => CustomTrailPlannerDialog.show(context),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2C1B2E), const Color(0xFF1E1F29)]
                            : [const Color(0xFFFFF3E0), Colors.white],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: PujaColors.festivalGold.withValues(alpha: 0.6),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: PujaColors.festivalGold.withValues(alpha: 0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: PujaColors.festivalGold.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.auto_awesome_rounded,
                            color: PujaColors.festivalGold,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'AI Custom Trail Planner',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: PujaColors.durgaRed,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'NEW',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Set your time in hand & hopping vibe (Heritage, Blockbuster, Low Queue). Includes Auto-Visit & Notification Bar progress.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? Colors.white70 : Colors.black54,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: PujaColors.festivalGold,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // Beginner's & First-Timer's Planning Guide Card
                _buildFirstTimersGuideCard(isDark),

                const SizedBox(height: 24),

                const Text(
                  'Curated Heritage Itineraries',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 12),

                ..._curatedRoutes.asMap().entries.map(
                      (entry) => AnimatedFadeSlide(
                        key: ValueKey('route_${entry.value.id}'),
                        delay: Duration(milliseconds: 60 + (entry.key * 45)),
                        child: _buildRouteCard(entry.value, isDark),
                      ),
                    ),
              ],
            ),
    );
  }

  Widget _buildRouteCard(HoppingRoute route, bool isDark) {
    // Resolve pandals in route
    final pandalsInRoute = route.pandalIds
        .map((id) => _pandalMap[id])
        .whereType<Pandal>()
        .toList();

    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      elevation: isDark ? 1 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: route.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(route.icon, color: route.color, size: context.dynamicIcon(26)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        route.bengaliTitle,
                        style: TextStyle(
                          color: route.color,
                          fontSize: context.dynamicFont(13),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        route.title,
                        style: TextStyle(
                          fontSize: context.dynamicFont(18),
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              route.subtitle,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black54,
                fontSize: context.dynamicFont(13),
                height: 1.4,
              ),
            ),

            const SizedBox(height: 14),

            // Metrics chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildMetricChip(context, Icons.schedule, route.duration, isDark),
                _buildMetricChip(context, Icons.straighten, route.distance, isDark),
                _buildMetricChip(context, Icons.light_mode, route.bestTime, isDark),
              ],
            ),

            const SizedBox(height: 16),

            const Divider(height: 1),

            const SizedBox(height: 14),

            // Stops sequence
            Text(
              'Stops in this route (${pandalsInRoute.length} pandals):',
              style: TextStyle(fontSize: context.dynamicFont(13), fontWeight: FontWeight.w700),
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
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: route.color.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${idx + 1}',
                            style: TextStyle(
                              color: route.color,
                              fontSize: context.dynamicFont(11),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          p.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.dynamicFont(14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (p.nearestMetro != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          p.nearestMetro!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: context.dynamicFont(11),
                            color: PujaColors.metroBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 14),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
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
                },
                icon: Icon(Icons.map, size: context.dynamicIcon(18)),
                label: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'Follow this Circuit on Map',
                    style: TextStyle(fontSize: context.dynamicFont(14), fontWeight: FontWeight.bold),
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: PujaColors.crimsonVelvet,
                  foregroundColor: PujaColors.goldBright,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: PujaColors.festivalGold.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFirstTimersGuideCard(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? PujaColors.nightCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: PujaColors.festivalGold.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _isGuideExpanded = !_isGuideExpanded);
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: PujaColors.durgaRed.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: PujaColors.durgaRed,
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
                              "First-Timer's Planning Guide",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text('💡', style: TextStyle(fontSize: 14)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Metro night hours, queue-skipping strategies & street food pairings',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isGuideExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: PujaColors.festivalGold,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
          if (_isGuideExpanded) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildGuideBullet(
                    icon: Icons.subway_rounded,
                    color: PujaColors.metroBlue,
                    title: 'Metro Lifeline (Runs Till 4 AM)',
                    body: 'The Blue Line (Dakshineswar to Kavi Subhash) runs past midnight up to 4:00 AM on Saptami, Ashtami, & Nabami. Use Green Line for Howrah Maidan & Salt Lake. Avoid private cars in narrow North Kolkata & Gariahat lanes.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildGuideBullet(
                    icon: Icons.access_time_filled_rounded,
                    color: const Color(0xFFFF9100),
                    title: 'Golden Hopping Windows',
                    body: '• Early Morning (5 AM - 9 AM): 0 queues, golden sunlight, perfect for Bonedi Bari.\n• Afternoon (1 PM - 4 PM): Best for South Kolkata themes with minimal lines.\n• Night (11 PM - 4 AM): The quintessential Kolkata night vibe & electric illuminations.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildGuideBullet(
                    icon: Icons.hiking_rounded,
                    color: const Color(0xFF00C853),
                    title: 'Footwear & Hydration',
                    body: 'Expect 12,000 - 20,000 steps per circuit! Wear comfortable slip-on sandals (you will need to remove shoes at household thakur-dalans). Sip Daab (green coconut water) frequently.',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildGuideBullet(
                    icon: Icons.restaurant_rounded,
                    color: const Color(0xFFFF1744),
                    title: 'Iconic Street Food Pairings',
                    body: '• North: Golbari Kosha Mangsho, Mitra Cafe Fish Fry, Paramount Daab Sherbet, Nakur Sandesh.\n• South: Kusum Double Chicken Egg Roll, Peter Cat Chelo Kebab, Maharaj Club Kachori.\n• Central: Nizam\'s original Kathi Roll, Anadi Cabin Mughlai Paratha.',
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

  Widget _buildMetricChip(BuildContext context, IconData icon, String text, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? PujaColors.nightSurface : PujaColors.goldSoft,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: PujaColors.festivalGold.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: context.dynamicIcon(13), color: PujaColors.durgaRed),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: context.dynamicFont(11),
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white70 : PujaColors.crimsonVelvet,
            ),
          ),
        ],
      ),
    );
  }
}
