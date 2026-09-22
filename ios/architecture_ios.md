# Uma — iOS Native Architecture & Build Plan

**Goal:** Ship a native iOS companion for Kolkata Durga Puja 2026 alongside the Flutter Android app. Liquid Glass design language, MapKit vector rendering, on-device-only operation.
**Today:** Sep 22, 2026 → ~3 weeks to Pujo (Mahalaya: Oct 10, main days Oct 16–21).
**Team:** 2 people. **Budget:** $0 (free tiers + Apple Developer Personal Team).

---

## 1. Why a native iOS port

The Flutter Android app (`hopping_guide_source/`) shipped first. A native iOS port exists for three reasons:

1. **Liquid Glass** — Apple's translucent-depth design language is SwiftUI-native. Web/Flutter approximations look like imitations.
2. **MapKit performance** — MapKit vector tiles fix the Android white-pixel bug at the architectural level (see §3).
3. **Smaller binary, lower memory** — no Flutter engine on the user's device. Important during crowded Pujo walks with low memory headroom.

Both targets share the **same dataset** (pandals.json, food_spots.json, etc.) and the **same algorithm suite** (TSP optimizer, omni-search, haversine). Only the UI shell is separate.

---

## 2. Scope (iOS-specific)

### Shipped in v1
- Welcome screen with animated "Uma Asche" header + live countdown to Maha Shasthi 2026
- MapKit-based map (vector tiles, native clustering, dark cartography)
- Omni-search across pandals / metro / food (token-weighted, phonetic)
- Pandals list (zone filter, sort by distance/rating/crowd, search) + detail screen
- 6 curated Routes (TSP-optimized via Held-Karp + 2-opt)
- Squad Hub (4-card layout, mock local-only sync, separation alerts)
- Squad Chat (text-only, mock local)
- Helplines (one-tap dialer grid: 100/101/102/1091/1077)
- 14 Durga Puja cultural icons (PNG, 3 variants each)
- 6 unit-test files (TrailOptimizer, OmniSearch, Haversine, DouglasPeucker, PandalSpatialCluster, LiquidGlassAvailability)

### Deferred (matches Android v1 omissions)
- Firebase auth / Firestore / Cloudinary — on-device only mode with bundled JSON
- Magic Lane GemKit — replaced by MapKit
- Chat media (base64 images) — text-only for v1
- Bengali Samarkan font — Bodoni 72 system serif substitute
- WidgetKit home-screen countdown widget

### v2 (in progress, addresses Issue #2 UI/UX)
- `ContentUnavailableView` empty states (Squad Hub, Helplines)
- Tab-bar Puja icons (DurgaEyes / DurgaFace / Ashtabhuja / Dhaki / TrishulEyes)
- Smooth search-focus transitions on Map
- 50 pt minimum touch targets on primary actions

---

## 3. System architecture

### Client (SwiftUI app, iOS 18+ deployment, Xcode 27 SDK)

```
┌───────────────────────────────────────────────────────────────┐
│ UmaApp (@main)                                                │
│  └─ AppRoot (TabView shell, Liquid Glass tab bar)            │
│      ├─ Welcome (animated countdown)                          │
│      ├─ MapTab ── MapView (UIViewRepresentable<MKMapView>)    │
│      ├─ PandalsList / PandalsListView / PandalDetail          │
│      ├─ Routes / RoutesView / TrailOptimizer (Held-Karp)     │
│      ├─ SquadHub / SquadDetail / SquadChat                   │
│      └─ Helplines (one-tap dialer)                            │
└───────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────── Services (all on-device) ─────────────────────┐
│ LocationService (CLLocationManager)                           │
│ RoutingService (MKDirections + geodesic fallback)             │
│ OmniSearchService (token-weighted phonetic)                   │
│ TrailOptimizer (Held-Karp DP + 2-opt heuristic)               │
│ SquadService / ChatService (mock local-only)                  │
│ UserStateService (UserDefaults persistence)                   │
└───────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌──────────────── Repositories (bundled JSON) ─────────────────┐
│ PandalRepository    → pandals.json (387 entries)              │
│ MetroRepository     → 41 stations hardcoded                   │
│ FoodSpotRepository  → food_spots.json (66 entries)            │
│ HelplineRepository  → helplines.json + safety_first_aid.json  │
│ ToiletRepository    → toilets.json                            │
└───────────────────────────────────────────────────────────────┘
```

### Map rendering — why MapKit (the white-pixel bug fix)

The Flutter Android app uses `flutter_map` with OSM raster tiles + a throttled tile updater (`rxdart.throttleTime(50ms)`). When in-flight tile requests are cancelled, partial rasters render with their original alpha regions still intact. A subsequent `_kDarkMatrix` ColorFilter — which only operates on **RGB**, not alpha — can't recover those white pixels. Result: bright white "missing pixel" blocks scattered across the dark map canvas. (`hopping_guide_source/app/lib/screens/map_screen.dart:128–149`)

