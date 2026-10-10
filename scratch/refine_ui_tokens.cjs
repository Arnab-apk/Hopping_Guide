// Consolidate existing adaptive foregrounds without touching semantic status colors.
const fs = require('fs');
const path = require('path');
const substitutions = [
  [/isDark\s*\? Colors\.white(?:54|60|70)\s*: Colors\.black54/g, 'Theme.of(context).colorScheme.onSurfaceVariant'],
  [/isDark\s*\? Colors\.white\s*: Colors\.black87/g, 'Theme.of(context).colorScheme.onSurface'],
  [/isDark\s*\? Colors\.white38\s*: Colors\.black38/g, 'Theme.of(context).colorScheme.onSurfaceVariant'],
];
for (const dir of ['app/lib/screens', 'app/lib/widgets']) {
  for (const name of fs.readdirSync(dir)) {
    if (!name.endsWith('.dart')) continue;
    const file = path.join(dir, name);
    const before = fs.readFileSync(file, 'utf8');
    let after = before;
    for (const [pattern, replacement] of substitutions) after = after.replace(pattern, replacement);
    if (before !== after) {
      fs.writeFileSync(file, after);
      process.stdout.write(file + '\n');
    }
  }
}
const popupFile = 'app/lib/widgets/leaflet_map_components.dart';
let popup = fs.readFileSync(popupFile, 'utf8');
for (const name of ['ToiletContent', 'PandalContent', 'FoodSpotContent', 'MetroContent', 'ActionButtons']) {
  popup = popup.replaceAll(`_build${name}(bool isDark)`, `_build${name}(BuildContext context, bool isDark)`);
  popup = popup.replaceAll(`_build${name}(effectiveDark)`, `_build${name}(context, effectiveDark)`);
}
fs.writeFileSync(popupFile, popup);
const profileFile = 'app/lib/widgets/user_profile_sheet.dart';
let profile = fs.readFileSync(profileFile, 'utf8');
profile = profile.replaceAll('child: _buildStatItem(\n', 'child: _buildStatItem(\n                            context: context,\n');
profile = profile.replaceAll('child: _buildStatItem(\r\n', 'child: _buildStatItem(\r\n                            context: context,\r\n');
fs.writeFileSync(profileFile, profile);
