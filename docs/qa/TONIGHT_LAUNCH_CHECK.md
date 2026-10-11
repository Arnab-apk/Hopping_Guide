# Uma launch verification — 10 October 2026

## Latest UI follow-up — 11 October 2026

- Group calls have a red, labelled End call button fixed below the media
  controls, clear of the system gesture area. The duplicate SDK call header
  is hidden, and the bottom end-call action remains available during reconnects.
- Direction and trail maps show only stations on their selected transit legs,
  including boarding, intermediate and exit stations. Unrelated nearby stations
  are no longer added; walking and driving routes have no incidental station
  pins. The browse map's full station layer is suppressed while viewing a route.
- Six call-lobby layout checks and 12 journey/planner checks passed. Full Dart
  static analysis found no issues. Signed release build **1.0.0 (2016)** includes
  both changes.

## Changes

- Refined shared light/dark themes, typography, page headers, cards, dialogs,
  chat composers, profile, group screens, helplines, and empty states.
- Restored the original five festival navigation icons at the user's request.
  Tab labels, selection feedback, and preserved screen state remain intact.
- Curated and custom trail maps now show nearby metro and railway stations
  independently of selected travel mode. Train legs include intermediate stops;
  station markers are deduplicated and pandal markers remain above them.
- Foreground trail arrival uses the current target's 80 m proximity radius.
  GPS must be at most 10 seconds old with reported accuracy no worse than 30 m.
  Repeat notifications for the same fix cannot visit another stop.
- Automatic visits preserve previously recorded visits and advance the squad's
  shared plan. Individual navigation arrivals also persist pandal visit state.
- Navigation rejects stale/invalid GPS fixes. Trail GPS subscriptions are owned
  once and released when the trail ends.
- Navigation's live indicator uses the same 10-second freshness window as
  guidance. GPS timestamps up to 2 seconds ahead of the device clock are
  tolerated for normal provider clock jitter; larger future timestamps fail
  the freshness check. Arrival still requires the current target and accuracy.
- GPS profile changes wait for native stream cancellation before attaching the
  replacement stream. A delayed-cancellation regression checks ordering and
  confirms that navigation receives fixes at its requested 1-second interval.
- Squad location publication failures now reach the service and screen instead
  of being silently logged. The UI shows a confirmed publication status or a
  retry/permission message; sharing off invalidates pending acknowledgements.

## Automated verification

- `flutter analyze`: no issues.
- Full suite with configured Mapbox credentials and `VERIFY_MAPBOX_LIVE=true`:
  **430 passed**, no skipped checks (`app/build/tonight_launch_regression.log`).
- All-page capture and layout suite: **96 passed**, light/dark, compact phone,
  enlarged text, and landscape (`app/build/all_pages_visual_final.log`).
- Live routing checks include pedestrian maneuvers and connected walking,
  metro, and train itineraries, including Behala and Chuchura connections.
- GPS simulations verify stale/inaccurate fix rejection, arrival persistence,
  duplicate protection, rerouting, navigation cleanup, and shared squad stop
  progression across two service sessions with an in-memory repository.
- Assistant integration checks use mocked responses and failure handling;
  they do not establish that the live Gemini service is available.

## Device verification scope

The connected Motorola Edge50 is the only available phone. Release 2010 was
installed with app data preserved; the original five navigation icons were
visually confirmed on the phone. The squad showed a server-confirmed `Live`
subscription and `Location shared with group`, confirming publication from this
phone. A real stop route preview loaded station pins and road directions.
Navigation subsequently exposed the GPS restart issue addressed above.
Final release **1.0.0 (2012)** was installed with `adb install -r`, preserving
app data, and its APK signature verified. Final static analysis is clean and
all 430 tests pass. The final continuous GPS device retest was inconclusive:
the phone switched out of Uma during the check, and earlier navigation showed
`Searching`. Continuous foreground GPS and outdoor arrival therefore remain
open launch checks; the automated fixes are not a substitute for those checks.

Physical arrival at a pandal and another member receiving updates on a second
phone have not been verified. Tracking is foreground-only: keep Uma open for
live navigation and location sharing. This audit does not establish 60 FPS,
80% widget coverage, store approval, or exhaustive production reliability.

## Discovery and map follow-up — 11 October 2026

- Removed doubled input backgrounds from discovery search bars. Search surfaces
  can grow with enlarged text, and clear actions expose labels.
- Search suggestions account for keyboard height, preventing dropdown rows
  from extending behind it. A compact-phone interaction check verifies the
  dropdown's screen bounds while focusing, typing, and clearing a query.
- Pandal and route filters share accessible themed chips; groups wrap so Regions
  and route categories remain visible. Original bottom navigation icons remain.
- Regions now uses a bounded scrollable sheet, consistent selection colors,
  region counts, and visible close/reset controls.
- The map has one information button. Feature availability remains accessible
  inside its information sheet.
- Compass updates and camera rotation no longer rebuild the whole map screen.
  The reset-north control listens to rotation events, including rotation without
  panning. Unchanged pandal marker widgets are reused. Squad notifications only
  rebuild the map when displayed squad data changes.
- Cluster cache invalidation covers same-size region/priority changes and zoom
  threshold crossings, preventing stale or incorrectly clustered pins.
- Final static analysis: no issues. Complete regression suite with live routing
  enabled after the keyboard correction: **434 passed**, no skips.
- Focused discovery/capture suite: 114 passed. After correcting the rotation
  event handling, map/navigation/layout follow-up: 55 passed. Rebuild checks
  verify that compass and camera rotation preserve the tile-layer widget while
  the reset-north button appears and clears correctly.
- Logs: `app/build/discovery_map_full_tests.log`,
  `app/build/discovery_map_final_tests.log` (final complete suite),
  `app/build/discovery_map_checks.log`, `app/build/discovery_map_live_checks.log`,
  `app/build/discovery_rotation_checks.log`, and
  `app/build/discovery_map_analyze_final.log`. The live-check log also records
  the initial reset-control failure, subsequently fixed and verified by the
  rotation follow-up suite.

These checks establish reduced rebuild work, not a measured frame-rate guarantee.
Outdoor arrival and receipt by a second physical phone remain unverified.

## Release installation follow-up — 11 October 2026, 08:32 IST

- Verified the final discovery/map APK signature and version: **1.0.0 (2013)**.
- Installed the final rebuilt APK on the Motorola Edge50 with `adb install -r`;
  installation succeeded with app data preserved. The installed package reports
  an update time of `2026-10-11 08:32:38`.
- Confirmed Uma was in the foreground after launch. The device UI exposed `Live`
  and pandal route controls. This is a launch smoke check; it does not establish
  continuous GPS, outdoor arrival, or receipt on a second phone.
- The existing final validation logs report 434 passing tests and clean static
  analysis. These checks were not rerun during this installation follow-up.
