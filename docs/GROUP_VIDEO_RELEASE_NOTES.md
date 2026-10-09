# UMA v0.1.5 — Group video calling

Open Groups → Chat → Group video call to join the group's room. Supports multiple participants, camera on/off, microphone mute, camera switching, speaker controls and leave/rejoin.

Firebase sign-in and current group membership are checked on the server. Stream secrets remain on the server. Calls use private rooms and expiring membership tokens; sign-out or membership removal leaves the call.

Calls are foreground-only. Reopen the group to rejoin after moving the app into the background. Closed-app ringing is not included. The free Render server can take about a minute to wake after inactivity.

Validation: Flutter analysis passed; 348 Flutter tests passed, 2 skipped; 7 backend security tests passed. Live checks against the deployed server verified Firebase authentication, room privacy and membership-removal denial. Three independent WebRTC clients received audio and decoded video using synthetic camera/microphone feeds; mute, camera toggle and participant leave passed. The signed Android APK installed successfully on a Motorola edge 50. Physical camera quality and audio routing across multiple phones have not been tested.

Android version: 0.1.5 (2003). The APK connects to https://uma-group-calling.onrender.com. Download `UMA-v0.1.5.apk`; `SHA256SUMS.txt` provides its checksum. Existing Firebase sign-in and group membership are required.
