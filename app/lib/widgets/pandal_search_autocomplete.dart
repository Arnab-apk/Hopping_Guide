import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';
import '../models/metro_station.dart';
import '../models/pandal.dart';
import '../repositories/metro_repository.dart';
import '../repositories/supplementary_repository.dart';
import '../services/omni_search_service.dart';
import '../utils/haversine.dart';
import '../utils/responsive.dart';
import 'durga_face_icon.dart';

/// Translucent, frosted-glass Universal Omni-Search Bar and auto-complete overlay.
/// Inspired by Arch Linux / Rofi / Spotlight omni-search.
/// Searches simultaneously across Pandals, Metro Stations, and Food Spots.
class PandalSearchAutocomplete extends StatefulWidget {
  const PandalSearchAutocomplete({
    super.key,
    required this.pandals,
    required this.onPandalSelected,
    this.onMetroSelected,
    this.onFoodSpotSelected,
    this.foodSpots,
    this.metroStations,
    this.onQueryChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.userLat,
    this.userLng,
    this.hintText = 'Search pandals, metro, food spots...',
    this.autoFocus = false,
    this.isFloatingOnMap = false,
  });

  final List<Pandal> pandals;
  final void Function(Pandal pandal) onPandalSelected;
  final void Function(MetroStation metro)? onMetroSelected;
  final void Function(FoodSpot foodSpot)? onFoodSpotSelected;
  final List<FoodSpot>? foodSpots;
  final List<MetroStation>? metroStations;
  final void Function(String query)? onQueryChanged;
  final void Function(String query)? onSubmitted;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final double? userLat;
  final double? userLng;
  final String hintText;
  final bool autoFocus;
  final bool isFloatingOnMap;

  @override
  State<PandalSearchAutocomplete> createState() => _PandalSearchAutocompleteState();
}

