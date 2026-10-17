# 3D map implementation verification — 17 October 2026

Continued the existing MapLibre/OpenFreeMap migration using
[Pujo Map](https://www.pujomap.com/) as the reference. Existing workspace edits
were preserved.

## Changes completed

- Flat mode hides building extrusions as well as removing camera pitch, in both
  bundled map themes. Street and place labels remain available.
- Pandal clustering observes asynchronous native viewport bounds, including the
  extra area visible on a pitched map. Bounds responses from detached native
  controllers are ignored.
- A recreated native map starts from the current camera, preserving center,
  zoom and rotation when retrying after the raster fallback.
- Marker projection explicitly schedules a frame when its data changes.
- Removed the obsolete Leaflet watermark covering the native attribution
  control. The fallback retry button sits above raster attribution.
- Fixed Android compilation with MapLibre 0.27's Java 21 classes. MapLibre uses
  a Java 21 compiler; the app selects JDK 21 while retaining its Java/Kotlin 17
  bytecode target. Other plugins retain their own toolchains. See
  [Gradle toolchains](https://docs.gradle.org/current/userguide/toolchains.html).

## Validation

- `flutter analyze --no-pub`: no issues.
- Full `flutter test --no-pub`: **472 passed, 5 opt-in tests skipped**.
- Separate opt-in run: **11 passed**, including map regressions, actual Mapbox
  Kolkata walking maneuvers, connected train/metro itineraries to South Kolkata
  and Behala, car-route comparison, and the mocked Gemini authentication/model
  fallback test. The Gemini test does not call the live model.
- Final focused map, toolbar and route-rendering checks after the attribution
  adjustment: **14 passed**.
- Signed ARM64 release APK built and installed successfully over the existing
  app on the connected Motorola Edge 50, preserving app data.
- Phone checks: native basemap, street zoom, 3D/2D switching, dark/light theme
  reloads, map settings, Bagbazar search, and a real Bagbazar train/metro route
  preview with street route geometry and destination/station pins.
- Recent phone logs showed no matching Flutter exceptions, fatal exceptions,
  or map camera/projection/overlay errors during these checks.
- `git diff --check`: passed.

## Build artifact

`app/build/app/outputs/flutter-apk/app-release.apk`

SHA-256: `6B0E2F88A31E3C757F5A57EDA3EF559B032A11FBC16085EAF23ECB845B128136`

## Coverage limits

These checks establish the behavior above, not a guarantee that every possible
app flow is faultless. Live calls, push delivery and squad location sharing
across multiple real devices were not exercised. iOS and browser rendering
were not tested on-device in this pass. Building coverage depends on the
underlying geographic data; building extrusions appear at street zoom levels.
