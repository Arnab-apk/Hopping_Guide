# UMA: Discovery, Transit, Festival Content and Public Gallery Implementation Brief

Prepared: 13 October 2026. This is an implementation specification for Codex, not a claim that the features below have already shipped.

## 1. Instructions for the implementing agent

Implement all seven feature areas in this document in the existing Flutter application, in the milestone order in section 12. Read current root `AMOEBA.md` and `AGENTS.md`, applicable nested instructions, and relevant source files before editing. Repository instructions and the user's permission mode continue to apply. This document does not authorize publishing, paid services, uploading private data, or production database changes.

Keep progress in `docs/FEATURE_IMPLEMENTATION_PROGRESS.md`: milestone, completed tasks, changed files, checks run, remaining work, and external prerequisites. Complete each milestone's local implementation and checks before proceeding. If credentials or approved content are missing, finish the interfaces, fixtures, local preview, and tests; clearly record the production prerequisite. Never represent a simulated backend, invented timetable, or sample photograph as production functionality.

Use existing Provider/ChangeNotifier state management, Material 3 themes, maps, navigation, and repository patterns. Avoid a framework migration. Preserve map state, squad invitations, bookmarks, visited IDs, custom trails, toilet directions, and emergency calling. Run Flutter commands from `app/`.

The reference website is inspiration for functionality, not a content source to copy without permission: https://www.durgapujakolkata.in/. Recheck technical package documentation and actual repository state when implementation begins.

## 2. Verified baseline and integration points

The following observations came from source inspection; runtime behavior and deployed configuration were not tested for this brief. Counts are snapshots, not requirements to hardcode.

| Existing implementation | Integration consequence |
| --- | --- |
| `app/assets/data/pandals.json`: 338 records; all `image_url` values empty | Build photo support and a legitimate content acquisition pipeline; placeholders cannot complete the feature. |
| `models/pandal.dart`: names, coordinates, zone, theme, description, rating, crowd, timings, transit, special features | Extend parsers with optional fields and preserve legacy JSON/Firestore compatibility. |
| `models/pandal.dart`: `bengaliName` currently returns null; entry fee returns a fixed string | Add real localized names and explicit admission metadata; avoid treating unknown fees as verified free entry. |
| `repositories/local_pandal_repository.dart`: static memory cache and one-shot asset loading | A refreshed catalogue must invalidate repository, search, cluster and screen caches together. |
| `screens/pandal_list_screen.dart`: favorites, visited, nearest, rating and crowd sorting | Add discovery collections to this screen instead of rebuilding these functions. |
| `services/pandal_user_state_service.dart`: SharedPreferences sets keyed by pandal IDs | Canonical IDs and migration aliases must preserve user history. |
| `services/omni_search_service.dart`: pandal, metro and food search with cache | Keep entity selection behavior and clear caches after catalogue changes. |
| `repositories/metro_repository.dart`: 55 station entries and five lines | Extend the existing network. Do not add a duplicate metro list or infer service status from record count. |
| `services/metro_transit_estimator.dart`, `trail_optimizer.dart`, `models/trail_leg.dart` | Keep estimated journey calculations separate from published schedules and service advisories. |
| `screens/routes_screen.dart`: six curated routes; custom trails | Connect collections and food stops to the existing trail flow. |
| `repositories/supplementary_repository.dart`: actual `FoodSpot` definition; `models/food_spot.dart` re-exports it | Extend the real definition first. Consolidate only with compatible imports and tests. |
| `assets/data/events.json` and `CulturalEvent` loader exist; no UI consumer found during inspection | Reuse/migrate event content instead of assuming a finished event calendar exists. |
| `utils/puja_schedule.dart`, `services/puja_day_theme_service.dart` | Extend schedule data without creating conflicting dates in splash, themes and calendar. |
| `widgets/pandal_detail_sheet.dart`: favorite, visited, share, transit and toilets | Add photo carousel and related content while retaining these actions. Inspect `pandal_detail_screen.dart` too so deep-linked details agree. |
| `app.dart`, `main.dart`, `screens/main_navigation_screen.dart` | Wire new repositories/services through existing providers and centralized route handling. |
| `pubspec.yaml`: `cached_network_image`, `image_picker`, `http`, `share_plus`, Firebase Auth, local notifications | Prefer installed packages; verify their current APIs and platform support before use. |
| `server/src/index.ts`: Node HTTP and WebSocket server; `server/src/db.ts`, `server/schema.sql`: PostgreSQL support | Add isolated content HTTP handlers and additive migrations; preserve squad REST/WebSocket behavior. |
| `server/src/index.ts`: identity extraction accepts `x-user-id` or raw bearer text without token verification | Do not reuse this authentication behavior for public uploads or moderation. See section 10. |
| `services/squad_chat_service.dart`: unsigned Cloudinary uploads with sample-media fallback | Public uploads need their own signed upload service with explicit errors; never publish sample media on failure. |

