#!/usr/bin/env bash
# tools/angkor_race_run.sh <worktree> <outdir> <paralel> [argumente in plus]
# 16 seed-uri x 8 masini x 250 s pe Angkor (index 16), observatorul --angkor.
# SEED_FROM=17 ruleaza seed-urile 17..32 (un exces se confirma doar pe seed-uri NOI).
WT="$1"; OUT="$2"; PAR="$3"; shift 3
GODOT=/d/GameDev/Godot_v4.7-stable_win64_console.exe
mkdir -p "$OUT"
cd "$WT" || exit 2
seq "${SEED_FROM:-1}" "$(( ${SEED_FROM:-1} + 15 ))" | xargs -P "$PAR" -I{} sh -c "timeout 1500 '$GODOT' --headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn -- --mode=race --track=16 --ai=7 --seed={} --seconds=250 --angkor --angkor-elephant=0.378,0.399 --angkor-crest=0.606,0.643 $* > '$OUT/seed{}.log' 2>&1"
echo "gata: $(ls "$OUT" | wc -l) log-uri"
