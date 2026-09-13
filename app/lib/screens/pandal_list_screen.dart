import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../models/pandal.dart';
import '../repositories/local_pandal_repository.dart';
import '../repositories/pandal_repository.dart';
import '../repositories/supplementary_repository.dart';
import '../services/location_service.dart';
import '../services/pandal_search_service.dart';
import '../services/pandal_user_state_service.dart';
import '../utils/constants.dart';
import '../utils/haversine.dart';
import '../utils/responsive.dart';
import '../widgets/animated_fade_slide.dart';
import '../widgets/durga_face_icon.dart';
import '../widgets/pandal_card.dart';
import '../widgets/pandal_detail_sheet.dart';
import '../widgets/pandal_search_autocomplete.dart';
import 'map_screen.dart';

enum PandalTabFilter {
  all,
  favorites,
  visited,
  nearest,
}

enum PandalSortOption {
  defaultOrder,
  nearestFirst,
  ratingHighToLow,
  lowCrowdFirst,
}

class PandalListScreen extends StatefulWidget {
  const PandalListScreen({super.key, this.repository});

  final PandalRepository? repository;

  @override
  State<PandalListScreen> createState() => _PandalListScreenState();
}

class _PandalListScreenState extends State<PandalListScreen> {
  late final PandalRepository _repo;
  List<Pandal> _allPandals = [];
  List<FoodSpot> _allFoodSpots = [];
  bool _isLoading = true;
  bool _showFoodOnly = false;

  String _searchQuery = '';
  KolkataZone? _selectedZone;
  PandalTabFilter _activeTab = PandalTabFilter.all;
  PandalSortOption _currentSort = PandalSortOption.defaultOrder;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? LocalAssetPandalRepository();
    _loadPandals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPandals() async {
    setState(() => _isLoading = true);
    final results = await Future.wait([
      _repo.all(),
      SupplementaryRepository().getFoodSpots(),
    ]);
    if (!mounted) return;
    setState(() {
      _allPandals = results[0] as List<Pandal>;
      _allFoodSpots = results[1] as List<FoodSpot>;
      _isLoading = false;
    });
  }

