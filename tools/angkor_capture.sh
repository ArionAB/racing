#!/usr/bin/env bash
# tools/angkor_capture.sh <worktree> <frac> <out.png> [flaguri snapshot in plus]
#
# O captura din masina pe Angkor (indexul 16), cu camera REALA de joc (--gamecam: 10 m sus, 12,5 m
# spate, fov 68; memoria `verifica-cu-parametrii-lui`), copiata la <out.png>.
# Snapshot NU merge headless (cere fereastra), iar capturile se fac SERIAL: lacatul de GPU
# D:/GameDev/.render_lock e comun tuturor sesiunilor (memoria `capturile-nu-se-paralelizeaza`).
set -u
WT="$1"; FRAC="$2"; OUT="$3"; shift 3
GODOT=/d/GameDev/Godot_v4.7-stable_win64_console.exe
LOCK=/d/GameDev/.render_lock
until mkdir "$LOCK" 2>/dev/null; do sleep 5; done
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
LOG=$(timeout 300 "$GODOT" --path "$WT" res://tools/snapshot.tscn -- --track=16 --frac="$FRAC" --gamecam "$@" 2>&1)
SRC=$(printf '%s\n' "$LOG" | sed -n 's/^SNAPSHOT: //p' | tail -1 | tr -d '\r')
if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
  printf '%s\n' "$LOG" | tail -20
  echo "CAPTURA ESUATA (frac $FRAC)"
  exit 1
fi
mkdir -p "$(dirname "$OUT")"
cp "$SRC" "$OUT"
echo "captura: $OUT"
