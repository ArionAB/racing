#!/usr/bin/env bash
# Sonda 1b San Francisco: scrie toate strazile SondaSfSerp*.tscn in doua trepte.
#
#   bash tools/sf_serp_gen_all.sh
#
# Treapta 1 (gen_sf_serpentine.py fara dump) aproximeaza fractiile capetelor
# benzii; dump-ul ProbeSfSerp scrie punctele COPTE ale buclei principale, iar
# treapta 2 pune entry_at / exit_at exact pe indicii copti (Godot nu coace la
# pas uniform, deci fractia nu se poate calcula din lungime).
#
# Variabile: GODOT (implicit exe-ul din D:/GameDev), SHAPES ("R" sau "R:BYPASS",
# separate prin spatiu), WIDTHS (semi-latimi).
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-D:/GameDev/Godot_v4.7-stable_win64_console.exe}"
SHAPES="${SHAPES:-8 10 12}"
WIDTHS="${WIDTHS:-3.5 4 4.5}"
# RE: raza virajelor de 90 ale scurtaturii (intrare, iesire, gura). Implicit 10;
# runda 2 masoara si RE=16 (aceeasi raza ca acele) — sufix "E16" in nume.
RE="${RE:-10}"
for shape in $SHAPES; do
  R="${shape%%:*}"
  B=270
  [[ "$shape" == *:* ]] && B="${shape##*:}"
  csv="tools/data/sf_serp/main_R${R}_L8_E${RE}_B${B}.csv"
  if [[ ! -f "$csv" ]]; then
    R=$R BW=3.5 RE=$RE BYPASS=$B AI=1.0 SUFIX=_tmp python tools/gen_sf_serpentine.py
    tmp="res://tools/SondaSfSerpR${R}W7_tmp.tscn"
    [[ "$B" != 270 ]] && tmp="res://tools/SondaSfSerpR${R}W7_tmp.tscn"
    timeout 300 "$GODOT" --headless --fixed-fps 60 --path . res://tools/ProbeSfSerp.tscn -- \
      --mode=dump --scene="$tmp" --out="$PWD/$csv" | grep -E "dump:|ruta 1"
    rm -f "tools/SondaSfSerpR${R}W7_tmp.tscn"
  fi
  for BW in $WIDTHS; do
    suffix=""
    [[ "$B" != 270 ]] && suffix="B${B}"
    [[ "$RE" != 10 ]] && suffix="${suffix}E${RE}"
    R=$R BW=$BW RE=$RE BYPASS=$B AI=1.0 SUFIX="${suffix}F" python tools/gen_sf_serpentine.py
    R=$R BW=$BW RE=$RE BYPASS=$B SUFIX="${suffix}N" python tools/gen_sf_serpentine.py
    R=$R BW=$BW RE=$RE BYPASS=$B AI=0.0 SUFIX="${suffix}O" python tools/gen_sf_serpentine.py
  done
done