  List<FoodSpot> _getFilteredFoodSpots(LocationService? locationService) {
    var list = List<FoodSpot>.from(_allFoodSpots);

    // If on the "Nearby (10km)" tab:
    if (_activeTab == PandalTabFilter.nearest) {
      final pos = locationService?.lastPosition;
      final rawLat = pos?.latitude ?? AppConfig.defaultLat;
      final rawLng = pos?.longitude ?? AppConfig.defaultLng;
      // If user GPS is unavailable or remote (e.g. emulator at default lat/lng), fall back to Kolkata center
      final isFarAway = haversineMeters(rawLat, rawLng, AppConfig.defaultLat, AppConfig.defaultLng) > 70000;
      final userLat = isFarAway ? AppConfig.defaultLat : rawLat;
      final userLng = isFarAway ? AppConfig.defaultLng : rawLng;

      // Filter strictly to within 10 km (10,000 meters)
      list = list.where((f) {
        return haversineMeters(userLat, userLng, f.lat, f.lng) <= 10000;
      }).toList();

      // Sort by distance ascending
      list.sort((a, b) {
        final da = haversineMeters(userLat, userLng, a.lat, a.lng);
        final db = haversineMeters(userLat, userLng, b.lat, b.lng);
        return da.compareTo(db);
      });
    } else if (_selectedZone != null) {
      list = list.where((f) {
        final matchingPandal = _allPandals.cast<Pandal?>().firstWhere(
          (p) => p != null && (p.name.toLowerCase() == f.nearbyPandal.toLowerCase() ||
                 f.nearbyPandal.toLowerCase().contains(p.name.toLowerCase()) ||
                 p.name.toLowerCase().contains(f.nearbyPandal.toLowerCase())),
          orElse: () => null,
        );
        return matchingPandal?.zone == _selectedZone;
      }).toList();
    }

    // Search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((f) {
        final nameMatch = f.name.toLowerCase().contains(q);
        final typeMatch = f.type.toLowerCase().contains(q);
        final mustTryMatch = (f.mustTry ?? '').toLowerCase().contains(q);
        final pandalMatch = f.nearbyPandal.toLowerCase().contains(q);
        return nameMatch || typeMatch || mustTryMatch || pandalMatch;
      }).toList();
    }

    return list;
  }

  List<Pandal> _getFilteredPandals(
    PandalUserStateService? userState,
    LocationService? locationService,
  ) {
    var list = List<Pandal>.from(_allPandals);

    // Tab filter (Favorites, Visited, Nearest)
    if (_activeTab == PandalTabFilter.favorites && userState != null) {
      list = list.where((p) => userState.isFavorite(p.id)).toList();
    } else if (_activeTab == PandalTabFilter.visited && userState != null) {
      list = list.where((p) => userState.isVisited(p.id)).toList();
    } else if (_activeTab == PandalTabFilter.nearest) {
      final pos = locationService?.lastPosition;
      final rawLat = pos?.latitude ?? AppConfig.defaultLat;
      final rawLng = pos?.longitude ?? AppConfig.defaultLng;
      final isFarAway = haversineMeters(rawLat, rawLng, AppConfig.defaultLat, AppConfig.defaultLng) > 70000;
      final userLat = isFarAway ? AppConfig.defaultLat : rawLat;
      final userLng = isFarAway ? AppConfig.defaultLng : rawLng;
      final nearby = list.where((p) => haversineMeters(userLat, userLng, p.lat, p.lng) <= 10000).toList();
      if (nearby.isNotEmpty) list = nearby;
    }

    // Zone filter
    if (_selectedZone != null) {
      list = list.where((p) => p.zone == _selectedZone).toList();
    }

    // Keyword Matching Search query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim();
      final scoredResults = <String, double>{};
      list = list.where((p) {
        final result = PandalSearchService.instance.scorePandal(p, query);
        if (result != null) {
          scoredResults[p.id] = result.score;
          return true;
        }
        return false;
      }).toList();

      // If default order and not nearest tab, sort by relevance score
      if (_currentSort == PandalSortOption.defaultOrder && _activeTab != PandalTabFilter.nearest) {
        list.sort((a, b) => (scoredResults[b.id] ?? 0.0).compareTo(scoredResults[a.id] ?? 0.0));
      }
    }

    // Sorting
    final effectiveSort = _activeTab == PandalTabFilter.nearest
        ? PandalSortOption.nearestFirst
        : _currentSort;

    switch (effectiveSort) {
      case PandalSortOption.nearestFirst:
        final pos = locationService?.lastPosition;
        final rawLat = pos?.latitude ?? AppConfig.defaultLat;
        final rawLng = pos?.longitude ?? AppConfig.defaultLng;
        final isFarAway = haversineMeters(rawLat, rawLng, AppConfig.defaultLat, AppConfig.defaultLng) > 70000;
        final userLat = isFarAway ? AppConfig.defaultLat : rawLat;
        final userLng = isFarAway ? AppConfig.defaultLng : rawLng;
        list.sort((a, b) {
          final distA = haversineMeters(userLat, userLng, a.lat, a.lng);
          final distB = haversineMeters(userLat, userLng, b.lat, b.lng);
          return distA.compareTo(distB);
        });
        break;
      case PandalSortOption.ratingHighToLow:
        list.sort((a, b) => (b.rating ?? 0.0).compareTo(a.rating ?? 0.0));
        break;
      case PandalSortOption.lowCrowdFirst:
        final crowdOrder = {'low': 0, 'medium': 1, 'high': 2};
        list.sort((a, b) {
          final ca = crowdOrder[a.crowdLevel?.toLowerCase()] ?? 1;
          final cb = crowdOrder[b.crowdLevel?.toLowerCase()] ?? 1;
          return ca.compareTo(cb);
        });
        break;
      case PandalSortOption.defaultOrder:
        break;
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final userState = context.watch<PandalUserStateService?>();
    final locationService = context.watch<LocationService?>();

    final displayList = _getFilteredPandals(userState, locationService);
    final visitedCount = userState?.visitedCount ?? 0;
    final totalCount = _allPandals.length;
    final progress = totalCount > 0 ? (visitedCount / totalCount).clamp(0.0, 1.0) : 0.0;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: const Text('Kolkata Pandals'),
        actions: [
          IconButton(
            tooltip: 'Update My Location',
            icon: Icon(
              locationService?.hasRealLocation == true
                  ? Icons.my_location
                  : Icons.location_searching,
              color: locationService?.hasRealLocation == true ? Colors.green : null,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final pos = await locationService?.updateLiveLocation();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(
                    pos != null
                        ? '📍 GPS updated! Distance calculated from your current spot.'
                        : (locationService?.error ?? 'Could not acquire GPS.'),
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: _showFoodOnly ? 'Show Pandals' : 'Show Food & Stalls',
            icon: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: _showFoodOnly ? PujaColors.festivalGold.withValues(alpha: 0.25) : Colors.transparent,
                shape: BoxShape.circle,
                border: _showFoodOnly ? Border.all(color: PujaColors.goldBright, width: 1.2) : null,
              ),
              child: Icon(
                _showFoodOnly ? Icons.restaurant_rounded : Icons.restaurant_outlined,
                color: _showFoodOnly ? PujaColors.goldBright : null,
                size: context.dynamicIcon(20),
              ),
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() => _showFoodOnly = !_showFoodOnly);
              final count = _getFilteredFoodSpots(locationService).length;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    _showFoodOnly
                        ? (_activeTab == PandalTabFilter.nearest
                            ? '🍲 Showing $count Food Stalls within 10 km range'
                            : '🍲 Showing $count Food & Restaurant Stalls')
                        : 'Switched back to Pandals list',
                  ),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          PopupMenuButton<PandalSortOption>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort Options',
            initialValue: _currentSort,
            onSelected: (val) => setState(() => _currentSort = val),
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: PandalSortOption.defaultOrder,
                child: Text('Default Order'),
              ),
              PopupMenuItem(
                value: PandalSortOption.nearestFirst,
                child: Text('📍 Nearest to Me'),
              ),
              PopupMenuItem(
                value: PandalSortOption.ratingHighToLow,
                child: Text('⭐ Highest Rated'),
              ),
              PopupMenuItem(
                value: PandalSortOption.lowCrowdFirst,
                child: Text('🟢 Least Crowded First'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar with Instant Keyword Matching & Autocomplete
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: PandalSearchAutocomplete(
              pandals: _allPandals,
              controller: _searchController,
              userLat: locationService?.lastPosition?.latitude,
              userLng: locationService?.lastPosition?.longitude,
              hintText: 'Search by pandal, area, metro, theme...',
              onQueryChanged: (val) {
                setState(() => _searchQuery = val);
              },
              onPandalSelected: (pandal) {
                PandalDetailSheet.show(context, pandal);
              },
            ),
          ),

          // 2. High-Level Tab Bar: All, Favorites, Visited, Nearest
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _buildTabPill(
                  label: 'All (${_allPandals.length})',
                  customIcon: DurgaFaceIcon(
                    size: context.dynamicIcon(15),
                    color: _activeTab == PandalTabFilter.all
                        ? PujaColors.goldBright
                        : PujaColors.festivalGold,
                    bindiColor: _activeTab == PandalTabFilter.all
                        ? const Color(0xFFFF1744)
                        : const Color(0xFFD50000),
                  ),
                  isSelected: _activeTab == PandalTabFilter.all,
                  onTap: () => setState(() => _activeTab = PandalTabFilter.all),
                ),
                const SizedBox(width: 8),
                _buildTabPill(
                  label: '❤️ Favorites (${userState?.favoriteCount ?? 0})',
                  icon: Icons.favorite,
                  isSelected: _activeTab == PandalTabFilter.favorites,
                  onTap: () => setState(() => _activeTab = PandalTabFilter.favorites),
                ),
                const SizedBox(width: 8),
                _buildTabPill(
                  label: '✅ Hopped ($visitedCount)',
                  icon: Icons.check_circle_outline,
                  isSelected: _activeTab == PandalTabFilter.visited,
                  onTap: () => setState(() => _activeTab = PandalTabFilter.visited),
                ),
                const SizedBox(width: 8),
                _buildTabPill(
                  label: '📍 Nearby (10km)',
                  icon: Icons.near_me,
                  isSelected: _activeTab == PandalTabFilter.nearest,
                  onTap: () => setState(() => _activeTab = PandalTabFilter.nearest),
                ),
              ],
            ),
          ),

          // 3. Hopped Celebration Progress Bar (visible if on Visited tab or has visited pandals)
          if (_activeTab == PandalTabFilter.visited || visitedCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1B2E1D) : const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hopping Progress: $visitedCount of $totalCount Pandals Visited',
                            style: TextStyle(
                              fontSize: context.dynamicFont(11.5),
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${(progress * 100).toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: context.dynamicFont(12),
                              fontWeight: FontWeight.w900,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: Colors.green.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 4. Zone Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                FilterChip(
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  label: const Text('All Zones'),
                  selected: _selectedZone == null,
                  onSelected: (_) => setState(() => _selectedZone = null),
                ),
                ...KolkataZone.values.map(
                  (zone) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: FilterChip(
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      label: Text(zone.label),
                      selected: _selectedZone == zone,
                      onSelected: (selected) {
                        setState(() {
                          _selectedZone = selected ? zone : null;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // 5. Pandals or Food Stalls List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _showFoodOnly
                    ? _buildFoodListView(locationService, isDark)
                    : displayList.isEmpty
                        ? _buildEmptyState(isDark)
                        : RefreshIndicator(
                            onRefresh: _loadPandals,
                            child: ListView.builder(
                              scrollCacheExtent: const ScrollCacheExtent.pixels(600.0),
                              physics: const BouncingScrollPhysics(
                                parent: AlwaysScrollableScrollPhysics(),
                              ),
                              itemCount: displayList.length,
                              itemBuilder: (context, index) {
                                final p = displayList[index];
                                final delayMs = (index < 8) ? index * 30 : 0;
                                return AnimatedFadeSlide(
                                  key: ValueKey('pandal_${p.id}'),
                                  delay: Duration(milliseconds: delayMs),
                                  child: PandalCard(
                                    pandal: p,
                                    onTap: () => PandalDetailSheet.show(context, p),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill({
    required String label,
    IconData? icon,
    Widget? customIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: context.scale(13),
          vertical: context.scale(6.5),
        ),
        decoration: BoxDecoration(
          color: isSelected ? PujaColors.crimsonVelvet : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? PujaColors.festivalGold
                : PujaColors.festivalGold.withValues(alpha: 0.35),
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: PujaColors.crimsonVelvet.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            customIcon ??
                Icon(
                  icon!,
                  size: context.dynamicIcon(14),
                  color: isSelected ? PujaColors.goldBright : PujaColors.festivalGold,
                ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? PujaColors.goldBright : null,
                fontSize: context.dynamicFont(11.5),
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    String message = 'No pandals match your criteria.';
    if (_activeTab == PandalTabFilter.favorites) {
      message = 'No favorites yet!\nTap the heart icon on any pandal card to bookmark it.';
    } else if (_activeTab == PandalTabFilter.visited) {
      message = 'No visited pandals yet!\nTap "Mark as Visited" on any pandal to track your hopping.';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _activeTab == PandalTabFilter.favorites
                  ? Icons.favorite_border
                  : (_activeTab == PandalTabFilter.visited ? Icons.check_circle_outline : Icons.search_off),
              size: 56,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodListView(LocationService? locationService, bool isDark) {
    final foodList = _getFilteredFoodSpots(locationService);

    if (foodList.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant_outlined, size: 48, color: Colors.orange),
              ),
              const SizedBox(height: 16),
              Text(
                _activeTab == PandalTabFilter.nearest
                    ? 'No food stalls found within 10 km'
                    : 'No food stalls match your search',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _activeTab == PandalTabFilter.nearest
                    ? 'Try selecting the "All" tab or updating your GPS location to explore stalls across Kolkata.'
                    : 'Try clearing the search query or exploring nearby areas.',
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white60 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPandals,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        itemCount: foodList.length,
        itemBuilder: (context, index) {
          final f = foodList[index];
          return AnimatedFadeSlide(
            key: ValueKey('food_${f.id}'),
            delay: Duration(milliseconds: (index < 8) ? index * 30 : 0),
            child: _buildFoodSpotCard(f, locationService, isDark),
          );
        },
      ),
    );
  }

  Widget _buildFoodSpotCard(FoodSpot f, LocationService? locationService, bool isDark) {
    final pos = locationService?.lastPosition;
    final rawLat = pos?.latitude ?? AppConfig.defaultLat;
    final rawLng = pos?.longitude ?? AppConfig.defaultLng;
    final isFarAway = haversineMeters(rawLat, rawLng, AppConfig.defaultLat, AppConfig.defaultLng) > 70000;
    final userLat = isFarAway ? AppConfig.defaultLat : rawLat;
    final userLng = isFarAway ? AppConfig.defaultLng : rawLng;
    final distStr = formatDistance(haversineMeters(userLat, userLng, f.lat, f.lng));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: isDark ? 1 : 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.restaurant_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.name,
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15.5),
                      ),
                      const SizedBox(height: 3),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              f.type,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                          ),
                          if (f.rating != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C853).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.star_rounded, size: 12, color: Color(0xFF00C853)),
                                  const SizedBox(width: 2),
                                  Text(
                                    f.rating!.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF00C853),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (f.priceRange != null)
                            Text(
                              f.priceRange!,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white60 : Colors.black54,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (distStr.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: PujaColors.durgaRed.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      distStr,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: PujaColors.durgaRed,
                      ),
                    ),
                  ),
              ],
            ),
            if (f.mustTry != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E1C12) : const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '🍲 Must Try: ${f.mustTry}',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFFFAB40) : const Color(0xFFD84315),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    '📍 Near ${f.nearbyPandal}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.map_outlined, size: 14, color: PujaColors.festivalGold),
                      label: const Text(
                        'Map',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PujaColors.festivalGold),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        MapScreen.centerOnFoodSpot(context, f);
                      },
                    ),
                    const SizedBox(width: 4),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.directions_walk_rounded, size: 14, color: PujaColors.festivalGold),
                      label: const Text(
                        'Trace Path',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: PujaColors.festivalGold),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        MapScreen.routeToFoodSpot(context, f);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
