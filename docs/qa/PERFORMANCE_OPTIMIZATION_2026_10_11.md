# Performance optimization — 11 October 2026

## Changes

- Keep the map mounted for startup/deep links, but mount other tabs only when
  first selected. Preserve visited tab state and mute hidden tabs' Flutter
  tickers. Location/navigation services continue operating independently.
- Reduce the greeting's minimum display time from 4000 ms to 800 ms and remove
  1800 ms of staged delays plus a 400 ms completion pause. Actual asset loading,
  map readiness (with the existing timeout), and permission checks still run.
- Rebuild the pandal directory for coordinate changes instead of every compass
  or location-service notification. Calculate each place's distance at most
  once per filter/sort pass and remove duplicate nearest-distance sorting.
- Coalesce concurrent identical Mapbox directions requests within a service
  instance. Driving, walking, coordinate order, and coordinates remain distinct.
  Completed/failed requests are removed so refreshes and retries stay fresh.
- Build per-ABI APKs instead of installing all three CPU architectures on a phone.

## Verification

- Complete suite with Mapbox live verification enabled: **438 passed**, no skips.
  Log: `app/build/optimization_full_tests.log`.
- After replacing deprecated test API calls, all four startup/tab tests passed
  again: `app/build/optimization_tab_final_tests.log`.
- Dart analysis of `lib` and `test`: no issues. Log:
  `app/build/optimization_analyze.log`.
- Verified APK signature and installed ARM64 release on Motorola Edge50 using
  `adb install -r`, retaining app data. Android version: **1.0.0 (4017)**.
- APK bytes: universal **333,882,689** → ARM64 **128,177,910**, a **61.6%**
  reduction (318.4 → 122.2 MiB). This is download-file size, not measured RAM use.
- One `adb am start -W -S` sample each: old build 1127 ms, new build 884 ms.
  These measure Android activity launch, not complete map readiness, and are
  insufficient to establish a repeatable startup-speed percentage.
- App launched successfully and device tab switching was exercised. No sustained
  frame-rate, battery-drain, or production network-usage benchmark was performed.

## Repeatable release command

From `app/`:

```powershell
flutter build apk --release --split-per-abi --dart-define-from-file=.env.mapbox.json --build-number=2017
```

Use an increasing build number for subsequent releases. Flutter applies ABI
version offsets: this build's ARM64 APK reports **4017**. Keep using the same
split release scheme; a universal APK with version code 2018 would be older than
the installed ARM64 build. Choose the APK matching the target device's ABI.