README metrics and root Firebase setup notes differ from current source. `main.dart` attempts Firebase initialization and marks configuration present. Confirm actual initialization and available backend capabilities rather than assuming either full demo mode or production readiness.

## 3. Product structure and shared architecture

### 3.1 Navigation

Keep the current five bottom destinations: Map, Pandals, Routes, Group, Helpline. Add a visible **Explore Pujo** entry in the Pandals screen and profile/menu, opening an `ExploreScreen` with collections, Calendar, Transit Guide, Food, Gallery and Stories. Keep emergency access in its current location. Secondary screens use normal back navigation; returning to the map preserves position and active navigation.

Suggested routes: `/explore`, `/collections/:id`, `/transit`, `/calendar`, `/food/:id`, `/gallery`, `/photo/:id`, `/stories`, `/story/:id`. Continue supporting current `/pandal/:id` and squad invite formats. Extend both `app.dart` and the real app-link listener, not just named routes. Only advertise HTTPS sharing links after the owned domain has association files and fallback pages configured. In local/demo builds share text without claiming a working public URL.

### 3.2 Data flow

Use this flow for curated public content:

```text
Reviewed source assets -> validator -> versioned content bundle
                                  -> static HTTPS publication
Flutter bundled seed -> disk last-good cache -> optional refresh
                    -> repositories -> ChangeNotifier -> screens/search/maps

Authenticated public photo submission -> server -> private quarantine
                                     -> reviewer approval -> public derivative
                                     -> gallery API and content publication
```

Default decision: versioned static JSON bundles for curated content; existing Node/PostgreSQL server for community submissions and moderation; an image host behind a `MediaStorage` interface. Reuse Cloudinary only after account settings, moderation access controls and budget are confirmed. Do not introduce a second database for the same content. If the existing deployment cannot host this design, document an adapter decision before changing providers.

Create `models/content_provenance.dart`, `repositories/content_repository.dart`, `services/content_sync_service.dart`, and `services/content_api_client.dart`. Inject HTTP, clock and disk storage interfaces for deterministic tests. Repositories expose typed loading/error/freshness state and immutable snapshots. UI should show last good data while refreshing; a refresh error must not erase useful content.

Every editorial record needs `id`, `revision`, `publishedAt`, `updatedAt`, `reviewedAt`, `sourceRefs`, and `publicationStatus`. A source reference includes URL or document reference, publisher, retrieval time, relevant year, and attribution/license when appropriate. Verification is field-specific: verifying coordinates does not verify theme, fees or ritual times.

Use stable IDs, UTC timestamps and explicit `Asia/Kolkata` interpretation for local dates. Add a timezone library only if existing date tools cannot implement correct schedule/reminder behavior. A photo year, award year and service date must not be inferred from the app's current year.

### 3.3 Design and accessibility

Reuse `config/theme.dart`, `app_colors.dart`, `pandal_theme_tokens.dart`, `utils/responsive.dart` and existing typography. New content must feel like UMA, with light and dark support. These are general design requirements; the local UI/UX search script was unavailable during brief preparation.

- Use at least 48 logical-pixel touch targets, meaningful tooltips and semantic labels.
- Support TalkBack, keyboard focus on web, and 200% text scaling without clipping essential information.
- Keep contrast readable; never communicate status only by color.
- Reserve image aspect ratios before load; use lazy lists/grids and thumbnail-sized decoding.
- Give images descriptive accessibility captions and visible attribution where required.
- Supply loading, empty, offline, error, retry and unavailable states for every new screen.
- Avoid autoplay video and decorative motion during navigation; respect reduced motion.
- On small phones use one-column cards where text demands it; widen to adaptive grids on tablets/web.
- Content refresh and thumbnail loading must not block map startup or squad updates.

## 4. Feature 1: Real pandal photos and visual previews

### Outcome and scope

A user can preview a real pandal before choosing it, distinguish current-year photos from archives, open a zoomable viewer and see its creator/source. Initial scope: still photos. Defer panoramas, video and 3D tours until still-image delivery is complete.

### Data contract

Create `PandalPhoto` in `models/pandal_photo.dart`:

```text
id, pandalId, year, kind [pandal|idol|lighting|entrance|archive]
thumbnailUrl, displayUrl, width, height, altTextEn, altTextBn?
captionEn?, captionBn?, credit, sourceUrl?, license, permissionRef?
capturedAt?, reviewedAt, sortOrder, isCover, publicationStatus
```

Keep photos in `assets/data/pandal_photos.json` and a `PhotoRepository`; optionally reference `coverPhotoId` from `Pandal`. Retain legacy `image_url` parsing as a compatibility fallback. Unknown permission metadata means the photo cannot be published. At most one cover per pandal/year. Cover selection order: approved current-year cover, approved current-year image, most recent approved archive, neutral placeholder.

### Implementation tasks