The iOS port uses `MKMapView` (UIKit) via `UIViewRepresentable`. MapKit draws tiles as **vectors** on-device — no raster fetching, no throttling cancellation artifacts, no ColorFilter matrix. Dark cartography is achieved with `MKMapView.overrideUserInterfaceStyle = .dark` + `MKStandardMapConfiguration(emphasisStyle: .muted)`. The bug class is eliminated at the architectural level.

### Liquid Glass strategy

Verified API surface on Xcode 27 SDK:

| API | Status |
|---|---|
| `.glassEffect(_:in:)` | ✅ |
| `.glassEffect(.regular.interactive())` | ✅ |
| `GlassEffectContainer(spacing:)` | ✅ |
| `.tabViewStyle(.glass)` | ❌ doesn't exist |
| `MKMapMapConfiguration` | ❌ typo |

Centralized in `DesignSystem/LiquidGlass.swift`:

```swift
.liquidBackground(.ultraThin, in: Capsule())  // glassEffect on iOS 26+, material on iOS 18-25
.liquidCard(cornerRadius: 22)                  // RoundedRectangle 22pt
.liquidPill()                                   // Capsule
```

Every floating panel (search bar, route HUD, callout, action chips) routes through this — no scattered `if #available` calls.

### Algorithm ports (faithful 1:1)

| Algorithm | File | Notes |
|---|---|---|
| Held-Karp DP `O(N²·2^N)` | `Services/TrailOptimizer.swift` | Exact for N ≤ 12. `numStops == 1` short-circuit preserved. |
| Nearest Neighbor + 2-opt | `Services/TrailOptimizer.swift` | **Preserved 1:1**: inner `break` after first improvement per outer iteration matches Flutter source (max 80 iterations). |
| Haversine + bearing | `Utils/Haversine.swift` | Identical formulas. `formatDistance` returns "850 m" / "1.2 km". |
| Douglas-Peucker simplification | `Utils/DouglasPeucker.swift` | Iterative Ramer-Douglas-Peucker. Tolerance 0.00005 (≈5m). |
| Omni-search token scoring | `Services/OmniSearchService.swift` | Exact/prefix/contains scoring (1300/850/480) + word/prefix-word (320/220) + distance bonus `(15-km) × 5` + rating boost. |
| 10 km corridor + 70 km fallback | `Utils/SpatialCorridor.swift` | Off-corridor threshold matches `AppConfig.offCorridorThreshold`. |

---

## 4. Tech stack

