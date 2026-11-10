#!/usr/bin/env bash
# Sonda 1b San Francisco: ruleaza in paralel loturile ProbeSfSerp.
#
#   bash tools/sf_serp_run.sh solo <dir_loguri>      # garajul, pe forme x ziduri
#   bash tools/sf_serp_run.sh race <dir_loguri>      # plutonul, 8 seed-uri x 150 s
#   python tools/sf_serp_sum.py <dir_loguri>/race_*.log
#
# Variabile: JOBS (procese Godot in paralel, implicit 4), SCENES, WALLS
# ("none" sau "off,h"), SEEDS. Fiecare proces Godot are `timeout` propriu: nu
# se opreste niciodata nimic dupa nume (pe masina ruleaza si alti agenti).
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-D:/GameDev/Godot_v4.7-stable_win64_console.exe}"
MODE="$1"
OUT="$2"
mkdir -p "$OUT"
JOBS="${JOBS:-4}"
WALLS="${WALLS:-none 1.0,1.5}"
jobs_file="$OUT/jobs_$MODE.txt"
: > "$jobs_file"
if [[ "$MODE" == solo ]]; then
  SCENES="${SCENES:-R8W7F R8W9F R10W7F R10W9F R12W7F R12W9F}"
  for sc in $SCENES; do
    for w in $WALLS; do
      wa=""; tag="${sc}_free"
      [[ "$w" != none ]] && wa="--walls=$w" && tag="${sc}_walls${w/,/_}"
      echo "timeout 3000 $GODOT --headless --fixed-fps 60 --path . res://tools/ProbeSfSerp.tscn -- --mode=solo --scene=res://tools/SondaSfSerp$sc.tscn --pilots=ai,pro,wide,line $wa > $OUT/solo_$tag.log 2>&1" >> "$jobs_file"
    done
  done
else
  SCENES="${SCENES:-R8W7F R8W7N}"
  SEEDS="${SEEDS:-1 2 3 4 5 6 7 8}"
  for sc in $SCENES; do
    for w in $WALLS; do
      wa=""; tag="${sc}_free"
      [[ "$w" != none ]] && wa="--walls=$w" && tag="${sc}_walls${w/,/_}"
      for s in $SEEDS; do
        echo "timeout 900 $GODOT --headless --fixed-fps 60 --path . res://tools/ProbeSfSerp.tscn -- --mode=race --scene=res://tools/SondaSfSerp$sc.tscn --seed=$s --seconds=150 $wa > $OUT/race_${tag}_s$s.log 2>&1" >> "$jobs_file"
      done
    done
  done
fi
echo "$(wc -l < "$jobs_file") procese, $JOBS in paralel -> $OUT"
tr '\n' '\0' < "$jobs_file" | xargs -0 -P "$JOBS" -I{} bash -c '{} || true'
echo "gata $MODE"