1. Build the model, tolerant parser and repository with approved-only public results.
2. Add a reusable `PandalPhotoThumbnail` using the existing image cache package; bounded decoding, stable aspect ratio and error placeholder.
3. Modify `widgets/pandal_card.dart` and actual detail views to use cover images. Keep crowded list cards lightweight; do not preload originals.
4. Add `PandalPhotoCarousel` and a `PhotoViewerScreen` with pinch zoom, image count, year, caption and attribution. Prevent swipe/zoom gesture conflicts and preserve viewer index on rotation.
5. Historical images receive an explicit year badge. No image displays a generic illustration labeled as the real pandal.
6. Add `scripts/validate_content.js` checks for resolvable IDs, positive dimensions, HTTPS or bundled asset paths, attribution, cover uniqueness and publication status.
7. Support a local rights ledger at `data/content/photo_permissions.json`; keep private permission evidence outside public bundles if it contains personal information.
8. Start the content pilot with 20 popular pandals across multiple zones, ideally two approved photographs each. These are acquisition targets; do not invent files or count placeholders as completion.

### Acceptance criteria

- Current-year, archive-only, missing-image and broken-image records produce distinct correct states.
- Browse and detail images match the same pandal and year; image failure never disables directions.
- Only thumbnails load in a long list; opening the viewer fetches a larger rendition.
- Cached images remain usable offline; uncached images show a clear placeholder.
- Unapproved photos are excluded even if their IDs are supplied through a deep link.
- Unit tests cover cover selection and permission validation; widget tests cover load failure, archive labels, text scaling and semantics.

## 5. Feature 2: Must-visit discovery and richer categories

### Outcome and data

Users choose a meaningful collection instead of guessing from hundreds of names. Add `nameBn`, `aliases`, normalized `tags`, `heritageType`, `themeYear`, `admission`, `accessibility` and optional evidence-backed award references to `Pandal`. `admission` supports `free|paid|unknown` plus source and year. Accessibility fields are tri-state `yes|no|unknown`; missing information never means accessible.

Create `DiscoveryCollection` in `models/discovery_collection.dart`: ID, English/Bengali title and summary, cover photo, explicit pandal IDs, ordering, optional zone, intended audience, year, editorial explanation and provenance. Start with First-Time Essentials, Heritage/Bonedi Bari, Theme Art, Spectacular Lighting, Near Metro and Editor's Picks. Use Award Winners only when award name, organizer, year and evidence exist. An editor's pick is not a public rating or award.

### Implementation tasks

1. Add `assets/data/discovery_collections.json` and `DiscoveryRepository` with validation of every linked ID.
2. Add horizontally browseable collection cards and a filter sheet to the directory. Combine collection, zone, tag, favorites and search predictably; provide Clear filters and result count.
3. Keep nearest/rating/crowd sorting. Label stored crowd information as typical or reported with timestamp; avoid introducing a Live badge without a real feed.
4. Add `CollectionDetailScreen`: rationale, list/map switch, Save collection locally, and Plan this trail.
5. Plan this trail passes validated IDs into the existing custom trail service; offer the existing order or optimized order. Do not silently overwrite an active trail.
6. Offline collections resolve against the active catalogue. Exclude missing/retired IDs with an explanation, rather than crashing.
7. Search should match genuine Bengali names/aliases in addition to existing normalization. Keep distinct name data rather than a getter returning null.

### Acceptance criteria

- Combined filters have defined intersection behavior; clearing them restores the expected list.
- Awards always show the award year; unverified awards do not appear as earned badges.
- Planning a collection preserves existing visited/favorite data and asks before replacing an active trip.
- Unknown accessibility is visibly unknown. Tests exercise intersecting filters, stable order and missing IDs.

## 6. Feature 3: Practical transit guidance

### Outcome and data

A user can determine where to board, where to change, which exit helps, and whether a published service notice affects the trip. Continue using existing station IDs and graph/estimator. Add supplemental `TransitServiceWindow`, `StationExit`, `TransitAdvisory` and `TransportConnection` records in `assets/data/transit_guidance.json`.

```text
TransitServiceWindow: id, lineId, direction, originStationId,
destinationStationId?, validFromDate, validThroughDate, weekdaySet,
firstDepartureLocal?, lastDepartureLocal?, frequencyMinutes?,
scheduleType [normal|festival|exception], sourceRefs, reviewedAt

StationExit: id, stationId, label, coordinates?, landmark,
connectedPandalIds, accessibility [yes|no|unknown], sourceRefs

TransitAdvisory: id, affectedLineIds, affectedStationIds, severity,
titleEn, titleBn?, body, startsAt, expiresAt, sourceRefs, reviewedAt

TransportConnection: id, mode [rail|bus|ferry|auto], location,
relatedStationIds, boardingAdvice, fareNote?, validity, sourceRefs
```

### Implementation tasks

