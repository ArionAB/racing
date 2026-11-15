#!/usr/bin/env bash
# Sonda 1d SF (podul rosu), contactul SOLO: masini x piloti x faze, cate o rulare
# de ProbeSfPod --mode=solo (un tur: trecerea pe DUS si pe INTORS), PAR in paralel.
#   bash tools/sf_pod_solo.sh <outdir> [scena] [config]
# Variabile: CARS (implicit toate 10: "0 1 2 3 4 5 6 7 8 9"), PILOTS ("hug line"),
# PHASES ("0.05 0.2 0.45 0.7"), PAR (4).
set -u
OUT="$1"; SCENE="${2:-res://tools/SondaSfPod.tscn}"; CFG="${3:-mobil}"
GODOT="${GODOT:-/d/GameDev/Godot_v4.7-stable_win64_console.exe}"
CARS="${CARS:-0 1 2 3 4 5 6 7 8 9}"; PILOTS="${PILOTS:-hug line}"
PHASES="${PHASES:-0.05 0.2 0.45 0.7}"; PAR="${PAR:-4}"
mkdir -p "$OUT"
export GODOT OUT SCENE CFG
for c in $CARS; do for p in $PILOTS; do for f in $PHASES; do
  echo "$c $p $f"; done; done; done | xargs -P "$PAR" -L 1 bash -c '
  timeout 300 "$GODOT" --headless --fixed-fps 60 --path . res://tools/ProbeSfPod.tscn -- --mode=solo \
    --scene="$SCENE" --config=$CFG --car=$0 --pilot=$1 --phase=$2 --out="$OUT/c$0_$1_f$2.json" \
    > "$OUT/c$0_$1_f$2.log" 2>&1
  grep -h "=== SF POD SOLO" "$OUT/c$0_$1_f$2.log"'
