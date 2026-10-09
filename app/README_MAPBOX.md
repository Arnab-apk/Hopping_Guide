# Mapbox walking navigation

The application uses the Mapbox Directions v5 `mapbox/walking` profile for
street geometry, pedestrian duration and turn instructions. Live GPS guidance
appears below the route summary. Tap the speaker to enable voice instructions;
closing the route cancels guidance. Deviations trigger a new walking request.
Metro and railway legs keep their existing transit routes.

Set `MAPBOX_ACCESS_TOKEN` at build time. The local token file `.env.mapbox.json`
is ignored by Git; never add it to source control. Its JSON format is:

```json
{"MAPBOX_ACCESS_TOKEN": "your_public_mapbox_token"}
```

From `app/`:

```powershell
flutter run --dart-define-from-file=.env.mapbox.json
flutter build apk --release --dart-define-from-file=.env.mapbox.json
```

Directions preserve the supplied stop order. Trails over the API's 25-coordinate
limit use overlapping requests. Route geometry and instructions are cached in
memory for 15 minutes. Network failures yield clearly marked preview corridors;
live requests reject these corridors. Access denial, rate limits, malformed
responses and timeouts produce controlled errors instead of fabricated turns.

Validation:

```powershell
flutter analyze
flutter test
```

For an explicit live API check using the local token:

```powershell
flutter test test/mapbox_live_smoke_test.dart --dart-define=VERIFY_MAPBOX_LIVE=true --dart-define-from-file=.env.mapbox.json
```

The Mapbox API is verified using a real Kolkata walking request. Automated
tests cover maneuver progression, street distance, route caching, ordered long
trails, denied requests, network failures and compact-screen guidance.

API reference: https://docs.mapbox.com/api/navigation/directions/