1. Create `TransitGuidanceRepository`; link records to existing stations rather than replacing the graph with marketing claims.
2. Build `TransitGuideScreen` with line selection, stations, interchange guidance, current applicable notices, and rail/ferry/bus information.
3. Extend station sheets in both map engines with exits, nearby pandals and source/freshness information.
4. Extend route-leg cards with interchange name, boarding direction and walking segment. Display Estimated journey duration separately from Published service hours.
5. Handle service beyond midnight with date-qualified timestamps; a 01:00 departure may belong to the next calendar date. Never compare plain time strings.
6. Do not infer the last train at an intermediate station from the origin terminal's departure. Display what the source actually states.
7. Select festival exceptions before normal service; expired or conflicting records produce a warning and source links, not a confident recommendation.
8. Advisory records may warn about disruptions. Do not dynamically remove graph edges unless the notice has structured, verified closures and safe routing fallback.
9. Update the unconditional `Metro Runs Till 4 AM` tip in `routes_screen.dart` to verified date/line-specific guidance or an explicit instruction to check current services.

### Acceptance criteria

- Tests cover overnight service, festival exceptions, expiry, unknown hours, line/station mismatch and interchange guidance.
- A cached expired timetable remains labeled outdated; no confident last-train advice derives from it.
- No additional GPS permissions are needed. Both map engines show consistent guidance.
- All transport operating claims carry source, validity and review date. The competitor site is not sufficient authority for real-time operations.

## 7. Feature 4: Larger, regularly maintained pandal coverage

### Outcome and bundle format

New pandals and corrections reach the app without losing bookmarks or requiring an app release. Preserve bundled content as first-launch fallback.

Use a manifest and immutable full snapshot first; defer deltas until full updates are reliable:

```json
{
  "schemaVersion": 2,
  "catalogVersion": "2026.10.13.1",
  "publishedAt": "2026-10-13T06:00:00Z",
  "minimumSupportedSchemaVersion": 2,
  "bundles": [
    {
      "name": "pandals",
      "url": "https://YOUR_OWNED_CONTENT_HOST/content/pandals-v2.json",
      "sha256": "REPLACE_WITH_COMPUTED_DIGEST",
      "byteLength": 0,
      "recordCount": 0
    }
  ]
}
```

This is a shape example, not publishable data. Actual URLs, lengths and hashes must be generated. Include all cross-linked bundles in one catalogue version: pandals, photos, collections, transit guidance, calendar, food and stories. Use a fixed owned-host allowlist. HTTPS plus trusted origin protects delivery; a checksum detects corruption but does not authenticate a malicious publisher.

### Implementation tasks

1. Add offline validators for unique IDs, coordinates inside configured coverage, required fields, valid enum values, references, and documented duplicate candidates. Do not merge nearby pandals automatically: separate committees may share an area.
2. Add `id_aliases.json`, retired records/tombstones and explicit manual canonicalization. Never recycle an old ID for a different pandal.
3. Replace global asset-only caching with a versioned catalogue snapshot. Keep constructor compatibility where practical; remove stale static cache assumptions and publish changes through one notifier.
4. Refresh manually and opportunistically on foreground launch no more often than a configurable six-hour interval. Add timeout, ETag support, bounded retries, download-size ceiling, and one in-flight refresh. No background location or continuous polling.
5. Download to staging, validate size/hash/schema/all references, then atomically switch the whole catalogue pointer. On crash or validation failure retain the last good version.
6. Keep the previous good snapshot for rollback and clean older snapshots with a bounded retention policy. Startup falls back disk -> bundled seed if corruption is found.
7. Reconcile favorite/visited IDs through aliases, retain retired IDs for history, and remap saved collection selections. Make reconciliation idempotent.
8. Clear `OmniSearchService` and pandal search caches, spatial cluster caches and directory derived state after activation. Ensure in-progress navigation holds a stable trip snapshot until the user opts to refresh it.
9. Add a Data updates page with version, last successful check, Update now and download failure state.
10. Extend existing scraper/seed workflows with a normalized import stage, validation report and dry-run mode. Preserve provenance and review imported descriptions, hours, awards and coordinates before publication.

### Acceptance criteria

- Invalid checksum, unsupported schema, missing references, timeout and interrupted writes never replace active data.
- A new valid snapshot appears in directory, map and search without restart or stale counts.
- Favorites and visited history survive alias migration, retirement and rollback.
- Offline startup works from both seed and last-good snapshot.
- Catalogue tests use small deterministic fixtures; counts in documentation derive from validated active content.

## 8. Feature 5: Puja calendar and ritual timings

### Outcome and data

Users can browse festival days, understand rituals and set optional reminders. Create `FestivalDay`, `RitualEvent` and `CulturalProgram` models with `year`, `dateLocal`, localized titles/descriptions, event type, source tradition, provenance and publication state.

`RitualEvent` adds `startAt?`, `endAt?`, `timeZone`, `timingPrecision [exact|approximate|unspecified]`, `pandalId?`, `locationScope [city|pandal]`. `CulturalProgram` adds venue, linked pandal, category and cancellation status. City-level ritual guidance must not be displayed as a committee's confirmed programme. Two Saptami calendar entries must be represented by distinct IDs, not collapsed by name.

### Implementation tasks

