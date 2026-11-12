#!/usr/bin/env bash
# Sonda 1c SF, plutonul: ProbeCarrara pe strada tramvaiului, 8 masini, N seed-uri,
# P in paralel, JSON in <outdir> (agregat de tools/sf_tramvai_report.py).
#   bash tools/sf_tramvai_race.sh <outdir> <config> <scena> [args ProbeCarrara...]
#   config: base (tramvaiul scos) | trucks (tramvaiul ramane)
# Variabile: SEEDS (implicit 16), PAR (3), SECONDS_RACE (200).
# Fiecare proces e oprit doar de propriul `timeout` (niciodata dupa nume).
set -u
OUT="$1"; CFG="$2"; SCENE="$3"; shift 3
GODOT="${GODOT:-/d/GameDev/Godot_v4.7-stable_win64_console.exe}"
SEEDS="${SEEDS:-16}"; PAR="${PAR:-3}"; SECS="${SECONDS_RACE:-200}"
mkdir -p "$OUT"
export GODOT OUT CFG SECS SCENE
export EXTRA="$*"
seq 1 "$SEEDS" | xargs -P "$PAR" -I{} bash -c '
  timeout 600 "$GODOT" --headless --fixed-fps 60 --path . res://tools/ProbeCarrara.tscn -- \
    --scene=$SCENE --config=$CFG --seed={} --seconds=$SECS --out="$OUT/s{}.json" $EXTRA \
    > "$OUT/s{}.log" 2>&1
  echo "seed {} gata: $(grep -h "=== CARRARA" "$OUT/s{}.log")"'
