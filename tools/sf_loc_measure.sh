#!/usr/bin/env bash
# tools/sf_loc_measure.sh — masuratorile testului de loc San Francisco (brief §7 pasul 0).
# Sonda CU fereastra (cadrele de masura cer randare), serializata pe lacatul de GPU comun
# (D:/GameDev/.render_lock), apoi statisticile. Optional: --sun=EL,AZ (vezi probe_sf_loc.gd).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT=/d/GameDev/Godot_v4.7-stable_win64_console.exe
LOCK=/d/GameDev/.render_lock
until mkdir "$LOCK" 2>/dev/null; do sleep 5; done
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
timeout 420 "$GODOT" --path "$ROOT" res://tools/ProbeSfLoc.tscn -- --frames "$@" 2>&1 \
  | grep -E "^SfLoc|^sf_loc|soare pe|materiale unice|SCRIPT ERROR" | tr -d '\r'
rmdir "$LOCK" 2>/dev/null
python "$ROOT/tools/sf_loc_stats.py"
