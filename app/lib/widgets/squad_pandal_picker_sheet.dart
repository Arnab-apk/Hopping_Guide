import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/theme.dart';
import '../models/pandal.dart';
import '../models/squad_pandal_stop.dart';
import '../repositories/local_pandal_repository.dart';
import '../services/squad_service.dart';
import '../utils/constants.dart';
import '../widgets/vote_avatar_stack.dart';

/// Bottom sheet dialog allowing squad members to search, filter,
/// and choose pandals to add to their shared group itinerary.
class SquadPandalPickerSheet extends StatefulWidget {
  const SquadPandalPickerSheet({super.key, required this.squadService});

  final SquadService squadService;

  static Future<void> show(BuildContext context, SquadService squadService) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SquadPandalPickerSheet(squadService: squadService),
    );
  }

  @override
  State<SquadPandalPickerSheet> createState() => _SquadPandalPickerSheetState();
}

class _SquadPandalPickerSheetState extends State<SquadPandalPickerSheet> {
  final LocalAssetPandalRepository _repo = LocalAssetPandalRepository();
  final TextEditingController _searchController = TextEditingController();

  List<Pandal> _allPandals = [];
  bool _isLoading = true;
  String _searchQuery = '';
  KolkataZone? _selectedZone;

  @override
  void initState() {
    super.initState();
    _loadPandals();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPandals() async {
    try {
      final list = await _repo.loadAll();
      if (mounted) {
        setState(() {
          _allPandals = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  List<Pandal> get _filteredPandals {
    return _allPandals.where((pandal) {
      if (_selectedZone != null && pandal.zone != _selectedZone) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchesName = pandal.name.toLowerCase().contains(query);
        final matchesArea = (pandal.area ?? '').toLowerCase().contains(query);
        final matchesTheme = pandal.theme.toLowerCase().contains(query);
        if (!matchesName && !matchesArea && !matchesTheme) return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final chosenMap = {for (var p in widget.squadService.chosenPandals) p.id: p};
    final currentUserId = widget.squadService.members.where((m) => m.isUser).firstOrNull?.id ?? 'guest';
    SquadPandalStop.setCurrentUserId(currentUserId);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose Pandals Together',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Select pandals to add to your group hopping trail',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search pandals or areas...',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                filled: true,
                fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF4F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // Zone Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _buildZoneFilterChip('All Zones', null, isDark, theme),
                _buildZoneFilterChip('North', KolkataZone.northKolkata, isDark, theme),
                _buildZoneFilterChip('Central', KolkataZone.centralKolkata, isDark, theme),
                _buildZoneFilterChip('South', KolkataZone.southKolkata, isDark, theme),
                _buildZoneFilterChip('Salt Lake', KolkataZone.saltLake, isDark, theme),
                _buildZoneFilterChip('New Town', KolkataZone.newTown, isDark, theme),
              ],
            ),
          ),
          const Divider(height: 1),

          // Pandal List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredPandals.isEmpty
                    ? Center(
                        child: Text(
                          'No pandals match your search',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black45,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: _filteredPandals.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final pandal = _filteredPandals[index];
                          final chosenStop = chosenMap[pandal.id];
                          final isChosen = chosenStop != null;

                          return _buildPandalPickerItem(
                            pandal: pandal,
                            isChosen: isChosen,
                            chosenStop: chosenStop,
                            isDark: isDark,
                            theme: theme,
                          );
                        },
                      ),
          ),

          // Bottom Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Done (${widget.squadService.chosenPandals.length} in Trail)',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoneFilterChip(
    String label,
    KolkataZone? zone,
    bool isDark,
    ThemeData theme,
  ) {
    final isSelected = _selectedZone == zone;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedZone = zone),
        selectedColor: theme.colorScheme.primary.withValues(alpha: 0.18),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          color: isSelected
              ? theme.colorScheme.primary
              : (isDark ? Colors.white70 : Colors.black87),
        ),
      ),
    );
  }

  Widget _buildPandalPickerItem({
    required Pandal pandal,
    required bool isChosen,
    required SquadPandalStop? chosenStop,
    required bool isDark,
    required ThemeData theme,
  }) {
    final voterMembers = chosenStop?.getVoterMembers(widget.squadService.members) ?? [];
    final hasVoted = chosenStop?.currentUserVoted ?? false;
    final voteCount = chosenStop?.voteCount ?? 0;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF262626) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isChosen
              ? AppColors.semanticLive.withValues(alpha: 0.6)
              : (isDark ? Colors.white10 : Colors.black12),
          width: isChosen ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Pandal Thumbnail or Zone Icon
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 50,
              height: 50,
              child: pandal.imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: pandal.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.temple_hindu_rounded, size: 24),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.temple_hindu_rounded, size: 24),
                      ),
                    )
                  : Container(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.temple_hindu_rounded, size: 24),
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Pandal Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pandal.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        pandal.zone.shortLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    if (pandal.area != null && pandal.area!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          pandal.area!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                // Vote Status Row
                if (isChosen && voteCount > 0) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      VoteAvatarStack(
                        voters: voterMembers,
                        currentUserId: widget.squadService.members
                            .where((m) => m.isUser)
                            .firstOrNull
                            ?.id,
                        maxVisible: 3,
                        avatarSize: 18,
                      ),
                      if (voteCount > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.thumb_up_rounded,
                                size: 11,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '$voteCount',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Add / Remove / Vote action button
          if (isChosen)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Vote button
                IconButton(
                  icon: Icon(
                    hasVoted ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                    color: hasVoted ? theme.colorScheme.primary : (isDark ? Colors.white54 : Colors.black54),
                    size: 22,
                  ),
                  tooltip: hasVoted ? 'Remove your vote' : 'Vote for this pandal',
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    await widget.squadService.toggleVotePandal(chosenStop!.id);
                    setState(() {});
                  },
                ),
                // Remove button
                IconButton(
                  icon: const Icon(Icons.check_circle_rounded, color: AppColors.semanticLive, size: 26),
                  tooltip: 'In Group Plan (tap to remove)',
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await widget.squadService.removePandalFromSquad(pandal.id);
                    setState(() {});
                  },
                ),
              ],
            )
          else
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Add', style: TextStyle(fontSize: 12)),
              onPressed: () async {
                HapticFeedback.selectionClick();
                await widget.squadService.addPandalToSquad(pandal);
                setState(() {});
              },
            ),
        ],
      ),
    );
  }
}
