#!/usr/bin/env bash
# ProbeRace pe San Francisco (Track25, indexul 17): 8 masini x N seed-uri x 250 s, cu observatorul
# --sf (lantul, scurtatura fata de ocol). Agregat: python tools/sf_route_report.py <outdir>.
#   bash tools/sf_route_race.sh <outdir> [argumente ProbeRace in plus]
# Variabile: SEEDS (16), PAR (4), SECS (250). Fiecare proces e oprit doar de propriul `timeout`
# (niciodata dupa nume: pe masina ruleaza si alti agenti si editorul).
set -u
OUT="$1"; shift
GODOT="${GODOT:-D:/GameDev/Godot_v4.7-stable_win64_console.exe}"
SEEDS="${SEEDS:-16}"; PAR="${PAR:-4}"; SECS="${SECS:-250}"
cd "$(dirname "$0")/.." || exit 2
mkdir -p "$OUT"
export GODOT OUT SECS
export EXTRA="$*"
seq 1 "$SEEDS" | xargs -P "$PAR" -I{} bash -c '
  timeout 1500 "$GODOT" --headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn -- \
    --mode=race --track=17 --ai=7 --seed={} --seconds=$SECS --sf $EXTRA > "$OUT/seed{}.log" 2>&1
  echo "seed {} gata: $(grep -h "TUR global" "$OUT/seed{}.log")"'
