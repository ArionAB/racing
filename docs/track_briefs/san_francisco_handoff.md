# San Francisco (Track25) — handoff for the next session

Updated 15 Nov 2026, at the end of the session that took the track from "not in
main" to step 6 done and the asset sheet accepted. Read this first, then the
brief (`docs/track_briefs/san_francisco.md`, §7 is the step plan). Project rules
are in `CLAUDE.md`; the running memory is `san-francisco-track-project.md` in the
auto-memory folder.

## Where things stand

Everything is in `main`, nothing is open:

| PR | What |
|---|---|
| #723 | Track25 itself (the route; #712 had merged into a stale base by mistake) |
| #724 | step 5: the two cable cars (`BusHazard`), A/B on ProbeRace; Track25 in the Quick Race guard |
| #733 | B200: the loop rebuilt around the drivable red bridge, two-way with a moving divider (`MovableMedianHazard`), start/finish on the far-shore end |
| #735 | step 6: brick switchbacks + hydrangeas, wooden pontoon on the north quay, 42 parked cars, bay water fixed |
| #738 | step 6b: `BumpProp` `opts["max_height"]`, hydrangea petals |
| #739 | asset sheet v0.2, diorama, inventory sheet, 4 Blender briefs (docs only) |

Track25 = San Francisco, B200 loop, ~2,571 m, lap ~82.6 s with 8 AI.
The developer drove it on iPhone after step 4 ("game feels nice"). **Their feel
test of the B200 loop and step 6 is deferred to the end of step 8.** No iOS
build since #723 (build 54) — **start one only when they ask.**

## Next steps (brief §7)

**Step 7 — hero assets.** The modelling is done by the Blender agent from the
self-contained briefs; this session integrates. Delivery order (inventory §6):

1. `docs/asset_briefs/sf_cable_car.md` → `cable_car.glb`. The consumer is ready:
   `BusHazard` takes a one-body model with `model_yaw` (inventory §1.1); the AABB
   must be exactly 2.5 × 3.2 × 8.5 m. Two instances (tram 1 on B, tram 2 at the
   switchback mouth) plus a static one on the turntable (H4).
2. `docs/asset_briefs/sf_red_bridge.md` (in parallel): a kit of 7–9 GLBs.
   **Nothing loads it today** (inventory §1.6): the generator must place
   `Pod/Model` pieces with `coliziune = none` over the existing deck. Includes
   `sf_bridge_walkway_8` (decided: yes).
3. House-kit pilot: `sf_row_b_canted` only, measured on `SfLoc.tscn` before the
   other six are ordered (`sf_painted_row_kit.md` §9). `CityFill row_mode` only
   partly handles slopes with plinths (inventory §1.2); mirroring by scale −1 in
   the MultiMesh is unverified (§7).
4. `sf_median_truck.md` any time — but `MovableMedianHazard` has no model
   exports yet (inventory §1.5: code missing).

Give the Blender agent the brief plus `docs/asset_briefs/img/sf_route/sf_inventar_v01_a.jpg`
(and `sf_inventar_v01_b_chiparosi.jpg` for the cypresses). The bridge in the
diorama is too close to the real one: **the brief, not the diorama, is the
reference for the tower shape.**

**Step 8 — kits, background, set dressing, sound**, then `probe_decor`, the
final read test and the developer's verdict at the wheel. Waves 2 and 3 are
listed in inventory §6.

## Decisions already made (do not re-litigate)

- Golden hour, **no fog/weather**; the red bridge is never called by its real
  name ("podul roșu" / "the red bridge"); no real-bridge silhouette.
- B200 loop; traffic on the bridge drives on the LEFT; backlight on the climb
  south stays, sun not rotated — re-judge with the painted houses (step 8).
- Parked cars: 70 kg, `max_footprint` 4.5 m, none on the road, none in the
  first 45 m after a crest. The van goes in through `max_height`.
- Pontoon: posts from x 52 every 6 m (none on the first 12 m) — keep.
- The house at the switchback entrance stays 4 m back; a front garden (N2) goes there.
- Petals on hydrangeas: yes (done).
- Five pastels: **one model per house, recoloured in code**.
- Clock tower: **dropped**.
- Painted ladies: north side of the ridge arm, facing south (option b).

## Open / watch

- **Petals are subtle** (8 flakes of 0.42 m, the shared `PropDebris` limit). The
  developer was offered a bigger dedicated burst; no answer yet.
- Tram 2 contact rose from 2.4% to 4–5% after step 6.
- Pontoon: 0.26–0.52% of passes fall in, all at x 49–54 where the reunion
  streams merge; accepted.
- A tipped tall prop (layer 9) is invisible to suspension rays, the camera and
  the respawn search: the camera can pass through it, a car can respawn next to it.
- Theme haze (`fog_max` 0.55, almost white) reads as fog from crest 1 — reduce
  when the horizon ring goes in.
- Not measured: iPhone cost of the 42 parked-car bodies; light on the jump chain
  once street trees (V4) are placed (`ProbeSfLight`, ≥ 80%).

## Tools and gotchas

- **Never hand-edit `Track25.tscn`**: regenerate with `python tools/gen_sf_route.py`
  (`SF_ROUTE_DRY=1` for a dry run; `SF_LAYOUT=vechi` is the old loop).
- Track indices differ per tool: ProbeRace via `tools/sf_route_race.sh` needs
  `--track=Track25` (17 is ambiguous with scene Track17 = Jodhpur);
  ProbeLayout / ProbeLaneClear / snapshot use `--track=17`; `probe_decor` and
  `probe_manual` use `--track=25`.
- Baselines: ProbeLaneClear 50 (sabotage 53); `probe_decor --track=25` 26
  materials (cap 38); ProbeSfRoute −0.29 m (contract ≥ −0.30).
- SF probes: `probe_sf_crest`, `ProbeSfPonton` (`--side=1` sabotage, `--fall`),
  `ProbeSfParked`, `ProbeBumpTall`, `ProbeSfPetals`, `probe_sf_watch` +
  `sf_route_report.py`.
- Jolt is nondeterministic: compare distributions (8 cars × 16 seeds × 250 s), not one run.
- Captures need a **window** (not `--headless`) and run serially.
- Godot binary: `/d/GameDev/Godot_v4.7-stable_win64_console.exe` (not on PATH).
- **Stop Godot only by your own PID** — never `taskkill /IM`, it kills the
  developer's editor and other agents. **Never `git stash`** (shared across worktrees).
- Work in a worktree cut from `main`, never in the main checkout. Before any
  merge: `bash tools/verify_local.sh` with main merged in. Merges only via PR.
  CI on GitHub is manual-only; don't trigger workflows or push `ios/**`.
- The 11 old SF worktrees (`D:/GameDev/wt-sf-*`: brief, 1b, 1c, loc, route,
  tram, pod, podplan, podtraseu, pas6, assets) are all stale — their work is in
  main or was absorbed by #733. Cut the next branch from `main`. `wt-sf-assets` has `main` as
  upstream — push from it only with `git push origin HEAD:refs/heads/<branch>`.
- Builders run as `Agent(model: "opus")`; judgement stays with the coordinator.
