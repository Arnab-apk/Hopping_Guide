# Uma: festival print meets mobile utility

The visual direction is restrained neo-brutalism: cream paper, burgundy actions,
gold selection markers, dark ink borders and hard offset shadows. Cultural artwork
remains in onboarding; navigation uses familiar Material icons with visible labels.

`app/lib/config/neo_theme.dart` applies the shared finish to both app themes.
Use semantic ColorScheme roles; keep body text readable instead of using heavy
display typography everywhere. Dark mode adapts the style with warm dark surfaces
and light outlines. Do not invert maps, photos or video content.

- Major borders: 2 px; secondary controls: 1.5 px; corners: 8 px.
- Primary controls: at least 48 dp; pressed shadows disappear without moving content.
- Headers may use gold blocks and 4 px hard shadows. Avoid rotated text and cards.
- Keep one primary action per section; outlined and text actions are secondary.
- Notifications use readable surface colors, status icons, dismiss and recovery actions.
- Keep text scaling, keyboard focus, reduced motion and safe areas working.
- Photos, map navigation and emergency information take priority over decoration.

Verification: Flutter analysis, existing launch/deep layout audit suites in both
themes, and notification contrast/action tests. Rendered audit previews are written
to `app/build/launch-audit/visuals` when CAPTURE_LAUNCH_VISUALS is enabled.
