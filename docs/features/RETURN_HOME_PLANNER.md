# Return-home planner

Open **Routes → Get home**. Save a home metro/railway station, use current
location or choose a starting station, select the Kolkata operating date, and
set a boarding buffer (5–60 minutes per connection). Preferences stay on-device.
The existing journey planner supplies connected walking and transit legs.

## Schedule status

The bundled `app/assets/data/verified_transit_runs.json` intentionally contains
no departures. Official, station-specific, date-specific source material could
not be retrieved during implementation. Secondary reports and line operating
hours are insufficient to establish a boardable last service. The UI therefore
shows estimated routes with schedule-unverified messaging and no leave-by claim.

## Import contract

The manifest is an object with `schema_version: 1` and `runs: []`. Each run needs:

- `service`: `metro:<line.code>` or `train:<corridorName>` matching route models.
- `from`, `to`: exact metro station IDs or railway station codes, in direction.
- `service_date`: operator's Kolkata operating date, `YYYY-MM-DD`.
- `departure`, `arrival`: actual station-to-station departure/arrival instants,
  including `+05:30` or `Z`; post-midnight services use the next calendar date.
- `verified_at`, `valid_until`: offset-bearing verification and expiry instants.
- `source_url`: HTTPS official Indian Railways page or document.

Only add entries after checking the operator notice and station coverage.
Do not extrapolate intermediate-station departures from terminal closing times.
No synthetic examples are shipped in the production manifest. Tests use fixtures.

The checker works backwards from the latest covered final service, selects
connections that arrive before each boarding buffer, and subtracts transfer and
access walks. Missing coverage for any ride suppresses the whole leave-by result.
Published schedules and walking estimates are not live cancellation or crowd data.
Routes are currently the existing planner's preferred itinerary, not an exhaustive
schedule-aware search of all alternatives. Home addresses, final-pandal origins,
live updates, reminders and map navigation handoff remain follow-up work.

## Remaining requested increments

1. Obtain and review official timetable coverage; extend origins/destinations and
   alternative-route selection before calling verified return planning complete.
2. Structured theme, heritage and sourced award filters.
3. Fresh queue reports in route ordering.
4. Sourced bhog and ritual schedules.
5. More verified curated circuits.
6. Pandal submissions and correction moderation.
