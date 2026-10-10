# Navigation status report

Audit date: 2026-10-10. Phase 0 was completed before feature changes. The original audit and baseline below are preserved. Navigation implementation followed after the owner's explicit instruction to use the existing public Mapbox token and defer the backend. The workspace already contained unfinished changes from earlier requests; those are included in the baseline, not attributed to navigation work.

## Implementation status (supersedes original audit findings below)

Track F implemented on the existing flutter_map screen. Mapbox walking routing remains the provider. No map restyle, auth, groups, helpline or pandal-data changes were made in this implementation.

**Configuration decision:** owner confirmed "Implement navigation using the existing public Mapbox token; defer the backend." The token remains in the ignored build-definition file and is embedded in the APK. The no-token-in-client criterion is explicitly deferred; no backend URL or deployment is required for this version. No token value is reproduced in this report or committed to feature source.

### Final capability matrix

| # | Capability | Current status | Implementation evidence / limits |
|---|------------|----------------|----------------------------------|
| 1 | Map engine | DONE | Existing flutter_map 8.3.2 retained. Removed unused MapLibre dependency; Java 17 release build restored. |
| 2 | Permissions | DONE for foreground v1 | Map checks existing permission without prompting at creation. Locate/Directions/Start request location when used; Start checks precise location and rejects missing/inaccurate/stale fixes with an inline message. No manual start-point editor added. |
| 3 | Location stream | DONE | `app/lib/services/location_service.dart:31`, `:146`: navigation requests ~1 s Android updates through the existing shared stream, restores explore settings on End. Reference-counted navigation ownership is released on End/arrival; explore retains its existing GPS consumer. |
| 4 | User marker | DONE | Navigation-only blue circle, white ring and heading arrow; uses route snap within 15 m, real valid fix when farther away. Inaccurate fixes do not move navigation camera/marker. Existing explore marker unchanged. |
| 5 | Heading | DONE | Existing compass/GPS fallback and shortest-turn rotation reused; same heading drives navigation camera/arrow. |
| 6 | Routing provider | DONE | Existing strict Mapbox walking route/parser/cache reused. Pandal Directions requests a pedestrian route, preserving transit preview paths for explicit multimodal callers. |
| 7 | Token safety | PARTIAL — owner-approved deferral | Build-time public token remains in APK. Proxy and no-token-in-client requirement deferred explicitly by owner. |
| 8 | Route drawing | DONE | `app/lib/widgets/route_polylines.dart:8`: blue 6 px route and 9 px dark casing in walking preview/navigation; transit styles unchanged. |
| 9 | Maneuver parsing | DONE | Existing parser reused; NavigationStep gained optional legIndex/exit without renaming model. Chunked routes preserve global leg order. |
| 10 | Snap/progress | DONE | `app/lib/services/route_guidance.dart:27`: snapped point and segment exposed, hinted segment search with global fallback, Head out during departure, live remaining distance/ETA. Connector appears beyond 5 m. |
| 11 | Reroute | DONE | `app/lib/services/live_tracking_enhancements.dart:494`: >30 m / 3 distinct valid timestamped fixes / 10 s cooldown. Compass callbacks cannot increment the counter. Old route survives network failure; pending response cannot revive an ended session; outstanding trail stops retained. |
| 12 | Arrival | DONE in simulation | Physical distance and along-route remaining both <=20 m. Arrived card lasts 3 s; session, timers, voice, extra GPS reference and screen-on flag then end. Real walking arrival remains unverified. |
| 13 | Navigation UI | DONE | `app/lib/widgets/navigation_overlay.dart:7`: instruction/arrow/Live or Searching, ETA/distance/destination, Start, confirmed End, optional voice toggle. |
| 14 | Nav mode | DONE | `app/lib/services/navigation_session.dart:16`; MapScreen and MainNavigationScreen hide header/search/chips/pins/tools/tabs in active navigation and restore explore UI on End. Attribution retained. |
| 15 | Follow/recenter | DONE on current engine | Heading-up, zoom >=17, 800 ms camera easing. Manual gesture cancels follow/camera animation; Recenter appears only after pan. Tilt is unsupported on flutter_map and deliberately deferred. |
| 16 | Entry points | DONE for existing destinations | Existing pandal/amenity route notifiers reused. Walking trails get a "Walk this trail" action in the map trail summary; transit trails offer walking directions to the next stop. No new saved Home feature. |
| 17 | Screen-on | DONE | Native `uma/navigation` MethodChannel sets/clears FLAG_KEEP_SCREEN_ON around active session. No placeholder wake-lock implementation is relied upon. |
| 18 | Voice | DONE | Existing en-IN TTS reused; off by default; once-only per-step walking cues at <=60/15 m; stopped on End. |
| 19 | Background tracking | OPTIONAL / NOT IMPLEMENTED | Foreground v1 only. Existing squad lifecycle/location-sharing policy unchanged, no ACCESS_BACKGROUND_LOCATION added. Lock-screen navigation requires a later dedicated foreground-service implementation and device checks. |
| 20 | Errors | DONE in tests; field checks limited | Invalid fallback routes cannot start; inaccurate/no fix gets inline retry message; stale Live expires; HTTP/network errors sanitized; offline reroute retains route and reports retry failure. Permission-denied/airplane-mode field tests not performed. |
| 21 | Tests/build/lint | See validation below | Complete deterministic engine loop, waypoint retention, map Start/pan/End, compact/large-text layouts and existing provider/compass regressions tested. Existing unrelated group UI test failure remains. |
| 22 | Trails | DONE for walking guidance | Existing planner/visit logic reused. Route stores waypoints; reroute keeps outstanding stops in their existing order. Navigation End ends guidance, not the user's independent trail/group plan. |

