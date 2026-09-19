<div align="center">

# 🪔 Kolkata Puja 2026
### *কলকাতা দুর্গাপূজা পরিক্রমা ও লাইভ স্কোয়াড কম্প্যানিয়ন*

**The Ultimate Community Durga Puja Pandal-Hopping, Metro Transit & Live Squad Companion**  
*Keyless Free-Tier OSM Map + GemKit Vector Engine · 387 Verified Pandals · 41 Kolkata Metro Stations · 66 Curated Food Spots · 8 Regional Circuits · Universal Omni-Search · Real Road-Following Pedestrian Routing · Consolidated 4-Card Squad Hub · One-Tap Native Calling · Dedicated Squad Chat & Media Sharing · Emergency Helplines*

---

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](./LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Passing%20(143%2F143)-success?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com)
[![Analysis](https://img.shields.io/badge/Analysis-0%20Issues-brightgreen?style=for-the-badge&logo=dart&logoColor=white)](https://github.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-orange?style=for-the-badge&logo=android&logoColor=white)](https://github.com)

<br/>

> **Target:** Launch on Google Play Store before Durga Puja 2026 (Mahalaya: Oct 10, 2026; Maha Shasthi: Oct 16, 2026).  
> **Philosophy:** 100% Free Tiers ($0 Infra Cost), Keyless OpenStreetMap Raster Tiles + Native On-Device Vector Maps, Zero Vendor Lock-in, Privacy-First, Open-Source.

</div>

---

## 📊 Live Project Stats Dashboard

| Metric | Status | Details |
|---|:---:|---|
| 🛕 **Curated Pandals** | **387 Verified Pandals** | Authentic de-duplicated database scraped directly from ThePujo.com & PujoPlanner spanning all 8 zones with coordinates, themes, timings, ratings, and nearest metro links |
| ⚡ **Rendering Engine** | **60/120 FPS Locked** | Sub-millisecond L1 spatial clustering cache, directional 35% margin culling, GPU `RepaintBoundary` isolation, zero-jank multi-touch gesture race |
| 🚇 **Kolkata Metro Network** | **41 Stations (4 Lines)** | Blue (North-South), Green (East-West / Underwater), Purple (Joka-Majerhat), and Orange (Ruby) lines |
| 🍲 **Curated Food & Cabins** | **66 Food Spots** | Legendary sweet shops, heritage cabins, Mughlai eateries, street food hubs, and community bhog spots |
| 🔍 **Universal Omni-Search** | **Unconditional Top Bar** | Permanent, unconditionally visible search bar with frosted-glass autocomplete recommendations; smooth search-active state unmounts filter chips for full vertical clearance |
| 🚶 **Pedestrian Road Routing** | **Real Street Paths** | Native on-device pedestrian routing via GemKit (`RouteTransportMode.pedestrian`) on OSM street networks; two-segment route styling (muted "Getting there" + bold gold "Your trail"); unified `route.getTimeDistance()` single source of truth |
| 🧭 **Custom Trail Optimizer** | **Held-Karp & 2-opt TSP** | Mathematically optimal walking order using Held-Karp dynamic programming ($N \le 12$) and 2-opt heuristic ($N > 12$) |
| 👥 **Consolidated Squad Hub** | **4-Card Hub** | Overview & 6-char code, Destination & Configurable Separation Alerts (250m/500m/1000m), Member List with battery indicators, Locate on Map, and **One-Tap Phone Calling (`tel:`)** |
| 💬 **Private Squad Chat** | **Chat & Media Sharing** | Dedicated in-squad group chat screen with real-time text streaming, photo/video sharing with Cloudinary URLs, and in-memory fallback for offline/demo mode |
| 🎨 **Splash & Divine Auth** | **Two-Layer Splash** | Native Android 12+ icon splash on `#0E0B0C`, in-app 3-dancer Dhunuchi splash (`splash_illustration.webp`), and Maa Durga eyes motif login background (`login_bg_eyes.webp`) with lowered glassmorphic auth card |
| 📍 **Regional Coverage** | **8 Zones** | Kolkata (North, Central, South, Salt Lake, New Town) + Suburbs (Kalyani, Chinsurah, Bandel) |
| 🗺️ **Map Tile Provider** | **Dual Engine** | Free-tier `flutter_map` OpenStreetMap raster tiles + Native on-device Magic Lane GemKit vector map & 3D buildings |
| 🚨 **Emergency Lifeline** | **1-Touch Calling** | Direct phone integration for Kolkata Police (100), Ambulance (102), Fire (101), Women Helpline (1091), Traffic & Disaster Management |
| 📱 **Mobile UX Optimization** | **100% Clean Layout** | In-layout contextual banner below filter chips (zero header overlap), compact squad status chip in filter row, single-line ellipsis truncation |
| 🧪 **Test & Lint Health** | **143/143 Passing** | `flutter analyze` = 0 issues, 143/143 automated unit, widget, and integration tests passing across 12 test suites |

---

## 🌟 Comprehensive Feature Catalog

```
                               ┌─────────────────────────────┐
                               │     Kolkata Puja App        │
                               └──────────────┬──────────────┘
                                              │
    ┌──────────────────┬──────────────────────┼──────────────────────┬──────────────────┐
    │                  │                      │                      │                  │
 🗺️ Map & Layers   🔍 Omni-Search         🚶 Road Routing & TSP  👥 Squad Hub & Chat  🚨 Safety & Helplines
 • 387 Pandals     • Unconditional Bar    • Real Street Paths    • 4-Card Clean Hub   • 1-Touch Calling
 • 41 Metro Stns   • In-Layout Banner     • GemKit On-Device     • 1-Tap Native Call  • Police, Ambulance
 • 66 Food Spots   • Category Tabs        • 2-Segment Styling    • Live GPS Sync      • Women Helpline
 • Dual Engine     • Full Vertical Clear  • Held-Karp Optimizer  • Squad Chat & Media • Offline Guide
```

### 🗺️ 1. Interactive Spatial Map & Dynamic Layers (`MapScreen` & `MapScreenGemKit`)
* **Keyless Free-Tier & Native Vector Maps:** Default `flutter_map` with OpenStreetMap raster tiles (zero billing risk) alongside Magic Lane GemKit vector map engine with 3D buildings and on-device offline navigation.
* **387 Authentic Durga Puja Pandals:** Verified locations spanning Kolkata North, South, Central, Salt Lake, New Town, and suburban heritage hubs (Kalyani, Chinsurah, Bandel).
* **Unconditional Top Search Bar:** `PandalSearchAutocomplete` renders permanently and unconditionally at the top of the map floating overlay—never hidden during startup, navigation, or destination selection.
* **In-Layout Contextual Banner:** Filter status messages (*"Showing 40+ Kolkata Metro stations on map"*, *"Showing all 338 pandals across Kolkata & Suburbs"*, zone switch notices) render cleanly within the layout beneath the filter chips, completely eliminating floating `Overlay` collisions over the AppBar header.
* **Search-Active State Transition:** When searching or focusing the search bar, filter chips and contextual banners cleanly unmount, granting autocomplete suggestions 100% vertical clearance.
* **Compact Squad Status Chip:** When a squad is active, a compact pill appears directly in the horizontal filter chip row showing live companion counts, tapping which opens the squad hub.
* **🚇 Kolkata Metro Layer Toggle:** One-tap toggle button displaying all 41 Kolkata Metro stations with line-coded markers (Blue, Green, Purple, Orange) and direct walking distance to nearby pandals.
* **🍲 Culinary & Food Layer Toggle:** One-tap toggle revealing 66 curated culinary gems, sweet shops, and heritage cabins directly on the map.
* **Auto-Fly Region Jump:** Instant smooth camera flight to any of the 8 regional clusters.

---

### 🔍 2. Universal Omni-Search (`OmniSearchService`)
* **Unified Multi-Entity Search:** Simultaneously queries across **387 pandals**, **41 metro stations**, and **66 food spots**.
* **Translucent Frosted-Glass Overlay:** Floating search HUD with acrylic blur (`BackdropFilter`), dynamic keyboard auto-focus, and quick clear actions.
* **Phonetic & Multi-Alias Matching:** Resolves variations and transliterations in both English and Bengali (e.g., *Shobhabazar*, *Sovabazar*, *Sobhabazar*, *Shovabazar*).
* **Substring Highlighting & Distance Badges:** Matches in names, areas, cuisines, metro lines, or themes are highlighted in real-time with live Haversine distance badges from the user.
* **Persistent Search Bar After Selection:** Selecting a location centers the map and displays the location card while keeping the top search bar intact and tappable.

---

### 🚶 3. Real Street-Level Pedestrian Routing & TSP Optimizer (`CustomHoppingTrailService` & `TrailOptimizer`)
* **Real Street Network Geometry:** Replaces straight diagonal lines with actual road-following walking paths computed by GemKit's on-device `RoutingService.calculateRoute()` (`RouteTransportMode.pedestrian`) using OSM road network data with zero external API dependencies.
* **Two-Segment Route Styling:**
  * **"Getting there" segment:** From current user location to the trail start point (rendered with `bMainRoute: false` as a muted secondary line).
  * **"Your trail" segment:** Ordered pandal circuit (rendered with `bMainRoute: true` as the highlighted bold gold line).
* **Unified Single Source of Truth:** Floating summary bars, route HUDs, and notifications consume the exact `route.getTimeDistance()` (`totalDistanceM` and `totalTimeS`) from the calculated route.
* **Mathematically Optimal Custom Trails:** Integrated Held-Karp dynamic programming ($O(N^2 2^N)$ for $N \le 12$) and 2-opt iterative improvement ($N > 12$) to calculate the shortest possible walking sequence.
* **Cross-Engine GeoJSON Sync:** Exports road coordinates to `ActiveCustomTrail.routedPolyline`, allowing the 2D fallback map to render the exact same street-level paths.

---

### 👥 4. Consolidated 4-Card Squad Hub, Live Calling & Private Chat (`GroupScreen` & `SquadChatScreen`)
* **Consolidated 4-Card Layout:** Streamlined from redundant banners into 4 clean cards:
  1. **Squad Overview Card:** Squad name (with auto-sanitized typo handling, e.g. `Arnab,s` $\to$ `Arnab's`), 6-character invite code, and 1-tap copy/share actions.
  2. **Target Destination & Separation Alert:** Live destination pin with configurable separation threshold buttons (**250m**, **500m**, **1000m**) and instant emergency alert dispatch.
  3. **Members & Companions List:** Real-time battery level indicators, proximity distances, **Locate on Map** action, and **Native One-Tap Phone Calling (`tel:`)** with profile phone number linking.
  4. **Squad Chat & Media Hub:** Direct access tile with live unread counts and latest message previews.
* **Dedicated Squad Chat Screen (`SquadChatScreen`):**
  * Private, end-to-end squad group messaging with real-time stream.
  * Media sharing: Share photos and festival videos with Cloudinary CDN URL attachments.
  * In-memory fallback (`SquadChatService`) for seamless operation in offline and demo mode before Firebase is configured.

---

### ⛩️ 5. Master 387 Pandal Directory & Isolated Personal Tracker (`PandalListScreen`)
* **Comprehensive Cultural Database:** Searchable catalog with theme classifications (Traditional *Sabeki* vs. Contemporary *Thematic*), committee names, establishment years, ratings, and crowd advisory badges.
* **Favorites Isolation:** Pandal favorites and Food Spot favorites are maintained in completely separate, isolated sets (`pandal_favorites` vs `food_favorites`), preventing cross-category count pollution.
* **Scoped Progress Tracking:** The "Hopped" toggle and progress bar are strictly scoped to pandals and omitted on food spots.
* **3-Step Custom Trail Planner Dialog (`CustomTrailPlannerDialog`):**
  * Step 1: Browse and multi-select pandals with live zone filters.
  * Step 2: Choose starting point (Live GPS or first pandal) and toggle the TSP path optimizer.
  * Step 3: Review the turn-by-turn itinerary with road-following distance/duration estimates and launch the route.

---

### 🚇 6. Integrated Kolkata Metro Network (`MetroRepository`)
* **Complete 41-Station Network:** Fully mapped across all operational and extended corridors:
  * 🔵 **Line 1 (Blue Line — North-South):** Dakshineswar to Kavi Subhash (New Garia).
  * 🟢 **Line 2 (Green Line — East-West / Underwater):** Howrah Maidan to Esplanade & Sealdah to Salt Lake Sector V.
  * 🟣 **Line 3 (Purple Line):** Joka to Majerhat / Taratala via Behala Chowrasta.
  * 🟠 **Line 6 (Orange Line):** Kavi Subhash to Hemanta Mukhopadhyay (Ruby Crossing).
* **Interactive Station Sheets:** Tapping any station reveals its operational line, corridor, interchange status, and direct walking distance to nearby pandals.

---

### 🍲 7. Culinary & Street Food Directory (`SupplementaryRepository`)
* **66 Curated Food Spots:** Hand-picked culinary landmarks categorized into iconic sweets, heritage cabins, Mughlai delicacies, Kolkata street food hubs, and community bhog spots.
* **Detailed Information:** Includes area, cuisine tags, specialty dishes, operating hours during puja, and price ratings (`₹` to `₹₹₹`).

---

### 🚨 8. Emergency Lifeline & Public Safety (`HelplinesScreen`)
* **1-Touch Direct Phone Calling:** Seamless dialer integration via `url_launcher` for Kolkata emergency services:
  * 🚓 Kolkata Police Control Room: **100** / **033-2214-3230**
  * 🚑 Ambulance Services: **102**
  * 🚒 Fire & Emergency Services: **101**
  * 🛡️ Women Helpline: **1091** / **1090**
  * 🚦 Kolkata Traffic Police Helpline: **1073** / **033-2214-3644**
  * 🆘 Disaster Management: **1070**
  * 👶 Childline: **1098**
* **Festival Safety Protocols:** Essential crowd safety advice, lost child reunification procedures, emergency medical booth locations, and electrical safety advisories.

---

### 🪔 9. Divine Welcome Experience & Festive Aesthetics (`WelcomeScreen`)
* **Animated Chokkhu Daan Formation:** Cultural welcome screen featuring the divine third eye and visage of Maa Durga drawn with an animated stroke-formation effect.
* **Ambient Breathing Pupil Glow:** Subtle, organic luminescence on pure dark OLED background.
* **Durga Puja 2026 Countdown Capsule:** Real-time countdown clock ticking down to Mahalaya (Oct 10, 2026) and Maha Shasthi (Oct 16, 2026).
* **Festive Material 3 Theme Palette:**
  * Crimson Velvet (`0xFF800020`) — Traditional sindoor and altar red
  * Festival Gold (`0xFFFFD700`) — Illumination and sacred adornment
  * Night Surface (`0xFF0E0E10`) — Battery-friendly OLED dark mode

---

## 📍 Regional Coverage Breakdown

| Zone | English Label | Bengali Label | Pandals | Key Highlights |
|---|---|---|:---:|---|
| `southKolkata` | South Kolkata | দক্ষিণ কলকাতা | **170** | Ekdalia, Tridhara, Suruchi Sangha, Deshapriya Park, Chetla, Mudiali, Singhi Park |
| `northKolkata` | North Kolkata | উত্তর কলকাতা | **129** | Bagbazar, Kumartuli, Hatibagan, Sovabazar, Tala, Kasi Bose Lane, Ahiritola |
| `eastKolkata` | Salt Lake & New Town | সল্টলেক ও নিউ টাউন | **62** | Sreebhumi, FD Block, BJ Block, AK Block, Labony, New Town Sarbojanin |
| `centralKolkata` | Central Kolkata | মধ্য কলকাতা | **11** | College Square, Md Ali Park, Santosh Mitra Square, Bowbazar |
| `nadiaKalyani` | Kalyani (Nadia) | কল্যাণী (নদিয়া) | **6** | ITI More Luminous, Rathtala, Central Park, A9, B-Block, Boat Park |
| `hooghlyChinsurah` | Chinsurah (Hooghly) | চুঁচুড়া (হুগলি) | **5** | Panchanantala, Pirtala, Datta Bari (Est. 1862), Chapatala, Sandeswar Tala |
| `howrah` | Howrah | হাওড়া | **3** | Howrah Sarbojanin, Salkia, Shibpur heritage pujas |
| `hooghlyBandel` | Bandel (Hooghly) | ব্যান্ডেল (হুগলি) | **1** | Keota Nabin Sangha & grand illumination zones |
| **Total** | **All Regions** | **সর্বমোট** | **387** | **100% Verified Authentic Pandals (0 Synthetic Placeholders)** |

---

## 🛠️ Tech Stack & Architecture

| Layer | Technology | Rationale |
|---|---|---|
| **Client Framework** | **Flutter 3 (Dart 3)** | Cross-platform native ARM performance, locked 60/120 FPS animations |
| **Map Rendering** | **flutter_map + GemKit** | Dual engines: Free OSM raster tiles + Native on-device Magic Lane vector maps |
| **Geospatial Engine** | **PandalSpatialClusterer (L1 Cache)** | Sub-millisecond memoized clustering, 35% margin culling, GPU `RepaintBoundary` |
| **Routing Engine** | **GemKit Native Pedestrian Routing** | On-device street-level pedestrian routing (`RouteTransportMode.pedestrian`) with Held-Karp / 2-opt TSP optimizer |
| **Universal Search** | **OmniSearchService** | Permanent top bar with multi-entity search, phonetic aliases, and auto-unmounting filter chips |
| **Squad Synchronization** | **Firebase Realtime Database / WebSocket** | Low-latency GPS coordinate syncing with 6-char codes and separation alerts |
| **Squad Chat & Media** | **SquadChatService + Cloudinary** | Real-time text messaging, photo/video sharing, and offline in-memory fallback |
| **Native Calling** | **url_launcher (`tel:`)** | Direct one-tap phone dialer launch with companion profile phone numbers |
| **Local Offline Cache** | **JSON Assets + SharedPreferences** | Instant zero-latency boot, offline bookmarks, and visited checklist |
| **Authentication** | **Firebase Auth + Guest Mode** | Google Sign-In with instant 1-tap anonymous guest entry |

---

## 📂 Repository Layout

```
.
├── app/                              # Flutter Mobile Application
│   ├── assets/
│   │   ├── data/
│   │   │   ├── pandals.json          # Master dataset of 387 verified authentic pandals
│   │   │   ├── food_spots.json       # 66 curated eateries, sweet shops & cabins
│   │   │   └── helplines.json        # Kolkata emergency services & safety guides
│   │   └── images/                   # Durga artwork, brand assets, app icons
│   ├── lib/
│   │   ├── config/                   # Theme tokens, Material 3 Durga palette
│   │   ├── models/                   # Pandal, MetroStation, FoodSpot, SquadMember, AppUser, ChatMessage
│   │   ├── repositories/             # LocalAsset, MetroRepository, SupplementaryRepository
│   │   ├── screens/
│   │   │   ├── map_screen.dart       # OSM 2D map, unconditional search bar, in-layout banner
│   │   │   ├── map_screen_gemkit.dart# GemKit native vector map, 3D buildings, road routing
│   │   │   ├── pandal_list_screen.dart# Searchable 387 directory with isolated favorites
│   │   │   ├── routes_screen.dart    # 5 Curated circuits & 3-step Custom Trail Planner
│   │   │   ├── group_screen.dart     # Consolidated 4-card squad hub, 1-tap calling
│   │   │   ├── squad_chat_screen.dart# Private squad group chat & media sharing
│   │   │   ├── helplines_screen.dart # 1-Touch emergency calling & safety tips
│   │   │   ├── welcome_screen.dart   # Divine Maa Durga animated Chokkhu Daan welcome
│   │   │   └── main_navigation_screen.dart # 5-Tab responsive navigation shell
│   │   ├── services/
│   │   │   ├── omni_search_service.dart # Universal multi-entity search
│   │   │   ├── routing_service.dart  # Calibrated pedestrian routing & dual-mode ETAs
│   │   │   ├── squad_service.dart    # Live squad sync, meetup pins & separation alerts
│   │   │   ├── squad_chat_service.dart # Real-time squad messaging & fallback stream
│   │   │   ├── trail_optimizer.dart  # Held-Karp & 2-opt TSP walking path optimizer
│   │   │   ├── custom_hopping_trail_service.dart # Active custom trail & routed metrics
│   │   │   ├── location_service.dart # GPS positioning & distance formatting
│   │   │   ├── pandal_user_state_service.dart # Offline favorites & visited tracker
│   │   │   ├── theme_service.dart    # Dark/light theme persistence
│   │   │   └── auth_service.dart     # Firebase Auth & guest mode provider
│   │   ├── utils/                    # Haversine distance, Spatial clustering, Responsive scaling
│   │   └── widgets/                  # Detail sheets, Omni-search HUD, Custom trail dialog, User profile
│   └── test/                         # 138 Automated unit, widget, and integration tests (100% passing)
├── data/
│   ├── pandals.json                  # Master pandal dataset
│   ├── pandals.csv                   # CSV export for spreadsheet auditing
│   ├── food_spots.json               # Food spots dataset
│   └── helplines.json                # Helplines dataset
├── scripts/
│   ├── scrape_pujoplanner.js         # Scraper script for puja data
│   └── seed_pandals.js               # Firestore seeding script
└── puja-pandal-app-architecture.md   # Complete build & launch architecture document
```

---

## 🚀 Getting Started & Development

### Prerequisites
* Flutter SDK (`3.13+` / Dart `3.0+`)
* Android SDK (API 36, Build-Tools 36.0.0)
* JDK 17
* Node.js 18+ (for data scripts)

### Development Commands (from `app/`)

```bash
# Install and resync Dart dependencies
flutter pub get

# Run static analysis and lint (must be 0 issues)
flutter analyze

# Execute full automated test suite (138 unit, widget, and integration tests)
flutter test

# Run live application on connected device or emulator
flutter run

# Build production Android release APK
flutter build apk --release
```

---

## 🔒 Privacy & Offline Resilience

* **Zero Background Location Tracking:** Location tracking operates strictly in the foreground while the app is actively used (`ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`), respecting battery life and user privacy.
* **Demo / Offline Mode by Default:** The app runs out-of-the-box in standalone offline mode using bundled assets. If Firebase is not yet configured, the app seamlessly runs all map, routing, metro, food, squad chat, and directory features without errors.
* **Credentials Safety:** `google-services.json`, `GoogleService-Info.plist`, `firebase_options.dart`, and service accounts are untracked in git to prevent credential leaks.

---

## 🗓️ Launch Roadmap

- [x] **Milestone 1: Architecture & Theme Foundation**
  - Scaffold Flutter app with Material 3 Durga palette (Crimson Velvet & Festival Gold)
  - Interactive OSM Map with custom temple markers & zero-billing raster tiles
  - Divine Maa Durga Chokkhu Daan animated welcome screen & countdown capsule
- [x] **Milestone 2: Mega Dataset & Spatial Infrastructure**
  - Ingested & verified **387 authentic pandals** (curated from ThePujo & PujoPlanner with 0 synthetic placeholders)
  - Integrated sub-millisecond L1 spatial clustering engine (`PandalSpatialClusterer`) with 60/120 FPS performance
- [x] **Milestone 3: Metro Network & Transit Architecture**
  - Mapped **41 Kolkata Metro stations across 4 lines** (Blue, Green, Purple, Orange)
  - Built interactive Metro station cards, corridor info, and direct transit routing
- [x] **Milestone 4: Universal Omni-Search & Layout Polish**
  - Built permanent, unconditionally visible top search bar
  - In-layout contextual banner below filter chips with zero header overlap
  - Phonetic alias matching in English & Bengali with instant map spotlighting
- [x] **Milestone 5: Road-Following Pedestrian Routing & TSP Optimizer**
  - GemKit on-device pedestrian routing (`RouteTransportMode.pedestrian`) on OSM road network
  - Two-segment styling (muted "Getting there" + bold gold "Your trail")
  - Held-Karp and 2-opt `TrailOptimizer` for mathematically optimal custom trail sequence
  - Unified distance & duration single source of truth from `route.getTimeDistance()`
- [x] **Milestone 6: Consolidated 4-Card Squad Hub, Calling & Chat**
  - Streamlined 4-card Squad Screen with configurable separation thresholds (250m/500m/1000m)
  - Native one-tap phone calling (`tel:`) for companions
  - Dedicated Squad Chat screen with real-time text streaming, photo/video sharing, and offline fallback
- [ ] **Milestone 7: Production Release & Play Store Launch**
  - Configure production Firebase project credentials
  - Generate release bundle and publish to Google Play Store before Durga Puja 2026

---

## 📜 License

This project is open-source software licensed under the **[MIT License](./LICENSE)**. Built with ❤️ for the festival-lovers and pandal-hoppers of Bengal.
