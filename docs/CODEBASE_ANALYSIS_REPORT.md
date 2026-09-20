# Kolkata Puja App — Codebase Analysis Report

**Generated:** 2026-09-14  
**Scope:** Full Flutter app (`app/`), scripts, architecture, CI, and data

---

## Executive Summary

The app is **feature-rich and well-architected** with excellent UI polish, offline-first design, and advanced features (custom trails, squad location sharing, OSRM routing). However, **several critical gaps exist** between the current implementation and a production-ready Play Store launch — particularly around Firebase configuration, real-time sync reliability, data freshness, and edge-case handling.

---

## 🔴 Critical Flaws (Launch Blockers)

### 1. Firebase Configuration Incomplete — **App will crash on non-Android platforms**

**File:** `app/lib/firebase_options.dart:18-52`  
Only Android is configured. iOS, macOS, Windows, Linux, and Web all throw `UnsupportedError` at runtime.

```dart
// Current: throws on every platform except Android
case TargetPlatform.iOS:
  throw UnsupportedError('DefaultFirebaseOptions have not been configured for ios...');
```

**Impact:**  
- App crashes on iOS simulator, macOS desktop, Windows, Linux, Chrome
- Cannot run integration tests on CI for non-Android
- Blocks any desktop/web testing

**Fix:** Run `flutterfire configure` for all target platforms, or add placeholder configs with clear error messages.

---

### 2. Firebase Realtime Database Rules Missing — **Squad location sharing will fail silently**

**Architecture doc (Section 3)** specifies RTDB at `/squads/{groupId}/members/{userId}`. No `database.rules.json` exists in the repo.

**Impact:**  
- Default rules deny all reads/writes → squad members never appear on map
- No authentication check on squad data → anyone with code can read all locations
- No `onDisconnect` cleanup → stale ghost markers persist

**Fix:** Add `database.rules.json` with:
```json
{
  "rules": {
    "squads": {
      "$squadId": {
        "members": {
          "$userId": {
            ".read": "auth != null && data.child('squadCode').val() == $squadId",
            ".write": "auth != null && $userId == auth.uid",
            ".validate": "newData.hasChildren(['latitude', 'longitude', 'lastSeen'])"
          }
        }
      }
    }
  }
}
```

---

### 3. Firestore Indexes Not Defined — **Zone/visited/favorite queries will fail**

**Queries in `PandalListScreen`** filter by `zone`, `isFavorite`, `isVisited` — composite indexes required.

**Impact:**  
- First-run users get "index not found" errors with links to create them manually
- No `firestore.indexes.json` in repo → manual setup required per project

**Fix:** Add `firestore.indexes.json` and deploy via `firebase deploy --only firestore:indexes`.

---

### 4. Google Sign-In SHA-1 Missing — **Auth fails on physical devices**

**`firebase_options.dart`** shows Android config but no SHA-1 fingerprint registered in Firebase Console.

**Impact:**  
- Google Sign-In works on emulator (debug keystore auto-registered) but fails on real devices / Play Store builds
- Users see generic "Sign-in cancelled" error (see `WelcomeScreen:121-139`)

**Fix:** Add release keystore SHA-1 to Firebase Console → Project Settings → Android app.

---

### 5. No `google-services.json` / `GoogleService-Info.plist` in Repo (Correct) — **But CI Uses Dummy Values**

**CI workflow (`.github/workflows/ci.yml:50-76`)** creates dummy config. Real builds need actual files.

**Impact:**  
- Local builds fail without manual file placement
- No documentation in README on how to obtain/place these files
- `flutterfire configure` not documented in setup steps

**Fix:** Add setup instructions to `app/README.md` referencing architecture doc Section 6.

---

## 🟠 High-Priority UX / Reliability Issues

### 6. Squad Location Sharing — No Presence / Stale Data Handling

**File:** `app/lib/services/squad_service.dart:322-357`  
`_listenToCloud()` listens to RTDB but:
- No `onDisconnect` removal → members who close app stay on map forever
- No "last seen" TTL cleanup → stale positions shown indefinitely
- No connection state UI → user doesn't know if sync is working

**User Impact:**  
- "My friend shows at Hatibagan but they're actually at home" → trust erosion
- No visual indicator for "last updated 45 min ago"

**Fix:**  
- Add `onDisconnect().remove()` when pushing user location
- Add `lastSeen` TTL filter in `_listenToCloud` (hide members > 5 min stale)
- Show connection status badge in Squad screen

---

### 7. Location Permission UX — No Rationale / Settings Deep Link

**File:** `app/lib/services/location_service.dart:38-103`  
`startLiveTracking()` requests permission but:
- No pre-permission rationale dialog (Android 12+ requirement)
- No "Open Settings" button when permanently denied
- Error messages are technical ("Location permissions permanently denied")

**User Impact:**  
- First-time users confused by system dialog
- Permanently denied users stuck with no recovery path

