#!/usr/bin/env bash
# tools/angkor_race_run.sh <worktree> <outdir> <paralel> [argumente in plus]
# 16 seed-uri x 8 masini x 250 s pe Angkor (index 16), observatorul --angkor.
WT="$1"; OUT="$2"; PAR="$3"; shift 3
GODOT=/d/GameDev/Godot_v4.7-stable_win64_console.exe
mkdir -p "$OUT"
cd "$WT" || exit 2
seq 1 16 | xargs -P "$PAR" -I{} sh -c "timeout 1500 '$GODOT' --headless --fixed-fps 60 --path . res://tools/ProbeRace.tscn -- --mode=race --track=16 --ai=7 --seed={} --seconds=250 --angkor --angkor-elephant=0.359,0.381 --angkor-crest=0.595,0.632 $* > '$OUT/seed{}.log' 2>&1"
echo "gata: $(ls "$OUT" | wc -l) log-uri"
