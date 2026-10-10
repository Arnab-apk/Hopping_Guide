# UMA v0.1.7 — More map names

The map now defaults to a denser view of street, neighbourhood and landmark labels while keeping the same map position and zoom. Open **Map Tools & Options → More map names** to switch back to larger labels. Your choice is remembered after reopening the app.

The denser view uses finer OpenStreetMap tiles. Labels are smaller and more tiles are fetched; only names present in OpenStreetMap can appear. At the provider's maximum native zoom, no further map detail is available. Nearby tile buffering is reduced in this mode to limit extra requests and memory.

Pandal pins, routes, navigation and group video calling continue to use the same map coordinates.

Android version: 0.1.7 (2005). Download `UMA-v0.1.7.apk`; `SHA256SUMS.txt` contains its checksum.

Validation: Flutter analysis passed; eight map layout checks passed across phone, compact, landscape and large-text layouts in light/dark themes. The density toggle saves its choice without changing the camera center or zoom. Both rendering modes were visually checked on the connected phone, and the signed APK installed as build 2005.

Implementation reference: [flutter_map tile rendering documentation](https://docs.fleaflet.dev/layers/tile-layer).