1. Add `assets/data/festival_calendar.json`, a `FestivalCalendarRepository`, and one shared schedule adapter used by splash/day themes/calendar. Preserve current dates until reviewed; do not silently replace them with competitor claims.
2. Build `FestivalCalendarScreen` with accessible day selector, agenda view, ritual/program filters and selected-day persistence. Provide a list alternative to a month grid.
3. Add event details with timing precision, source/tradition and linked pandal actions. Missing programmes show No confirmed programmes yet.
4. Migrate existing `events.json` only where year, time and venue can be confirmed; exclude incomplete fixtures from public confirmed schedules.
5. Add `FestivalReminderService` using existing local notifications. Ask for notification permission when the user requests a reminder, not on first launch.
6. Offer 15-minute and one-hour reminders. Use stable notification IDs, platform-appropriate scheduling, proper timezone initialization, and no exact-alarm permission unless a verified requirement justifies it. Explain that OS delivery can be delayed.
7. Cancel/reschedule reminders when confirmed events change or are withdrawn; do not schedule guessed times. Persist selections and handle denied permission without claiming the reminder is active.

### Acceptance criteria

- Festival dates agree across theme, splash and calendar.
- Date boundaries and reminder timestamps work on a device configured outside India.
- Unknown times, approximate times, cancellations and denied notifications have accurate states.
- Tests cover repeated ritual names on different dates and changed-event reminder reconciliation.

## 9. Feature 6: Complete food information and trail integration

### Outcome and data

Users can find a suitable food stop along the trip, see useful hours and distinguish verified opening information from unknown status.

Extend the existing `FoodSpot` with localized name, address, linked pandal IDs, cuisine/tags, dietary options, dietary verification, structured hours, festival overrides, cost band, currency, contact, menu source, photo IDs and provenance. Existing `mustTry`, `priceRange` and `nearbyPandal` remain supported. Treat dietary options as claimed/verified/unknown; do not guarantee allergen safety from a tag.

Hours: timezone, weekday intervals, overnight intervals, validity dates, exceptions, review time. Keep free-text hours only as display fallback. `openNow` is `open|closed|unknown`; stale or unparseable data produces unknown, not closed.

### Implementation tasks

1. Extend `SupplementaryRepository` and the actual FoodSpot model; migrate old name-based pandal relationships to canonical IDs with a review report.
2. Add `FoodDetailScreen`, a Food list in Explore, and filters for cuisine, dietary options, price band and verified open-now. Retain food results in omni-search.
3. Show must-try dishes, hours, source date, distance and directions. Reuse map routing and label estimated walking distances.
4. Introduce a generalized trail stop wrapper rather than converting a restaurant into a fake Pandal:

```text
TrailStop: id, entityType [pandal|food], entityId, label,
coordinates, visitDurationMinutes?, isPinnedInOrder
```

5. Adapt custom trail service and optimizer through a coordinate-based interface. Keep existing Pandal optimizer methods as compatibility adapters. Add optional food stops with user-chosen dwell time; food insertion must preserve pinned order and allow removal.
6. Offer Add food break along the planned route, ranking by route detour and dietary selection. Use existing route-corridor tools where applicable; straight-line distance is an estimate, not verified road detour.
7. Recalculate travel plus visit/break time separately, show the change before confirmation and preserve completed stops. Without reliable route data show an estimated detour.

### Acceptance criteria

- Food hours handle overnight intervals, closures, festival exceptions and missing data.
- No fabricated prices or dietary claims appear as verified.
- A mixed trail can start, continue, resume and remove a food stop without corrupting pandal visited counts.
- Existing pandal-only trail tests still pass; new tests cover pinned order and duration breakdown.

## 10. Feature 7: Public photo gallery and festival stories

### 10.1 Curated gallery and stories first

Ship an approved read-only gallery before community publishing. `GalleryPhoto` references the same image/rights model as pandal photos with approved publication metadata. Do not expose squad attachments, chat or member locations in the public gallery.

Create `FestivalStory`: ID/slug, English/Bengali title, summary, language, category, author credit, cover photo, ordered body blocks, source references, related pandal IDs, year relevance, draft/published/withdrawn status, publish/update times. Use a bounded block format (`paragraph`, `heading`, `image`, `quote`, `list`, `relatedPandal`) instead of unrestricted executable HTML. Quotes and image use need permission/source metadata. Validate external links and render them safely.

Build `GalleryScreen`, shared photo viewer, `StoriesScreen` and `StoryDetailScreen`. Provide zone/year/pandal filters, lazy paging, story category/language selection, reading progress and local bookmarks. Cache selected story text and bounded images for offline reading. Browsing requires no sign-in. Share using real configured links or a text fallback. Start with original reviewed stories on heritage, artisans, dhak, food and first-time hopping; no copied competitor articles or invented local histories.

### 10.2 Public submission flow

