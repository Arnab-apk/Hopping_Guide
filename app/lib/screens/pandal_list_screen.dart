import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../config/app_config.dart';
import '../config/theme.dart';
import '../models/pandal.dart';
import '../models/place.dart';
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
import '../widgets/pandal_card.dart';
import '../widgets/pandal_detail_sheet.dart';
import '../widgets/pandal_search_autocomplete.dart';
import '../widgets/puja_icons.dart';
import 'main_navigation_screen.dart';
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

  /// Global notifier allowing external callers (e.g. Map screen "Food (66)" chip)
  /// to deep-link directly into a specific category segment on this screen.
  static final ValueNotifier<PlaceCategory?> externalCategoryNotifier =
      ValueNotifier<PlaceCategory?>(null);

  /// Programmatically switch to any category segment and bring this tab to the foreground.
  static void switchToCategory(PlaceCategory category) {
    externalCategoryNotifier.value = category;
    MainNavigationScreen.switchToTab(1);
  }

  @override
  State<PandalListScreen> createState() => _PandalListScreenState();
}

class _PandalListScreenState extends State<PandalListScreen> {
  late final PandalRepository _repo;

  PlaceCategory _category = PlaceCategory.pandal;
  List<Place> _allPlaces = [];
  List<Pandal> _allPandals = [];
  List<FoodSpot> _allFoodSpots = [];
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

    PandalListScreen.externalCategoryNotifier.addListener(_handleExternalCategorySwitch);
    if (PandalListScreen.externalCategoryNotifier.value != null) {
      _category = PandalListScreen.externalCategoryNotifier.value!;
      PandalListScreen.externalCategoryNotifier.value = null;
    }

