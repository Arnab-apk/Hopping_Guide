# UMA v0.1.9 — Adaptive directions and route pins

Directions for pandals, stations, food spots, toilets and group-member locations now compare connected walking, train, metro and car/taxi routes from the user's actual location. The itinerary selects the lowest estimated travel time among the calculated candidates. Turn off **Include car/taxi** to compare walking and public transport only. Starting directions refreshes the route from a fresh GPS fix.

Walking and driving navigation detect sustained deviations and recalculate from the user's new position, preserving the current destination and remaining pandal order. Fresh, accurate fixes, a confirmation interval and a cooldown prevent GPS jitter and duplicate compass updates from repeatedly rerouting. Failed updates retain the displayed route; cancelled navigation cannot be replaced by a late response.

Rail journeys monitor deviations from mapped tracks when reliable GPS is available. **Change route from here** provides an explicit way to replan after changing stations or transport. Underground GPS loss and approximate track geometry do not trigger speculative rerouting. A public-transport journey does not silently switch to a taxi during automatic rerouting.

Car/taxi directions use Mapbox's automotive traffic profile and automotive maneuvers, with pedestrian connectors when the mapped pickup/drop-off point differs from the destination. Train and metro ride times are network estimates, not live departure schedules. “Fastest” refers to supported routes calculated by the app, not a guarantee about service availability, road closures or taxi pickup time.

The itinerary and active navigation maps also restore the familiar numbered pandal pins, line-coloured metro icons including intermediate stations, and railway pins. Tap a pin to see its name.

Provider documentation: https://docs.mapbox.com/api/navigation/directions/

Android version: 0.1.9 (2007). Download `UMA-v0.1.9.apk`; `SHA256SUMS.txt` contains its checksum.

Validation: static analysis clean; full suite 362 passed, 4 skipped; live Chuchura–Behala comparison and public-transport connection checks passed. Signed release installed on a Motorola edge50; live GPS car/taxi guidance and numbered pandal pins verified on the device. Sustained detours, GPS-noise rejection, provider failures and cancellation are covered by automated navigation tests; no physical train or car journey was performed.