1. User opens Upload photo and explicitly chooses a real authenticated session. A device-only/demo guest ID is insufficient; verified anonymous Firebase sessions may submit under stricter quota.
2. Pick one photo, choose its pandal, enter year/caption and credit, preview it, and confirm the right to publish. Request camera/media access only when used.
3. Restrict initial uploads to JPEG/PNG/WebP, 10 MB input and a configured decoded-pixel ceiling. Validate real content, not only MIME text or extension; reject malformed/animated formats initially.
4. Create an authenticated upload intent. Use a short-lived signed upload or authenticated server upload into **private quarantine**, bound to the owner, intent and allowed media settings. Ordinary publicly fetchable pending URLs are unacceptable.
5. Server verifies actual uploaded asset ownership, dimensions, size, hash and media type. Re-encode and strip EXIF/GPS server-side before public approval; client stripping alone is insufficient.
6. Finalize the intent with an idempotency key. Create a pending submission; only its owner and moderators may inspect it.
7. User sees Pending review, Rejected with reason, Approved or Failed, with retry/cancel. A failed upload never substitutes sample media or silently creates a public record.
8. Local offline drafts are allowed with explicit local status. Retry upload only following a deliberate user action; do not automatically upload gallery selections on reconnect.

### 10.3 Server API and persistence

Add `/api/content` routing through a dedicated handler rather than enlarging the squad monolith. Suggested contracts:

| Endpoint | Access | Behavior |
| --- | --- | --- |
| `GET /api/content/gallery?pandalId=&year=&cursor=&limit=` | Public | Approved, non-withdrawn images only; stable cursor; limit capped at 50. |
| `GET /api/content/gallery/:id` | Public | Same approval check as list; guessed pending IDs return not found. |
| `GET /api/content/stories` and `/:slug` | Public | Published content only; static bundles may serve these instead. |
| `POST /api/content/upload-intents` | Verified user | Validate quota and metadata; return expiring intent and upload parameters. |
| `POST /api/content/submissions` | Intent owner | Verify uploaded media and finalize once; replay returns the original result. |
| `GET /api/content/my-submissions` | Verified user | Only requester-owned records, cursor paged. |
| `DELETE /api/content/submissions/:id` | Owner/moderator | Withdraw access promptly; queue provider cleanup and retain minimal audit. |
| `POST /api/content/reports` | Verified user | Submit report, rate limited; no private reviewer details returned. |
| `GET /api/content/moderation/queue` | Moderator | Pending/reported records with private previews. |
| `PATCH /api/content/moderation/:id` | Moderator | Transactional approve/reject/withdraw plus reason and audit event. |

Use standard JSON errors (`code`, safe `message`, optional `retryAfterSeconds`), request size limits, query validation, parameterized SQL, structured logs without tokens/private URLs, and explicit 401/403/409/413/429 handling.

Add additive migrations in `server/migrations/` for `content_upload_intents`, `content_submissions`, `content_media`, `content_reports`, `content_moderation_events` and server-managed moderator roles. Store editorial stories/collections in versioned bundles initially. Index `(status, published_at, id)`, `(pandal_id, year, status)` and `(owner_uid, created_at, id)`. Store audit reasons separately from public DTOs.

Submission state machine: `intent_created -> uploaded -> pending_review -> approved|rejected`; approved can become withdrawn. Expired intents cannot finalize. Concurrent review uses version checks and a transaction. Never allow clients to set owner, approval, reviewer identity or asset visibility.

### 10.4 Authentication, storage and moderation requirements

- Add Firebase Admin token verification for content endpoints, verifying signature/project/expiry and obtaining the UID from the token. Do not trust `x-user-id`, a body UID, or raw bearer text as identity. Existing squad authentication is a separate remediation concern; ensure this feature does not inherit its behavior.
- Bind all queries and media operations to verified ownership or server-managed moderator role. UI hiding is not authorization.
- Cloudinary secrets and database credentials stay server-side. Signed parameters must constrain resource type and asset placement; completion revalidates the actual asset.
- Define durable per-user upload limits (initial configurable target: five submissions/day), intent concurrency, byte quotas and abusive-request limits. In-memory-only limits do not suffice across deployments.
- Moderation checks rights, correct pandal/year, identifying personal information, inappropriate material and misleading content. Automated checks can assist, but initial publication requires reviewer approval.
- Supply a working moderator UI or authenticated local admin CLI with list/preview/approve/reject/withdraw/report resolution. No public uploads enabled until a reviewer can use it end to end.
- Add report action, owner withdrawal, account deletion handling and copyright contact/rights process. Updating `PRIVACY.md` and public contribution wording is part of implementation; legal text must be reviewed before release.
- Public CDN cache invalidation/asset deletion and catalogue removal must accompany withdrawal. Document achievable revocation latency and cache TTL; offline devices may retain older cached copies until refresh, so do not promise instantaneous universal deletion.
- Run cleanup for abandoned intents and rejected/withdrawn private assets with documented retention. Keep user drafts local and purge them on cancel as appropriate.
- No likes/comments/follower system in initial scope. They add moderation and state complexity unrelated to the requested gallery.

### Acceptance criteria

