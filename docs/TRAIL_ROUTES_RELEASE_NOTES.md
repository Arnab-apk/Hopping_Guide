# UMA v0.1.8 — Connected trail directions

Group route and the active Trail button now open a map with the complete itinerary from the device location through the remaining pandals. Routes combine pedestrian streets, Kolkata Metro and suburban trains when the connected transit journey is faster. Boarding, direction of travel, alighting, transfers and the final walk appear in visit order.

After optimising or starting a group trail, **Get directions** prompts you to reach the next pandal. **Directions to next destination** starts in-app walking guidance to the first boarding station or directly to the pandal. At each alighting station, location confirmation continues the itinerary; street guidance then handles the transfer or final walk. A pandal is completed only after the destination leg. Completed or skipped stops stay outside the remaining optimisation order.

Street connections require real pedestrian directions with maneuvers; a missing route shows retry instead of a fabricated straight walking line. The actual starting location is retained for journeys into Kolkata. The Howrah corridor now extends to Bandel. Rail shapes use bundled OpenStreetMap track mapping; dashed rail sections identify missing or approximate geometry.

Ride times include estimated waits and transfers. This release does not provide live departures, disruption notices or guaranteed service availability; check station service information. Roads are pedestrian routes, not driving navigation.

Android version: 0.1.8 (2006). Download `UMA-v0.1.8.apk`; verify using `SHA256SUMS.txt`.

Validation: Flutter analysis passes; 356 tests pass (four skipped). Separate live-provider checks pass for Chuchura ? Suruchi Sangha and Chuchura ? Behala Club, including connected street maneuvers, suburban train, metro and transfers. The signed APK installed as version 0.1.8 / build 2006 on the connected Motorola phone. Its nine-stop group itinerary shows a train + metro first journey and walking guidance to Chuchura station starts with live GPS. Arrival progression is covered by automated tests; an actual train journey was not performed.

Sources: [Mapbox pedestrian directions](https://docs.mapbox.com/api/navigation/directions/), [Kolkata Metro system map](https://mtp.indianrailways.gov.in/view_section.jsp?backgroundColor=LIGHTSTEELBLUE&fontColor=black&id=0%2C2%2C630%2C659&lang=0), [OpenStreetMap data licence](https://www.openstreetmap.org/copyright).
