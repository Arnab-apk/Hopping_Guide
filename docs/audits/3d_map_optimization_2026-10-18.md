# 3D map optimization — 18 October 2026

## Changes

- Building and POI visibility changes update native layers in place. Switching
  2D/3D or map-name density retains the loaded style, geographic overlays and
  image atlas. Theme changes still load the appropriate bundled style.
- Camera pitch is retained independently of delayed native camera callbacks.
  Programmatic moves and theme reloads preserve the current pitch; 2D/3D
  controls explicitly select zero/45 degrees.
- A native gesture delivers one position callback instead of also reporting
  the intermediate Flutter camera synchronization as a programmatic change.
- Camera notifications are coalesced per Flutter frame. Marker artwork widgets
  are reused during projection-only updates. A regression sends 30 camera
  notifications and verifies one projection with the same artwork widgets.
- Late projection responses cannot restore obsolete marker lists or apply
  results from a detached native controller. Projection result lengths are
  checked before pairing screen coordinates with marker identities.
- Stable marker keys no longer trigger continuous bitmap snapshots. Live
  tracking artwork and the selected pandal pulse opt in to nested-animation
  refreshes. Pandal identity is stable across selection and clustering updates.
- Separate native symbol layers preserve upright versus map-aligned rotation,
  matching the Flutter tap targets. Dashed route lines render beneath pins.
- Native bounds updates skip unchanged regions and retain pending requests
  while an earlier bounds query completes.
- Two existing catalog tests assumed exactly 338 records, whereas the user's
  existing workspace data contains 347. They now allow catalog additions while
  retaining minimum coverage, unique-ID, coordinate and cache assertions.
  Existing data edits were preserved.

## Verification

- Full `flutter test --no-pub`: **479 passed, 5 opt-in tests skipped**.
- `flutter analyze --no-pub`: no issues.
- `git diff --check`: passed.
- Signed ARM64 release built and installed on the connected Motorola Edge 50
  using `adb install -r`, preserving app data.
- Phone checks: street-level 3D buildings, cluster-to-individual-pin zoom,
  repeated drags and zoom buttons, 2D/3D switching, map-name settings,
  dark/light theme reloads, and opening/closing the Hatibagan Sarbojanin popup
  by tapping its native pin. Dark mode was restored.
- App-process logs sampled after these interactions contained no matching
  camera, projection, artwork, visibility, overlay or Flutter exception errors.

Generated evidence is in `app/build/`: `map-optimization-tests.log`,
`uma-map-3d-qa.mp4`, `uma-map-check.png` and `uma-map-light.png`.

Release: `app/build/app/outputs/flutter-apk/app-release.apk`.

SHA-256: `9EE1B76E41F28A4ABA58719E7DD1810D3479DE41178941D43C1B5033369057C8`.

## Limits

These checks verify the exercised behavior and reduced redundant work; they
do not establish zero dropped frames under every device/network condition.
The phone recording and screenshots are sampled interaction evidence, not a
native renderer FPS benchmark. Physical multitouch pinch/rotation, iOS/web,
and live multi-device squad sharing were not exercised in this pass. Automated
checks cover Android/iOS projection scaling, camera synchronization, pin taps,
marker reorder, fallback/retry, style restoration, routes, live tracking, and
compact/landscape/large-text layouts.
