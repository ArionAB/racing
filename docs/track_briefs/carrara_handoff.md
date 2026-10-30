# Carrara (Track23) — handoff for the next session

Written 27 Oct 2026 at the end of the session that took the track from the
accepted diorama to wave 1 of the asset kit mounted on the track. Read this
first, then the files it points to. Project rules are in `CLAUDE.md`; the
running project memory is `carrara-track-project.md` in the auto-memory folder.

## Where things stand

**Open pull requests, stacked (merge in this order, none merged yet):**

| PR | branch → base | what |
|---|---|---|
| #586 | `carrara/kit-pilot` → `main` | kit harness (Blender build/preview/verify tools) + `quarry_truck.glb`; both Track23 trucks switched from the Baikal Kamaz to it (race A/B neutral) |
| #587 | `carrara/kit-val1` → `carrara/kit-pilot` | wave 1: 25 GLBs (hazard machines, viaduct and portals, the quarry kit) |
| #588 | `carrara/kit-montaj` → `carrara/kit-val1` | wave 1 mounted on Track23 from `tools/gen_carrara_route.py` + the kit's material classes in `CLASSES_CARRARA` |

All three passed `bash tools/verify_local.sh` (57 steps) with main up to date
on 27 Oct. If main moved since, bring it into the top branch and rerun before
merging. Merge each PR, then retarget the next one to `main`.

**Also unmerged:** `docs/carrara-brief` has 10+ commits that main lacks: brief
steps 1–5, section 9 (dioramas, prompts, results), the kit brief
`docs/asset_briefs/carrara_kit.md`, the per-piece crops, and this file. It
needs its own PR to main. The kit PRs do not contain the kit brief.

**Worktrees** (all siblings in `D:/GameDev/`):
- `wt-carrara-kit` — on `carrara/kit-montaj`, sparse without most of docs/,
  has a working `.godot` import cache. Use this one to continue.
- `wt-carrara-doc` — on `docs/carrara-brief`, sparse: only the Carrara brief,
  asset briefs, Carrara images and the crop tool.
- `wt-crr-a`, `wt-crr-b`, `wt-crr-c` — the three wave 1 builders' branches,
  already merged into `kit-val1`. Safe to remove (remove the worktree, keep
  the branches until the PRs merge). `wt-crr-a` has a copied `.godot` (1.7 GB).
