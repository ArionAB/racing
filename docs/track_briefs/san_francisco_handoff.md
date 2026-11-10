# San Francisco (Track25) — handoff for the next session

Written 10 Nov 2026 at the end of the session that picked the track, wrote the
brief and measured the jump chain on a synthetic test street. No part of the
real track exists yet. Read this first, then the brief. Project rules are in
`CLAUDE.md`; the running project memory is `san-francisco-track-project.md` in
the auto-memory folder.

## Where things stand

**One open pull request:** [#666](https://github.com/ArionAB/racing/pull/666),
`sanfrancisco/brief` → `main`. It touches only `docs/` and `tools/`. Nothing in
`scenes/`, nothing in `GameState.TRACK_SCENES`, no game code changed.

- It needs a human review to merge (branch protection; the author cannot
  approve their own PR).
- `bash tools/verify_local.sh` passed, 67 of 67 steps, on the first commit
  (`60c74d58`), with `main` up to date. The commits after it only edit the
  brief, add this file and add one test scene that nothing references; the
  suite was not rerun on them. `main` had not moved as of this writing. If it
  moves, bring it into the branch and rerun before merging.

**Worktree:** `D:/GameDev/wt-sf-brief`, on `sanfrancisco/brief`, with a working
`.godot` import cache. Continue from here, or cut the next branch from it. It
shows many untracked `*.png.import` files under `docs/`; they come from the
import step and must not be committed.

**Godot binary:** `D:/GameDev/Godot_v4.7-stable_win64_console.exe`.

## Decisions already made (do not re-litigate)

All four are the developer's, taken on 10 Nov 2026.

- **The track is San Francisco**, chosen over Wadi Rum → Petra and Iceland on
  the criterion "it has to be fun". The other two stay candidates for later.
- **Golden hour, no fog.** No fog weather and no fog hazard. The theme's thin
  distance haze stays (`fog_end` about 360, under `FAR_PLANE` 380), because the
  background rings would otherwise be cut at the far plane.
- **The shortcut is the crooked street**: the main road goes around the block
  on a wide boulevard, the shortcut dives down three tight brick hairpins, and
  a cable car crosses its mouth at the bottom.
- **The jump chain is four short blocks**, not three long ones. One block is
  24 m at a constant 28% grade, then a 17% and a 7% step to ease out: 48 m
  long, 9.6 m of drop. Blocks are separated by a 24 m flat intersection, so
  the edges are 72 m apart. In the generator this is the `plan28s` profile.

## What was measured

About 10,000 solo flights across ten block profiles, all ten garage cars, plus
pack runs of 8 cars × 8 seeds × 150 s. The full table is in the brief, §7
step 1a. The points that constrain future work:

- On the chosen block, every car flies off all four edges: 0.63 s of airtime
  at normal top speed (about 34 m/s), 0.82 s with turbo. Zero incidents in
  about 1,400 solo flights and in 1,020 pack flights.
- **Block shape decides safety.** Every ejection traced in the other profiles
  was the car touching the road surface in the concave part of the profile,
  where the slope bends into the flat. The rule: the car must land on the
  straight slope, with the bend after it. Do not change the block shape
  without rerunning the probe.
- Airtime grows almost linearly with grade (20% gives 0.38 s, 32% gives
  0.73 s). Below about 24% it is a hop, not a flight.
- Speed does **not** build along the chain; the speed cap holds every edge at
  about 34 m/s. Only turbo makes a jump longer.
- Intersections must be 24–36 m. At 12 m the ease-out of one block runs into
  the next edge and makes a small kicker.
- The AI drives the chain without braking.

## Key files

- Brief: `docs/track_briefs/san_francisco.md`. Camera checks §2.0, route and
  points of interest §2, hazards §3, palette and light §4, asset sketch §5,
  budgets and risks §6, build order with the measured results §7, rejected
  ideas and legal §8.
- `tools/gen_sf_sonda.py` — generates the synthetic test streets
  (`tools/SondaSf<Profile>.tscn`). Profiles and environment variables are in
  its docstring.
- `tools/probe_sf_crest.gd` + `tools/ProbeSfCrest.tscn` — measures every car
  over every edge: airtime, flight distance, height, landing speed, incidents.
- `tools/drive_scene.gd` + `tools/DriveScene.tscn` — lets a person drive any
  scene that is not in `TRACK_SCENES`. It restores the saved lap records every
  frame, so test laps cannot overwrite the developer's real records.
- Test streets kept in the PR: `SondaSfPlan28s` (the chosen block),
  `SondaSfPlan28` (60 m block), `SondaSfAngkor` (the Angkor ski-jump profile,
  for comparison), `SondaSfPlan28lX3` (three long blocks, the fallback).

Commands, run from the worktree:

```
python tools/gen_sf_sonda.py
D:/GameDev/Godot_v4.7-stable_win64_console.exe --headless --fixed-fps 60 --path . res://tools/ProbeSfCrest.tscn -- --scene=res://tools/SondaSfPlan28s.tscn --modes=14,22,max,t1,t3 --lats=0,-4,4
D:/GameDev/Godot_v4.7-stable_win64_console.exe --path . res://tools/DriveScene.tscn -- --scene=res://tools/SondaSfPlan28s.tscn
```

The third one opens a window. Options: `--ai=3`, `--car=N`, `--laps=N`.

## What is not done, in order

1. **The developer's feel verdict** on the chosen street, with `DriveScene`.
   The probe's test driver never makes a mistake and the street has no houses;
   it says the chain is safe, not that it is fun.
2. **Step 0** of the brief: the place and palette test.
3. **Probe 1b, the hairpins.** Three hairpins at radius 8 m on a 7 m road,
   next to a 270 m bypass. Radius 8 is tighter than anything measured in this
   project (Carrara's hairpins were radius 16 and had to be widened to 9 m for
   the AI), so this is the first thing likely to fail. The shortcut's time
   gain in the brief is an estimate until this runs.
4. **Probe 1c, the cable car.** A `BusHazard` going in the race direction up
   an 11.5% climb at 4.5 m/s. The contract is on `[blocaj]` and on the AI
   queue behind it, with a sabotage run (`ai_reads_lane` off must fail).
5. **The route**: `Track25.tscn` from a new `tools/gen_sf_route.py`, then the
   rest of the brief's build order (§7, steps 2–8).

## Open risks and traps

- **Turbo landings on the short block.** A turbo flight is 35–38 m and lands
  close to the bend of the 48 m block. Zero incidents in 200 turbo flights,
  but that is the sensitive spot. If the real track shows ejections there, the
  valid move is three 72 m blocks (a hill about 11 m taller, about 95 m more
  climb), not a different block shape. The 60 m block is not a fix: its turbo
  flights land exactly where its bend begins.
- `SondaSfPlan28lX3` has not been run through the probe as three blocks. The
  same block shape gave zero incidents in about 800 flights as a chain of four.
- The pack result comes from a bare test loop with no shortcut, no cable car
  and no corner before the chain. The pack verdict has to be repeated on the
  real track.
- Three things from the original pitch were wrong and the brief corrects them:
  Jodhpur's moving traffic is hard-wired (lane, speed, vehicle) and is not a
  cheap reuse; `TRAIN_ALONG` and `TrainHazard` cannot be the cable car;
  the bay is not visible from the first edge (it is about 355 m away), so the
  brief reveals water from the second edge and the island from the third.
- The palette has 32 slots and none is free. The brief stays inside it with
  one material class plus tints, and tints can only darken.
- When the track enters `TRACK_SCENES` its index will be 17. Most tools take
  the index or the scene number; `probe_decor` and `probe_manual` take only
  the scene number, 25.
- `GameState.track_scene_override` works only on the synchronous
  `Race._ready` path, which is why `DriveScene` changes scene directly.
- Jolt runs multithreaded: one ejection appeared in two runs and not in a
  third identical one. Compare distributions, never single runs.

## Housekeeping from this session

- The auto-memory index `MEMORY.md` was over its size limit and was regrouped
  into ten themed index files (`index-piste.md`, `index-fizica.md`, and so on).
  All 330 memories are kept; only the index layout changed.
- The memory `creasta-saritura-genunchi-concav.md` now carries the jump-chain
  findings, so they apply to any future jump on any track.
