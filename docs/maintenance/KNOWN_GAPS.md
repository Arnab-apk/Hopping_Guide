# UMA — Known Gaps & Remaining Issues

**Branch:** `fix/critical-issues`  
**Date:** 2026-09-25  
**Status:** Documented for next sprint

---

## Summary

| Severity | Count |
|----------|-------|
| High | 1 |
| Medium | 2 |
| Low | 2 |

---

## High Severity

### 1. App Disconnects After ~3 Minutes on Device
**Symptom:** App runs fine for 2-3 minutes, then loses connection to Dart VM (`Lost connection to device` in logs). Process stays alive but debug session dies.

**Evidence:**
```
I/flutter (19636): [VoiceNav] Initialized successfully
I/Choreographer(19636): Skipped 92 frames!  The application may be doing too much work on its main thread.
D/Surface (19636): Surface::disconnect
...
Lost connection to device.
```

**Suspected Causes:**
- Memory leak in `MapScreen` (5530 lines, many listeners, animation controllers)
- GC pressure from frequent GPS updates + map marker rebuilds
- `flutter_tts` / `flutter_compass` native channels not cleaned up
- `StreamSubscription` leaks in `SquadService` / `LocationService`

**Debug Commands:**
```bash
# Profile memory on device
flutter run --profile -d ZD222QRCS7
# Then open DevTools → Memory → take heap snapshots every 30s

# Check for listener leaks
grep -r "addListener" app/lib/services/ | grep -v "removeListener"
```

**Proposed Fix:**
1. Add `dispose()` audit — every `addListener`/`StreamSubscription`/`AnimationController`/`Timer` must have matching cleanup
2. Wrap heavy map layers in `RepaintBoundary`
3. Reduce `setState` frequency in `_startContinuousTracking` (throttle to 500ms for UI updates)
4. Use `flutter run --trace-startup --profile` to measure baseline

---

## Medium Severity

### 2. SharedPreferences PlatformException on Android
**Symptom:** Channel error when accessing prefs:
```
E/flutter: PlatformException(channel-error, Unable to establish connection on channel: 
  "dev.flutter.pigeon.shared_preferences_android.SharedPreferencesApi.getAll"., null, null)
```

**Impact:** User preferences (login state, tutorial seen, settings) may not persist across restarts.

**Root Cause:** `shared_preferences_android` pigeon channel fails to initialize — possibly version mismatch or missing Gradle config.

**Files:**
- `pubspec.yaml`: `shared_preferences: ^2.5.5`
- Android `build.gradle` may need `namespace` or `compileOptions` fix

**Proposed Fix:**
```bash
# 1. Upgrade to latest
flutter pub upgrade shared_preferences

# 2. Verify Android Gradle config
# android/app/build.gradle:
android {
    namespace "com.kolkatapuja.kolkata_puja"
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_17
        targetCompatibility JavaVersion.VERSION_17
    }
}

# 3. Add test mock to verify
# test/shared_preferences_mock.dart:
class MockSharedPreferences extends Mock implements SharedPreferences {}
```

### 3. GemKit / MagicLane Native Plugin Not Wired
**Symptom:**
```
I/flutter: ⚠ GemKit initialization note: MissingPluginException(
  No implementation found for method initializeGemSdk on channel 
  plugins.flutter.dev/gem_engine)
I/flutter: [OfflineMap] Initialization error: Failed to load dynamic library at path: libdartjni.so
```

**Impact:** 3D map / offline tiles / advanced routing unavailable. App falls back to `flutter_map` (OSM raster).

**Root Cause:** `magiclane_maps_flutter` plugin (local at `plugins/magiclane_maps_flutter`) not properly registered in `GeneratedPluginRegistrant` or missing native `.so` libs.

**Files:**
- `app/plugins/magiclane_maps_flutter/` — local plugin
- `app/android/app/src/main/kotlin/.../MainActivity.kt` — may need plugin registration
- `app/pubspec.yaml`: `magiclane_maps_flutter: path: plugins/magiclane_maps_flutter`

**Proposed Fix:**
1. Verify plugin `pubspec.yaml` declares `flutter: plugin:` and `androidPackage`
2. Check `android/src/main/jniLibs/` has `libgem_engine.so` for arm64-v8a
3. Run `flutter clean && flutter pub get` then rebuild
4. If plugin is incomplete, document as known limitation and keep OSM fallback

---

## Low Severity

