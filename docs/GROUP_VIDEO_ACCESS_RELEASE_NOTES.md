# UMA v0.1.6 — Easier access to group video calls

The large **Group video call** button is now visible on every group tab. Open Groups and tap it directly, without switching to Chat. Standalone chat also has the same full-width button with a touch target at least 48 logical pixels high.

Tapping the button opens the group's existing lobby, where you choose camera on/off before joining. Firebase sign-in and group membership are still required.

Android version: 0.1.6 (2004). Download `UMA-v0.1.6.apk`; `SHA256SUMS.txt` provides its checksum. The APK uses https://uma-group-calling.onrender.com.

Validation: Flutter analysis passed with no issues; 19 relevant tests passed, including opening the call lobby directly from the Trail tab. The signed APK was installed and its button placement checked on the connected phone.

Calls are foreground-only. The free Render server may take about a minute to wake after inactivity. The previous release verified three-participant audio/video with synthetic feeds; physical media quality across multiple phones remains unverified.
