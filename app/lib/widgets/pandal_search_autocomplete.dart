import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/metro_station.dart';
import '../models/pandal.dart';
import '../repositories/metro_repository.dart';
import '../repositories/supplementary_repository.dart';
import '../services/omni_search_service.dart';
import '../utils/haversine.dart';
import '../utils/responsive.dart';
import 'puja_icons.dart';

/// Google Maps-styled Omni-Search Bar.
/// Features a floating stadium shape, search magnifying glass, clean Google typography,
/// clear icon button, and tonal suggestions dropdown.
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
    this.hintText = 'Search e.g. Sreebhumi, Kalighat, Golbari...',
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
  Timer? _focusDebounceTimer;

  List<OmniSearchResult> _suggestions = [];
  bool _showDropdown = false;

  static const List<String> _pandalExampleQueries = [
    'Sreebhumi Sporting Club',
    'Ekdalia Evergreen Club',
    'College Square',
    'Baghbazar Sarbojanin',
    'Suruchi Sangha',
    'Maddox Square',
  ];

  static const List<String> _foodExampleQueries = [
    'Golbari Kosha Mangsho',
    'Mitra Cafe Brain Chop',
    'Allen Kitchen Prawn Cutlet',
    'Chittaranjan Mistanna Bhandar',
    'Arsalan Biryani',
    'Paramount Sharbat',
  ];

  List<String> get _exampleQueries {
    if (widget.pandals.isEmpty && widget.foodSpots?.isNotEmpty == true) {
      return _foodExampleQueries;
    }
    return _pandalExampleQueries;
  }


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
    _focusDebounceTimer?.cancel();
    _controller.removeListener(_handleTextChange);
    _focusNode.removeListener(_handleFocusChange);
    if (_ownsController) _controller.dispose();
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  void _handleTextChange() {
    final query = _controller.text;
    widget.onQueryChanged?.call(query);
    _updateSuggestions(query);
  }

  void _handleFocusChange() {
    _focusDebounceTimer?.cancel();
    if (_focusNode.hasFocus) {
      _updateSuggestions(_controller.text);
      setState(() => _showDropdown = true);
    } else {
      // Delay closing dropdown slightly so tap on suggestion registers
      _focusDebounceTimer = Timer(const Duration(milliseconds: 250), () {
        if (mounted && !_focusNode.hasFocus) {
          setState(() => _showDropdown = false);
        }
      });
    }
  }

  void _updateSuggestions(String query) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (query.trim().isEmpty) {
      setState(() {
        _suggestions = [];
        _showDropdown = _focusNode.hasFocus;
      });
      return;
    }

    final normalStyle = GoogleFonts.plusJakartaSans(
      fontSize: 13.0,
      fontWeight: FontWeight.w500,
      color: colorScheme.onSurface,
    );
    final highlightStyle = GoogleFonts.plusJakartaSans(
      fontSize: 13.0,
      fontWeight: FontWeight.w700,
      color: colorScheme.primary,
    );

    final results = OmniSearchService.instance.search(
      query: query,
      pandals: widget.pandals,
      foodSpots: widget.foodSpots,
      metroStations: widget.metroStations ?? MetroRepository.allStations,
      category: OmniCategory.all,
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

  void _selectQueryPrompt(String query) {
    HapticFeedback.lightImpact();
    _controller.text = query;
    _controller.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    _updateSuggestions(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final hasText = _controller.text.trim().isNotEmpty;
    final recentList = OmniSearchService.instance.recentSearches;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Google Maps Style Floating Search Bar
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? (widget.isFloatingOnMap ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainer)
                : colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.6),
              width: _focusNode.hasFocus ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isFloatingOnMap ? 0.18 : 0.04),
                blurRadius: widget.isFloatingOnMap ? 12 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 14.0, right: 6.0),
                child: Icon(
                  Icons.search_rounded,
                  size: 22,
                  color: _focusNode.hasFocus ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autoFocus,
                  cursorColor: colorScheme.primary,
                  cursorWidth: 2.0,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: context.dynamicFont(13.8),
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: GoogleFonts.plusJakartaSans(
                      fontSize: context.dynamicFont(13.0),
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
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
                  iconSize: 20,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  icon: Icon(Icons.close_rounded, color: colorScheme.onSurfaceVariant),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _controller.clear();
                    _focusNode.unfocus();
                    setState(() {
                      _showDropdown = false;
                      _suggestions = [];
                    });
                  },
                ),
            ],
          ),
        ),

        // 2. Google M3 Suggestions & Examples Dropdown
        if (_showDropdown) ...[
          const SizedBox(height: 6),
          Container(
            constraints: BoxConstraints(
              maxHeight: math.min(300.0, MediaQuery.sizeOf(context).height * 0.42),
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? (widget.isFloatingOnMap ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainerLow)
                  : colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: isDark ? 0.35 : 0.5),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // A. When Query is Empty -> Show Clean Example Texts
                  if (!hasText) ...[
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                      child: Text(
                        'TRY SEARCHING',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: context.dynamicFont(10.5),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    ..._exampleQueries.map((example) {
                      return InkWell(
                        onTap: () => _selectQueryPrompt(example),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Icon(Icons.history_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                              const SizedBox(width: 10),
                              Text(
                                example,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: context.dynamicFont(12.5),
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),

                    // Recent Searches
                    if (recentList.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Divider(
                          height: 14,
                          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RECENT SEARCHES',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: context.dynamicFont(10.5),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: colorScheme.primary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                setState(() {
                                  OmniSearchService.instance.clearRecentSearches();
                                });
                              },
                              child: Text(
                                'Clear all',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: context.dynamicFont(11),
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...recentList.map((recent) {
                        return InkWell(
                          onTap: () => _selectQueryPrompt(recent),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                            child: Row(
                              children: [
                                Icon(Icons.manage_search_rounded, size: 16, color: colorScheme.onSurfaceVariant),
                                const SizedBox(width: 10),
                                Text(
                                  recent,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: context.dynamicFont(12.2),
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                    const SizedBox(height: 6),
                  ]

                  // B. Matches Found -> Clean Minimalist List Rows
                  else if (_suggestions.isNotEmpty) ...[
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _suggestions.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      ),
                      itemBuilder: (context, index) {
                        final res = _suggestions[index];
                        final distStr = res.distanceMeters != null
                            ? formatDistance(res.distanceMeters!)
                            : null;

                        return InkWell(
                          onTap: () => _onResultSelected(res),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: Row(
                              children: [
                                if (res.type == OmniResultType.pandal)
                                  PujaIcon.durgaFace(
                                    size: 24,
                                    color: colorScheme.primary,
                                  )
                                else if (res.type == OmniResultType.food)
                                  PujaIcon.bhogSweets(
                                    size: 24,
                                    color: const Color(0xFFFF9100),
                                  )
                                else
                                  Icon(
                                    Icons.directions_subway_rounded,
                                    size: 24,
                                    color: colorScheme.primary,
                                  ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      RichText(
                                        text: TextSpan(children: res.highlightSpans),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        res.subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: context.dynamicFont(11.0),
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (distStr != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    distStr,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: context.dynamicFont(11.0),
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ]

                  // C. Empty Search Message
                  else ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'No results for "${_controller.text}"',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: context.dynamicFont(13),
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Try searching for Sreebhumi, Kalighat, or Golbari',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: context.dynamicFont(11.5),
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
