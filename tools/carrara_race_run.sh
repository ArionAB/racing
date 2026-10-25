#!/usr/bin/env bash
# ProbeRace pe pista goala Carrara (indexul 15), 8 masini, N seed-uri, P in paralel; logurile in <outdir>.
#   bash tools/carrara_race_run.sh <outdir> [--ai=7 ...]
# Variabile: SEEDS (implicit 16), START (primul seed, implicit 1), PAR (implicit 6), SECONDS_RACE (implicit 210).
# Rezumat: python3 tools/carrara_race_sum.py <outdir>
set -u
OUT="$1"; shift
GODOT="${GODOT:-/d/GameDev/Godot_v4.7-stable_win64_console.exe}"
SEEDS="${SEEDS:-16}"; START="${START:-1}"; PAR="${PAR:-6}"; SECS="${SECONDS_RACE:-210}"
mkdir -p "$OUT"
export GODOT OUT SECS
export EXTRA="$*"
seq "$START" $((START + SEEDS - 1)) | xargs -P "$PAR" -I{} bash -c '
  "$GODOT" --headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn -- \
    --mode=race --track=15 --ai=7 --seed={} --seconds=$SECS $EXTRA \
    > "$OUT/s{}.log" 2>&1'
echo "gata: $OUT"
