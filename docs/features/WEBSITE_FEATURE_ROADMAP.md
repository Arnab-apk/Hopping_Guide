# Website feature implementation checklist

Implement in this order. Existing navigation and group hopping stay the core of UMA.

| Order | Feature | Status | Prerequisites |
| --- | --- | --- | --- |
| 1 | Real pandal photographs and galleries | In progress: gallery and public metadata scraper implemented; validation underway | Public photo source; reliable pandal matching; photographer attribution; confirmed reuse rights and stable hosting before release |
| 2 | Featured and themed discovery collections | Todo | Editorial picks; verified category and award tags; award year/source |
| 3 | Broader verified pandal coverage and correction submissions | Todo | Trusted records, coordinates, deduplication, review queue and correction storage |
| 4 | Detailed Panzika and ritual reminders | Todo | Authoritative Kolkata timetable, calendar tradition/source, per-pandal ceremony times, notification permission |
| 5 | Food opening hours and meal breaks in routes | Todo | Checked hours, seasonal changes, dietary metadata and routing support for food stops |
| 6 | Verified committee contributions | Todo | Working authentication/backend, organiser verification, moderation, image storage, upload limits and rules |
| 7 | Culture and visitor guides | Todo | Original/licensed editorial content, Bengali/English copy and attribution |

## First feature

- [x] Backward-compatible photo metadata in Pandal and Place models.
- [x] Optional bundled photo manifest merged into the offline directory.
- [x] Cover photos on directory cards and gallery entry on pandal details.
- [x] Fullscreen swipe/button browsing, pinch zoom, credits and source links.
- [x] Cached network images with loading/error feedback and honest empty states.
- [x] Public website scraper with strict name/location matching and reachable-image checks.
- [ ] Populate and inspect the first public-source photo batch.
- [ ] Complete analysis, regression checks and gallery tests.
- [ ] Confirm photo reuse rights and production hosting before public release.

### Photo import

From the workspace root:

```powershell
node scripts/scrape_pandal_photos.cjs --limit=12
node scripts/scrape_pandal_photos.cjs --limit=12 --apply
```

The default is a dry run. `--apply` updates only `app/assets/data/pandal_photos.json`.
It reads public pages, records stable image proxy URLs and public photographer
credits, and never stores signed storage URLs, private account data or login cookies.
It skips ambiguous name matches and location disagreements over 1 km.
Refreshes preserve curated metadata. Source edition dates are not photo dates.

Photo entries contain `url`, `caption`, `credit`, `source_url`, optional `year`,
and `rights_status`. Website photos initially have `rights_status: unverified`:
they are prototype references, not evidence of a reusable licence. Review these
records before a public release and move approved assets to controlled hosting.

Core gallery display needs no new package, account or Firebase configuration.
Remote photos require connectivity on first load; cached images may be reused,
but this is not a promise that the whole gallery is available offline. When no
year or individual credit is established, the app does not invent one.
Community uploads are deferred to item 6 because they require moderation and storage.

Google Photos requires a publicly shared album supplied by its owner. Private
albums are outside this scraper's scope. A shared album also needs permission
and permanent hosting before its photographs become production app assets.
