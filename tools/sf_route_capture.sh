#!/usr/bin/env bash
# tools/sf_route_capture.sh <frac> <out.png> [flaguri snapshot in plus]
#
# O captura din masina pe San Francisco (Track25, indexul 17), cu camera REALA de joc (--gamecam:
# 10 m sus, 12,5 m spate, fov 68), copiata la <out.png>. Snapshot NU merge headless (cere
# fereastra), iar capturile se fac SERIAL: lacatul de GPU D:/GameDev/.render_lock e comun tuturor
# sesiunilor (memoria `capturile-nu-se-paralelizeaza`). Procesul e oprit doar de propriul timeout.
set -u
FRAC="$1"; OUT="$2"; shift 2
WT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT=/d/GameDev/Godot_v4.7-stable_win64_console.exe
LOCK=/d/GameDev/.render_lock
until mkdir "$LOCK" 2>/dev/null; do sleep 5; done
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
LOG=$(timeout 300 "$GODOT" --path "$WT" res://tools/snapshot.tscn -- --track=17 --frac="$FRAC" --gamecam "$@" 2>&1)
SRC=$(printf '%s\n' "$LOG" | sed -n 's/^SNAPSHOT: //p' | tail -1 | tr -d '\r')
if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
  printf '%s\n' "$LOG" | tail -20
  echo "CAPTURA ESUATA (frac $FRAC)"
  exit 1
fi
mkdir -p "$(dirname "$OUT")"
cp "$SRC" "$OUT"
echo "captura: $OUT"
