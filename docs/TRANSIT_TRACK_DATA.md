# Transit track data

`app/assets/data/transit_track_shapes.json` is derived from OpenStreetMap contributors, licensed under [ODbL 1.0](https://opendatacommons.org/licenses/odbl/1-0/). The original Overpass response is retained in `scripts/data/transit_osm_source.json` for reproducible generation. It covers latitude 22.35–22.98, longitude 88.20–88.56, queried on 2026-10-10 with:

```overpass
[out:json][timeout:45];
(way[railway=rail](22.35,88.20,22.98,88.56);
 way[railway=subway](22.35,88.20,22.98,88.56););
out body geom;
```

Run `node scripts/build_transit_shapes.cjs` from the repository root to regenerate the bundle using the ordered station repositories. The generator ignores yards, sidings and spurs, snaps station anchors within 350 m to connected track nodes, and bounds the search length. Short station-anchor links account for platform access and mapping offsets. This is a geometric track snapshot, not a live service feed or a timetable.

The bundle currently has 85 mapped adjacent-station sections and 17 unmapped sections. The planner marks any ride containing an unmapped section as approximate and renders it dashed. Walks to stations, between stations and to pandals come from the pedestrian directions provider, never from this track graph.

The map credits OpenStreetMap contributors. Keep attribution and this source/licence record when distributing derived track data.
