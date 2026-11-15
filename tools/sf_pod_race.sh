#!/usr/bin/env bash
# Sonda 1d SF (podul rosu), plutonul: ProbeSfPod --mode=race, 8 masini, N seed-uri,
# P in paralel, JSON in <outdir> (agregat de tools/sf_pod_report.py).
#   bash tools/sf_pod_race.sh <outdir> <config> <scena> [args ProbeSfPod...]
#   config: mobil | fix | orb | static   (vezi antetul tools/probe_sf_pod.gd)
# Variabile: SEEDS (implicit 16), PAR (4), SECONDS_RACE (200).
# Fiecare proces e oprit doar de propriul `timeout` (niciodata dupa nume: pe
# masina ruleaza si alti agenti si editorul dezvoltatorului).
set -u
OUT="$1"; CFG="$2"; SCENE="$3"; shift 3
GODOT="${GODOT:-/d/GameDev/Godot_v4.7-stable_win64_console.exe}"
SEEDS="${SEEDS:-16}"; PAR="${PAR:-4}"; SECS="${SECONDS_RACE:-200}"
mkdir -p "$OUT"
export GODOT OUT CFG SECS SCENE
export EXTRA="$*"
seq 1 "$SEEDS" | xargs -P "$PAR" -I{} bash -c '
  timeout 900 "$GODOT" --headless --fixed-fps 60 --path . res://tools/ProbeSfPod.tscn -- --mode=race \
    --scene=$SCENE --config=$CFG --seed={} --seconds=$SECS --out="$OUT/s{}.json" $EXTRA \
    > "$OUT/s{}.log" 2>&1
  echo "seed {} gata: $(grep -h "=== SF POD" "$OUT/s{}.log")"'
