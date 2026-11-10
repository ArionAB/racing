#!/usr/bin/env bash
# tools/sf_loc_capture.sh <out.png> [flaguri snapshot]
#
# O captura cu Snapshot (CU fereastra: randarea nu merge headless), serializata pe lacatul de
# GPU comun tuturor sesiunilor (D:/GameDev/.render_lock, memoria `capturile-nu-se-paralelizeaza`),
# copiata la <out.png>. Testul de loc San Francisco (brief §7 pasul 0):
#   tools/sf_loc_capture.sh out.png --scene=res://tools/SfLoc.tscn --frac=0.06 --gamecam --car
#   tools/sf_loc_capture.sh out.png --track=11 --frac=0.30 --gamecam --car
set -u
OUT="$1"; shift
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT=/d/GameDev/Godot_v4.7-stable_win64_console.exe
LOCK=/d/GameDev/.render_lock
until mkdir "$LOCK" 2>/dev/null; do sleep 5; done
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
LOG=$(timeout 420 "$GODOT" --path "$ROOT" res://tools/Snapshot.tscn -- "$@" 2>&1)
SRC=$(printf '%s\n' "$LOG" | sed -n 's/^SNAPSHOT: //p' | tail -1 | tr -d '\r')
if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
  printf '%s\n' "$LOG" | grep -v "^\s*$" | tail -20
  echo "CAPTURA ESUATA ($*)"
  exit 1
fi
mkdir -p "$(dirname "$OUT")"
cp "$SRC" "$OUT"
printf '%s\n' "$LOG" | grep -E "^snapshot: (pista|scena)|^RENDER" | tr -d '\r'
echo "captura: $OUT"
