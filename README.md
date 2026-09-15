<div align="center">

# 🪔 Kolkata Puja 2026
### *কলকাতা দুর্গাপূজা পরিক্রমা ও লাইভ স্কোয়াড কম্প্যানিয়ন*

**The Ultimate Community Durga Puja Pandal-Hopping, Metro Transit & Live Squad Companion**  
*Keyless Free-Tier OSM Map · 387 Verified Pandals · 41 Kolkata Metro Stations · 66 Curated Food Spots · 8 Regional Circuits · Universal Omni-Search · Calibrated Pedestrian & Dual-Mode Transit ETAs · Live Squad Tracking · Emergency Helplines*

---

[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg?style=for-the-badge)](./LICENSE)
[![Tests](https://img.shields.io/badge/Tests-Passing%20(57%2F57)-success?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com)
[![Analysis](https://img.shields.io/badge/Analysis-0%20Issues-brightgreen?style=for-the-badge&logo=dart&logoColor=white)](https://github.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Web-orange?style=for-the-badge&logo=android&logoColor=white)](https://github.com)

<br/>

> **Target:** Launch on Google Play Store before Durga Puja 2026 (Mahalaya: Oct 10, 2026; Maha Shasthi: Oct 16, 2026).  
> **Philosophy:** 100% Free Tiers ($0 Infra Cost), Keyless OpenStreetMap Raster Tiles, Zero Vendor Lock-in, Privacy-First, Open-Source.

</div>

---

## 📊 Live Project Stats Dashboard

| Metric | Status | Details |
|---|:---:|---|
| 🛕 **Curated Pandals** | **387 Verified Pandals** | Authentic de-duplicated database scraped directly from ThePujo.com & PujoPlanner spanning all zones with coordinates, themes, timings, ratings, and nearest metro links |
| ⚡ **Rendering Engine** | **60/120 FPS Locked** | Sub-millisecond L1 spatial clustering cache, directional 35% margin culling, GPU `RepaintBoundary` isolation, zero-jank multi-touch gesture race |
| 🚇 **Kolkata Metro Network** | **41 Stations (4 Lines)** | Blue (North-South), Green (East-West / Underwater), Purple (Joka-Majerhat), and Orange (Ruby) lines |
| 🍲 **Curated Food & Cabins** | **66 Food Spots** | Legendary sweet shops, heritage cabins, Mughlai eateries, street food hubs, and community bhog spots |
| 🔍 **Universal Omni-Search** | **Arch/Rofi Style** | Translucent frosted-glass HUD searching across Pandals, Metro, and Food simultaneously with instant keyboard navigation |
| 🚶 **Pedestrian & Transit Routing** | **Calibrated ETAs** | Human walking speed (4.5 km/h, 1.25× circuity), dual-mode transit ETAs for distances > 3.5 km, OSRM foot corridors, offline geodesic fallback |
| 📍 **Regional Coverage** | **8 Zones** | Kolkata (North, Central, South, Salt Lake, New Town) + Suburbs (Kalyani, Chinsurah, Bandel) |
| 🗺️ **Map Tile Provider** | **OpenStreetMap** | Raster tiles via `flutter_map` — 100% keyless, free, zero billing risk, no API quota limits |
| 👥 **Live Squad Tracking** | **Realtime GPS** | Ephemeral GPS sync via Firebase Realtime Database with 6-digit invite codes, avatars, meetup pins, and lost member alerts |
| 🚶 **Curated Circuits & Planner** | **5 Trails + Custom** | North Heritage, South Classics, South-West Themes, Bonedi Bari, Salt Lake Marvels + Custom Interactive Trail Builder |
| 🚨 **Emergency Lifeline** | **1-Touch Calling** | Direct phone integration for Kolkata Police (100), Ambulance (102), Fire (101), Women Helpline (1091), Traffic & Disaster Management |
| 📱 **Mobile UX Optimization** | **100% Responsive** | Pinned region selector, non-clipping frosted pills, dual-thumb navigation FABs, non-intrusive floating status pill |
| 🧪 **Test & Lint Health** | **100% Clean Suite** | `flutter analyze` = 0 issues, 57/57 automated unit and widget tests passing |

---

## 🌟 Comprehensive Feature Catalog

```
                               ┌─────────────────────────────┐
                               │     Kolkata Puja App        │
                               └──────────────┬──────────────┘
                                              │
    ┌──────────────────┬──────────────────────┼──────────────────────┬──────────────────┐
    │                  │                      │                      │                  │
 🗺️ Map & Layers   🔍 Omni-Search         🚶 Routing & Trails    👥 Squad Tracking   🚨 Safety & Helplines
 • 387 Pandals     • Arch/Rofi HUD        • 4.5 km/h Walking     • Ephemeral Sync    • 1-Touch Calling
 • 41 Metro Stns   • Category Tabs        • Dual-Mode ETAs       • Meetup Landmark   • Police, Hospital
 • 66 Food Spots   • Live Highlighting    • 5 Curated Circuits   • Distance Alerts   • Safety Protocols
 • Spatial LOD     • Distance Badges      • Custom Trail Builder • Companion Pins    • Offline Emergency
```

### 🗺️ 1. Interactive Spatial Map & Dynamic Layers (`MapScreen`)
* **Keyless & Zero Billing Risk:** Powered by `flutter_map` and OpenStreetMap raster tiles. Completely eliminates expensive Google Maps SDK fees and API key leak risks.
* **387 Authentic Durga Puja Pandals:** Verified locations spanning Kolkata North, South, Central, Salt Lake, New Town, and suburban heritage hubs (Kalyani, Chinsurah, Bandel).
* **Spatial Clustering & Level-of-Detail (LOD):** Smoothly clusters pandals based on camera zoom levels, preventing UI lag and marker clutter while maintaining high responsiveness.
* **🚇 Kolkata Metro Layer Toggle (`_buildMetroToggleChip`):** One-tap toggle button displaying all 41 Kolkata Metro stations with line-coded markers (Blue, Green, Purple, Orange). Tapping any station reveals its corridor, interchange status, and nearby popular pandals.
* **🍲 Culinary & Food Layer Toggle (`_buildFoodToggleChip`):** One-tap toggle revealing 66 curated culinary gems, sweet shops, and heritage cabins directly on the map.
* **Auto-Fly Region Jump:** Instant smooth camera flight to any of the 8 regional clusters (e.g., jump 45 km north to Kalyani or 35 km to Chinsurah in 1 tap).
* **Non-Intrusive Floating Status Pill:** Replaces disruptive modal banners with a sleek, self-dismissing frosted glass pill for connectivity and location status.
* **Dual-Thumb Ergonomics:** Stacked floating action buttons for instant GPS recentering, region selection, and custom trail management.

---

### 🔍 2. Arch Linux / Omachi Style Universal Omni-Search (`OmniSearchService`)
* **Unified System Search:** Inspired by Rofi, Spotlight, and Arch Linux Omachi. Simultaneously queries across **387 pandals**, **41 metro stations**, and **66 food spots**.
* **Translucent Frosted-Glass Overlay:** Floating search HUD with acrylic blur (`BackdropFilter`), dynamic keyboard auto-focus, and quick clear actions.
* **Multi-Category Filter Chips:** Instant switching between `All`, `Pandals`, `Metro`, and `Food` tabs.
* **Phonetic & Multi-Alias Matching:** Resolves variations and transliterations in both English and Bengali (e.g., *Shobhabazar*, *Sovabazar*, *Sobhabazar*, *Shovabazar*).
* **Substring Highlighting & Distance Badges:** Matches in names, areas, cuisines, metro lines, or themes are highlighted in real-time with live Haversine distance badges from the user.
* **One-Tap Map Focus & Spotlight:** Tapping any search result smoothly flies the map camera to the target, triggers a pulsating beacon glow, and opens the preview card.

---

### 🚶 3. Calibrated Pedestrian Routing & Dual-Mode Transit ETAs (`RoutingService`)
* **Calibrated Human Walking Pace:** Calculated using realistic human pedestrian speed (4.5 km/h = 1.25 m/s) with a 1.25× urban street circuity factor, replacing unrealistic straight-line driving speeds.
* **Dual-Mode Transit ETAs:** For destinations farther than 3.5 km, displays both vehicular/transit travel time and walking time (e.g., `43.4 km · 46 mins drive/transit · 9h 39m walk`).
* **Real Street Walking Corridors:** Fetches actual footpaths and pedestrian street geometry via the OSRM foot engine.
* **100% Offline Geodesic Fallback:** If internet connectivity drops amidst festival crowds or underground metro corridors, automatically calculates geodesic routing without interrupting navigation.
* **Central Kolkata Esplanade Fallback:** When device GPS permissions are denied or unavailable, gracefully anchors routing to Kolkata's geographical transit center (Esplanade: `22.5645, 88.3516`).
* **Active Route HUD:** Displays destination title, distance badge, calibrated ETA, zoom-to-fit action, and a quick `✕ Clear Path` button.

---

### 🚇 4. Integrated Kolkata Metro Network (`MetroRepository`)
* **Complete 41-Station Network:** Fully mapped across all operational and extended corridors:
  * 🔵 **Line 1 (Blue Line — North-South):** Dakshineswar to Kavi Subhash (New Garia) via Dum Dum, Shyambazar, Sovabazar, MG Road, Central, Esplanade, Park Street, Kalighat, and Tollygunge.
  * 🟢 **Line 2 (Green Line — East-West / Underwater):** Howrah Maidan to Esplanade (under the Hooghly River) & Sealdah to Salt Lake Sector V via Karunamoyee and Central Park.
  * 🟣 **Line 3 (Purple Line):** Joka to Majerhat / Taratala via Behala Chowrasta.
  * 🟠 **Line 6 (Orange Line):** Kavi Subhash to Hemanta Mukhopadhyay (Ruby Crossing).
* **Interactive Station Sheets:** Tapping any station reveals its operational line, corridor, interchange status, and direct walking distance to nearby high-profile pandals.
* **Direct Metro Routing:** Single-tap "Route to Station" button calculates pedestrian paths from the user's live coordinates to the nearest metro gate.

---

### 🍲 5. Culinary & Street Food Directory (`SupplementaryRepository`)
* **66 Curated Food Spots:** Hand-picked culinary landmarks categorized into iconic sweets, heritage cabins, Mughlai delicacies, Kolkata street food hubs, and community bhog spots.
* **Detailed Information:** Includes area, cuisine tags, specialty dishes, operating hours during puja, and price ratings (`₹` to `₹₹₹`).
* **Direct Map Navigation:** Tap any eatery in the directory to fly to its pin on the map or calculate an in-app walking route.

---

### ⛩️ 6. Master 387 Verified Pandal Directory & Personal Tracker (`PandalListScreen`)
* **Comprehensive Cultural Database:** Searchable catalog with theme classifications (Traditional *Sabeki* vs. Contemporary *Thematic*), committee names, establishment years, ratings, and crowd advisory badges.
* **Multi-Criteria Sorting & Filtering:**
  * Filter tabs: `All`, `Favorites`, `Visited`, and `Nearest`.
  * Sorting: `Default`, `Nearest First (GPS)`, `Rating: High to Low`, and `Low Crowd First`.
  * Zone filtering: Quick chips for North, Central, South, Salt Lake, New Town, Kalyani, Chinsurah, and Bandel.
* **Offline Personal Tracker (`PandalUserStateService`):**
  * ❤️ **Favorite Bookmarks:** Save must-visit pandals to a personal wishlist.
  * ✅ **Visited / Hopped Checklist:** Mark completed pandals to track parikrama progress across the 5 days of Durga Puja.
  * Local persistence via `SharedPreferences` ensures all bookmarks work offline without requiring an account.
* **Minimalist Pandal Detail Sheet (`PandalDetailSheet`):**
  * Consolidated transit card with nearest metro station, suburban railway link, and bus stops.
  * Tap-to-copy latitude and longitude coordinates.
  * One-touch social invite sharing via WhatsApp and messaging apps.

---

### 🚶 7. Curated Heritage Circuits & Custom Trail Planner (`RoutesScreen`)
* **5 Curated Hopping Circuits:**
  1. 🔴 **North Kolkata Heritage Walk (4.8 km):** Bagbazar Sarbojanin, Kumartuli Park, Ahiritola, Hatibagan, Kasi Bose Lane, Nabin Pally.
  2. 🟡 **South Kolkata Grand Circuit (5.8 km):** Ekdalia Evergreen, Ballygunge Cultural, Singhi Park, Maddox Square, Deshapriya Park, Tridhara Sammilani.
  3. 🔵 **South-West Thematic Wonder Trail (4.9 km):** Suruchi Sangha, Chetla Agrani, Mudiali Club, Shib Mandir, Badamtala Ashar Sangha, Behala Natun Dal.
  4. 🟣 **Zamindar & Bonedi Bari Trail (3.6 km):** Sovabazar Rajbari (Est. 1757), Chatu Babu Latu Babu, Shimla Street, College Square, Santosh Mitra Square.
  5. 🟠 **Salt Lake & VIP Road Modern Marvels (6.4 km):** Sreebhumi Sporting Club, FD Block, BJ Block, AK Block, Labony Estate.
* **Interactive Custom Trail Builder (`CustomTrailPlannerDialog`):**
  * Select custom pandals from the verified 387 database.
  * Drag-and-drop to reorder hopping sequence.
  * Real-time progress tracking (e.g., `2 / 5 Pandals Hopped`).
  * "Start Trail" action plots polyline corridors across the entire circuit on the map.

---

### 👥 8. Live Hopping Squad & Ephemeral GPS Sync (`SquadService` & `GroupScreen`)
* **Low-Latency Group Synchronization:** Powered by Firebase Realtime Database for friend and family hopping squads.
* **6-Digit Invite Codes:** Create or join squads instantly without complicated setup or account friction.
* **Designated Meetup Landmark:** Squad leaders can set a central rendezvous point (e.g., *"Near Hatibagan Crossing"*), rendered with a distinct meet-up flag marker on the map.
* **Real-time Member Avatars & Proximity:** Displays live companion avatars on the map with real-time distance calculations.
* **Crowd Separation Alert ("Lost Companion Alert"):** Automatically alerts squad members if a companion drifts beyond safety thresholds in dense crowds.
* **Navigate to Companion:** One-tap button computes an immediate walking route to a separated friend's live coordinates.

---

### 🚨 9. Emergency Lifeline & Public Safety (`HelplinesScreen`)
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

### 🪔 10. Divine Welcome Experience & Festive Aesthetics (`WelcomeScreen`)
* **Animated Chokkhu Daan Formation:** Cultural welcome screen featuring the divine third eye and visage of Maa Durga drawn with an animated stroke-formation effect.
* **Ambient Breathing Pupil Glow:** Subtle, organic luminescence on pure dark OLED background.
* **Durga Puja 2026 Countdown Capsule:** Real-time countdown clock ticking down to Mahalaya (Oct 10, 2026) and Maha Shasthi (Oct 16, 2026).
* **Festive Material 3 Theme Palette:**
  * Crimson Velvet (`0xFF800020`) — Traditional sindoor and altar red
  * Festival Gold (`0xFFFFD700`) — Illumination and sacred adornment
  * Night Surface (`0xFF0E0E10`) — Battery-friendly OLED dark mode
* **Bilingual Cultural Typography:** Styled with Google Fonts (`Plus Jakarta Sans`, `Anek Bangla`, and `Hind Siliguri`).
* **Persistent Dark / Light Mode Toggle:** Supports automatic system theme detection and manual user override.

---

### ⚡ 11. 60/120 FPS Buttery-Smooth Geospatial Engine (`PandalSpatialClusterer`)
* **Sub-Millisecond L1 Spatial Cache:** Pre-computes and caches cluster nodes and visible pins across quantized spatial grid keys (`_CacheKey`). Micro camera pans within a buffered region return in `< 0.01 ms` with zero garbage collection overhead.
* **Directional Viewport Margin Culling:** Features an aggressive 35% bounding box pre-fetch buffer (`_kViewportMarginFactor = 0.35`). Markers are culled before rasterization, eliminating off-screen canvas draw calls.
* **GPU Layer Isolation (`RepaintBoundary`):** Dedicated GPU layer backing for both the full 41-station Kolkata Metro network and dynamic clustered pandals, completely isolating marker rasterization from base tile updates and UI bottom sheet animations.
* **Aggressive Tile Pre-fetching & Buffer Tuning:** Configured with `panBuffer: 3` and `keepBuffer: 6` with ultra-fast 140 ms tile cross-fade, totally eliminating grey tile starvation during rapid kinetic inertia swipes.
* **Zero-Jank Multi-Finger Race (`enableMultiFingerGestureRace: true`):** Resolves simultaneous multi-touch pan and pinch-to-zoom gestures natively without blocking Dart UI threads.

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
| **Map Rendering** | **flutter_map + OpenStreetMap** | Free raster tiles, 100% keyless, zero billing risks, zero vendor lock-in |
| **Map SDK (Optional)** | **Magic Lane GemKit** | *Optional premium SDK integration for offline maps, turn-by-turn navigation, 3D rendering. See `MAGIC_LANE_INTEGRATION.md` for details.* |
| **Geospatial Engine** | **PandalSpatialClusterer (L1 Cache)** | Sub-millisecond memoized clustering, 35% margin culling, GPU `RepaintBoundary` |
| **Tile Pre-fetching** | **flutter_map TileBuffers** | `panBuffer: 3`, `keepBuffer: 6` with multi-finger gesture race resolution |
| **Universal Search** | **OmniSearchService** | Unified tokenization & multi-entity substring search with Bengali aliases |
| **Routing Engine** | **OSRM Foot API + Geodesic Fallback** | Pedestrian routing at 4.5 km/h walking pace with offline distance calculations |
| **Local Offline Cache** | **JSON Assets + SharedPreferences** | Instant zero-latency boot, offline bookmarks, and visited checklist |
| **Device Geolocation** | **geolocator** | High-accuracy foreground GPS with battery-saving throttling |
| **Authentication** | **Firebase Auth + Guest Mode** | Google Sign-In with instant 1-tap anonymous guest entry |
| **Live Squad Sync** | **Firebase Realtime Database** | Ephemeral GPS coordinates sync under `/groups/{groupId}/locations` |
| **Data Ingestion** | **ThePujo + PujoPlanner Scraper** | Scrapes, parses, and normalizes authentic verified pandals and transit links |

> **📍 Magic Lane GemKit Integration (Optional Premium Feature)**  
> The app is architected to optionally support [Magic Lane's GemKit SDK](https://www.linkedin.com/company/magiclane) for enhanced mapping capabilities including offline maps, professional turn-by-turn navigation, and 3D rendering. This is a **commercial SDK** requiring licensing from Magic Lane International B.V. The app works perfectly with the free flutter_map implementation by default. For GemKit integration details, see `MAGIC_LANE_INTEGRATION.md` and `QUICK_START_GEMKIT.md`.

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
│   │   ├── models/                   # Pandal, MetroStation, FoodSpot, SquadMember, AppUser
│   │   ├── repositories/             # LocalAsset, MetroRepository, SupplementaryRepository
│   │   ├── screens/
│   │   │   ├── map_screen.dart       # Interactive OSM map, layers, beacons, routing HUD
│   │   │   ├── pandal_list_screen.dart# Searchable 387 directory with filters & sorting
│   │   │   ├── routes_screen.dart    # 5 Curated circuits & custom trail manager
│   │   │   ├── group_screen.dart     # Live squad sync, meetups, distance alerts
│   │   │   ├── helplines_screen.dart # 1-Touch emergency calling & safety tips
│   │   │   ├── welcome_screen.dart   # Divine Maa Durga animated Chokkhu Daan welcome
│   │   │   └── main_navigation_screen.dart # 5-Tab responsive navigation shell
│   │   ├── services/
│   │   │   ├── omni_search_service.dart # Arch/Rofi-style universal multi-entity search
│   │   │   ├── routing_service.dart  # Calibrated pedestrian routing & dual-mode ETAs
│   │   │   ├── squad_service.dart    # Live squad sync & meetup coordinate state
│   │   │   ├── location_service.dart # GPS positioning & distance formatting
│   │   │   ├── pandal_user_state_service.dart # Offline favorites & visited tracker
│   │   │   ├── custom_hopping_trail_service.dart # Active custom circuit state
│   │   │   ├── theme_service.dart    # Dark/light theme persistence
│   │   │   └── auth_service.dart     # Firebase Auth & guest mode provider
│   │   ├── utils/                    # Haversine distance, Spatial clustering, Responsive scaling
│   │   └── widgets/                  # Detail sheets, Omni-search HUD, Crowd badges, Pins
│   └── test/                         # 57 Automated unit and widget tests (100% passing)
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

# Execute full automated test suite (57 unit and widget tests)
flutter test

# Run live application on connected device or emulator
flutter run

# Build production Android release APK
flutter build apk --release
```

### Data Seeding & Auditing (from `scripts/`)

```bash
cd scripts
npm install

# Scrape latest pandals, food, and events from web sources
npm run scrape

# Preview parsed data without database writes
npm run seed:dry

# Write pandals into Firestore (requires FIREBASE_PROJECT_ID)
npm run seed
```

---

## 🔒 Privacy & Offline Resilience

* **Zero Background Location Tracking:** Location tracking operates strictly in the foreground while the app is actively used (`ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION`), respecting battery life and user privacy.
* **Demo / Offline Mode by Default:** The app runs out-of-the-box in standalone offline mode using bundled assets. If Firebase is not yet configured with `flutterfire configure`, the app seamlessly runs all map, routing, metro, food, and directory features without errors.
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
- [x] **Milestone 4: Arch-Style Universal Omni-Search**
  - Built frosted-glass floating HUD with multi-entity search (Pandals, Metro, Food)
  - Phonetic alias matching in English & Bengali with instant map spotlighting
- [x] **Milestone 5: Calibrated Routing & Dual-Mode Transit ETAs**
  - Human walking pace calibration (4.5 km/h, 1.25× circuity factor)
  - Dual-mode transit ETAs for long distances (> 3.5 km) with 100% offline geodesic fallback
- [x] **Milestone 6: Curated Circuits & Live Squad Tracking**
  - 5 Curated walking circuits + drag-and-drop Custom Trail Builder
  - Live squad synchronization with meetup landmark pins and separation alerts
- [ ] **Milestone 7: Production Release & Play Store Launch**
  - Configure production Firebase project credentials
  - Generate release bundle and publish to Google Play Store before Durga Puja 2026

---

## 📜 License

This project is open-source software licensed under the **[MIT License](./LICENSE)**. Built with ❤️ for the festival-lovers and pandal-hoppers of Bengal.
