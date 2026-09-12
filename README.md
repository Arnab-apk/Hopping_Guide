# Kolkata Puja Pandal-Hopping App

A community pandal-hopping companion for Durga Puja in Kolkata — interactive
map of pandals, "nearest to me", zone browsing, group creation, and live
location sharing with friends.

**Target:** Play Store MVP before Durga Puja 2026 (Mahalaya: Oct 10; main days
Oct 16–21). Open source under the MIT License.

See [`puja-pandal-app-architecture.md`](./puja-pandal-app-architecture.md) for
the full architecture, feature scope, and week-by-week plan.

## Tech stack

| Layer | Choice |
|---|---|
| Mobile | Flutter (Dart) |
| Map | flutter_map + OSM raster tiles (keyless, free) |
| Auth | Firebase Auth — Google Sign-In |
| Live location | Firebase Realtime Database |
| Structured data | Cloud Firestore |
| Push | Firebase Cloud Messaging |
| Images | Cloudinary free tier or jsDelivr CDN |
| Routing (P1) | OpenRouteService free tier |

## Repository layout

```
.
├── app/                      # Flutter project (kolkata_puja)
│   └── lib/
│       ├── config/           # theme, env config
│       ├── models/           # Pandal, Group, AppUser (+ Firestore mappers)
│       ├── services/         # auth, location, group-location sync
│       ├── repositories/     # thin data-access layer (swappable backend)
│       ├── screens/          # map, list, detail, group, auth
│       ├── utils/             # haversine, zone constants
│       └── app.dart / main.dart
├── data/
│   └── pandals.csv           # curated pandal dataset (the app's real value)
├── scripts/
│   ├── seed_pandals.js       # pushes CSV → Firestore
│   └── package.json
├── docs/                     # (add screenshots, Play Store assets here)
└── puja-pandal-app-architecture.md
```

## Setup

Flutter SDK, Android Studio + Android SDK (API 36, build-tools 36.0.0), and
JDK 17 are required. Verify with:

```bash
flutter doctor
```

Install app dependencies:

```bash
cd app
flutter pub get
```

Run the app (smoke-testable now; the map renders OSM tiles on Kolkata):

```bash
flutter run
```

## Firebase setup (required before backend features work)

1. Create a Firebase project at <https://console.firebase.google.com>.
2. Enable **Authentication → Google**, **Cloud Firestore**, **Realtime
   Database**, and **Cloud Messaging**.
3. Install the FlutterFire CLI and configure the app:

   ```bash
   dart pub global activate flutterfire_cli
   flutterfire configure --project=<your-firebase-project-id>
   ```

   This generates `app/lib/firebase_options.dart`. Then uncomment the Firebase
   init block in [`app/lib/main.dart`](app/lib/main.dart) and flip
   `kFirebaseConfigured` to `true`.
4. Seed the curated pandal list into Firestore:

   ```bash
   cd scripts
   npm install
   # authenticate via `firebase login` or set GOOGLE_APPLICATION_CREDENTIALS
   $env:FIREBASE_PROJECT_ID="<your-firebase-project-id>"   # Windows PowerShell
   npm run seed            # use `npm run seed:dry` to preview first
   ```

## Environment & secrets

Never commit secrets. Pass keys at build time with `--dart-define`:

```bash
flutter run --dart-define=ORS_API_KEY=<your_openrouteservice_key>
```

`google-services.json`, `GoogleService-Info.plist`, and service-account JSONs
are git-ignored.

## Scripts

| Command | What it does |
|---|---|
| `flutter pub get` | install Dart dependencies (run in `app/`) |
| `flutter analyze` | static analysis / lint |
| `flutter test` | run unit/widget tests |
| `flutter run` | run on a connected device/emulator |
| `flutter build apk --release` | release Android build |

> Open `AGENTS.md` for the canonical commands to run during development.

## Roadmap

- **Week 1 (Sep 12–19):** repo + Firebase + skeleton; map renders. ✓ scaffold
- **Week 2 (Sep 19–26):** list/detail wired to Firestore; nearest sort; auth.
- **Week 3 (Sep 26–Oct 3):** groups + live location + background service.
- **Week 4 (Oct 3–10):** polish + stretch (routing, trails); trial walk.
- **Week 5 (Oct 10–16):** ship to Play Store; open-source the repo.

## License

MIT — see [`LICENSE`](./LICENSE).
