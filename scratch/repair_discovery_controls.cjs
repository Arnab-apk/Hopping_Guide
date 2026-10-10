const fs = require('fs');
const root = 'D:/projects/puja_proj/app/lib/';
const read = p => fs.readFileSync(root + p, 'utf8').replace(/\r\n/g, '\n');
const write = (p,s) => fs.writeFileSync(root + p, s);
let s = read('screens/pandal_list_screen.dart');
s = s.replace("import '../widgets/app_notice.dart';", "import '../widgets/app_notice.dart';\nimport '../widgets/app_filter_chip.dart';");
let begin = s.indexOf('          // 3. Category Filter Chips');
let end = s.indexOf('          // 4. Hopping Progress Bar', begin);
if (begin < 0 || end < 0) throw Error('Pandals filters not found');
s = s.slice(0, begin) + `          // Keep every filter visible; individual labels stay on one line.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(spacing: 8, runSpacing: 0, children: statusPills),
            ),
          ),

` + s.slice(end);
begin = s.indexOf('  Widget _buildTabPill(');
end = s.indexOf('  void _showRegionBottomSheet', begin);
if (begin < 0 || end < 0) throw Error('Pill builders not found');
s = s.slice(0, begin) + `  Widget _buildTabPill({
    required String label,
    IconData? icon,
    Widget? customIcon,
    required bool isSelected,
    required VoidCallback onTap,
  }) => AppFilterChip(
    label: label,
    selected: isSelected,
    avatar: customIcon ?? (icon == null ? null : Icon(icon, size: 18)),
    onSelected: (_) { HapticFeedback.selectionClick(); onTap(); },
  );

  Widget _buildRegionPill(BuildContext context, bool isDark) => AppFilterChip(
    label: _selectedZone?.shortLabel ?? 'Regions',
    selected: _selectedZone != null,
    avatar: const Icon(Icons.location_on_outlined, size: 18),
    onSelected: (_) => _showRegionBottomSheet(context, isDark),
  );

` + s.slice(end);
begin = s.indexOf('  void _showRegionBottomSheet');
s = s.slice(0, begin) + `  void _showRegionBottomSheet(BuildContext context, bool isDark) {
    final colors = Theme.of(context).colorScheme;
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: colors.surfaceContainerLow,
      builder: (ctx) => FractionallySizedBox(
        heightFactor: .8,
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 8, 12),
                child: Row(children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Choose a region', style: Theme.of(ctx).textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(_category == PlaceCategory.pandal ? 'Find pandals by neighbourhood' : 'Find food spots by neighbourhood',
                        style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                    ],
                  )),
                  IconButton(tooltip: 'Close regions', onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                ]),
              ),
              if (_selectedZone != null)
                Align(alignment: Alignment.centerRight, child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: TextButton(onPressed: () { setState(() => _selectedZone = null); Navigator.pop(ctx); }, child: const Text('Reset All')),
                )),
              const Divider(height: 1),
              Expanded(child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
                children: [
                  _regionOption(ctx, label: _category == PlaceCategory.pandal ? 'All Kolkata Pandals' : 'All Kolkata Food Spots', count: _allPlaces.length, zone: null),
                  for (final zone in KolkataZone.values)
                    _regionOption(ctx, label: zone.label, count: _allPlaces.where((p) => p.zone == zone).length, zone: zone),
                ],
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _regionOption(BuildContext ctx, {required String label, required int count, required KolkataZone? zone}) {
    final colors = Theme.of(ctx).colorScheme;
    final selected = _selectedZone == zone;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        selected: selected,
        selectedColor: colors.onPrimaryContainer,
        selectedTileColor: colors.primaryContainer,
        leading: Icon(zone == null ? Icons.public : Icons.location_on_outlined, color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant),
        title: Text(label),
        subtitle: Text('$count \${_category == PlaceCategory.pandal ? 'pandals' : 'food spots'}', style: TextStyle(color: selected ? colors.onPrimaryContainer : colors.onSurfaceVariant)),
        trailing: selected ? Icon(Icons.check_circle, color: colors.onPrimaryContainer) : null,
        onTap: () { setState(() => _selectedZone = zone); Navigator.pop(ctx); },
      ),
    );
  }
}
`;
write('screens/pandal_list_screen.dart', s);
s = read('screens/routes_screen.dart').replace("import '../widgets/app_page_intro.dart';", "import '../widgets/app_page_intro.dart';\nimport '../widgets/app_filter_chip.dart';");
begin = s.indexOf('          // 2. Horizontal Filter Chips Row');
end = s.indexOf('          const Divider(height: 1)', begin);
if (begin < 0 || end < 0) throw Error('Routes filter section not found');
s = s.slice(0, begin) + `          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Align(alignment: Alignment.centerLeft, child: Wrap(
              spacing: 8,
              runSpacing: 0,
              children: [for (final filter in RouteCategoryFilter.values)
                AppFilterChip(
                  label: filter == RouteCategoryFilter.all ? 'All (\${_curatedRoutes.length})' : filter.label,
                  selected: _selectedFilter == filter,
                  avatar: Icon(filter.icon, size: 18),
                  onSelected: (_) { HapticFeedback.selectionClick(); setState(() => _selectedFilter = filter); },
                ),
              ],
            )),
          ),

` + s.slice(end);
write('screens/routes_screen.dart', s);