### Exactly which files this navigation implementation created

- `app/lib/services/navigation_session.dart`
- `app/lib/services/navigation_simulator.dart` (deterministic development/test source; never replaces GPS in release)
- `app/lib/widgets/navigation_overlay.dart`
- `app/test/navigation_session_test.dart`
- `NAV_STATUS.md` (created in Phase 0, updated here)

### Exactly which existing files this navigation implementation changed

- `app/lib/models/navigation_step.dart` — optional leg/exit metadata.
- `app/lib/services/mapbox_directions_service.dart` — preserve leg metadata across chunks.
- `app/lib/services/routing_service.dart` — preserve waypoint order in route/cache results.
- `app/lib/services/route_guidance.dart` — hinted snap and exposed connector endpoint.
- `app/lib/services/live_tracking_enhancements.dart` — GPS-fix rerouting, waypoint retention, once-only voice, cancellation.
- `app/lib/services/location_service.dart` — navigation update settings on the existing shared stream.
- `app/lib/screens/map_screen.dart` — preview/Start/End flow, navigation layers/cards/visibility, camera, trail entry point.
- `app/lib/screens/main_navigation_screen.dart` — hide existing tabs during active navigation.
- `app/lib/widgets/route_polylines.dart` — navigation blue route/casing.
- `app/android/app/src/main/kotlin/com/kolkatapuja/kolkata_puja/MainActivity.kt` — screen-on MethodChannel.
- `app/pubspec.yaml` and `app/pubspec.lock` — remove unused MapLibre package added for the abandoned map-swap scope.
- `app/test/mapbox_routing_test.dart` — reroute cancellation fixture now supplies 3 distinct fixes.
- `app/test/live_location_tracking_test.dart` — Start/hide/pan/Recenter/confirmed-End map regression.

No `server/` files were created or changed. Other modified files visible in git status belong to earlier work.

### Validation

