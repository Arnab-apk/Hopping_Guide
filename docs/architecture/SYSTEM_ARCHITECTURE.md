# Kolkata Puja Pandal-Hopping App — Architecture & Build Plan

**Goal:** Ship a Play Store MVP before Durga Puja 2026 (Mahalaya: Oct 10, main days Oct 16–21), open source the repo.
**Today:** Sep 12, 2026 → ~5 weeks to launch.
**Team:** 2–3 people. **Budget:** $0 (free tiers only).

---

## 1. Feature Scope (prioritized — be ruthless about this)

Trying to ship everything Sharodiya has (map + nearest-pandal + routing + groups + live location + metro/toilet layers) in 5 weeks with 2–3 people is not realistic alongside classes. Cut to this:

### P0 — Launch blockers
- Interactive map of Kolkata with pandal markers (curated dataset)
- Pandal detail screen: name, area, theme, timings, photo, description
- "Nearest pandals to me" — sorted by distance from device GPS
- Filter/browse by zone (North / South / Central Kolkata, Salt Lake, New Town)
- Auth (Google Sign-In)
- Create/join a group (shareable code or deep link)
- Live location sharing inside a group + seeing group members' pins on the map

### P1 — Stretch, only if Week 3 finishes early
- Walking directions between two pandals
- Curated pandal-hopping trails (e.g. "South Kolkata Bonedi Bari trail") — real users of the original app asked for exactly this in their reviews, so it's validated demand
- Static "nearest metro station" info per pandal (fixed data, no live API needed)
- Push notifications (FCM) for group activity

