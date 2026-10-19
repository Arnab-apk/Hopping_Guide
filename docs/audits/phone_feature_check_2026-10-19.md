# Phone feature check — 19 October 2026

Device: connected Motorola Edge 50. Initial app: 1.1.0 (4023).

## Fixes

- Group video calls returned HTTP 503 while configuring the Stream call type.
  Reproduced the SDK's 3-second timeout locally. Increased upstream operation
  timeout to 15 seconds. A subsequent real call-token read failed with Stream
  error 42 (token used before issue time); the local clock was about two seconds
  ahead of Stream. Call tokens now tolerate 30 seconds of skew while retaining
  the five-minute total lifetime and room scoping. Reported remaining validity
  is 270 seconds. Deployed commit `2c8320117d8e809010cee657a58482ec55677bf7`
  to the existing Render service; deployment `dep-dbaq8iijnfac738nena0` is live.
- Journey cards covered map GPS, settings and 2D/3D controls after stopping a
  walking leg. Controls and card now share a column, using the card's actual
  height. Short phones use a horizontal toolbar during a journey. Device retest
  opened settings and activated GPS follow while the journey card was visible.
- Profile statistics used a hard-coded total of 338. The denominator now comes
  from the loaded pandal directory.
- Android location was initially off. Enabled it on the device; group status
  subsequently confirmed `Location shared with group`.

## Verification

- Flutter analysis: no issues after final source changes.
- Full Flutter suite after map fix: 480 passed, five opt-in tests skipped.
- Separate live routing run: four passed (walking maneuvers, Chuchura–South
  Kolkata train/metro, Chuchura–Behala, and car/train/metro comparison).
- Final focused UI suite after profile change: 52 passed. Includes native
  toolbar/card hit testing at 375×667 and 844×390 and page layout audits.
- Server build and seven video tests passed. Local two-client squad/WebSocket
  checks passed, including chat acknowledgements and separation events. Four
  call-notification tests passed. Six chatbot test groups passed using fallback;
  the local NVIDIA credential returned 403 and is not a verified cloud-AI path.
- Live Firebase/Stream checks passed locally and against the deployed service:
  authenticated private call access, unrelated-room denial, forged identity
  rejection and membership-removal denial. Temporary records were cleaned up.
- Three synthetic hosted media clients each decoded remote video and received
  remote audio. Camera/microphone toggles and participant leave passed. Evidence:
  `scratch/video_media/verified.json`; temporary test records cleaned up.
- Phone joined the existing one-member group's call with real camera preview
  and microphone activity. Camera off, microphone mute and End call worked.
  Call invitations and endings appeared in the group's chat.
- Puja Bot answered a nearest-station question in the user's one-member group.
  This establishes response delivery, not factual accuracy of all generated text.

## Phone feature coverage and limits

| Feature | Live evidence | Remaining scope |
| --- | --- | --- |
| Startup/account/profile | Signed-in profile retained through installation | Fresh Google login, account switching and profile writes not performed |
| Map | Native map/3D buildings rendered; 2D/3D toggle, light/dark themes, region sheet, metro layer, GPS follow and settings exercised | Full gesture/performance certification not established |
| Search | Bagbazar query returned pandal, railway, food and metro suggestions | Voice recognition not exercised |
| Directory | 347 pandals, 66 food spots, detail/transit information, saved four visits retained | Some pandals have no photos; live upload and every gallery not verified |
| Favorites | Added a food favorite, filtered to it, then removed it; count restored to zero | Cross-account persistence not verified |
| Routes | Six curated circuits loaded; real Bagbazar train/metro itinerary and walking guidance started with Live GPS | Outdoor turn completion, deviation and physical arrival not exercised |
| Custom trails | Selected start and two stops; reached final generation/review step | Did not replace the user's existing 15-stop group plan |
| Return home | Planner and home-station picker opened | Official last departures are unverified; UI states this limitation |
| Groups/location | Existing group connected Live; GPS publication confirmed | Second physical member receiving updates not verified |
| Chat/bot | Existing history, call events and bot reply visible | Media upload and delivery to another physical phone not verified |
| Video/push | Phone joined/muted/left; hosted synthetic remote media and notification logic passed | Second physical phone, background ringing and real remote audio quality not verified |
| Helplines | Directory and first-aid content loaded | No emergency calls placed |
| Walkthrough | All five pages opened | Text is not a guarantee of every advertised capability |
| Offline | Bundled directory and automated fallback/offline checks passed | Full airplane-mode map/navigation coverage not established |

## Artifacts

Screenshots and UI dumps: `app/build/phone-feature-audit/`.
Full regression log: `app/build/phone-audit-final-tests.log`.
Final focused UI log: `app/build/phone-audit-ui-final.log`.
APK: `app/build/app/outputs/flutter-apk/app-release.apk`.

Final release build: 1.1.0 (4025), built with the existing ignored build settings.
Build 4024 established the map repair on the phone; 4025 includes the profile
correction added during the first build. User data is preserved with `adb install -r`.
Android reports build 4025 installed at 11:04:24. On-device profile retest shows
`Out of 347`, four visits, zero bookmarks and the existing group retained.
APK SHA-256: `F89B025C5C41F3D928D77830F4EA7217A3941F82FBA2D235712FD135A9614115`.

This audit does not certify every feature as working end to end. The unverified
physical, account and offline scenarios above remain open.

## Friend join and premade list follow-up

Used a newly created Firebase identity and real client REST requests (not Admin
requests) to look up the user's invite code, batch-join `Locals`, read its members and
existing 15-stop list, and query the account's My groups membership. All passed
under deployed Firestore rules. Every stop has finite map coordinates and the
list matches the original order. First stop: Chuchura Rathtala Durgotsav. The
group was not hopping when checked; its saved list remains available.

Temporary membership/member document and identity were removed; the original
plan was compared after cleanup and remained unchanged. Test output:
`app/build/phone-feature-audit/friend-join-result.json`.

All six bundled curated circuits resolve every referenced stop in the real
pandal dataset: 7, 6, 6, 5, 5 and 5 stops. Invite web/deep-link checks: four
passed. Flutter invite, collaborative hopping and route-page checks: 26 passed
(`app/build/friend-group-route-tests.log`). A real friend's Google login and
second physical phone display remain unverified; this proves a fresh identity's
deployed membership/data access and the route UI's tested behavior.
