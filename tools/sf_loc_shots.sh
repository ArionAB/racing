#!/usr/bin/env bash
# tools/sf_loc_shots.sh [flaguri sonda]  — cadre din camere date pe strada testului de loc
# (`--shot=nume:px,py,pz:tx,ty,tz[:fov]`, vezi tools/probe_sf_loc.gd), CU fereastra, pe lacatul
# de GPU comun. Iesirea: snapshots/sf_loc_shot_<nume>.png. Pasul 7 (pilotul kitului), de ex.:
#   bash tools/sf_loc_shots.sh --glb --mirror-test "--shot=oglinda:123.5,m9,14:123.5,m5,-16:70"
#   bash tools/sf_loc_shots.sh --glb "--shot=soclu:5,r2,-26:10.5,r1.5,5:60"
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT=/d/GameDev/Godot_v4.7-stable_win64_console.exe
LOCK=/d/GameDev/.render_lock
until mkdir "$LOCK" 2>/dev/null; do sleep 5; done
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
timeout 420 "$GODOT" --path "$ROOT" res://tools/ProbeSfLoc.tscn -- "$@" 2>&1 \
  | grep -E "^SfLoc: shot|test oglinda|SCRIPT ERROR|wall_class" | tr -d '\r'