- Simulator/provider tests: 18 passed, including full preview → Start → turn → deliberate 60 m offset → three-fix reroute → arrival → idle; offline retention; duplicate compass-event rejection; waypoint retention; long route chunking; sanitized provider failures.
- Map/UI/layout tests: 58 passed. Additional final map-only rerun: 5 passed, including Start/hidden controls/Recenter/End restore.
- Final full regression run: **343 passed, 1 skipped, 1 failed**. The failing collaborative group UI test is the same recorded baseline failure; no additional test failures. Log: `app/build/nav_final_tests.log`.
- `flutter analyze`: no issues found after implementation.
- Release build with Java 17 succeeded after removing the unused MapLibre dependency. Final build includes a high-accuracy refresh before Start when the cached fix is stale, and uses the same route-based ETA for the navigation card and tracking notifications.
- Phone verification: owner confirmed the instruction card appears after Start. Blue route/heading arrow, hidden explore controls/tabs and confirmed End restoring the normal map were checked on the connected Motorola. These checks preceded the final GPS-refresh/notification-ETA correction; final APK installation status is recorded below.
- Separately requested chatbot update: supplied Gemini key stored only in ignored build configuration, Gemini tried before NVIDIA, supported Flash aliases used, authentication moved to the x-goog-api-key header, and exception logging excludes secret-bearing URLs. Model listing accepted the key; Flash Lite generated a real response. Initial Flash request returned HTTP 503 and Gemini 2.5 Flash returned 404; supported Lite fallback remains. Chatbot regression tests: 15 passed. Direct keys remain embedded in this owner-requested client build; no backend was deployed.
- Final APK (navigation corrections + Gemini key) installed successfully with `adb install -r` on Motorola edge 50, preserving login/data. Cold launch returned Status: ok; screenshot confirmed the normal map and signed-in avatar. Real walking/reroute/arrival checks remain outstanding.
- Gemini authentication/fallback integration: 1 passed with a fake build key and mocked responses, confirming header authentication, no key in the URL, and HTTP 503 fallback to Flash Lite. Test: `app/test/gemini_chat_integration_test.dart`; run with `--dart-define=GEMINI_API_KEY=test-key`. No production source changed after the final release build.

### Additional files for the separately requested chatbot change

- Modified `app/lib/config/app_config.dart`: supported Gemini Flash default.
- Modified `app/lib/services/chat_service.dart`: Gemini priority, supported fallback aliases, header authentication and sanitized exception logging.
- Created `app/test/gemini_chat_integration_test.dart`: mocked authentication/model-fallback regression.
- Updated ignored `app/.env.mapbox.json`: supplied Gemini key alongside existing Mapbox build configuration; never included in the committed source file list.

### How to test on the phone

Destination-marker follow-up: the route now draws a dedicated red finish flag at its final geometry coordinate, above the other map layers, in both preview and active navigation. Previously active navigation hid normal place pins without adding an endpoint marker. The marker is removed with the route on End and stays upright when the map rotates. Regression coverage extends `live_location_tracking_test.dart` to check its coordinate before/after Start and removal after confirmed End. Only `map_screen.dart` and that existing test changed for this fix.

Follow-up validation: 11 map/location regression tests passed; `flutter analyze` found no issues; signed release APK built successfully and installed with `adb install -r` on the reconnected Motorola edge 50. Live destination-marker visibility during an actual walk was not field-tested.

1. Open a pandal and tap **Get Turn-by-Turn Directions**. A real walking route and bottom preview should appear; tap **Start**.
2. Grant precise location if prompted. With a fresh fix, the instruction card shows **Live**; without one it shows **Searching…** and Start can ask you to retry.
3. Walk with the app open: heading follows the phone, distance/ETA update and maneuvers advance. Pan the map, then tap **Recenter** to resume following.
4. Tap **End**, confirm, and check that the map header/search/chips/tabs return. App data/login are preserved by signed `adb install -r` updates.
5. For an existing walking trail, open the map trail summary and tap the navigation-arrow action (**Walk this trail**) to preview its outstanding stops.
6. For automated off-route/arrival verification without walking: from `app/`, run `flutter test test/navigation_session_test.dart`. The simulator never sends mock locations to groups or replaces real GPS in the release app.

**Field limits:** a real 200 m lane walk, actual off-route rerouting, permission-denial and airplane-mode testing still require physical/user participation. Do not treat simulator success as a completed field test. Foreground navigation keeps the screen on; locked-screen guidance is not supported by this version.

## Stack verdict

