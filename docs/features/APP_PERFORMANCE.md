# Smoothness improvements

The existing visual design stays in place.

- LiveTrackingMarkerLayer supplies a TickerProvider to PositionInterpolator.
  Display interpolation follows Flutter's frame scheduler instead of a 33 ms
  periodic timer. TickerMode mutes markers on hidden tabs. Non-visual consumers
  retain the timer fallback. Raw GPS, routing and cloud coordinates are unchanged.
- Search reuses normalized strings in a bounded 4,096-entry cache and compiles
  normalization regexes once. Cache keys are source strings, so refreshed records
  receive updated search terms. Name splitting happens once per candidate.
- Directory filtering skips highlight spans it does not render.
- Directory cards use their existing staggered entrance without a second nested
  fade/slide animation. Other PlaceCard callers keep the default entrance.

## Measurements

`flutter test --no-pub test/search_performance_test.dart` exercises 100 warmed-up
queries across the real 338-pandal directory. On this development machine:

| Version | Total search time | Matches |
| --- | ---: | ---: |
| Before | 1,632 ms | 8,820 |
| After | 195 ms | 8,820 |

This is a local search benchmark, not an on-device FPS measurement. Device,
thermal conditions, maps and network requests affect real-world frame times.
Tests verify 16 ms marker progress, muted callbacks while hidden, retargeting,
reduced motion, stale GPS snapping, search relevance, and list interactions.
