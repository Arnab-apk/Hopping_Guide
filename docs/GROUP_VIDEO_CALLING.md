# Group video calling

Open **Groups → Chat → Group video call**. Choose camera on/off and tap **Join group call**. Other signed-in members open the same group's call to join the room. Stream supplies the participant layout, mute, camera toggle, camera flip, speaker and leave controls.

This is a foreground call room. Calls leave when the app moves into the background; rejoin from the group when returning. There are no closed-app ringing notifications. The repository has no iOS runner, so the implemented native permissions and build verification cover Android.

## Backend setup

The existing `server/` Node service now exposes `POST /api/squads/:squadId/video/session`. The app sends a real Firebase ID token. The endpoint checks revoked tokens and the Firestore `squads/{id}.membersUid` roster; demo UIDs and `x-user-id` never authorize video calls.

Add these settings to the server's ignored `.env` or the hosting provider's secret environment:

```dotenv
STREAM_API_KEY=<Stream app API key>
STREAM_API_SECRET=<Stream app secret; server only>
GOOGLE_APPLICATION_CREDENTIALS=<absolute path to Firebase service-account JSON>
```

Alternatively, use the existing `FIREBASE_SERVICE_ACCOUNT_JSON` environment variable. The service account must belong to the same Firebase project as the app and have Firebase Authentication and Firestore access. An emulator-only `demo-project` Admin instance cannot verify real app sign-ins. Never bundle the Stream secret or service-account file in Flutter assets, Dart defines, Git, or the APK.

The supplied Stream credentials were saved only to the local ignored `server/.env`. The supplied Firebase Admin key is configured there by local file path for project `kolkata-puja-2026`; the key was not copied into the app. A live integration check verified Firebase sign-in, private Stream call access and denial after membership removal, then cleaned up its temporary records. For production use HTTPS, set `ALLOWED_ORIGIN` for any web build, and keep the secrets in your hosting provider.

From `server/`:

```powershell
npm.cmd install
npm.cmd run build
npm.cmd run test:video
npm.cmd run configure:video
npm.cmd start
```

`configure:video` validates the credentials and creates/updates the dedicated `uma_squad` call type. Regular, anonymous and guest roles have no call grants. Only a call token grants the `call_member` permissions to read/join/send audio/video. Other Stream call types are not changed. The endpoint also ensures this configuration on its first request; no manual dashboard permission edits are required.

Tokens expire after five minutes. The Flutter token loader rechecks group membership through the endpoint before renewing them. No permanent Stream membership is created. Firestore membership and Firebase auth listeners leave the call on removal/sign-out. A disconnected or modified client can retain the already-issued token until expiry; instantaneous server-side revocation of active media would require a membership-change webhook/trigger.

Room IDs include the Firestore document creation timestamp, so recreating an old invite code cannot grant access to its old room.

## App/server connection

### Free Render hosting

`render.yaml` defines the `uma-group-calling` free Node web service. It builds only `server/`, uses Node 22 and checks `/health`. In Render, connect this GitHub repository and deploy the Blueprint from the branch containing the calling implementation. Set `STREAM_API_KEY`, `STREAM_API_SECRET` and `FIREBASE_SERVICE_ACCOUNT_JSON` as private service environment variables. The last value is the entire Firebase Admin JSON file, not its local Windows path. Do not put these values in the Blueprint or Git.

For manual setup: choose Web Service, Node, Free plan, root directory `server`, build command `npm ci && npm run build`, start command `npm start`, and Node version 22. The app's group membership stays in Firestore; the calling endpoint does not depend on the server's in-memory Neon demo store.

Render's free services sleep after 15 minutes of inactivity and can take about a minute to wake. The session request therefore allows 90 seconds. This free tier is suitable for hobby/testing use and has usage limits; it does not provide continuous production availability. See [Render's free-service documentation](https://render.com/docs/free).

Once the deployed HTTPS origin has been verified with an authenticated live test, build the release APK with `--dart-define=VIDEO_API_URL=https://your-service.onrender.com`. Do not publish a localhost-configured APK as an internet-ready video-calling release.

For a hosted backend, from `app/`:

```powershell
flutter run --dart-define=VIDEO_API_URL=https://your-server.example
```

`VIDEO_API_URL` defaults to the app's existing `NEON_API_URL`, then localhost for development. It is the backend origin, not the Stream endpoint. The backend returns the public Stream API key and a short-lived token, so no Stream secret is passed at build time.

For a USB-connected Android device and a local server:

```powershell
D:\src\android-sdk\platform-tools\adb.exe reverse tcp:8080 tcp:8080
flutter run
```

For an Android emulator without reverse forwarding, use `--dart-define=VIDEO_API_URL=http://10.0.2.2:8080`.

## Verification

From `app/`, run `flutter analyze`, `flutter test test/group_video_api_test.dart test/squad_chat_test.dart test/squad_screen_simplified_test.dart` and `flutter build apk --debug`. From `server/`, run `npm.cmd run build` and `npm.cmd run test:video`.

On two or more physical devices, sign in as different users and join the same group. Open the call on each device and verify video, microphone mute, camera off/on, speaker routing and leave/rejoin. Check camera/microphone permission denial, network interruption, sign-out, membership removal and foreground/background transitions. A different group's call must stay separate. Live media behavior needs this device check; automated tests verify API authentication, token scoping/expiry, membership denial and malformed responses.

## References

- [Stream Flutter video tutorial](https://getstream.io/video/sdk/flutter/tutorial/video-calling/)
- [Stream authentication and call tokens](https://getstream.io/docs/platform/authentication/)
- [Stream server call permissions](https://getstream.io/video/docs/api/calls/)