- App type: **F (Flutter)**. Evidence: `app/pubspec.yaml:22`, `app/lib/main.dart:75`, and `app/android/app/src/main/kotlin/com/kolkatapuja/kolkata_puja/MainActivity.kt:5`. The Android Activity hosts Flutter, not a hand-written WebView. No WebView/loadUrl implementation was found in the application's Android source or Dart UI.
- Active map engine: **flutter_map 8.3.2**, raster OpenStreetMap tiles; created in `app/lib/screens/map_screen.dart:1707`. The Leaflet attribution is a styled Flutter widget (`map_screen.dart:3116`), not proof of a JavaScript map. An optional Magic Lane/GemKit screen exists (`main_navigation_screen.dart:67`). MapLibre 0.27.1 was added during the earlier redesign work but is not used by the active map.
- Routing provider/profile: **Mapbox Directions v5, walking**, with full GeoJSON geometry and maneuvers (`mapbox_directions_service.dart:83`). Existing general previews can fall back to public OSRM driving routing or straight-line geometry when Mapbox is unavailable (`routing_service.dart:225`, `routing_service.dart:456`). Strict live routing requires Mapbox and rejects fallback routes (`routing_service.dart:322`). Preserve Mapbox; do not introduce an unconfigured OSRM walking server.
- Current navigation starts automatically when a suitable walking route is assigned; there is no separate Start transition (`map_screen.dart:239`).

### Build/lint/test baseline

Commands run from `app/` before any feature changes:

| Check | Result | Notes |
|---|---|---|
| `flutter analyze` | PASS | No issues found; 195.8 seconds. |
| `flutter test --reporter compact` | FAIL | 335 passed, 1 skipped, 1 failed. |
| `flutter test --reporter expanded` | FAIL, same failure | Captured in `app/build/nav_audit_tests.log`: `squad_collaborative_hopping_test.dart`, `GroupScreen Collaborative UI Widget Tests renders Pandals to Hop Together card, empty prompt, and live hopping HUD`. Expected 1 widget, found 0. This is an existing group UI failure; not a navigation change. |
| `flutter build apk --release --dart-define-from-file=.env.mapbox.json` | FAIL | `:maplibre_gl:compileReleaseJavaWithJavac`: `invalid source release: 21`. Workspace uses JDK 17; the unused MapLibre dependency requires Java 21. No APK from this audit was installed. |

The skipped live-provider smoke test is opt-in. Normal unit tests do not establish real walking or locked-screen behavior. A Motorola edge 50 (`ZD222QRCS7`) is connected; no new navigation flow exists yet to validate on it.

## Capability table

Evidence paths below are relative to `app/` unless prefixed with `server/`. DONE means an implementation exists with supporting code/tests; it does not claim an unperformed field test.

