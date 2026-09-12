# AGENTS.md — canonical commands for this workspace

Flutter app lives in `app/`. Run all Flutter commands from there unless noted.

## Environment

- Flutter SDK: `D:\src\flutter` (bin on PATH)
- Android SDK: `D:\src\android-sdk` (ANDROID_HOME set, platform android-36, build-tools 36.0.0)
- JDK 17 (JAVA_HOME set)
- Firebase CLI (npm global): `firebase`

## Development commands

```bash
# from app/
flutter pub get          # install/resync Dart dependencies
flutter analyze          # static analysis + lint (run before commits)
flutter test             # run tests
flutter run              # run on connected device/emulator
flutter build apk --release   # release Android build
```

## Data seeding (from scripts/)

```bash
cd scripts
npm install
npm run seed:dry         # preview parsed CSV (no writes)
npm run seed             # write pandals into Firestore (needs FIREBASE_PROJECT_ID)
```

## Environment variables

- `ORS_API_KEY` — passed via `--dart-define=ORS_API_KEY=...` (P1 routing)
- Firebase project id: `FIREBASE_PROJECT_ID` (seed script only)

## Notes

- Firebase is NOT yet configured. Until `flutterfire configure` is run, the app
  runs in demo mode (map only). See README "Firebase setup".
- Do NOT commit `google-services.json`, `GoogleService-Info.plist`,
  service-account JSONs, or `.env`.
- Foreground-only location sharing (no `ACCESS_BACKGROUND_LOCATION`) to avoid
  the Play Store background-location review — see architecture doc section 6.
