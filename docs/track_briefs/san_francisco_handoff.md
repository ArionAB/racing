# San Francisco (Track25) — handoff for the next session

Updated 15 Nov 2026, at the end of the session that did step 7 (hero assets).
Read this first, then the brief (`docs/track_briefs/san_francisco.md`; §7 is the
step plan, and "pasul 7" there has the full results). Project rules are in
`CLAUDE.md`; the running memory is `san-francisco-track-project.md` in the
auto-memory folder.

## Where things stand

In `main`: #723 (the route), #724 (cable cars as `BusHazard`), #733 (B200 loop
over the drivable red bridge), #735 + #738 (step 6: switchbacks, pontoon, parked
cars, petals), #739 (asset sheet, briefs).

**Step 7 is in two open PRs** (worktree `D:/GameDev/wt-sf-pas7`; `verify_local` OK, 80 steps, on each):
**#740** `sanfrancisco/pas7-hero` (cable car, bridge, barrier machine) and **#741**
`sanfrancisco/pas7b-case` (the house kit; cut from #740's branch, so it contains it). Neither
is merged; the developer merges.

| Piece | State |
|---|---|
| `vehicles/cable_car.glb` | in game on both trams; AABB exactly 2.50 × 3.20 × 8.50 |
| `structures/sf_bridge_*.glb` (9 pieces) | in game: 110 instances under `DecorManual/Pod`, no collision of their own |
| `vehicles/sf_median_truck.glb`, `props/sf_median_block.glb` | in game through the new `truck_model` / `block_model` exports of `MovableMedianHazard` |
| `buildings/sf_row_b_canted.glb` (house pilot) | v1 (in `pas7-hero`) read as a white house; **v2 accepted on branch `sanfrancisco/pas7b-case`**: pastel 39.8 % of house pixels on `SfLoc` (v1 17.5 %, code houses 31 %), with a truly mirrored `_m` variant |

Track25 = San Francisco, B200 loop, ~2,571 m, lap ~82.8 s with 8 AI. The
developer's feel test of the B200 loop, step 6 and step 7 is deferred to the end
of step 8. No iOS build since #723 (build 54) — **start one only when they ask.**

## Step 7 numbers (8 cars × 16 seeds × 250 s, all models in)

- lap 82.83 s; tram 1 contact 1.7 % (band 1.3–3.2), tram 2 2.8 % (band 2.1–5.5);
- bridge: 0 crossings over the divider, 0 head-ons in the corridor;
- **barrier contact 6.7 %, above the step-2b band (4.6–5.5 %)** — but the control
  batch with the placeholder divider gave 6.1 %, so it is not the models. The band
  predates step 6. Watch it.
- `probe_decor --track=25`: **17 materials** (was 26; cap 38). `ProbeLaneClear
  --track=17`: 50 (baseline).

## Next steps

1. **Put the house kit on Track25.** All seven houses, each with a truly
   mirrored `_m` file, are done and accepted on `sanfrancisco/pas7b-case`
   (14 GLBs; mixed kit on `SfLoc --glb=kit`: pastel 40.3 % of house pixels,
   ΔV 0.349, ΔE 15.0, 16 materials). They are on no track yet. Rules measured
   at the kit (brief §7 "Kitul complet"):
   - mixing rule `KIT_SEQ` from `tools/sf_loc_decor.gd` (family changes at every
     neighbour); the other hand uses the `_m` file, never `scale.x = −1`;
   - **corner turrets cost sun on the chain** (85.4 % → 81.4 %, threshold 80 %):
     place them only at the downhill end of a row or on the east side of the
     N–S streets, and re-measure with `ProbeSfLight` before street trees (V4);
   - facades A/B/C look alike below the roofline, and A and C are hard to tell
     apart from the chase camera — a lever if the rows read repetitive.
2. **Step 8 — kits, background, set dressing, sound.** Waves 2 and 3 are in
   `docs/asset_briefs/sanfrancisco_inventory.md` §6. Code that step 8 needs,
   found at the pilot:
   - `CityFill._templates()` knows two wall tints; it needs N variants keyed on
     `WorldProp.WALL_CLASS_META`, and it must use the `_m` meshes for the
     mirrored hand (a `scale.x = −1` instance renders inside-out in a MultiMesh);
   - `WorldProp.PROP_COLLISION` needs `sf_row_*: "none"` once the generator
     writes the facade-plane collision box (the default hull puts an invisible
     wall in front of the garage);
   - the front rows are `DecorManual` nodes written by `tools/gen_sf_route.py`
     (floor at the pavement level of the UPPER end + kerb 0.15, as in
     `tools/sf_loc_decor.gd --glb`).
3. Still grey on the bridge: the soft walls in the S-bends (`Pod/CapS`).
4. Then `probe_decor`, the final read test and the developer's verdict at the wheel.

## How step 7 was built (reuse it)

- **Blender runs headless on this machine**: `D:/Blender/blender.exe --background
  --factory-startup --python tools/blender/run_build.py -- build_sf_<x>.py`. The
  modelling was done by Opus builders, one per brief, each with its own
  `build_sf_*.py` / `preview_sf_*.py`; the coordinator judged the renders next to
  the per-piece crops (`docs/track_briefs/img/sf_assets_v1/`, made by
  `tools/blender/crop_sf_sheet.py` — all 48 pieces of the sheet are already cropped).
- `bash tools/blender/verify_sanfrancisco.sh`: verify_glb with the declared
  exceptions + `measure_sf_bridge.py` (bridge clearance) + `measure_sf_gabarit.py`
  (the boxes physics reads). Both guards have a sabotage selftest.
- `tools/gen_sf_route.py` links a GLB only if the file exists. `SF_PAS7=0`
  reproduces the step-6 scene; `SF_POD_MODEL=0`, `SF_TRAM_MODEL=0`,
  `SF_MEDIAN_MODEL=0` switch one family off (for A/B).
- Captures used: `--track=17 --gamecam` at `--frac=0.995` (grid), `0.022` (deck,
  machine), `0.06` (under the tower), `--frac=0.2025 --bus-at=26` (tram 1).
- House measurement: `bash tools/sf_loc_pilot_runs.sh` (see its header), stats in
  `tools/sf_loc_stats.py` (section 5 = pixel share per class).

## Decisions already made (do not re-litigate)

- Golden hour, **no fog/weather**; the red bridge is never called by its real
  name ("podul roșu" / "the red bridge"); no real-bridge silhouette.
- B200 loop; traffic on the bridge drives on the LEFT; backlight on the climb
  south stays, sun not rotated — re-judge with the painted houses (step 8).
- Parked cars: 70 kg, `max_footprint` 4.5 m, none on the road, none in the
  first 45 m after a crest. The van goes in through `max_height`.
- Pontoon: posts from x 52 every 6 m (none on the first 12 m) — keep.
- The house at the switchback entrance stays 4 m back; a front garden (N2) goes there.
- Petals on hydrangeas: yes (done). Five pastels: **one model per house,
  recoloured in code** (done for `WorldProp`: metadata `wall_class`).
- Clock tower: **dropped**. Painted ladies: north side of the ridge arm, facing south.

## Coordinator's calls in step 7 — the developer has not seen these yet

- **Cable car roof is cream** with a red clerestory and ends (the brief), not red
  as on the sheet: from the chase camera a red roof over a red body read as one
  blob. One-line switch: `ROOF_SLOT` in `tools/blender/build_sf_cable_car.py`.
- **The barrier machine is the brief's low two-cab machine with a tunnel**, not
  the ramp lorry of the sheet; side-on it looks a bit like a locomotive.
- **The bridge tower is slender** (3 × 3 m legs, the size of their collision
  boxes), not massive as on the sheet; in game only its lower part is ever in frame.
- The red steel carries the world material's detail layer and looks like painted
  toy wood. No "painted steel" class was added (+1 material if wanted).
- **House pilot v2 puts the ground storey on pastel**, where the sheet shows
  stone. Reason: measured pastel share (17.5 % vs 31 %) and the wavy detail
  texture on the big stone faces. The stone storey stays a parameter in
  `build_sf_row.py`.

## Open / watch

- Barrier contact on the bridge 6.1–6.7 % vs the 4.6–5.5 % band (above).
- **Petals are subtle** (8 flakes of 0.42 m, the shared `PropDebris` limit). The
  developer was offered a bigger dedicated burst; no answer yet.
- Pontoon: 0.52 % of passes fall in (x 49–54, where the streams merge); accepted.
- A tipped tall prop (layer 9) is invisible to suspension rays, the camera and
  the respawn search.
- Theme haze (`fog_max` 0.55, almost white) reads as fog; the far shore behind
  the bridge is washed out. Reduce when the horizon ring goes in.
- Not measured: iPhone cost of the 42 parked-car bodies and of the bridge kit
  (`ProbePerf --attrib`); light on the jump chain once street trees (V4) are
  placed (`ProbeSfLight`, ≥ 80 %).

## Tools and gotchas

- **Never hand-edit `Track25.tscn`**: regenerate with `python tools/gen_sf_route.py`
  (`SF_ROUTE_DRY=1` for a dry run; `SF_OUT=...` writes another file;
  `SF_LAYOUT=vechi` is the old loop). **Do not regenerate while a ProbeRace batch
  is running** — the batch reads the scene per seed.
- Track indices differ per tool: ProbeRace via `tools/sf_route_race.sh` needs
  `--track=Track25`; ProbeLayout / ProbeLaneClear / snapshot use `--track=17`;
  `probe_decor` and `probe_manual` use `--track=25`.
- Baselines: ProbeLaneClear 50 (sabotage 53); `probe_decor --track=25` 17
  materials (cap 38); ProbeSfRoute −0.29 m (contract ≥ −0.30).
- SF probes: `probe_sf_crest`, `ProbeSfPonton`, `ProbeSfParked`, `ProbeBumpTall`,
  `ProbeSfPetals`, `ProbeSfLoc`, `probe_sf_watch` + `sf_route_report.py`,
  `sf_tram_report.py`.
- Jolt is nondeterministic: compare distributions (8 cars × 16 seeds × 250 s).
- Captures and Blender renders need the shared GPU lock
  (`mkdir D:/GameDev/.render_lock` … `rmdir`); captures need a **window** and run serially.
- `verify_glb.py --front=-Z` calls the largest face plane "the front", so it fails
  on anything longer than wide (wagon, machine, deep house). Don't use it there.
- Builders sharing one worktree: unique helper-script names in the scratchpad
  (one overwrote another's `render.sh`), commit only own paths with a pathspec.
- Godot binary: `/d/GameDev/Godot_v4.7-stable_win64_console.exe` (not on PATH).
- **Stop Godot only by your own PID** — never `taskkill /IM`. **Never `git stash`.**
- Work in a worktree cut from `main`, never in the main checkout. Before any
  merge: `bash tools/verify_local.sh` with main merged in. Merges only via PR.
  CI on GitHub is manual-only; don't trigger workflows or push `ios/**`.
- The old SF worktrees (`D:/GameDev/wt-sf-*` other than `wt-sf-pas7`) are stale.
- Builders run as `Agent(model: "opus")`; judgement stays with the coordinator.