- Spoofed user headers, invalid tokens, wrong owners and non-moderator decisions are rejected.
- Pending/rejected/private records and previews cannot be fetched through public endpoints, provider URLs or guessed IDs.
- Failed uploads preserve a retryable draft; no sample image reaches the public feed.
- Duplicate finalization yields one submission. Pagination remains stable across insertions.
- Approved photos appear in gallery; explicit editorial promotion is needed before becoming a pandal cover.
- Withdrawal removes public listing/detail access and enqueues media cleanup; cache behavior is documented and tested.
- Story references, Bengali text, bookmarks and offline reading work. Authenticated test fixtures exercise moderation transitions and ownership.

## 11. Cross-cutting configuration, delivery and quality

### Configuration

Add non-secret Flutter defines such as `CONTENT_BASE_URL`, `CONTENT_API_BASE_URL`, `ENABLE_CONTENT_SYNC` and `ENABLE_PUBLIC_PHOTO_UPLOADS`. Gallery browsing and uploads have separate flags. Default uploads off until backend moderation is ready. Flutter defines are inspectable in distributed builds; never put a secret there.

Server configuration includes database URL, Firebase project/admin credentials, media signing credentials, allowed origins, upload quotas, cleanup retention and publication flags. Provide `.env.example` with names and dummy values only, and verify it is safe to track. Do not commit `.env`, generated Firebase options, platform Firebase config, service-account JSON or credentials.

### Performance and operational behavior

- Define a 20 MB catalogue download ceiling initially; tune with measured content size and use streaming limits before full allocation. Keep images outside JSON bundles.
- Serve appropriately sized image derivatives; target thumbnails below 150 KB where visual quality permits. Gallery pages fetch approximately 20 items.
- Bound disk image cache (initial target 100 MB), cache text/metadata separately and expose Clear downloaded content without deleting favorites/visited.
- Restrict pending preview retention and monitor image-host/storage/egress limits. Free-tier affordability is a constraint to verify, not a promise of permanent zero cost.
- App content failures must not disable map, squad or emergency functionality.
- Do not bulk download OSM tiles as part of these features. Any map download work is separate and must respect the selected provider's policy.
- Keep analytics opt-in if added; no precise location, private chat or original EXIF in content analytics.

### Validation commands

From `app/`:

```powershell
flutter pub get
dart format lib test
flutter analyze
flutter test
```

From `server/`, when server code changes:

```powershell
npm ci
npm run build
```

Inspect current server tests before executing `npm test`: they may depend on a running service/database. Add an isolated `test:content` script using disposable local test data for auth, moderation and storage mocks. Do not run migration or destructive integration tests against an unknown production database.

From `scripts/`, create and document `npm run validate:content` for fixtures/assets and `npm run content:dry` for import/bundle preview. Publication must remain a separate explicit action. Run the existing Flutter suite after milestone changes; write behavior tests for new logic rather than mirroring widget implementation.

Manual checks: small Android phone, tablet/web layout, light/dark, TalkBack, large text, flaky network, airplane mode, restored process, backend disabled and malformed deep links. Inspect both map engines' changed detail flows. Capture review screenshots of new screens where feasible. Record actual results; never claim historical README test totals as current results.

## 12. Milestones and exact work order

| Milestone | Tasks | Completion gate |
| --- | --- | --- |
| M0: Foundations | Confirm runtime configuration; content schemas, provenance, flags, interfaces and validators; progress file | Legacy assets parse; app launches; fixtures validate; baseline checks recorded. |
| M1: Photo previews | Feature 1 UI, photo repository, viewer, rights ledger and curated pilot | Honest image states and image tests pass; real approved pilot content acquired or documented as a content prerequisite. |
| M2: Discovery | Feature 2 localized data, collections, filters and existing trail handoff | Filters/planning work offline; no fabricated awards/accessibility claims. |
| M3: Catalogue refresh | Feature 4 snapshot sync, alias migration, rollback and cache invalidation | Update failures leave old data usable; favorites/trips survive changes. |
| M4: Transit | Feature 3 station/line guide, exits, notices and verified schedule handling | Overnight/expiry tests pass; both map engines agree; unsupported operating claims removed. |
| M5: Calendar | Feature 5 shared schedule, agenda and optional reminders | Dates consistent; timezone/permission/cancellation checks pass. |
| M6: Food | Feature 6 hours/dietary detail and mixed trail stops | Pandal-only routes preserved; food insertion and open-now behavior tested. |
| M7: Editorial media | Feature 7 read-only gallery and original stories | Published-only browsing, pagination and offline reading work without sign-in. |
| M8: Community backend | Verified auth, quarantine, intents, quotas, moderation tooling, reports and cleanup | Security/ownership tests pass; reviewer workflow works; private assets remain inaccessible publicly. |
| M9: Community Flutter | Upload form, local drafts, owner status/withdrawal and flag wiring | Failure/retry/idempotency/approval/withdrawal verified end to end against local backend. |
| M10: Release review | Documentation, content audit, privacy wording, configuration and regression checks | All seven features demonstrated; unresolved external items clearly listed; no fake production success. |

