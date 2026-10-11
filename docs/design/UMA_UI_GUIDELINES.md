# Uma mobile UI guidelines

Applied with the installed `ui-ux-pro-max` skill from
https://github.com/nextlevelbuilder/ui-ux-pro-max-skill.

Uma is a Flutter festival discovery and navigation app, used while walking,
often outdoors or at night. Favor clear actions, readable content, and predictable
navigation. The existing Material 3 crimson-and-gold brand remains the visual
foundation.

## Verified guidance

- Flutter search: `responsive cards semantics reduced motion` returned relevant
  Semantics and LayoutBuilder recommendations.
- UX search: `badge chip label wraps` returned Compact Label Overflow guidance.
- Reviewed the native pre-delivery checklist and accessibility, touch, and
  performance rules in the skill's quick reference.
- The initial global design query returned Aurora UI and marketing storytelling.
  The narrower `mobile utility minimal` query returned Minimalism & Swiss Style
  and Plus Jakarta Sans. These suit the app's readable, compact mobile layouts.
  The existing crimson brand takes priority over the suggested generic palette.
- Flutter `theme responsive modal` guidance informs the shared theme and sheets.

## Implementation

- Bottom navigation retains the original festival icons at the user's request:
  Durga eyes, Durga face, multi-armed goddess, dhaki, and trishul with eyes.
  Destination labels provide their accessible names; selection uses theme colors.
- Neutral surfaces, crimson accents, consistent typography, left-aligned page
  titles, and shared page introductions apply throughout the main and secondary
  screens. Dialogs, profile, chat, group settings, and helplines use the same
  semantic color tokens and control sizing.
- Discovery cards share semantic theme colors across light/dark mode instead
  of assigning ad hoc status, transit, or food colors.
- Use 16 dp card padding, 8/12/16 dp gaps, and a 16 dp corner radius.
- Titles, food categories, nearby landmarks, and transit names can reflow.
  Essential values remain readable with enlarged system text.
- Bookmark and map controls have at least 48 dp touch areas. Bookmark states
  use outlined/filled forms of the same icon and expose toggled semantics.
- Decorative metadata icons are excluded from the accessibility tree. Ratings
  expose their five-point scale through a descriptive semantic label.
- Card entrance motion is disabled when the system requests reduced motion.
- Favorite and visited state subscriptions stay scoped to the individual card.
- Custom search fields disable the global filled input decoration inside their
  existing surface, preventing nested backgrounds and borders.
- Search suggestion lists limit their height with the visible keyboard taken
  into account, preserving access to suggestion rows on compact phones.
- Discovery filter groups wrap, keeping Regions and every route category visible.
  Single-line labels, matching selected foreground/background colors, tooltips,
  and padded touch targets are shared through `AppFilterChip`.
- Regions uses a bounded, scrollable sheet with theme surfaces, a close control,
  region counts, and an explicit reset action.
- Map information and feature availability share one app-bar entry.
- Compass and camera rotation update their local controls instead of rebuilding
  the map screen. Unchanged pandal marker widgets are reused, and map squad
  subscriptions select only data relevant to displayed companions and meetups.
- Cluster cache keys include actual pandals, priority IDs, and zoom bands so
  region changes and zoom thresholds cannot leave stale pins on screen.

## Validation scope

Focused widget checks cover 375 dp phones and landscape, both themes, 2x text,
long labels, independent card/map/bookmark actions, and reduced motion. Existing
regression tests cover the directory and other app features. Screenshots are
generated locally under `app/build/launch-audit/visuals` when the launch checks
run with `CAPTURE_LAUNCH_VISUALS=true`.
The capture mode loads the Material icon font and requests reduced motion for
deterministic still previews. Normal regression runs retain animation behavior.

Launch verification results are recorded in `docs/qa/TONIGHT_LAUNCH_CHECK.md`.

Automated checks do not establish real-device screen reader quality or outdoor
readability; those still need device evaluation.
