import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../services/pandal_search_service.dart';
import '../utils/constants.dart';
import '../utils/haversine.dart';
import '../utils/responsive.dart';
import 'durga_face_icon.dart';

/// Interactive search bar with instant keyword matching, substring highlight,
/// and auto-complete suggestions overlay for Durga Puja pandals.
class PandalSearchAutocomplete extends StatefulWidget {
  const PandalSearchAutocomplete({
    super.key,
    required this.pandals,
    required this.onPandalSelected,
    this.onQueryChanged,
    this.onSubmitted,
    this.controller,
    this.focusNode,
    this.userLat,
    this.userLng,
    this.hintText = 'Search pandals by name, metro, theme...',
    this.autoFocus = false,
    this.isFloatingOnMap = false,
  });

  final List<Pandal> pandals;
  final void Function(Pandal pandal) onPandalSelected;
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

  List<PandalSearchResult> _suggestions = [];
  bool _showDropdown = false;

  static const List<String> _popularPandals = [
    'Sreebhumi',
    'Ekdalia Evergreen',
    'Bagbazar',
    'College Square',
    'Suruchi Sangha',
    'Maddox Square',
    'Chetla Agrani',
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
      fontSize: 14.5,
      fontWeight: FontWeight.w600,
      color: isDark ? Colors.white : Colors.black87,
    );
    final highlightStyle = const TextStyle(
      fontSize: 14.5,
      fontWeight: FontWeight.w900,
      color: PujaColors.festivalGold,
      decoration: TextDecoration.underline,
      decorationColor: PujaColors.festivalGold,
      decorationThickness: 1.5,
    );

    final results = PandalSearchService.instance.getAutoCompleteSuggestions(
      query,
      widget.pandals,
      limit: 6,
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

  void _selectPandal(Pandal pandal) {
    HapticFeedback.selectionClick();
    PandalSearchService.instance.addRecentSearch(pandal.name);
    _controller.text = pandal.name;
    _focusNode.unfocus();
    setState(() => _showDropdown = false);
    widget.onPandalSelected(pandal);
  }

  void _selectQueryChip(String query) {
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
    final recentList = PandalSearchService.instance.recentSearches;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Sleek Search Input Bar
        Container(
          decoration: BoxDecoration(
            color: isDark
                ? (widget.isFloatingOnMap ? PujaColors.nightCard.withValues(alpha: 0.95) : PujaColors.nightCard)
                : (widget.isFloatingOnMap ? Colors.white.withValues(alpha: 0.96) : Colors.white),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _focusNode.hasFocus
                  ? PujaColors.festivalGold
                  : PujaColors.festivalGold.withValues(alpha: 0.28),
              width: _focusNode.hasFocus ? 1.6 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: widget.isFloatingOnMap ? 0.22 : 0.08),
                blurRadius: widget.isFloatingOnMap ? 14 : 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 8.0),
                child: DurgaFaceIcon(
                  size: context.dynamicIcon(20),
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
                    fontSize: context.dynamicFont(13.5),
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onSubmitted: (val) {
                    _focusNode.unfocus();
                    setState(() => _showDropdown = false);
                    widget.onSubmitted?.call(val);
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
                    _updateSuggestions('');
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Icon(
                    Icons.search_rounded,
                    size: context.dynamicIcon(20),
                    color: PujaColors.festivalGold.withValues(alpha: 0.6),
                  ),
                ),
            ],
          ),
        ),

