#!/usr/bin/env bash
# Ruleaza ProbeCarrara pe N seed-uri, P in paralel, JSON in <outdir>.
#   bash tools/carrara_sonda_run.sh <outdir> <config> [--scene=...] [--apex=0] ...
# Variabile: SEEDS (implicit 16), PAR (implicit 3), SECONDS_RACE (implicit 200).
set -u
OUT="$1"; CFG="$2"; shift 2
GODOT="${GODOT:-/d/GameDev/Godot_v4.7-stable_win64_console.exe}"
SEEDS="${SEEDS:-16}"; PAR="${PAR:-3}"; SECS="${SECONDS_RACE:-200}"
mkdir -p "$OUT"
export GODOT OUT CFG SECS
export EXTRA="$*"
seq 1 "$SEEDS" | xargs -P "$PAR" -I{} bash -c '
  "$GODOT" --headless --fixed-fps 60 --path . res://tools/ProbeCarrara.tscn -- \
    --config=$CFG --seed={} --seconds=$SECS --out="$OUT/s{}.json" $EXTRA \
    > "$OUT/s{}.log" 2>&1
  echo "seed {} gata: $(grep -h "=== CARRARA" "$OUT/s{}.log")"'
