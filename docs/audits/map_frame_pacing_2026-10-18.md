# Map frame pacing follow-up — 2026-10-18

The earlier functional checks did not measure native frame pacing. This pass
uses a signed ARM64 release on the connected Motorola Edge 50 and Android
SurfaceFlinger layer timing, with eight alternating 1.2-second map drags.

## Changes

- Enable MapLibre 0.27.1's TextureView path before constructing maps. Its
  `useHybridComposition` name does not mean Flutter's legacy hybrid composition:
  this SDK setting avoids the SurfaceView-backed virtual display. A release
  built with `--dart-define=MAP_TEXTURE_COMPOSITION=false` retains the former
  path for device comparisons and rollback.
- Read the initial native camera from the existing controller, removing the
  native widget's inherited dependency on every FlutterMap camera update.
- Stop native marker artwork capture when the enclosing tab's TickerMode is
  disabled. Resume capture on return; marker position, semantics and taps remain.
- Request 120 Hz through the Android window's preferred refresh-rate hint.
  This is a request, not a forced system setting or an FPS guarantee.
- Brighten dark-mode street names and increase their text size and dark halo.

## Measurements

| Street-level map drag sample | App Flutter surface average FPS | Intervals >=50 ms |
| --- | ---: | ---: |
| Previous virtual-display rendering | 82.381 | 14 / 815 |
| Texture rendering, before refresh-rate hint | 89.151 | 0 / 885 |

The display was in its 90 Hz gesture mode. Baseline native map surface alone
reported 89.489 FPS, demonstrating why native map FPS alone missed the Flutter
presentation stalls. Texture rendering removed that separate map SurfaceView.
The revised Flutter surface still had 16 intervals >=22 ms. Its Android window
layer separately reported 83.257 FPS and 71 timeline-janky frames out of 822,
mostly attributed by Android to SurfaceFlinger scheduling. These are different
layers and must not be combined into a claim that every visible frame is smooth.

These are short same-device samples, not a controlled long-duration benchmark:
camera positions can drift after inertial drags and cached tiles differ. They
support keeping the rendering change but do not establish sustained 120 FPS,
universal zero jitter, or an app-wide frame-rate guarantee.

Baseline raw timing: `scratch/map-perf/baseline.txt`. Reproduction script:
`scratch/map-perf/measure.py`. The original texture summary is recorded above;
its raw dump was overwritten during a subsequent diagnostic run. That later
run is invalid for visible performance: a call's proximity wake lock had
switched the physical display off. The script now rejects display-off runs
and preserves existing results with timestamped filenames.

## Validation

- Full Flutter suite: **480 passed, five optional tests skipped**.
- Flutter analyze: **no issues**.
- Added regression coverage for deferred hidden-marker artwork and resuming
  uploads when the tab becomes visible.
- Map drag, zoom, 2D/3D toggle, Pandals list scroll, Routes/Helpline tab visits,
  and returning to the 3D map exercised on the texture build. A screenshot
  confirmed street labels and 3D buildings after returning to the map.
- Final visible-device checks were interrupted by the call proximity sensor.
  The 120 Hz hint has not been validated with a visible-display benchmark.

Final signed release APK SHA-256:
`F20C34ADD295AF7A4F11DE205E2093DBF8206FD51B85C984A2E1DE27198AF830`.
Artifact: `app/build/app/outputs/flutter-apk/app-release.apk`.

## Remaining performance work

For a stronger 120 FPS target, profile long sessions with routes and live squad
locations, separate frequently updated points from static route GeoJSON, and
measure marker bitmap capture and platform-channel projection costs. Those
larger changes should be backed by their own regressions and device comparisons.
Physical multitouch, slow-network tile loading, thermal throttling and iOS/web
still need dedicated coverage. No map features were deliberately removed.

References: [Flutter platform-view composition](https://docs.flutter.dev/platform-integration/android/platform-views)
and [Android refresh-rate guidance](https://developer.android.com/media/optimize/performance/frame-rate).