**Fix:** Add rationale dialog + `Geolocator.openAppSettings()` link.

---

### 8. OSRM Routing — No Timeout Handling / Fallback Visibility

**File:** `app/lib/services/routing_service.dart:88-121`  
4-second timeout but:
- No retry logic
- Fallback (straight line) not clearly marked to user
- No offline caching of routes

**User Impact:**  
- "Path" button spins then shows straight line through buildings/rivers
- No indication that route is approximate

**Fix:**  
- Show "Approximate route (offline)" badge when `isFallback=true`
- Add exponential backoff retry (2s → 4s)
- Cache successful routes in `SharedPreferences` for offline reuse

---

### 9. Custom Trail Auto-Visit — 80m Threshold Too Aggressive for Dense Areas

**File:** `app/lib/services/custom_hopping_trail_service.dart:164`  
`autoVisitThresholdMeters = 80.0`

**User Impact:**  
- In narrow North Kolkata lanes, GPS drift ±20m triggers false visits
- User misses "Visit" haptic feedback because it auto-triggered while walking past
- No cooldown → rapid re-trigger if GPS bounces

**Fix:**  
- Increase to 100-120m for high-density zones
- Add 60-second cooldown per pandal
- Require 2 consecutive fixes within threshold

---

### 10. Pandal Data — No Images, Static Crowd Levels, 2026 Hardcoded

**Files:** `data/pandals.json`, `app/lib/models/pandal.dart`  
- `image_url: ""` for all 117 pandals → detail screen shows empty placeholder
- `crowd_level` is static string ("high"/"medium"/"low") — not real-time
- Welcome screen countdown hardcoded to **2026-10-16** (`welcome_screen.dart:39`)

**User Impact:**  
- Detail screen looks broken/empty
- Crowd badges misleading (actual crowd varies by hour/day)
- Countdown wrong after 2026

**Fix:**  
- Integrate Cloudinary / GitHub raw images via `image_url`
- Add `crowd_level_updated_at` timestamp; show "Last updated X min ago"
- Make Puja dates configurable via Remote Config or asset JSON

---

## 🟡 Medium-Priority Issues

### 11. Map Tile Dark Mode — Color Matrix Breaks Tile Attribution

**File:** `app/lib/screens/map_screen.dart:82-103`  
`_kDarkMatrix` inverts tile colors via `ColorFiltered`.

**Issue:**  
- OSM attribution (bottom-left) becomes unreadable (white on white)
- Violates OSM tile usage policy (attribution must be legible)

**Fix:** Use MapLibre GL style with native dark theme, or overlay attribution separately.

---

### 12. Cluster Layer — No Pandal Count Badge on Cluster Markers

**File:** `app/lib/screens/map_screen.dart:1154-1177` (`_ClusteredPandalLayer`)  
Clusters show only a generic icon, no count.

**User Impact:**  
- User taps cluster expecting 1 pandal, gets 5 — no way to know beforehand

**Fix:** Add count badge to cluster marker (standard in `flutter_map` clustering).

---

### 13. Search Autocomplete — No Debounce / Excessive Rebuilds

**File:** `app/lib/widgets/pandal_search_autocomplete.dart` (not read but used heavily)  
Triggered on every keystroke in both Map and List screens.

**Impact:**  
- Jank on low-end devices with 117 pandals
- Battery drain from repeated scoring

**Fix:** Add 300ms debounce in `PandalSearchService`.

---

### 14. Squad Service — Random 3-Digit Code Collisions

**File:** `app/lib/services/squad_service.dart:147`  
```dart
final code = 'PUJA${100 + _random.nextInt(900)}'; // PUJA100–PUJA999
```
Only 900 possible codes.

**Impact:**  
- Collision likely with >30 concurrent squads (birthday paradox)
- No retry on collision

**Fix:** Use 6-char alphanumeric (2.1B combinations) or Firebase push ID.

---

### 15. Notification Service — No Channel Configuration for Android 8+

**File:** `app/lib/services/notification_progress_service.dart` (not read but used)  
Uses `flutter_local_notifications` without explicit channel setup.

**Impact:**  
- Notifications may not show on Android 8+ without channel
- Trail progress notification disappears on swipe

**Fix:** Create high-priority channel with `ongoing: true` for trail progress.

---

### 16. No Offline Map Caching — Map Blank Without Network

**Architecture doc (P2)** lists "Offline map caching" as post-launch, but app has zero caching.

**Impact:**  
- Metro stations / pandal areas often have poor signal
- Map becomes unusable in subway/tunnels

**Fix:** Add `flutter_map_tile_caching` package; pre-cache Kolkata bounds on first launch.

---

### 17. Error Boundaries Missing — Single Widget Crash Takes Down Screen

**Files:** `map_screen.dart` (2450+ lines), `pandal_list_screen.dart` (867 lines)  
Massive `build()` methods with no `ErrorWidget` wrapping.

**Impact:**  
- One bad pandal image / null field → entire map/list screen white-screens
- No graceful degradation