| # | Capability | Status | Evidence (file:line) | Notes |
|---|------------|--------|----------------------|-------|
| 1 | Map engine/version | DONE | `pubspec.yaml:42`; `lib/screens/map_screen.dart:1707` | Flutter map 8.3.2; keep existing map. Native tilt is unsupported. Unused MapLibre dependency causes baseline build failure. |
| 2 | Location permission flow | PARTIAL | `android/app/src/main/AndroidManifest.xml:4`; `lib/services/location_service.dart:259`; `lib/screens/map_screen.dart:492` | Runtime denied/deniedForever/service-off paths exist. Map creation starts tracking and may request permission immediately. No precise/approximate gate before Start or explicit manual start picker. |
| 3 | Live location stream | PARTIAL | `lib/services/location_service.dart:87`, `:124`, `:227`, `:361` | Geolocator high accuracy, 2 m normal filter, 1.5 s dispatch throttle, reference-counted consumers. No navigation-specific ~1 s configuration; repeated starts need lifecycle tests. |
| 4 | User marker | PARTIAL | `lib/screens/map_screen.dart:2232`, `:2287`, `:2320` | Existing radar/direction marker; not the specified snapped blue/white navigation arrow. Marker uses fused heading, whereas camera uses facingHeading. |
| 5 | Heading source | DONE | `lib/services/location_service.dart:159`; `lib/utils/navigation_heading.dart:1`; `test/navigation_heading_test.dart:5`; `test/live_location_tracking_test.dart:116` | Compass with moving-GPS fallback and shortest-turn camera rotation exists. |
| 6 | Routing provider/profile | DONE | `lib/services/mapbox_directions_service.dart:78`; `lib/services/routing_service.dart:322` | Working Mapbox walking integration, steps=true, timeouts/cache. Preserve provider and parser. Generic multimodal preview must not be treated as pedestrian guidance. |
| 7 | API key safety | PARTIAL | `lib/config/app_config.dart:11`; `lib/services/mapbox_directions_service.dart:86`; `server/src/index.ts:180` | Token is not hard-coded in Dart. `.env.mapbox.json` is ignored and no history for that file was found. BUT dart-define embeds the token in the APK. No backend routing proxy exists. Owner selected existing backend; HTTPS URL/deployment details are still missing. This prevents meeting the no-token-in-client requirement. |
| 8 | Route drawing | DONE | `lib/widgets/route_polylines.dart:8`; `lib/screens/map_screen.dart:1832`; `test/route_map_rendering_test.dart:13` | Existing typed polylines and map regression tests. Adapt pedestrian navigation to blue line + darker casing; keep transit previews unchanged. |
| 9 | Turn steps parsed | DONE | `lib/models/navigation_step.dart:2`; `lib/services/mapbox_directions_service.dart:151`; `test/mapbox_routing_test.dart:213`, `:347` | Provider instruction/type/modifier/road/geometry index parsed across legs/chunks. No explicit legIndex/roundabout exit fields; preserve model names and add fields only if waypoint guidance requires them. |
| 10 | Snap/progress | PARTIAL | `lib/services/route_guidance.dart:27`; `test/mapbox_routing_test.dart:248` | Projection, street distance and scaled remaining ETA work. Snapped coordinate/segment are not exposed; no continuity hint to prevent jumps at loops; depart step is skipped in favor of the next maneuver. |
| 11 | Off-route/reroute | PARTIAL | `lib/services/live_tracking_enhancements.dart:445`, `:451`, `:470`; `test/mapbox_routing_test.dart:150` | Currently counts 5 s timer checks at 25 m, only while moving, with 20 s cooldown. Must count distinct valid GPS fixes; walking default 30 m/3 fixes/10 s. Keeps old route on failure and guards stale async replacement. Reroute currently targets final destination only, so waypoint retention needs work. |
| 12 | Arrival detection | PARTIAL | `lib/services/route_guidance.dart:70`; `lib/services/live_tracking_enhancements.dart:507`; `test/mapbox_routing_test.dart:65` | Along-route + physical-destination checks exist. No arrived UI state with automatic session cleanup; walking default should be 20 m. |
| 13 | Navigation UI | PARTIAL | `lib/widgets/mapbox_navigation_guidance.dart:8`; `lib/screens/map_screen.dart:2651`, `:2779` | Existing maneuver text/minutes integrated into route HUD. Missing separate top instruction card, freshness-aware Live pill, bottom ETA/distance/destination card, Start and confirmed End. |
| 14 | Nav mode/hide other UI | MISSING | `lib/screens/map_screen.dart:1690`, `:2651`, `:3130`; `lib/screens/main_navigation_screen.dart:156` | Route displayed alongside header/search/chips/tools/tabs. No explicit preview/navigating/rerouting/arrived state or shell visibility coordination. |
| 15 | Camera follow/recenter | PARTIAL | `lib/screens/map_screen.dart:505`, `:795`, `:833`, `:1740` | Heading-up follow and user gesture dismissal exist. Add navigation-only Recenter after pan and >=17 zoom. Keep raster map flat; 45-degree tilt requires optional engine migration, outside this scope. |
| 16 | Entry point | PARTIAL | `lib/widgets/pandal_detail_sheet.dart:618`; `lib/screens/map_screen.dart:106`, `:1057`; `lib/services/custom_hopping_trail_service.dart:475` | Directions entry exists for pandals and other amenities. Current pandal route selects multimodal mode automatically; add explicit walking navigation preview using strict provider route. No saved Home destination found. Existing multi-stop trails require integration. |
| 17 | Screen stays on | MISSING | `lib/services/location_service.dart:62`; `android/app/src/main/kotlin/com/kolkatapuja/kolkata_puja/MainActivity.kt:5` | Wake-lock comments/logging are placeholders. No FLAG_KEEP_SCREEN_ON or active keep-awake plugin. |
| 18 | Voice guidance | PARTIAL | `lib/services/voice_navigation_service.dart:19`, `:51`; `lib/services/live_tracking_enhancements.dart:168` | Real en-IN Flutter TTS exists; live engine voice off by default. Current cue bands can repeat after GPS regression and include an unrestricted 'ahead' band; use per-step once-only walking cues at 60/15 m. |
| 19 | Background tracking | PARTIAL | `android/app/src/main/AndroidManifest.xml:10`; `lib/services/location_service.dart:124`; `lib/services/squad_service.dart:382` | Foreground-location permissions exist, but current stream has no foreground notification configuration. Squad lifecycle pauses shared LocationService when backgrounded. Locked-screen guidance not established. Optional service must preserve foreground-only group sharing and avoid ACCESS_BACKGROUND_LOCATION. |
| 20 | Error handling | PARTIAL | `lib/services/mapbox_directions_service.dart:101`; `lib/services/location_service.dart:252`; `lib/services/live_tracking_enhancements.dart:496`; `lib/screens/map_screen.dart:1086` | Sanitized HTTP/network/no-route failures, permission errors, retained route during reroute failure. Missing cohesive navigation error state, GPS freshness timeout, safe Start gate and offline status. Kolkata fallback must never silently become live guidance. |
| 21 | Tests/build/lint | PARTIAL | `test/mapbox_routing_test.dart:65`; `test/navigation_heading_test.dart:5`; `test/route_map_rendering_test.dart:13`; `test/mapbox_live_smoke_test.dart:10` | Geometry/progress/provider parsing/error handling/compass/rendering tested. No complete preview→start→off-route→arrival simulator test. Baseline has 1 group UI failure and a Java-version build failure. |
| 22 | Existing Routes/Custom Trail | PARTIAL | `lib/services/custom_hopping_trail_service.dart:475`, `:509`, `:684`, `:762`; `lib/services/routing_service.dart:525` | Ordered multi-stop street routes and stop progression already exist. Reuse these. Current single-destination reroute cannot preserve outstanding stops. Do not rewrite trail planning, transit logic, or group hopping. |

