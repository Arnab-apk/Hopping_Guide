const fs=require('fs');
function edit(p,fn){fs.writeFileSync(p,fn(fs.readFileSync(p,'utf8').replace(/\r\n/g,'\n')));}
edit('app/lib/config/theme.dart',s=>s.replaceAll('return ThemeData(', 'return _polishTheme(ThemeData(').replaceAll('\n  );\n}', '\n  ));\n}')+`
ThemeData _polishTheme(ThemeData theme) {
  final colors = theme.colorScheme;
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(16));
  const target = Size(48, 48);
  final buttons = ButtonStyle(minimumSize: const WidgetStatePropertyAll(target),
    tapTargetSize: MaterialTapTargetSize.padded, shape: WidgetStatePropertyAll(shape));
  return theme.copyWith(
    materialTapTargetSize: MaterialTapTargetSize.padded,
    filledButtonTheme: FilledButtonThemeData(style: theme.filledButtonTheme.style?.merge(buttons)),
    outlinedButtonTheme: OutlinedButtonThemeData(style: theme.outlinedButtonTheme.style?.merge(buttons)),
    elevatedButtonTheme: ElevatedButtonThemeData(style: theme.elevatedButtonTheme.style?.merge(buttons)),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(
      minimumSize: target, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      shape: shape, foregroundColor: colors.primary)),
    iconButtonTheme: IconButtonThemeData(style: IconButton.styleFrom(minimumSize: target,
      tapTargetSize: MaterialTapTargetSize.padded)),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true, fillColor: colors.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(color: colors.onSurfaceVariant),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.outlineVariant)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: colors.primary, width: 2)),
      errorMaxLines: 3,
    ),
    dialogTheme: DialogThemeData(backgroundColor: colors.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      constraints: const BoxConstraints(maxWidth: 560),
      titleTextStyle: theme.textTheme.titleLarge?.copyWith(color: colors.onSurface, fontWeight: FontWeight.w700),
      contentTextStyle: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant, height: 1.5)),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: colors.surfaceContainerLow,
      modalBackgroundColor: colors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      constraints: const BoxConstraints(maxWidth: 640), clipBehavior: Clip.antiAlias),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating,
      backgroundColor: colors.inverseSurface, contentTextStyle: TextStyle(color: colors.onInverseSurface, fontSize: 14, height: 1.4),
      actionTextColor: colors.inversePrimary, showCloseIcon: true, closeIconColor: colors.onInverseSurface,
      shape: shape, elevation: 4, insetPadding: const EdgeInsets.all(12)),
    tooltipTheme: TooltipThemeData(waitDuration: const Duration(milliseconds: 500),
      showDuration: const Duration(seconds: 5), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      constraints: const BoxConstraints(maxWidth: 280),
      textStyle: TextStyle(color: colors.onInverseSurface, fontSize: 13),
      decoration: BoxDecoration(color: colors.inverseSurface, borderRadius: BorderRadius.circular(10))),
    dividerTheme: DividerThemeData(color: colors.outlineVariant, thickness: .7),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: colors.primary, linearMinHeight: 3),
  );
}
`);
// Keep existing content and actions; standardize delivery across all screens.
for(const dir of ['app/lib/screens','app/lib/widgets'])for(const name of fs.readdirSync(dir)){
if(!name.endsWith('.dart')||name==='app_notice.dart')continue;
const p=dir+'/'+name;let s=fs.readFileSync(p,'utf8');
const next=s.replace(/ScaffoldMessenger\.of\((\w+)\)\s*\.showSnackBar\(/g,'showAppSnackBar($1, ');
if(next!==s){s="import '../widgets/app_notice.dart';\n"+next;fs.writeFileSync(p,s);}
}
edit('app/lib/screens/group_video_call_screen.dart',s=>s.replace('child: Padding(\n                  padding: const EdgeInsets.all(24),', 'child: SingleChildScrollView(\n                padding: const EdgeInsets.all(24),').replace('child: Column(\n                    mainAxisSize:', 'child: ConstrainedBox(\n                  constraints: const BoxConstraints(maxWidth: 480),\n                  child: Column(\n                    mainAxisSize:').replace('                  ),\n                ),\n              ),\n      ),', '                  ),\n                  ),\n                ),\n              ),\n      ),').replace('AppBar(title: Text(widget.squadName))', 'AppBar(title: Text(widget.squadName, maxLines: 1, overflow: TextOverflow.ellipsis))'));
edit('app/lib/screens/pandal_detail_screen.dart',s=>s.replaceAll('backgroundColor: Colors.black,', 'backgroundColor: Theme.of(context).colorScheme.surface,'));
// Decorative artwork should not compete with real tab labels in TalkBack.
edit('app/lib/screens/main_navigation_screen.dart',s=>{
  s=s.replace(/(icon: |selectedIcon: )(PujaIcon\.\w+\([\s\S]*?\n\s*\)),/g,'$1ExcludeSemantics(child: $2),');
  return s;
});
// Correct subdued copy contrast in both palettes.
for(const p of ['app/lib/screens/group_screen.dart','app/lib/widgets/pandal_detail_sheet.dart'])edit(p,s=>s.replaceAll('Colors.grey.shade600', 'Theme.of(context).colorScheme.onSurfaceVariant'));
