# UMA v1.0.0 â€” October 16 update

Updated Android packages for the existing v1.0.0 release.

- Pandal cover photos and galleries with source attribution.
- **Routes > Get home**: save a home station, choose an operating date, and
  set a connection boarding buffer.
- Smoother self and squad location markers, with immediate corrections after
  stale updates or large location changes and support for reduced motion.
- Faster pandal search through cached normalization and reduced list animation.
- Existing festival interface retained.

The return-home timetable has no verified departures yet. Routes are estimates;
the app does not claim a verified last train or leave-by time.
See [return-home planner details](../features/RETURN_HOME_PLANNER.md).

## Downloads

- `UMA-v1.0.0-arm64-v8a.apk`: most modern Android phones.
- `UMA-v1.0.0-armeabi-v7a.apk`: older 32-bit ARM phones.
- `UMA-v1.0.0-x86_64.apk`: compatible emulators and x86 Android devices.
- `SHA256SUMS.txt`: SHA-256 checksums for the three updated APKs.

Version: `1.0.0+2022`. APKs use the existing release signing identity.
The iOS package on this release is unchanged and does not include this update.

Validation: Flutter analysis reports no issues; 466 tests pass with five skipped.

Updated Android build source: https://github.com/Arnab-apk/Hopping_Guide/commit/7c25e16133882178d5dcb71ffe62790c2a4532ce

The existing v1.0.0 source archives retain the original release tag; use the linked commit for this Android update.

