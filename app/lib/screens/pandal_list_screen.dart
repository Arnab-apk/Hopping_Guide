import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../repositories/local_pandal_repository.dart';
import '../repositories/pandal_repository.dart';
import '../services/location_service.dart';
import '../services/pandal_user_state_service.dart';
import '../utils/constants.dart';
import '../utils/responsive.dart';
import '../widgets/pandal_card.dart';
import '../widgets/pandal_detail_sheet.dart';

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
  bool _isLoading = true;

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
    final data = await _repo.all();
    if (!mounted) return;
    setState(() {
      _allPandals = data;
      _isLoading = false;
    });
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
    }

    // Zone filter
    if (_selectedZone != null) {
      list = list.where((p) => p.zone == _selectedZone).toList();
    }

    // Search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((p) {
        final nameMatch = p.name.toLowerCase().contains(q);
        final areaMatch = (p.area ?? '').toLowerCase().contains(q);
        final themeMatch = p.theme.toLowerCase().contains(q);
        final metroMatch = (p.nearestMetro ?? '').toLowerCase().contains(q);
        return nameMatch || areaMatch || themeMatch || metroMatch;
      }).toList();
    }

    // Sorting
    final effectiveSort = _activeTab == PandalTabFilter.nearest
        ? PandalSortOption.nearestFirst
        : _currentSort;

    switch (effectiveSort) {
      case PandalSortOption.nearestFirst:
        if (locationService != null) {
          list.sort((a, b) {
            final distA = locationService.distanceToMeters(a.latitude, a.longitude);
            final distB = locationService.distanceToMeters(b.latitude, b.longitude);
            return distA.compareTo(distB);
          });
        }
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
          // 1. Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by pandal, theme, metro, zone...',
                prefixIcon: Icon(Icons.search, color: PujaColors.festivalGold, size: context.dynamicIcon(20)),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, size: context.dynamicIcon(18)),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? PujaColors.nightCard : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: PujaColors.festivalGold.withValues(alpha: 0.25),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: PujaColors.festivalGold.withValues(alpha: 0.25),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: PujaColors.festivalGold,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
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
                  icon: Icons.temple_hindu_outlined,
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
                  label: '📍 Nearest to Me',
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
                  label: const Text('All Zones'),
                  selected: _selectedZone == null,
                  onSelected: (_) => setState(() => _selectedZone = null),
                ),
                ...KolkataZone.values.map(
                  (zone) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: FilterChip(
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

          // 5. Pandals List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayList.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: _loadPandals,
                        child: ListView.builder(
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final p = displayList[index];
                            return PandalCard(
                              pandal: p,
                              onTap: () => PandalDetailSheet.show(context, p),
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
    required IconData icon,
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
            Icon(
              icon,
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
}