### P2 — Post-launch / v2
- Public toilet layer with usability/cleanliness notes (also directly requested in Sharodiya's reviews)
- In-app group chat
- Offline map caching
- User-submitted photos/reviews
- iOS build (Flutter makes this cheap later — mostly App Store account + signing)

---

## 2. Tech Stack

| Layer | Choice | Why |
|---|---|---|
| Mobile framework | **Flutter (Dart)** | One codebase for a 2–3 person team, strong maps + geolocation + Firebase plugin ecosystem, compiles native, best long-term fit for an OSS project |
| Map rendering | **flutter_map** (OSM raster tiles) or **maplibre_gl** (vector tiles via a free tier like MapTiler) | Free, no API key, no billing account, no risk of a leaked key in the public repo. Google Maps' free tier is now capped (~10K req/mo per SKU, billing required) — wrong fit for a student OSS project |
| Auth | **Firebase Authentication** — Google Sign-In (+ email/password as fallback) | Free, unlimited on Spark plan. Skip phone/OTP auth for MVP — SMS verification isn't free even on the free plan |
| Live location + presence | **Firebase Realtime Database** | Purpose-built for this exact case (low-latency sync, `onDisconnect` presence). Spark free tier: 1GB storage, 10GB/month download, 100 concurrent connections — plenty for a launch-scale audience |
| Structured data (pandals, groups, users, trails) | **Cloud Firestore** | Free tier: 50K reads / 20K writes / 20K deletes per day. Good querying for zone filters |
| Push notifications | **Firebase Cloud Messaging** | Free, unlimited |
| Images (pandal photos) | **Cloudinary free tier**, or images bundled from a public GitHub folder via jsDelivr CDN | **Not Firebase Storage** — since Feb 2026, new Storage buckets require the paid Blaze plan even for free-tier usage |
| Routing between pandals (P1) | **OpenRouteService free tier** (2,000 req/day, no billing card) | Since your pandal list is small and mostly static, pre-compute the common routes once during data prep and only hit the live API for real-time "route from my current spot" calls — you'll stay far under the cap |
| Background location | `geolocator` + `flutter_background_service`, with explicit Android 12+ foreground-service-type handling | This is the single most common place these apps break in production — budget real testing time for it |
| CI/CD | GitHub Actions (free for public repos) | Build + test Flutter on every push |
| License / repo hygiene | MIT or Apache-2.0, `.env`/`--dart-define` for any keys, never commit secrets | Non-negotiable for an open-source repo |

**Note on Firebase vs. open-source purity:** Firebase is proprietary, which is a minor tension with "open source it." It's still the pragmatic pick — it gets real-time location working with the least backend code, which matters when you have 5 weeks. Put your data access behind a thin repository/service layer in the app so swapping to something like Supabase (Postgres + PostGIS + Realtime, also free-tier friendly, fully OSS) later is a contained change, not a rewrite.

---

## 3. System Architecture (how the pieces talk to each other)

**Client (Flutter app)**
- Map screen: renders OSM/MapLibre tiles + pandal markers + live friend pins
- Pandal browse/detail screens: read from Firestore
- Group screen: create/join group (Firestore doc), then subscribes to that group's node in Realtime DB
- Background location service: while sharing is active, pushes `{lat, lng, timestamp}` to `RTDB: /groups/{groupId}/locations/{userId}` every ~5–10s; other members' clients listen on that same path and update pins live
- Auth state gates all of the above via Firebase Auth

**Backend (fully managed, no server you run yourself)**
- Firebase Auth → identity
- Firestore → pandals collection (seeded once from your curated dataset), groups collection, users collection, trails collection
- Realtime Database → ephemeral live-location data only (keep this separate from Firestore — it's the right tool for high-frequency writes and won't burn your Firestore write quota)
- Cloud Functions (optional, free tier covers light use) → e.g. cleaning up stale group locations, sending FCM notifications on group events

**External free services**
- OSM/MapLibre tile provider → map rendering
- OpenRouteService → walking directions (P1)
- Cloudinary → pandal images

**Data pipeline (do this instead of building a CMS)**
With 5 weeks and no dedicated backend hire, don't build an admin panel — that's scope you don't have. Curate pandals in a shared Google Sheet/CSV (name, lat/lng, zone, theme, timings, image URL), write one small script (Node or Python) that pushes it into Firestore. The app's actual value is the quality of that curated list (20–40 well-chosen major pandals + zone tagging), not a fancy CMS.

---

## 4. Team Split (2–3 people)

- **Person A — App/Map:** Flutter UI, map screen, pandal browse/search/filter/detail, nearest-pandal sort
- **Person B — Realtime/Backend:** Firebase setup, auth flow, groups, live-location sync, background location service (hardest, most failure-prone piece — give it a dedicated owner)
- **Person C — Data + Ship:** pandal dataset curation, Play Store listing (screenshots, description, privacy policy page), QA/testing during a real trial walk, open-source docs (README, CONTRIBUTING, LICENSE)

If it's 2 people, fold C into A and B — data curation can happen in parallel with early dev since it doesn't block coding.

---

## 5. Week-by-Week Plan

**Week 1 (Sep 12–19) — Foundation**
Repo + Firebase project + Flutter skeleton. Map renders with hardcoded OSM tiles and a few test markers. Finalize the pandal data schema. Start curating the pandal list in parallel.

**Week 2 (Sep 19–26) — Core browsing**
Pandal list/detail screens wired to Firestore. Nearest-pandal sort using device GPS + haversine (no API needed — it's your own dataset). Zone filter/search. Google Sign-In auth flow.

**Week 3 (Sep 26–Oct 3) — Groups + live location**
Create/join group. Realtime DB location sync. Background location service with proper Android permission handling. Friend pins rendering on the map.

**Week 4 (Oct 3–10) — Polish + stretch**
P1 features if time allows (routing, curated trails). Closed testing via Play Console's internal testing track — do an actual trial walk with friends sharing location.

**Week 5 (Oct 10–16) — Ship**
Bug fixes from testing. Play Store listing assets, hosted privacy policy (GitHub Pages works fine, free). Submit for review (allow 2–3 days). Open-source the repo: README, CONTRIBUTING, LICENSE.

**Target:** live and stable before Shashthi (Oct 16), tested before Mahalaya (Oct 10) for buffer.

---

## 6. Play Store Specifics to Plan For

- **Data Safety form:** since you're collecting and sharing location between users, fill this out honestly — Google checks it against actual app behavior
- **In-app consent screen:** show explicit consent before a user's location is first shared with a group — standard requirement for location-sharing apps, and good practice regardless
- **Background location review:** if you request `ACCESS_BACKGROUND_LOCATION` (always-on sharing, even app closed), Google requires a manual justification form during review — budget a few extra days. A simpler MVP-safe alternative: **foreground-only** sharing (active while the app/foreground-service notification is up), which is enough for pandal-hopping since people have their phones out anyway, and avoids that review friction entirely
- **Privacy policy URL:** required for any app requesting location — host a simple one on GitHub Pages, free

---

## 7. Cost Check

At realistic launch-week traffic (low thousands of users), this entire stack should run at **$0**: Flutter is free, OSM/MapLibre tiles are free and keyless, Firebase Spark has hard caps (not overage billing) so no surprise bill, OpenRouteService free tier is free, GitHub + Actions are free for public repos, Cloudinary's free tier covers a curated image set. The only realistic future cost trigger is scaling well past thousands of concurrent Realtime DB connections or 50K Firestore reads/day — a good problem to have, and solvable later if Sharodiya-level traction actually happens.