Each milestone should be a reviewable change. Avoid mixing unrelated squad/map rewrites into content work. Add migration adapters before removing old fields. Do not leave overlapping calendar repositories or duplicate photo/food definitions after migration.

## 13. Suggested new files

Names are suggested, not mandates to duplicate existing abstractions. Inspect existing files before creating them.

```text
app/lib/models/
  content_provenance.dart, pandal_photo.dart, discovery_collection.dart
  transit_guidance.dart, festival_event.dart, festival_story.dart
  gallery_submission.dart, trail_stop.dart
app/lib/repositories/
  content_repository.dart, photo_repository.dart, discovery_repository.dart
  transit_guidance_repository.dart, festival_calendar_repository.dart
  gallery_repository.dart, story_repository.dart
app/lib/services/
  content_sync_service.dart, content_api_client.dart
  festival_reminder_service.dart, public_photo_upload_service.dart
app/lib/screens/
  explore_screen.dart, collection_detail_screen.dart, transit_guide_screen.dart
  festival_calendar_screen.dart, food_detail_screen.dart
  gallery_screen.dart, photo_viewer_screen.dart, photo_upload_screen.dart
  my_submissions_screen.dart, stories_screen.dart, story_detail_screen.dart
app/lib/widgets/
  pandal_photo_thumbnail.dart, pandal_photo_carousel.dart
  content_freshness_label.dart, collection_card.dart, transit_advisory_card.dart
app/assets/data/
  pandal_photos.json, discovery_collections.json, transit_guidance.json
  festival_calendar.json, festival_stories.json, id_aliases.json
server/src/content/
  routes.ts, repository.ts, auth.ts, media-storage.ts, moderation.ts
server/migrations/
  [next migration number]_content.sql
scripts/
  validate_content.js, build_content_bundle.js, import_content.js
docs/
  FEATURE_IMPLEMENTATION_PROGRESS.md, CONTENT_OPERATIONS.md
```

## 14. Content and operational prerequisites

Code completion alone cannot supply real photos, current-year themes, reliable timetables or ritual knowledge. Track these as separate deliverables:

- Photographer/committee-approved photos and public attribution/license metadata.
- Reviewed canonical pandal records and ID mappings; supported coverage boundary.
- Published transport notices from the relevant operators, including validity dates and directions.
- Reviewed ritual sources/traditions and committee-confirmed cultural programmes.
- Reviewed restaurant hours, dietary claims and festival exceptions.
- Original reviewed festival articles with sources and properly licensed illustrations.
- Owned content host/share domain, backend database, authenticated media storage and a functioning reviewer workflow.
- Provider budget/quotas and storage retention reviewed against expected traffic.

When a prerequisite is absent, display unknown/unavailable honestly, retain working offline functions and document exactly what is needed. Continue independent local implementation rather than blocking all milestones on content acquisition.

## 15. Final handoff required from Codex

Deliver a concise summary with implemented milestones, changed files, actual validation results, screenshots where available, migrations/configuration instructions, and remaining production/content prerequisites. Include commands for local preview, dry-run validation and rollback. Explicitly identify any feature whose UI exists but production data or service is still unavailable.

Definition of done: the seven feature areas have functioning local/demo behavior with realistic approved fixtures, compatible migration paths, robust offline/error behavior, passing relevant checks and documented production setup. Production public uploads are complete only after real authentication, private quarantine, review, publication, reporting and withdrawal have been verified together.

## 16. References

Reference website pages inspected during the comparison:

- [Pandal map](https://www.durgapujakolkata.in/map): advertised map and route planner; interactive behavior not verified.
- [Pandal directory](https://www.durgapujakolkata.in/paras): discovery tags, featured/saved categories and broader visible coverage.
- [Transit guide](https://www.durgapujakolkata.in/guide/navigating-kolkata): transport guidance inspiration; independently verify operational claims.
- [Panzika](https://www.durgapujakolkata.in/panzika): calendar/ritual presentation inspiration; independently verify timings.
- [Food trail](https://www.durgapujakolkata.in/guide/food-trail): hours and dish information inspiration.
- [Homepage](https://www.durgapujakolkata.in/): photographic showcases, gallery links and cultural articles.
- [Events](https://www.durgapujakolkata.in/events): programmes were still being prepared when inspected; do not treat advertised features as completed functionality.

Primary implementation documentation checked while preparing this brief:

- [Firebase Admin: verify ID tokens](https://firebase.google.com/docs/auth/admin/verify-id-tokens). Use verified client ID tokens to identify users on the custom server.
- [Cloudinary upload documentation](https://cloudinary.com/documentation/upload_images). Check signed upload and asset access behavior for the actual account configuration before choosing storage settings.
- [Flutter accessibility](https://docs.flutter.dev/ui/accessibility). Apply semantics and accessibility checks to new UI.

Repository guidance remains authoritative for local commands and permissions. Package APIs and provider policies must be rechecked at implementation time.
