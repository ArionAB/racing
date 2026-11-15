#!/usr/bin/env bash
# tools/sf_pod_capture.sh <scena> <frac> <out.png> [flaguri snapshot in plus]
#
# O captura cu camera REALA de joc (--gamecam) pe strada sintetica a podului rosu
# (sonda 1d SF). Snapshot NU merge headless (cere fereastra); capturile se fac
# SERIAL, prin lacatul de GPU comun D:/GameDev/.render_lock (memoria
# `capturile-nu-se-paralelizeaza`). Procesul e oprit doar de propriul timeout.
set -u
SCENE="$1"; FRAC="$2"; OUT="$3"; shift 3
WT="$(cd "$(dirname "$0")/.." && pwd)"
GODOT="${GODOT:-/d/GameDev/Godot_v4.7-stable_win64_console.exe}"
LOCK=/d/GameDev/.render_lock
until mkdir "$LOCK" 2>/dev/null; do sleep 5; done
trap 'rmdir "$LOCK" 2>/dev/null' EXIT
LOG=$(timeout 300 "$GODOT" --path "$WT" res://tools/snapshot.tscn -- --scene="$SCENE" --frac="$FRAC" --gamecam "$@" 2>&1)
SRC=$(printf '%s\n' "$LOG" | sed -n 's/^SNAPSHOT: //p' | tail -1 | tr -d '\r')
if [ -z "$SRC" ] || [ ! -f "$SRC" ]; then
  printf '%s\n' "$LOG" | tail -20
  echo "CAPTURA ESUATA (frac $FRAC)"
  exit 1
fi
mkdir -p "$(dirname "$OUT")"
cp "$SRC" "$OUT"
echo "captura: $OUT"
