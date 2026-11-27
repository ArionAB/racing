#!/usr/bin/env bash
# tools/halong_race_run.sh <worktree> <outdir> <paralel> [argumente in plus]
# 8 seed-uri x 6 masini x 230 s (3 tururi) pe Ha Long (index 14), cu
# --seed-ai-prefs (zarul scurtaturii semanat, memoria proberace-nedeterminism).
# SEED_FROM=9 ruleaza seed-urile 9..16 (un exces se confirma doar pe seed-uri NOI).
WT="$1"; OUT="$2"; PAR="$3"; shift 3
GODOT=/d/GameDev/Godot_v4.7-stable_win64_console.exe
mkdir -p "$OUT"
cd "$WT" || exit 2
seq "${SEED_FROM:-1}" "$(( ${SEED_FROM:-1} + ${SEEDS:-8} - 1 ))" | xargs -P "$PAR" -I{} sh -c "timeout 1500 '$GODOT' --headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn -- --mode=race --track=14 --seed={} --seconds=230 --seed-ai-prefs $* > '$OUT/seed{}.log' 2>&1"
echo "gata: $(ls "$OUT" | wc -l) log-uri"
