# Live tracking and visit feedback

The default FlutterMap view animates received coordinates for the user's marker
and squad avatars. Each member has a stable marker identity. Animation lasts
250–1000 ms, adapts to the interval between observations, and starts from the
currently displayed point when interrupted. Large corrections (over 150 m) and
updates after a gap of over 20 seconds snap instead. Markers stop at the last
received coordinate; there is no prediction of a missing location.

The follow camera uses the animated user's position, except while an explicit
recenter/zoom animation is running. A drag cancels follow. Device direction uses
shortest-angle rotation and respects reduced-motion preferences. Squad markers
whose location sharing is disabled are hidden. Freshness colours reflect the
existing member freshness model when the squad layer rebuilds.

These animations run locally, add no API calls or dependencies, and do not alter
GPS permission, cloud publish frequency, routing providers, or map tile sources.
They apply to the default FlutterMap view; the optional Magic Lane view is unchanged.

## Recorded visits

Existing navigation arrival, journey completion, and custom-trail proximity logic
record visits. A custom trail checks only its current target, within 80 m, using
a GPS fix at most 10 seconds old and with accuracy at most 30 m. This is proximity
detection, not proof of entering a pandal, and has no dwell-time requirement.

The map now displays a success notice for the custom trail's auto-visit events.
Saved visits also mark individual directory pins after the trail ends. The
directory's Visited filter remains available. Saved visits contain IDs, not a
timestamped movement history. Background visit detection, all-pandal geofencing,
and visit review/confirmation have not been added.

## Free-tier boundaries

Local GPS and marker animation need no paid Maps API. Shared tracking still uses
network/backend resources. Firestore's published standard free quota is 20,000
document writes and 50,000 reads per day; listener updates consume reads.
For illustration, one write every 10 seconds is 360 writes per user-hour. A
five-member group listening to each other's updates can consume about 7,200
member-document reads per hour, before initial reads, security-rule reads, and
other app operations. This is an illustration, not the app's configured rate or
a guarantee of quota capacity. The existing publisher uses time and distance
thresholds, so rapid movement can produce more frequent writes.

The public OpenStreetMap raster service has best-effort availability and forbids
bulk offline downloads. Production capacity needs a suitable tile provider or
hosting arrangement. Current route-provider quotas also remain applicable.

Sources checked 2026-10-16:
- https://firebase.google.com/docs/firestore/pricing
- https://operations.osmfoundation.org/policies/tiles/
