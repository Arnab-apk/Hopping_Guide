import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../models/metro_station.dart';
import '../models/pandal.dart';
import '../repositories/metro_repository.dart';
import '../repositories/supplementary_repository.dart';
import '../services/omni_search_service.dart';
import '../utils/haversine.dart';
import '../utils/responsive.dart';

/// Minimalist, seamless Omni-Search Bar.
/// Zero clutter, no icons, pure clean typography with example suggestions.
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

  List<OmniSearchResult> _suggestions = [];
  bool _showDropdown = false;

  // Clean text-only examples
  static const List<String> _exampleQueries = [
    'Sreebhumi Sporting Club',
    'Kalighat Metro Station',
    'Golbari Kosha Mangsho',
    'Ekdalia Evergreen Club',
    'Esplanade Metro Station',
    'College Square',
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
    final normalStyle = GoogleFonts.jetBrainsMono(
      fontSize: 13.0,
      fontWeight: FontWeight.w500,
      color: isDark ? Colors.white : Colors.black87,
    );
    final highlightStyle = GoogleFonts.jetBrainsMono(
      fontSize: 13.0,
      fontWeight: FontWeight.w800,
      color: PujaColors.festivalGold,
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
    final isDark = theme.brightness == Brightness.dark;
    final hasText = _controller.text.trim().isNotEmpty;
    final recentList = OmniSearchService.instance.recentSearches;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Clean, Seamless Minimalist Search Input Bar (No icons, pure typography)
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? (widget.isFloatingOnMap ? const Color(0xF212141A) : const Color(0xFF14161E))
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? (isDark ? Colors.white38 : Colors.black45)
                  : (isDark ? Colors.white12 : Colors.black12),
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isFloatingOnMap ? 0.25 : 0.06),
                blurRadius: widget.isFloatingOnMap ? 14 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: widget.autoFocus,
                  cursorColor: isDark ? Colors.white : Colors.black,
                  cursorWidth: 1.8,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: context.dynamicFont(13.2),
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: widget.hintText,
                    hintStyle: GoogleFonts.jetBrainsMono(
                      fontSize: context.dynamicFont(12.2),
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.w400,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _controller.clear();
                    _focusNode.unfocus();
                    setState(() {
                      _showDropdown = false;
                      _suggestions = [];
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    child: Text(
                      'clear',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: context.dynamicFont(11),
                        color: isDark ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 2. Seamless Suggestions & Examples Dropdown
        if (_showDropdown) ...[
          const SizedBox(height: 4),
          Container(
            constraints: BoxConstraints(
              maxHeight: math.min(290.0, MediaQuery.sizeOf(context).height * 0.42),
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? (widget.isFloatingOnMap ? const Color(0xF212141A) : const Color(0xFF14161E))
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white12 : Colors.black12,
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
                        'EXAMPLES',
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: context.dynamicFont(9.5),
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: isDark ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ),
                    ..._exampleQueries.map((example) {
                      return InkWell(
                        onTap: () => _selectQueryPrompt(example),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            example,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: context.dynamicFont(12.2),
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
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
                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'RECENT',
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: context.dynamicFont(9.5),
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.2,
                                color: isDark ? Colors.white38 : Colors.black38,
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
                                'clear',
                                style: GoogleFonts.jetBrainsMono(
                                  fontSize: context.dynamicFont(9.5),
                                  color: isDark ? Colors.white38 : Colors.black38,
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
                            child: Text(
                              recent,
                              style: GoogleFonts.jetBrainsMono(
                                fontSize: context.dynamicFont(11.8),
                                color: isDark ? Colors.white54 : Colors.black54,
                              ),
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
                        color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
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
                                        style: GoogleFonts.jetBrainsMono(
                                          fontSize: context.dynamicFont(10.5),
                                          color: isDark ? Colors.white38 : Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (distStr != null) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    distStr,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: context.dynamicFont(10.5),
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? Colors.white54 : Colors.black54,
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
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: context.dynamicFont(12),
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white70 : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Try searching for Sreebhumi, Kalighat, or Golbari',
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: context.dynamicFont(10.5),
                              color: isDark ? Colors.white38 : Colors.black38,
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