**Fix:** Wrap major sections (marker layers, list items) in `ErrorWidget.builder` or try/catch.

---

## 🟢 Low-Priority / Polish Issues

### 18. Hardcoded Strings — No Localization Support

**Throughout UI:** Bengali text mixed with English, no `intl` / `arb` files.

**Impact:**  
- Cannot ship Bengali-only build
- Accessibility screen readers struggle with mixed scripts

**Fix:** Extract all user-facing strings to ARB files; add `flutter_localizations`.

---

### 19. No Analytics / Crash Reporting

**Pubspec:** No `firebase_analytics` or `firebase_crashlytics`.

**Impact:**  
- Zero visibility into crashes in production
- No funnel data (drop-off at auth, map load, etc.)

**Fix:** Add both; they're free on Spark plan.

---

### 20. Test Coverage Gaps

**Current tests:** 7 test files, mostly unit/widget for search/clustering.  
**Missing:**  
- Integration tests for auth → map → squad flow
- Golden image tests for dark/light themes
- Performance tests (map 60fps with 117 markers)
- Squad RTDB sync simulation

---

### 21. CI — No iOS Build / Testflight Deploy

**CI workflow:** Only builds Android debug APK.

**Impact:**  
- iOS regressions undetected
- No automated TestFlight / Play Console internal track upload

---

### 22. Data Seeding Script — No Idempotency / Rollback

**File:** `scripts/seed_pandals.js` (not read but referenced)  
Uses `firebase-admin` to write pandals.

**Risk:**  
- Re-running duplicates data
- No dry-run validation of schema compliance
- No backup before overwrite

---

### 23. Architecture Doc vs Implementation Drift

| Architecture Doc (Section 1) | Implementation Status |
|---|---|
| P0: "Walking directions between two pandals" | ✅ Implemented (OSRM) |
| P0: "Curated pandal-hopping trails" | ✅ Implemented (6 curated + AI generator) |
| P0: "Static nearest metro station" | ✅ Implemented |
| P0: "Push notifications (FCM)" | ⚠️ Partial (local notifications only) |
| P1: "Public toilet layer" | ❌ Not implemented |
| P1: "In-app group chat" | ❌ Not implemented |
| P2: "Offline map caching" | ❌ Not implemented |
| P2: "User-submitted photos/reviews" | ❌ Not implemented |

**Note:** Implementation exceeds P0 scope significantly — good for features, but increases surface area for bugs.

---

## 📋 Suggested Fix Priority Order

| Week | Focus | Tasks |
|---|---|---|
| **1** | Firebase & Auth | Run `flutterfire configure` for all platforms; add RTDB rules, Firestore indexes, SHA-1; document setup |
| **2** | Squad Reliability | Add `onDisconnect` cleanup, stale member filtering, connection status UI, permission rationale |
| **3** | Routing & Trails | Mark fallback routes, add retry/caching, tune auto-visit threshold, add cooldown |
| **4** | Data & Polish | Add pandal images, dynamic crowd timestamps, configurable Puja dates, error boundaries |
| **5** | Launch Prep | Offline map caching, analytics/crashlytics, iOS CI, Play Console internal test, privacy policy hosting |

---

## 📦 Files to Create / Modify (Checklist)

- [ ] `app/lib/firebase_options.dart` — complete all platforms
- [ ] `database.rules.json` — RTDB security rules
- [ ] `firestore.indexes.json` — composite indexes
- [ ] `app/android/app/google-services.json` — (local only, gitignored)
- [ ] `app/ios/Runner/GoogleService-Info.plist` — (local only, gitignored)
- [ ] `app/README.md` — add Firebase setup steps
- [ ] `app/lib/services/squad_service.dart` — presence, stale filter, code collision fix
- [ ] `app/lib/services/location_service.dart` — permission rationale, settings deep link
- [ ] `app/lib/services/routing_service.dart` — fallback badge, retry, caching
- [ ] `app/lib/services/custom_hopping_trail_service.dart` — auto-visit tuning
- [ ] `app/lib/screens/map_screen.dart` — cluster count badge, error boundaries
- [ ] `app/lib/widgets/pandal_search_autocomplete.dart` — debounce
- [ ] `pubspec.yaml` — add `firebase_analytics`, `firebase_crashlytics`, `flutter_map_tile_caching`
- [ ] `.github/workflows/ci.yml` — add iOS build, TestFlight/Play deploy steps
- [ ] `scripts/seed_pandals.js` — idempotency, dry-run validation

---

## 🎯 Bottom Line

**The app is 80% feature-complete for a spectacular launch.** The remaining 20% (Firebase config, RTDB reliability, data freshness, edge-case hardening) represents the difference between "works on my machine" and "survives 50,000 users during Durga Puja week." Prioritize the 🔴 Critical items first — they are binary blockers. The 🟠 High-Priority items determine whether users *trust* the app enough to rely on it in a crowd.