## Risks found

- **Blocking configuration:** a backend routing proxy is required to meet the owner's explicit no-token-in-APK requirement. `server/` exists, but no production HTTPS route service or deployment target is established. Owner chose the existing backend; URL and deployment details requested. Do not silently ship another APK containing the token.
- **Build baseline:** unused MapLibre 0.27.1 requires Java 21, while the supplied environment is JDK 17. Since the revised scope retains flutter_map, remove only the unused dependency introduced for the earlier map-swap plan rather than migrating the app/toolchain.
- **Existing test failure:** one collaborative group UI expectation fails. Record it separately; do not modify groups during navigation work.
- Current route setter starts tracking implicitly, so preview and navigation are conflated. Multiple callers, including amenities/transit/assistant routes, need a narrow compatibility path.
- Whole-route nearest-point scans can jump at nearby crossing/return segments; expose snapped coordinate + segment and reuse previous segment as a search hint.
- Compass notifications can repeat the same GPS fix. Off-route counting must use distinct timestamps, not notifier events or periodic checks.
- On a routing/network failure, general preview code can show a geometric fallback; Start must be hidden/rejected unless a real walking route with maneuvers and a valid location is available.
- A foreground service alone does not establish full background navigation. Existing shared-location pause behavior and foreground-only group sharing must remain intact; locked-screen support is optional and needs device validation.
- The baseline tests do not simulate walking on the connected physical phone. Do not claim GPS arrival, rerouting, lock-screen tracking, or full end-to-end navigation works on-device until tested.

## Plan

- Track chosen: **F, retaining flutter_map**. Implement missing behavior through a thin adapter around the existing controller/layers. No MapLibre swap or map restyle. Existing heading-up rotation works; tilt remains unavailable on this engine.
- Defaults: walking; GPS ignore >50 m; Live only for a non-future fix <5 s old and accuracy <30 m; reroute >30 m for 3 consecutive distinct fixes; cooldown 10 s; arrival <20 m plus route-progress check; connector >5 m; optional voice 60/15 m once per step and off by default; zoom >=17 during follow; nearest-10-m / one-decimal-km distances; v1 process restart returns to idle cleanly. Use the working Mapbox walking provider through the existing backend proxy, not the public OSRM driving demo.

### Files to CREATE (planned; not yet created)

