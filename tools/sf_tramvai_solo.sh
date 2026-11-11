#!/usr/bin/env bash
# Sonda 1c SF, contractul 2 (contact moale): masini x moduri x {cu, fara}
# tramvai, cate o rulare de ProbeSfTramvai, PAR in paralel. Fiecare proces e
# oprit doar de propriul `timeout` (niciodata dupa nume: pe masina ruleaza si
# alti agenti si editorul).
#   bash tools/sf_tramvai_solo.sh <outdir> [scena]
# Variabile: CARS (implicit "1 0 5 3"), MODES ("rear corner side"), REPS (1), PAR (4).
set -u
OUT="$1"; SCENE="${2:-res://tools/SondaSfTramvai.tscn}"
GODOT="${GODOT:-/d/GameDev/Godot_v4.7-stable_win64_console.exe}"
CARS="${CARS:-1 0 5 3}"; MODES="${MODES:-rear corner side}"; REPS="${REPS:-1}"; PAR="${PAR:-4}"
mkdir -p "$OUT"
export GODOT OUT SCENE
for c in $CARS; do for m in $MODES; do for tr in 1 0; do for r in $(seq 1 "$REPS"); do
  echo "$c $m $tr $r"; done; done; done; done | xargs -P "$PAR" -L 1 bash -c '
  timeout 300 "$GODOT" --headless --fixed-fps 60 --path . res://tools/ProbeSfTramvai.tscn -- \
    --scene="$SCENE" --car=$0 --mode=$1 --tram=$2 > "$OUT/c$0_$1_t$2_r$3.log" 2>&1
  grep -h "=== SF TRAMVAI" "$OUT/c$0_$1_t$2_r$3.log"'
