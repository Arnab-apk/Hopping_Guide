# Feature and optimization check — 17 October 2026

## Changes

- Separated camera movement notifications from artwork notifications. Updating
  a marker texture no longer projects every marker through the native channel.
- Skip rebuilding marker overlays when both their widgets and projected
  positions are unchanged; skip native projection calls for empty layers.
- Reuse spatial clusters within the same zoom band while the existing viewport,
  data, selection and priority checks remain valid.

These changes remove redundant work. No measured FPS or battery improvement is
claimed; device profiling would be needed to quantify those gains.

## Verification

- Full Flutter suite: **478 passed, 5 opt-in tests skipped**.
- Opt-in integration run: **5 passed**. Four exercise live Mapbox walking and
  multimodal routing. Gemini authentication/model fallback uses a mocked HTTP
  response; this does not prove a real chatbot answer is available.
- Focused map, cluster and toolbar suite: **22 passed**.
- Static analysis: **no issues**. Optimized ARM64 release installed successfully,
  preserving user data. Phone smoke checks opened map, directory (338 pandals),
  curated routes (6 circuits), the existing group, and helplines. No matching
  fatal or marker/overlay errors appeared in the sampled recent logs.
- Regression checks cover retaining pins across movement/reordering, avoiding
  reprojection on overlay updates, preserving cluster caches within a zoom band,
  and invalidating caches when bounds or grouping change.

| Feature area | Evidence and limits |
| --- | --- |
| 2D/3D map, marker interaction, controls | Native-platform adapter tests and existing phone checks; automated tests do not reproduce every GPU/gesture behavior. |
| Directory, search, photos, saved state | Automated repository, widget and resilience tests passed. |
| Trails, routing, navigation, metro/train planning | Automated tests plus live routing checks passed; physical turn-by-turn travel was not exercised. |
| Groups, chat, live locations, calls | Automated service/widget tests passed; real multi-device sync and calls remain unverified. |
| Login, profile, app startup | Automated flows passed; production authentication providers were not independently exercised. |
| Helplines | UI tests passed; no emergency telephone calls were placed. |
| Offline behavior | Fallback and offline UI tests passed; complete offline map coverage is not established. |
| Chatbot and push notifications | Mocked chatbot integration passed; real cloud answers and push delivery remain unverified. |

The app's Feature status dialog still describes offline map coverage and some
cloud-dependent features as limited. Passing tests does not certify that every
production integration or device-specific behavior is working.

Test logs are under `app/build/feature-audit-tests.txt`,
`app/build/feature-audit-live.txt`, and `app/build/map-optimization-tests.txt`.

Installed APK SHA-256:
`B18AA03B304231BAF5AB140CFEAB3F94B92DEF062D5534C9C157843FCB65D404`.
