# Mapbox walking navigation

## Map rendering

The primary map surface uses MapLibre with the bundled OpenFreeMap Liberty
light and Dark vector styles (`assets/maps/`). The map supports rotation,
pitch, 3D building extrusions, and native geographic route, circle and marker
layers for pandals, navigation, and squad locations. Marker artwork comes from
the existing Flutter widgets, while MapLibre positions the visible pins and
popups on every native camera frame. Flutter retains their tap targets and
accessibility semantics. `flutter_map` remains a
keyless OpenStreetMap raster fallback for unsupported platforms or a failed
style load. MapLibre styles are public and keyless; Mapbox credentials below
are used only for walking directions and maneuver guidance.

The 2D control disables both camera pitch and building extrusions. Native
viewport bounds drive pandal clustering so pins remain available near the far
edge of a tilted map. If the vector style times out, the raster fallback offers
Retry 3D map and retains the current center, zoom, and rotation.

Android marker images compensate for screen density. Artwork snapshots include
shadow padding; native texture slots are reused only for matching dimensions to
avoid clipping after cluster changes. Live avatar/heading artwork refreshes
independently of map movement. The map toolbar uses a horizontal layout on short
landscape screens so the compass and zoom controls cannot cover search.

Android builds need installed JDK 17 and JDK 21 toolchains. MapLibre 0.27 uses
Java 21; the app compiler also uses JDK 21 to read its classes while the app's
Java/Kotlin target stays at 17. Other plugins retain their own toolchains. If
your JDK installation paths differ, update
`org.gradle.java.installations.paths` in `android/gradle.properties`.

The application uses the Mapbox Directions v5 `mapbox/walking` profile for
street geometry, pedestrian duration and turn instructions. Live GPS guidance
appears below the route summary. Tap the speaker to enable voice instructions;
closing the route cancels guidance. Deviations trigger a new walking request.
Metro and railway legs keep their existing transit routes.

Set `MAPBOX_ACCESS_TOKEN` at build time. The local token file `.env.mapbox.json`
is ignored by Git; never add it to source control. Its JSON format is:

```json
{"MAPBOX_ACCESS_TOKEN": "your_public_mapbox_token"}
```

From `app/`:

```powershell
flutter run --dart-define-from-file=.env.mapbox.json
flutter build apk --release --dart-define-from-file=.env.mapbox.json
```

Directions preserve the supplied stop order. Trails over the API's 25-coordinate
limit use overlapping requests. Route geometry and instructions are cached in
memory for 15 minutes. Network failures yield clearly marked preview corridors;
live requests reject these corridors. Access denial, rate limits, malformed
responses and timeouts produce controlled errors instead of fabricated turns.

Validation:

```powershell
flutter analyze
flutter test
```

For an explicit live API check using the local token:

```powershell
flutter test test/mapbox_live_smoke_test.dart --dart-define=VERIFY_MAPBOX_LIVE=true --dart-define-from-file=.env.mapbox.json
```

The Mapbox API is verified using a real Kolkata walking request. Automated
tests cover maneuver progression, street distance, route caching, ordered long
trails, denied requests, network failures and compact-screen guidance.

API reference: https://docs.mapbox.com/api/navigation/directions/