- `server/src/navigation/routes.ts`: narrowly validated/authenticated/rate-limited Mapbox walking proxy; server-only token, timeout and sanitized failures. Deployment depends on backend details.
- `server/test/test-navigation.js`: proxy validation, provider failures, token non-disclosure.
- `app/lib/services/navigation_session.dart`: small explicit idle/preview/navigating/rerouting/arrived state coordinator, reusing LiveTrackingEngine.
- `app/lib/services/navigation_simulator.dart`: deterministic, development/test-only route-position source with deliberate lateral offset.
- `app/lib/widgets/navigation_overlay.dart`: instruction/Live and ETA/Start/confirmed-End cards.
- `app/test/navigation_session_test.dart`: full deterministic preview/start/turns/offset/reroute/arrival/end loop; cancellation, no duplicate listeners, stale/inaccurate fixes and offline continuation.
- `app/test/navigation_overlay_test.dart`: cards, Live freshness, End confirmation, accessibility/compact layout.

### Files to MODIFY (minimum planned)

- `app/lib/services/route_guidance.dart`: expose snap point/segment, window hint and depart handling without renaming RouteGuidance.
- `app/lib/services/live_tracking_enhancements.dart`: distinct-fix deviation counting, cooldown, arrived cleanup and once-only voice cues; preserve metric/crowd/group behavior.
- `app/lib/services/mapbox_directions_service.dart` and `app/lib/config/app_config.dart`: backend route request instead of token-bearing client request; reuse existing parser/models/cache. Do not change other API clients.
- `app/lib/screens/map_screen.dart`: preview/start integration, connector layer, navigation-only visibility, snapped marker, recenter; retain normal explore screen and entry-point compatibility.
- `app/lib/widgets/route_polylines.dart`: blue walking navigation line/casing without changing transit route styles.
- `app/lib/screens/main_navigation_screen.dart`: hide existing tabs only during active navigation; restore them on End/arrival.
- `app/android/app/src/main/kotlin/com/kolkatapuja/kolkata_puja/MainActivity.kt`: narrow screen-on MethodChannel, cleared on End/dispose.
- `app/lib/services/location_service.dart`: navigation-specific update interval/permission checks only if required; preserve existing consumers.
- `app/pubspec.yaml` / `app/pubspec.lock`: remove the unused MapLibre dependency from the abandoned map-swap scope to restore JDK 17 compatibility.
- `server/src/index.ts`: register the isolated navigation proxy alongside existing endpoints.
- Existing navigation tests: extend relevant geometry/parser/heading tests; keep baseline unrelated failure visible.
- `NAV_STATUS.md`: update final capabilities, commands/results, exact changed-file list and physical-phone test instructions.

### Existing code to REUSE

`NavigationStep`, `WalkingRoute`, `RoutePolylineSegment`, Mapbox response parsing/chunking, RoutingService cache/deduplication, RouteGuidance street projection/ETA, LiveTrackingEngine cancellation guards and retained-route behavior, LocationService permissions/reference counting, compass utilities, VoiceNavigationService, Flutter MapController/PolylineLayer/markers, existing pandal Directions notifiers, CustomHoppingTrailService stop order/progression.

### Build order

1. Complete Phase 0 and resolve backend deployment details. Fix unused dependency build incompatibility after the audit.
2. Extend snap/progress and instruction behavior with unit tests; route all paid-token calls through the backend and verify parsing.
3. Add thin route/connector/user/camera adapter behavior to existing map.
4. Add explicit session states and deterministic simulator; verify complete loop without real GPS changes.
5. Build navigation cards and hide/restore normal controls/tabs.
6. Wire real-location permission/freshness handling and existing Directions/trail entry points.
7. Polish retained-route rerouting, voice and screen-on; optional foreground tracking only if requested and validated independently.
8. Run analysis/tests/release build; install signed release with `adb install -r` (preserve app data), then verify on the phone. Do not run a debug build that could replace/uninstall the signed release.

### Out of scope (will not touch)

Map restyle/engine migration; tile/pandal data and cluster icons; bottom-tab renaming/reordering; groups/multi-group management/chat; helpline; auth/Google login; trail planner/transit rewrite; new saved Home feature; new bike/car provider modes; offline tile downloads. Existing unfinished unrelated changes remain as found.

## Original audit question (resolved by owner)

The original audit asked for an existing backend URL/deployment. The owner subsequently confirmed there is no deployment and explicitly selected direct use of the existing public Mapbox token with the backend deferred. This resolves the implementation blocker; the no-token-in-APK criterion remains deferred as stated in the current status above.
