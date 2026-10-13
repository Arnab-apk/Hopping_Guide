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

## Data seeding & scraping (from scripts/)

```bash
cd scripts
npm install
npm run scrape           # scrape latest pandals, food, events from pujoplanner.com
npm run seed:dry         # preview parsed data (no writes)
npm run seed             # write pandals into Firestore (needs FIREBASE_PROJECT_ID)
```

## Environment variables

- `ORS_API_KEY` — passed via `--dart-define=ORS_API_KEY=...` (P1 routing)
- Firebase project id: `FIREBASE_PROJECT_ID` (seed script only)

## Notes

- Firebase is NOT yet configured. Until `flutterfire configure` is run, the app
  runs in demo mode (map only). See README "Firebase setup".
- Do NOT commit `google-services.json`, `GoogleService-Info.plist`,
  `firebase_options.dart`, service-account JSONs, or `.env`.
- Foreground-only location sharing (no `ACCESS_BACKGROUND_LOCATION`) to avoid
  the Play Store background-location review — see architecture doc section 6.

<!-- coord:start -->
## Team coordination

This repo is set up for team coordination between agents working in shared
sessions. Follow these rules:

- Before starting non-trivial work, publish a plan with `publish_plan`.
- Keep step status current as you go, using `update_step`.
- If the injected context shows an overlap warning, coordinate before you
  edit (spec Law 3, Rev 28) — never silently duplicate the work. If it is the
  same task and you have not started, join their session: register on their
  branch, or offer `propose_work_request` — the server auto-accepts only
  when every step is provably unstarted and unassigned, so a safe join needs
  no human. If the work is related, claim only unstarted, unassigned steps
  the same way. Never take started or assigned work. Stop and ask your human
  only when your permission mode requires approval or no safe action exists.
- When you discover something non-obvious (a gotcha, a decision, a fact
  someone else would need), write it down with `remember` so the team
  keeps it.
- When something is a teammate’s job rather than yours — their area, their
  decision, a question only they can answer — hand it to them with
  `assign_work` instead of asking your human to relay a message. Use
  `list_people` to turn a name into an assignee id, put the whole brief
  in the note, and tell your human who you handed it to. Their own agent is
  told at its next prompt. This is free: no model call, no sponsor, nothing
  to pay for.
- When you hit a bug, a blocker, or something that plainly wants a different
  specialist, open it with `report_opportunity` and close it with
  `resolve_opportunity` when it is handled. Nothing reads your transcript
  looking for these, so a problem you only describe in your answer reaches
  nobody; reporting it is what lets the team's Brain offer it to whoever fits.
  Reporting is not notifying — it may reach no one — so do not tell your human
  a teammate was alerted.
<!-- coord:end -->
