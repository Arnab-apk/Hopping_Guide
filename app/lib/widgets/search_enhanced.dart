/// Enhanced search widget with history, suggestions, voice search, and better UX.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../utils/animation_constants.dart';
const int _kMaxSearchHistory = 10;

/// Enhanced search bar with autocomplete, history, and voice input.
class EnhancedSearchBar extends StatefulWidget {
  const EnhancedSearchBar({
    super.key,
    this.controller,
    this.hintText = 'Search pandals, food, routes...',
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.suggestions,
    this.recentSearches,
    this.trendingSearches,
    this.showVoiceInput = true,
    this.showFilterChip = false,
    this.onFilterTap,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.backgroundColor,
    this.height = 52,
    this.borderRadius = 28,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final TextEditingController? controller;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final List<SearchSuggestion>? suggestions;
  final List<String>? recentSearches;
  final List<String>? trendingSearches;
  final bool showVoiceInput;
  final bool showFilterChip;
  final VoidCallback? onFilterTap;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final Color? backgroundColor;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  State<EnhancedSearchBar> createState() => _EnhancedSearchBarState();

  /// Shows the search overlay with suggestions and history.
  static void showOverlay({
    required BuildContext context,
    required TextEditingController controller,
    required List<SearchSuggestion> suggestions,
    List<String> recentSearches = const [],
    List<String> trendingSearches = const [],
    ValueChanged<String>? onSelected,
    VoidCallback? onClose,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SearchSuggestionsOverlay(
        controller: controller,
        focusNode: FocusNode(),
        suggestions: suggestions,
        recentSearches: recentSearches,
        trendingSearches: trendingSearches,
        onSelected: (suggestion) {
          onSelected?.call(suggestion.query);
          Navigator.of(context).pop();
        },
        onClose: () {
          onClose?.call();
          Navigator.of(context).pop();
        },
      ),
    );
  }
}

class _EnhancedSearchBarState extends State<EnhancedSearchBar>
    with SingleTickerProviderStateMixin {
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _borderColorAnimation;

  bool _isFocused = false;
  bool _hasText = false;
  OverlayEntry? _overlayEntry;
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? TextEditingController();
    _focusNode = FocusNode();
    _animationController = AnimationController(
      duration: AppDurations.quick,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _borderColorAnimation = ColorTween(
      begin: Theme.of(context).colorScheme.outlineVariant,
      end: Theme.of(context).colorScheme.primary,
    ).animate(_animationController);

    _controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  void _onTextChanged() {
    final hasText = _controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
    widget.onChanged?.call(_controller.text);
  }

  void _onFocusChanged() {
    final isFocused = _focusNode.hasFocus;
    if (isFocused != _isFocused) {
      setState(() => _isFocused = isFocused);
      if (isFocused) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _focusNode.removeListener(_onFocusChanged);
    if (widget.controller == null) _controller.dispose();
    _focusNode.dispose();
    _animationController.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Future<void> _startVoiceInput() async {
    if (_isListening) return;

    final available = await _speech.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _isListening = false);
        }
      },
    );

    if (!available) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech recognition not available')),
        );
      }
      return;
    }

    setState(() => _isListening = true);
    HapticFeedback.lightImpact();

    _speech.listen(
      onResult: (result) {
        if (mounted) {
          _controller.text = result.recognizedWords;
          _controller.selection = TextSelection.fromPosition(
            TextPosition(offset: _controller.text.length),
          );
        }
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
      ),
    );
  }

  void _stopVoiceInput() {
    if (!_isListening) return;
    _speech.stop();
    setState(() => _isListening = false);
  }

  void _clearText() {
    _controller.clear();
    widget.onChanged?.call('');
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            height: widget.height,
            decoration: BoxDecoration(
              color:
                  widget.backgroundColor ??
                  theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(widget.borderRadius),
              border: Border.all(
                color:
                    _borderColorAnimation.value ??
                    theme.colorScheme.outlineVariant,
                width: _isFocused ? 2 : 1.5,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.15,
                        ),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  if (!widget.readOnly && widget.enabled) {
                    _focusNode.requestFocus();
                    widget.onTap?.call();
                  }
                },
                borderRadius: BorderRadius.circular(widget.borderRadius),
                child: Padding(
                  padding: widget.padding,
                  child: Row(
                    children: [
                      // Search icon
                      Icon(
                        Icons.search_rounded,
                        size: 22,
                        color: _isFocused || _hasText
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 10),
                      // Text field
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          focusNode: _focusNode,
                          readOnly: widget.readOnly,
                          enabled: widget.enabled,
                          autofocus: widget.autofocus,
                          decoration: InputDecoration(
                            hintText: widget.hintText,
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: theme.colorScheme.onSurface,
                          ),
                          textInputAction: TextInputAction.search,
                          onSubmitted: (value) {
                            _removeOverlay();
                            widget.onSubmitted?.call(value);
                          },
                          onTapOutside: (_) => _focusNode.unfocus(),
                        ),
                      ),
                      // Clear button
                      if (_hasText && !widget.readOnly)
                        IconButton(
                          icon: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: _clearText,
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      // Voice input
                      if (widget.showVoiceInput &&
                          !widget.readOnly &&
                          widget.enabled)
                        IconButton(
                          icon: AnimatedSwitcher(
                            duration: AppDurations.quick,
                            child: Icon(
                              _isListening
                                  ? Icons.mic_rounded
                                  : Icons.mic_none_rounded,
                              key: ValueKey(_isListening),
                              size: 22,
                              color: _isListening
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          onPressed: _isListening
                              ? _stopVoiceInput
                              : _startVoiceInput,
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      // Filter chip
                      if (widget.showFilterChip && widget.onFilterTap != null)
                        IconButton(
                          icon: Icon(
                            Icons.tune_rounded,
                            size: 22,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          onPressed: widget.onFilterTap,
                          splashRadius: 20,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Search suggestion model.
class SearchSuggestion {
  const SearchSuggestion({
    required this.query,
    this.category,
    this.icon,
    this.subtitle,
    this.isTrending = false,
    this.resultCount,
  });

  final String query;
  final String? category;
  final IconData? icon;
  final String? subtitle;
  final bool isTrending;
  final int? resultCount;
}

/// Search suggestions overlay.
class _SearchSuggestionsOverlay extends StatelessWidget {
  const _SearchSuggestionsOverlay({
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.recentSearches,
    required this.trendingSearches,
    required this.onSelected,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<SearchSuggestion> suggestions;
  final List<String> recentSearches;
  final List<String> trendingSearches;
  final ValueChanged<SearchSuggestion> onSelected;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Backdrop tap to close
          Positioned.fill(
            child: GestureDetector(
              onTap: onClose,
              behavior: HitTestBehavior.translucent,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Suggestions sheet
          Align(
            alignment: Alignment.topCenter,
            child: _SuggestionsSheet(
              controller: controller,
              focusNode: focusNode,
              suggestions: suggestions,
              recentSearches: recentSearches,
              trendingSearches: trendingSearches,
              onSelected: onSelected,
              onClose: onClose,
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionsSheet extends StatefulWidget {
  const _SuggestionsSheet({
    required this.controller,
    required this.focusNode,
    required this.suggestions,
    required this.recentSearches,
    required this.trendingSearches,
    required this.onSelected,
    required this.onClose,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<SearchSuggestion> suggestions;
  final List<String> recentSearches;
  final List<String> trendingSearches;
  final ValueChanged<SearchSuggestion> onSelected;
  final VoidCallback onClose;

  @override
  State<_SuggestionsSheet> createState() => _SuggestionsSheetState();
}

class _SuggestionsSheetState extends State<_SuggestionsSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppDurations.standard,
      vsync: this,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
          CurvedAnimation(parent: _controller, curve: AppCurves.brandEaseOut),
        );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final query = widget.controller.text.toLowerCase();

    // Filter suggestions based on query
    final filteredSuggestions = widget.suggestions.where((s) {
      return s.query.toLowerCase().contains(query) ||
          (s.category?.toLowerCase().contains(query) ?? false);
    }).toList();

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.only(
            top: kToolbarHeight + 8,
            left: 16,
            right: 16,
          ),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    // Trending searches
                    if (widget.trendingSearches.isNotEmpty && query.isEmpty)
                      _buildSection(
                        context,
                        title: 'Trending',
                        icon: Icons.trending_up_rounded,
                        children: widget.trendingSearches
                            .map(
                              (s) => _buildSuggestionTile(
                                context,
                                SearchSuggestion(
                                  query: s,
                                  isTrending: true,
                                  icon: Icons.trending_up_rounded,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    // Recent searches
                    if (widget.recentSearches.isNotEmpty && query.isEmpty)
                      _buildSection(
                        context,
                        title: 'Recent',
                        icon: Icons.history_rounded,
                        trailing: TextButton(
                          onPressed: () {
                            // Clear history
                            HapticFeedback.selectionClick();
                          },
                          child: Text('Clear', style: TextStyle(fontSize: 13)),
                        ),
                        children: widget.recentSearches
                            .map(
                              (s) => _buildSuggestionTile(
                                context,
                                SearchSuggestion(
                                  query: s,
                                  icon: Icons.history_rounded,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    // Suggestions
                    if (filteredSuggestions.isNotEmpty)
                      _buildSection(
                        context,
                        title: 'Suggestions',
                        icon: Icons.search_rounded,
                        children: filteredSuggestions
                            .map((s) => _buildSuggestionTile(context, s))
                            .toList(),
                      ),
                    // No results
                    if (query.isNotEmpty && filteredSuggestions.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No suggestions',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Try a different search term',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: theme.colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
    Widget? trailing,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(
                title.toUpperCase(),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              ?trailing,
            ],
          ),
        ),
        ...children,
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildSuggestionTile(
    BuildContext context,
    SearchSuggestion suggestion,
  ) {
    final theme = Theme.of(context);

    return ListTile(
      dense: true,
      leading: Icon(
        suggestion.icon ?? Icons.search_rounded,
        size: 20,
        color: suggestion.isTrending
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        suggestion.query,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: theme.colorScheme.onSurface,
        ),
      ),
      subtitle: suggestion.subtitle != null
          ? Text(
              suggestion.subtitle!,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      trailing: suggestion.resultCount != null
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${suggestion.resultCount}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            )
          : suggestion.isTrending
          ? Icon(
              Icons.trending_up_rounded,
              size: 16,
              color: theme.colorScheme.primary,
            )
          : null,
      onTap: () {
        HapticFeedback.selectionClick();
        widget.onSelected(suggestion);
        widget.onClose();
      },
    );
  }
}

/// Search history manager.
class SearchHistory {
  SearchHistory._();

  static final List<String> _memoryCache = [];

  /// Get search history from memory cache.
  static List<String> get history => List.unmodifiable(_memoryCache);

  /// Add a search query to history.
  static void add(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    _memoryCache.remove(trimmed);
    _memoryCache.insert(0, trimmed);
    if (_memoryCache.length > _kMaxSearchHistory) {
      _memoryCache.removeLast();
    }
  }

  /// Remove a specific query from history.
  static void remove(String query) {
    _memoryCache.remove(query);
  }

  /// Clear all history.
  static void clear() {
    _memoryCache.clear();
  }
}

/// Search filter chip row.
class SearchFilterChips extends StatelessWidget {
  const SearchFilterChips({
    super.key,
    required this.filters,
    required this.selectedFilter,
    this.onFilterChanged,
    this.scrollable = true,
  });

  final List<SearchFilter> filters;
  final String selectedFilter;
  final ValueChanged<String>? onFilterChanged;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: scrollable
          ? ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (_, index) {
                final filter = filters[index];
                final isSelected = filter.id == selectedFilter;
                return FilterChip(
                  label: Text(
                    filter.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  avatar: filter.icon != null
                      ? Icon(
                          filter.icon!,
                          size: 16,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                  selected: isSelected,
                  onSelected: (_) => onFilterChanged?.call(filter.id),
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  checkmarkColor: theme.colorScheme.onPrimary,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              },
            )
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: filters.map((filter) {
                final isSelected = filter.id == selectedFilter;
                return FilterChip(
                  label: Text(
                    filter.label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                  avatar: filter.icon != null
                      ? Icon(
                          filter.icon!,
                          size: 16,
                          color: isSelected
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurfaceVariant,
                        )
                      : null,
                  selected: isSelected,
                  onSelected: (_) => onFilterChanged?.call(filter.id),
                  selectedColor: theme.colorScheme.primary,
                  backgroundColor: theme.colorScheme.surfaceContainerHigh,
                  checkmarkColor: theme.colorScheme.onPrimary,
                  labelStyle: GoogleFonts.plusJakartaSans(
                    color: isSelected
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurface,
                  ),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant,
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                );
              }).toList(),
            ),
    );
  }
}

/// Search filter model.
class SearchFilter {
  const SearchFilter({
    required this.id,
    required this.label,
    this.icon,
    this.count,
  });

  final String id;
  final String label;
  final IconData? icon;
  final int? count;
}

/// Voice search button widget.
class VoiceSearchButton extends StatefulWidget {
  const VoiceSearchButton({
    super.key,
    required this.onResult,
    this.label = 'Voice Search',
    this.icon = Icons.mic_rounded,
    this.activeColor,
    this.inactiveColor,
  });

  final ValueChanged<String> onResult;
  final String label;
  final IconData icon;
  final Color? activeColor;
  final Color? inactiveColor;

  @override
  State<VoiceSearchButton> createState() => _VoiceSearchButtonState();
}

class _VoiceSearchButtonState extends State<VoiceSearchButton>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _speech.stop();
      _pulseController.stop();
      setState(() => _isListening = false);
      return;
    }

    final available = await _speech.initialize();
    if (!available) return;

    _pulseController.repeat(reverse: true);
    setState(() => _isListening = true);
    HapticFeedback.lightImpact();

    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          widget.onResult(result.recognizedWords);
          _speech.stop();
          _pulseController.stop();
          if (mounted) setState(() => _isListening = false);
        }
      },
      listenOptions: SpeechListenOptions(
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isListening ? _pulseAnimation.value : 1.0,
          child: FilledButton.tonalIcon(
            onPressed: _toggleListening,
            icon: Icon(
              _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
              color: _isListening
                  ? (widget.activeColor ?? theme.colorScheme.primary)
                  : (widget.inactiveColor ??
                        theme.colorScheme.onSurfaceVariant),
            ),
            label: Text(
              _isListening ? 'Listening...' : widget.label,
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: _isListening
                  ? (widget.activeColor ?? theme.colorScheme.primary)
                        .withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerHigh,
              foregroundColor: _isListening
                  ? (widget.activeColor ?? theme.colorScheme.primary)
                  : theme.colorScheme.onSurface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
        );
      },
    );
  }
}