| Layer | Choice | Why |
|---|---|---|
| Framework | **SwiftUI 6** (iOS 18+) + UIKit interop for `MKMapView` | Liquid Glass is SwiftUI-native. `MKMapView` requires UIKit for `MKClusterAnnotation`. |
| Map | **MapKit** (`MKMapView` via `UIViewRepresentable`) + **CoreLocation** | Native vector rendering. No API key, no billing. |
| Routing | **`MKDirections`** (Apple's pedestrian engine) + geodesic × 1.25 circuity fallback | Replaces OSRM. Available offline on Apple Maps. |
| State | **SwiftUI `@Observable` + `Observation` framework** | Native to SwiftUI 5+. No third-party state lib. |
| Persistence | **`UserDefaults`** for user state (visited/favorites/guest name) | Bundled JSON for datasets. No Core Data needed at this scale. |
| Concurrency | Swift 6 structured concurrency (`async`/`await`, `actor`) | `RoutingService` is an actor; all services use `@MainActor` `@Observable`. |
| Build system | **xcodegen** (`project.yml`) | Single source of truth for the Xcode project. Replaces hand-written `project.pbxproj`. |
| Tests | **XCTest** | 6 test files, all green. |
| Signing | **Personal Team** (`DEVELOPMENT_TEAM` in `project.yml`) | Free. Sideload to registered devices. |
| CI | (deferred to v2) GitHub Actions with `macos-26` runner for iOS 26 Liquid Glass visual verification | |

---

## 5. Team split (2 people)

- **Person A — Map & Routing:** `MapView`, `MKDirections` integration, clustering, callouts, walking route polylines.
- **Person B — Algorithm ports & tests:** Held-Karp + 2-opt, Omni-search, Haversine, Douglas-Peucker, regression tests. Screens: Pandals list/detail, Routes, Squads, Helplines, Welcome.
- **Shared — DesignSystem:** Liquid Glass abstraction, Puja icons asset pipeline, theme tokens.

If 1 person: ship map + Welcome first, then features.

---

## 6. Folder layout

```
ios/                                    # iOS project root (native SwiftUI port lives alongside Flutter app/)
├── project.yml                         # xcodegen spec
├── README.md
├── Uma/                                # App source
│   ├── App/
│   │   ├── UmaApp.swift                # @main
│   │   ├── AppRoot.swift               # TabView shell + Puja icons
│   │   └── AppEnvironment.swift        # @Observable DI container
│   ├── DesignSystem/
│   │   ├── LiquidGlass.swift           # liquidBackground() modifier
│   │   ├── Theme.swift                 # PujaColors tokens
│   │   ├── PujaIcons.swift             # 14 icons × 3 variants via Bundle
│   │   └── Haptics.swift
│   ├── Models/                         # 11 Swift structs
│   ├── Repositories/                   # 5 JSON loaders
│   ├── Services/                       # 8 services
│   ├── Utils/                          # 5 math helpers
│   ├── Features/
│   │   ├── Welcome/                    # Animated onboarding + countdown
│   │   ├── Map/                        # MKMapView + UI + callouts
│   │   ├── Pandals/                    # list, detail, card
│   │   ├── Routes/                     # 6 curated circuits
│   │   ├── Squad/                      # 4-card hub + chat
│   │   └── Helplines/                  # Emergency dialer
│   ├── Resources/
│   │   ├── *.json                      # 6 data files (verbatim from Flutter)
│   │   └── Icons/                      # 42 Puja icon PNGs
│   └── Assets.xcassets/                # AppIcon + AccentColor
└── UmaTests/                           # 6 regression test files
```

---

## 7. Issue #2 — UI/UX refinement (v2)

The Android app's Issue #2 calls out visual density and crowded UI. iOS-native patterns address most of this by default (system tab bar, system materials, system pickers). Targeted improvements:

| Concern from Issue #2 | iOS fix |
|---|---|
| Floating controls cluttered | `MapFloatingControls` stacked, 42 pt squircle Liquid Glass buttons |
| Filter chips crowded | Horizontal `ScrollView` (one row, swipeable) — never vertical stacks |
| Empty state visual noise | `ContentUnavailableView` (iOS 17+) with hierarchical SF Symbol + one-line description + max 2 actions |
| Thumb-friendly touch targets | All primary buttons 50 pt min-height. iOS HIG minimum 44 pt, we exceed. |
| Tab transition smoothness | Native `TabView` w/ `.tint(PujaColors.durgaRed)` — system-managed spring transitions |
| Typography consistency | `PujaTypography` exposes `display()`, `rounded()`, `body()`, `mono()` — views pick one role per text element |
| Cohesive color palette | All colors flow through `PujaColors` (PujaColors.durgaRed, festivalGold, etc.). No ad-hoc colors in views. |

### Open Issue #2 items for v2.1
- PandalDetailView progressive disclosure (collapse theme/area/metro sections into a "Show more")
- SquadChatView reply swipe gesture
- Animated tab-bar Puja icon transitions on selection

---

## 8. Build, run, ship

```bash
# Generate Xcode project from project.yml
cd ios
xcodegen generate

# Build for physical iPhone (Personal Team signing)
xcodebuild -project Uma.xcodeproj -scheme Uma \
  -sdk iphoneos -destination 'generic/platform=iOS' \
  -configuration Debug build

# Open in Xcode, set Team ID under Signing & Capabilities
open Uma.xcodeproj
```

### Deploying
1. Register iPhone UDID on Apple Developer portal (or via Xcode auto-register)
2. In Xcode: Product → Run (⌘R)
3. On device: Settings → General → VPN & Device Management → Trust "Ankit Gupta (Personal Team)"

### TestFlight (deferred)
- $99 Apple Developer Program enrollment required
- 14 curated pandals in iPhone-only v2 testing build

---

## 9. What's intentionally not ported

| Android-only feature | Why skipped on iOS |
|---|---|
| Firebase RTDB live location | No backend — mocked locally |
| Firestore queries | Bundled JSON is sufficient for 387 pandals |
| Cloudinary image upload | Chat is text-only v1 |
| Magic Lane GemKit 3D buildings | MapKit `.realistic` elevation is comparable, free |
| Samarkan Bengali font | Not bundled with iOS. Bodoni 72 substitute. Bengali script renders via system fallback for now. |
| Speech/TTS voice navigation | v2.1 |
| `pujoparikrama://` deep linking | v2.1 |

---

## 10. Known v1 limitations

- Liquid Glass visual verification blocked locally: only iOS 18.6 simulator runtime installed; Xcode 27 SDK is iOS 27. iOS 26+ rendering paths will be verified on a macOS-26 GitHub Actions runner in v2.1.
- Tab-bar Puja icons: SF Symbols would be the "safer" default, but we render the actual cultural PNGs (14 icons × 3 variants) to preserve the brand identity from the Flutter app.
- MKDirections requires network access; offline mode falls back to geodesic × 1.25 circuity with Douglas-Peucker simplification. Same behavior as the Flutter OSRM fallback path.
- Squad/Chat are local-mock only. Multi-device squad sync requires Firebase or a backend — out of scope for v1.