class _PandalSearchAutocompleteState extends State<PandalSearchAutocomplete> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;
  bool _ownsController = false;
  bool _ownsFocusNode = false;

  List<OmniSearchResult> _suggestions = [];
  bool _showDropdown = false;
  OmniCategory _selectedCategory = OmniCategory.all;

  static const List<_QuickSearchPrompt> _popularPrompts = [
    _QuickSearchPrompt('Sreebhumi', OmniCategory.pandals, '🏛️'),
    _QuickSearchPrompt('Shyambazar Metro', OmniCategory.metro, '🚇'),
    _QuickSearchPrompt('Golbari', OmniCategory.food, '🍽️'),
    _QuickSearchPrompt('Mitra Cafe', OmniCategory.food, '🍽️'),
    _QuickSearchPrompt('Ekdalia Evergreen', OmniCategory.pandals, '🏛️'),
    _QuickSearchPrompt('College Square', OmniCategory.pandals, '🏛️'),
    _QuickSearchPrompt('Esplanade Metro', OmniCategory.metro, '🚇'),
    _QuickSearchPrompt('Maddox Square', OmniCategory.pandals, '🏛️'),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.controller != null) {
      _controller = widget.controller!;
    } else {
      _controller = TextEditingController();
      _ownsController = true;
    }

    if (widget.focusNode != null) {
      _focusNode = widget.focusNode!;
    } else {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    }

    _controller.addListener(_handleTextChange);
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChange);
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _showDropdown = _focusNode.hasFocus;
      if (_focusNode.hasFocus) {
        _updateSuggestions(_controller.text);
      }
    });
  }

  void _handleTextChange() {
    final query = _controller.text;
    widget.onQueryChanged?.call(query);
    _updateSuggestions(query);
  }

  void _updateSuggestions(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
      });
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final normalStyle = TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : Colors.black87,
    );
    final highlightStyle = const TextStyle(
      fontSize: 14.0,
      fontWeight: FontWeight.w900,
      color: PujaColors.festivalGold,
      decoration: TextDecoration.underline,
      decorationColor: PujaColors.festivalGold,
      decorationThickness: 1.6,
    );

    final results = OmniSearchService.instance.search(
      query: query,
      pandals: widget.pandals,
      foodSpots: widget.foodSpots,
      metroStations: widget.metroStations ?? MetroRepository.allStations,
      category: _selectedCategory,
      limit: 8,
      userLat: widget.userLat,
      userLng: widget.userLng,
      normalStyle: normalStyle,
      highlightStyle: highlightStyle,
    );

    setState(() {
      _suggestions = results;
      _showDropdown = true;
    });
  }

  void _onResultSelected(OmniSearchResult result) {
    HapticFeedback.selectionClick();
    OmniSearchService.instance.addRecentSearch(result.title);
    _controller.text = result.title;
    _focusNode.unfocus();
    setState(() => _showDropdown = false);

    switch (result.type) {
      case OmniResultType.pandal:
        if (result.pandal != null) {
          widget.onPandalSelected(result.pandal!);
        }
        break;
      case OmniResultType.metro:
        if (result.metroStation != null) {
          if (widget.onMetroSelected != null) {
            widget.onMetroSelected!(result.metroStation!);
          } else {
            // Fallback: if no dedicated metro callback, find first pandal nearby
            final nearbyPandalName = result.metroStation!.popularPandalsNearby.firstOrNull;
            if (nearbyPandalName != null) {
              final matchedPandal = widget.pandals.firstWhere(
                (p) => p.name.toLowerCase().contains(nearbyPandalName.toLowerCase()),
                orElse: () => widget.pandals.first,
              );
              widget.onPandalSelected(matchedPandal);
            }
          }
        }
        break;
      case OmniResultType.food:
        if (result.foodSpot != null) {
          if (widget.onFoodSpotSelected != null) {
            widget.onFoodSpotSelected!(result.foodSpot!);
          } else {
            // Fallback: find nearest pandal
            final nearbyPandal = widget.pandals.firstWhere(
              (p) => p.name.toLowerCase().contains(result.foodSpot!.nearbyPandal.toLowerCase()),
              orElse: () => widget.pandals.first,
            );
            widget.onPandalSelected(nearbyPandal);
          }
        }
        break;
    }
  }

  void _selectQueryPrompt(String query, OmniCategory category) {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedCategory = category;
    });
    _controller.text = query;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _updateSuggestions(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final hasText = _controller.text.trim().isNotEmpty;
    final recentList = OmniSearchService.instance.recentSearches;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Translucent Frosted-Glass Search Input Bar
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? (widget.isFloatingOnMap
                        ? PujaColors.nightSurface.withValues(alpha: 0.85)
                        : PujaColors.nightCard)
                    : (widget.isFloatingOnMap
                        ? Colors.white.withValues(alpha: 0.88)
                        : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? PujaColors.festivalGold
                      : PujaColors.festivalGold.withValues(alpha: 0.35),
                  width: _focusNode.hasFocus ? 1.8 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _focusNode.hasFocus
                        ? PujaColors.festivalGold.withValues(alpha: 0.22)
                        : Colors.black.withValues(alpha: widget.isFloatingOnMap ? 0.25 : 0.08),
                    blurRadius: widget.isFloatingOnMap ? 16 : 6,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search TextField Row
                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(left: 14.0, right: 8.0),
                        child: DurgaFaceIcon(
                          size: context.dynamicIcon(21),
                          color: PujaColors.festivalGold,
                          bindiColor: const Color(0xFFFF1744),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          autofocus: widget.autoFocus,
                          style: TextStyle(
                            fontSize: context.dynamicFont(13.8),
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: TextStyle(
                              fontSize: context.dynamicFont(12.5),
                              color: isDark ? Colors.white54 : Colors.black45,
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 13),
                          ),
                          onSubmitted: (val) {
                            if (_suggestions.isNotEmpty) {
                              _onResultSelected(_suggestions.first);
                            } else {
                              _focusNode.unfocus();
                              setState(() => _showDropdown = false);
                              widget.onSubmitted?.call(val);
                            }
                          },
                        ),
                      ),
                      if (hasText)
                        IconButton(
                          icon: Icon(
                            Icons.clear_rounded,
                            size: context.dynamicIcon(18),
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                          tooltip: 'Clear',
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            _controller.clear();
                            _focusNode.unfocus();
                            setState(() {
                              _showDropdown = false;
                              _suggestions = [];
                            });
                          },
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 14.0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: PujaColors.festivalGold.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_rounded,
                                  size: context.dynamicIcon(15),
                                  color: PujaColors.festivalGold,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'OMNI',
                                  style: TextStyle(
                                    fontSize: context.dynamicFont(9.5),
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.8,
                                    color: PujaColors.festivalGold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Category Filter Chips (Shown when focused or actively typing)
                  if (_focusNode.hasFocus || _showDropdown) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
                      child: Row(
                        children: OmniCategory.values.map((cat) {
                          final isSelected = _selectedCategory == cat;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2.0),
                              child: InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => _selectedCategory = cat);
                                  _updateSuggestions(_controller.text);
                                },
                                borderRadius: BorderRadius.circular(10),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? PujaColors.festivalGold
                                        : (isDark
                                            ? Colors.white.withValues(alpha: 0.08)
                                            : Colors.black.withValues(alpha: 0.05)),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: isSelected
                                          ? PujaColors.goldBright
                                          : Colors.transparent,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        cat.icon,
                                        size: context.dynamicIcon(11),
                                        color: isSelected
                                            ? Colors.black
                                            : (isDark ? Colors.white70 : Colors.black87),
                                      ),
                                      const SizedBox(width: 3),
                                      Text(
                                        cat.label,
                                        style: TextStyle(
                                          fontSize: context.dynamicFont(10),
                                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                          color: isSelected
                                              ? Colors.black
                                              : (isDark ? Colors.white70 : Colors.black87),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // 2. Auto-Complete Suggestions Frosted Glass Overlay
        if (_showDropdown) ...[
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: math.min(300.0, MediaQuery.sizeOf(context).height * 0.42),
                ),
                decoration: BoxDecoration(
                  color: isDark
                      ? PujaColors.nightSurface.withValues(alpha: 0.90)
                      : Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: PujaColors.festivalGold.withValues(alpha: 0.40),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.32),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // A. When Query is Empty -> Show Popular & Recent Searches
                      if (!hasText) ...[
                        // Popular Prompts Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                          child: Row(
                            children: [
                              const Text('⚡ ', style: TextStyle(fontSize: 13)),
                              Text(
                                'Popular Destinations',
                                style: TextStyle(
                                  fontSize: context.dynamicFont(12),
                                  fontWeight: FontWeight.w800,
                                  color: PujaColors.festivalGold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: _popularPrompts.map((item) {
                              return ActionChip(
                                visualDensity: VisualDensity.compact,
                                backgroundColor: isDark
                                    ? PujaColors.nightCard.withValues(alpha: 0.8)
                                    : const Color(0xFFFFF8E1),
                                side: BorderSide(
                                  color: PujaColors.festivalGold.withValues(alpha: 0.35),
                                ),
                                avatar: Text(item.emoji, style: const TextStyle(fontSize: 12)),
                                label: Text(
                                  item.title,
                                  style: TextStyle(
                                    fontSize: context.dynamicFont(11),
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                                onPressed: () => _selectQueryPrompt(item.title, item.category),
                              );
                            }).toList(),
                          ),
                        ),

                        // Recent Searches Section
                        if (recentList.isNotEmpty) ...[
                          const Divider(height: 14),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.history_rounded, size: 14, color: Colors.grey),
                                    const SizedBox(width: 5),
                                    Text(
                                      'Recent Searches',
                                      style: TextStyle(
                                        fontSize: context.dynamicFont(11.5),
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white60 : Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                                GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    setState(() {
                                      OmniSearchService.instance.clearRecentSearches();
                                    });
                                  },
                                  child: Text(
                                    'Clear',
                                    style: TextStyle(
                                      fontSize: context.dynamicFont(11),
                                      fontWeight: FontWeight.bold,
                                      color: PujaColors.durgaRed,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...recentList.map((recent) {
                            return Material(
                              color: Colors.transparent,
                              child: ListTile(
                                dense: true,
                                visualDensity: VisualDensity.compact,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 0),
                                leading: const Icon(Icons.search, size: 15, color: Colors.grey),
                                title: Text(
                                  recent,
                                  style: TextStyle(
                                    fontSize: context.dynamicFont(12.5),
                                    color: isDark ? Colors.white70 : Colors.black87,
                                  ),
                                ),
                                trailing: const Icon(Icons.north_west_rounded, size: 13, color: Colors.grey),
                                onTap: () => _selectQueryPrompt(recent, OmniCategory.all),
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 8),
                      ]

                      // B. When Query is Active and Matches Found
                      else if (_suggestions.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Matches (${_suggestions.length} found)',
                                style: TextStyle(
                                  fontSize: context.dynamicFont(11),
                                  fontWeight: FontWeight.bold,
                                  color: PujaColors.festivalGold,
                                ),
                              ),
                              Text(
                                'Tap to highlight on map',
                                style: TextStyle(
                                  fontSize: context.dynamicFont(10.5),
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 8),
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _suggestions.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1, indent: 14, endIndent: 14),
                          itemBuilder: (context, index) {
                            final res = _suggestions[index];
                            final distStr = res.distanceMeters != null
                                ? formatDistance(res.distanceMeters!)
                                : null;

                            return InkWell(
                              onTap: () => _onResultSelected(res),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    // Category Avatar
                                    Container(
                                      padding: const EdgeInsets.all(7),
                                      decoration: BoxDecoration(
                                        color: res.accentColor.withValues(alpha: 0.16),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: res.accentColor.withValues(alpha: 0.4),
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                        res.icon,
                                        size: context.dynamicIcon(16),
                                        color: res.accentColor,
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Main Details with Highlight Spans
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          RichText(
                                            text: TextSpan(children: res.highlightSpans),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Wrap(
                                            spacing: 6,
                                            runSpacing: 2,
                                            crossAxisAlignment: WrapCrossAlignment.center,
                                            children: [
                                              // Badge
                                              if (res.badgeText != null)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                      horizontal: 5, vertical: 1),
                                                  decoration: BoxDecoration(
                                                    color: (res.badgeColor ?? PujaColors.festivalGold)
                                                        .withValues(alpha: 0.18),
                                                    borderRadius: BorderRadius.circular(4),
                                                  ),
                                                  child: Text(
                                                    res.badgeText!,
                                                    style: TextStyle(
                                                      fontSize: context.dynamicFont(9),
                                                      fontWeight: FontWeight.w800,
                                                      color: res.badgeColor ?? PujaColors.festivalGold,
                                                    ),
                                                  ),
                                                ),
                                              Text(
                                                res.subtitle,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: context.dynamicFont(10.5),
                                                  fontWeight: FontWeight.w500,
                                                  color: isDark ? Colors.white60 : Colors.black54,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Distance & Rating Column
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (distStr != null)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: PujaColors.festivalGold.withValues(alpha: 0.15),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: PujaColors.festivalGold.withValues(alpha: 0.3),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              distStr,
                                              style: TextStyle(
                                                fontSize: context.dynamicFont(10),
                                                fontWeight: FontWeight.w800,
                                                color: PujaColors.festivalGold,
                                              ),
                                            ),
                                          ),
                                        if (res.rating != null) ...[
                                          const SizedBox(height: 2),
                                          Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.star_rounded,
                                                  size: 12, color: PujaColors.goldBright),
                                              const SizedBox(width: 2),
                                              Text(
                                                res.rating!.toStringAsFixed(1),
                                                style: TextStyle(
                                                  fontSize: context.dynamicFont(10),
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark ? Colors.white70 : Colors.black87,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 4),
                      ]

                      // C. When Query is Active but No Matches
                      else ...[
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            children: [
                              Icon(
                                Icons.travel_explore_rounded,
                                size: 36,
                                color: isDark ? Colors.white38 : Colors.grey,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'No results match "${_controller.text}"',
                                style: TextStyle(
                                  fontSize: context.dynamicFont(13),
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white70 : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Try searching for pandals (e.g. Sreebhumi), metro stations (e.g. Kalighat), or food (e.g. Biryani, Golbari).',
                                style: TextStyle(
                                  fontSize: context.dynamicFont(11),
                                  color: isDark ? Colors.white54 : Colors.black54,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickSearchPrompt {
  const _QuickSearchPrompt(this.title, this.category, this.emoji);
  final String title;
  final OmniCategory category;
  final String emoji;
}
