import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../repositories/local_pandal_repository.dart';
import '../utils/responsive.dart';
import '../widgets/pandal_detail_sheet.dart';

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

  final List<HoppingRoute> _curatedRoutes = const [
    HoppingRoute(
      id: 'north_heritage',
      title: 'North Kolkata Heritage Walk',
      bengaliTitle: 'উত্তর কলকাতার সাবেকি পরিক্রমা',
      subtitle: 'Oldest traditional barowari idols, clay artists & vintage lighting',
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
      ],
    ),
    HoppingRoute(
      id: 'south_classics',
      title: 'South Kolkata Grand Circuit',
      bengaliTitle: 'দক্ষিণ কলকাতার মহাউৎসব',
      subtitle: 'Spacious pandals, iconic artistic themes and family parks',
      duration: '4h 15m',
      distance: '6.2 km',
      bestTime: 'Afternoon 2 PM - 6 PM',
      color: PujaColors.festivalGold,
      icon: Icons.stars,
      pandalIds: [
        'ballygunge_cultural',
        'ekdalia_evergreen_club',
        'singhi_park',
        'maddox_square',
      ],
    ),
    HoppingRoute(
      id: 'bonedi_bari',
      title: 'Zamindar & Bonedi Bari Trail',
      bengaliTitle: 'বনেদি বাড়ির পুজো পরিক্রমা',
      subtitle: 'Century-old aristocratic household traditions dating back to 1757',
      duration: '2h 45m',
      distance: '3.5 km',
      bestTime: 'Early Morning (Best lighting & no rush)',
      color: PujaColors.railwayPurple,
      icon: Icons.history_edu,
      pandalIds: [
        'chatu_babu_latu_babus_thakur_bari',
        'sovabazar_rajbari',
        'shimla_street',
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
                // Header Banner
                Container(
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

                const SizedBox(height: 24),

                const Text(
                  'Recommended Itineraries',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),

                const SizedBox(height: 12),

                ..._curatedRoutes.map((route) => _buildRouteCard(route, isDark)),
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
                          style: TextStyle(
                            fontSize: context.dynamicFont(14),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (p.nearestMetro != null)
                        Text(
                          p.nearestMetro!,
                          style: TextStyle(
                            fontSize: context.dynamicFont(11),
                            color: PujaColors.metroBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
                  Navigator.of(context).pushNamed('/main');
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
