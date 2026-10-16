from pathlib import Path
import subprocess

root = Path(__file__).resolve().parents[1]
restore = [
    'app/lib/config/theme.dart',
    'app/lib/screens/group_screen.dart',
    'app/lib/screens/group_video_call_screen.dart',
    'app/lib/screens/helplines_screen.dart',
    'app/lib/screens/main_navigation_screen.dart',
    'app/lib/screens/route_chat_screen.dart',
    'app/lib/widgets/app_filter_chip.dart',
    'app/lib/widgets/app_notice.dart',
    'app/lib/widgets/app_page_intro.dart',
    'app/lib/widgets/pandal_search_autocomplete.dart',
    'app/lib/widgets/user_profile_sheet.dart',
    'app/test/launch_layout_test.dart',
    'app/test/ui_deep_audit_test.dart',
]
mixed = {
    'app/lib/screens/routes_screen.dart': (
        '''        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isExpanded ? colorScheme.primary : colorScheme.outline,
          width: 2,
        ),''',
        '''        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isExpanded
              ? colorScheme.primary.withValues(alpha: 0.65)
              : colorScheme.outlineVariant.withValues(
                  alpha: isDark ? 0.45 : 0.65,
                ),
          width: isExpanded ? 1.4 : 1.0,
        ),'''),
    'app/lib/widgets/pandal_card.dart': (
        '''          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isVis ? colors.primary : colors.outline,
            width: 2,
          ),''',
        '''          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isVis ? colors.primary : colors.outlineVariant,
          ),'''),
    'app/lib/widgets/pandal_detail_sheet.dart': (
        '''        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline,
            width: 2,
          ),''',
        '''        color: isDark ? const Color(0xFF141415) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.0,
          ),'''),
}
created = ['app/lib/config/neo_theme.dart', 'app/test/neo_notice_test.dart', 'docs/design/UMA_UI.md']
backup = root / 'scratch/ui-refresh-rollback-backup'
# Check every mixed-file replacement before writing anything.
for name, (current, previous) in mixed.items():
    assert (root / name).read_text(encoding='utf-8').count(current) == 1, name
for name in restore + list(mixed) + created:
    path = root / name
    if path.exists():
        dest = backup / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_bytes(path.read_bytes())
for name in restore:
    data = subprocess.check_output(['git', 'show', 'HEAD:' + name], cwd=root)
    (root / name).write_bytes(data)
for name, (current, previous) in mixed.items():
    path = root / name
    path.write_text(path.read_text(encoding='utf-8').replace(current, previous, 1), encoding='utf-8')
for name in created:
    (root / name).unlink(missing_ok=True)
print('Reverted UI changes in 16 files and removed 3 UI-only additions. Other feature changes preserved.')
