# Map marker and UI audit — 17 October 2026

## Fixed issues

1. **Pins moved separately from the map.** The old implementation drew visible
   Flutter overlays and waited for asynchronous geographic-to-screen projection
   after native camera movement. Visible pins and map popups now use geographic
   point features and native symbol layers, so the same renderer moves the map
   and its markers. Flutter retains the existing artwork, controls, tap targets
   and accessibility semantics.
2. **Incorrect icon size on dense Android displays.** Native bitmap density and
   the artwork capture resolution are compensated independently. The geographic
   anchor remains consistent with the original Flutter marker alignment.
3. **Clipped pins after cluster/selection changes.** Snapshots include padding
   for shadows and halos. Native texture names are reused only for matching
   dimensions. A capture from an outdated marker size or map instance is
   discarded before upload.
4. **Landscape toolbar overlaps search.** The controls switch to a horizontal
   arrangement on short screens. Regression checks include the expanded
   compass/reset control, which was missing from the previous layout coverage.

Live avatar and compass artwork updates are throttled independently of native
camera rendering. Image names are pooled by dimensions instead of growing for
every newly visible marker. Style reloads restore marker images and geometry.

## Verification

- Full regression suite: **476 passed, 5 opt-in tests skipped**.
- Screen/dialog layout and visual audit: **96 passed** across light/dark themes,
  compact screens, landscape, large text and reduced-motion capture mode.
- Final focused rerun after the clipping fix: **12 passed**, covering native
  geographic pins, Android/iOS density rules, preserved tap actions, style reload,
  image reuse, raster retry, and portrait/landscape toolbar clearance.
- Final `flutter analyze --no-pub`: **no issues**.
- Signed ARM64 release built and installed over the existing app on the
  connected Motorola Edge 50, preserving app data.
- On-device checks included native rendering, marker sizes, repeated camera
  movement, cluster refresh and opening the Park Circus interactive popup by
  tapping its visible native pin. No matching map/Flutter/fatal errors appeared
  in recent logs during the final drag/zoom run. Test images and recording are under
  `app/build/pinned-marker-audit/` (generated, not source-controlled).

The visual audit covered the welcome, map, pandal directory, curated routes,
group, helplines, group settings, group chat, route assistant, video lobby,
profile, tutorial, custom trail planner and pandal detail surfaces. Automated
native-map checks additionally exercise the map controls with native rendering
enabled; general headless layout checks use the raster fallback.

## Build

`app/build/app/outputs/flutter-apk/app-release.apk`

SHA-256: `08D54F7EC432B656DC32E8C48A6830BB617A64C629AE62B148717AF8A1BDD97B`

## Follow-up: icons flashing during zoom

The subsequent zoom report exposed lifecycle and update problems beyond the
initial still-image checks. Native markers now retain their state outside the
projected screen rectangle and use stable geographic keys when unkeyed marker
lists change order. The existing buffered geographic cluster filter still limits
the working set. Identical PNG snapshots are discarded, and artwork refreshes no
longer replace unchanged GeoJSON geometry. Each geometry update is captured
together with its image upload set to avoid publishing points before their images.

Validation: 13 focused map/toolbar tests passed, including off-screen return,
marker reorder, and artwork-only update regressions. Static analysis passed.
The release was installed with user data preserved. Repeated zoom-in/out button
checks on the phone covered clustered and individual pins in dark 3D mode; sampled
screenshots are in `app/build/pinned-marker-audit/zoom-*.png`. Recent logs contained
no matching marker/overlay failures. These sampled checks do not constitute a
frame-by-frame verification of every pinch gesture.

Latest APK SHA-256:
`CBA75682F939FE205A6D2BD8093CAA195F031CE7766205644E11ABE0BC9CC70D`.

## Remaining validation limits

This is the verified scope, not a guarantee that every possible device, network
condition or app state is glitch-free. Physical iOS/browser behavior and live
multi-device call/push/squad flows were not exercised in this UI pass. Existing
unrelated workspace edits were preserved.
