# Kolkata Puja 2026 — Flutter App

This directory contains the Flutter mobile client for **Kolkata Puja 2026** (*কলকাতা দুর্গাপূজা পরিক্রমা ও লাইভ স্কোয়াড কম্প্যানিয়ন*).

For the complete project overview, stats dashboard, architecture, and roadmap, see the root [README.md](../README.md).

## Quick Stats

- **Curated Pandals:** 338 verified pandals in the bundled dataset
- **Covered Zones:** 8 (North, Central, South, Salt Lake, New Town, Kalyani, Chinsurah, Bandel)
- **Kolkata Metro Network:** 55 stations across 5 operational lines
- **Culinary Landmarks:** 66 Curated Food Spots, Sweet Shops & Heritage Cabins
- **Map Providers:** Dual mapping engines — Free-tier `flutter_map` OpenStreetMap raster tiles + Native on-device Magic Lane GemKit vector maps & routing
- **Routing Engine:** Real road-following pedestrian paths via GemKit native routing (`RouteTransportMode.pedestrian`) with Held-Karp / 2-opt TSP optimizer
- **Squad Features:** Consolidated 4-card Squad Hub, Live GPS sync, 1-tap phone calling (`tel:`), and dedicated Squad Chat with photo/video sharing
- **Framework:** Flutter (Dart 3)
- **Static Analysis:** 0 issues (`flutter analyze` clean)
- **Tests:** 433 distinct checks passed (429 regression checks and 4 live routing checks); see [launch verification](../docs/qa/TONIGHT_LAUNCH_CHECK.md).

## Development Commands

Run all commands from this directory (`app/`):

```bash
# Install dependencies
flutter pub get

# Run static analysis and lint checks (0 issues expected)
flutter analyze

# Run unit and widget tests (optional live checks need API credentials)
flutter test

# Run the application on connected device or emulator
flutter run

# Build release APK
flutter build apk --release
```

See [AGENTS.md](../AGENTS.md) for canonical commands and development guidelines.