- `wt-carrara` — the old track branch (`carrara/track`, merged as #582).

Disk D: had 27 GB free. Follow the memory `disc-plin-worktree-rar-cache-partajat`
for any new worktree (sparse, no docs, `MSYS_NO_PATHCONV=1`).

## Key files

- Track brief: `docs/track_briefs/carrara.md` (on `docs/carrara-brief`). POI
  table §2, hazards §3, palette §4, assets §5 (code contracts §5.6), build
  order §7, ChatGPT prompts and results §9.
- Kit contract: `docs/asset_briefs/carrara_kit.md` (on `docs/carrara-brief`).
- Kit state and every acceptance decision: `docs/asset_briefs/carrara_inventory.md`
  (on the kit branches), plus `carrara_inventory_crr-a.md`, `_crr-b.md`, `_crr-c.md`.
- Reference images: `docs/track_briefs/img/carrara_plan/` (accepted diorama
  `diorama_v01_iter2.jpg`, accepted sheet `inventar_v01_a.jpg`),
  per-piece crops in `docs/track_briefs/img/carrara_assets_v1/`.
- In-game captures of the mount: `docs/asset_briefs/img/carrara_montaj/`.
- Generator (single source of truth for Track23): `tools/gen_carrara_route.py`.
  Hand edits to `Track23.tscn` are lost on regeneration.

## Decisions already made (do not re-litigate)

- **Builders run on Opus** for this work (developer's request, 27 Oct). The
  standing rule elsewhere is Sonnet builders with an Opus/Fable coordinator.
- The diorama was accepted with E drawn too low: ChatGPT failed it twice, and
  heights come from Track23, not the diorama.
- Trucks come toward you (AI reads their lane; head-on contact does not
  eject). The excavator AI rolls a die per pass and gives up after one wait.
  The sled hit is the class's 3 s crush. The derrick stays on the left.
- Machines are faded yellow (palette slot 13) plus rust, never car yellow.
  Nothing on the track is white (no slot 22).
- Marble pieces use `carrara_marble`; the viaduct brick uses `ok_roof`
  (`roof_tiles` rendered almost white on this theme).

## Open issues, roughly by priority

1. **Excavator pushes cars through the road** at frac ~0.050. The car then
   drives under the track for a lap and hits the viaduct abutment. Found
   during the mount, not fixed. Look at `ExcavatorHazard` collision vs the
   car (arm box comes down to the ground).
2. **Excavator queue at the start** (known since step 5): 7–15 blockages per
   16-seed race series, all at the arm. The developer's "give up after one
   wait" rule helped but did not reach the contract.
3. **The excavator model** `quarry_excavator.glb` exists but is not loaded:
   `Track._build_excavator` hard-codes `rusted_digger.glb` and forces
   `rust_metal`. Code list item 1 in brief §5.6 (model/side/phase/class from
   the marker spec, defaults bit-identical).
4. **Sled chute has no slope**: the right-hand hillside at POI G is flat. Build
   the POI G relief (rubble slope), then regenerate the chute (~30°). The 2 s
   warning bell does not exist in code.
5. **`lizza_sled.glb` to redo**: reads as a crate on a pallet. Keep the
   2.4 × 2.4 m footprint (the sled probe fails at 2.6 m), lower the block to
   ~1.2–1.4 m, raise the runner tips.
6. **Hazard models skip the theme classes**: the derrick's hanging block, the
   sled and the truck's blocks get materials through `WorldProp.prop_classes()`,
   not `CLASSES_CARRARA`, so their marble is still on the raw atlas.
7. **Upper gallery mouth** (frac ~0.591) reads as a free-standing facade: the
   gallery massif is far from it.
8. Smaller: the container and fuel tank look striped on the atlas; the
   tipped block (POI D) waits for the 16 m hall, which was never built;
   `gallery_pillar` is deferred for the same reason.

## Next steps (pick with the developer)

- Review and merge #586 → #587 → #588, and open the PR for `docs/carrara-brief`.
- **Wave 2 of the kit** (kit brief §3): decorative machines (`wire_saw`,
  `chain_saw_crawler`, `drill_rig`), museum corner (3 GLBs), village
  (`colonnata_church`, 3 houses), `quarry_sign_block`, background
  `effects/carrara_horizon.glb`. Same method: one worktree and branch per
  builder from the latest kit branch, Opus, the coordinator reviews every
  comparison image, max 3 rounds per piece.
- Fix issues 1, 3 and 6 (code), then 4 and 5 (POI G relief + sled redo).
- Later: the POI art passes (brief §7 step 8) and the season test (brief §6).

## Working rules learned here

- Godot: `/d/GameDev/Godot_v4.7-stable_win64_console.exe`. Run `--headless --path . --import`
  after any asset change. Track index: `--track=15` for snapshot/ProbeRace,
  `--track=23` for probe_decor/probe_manual.
- Race A/B: `SEEDS=16 PAR=5 bash tools/carrara_race_run.sh <dir>` then
  `python tools/carrara_race_sum.py <dir>`. Compare distributions, and read
  where each blockage happens: "Autobuzul" in a log line is a garage car's
  name, not the truck hazard.
- Captures need a window: `--path . res://tools/snapshot.tscn -- --track=15 --frac=F --gamecam`
  or `--eye=x,y,z --look=x,y,z`. A free camera can end up inside or under the
  terrain, so check the image. Hold the GPU lock (`mkdir D:/GameDev/.render_lock`,
  `rmdir` after) for every render, Blender or Godot.
- Blender builds: `D:/Blender/blender.exe --background --factory-startup --python tools/blender/run_build.py -- build_crr_<group>.py`.
  Kit verdict: `bash tools/blender/verify_carrara.sh`. A green verdict is not
  acceptance: look at the comparison images.
- Git Bash rewrites leading-slash paths: use `MSYS_NO_PATHCONV=1` for
  sparse-checkout patterns. Never `git stash` (shared between worktrees).
- Opus builders burn the usage limit fast: three in parallel hit the session
  limit once. Resuming them with a message after the reset continued their
  work intact.