### 4. Google Fonts Network Load Fails in Tests
**Symptom:**
```
Error: google_fonts was unable to load font PlusJakartaSans-Regular because:
Exception: Failed to load font with url: https://fonts.gstatic.com/...
```

**Impact:** Test output noise only — doesn't affect production (fonts cached locally on device).

**Fix Options:**
```dart
// test/test_font_loader.dart
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() {
    // Disable network font loads in tests
    GoogleFonts.config.allowRuntimeFetching = false;
    // Provide local fallback
    GoogleFonts.config.fonts = {
      'PlusJakartaSans': GoogleFontsVariant(
        fontFamily: 'PlusJakartaSans',
        fontWeight: FontWeight.normal,
        fontStyle: FontStyle.normal,
        fontUrl: '',
      ),
    };
  });
}
```

Or add `google_fonts` test dependency with local fonts in `test/fonts/`.

### 5. OSRM Multi-Stop Returns HTTP 400 in Tests
**Symptom:**
```
[RoutingService] ❌ OSRM HTTP 400 for multi-stop route
[TrailService] Multi-stop route: 4 pts, isFallback=true, 1.79 km
```

**Impact:** Multi-stop trail routing falls back to geodesic (straight-line) corridors instead of street-following routes. Single-stop routes work fine.

**Root Cause:** OSRM `/route/v1/foot/` endpoint expects specific coordinate format for multi-stop; current payload may exceed URL length or have malformed waypoints.

**Current Code (`routing_service.dart`):**
```dart
// Multi-stop not yet implemented — uses fallback
Future<WalkingRoute> getMultiStopRoute({required List<LatLng> waypoints}) async {
  // TODO: Implement proper OSRM multi-stop call
  return _buildGeodesicFallback(...);
}
```

**Proposed Fix:**
```dart
// Use OSRM trip endpoint for multi-stop (traveling salesman)
// POST /trip/v1/foot/{coordinates}?roundtrip=false&source=first&destination=last
Future<WalkingRoute> getMultiStopRoute({required List<LatLng> waypoints}) async {
  if (waypoints.length < 2) throw ArgumentError('Need at least 2 waypoints');
  
  final coords = waypoints.map((p) => '${p.longitude},${p.latitude}').join(';');
  final url = Uri.parse('https://router.project-osrm.org/trip/v1/foot/$coords?roundtrip=false&source=first&destination=last&geometries=geojson');
  
  final response = await _client.post(url, headers: {...}).timeout(Duration(seconds: 10));
  // Parse response similar to single-route
}
```

---

## Quick Reference Table

| # | Issue | Severity | Effort | Owner | Target Sprint |
|---|-------|----------|--------|-------|---------------|
| 1 | 3-min disconnect | High | 2-3 days | — | Next |
| 2 | SharedPreferences crash | Medium | 1 day | — | Next |
| 3 | GemKit plugin | Medium | 2-5 days | — | Later |
| 4 | Font loads in tests | Low | 0.5 day | — | Anytime |
| 5 | OSRM multi-stop 400 | Low | 1-2 days | — | When trails needed |

---

## Debugging Checklist for Next Session

```bash
# 1. Memory profile
flutter run --profile -d ZD222QRCS7 --trace-startup
# DevTools → Memory → heap snapshot at 0s, 60s, 120s, 180s

# 2. Listener audit
cd app
grep -rn "addListener\|StreamSubscription\|AnimationController\|Timer(" lib/services/ | grep -v "removeListener\|cancel()\|dispose()"

# 3. SharedPreferences test
flutter test test/shared_preferences_test.dart

# 4. GemKit check
ls -la app/plugins/magiclane_maps_flutter/android/src/main/jniLibs/

# 5. OSRM multi-stop manual test
curl "https://router.project-osrm.org/trip/v1/foot/88.36,22.57;88.37,22.58;88.38,22.59?roundtrip=false&source=first&destination=last&geometries=geojson"
```

---

## Acceptance Criteria for "Fixed"

| Issue | Verification |
|-------|--------------|
| 3-min disconnect | App runs 30+ min on device with `flutter run --profile` without disconnect |
| SharedPreferences | `flutter test` passes; prefs persist across app kill/restart on device |
| GemKit | `initializeGemSdk` succeeds; 3D map renders without `MissingPluginException` |
| Font loads | `flutter test` shows zero `google_fonts` network errors |
| OSRM multi-stop | Returns valid GeoJSON route for 3+ waypoints; no fallback used |

---

**Next Action:** Prioritize #1 (stability) and #2 (data persistence) for next sprint. #3 can be deferred if 3D map not required for Puja 2026 launch.