    _loadPlaces();
  }

  void _handleExternalCategorySwitch() {
    final target = PandalListScreen.externalCategoryNotifier.value;
    if (target != null && mounted) {
      PandalListScreen.externalCategoryNotifier.value = null;
      _onCategoryChanged(target);
    }
  }

  @override
  void dispose() {
    PandalListScreen.externalCategoryNotifier.removeListener(_handleExternalCategorySwitch);
    _searchController.dispose();
    super.dispose();
  }

  /// Queries the repository strictly for the active category, guaranteeing that
  /// no food spots leak into the pandals list and vice versa at the data layer.
  Future<void> _loadPlaces() async {
    setState(() => _isLoading = true);
    final places = await _repo.getPlaces(category: _category);
    if (!mounted) return;

    setState(() {
      _allPlaces = places;
      if (_category == PlaceCategory.pandal) {
        _allPandals = places.map((p) => p.rawPandal ?? Pandal.fromMap(p.id, p.toMap())).toList();
      } else {
        _allFoodSpots = places.map((p) => p.rawFoodSpot ?? FoodSpot.fromJson(p.toMap())).toList();
      }
      _isLoading = false;
    });
  }

  void _onCategoryChanged(PlaceCategory newCat) {
    if (_category == newCat) return;
    HapticFeedback.selectionClick();
    setState(() {
      _category = newCat;
      _activeTab = PandalTabFilter.all;
      _selectedZone = null;
      _searchQuery = '';
      _searchController.clear();
    });
    // Re-run the query from the repository for the selected category
    _loadPlaces();
  }

  List<Place> _getFilteredPlaces(
    PandalUserStateService? userState,
    LocationService? locationService,
  ) {
    var list = List<Place>.from(_allPlaces);

    // Tab filter (Favorites, Visited/Hopped, Nearest)
    if (_activeTab == PandalTabFilter.favorites && userState != null) {
      list = list.where((p) => userState.isFavorite(p.id)).toList();
    } else if (_activeTab == PandalTabFilter.visited && userState != null && _category == PlaceCategory.pandal) {
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

      list.sort((a, b) {
        final da = haversineMeters(userLat, userLng, a.lat, a.lng);
        final db = haversineMeters(userLat, userLng, b.lat, b.lng);
        return da.compareTo(db);
      });
    }

    // Zone filter
    if (_selectedZone != null) {
      list = list.where((p) => p.zone == _selectedZone).toList();
    }

    // Keyword Matching Search query
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      if (_category == PlaceCategory.pandal) {
        final scoredResults = <String, double>{};
        list = list.where((p) {
          if (p.rawPandal != null) {
            final result = PandalSearchService.instance.scorePandal(p.rawPandal!, _searchQuery.trim());
            if (result != null) {
              scoredResults[p.id] = result.score;
              return true;
            }
          }
          final nameMatch = p.name.toLowerCase().contains(q);
          final themeMatch = (p.theme ?? '').toLowerCase().contains(q);
          final metroMatch = (p.nearestMetro ?? '').toLowerCase().contains(q);
          return nameMatch || themeMatch || metroMatch;
        }).toList();

        if (_currentSort == PandalSortOption.defaultOrder && _activeTab != PandalTabFilter.nearest) {
          list.sort((a, b) => (scoredResults[b.id] ?? 0.0).compareTo(scoredResults[a.id] ?? 0.0));
        }
      } else {
        list = list.where((p) {
          final nameMatch = p.name.toLowerCase().contains(q);
          final typeMatch = (p.type ?? '').toLowerCase().contains(q);
          final mustTryMatch = (p.mustTry ?? '').toLowerCase().contains(q);
          final pandalMatch = (p.nearbyPandal ?? '').toLowerCase().contains(q);
          return nameMatch || typeMatch || mustTryMatch || pandalMatch;
        }).toList();
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

    final displayList = _getFilteredPlaces(userState, locationService);
    final visitedCount = userState?.visitedCount ?? 0;
    final totalCount = _allPlaces.length;
    final progress = (_category == PlaceCategory.pandal && totalCount > 0)
        ? (visitedCount / totalCount).clamp(0.0, 1.0)
        : 0.0;
    final statusPills = _buildStatusPills(
      context: context,
      category: _category,
      userState: userState,
      isDark: isDark,
    );

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          _category == PlaceCategory.pandal ? 'Kolkata Pandals' : 'Food Spots',
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort_rounded),
            tooltip: 'Sort & Options',
            onSelected: (val) async {
              if (val == 'update_gps') {
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
              } else if (val == 'defaultOrder') {
                setState(() => _currentSort = PandalSortOption.defaultOrder);
              } else if (val == 'nearestFirst') {
                setState(() => _currentSort = PandalSortOption.nearestFirst);
              } else if (val == 'ratingHighToLow') {
                setState(() => _currentSort = PandalSortOption.ratingHighToLow);
              } else if (val == 'lowCrowdFirst') {
                setState(() => _currentSort = PandalSortOption.lowCrowdFirst);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'defaultOrder',
                child: Text('Default Order'),
              ),
              const PopupMenuItem(
                value: 'nearestFirst',
                child: Text('📍 Nearest to Me'),
              ),
              const PopupMenuItem(
                value: 'ratingHighToLow',
                child: Text('⭐ Highest Rated'),
              ),
              if (_category == PlaceCategory.pandal)
                const PopupMenuItem(
                  value: 'lowCrowdFirst',
                  child: Text('🟢 Least Crowded First'),
                ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'update_gps',
                child: Row(
                  children: [
                    Icon(Icons.my_location, size: 18),
                    SizedBox(width: 8),
                    Text('Refresh GPS Location'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Segmented Control Switcher ([ Pandals ] [ Food Spots ])
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<PlaceCategory>(
                segments: const [
                  ButtonSegment<PlaceCategory>(
                    value: PlaceCategory.pandal,
                    label: Text('Pandals'),
                    icon: Icon(Icons.temple_hindu_rounded),
                  ),
                  ButtonSegment<PlaceCategory>(
                    value: PlaceCategory.foodSpot,
                    label: Text('Food Spots'),
                    icon: Icon(Icons.restaurant_rounded),
                  ),
                ],
                selected: {_category},
                onSelectionChanged: (Set<PlaceCategory> newSelection) {
                  _onCategoryChanged(newSelection.first);
                },
              ),
            ),
          ),

          // 2. Search Bar with Instant Keyword Matching & Autocomplete
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: PandalSearchAutocomplete(
              pandals: _category == PlaceCategory.pandal ? _allPandals : const [],
              foodSpots: _category == PlaceCategory.foodSpot ? _allFoodSpots : const [],
              metroStations: _category == PlaceCategory.pandal ? null : const [],
              controller: _searchController,
              userLat: locationService?.lastPosition?.latitude,
              userLng: locationService?.lastPosition?.longitude,
              hintText: _category == PlaceCategory.pandal
                  ? 'Search by pandal, area, metro, theme...'
                  : 'Search by restaurant, cuisine, area...',
              onQueryChanged: (val) {
                setState(() => _searchQuery = val);
              },
              onPandalSelected: (pandal) {
                PandalDetailSheet.show(context, pandal);
              },
              onFoodSpotSelected: (foodSpot) {
                MapScreen.centerOnFoodSpot(context, foodSpot);
              },
            ),
          ),

          // 3. Category Filter Chips (Assembled dynamically per category)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                for (int i = 0; i < statusPills.length; i++) ...[
                  if (i > 0) const SizedBox(width: 8),
                  statusPills[i],
                ],
              ],
            ),
          ),

          // 4. Hopping Progress Bar (Strictly for Pandals Segment)
          if (_category == PlaceCategory.pandal &&
              (_activeTab == PandalTabFilter.visited || visitedCount > 0))
            _buildHoppingProgressBar(
              context: context,
              isDark: isDark,
              visitedCount: visitedCount,
              totalCount: totalCount,
              progress: progress,
            ),

          const Divider(height: 1),

          // 5. Places List View
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayList.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: _loadPlaces,
                        child: ListView.builder(
                          scrollCacheExtent: const ScrollCacheExtent.pixels(600.0),
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          itemCount: displayList.length,
                          itemBuilder: (context, index) {
                            final place = displayList[index];
                            final delayMs = (index < 8) ? index * 30 : 0;
                            return AnimatedFadeSlide(
                              key: ValueKey('${place.category.name}_${place.id}'),
                              delay: Duration(milliseconds: delayMs),
                              child: PlaceCard(
                                place: place,
                                onTap: () {
                                  if (place.isPandal && place.rawPandal != null) {
                                    PandalDetailSheet.show(context, place.rawPandal!);
                                  } else if (place.isFoodSpot && place.rawFoodSpot != null) {
                                    MapScreen.centerOnFoodSpot(context, place.rawFoodSpot!);
                                  }
                                },
                                onMapTap: place.isFoodSpot && place.rawFoodSpot != null
                                    ? () => MapScreen.centerOnFoodSpot(context, place.rawFoodSpot!)
                                    : null,
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

  /// Dynamically assembles the status filter pills based on the active category.
  /// Strictly isolates favorites count per category and ensures pandal-only pills
  /// (such as "Hopped") are completely omitted when browsing food spots.
  List<Widget> _buildStatusPills({
    required BuildContext context,
    required PlaceCategory category,
    required PandalUserStateService? userState,
    required bool isDark,
  }) {
    final pills = <Widget>[];

    // 1. All places pill
    pills.add(
      _buildTabPill(
        label: 'All (${_allPlaces.length})',
        customIcon: category == PlaceCategory.pandal
            ? PujaIcon.durgaFace(
                size: context.dynamicIcon(22),
                color: _activeTab == PandalTabFilter.all
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              )
            : Icon(
                Icons.restaurant_rounded,
                size: context.dynamicIcon(18),
                color: _activeTab == PandalTabFilter.all
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        isSelected: _activeTab == PandalTabFilter.all,
        onTap: () => setState(() => _activeTab = PandalTabFilter.all),
      ),
    );

    // 2. Favorites pill — count strictly isolated by active category
    final categoryFavoritesCount = userState != null
        ? _allPlaces.where((p) => userState.isFavorite(p.id)).length
        : 0;
    pills.add(
      _buildTabPill(
        label: 'Favorites ($categoryFavoritesCount)',
        customIcon: PujaIcon.kalash(
          size: context.dynamicIcon(22),
          color: _activeTab == PandalTabFilter.favorites
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        isSelected: _activeTab == PandalTabFilter.favorites,
        onTap: () => setState(() => _activeTab = PandalTabFilter.favorites),
      ),
    );

    // 3. Hopped pill — strictly Pandal-only. Never added to Food Spots.
    if (category == PlaceCategory.pandal) {
      final visitedCount = userState?.visitedCount ?? 0;
      pills.add(
        _buildTabPill(
          label: 'Hopped ($visitedCount)',
          customIcon: PujaIcon.shankha(
            size: context.dynamicIcon(22),
            color: _activeTab == PandalTabFilter.visited
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          isSelected: _activeTab == PandalTabFilter.visited,
          onTap: () => setState(() => _activeTab = PandalTabFilter.visited),
        ),
      );
    }

    // 4. Nearby (10km) pill — shared across categories
    pills.add(
      _buildTabPill(
        label: 'Nearby (10km)',
        customIcon: PujaIcon.durgaEyes(
          size: context.dynamicIcon(22),
          color: _activeTab == PandalTabFilter.nearest
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        isSelected: _activeTab == PandalTabFilter.nearest,
        onTap: () => setState(() => _activeTab = PandalTabFilter.nearest),
      ),
    );

    // 5. Region/Area filter pill
    pills.add(_buildRegionPill(context, isDark));

    return pills;
  }

  Widget _buildHoppingProgressBar({
    required BuildContext context,
    required bool isDark,
    required int visitedCount,
    required int totalCount,
    required double progress,
  }) {
    return Padding(
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
    );
  }

  Widget _buildTabPill({
    required String label,
    IconData? icon,
    Widget? customIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        onTap();
      },
      avatar: customIcon ??
          (icon != null
              ? Icon(
                  icon,
                  size: context.dynamicIcon(15),
                  color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
                )
              : null),
      label: Text(label),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  Widget _buildRegionPill(BuildContext context, bool isDark) {
    final isSelected = _selectedZone != null;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FilterChip(
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        _showRegionBottomSheet(context, isDark);
      },
      avatar: Icon(
        Icons.tune_rounded,
        size: context.dynamicIcon(15),
        color: isSelected ? colorScheme.onSecondaryContainer : colorScheme.onSurfaceVariant,
      ),
      label: Text(
        _selectedZone != null ? _selectedZone!.shortLabel : 'Regions',
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      showCheckmark: false,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }

  void _showRegionBottomSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
                child: Row(
                  children: [
                    Text(
                      _category == PlaceCategory.pandal
                          ? 'Filter Pandals by Region'
                          : 'Filter Food Spots by Region',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const Spacer(),
                    if (_selectedZone != null)
                      TextButton(
                        onPressed: () {
                          setState(() => _selectedZone = null);
                          Navigator.pop(ctx);
                        },
                        child: const Text('Reset All'),
                      ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.all_inclusive_rounded, color: PujaColors.festivalGold),
                      title: Text(
                        _category == PlaceCategory.pandal ? 'All Kolkata Pandals' : 'All Kolkata Food Spots',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      trailing: _selectedZone == null ? const Icon(Icons.check_circle, color: Color(0xFF00E676)) : null,
                      onTap: () {
                        setState(() => _selectedZone = null);
                        Navigator.pop(ctx);
                      },
                    ),
                    ...KolkataZone.values.map((zone) {
                      final isSelected = _selectedZone == zone;
                      final count = _allPlaces.where((p) => p.zone == zone).length;
                      return ListTile(
                        leading: const Icon(Icons.location_on_outlined, color: PujaColors.durgaRed),
                        title: Text(zone.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          _category == PlaceCategory.pandal
                              ? '$count Pandals in ${zone.shortLabel}'
                              : '$count Food Spots in ${zone.shortLabel}',
                        ),
                        trailing: isSelected ? const Icon(Icons.check_circle, color: Color(0xFF00E676)) : null,
                        onTap: () {
                          setState(() => _selectedZone = zone);
                          Navigator.pop(ctx);
                        },
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    String title = _category == PlaceCategory.pandal ? 'No Pandals Found' : 'No Food Spots Found';
    String subtitle = 'Try adjusting your search query or selected filters.';
    String ctaText = _category == PlaceCategory.pandal ? 'View All Pandals' : 'View All Food Spots';
    VoidCallback onCta = () {
      setState(() {
        _searchQuery = '';
        _searchController.clear();
        _activeTab = PandalTabFilter.all;
        _selectedZone = null;
      });
    };

    if (_activeTab == PandalTabFilter.favorites) {
      title = _category == PlaceCategory.pandal ? 'No Favorites Yet' : 'No Favorite Food Spots';
      subtitle = _category == PlaceCategory.pandal
          ? 'Tap the heart icon on any pandal card to bookmark your favorites.'
          : 'Bookmark legendary food stops to build your Puja feast list.';
      ctaText = _category == PlaceCategory.pandal ? 'Explore Pandals' : 'Explore Food Spots';
    } else if (_activeTab == PandalTabFilter.visited && _category == PlaceCategory.pandal) {
      title = 'No Pandals Visited Yet';
      subtitle = 'Mark pandals as hopped to celebrate and track your journey.';
      ctaText = 'Start Hopping';
    } else if (_selectedZone != null) {
      title = _category == PlaceCategory.pandal
          ? 'No Pandals in ${_selectedZone!.shortLabel}'
          : 'No Food Spots in ${_selectedZone!.shortLabel}';
      subtitle = 'Try clearing the zone filter to view all places across Kolkata.';
      ctaText = 'Clear Region Filter';
      onCta = () => setState(() => _selectedZone = null);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _activeTab == PandalTabFilter.favorites
                  ? Icons.favorite_border_rounded
                  : (_activeTab == PandalTabFilter.visited
                      ? Icons.check_circle_outline_rounded
                      : Icons.search_off_rounded),
              size: 56,
              color: PujaColors.festivalGold,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.tonal(
              onPressed: onCta,
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              child: Text(ctaText),
            ),
          ],
        ),
      ),
    );
  }
}