        // 2. Auto-Complete Suggestions Dropdown Overlay
        if (_showDropdown) ...[
          const SizedBox(height: 6),
          Container(
            constraints: BoxConstraints(
              maxHeight: math.min(260.0, MediaQuery.sizeOf(context).height * 0.35),
            ),
            decoration: BoxDecoration(
              color: isDark ? PujaColors.nightCard : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: PujaColors.festivalGold.withValues(alpha: 0.35),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // A. When Query is Empty -> Show Popular & Recent Searches
                    if (!hasText) ...[
                      // Popular Pandals Section
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                        child: Row(
                          children: [
                            const Text('🔥 ', style: TextStyle(fontSize: 13)),
                            Text(
                              'Popular Pandals',
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
                          children: _popularPandals.map((name) {
                            return ActionChip(
                              visualDensity: VisualDensity.compact,
                              backgroundColor: isDark ? PujaColors.nightSurface : const Color(0xFFFFF8E1),
                              side: BorderSide(
                                color: PujaColors.festivalGold.withValues(alpha: 0.3),
                              ),
                              avatar: const Icon(
                                Icons.trending_up_rounded,
                                size: 13,
                                color: PujaColors.festivalGold,
                              ),
                              label: Text(
                                name,
                                style: TextStyle(
                                  fontSize: context.dynamicFont(11),
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87,
                                ),
                              ),
                              onPressed: () => _selectQueryChip(name),
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
                                    PandalSearchService.instance.clearRecentSearches();
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
                          return ListTile(
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
                            onTap: () => _selectQueryChip(recent),
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
                              'Suggestions (${_suggestions.length} matches)',
                              style: TextStyle(
                                fontSize: context.dynamicFont(11),
                                fontWeight: FontWeight.bold,
                                color: PujaColors.festivalGold,
                              ),
                            ),
                            Text(
                              'Tap to jump',
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
                        separatorBuilder: (context, index) => const Divider(height: 1, indent: 14, endIndent: 14),
                        itemBuilder: (context, index) {
                          final res = _suggestions[index];
                          final p = res.pandal;
                          final distStr = res.distanceMeters != null
                              ? formatDistance(res.distanceMeters!)
                              : null;

                          return InkWell(
                            onTap: () => _selectPandal(p),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  // Durga icon avatar
                                  Container(
                                    padding: const EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      color: PujaColors.durgaRed.withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: DurgaFaceIcon(
                                      size: context.dynamicIcon(15),
                                      color: PujaColors.durgaRed,
                                      bindiColor: const Color(0xFFFF1744),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Main info with highlight spans
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        RichText(
                                          text: TextSpan(children: res.nameHighlightSpans),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 2,
                                          crossAxisAlignment: WrapCrossAlignment.center,
                                          children: [
                                            Text(
                                              p.zone.label,
                                              style: TextStyle(
                                                fontSize: context.dynamicFont(10.5),
                                                fontWeight: FontWeight.w700,
                                                color: isDark ? Colors.white60 : Colors.black54,
                                              ),
                                            ),
                                            if (p.nearestMetro != null && p.nearestMetro!.isNotEmpty) ...[
                                              Text('•', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                                              Text(
                                                '🚇 ${p.nearestMetro}',
                                                style: TextStyle(
                                                  fontSize: context.dynamicFont(10.5),
                                                  fontWeight: FontWeight.w600,
                                                  color: const Color(0xFF00E676),
                                                ),
                                              ),
                                            ],
                                            if (res.matchedField != 'Name' && res.matchedField.isNotEmpty) ...[
                                              Text('•', style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                                              Text(
                                                'Matched ${res.matchedField}',
                                                style: TextStyle(
                                                  fontSize: context.dynamicFont(10),
                                                  fontStyle: FontStyle.italic,
                                                  color: PujaColors.festivalGold,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Trailing info: Distance & Rating
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (distStr != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: PujaColors.crimsonVelvet.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(
                                              color: PujaColors.durgaRed.withValues(alpha: 0.3),
                                              width: 0.8,
                                            ),
                                          ),
                                          child: Text(
                                            distStr,
                                            style: TextStyle(
                                              fontSize: context.dynamicFont(10.5),
                                              fontWeight: FontWeight.w800,
                                              color: PujaColors.durgaRed,
                                            ),
                                          ),
                                        ),
                                      if (p.rating != null) ...[
                                        const SizedBox(height: 2),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star_rounded, size: 12, color: PujaColors.goldBright),
                                            const SizedBox(width: 2),
                                            Text(
                                              p.rating!.toStringAsFixed(1),
                                              style: TextStyle(
                                                fontSize: context.dynamicFont(10.5),
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
                        padding: const EdgeInsets.all(18.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 36,
                              color: isDark ? Colors.white38 : Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'No pandals match "${_controller.text}"',
                              style: TextStyle(
                                fontSize: context.dynamicFont(13),
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white70 : Colors.black87,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try searching by landmark, metro line, theme, or general area.',
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
        ],
      ],
    );
  }
}
