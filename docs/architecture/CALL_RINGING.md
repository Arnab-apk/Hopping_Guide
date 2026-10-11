# Incoming group call ringing (Android)

Incoming calls use a native Android `CATEGORY_CALL` notification with the user's
default ringtone, `USAGE_NOTIFICATION_RINGTONE`, vibration, and `FLAG_INSISTENT`.
Android applies ring volume, ringer mode, Do Not Disturb, notification permissions,
and the user's Incoming calls channel settings. No media connection, full-screen
intent permission, or extra foreground service is started merely to ring.

The notification includes Answer and Decline actions. Answer stops the alert,
opens UMA, verifies the invitation from Firestore, and joins the group room.
Decline stops the alert and suppresses duplicate delivery of that invitation.
Alerts expire at the invitation's 60-second deadline. Caller hang-up writes the
end event and sends an authenticated cancellation push; local expiry also bounds
ringing if the cancellation cannot be delivered. Android may silence insistent
alerts when the notification shade is opened.

`CallPushReceiver` accepts broadcasts protected by Google's C2DM send permission.
It handles high-priority, data-only `group_call_ring` and `group_call_end` payloads.
Native state contains the signed-in user's current group IDs and ignores stale,
expired, handled, or busy-state invitations. Foreground Firestore invitations use
the same notification implementation, avoiding separate unconditionally played
sound or haptic effects.

New devices register `callRingTokens` alongside `callPushTokens`. The server sends
the new payload only to those devices; older installations retain ordinary FCM
notification delivery. Only current group members receive alerts. The caller's
identity and invitation ownership are checked for both invitation and end events.

Use normal notification actions rather than Android `CallStyle`: newer Android
versions require a foreground service, user-initiated job, or full-screen intent
for `CallStyle`, and otherwise reject the notification.

## Validation

- Flutter analysis: clean (`app/build/call_ringing_analyze_final.log`).
- Flutter suite: 439 passed, 5 skipped (`app/build/call_ringing_tests.log`).
- Server build and 11 video/notification tests: passed.
- Signed release build: 1.0.0, build number 2020 (arm64 version code 4020).
- Device validation uses the existing isolated UMA Call Verification group.
- Render service `uma-group-calling` has automatic deployment disabled; pushing
  `deploy/stream-group-video` must be followed by an explicit deploy.

Device verification and provider availability are recorded separately from unit
test results. Successful push delivery does not establish two-way media quality.
