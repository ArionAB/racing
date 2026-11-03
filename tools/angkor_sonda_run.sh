#!/usr/bin/env bash
# Ruleaza ProbeRace --angkor pe N seed-uri, P in paralel, log-uri in <outdir>.
#   bash tools/angkor_sonda_run.sh <outdir> <track_index>
# Variabile: SEEDS (implicit 16), PAR (implicit 4), SECS (implicit 150).
set -u
OUT="$1"; TRK="$2"
GODOT="${GODOT:-/d/GameDev/Godot_v4.7-stable_win64_console.exe}"
SEEDS="${SEEDS:-16}"; PAR="${PAR:-4}"; SECS="${SECS:-150}"
mkdir -p "$OUT"
export GODOT OUT TRK SECS
seq 1 "$SEEDS" | xargs -P "$PAR" -I{} bash -c '
  timeout 900 "$GODOT" --headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn -- \
    --mode=race --track=$TRK --seconds=$SECS --ai=7 --seed={} --angkor \
    --angkor-elephant=0.155,0.19 --angkor-crest=0.64,0.70 > "$OUT/s{}.log" 2>&1
  echo "seed {} gata"'
