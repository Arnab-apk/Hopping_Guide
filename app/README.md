# Kolkata Puja 2026 — Flutter App

This directory contains the Flutter mobile client for **Kolkata Puja 2026** (*কলকাতা দুর্গাপূজা পরিক্রমা ও লাইভ স্কোয়াড কম্প্যানিয়ন*).

For the full project overview, stats dashboard, architecture, and roadmap, see the root [README.md](../README.md).

## Quick Stats

- **Curated Pandals:** 117 (Kolkata Metro + Nadia & Hooghly Suburbs)
- **Covered Zones:** 8 (North, Central, South, Salt Lake, New Town, Kalyani, Chinsurah, Bandel)
- **Map Provider:** `flutter_map` with OpenStreetMap raster tiles (100% Keyless & Free)
- **Framework:** Flutter (Dart 3)
- **Static Analysis:** 0 issues (`flutter analyze` passing)
- **Tests:** 100% passing (`flutter test`)

## Development Commands

Run all commands from this directory (`app/`):

```bash
# Install dependencies
flutter pub get

# Run static analysis and lint checks
flutter analyze

# Run unit and widget tests
flutter test

# Run the application locally
flutter run

# Build release APK
flutter build apk --release
```

See [AGENTS.md](../AGENTS.md) for canonical commands and development guidelines.
