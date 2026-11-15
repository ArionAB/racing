#!/usr/bin/env bash
# tools/sf_loc_pilot_runs.sh <eticheta> [flaguri sonda]
#
# Pasul 7 (pilotul kitului casei de rand): o rulare a masuratorilor testului de loc
# (`tools/sf_loc_measure.sh`, CU fereastra, pe lacatul de GPU), cu iesirea pastrata in
# snapshots/sf_loc_runs/<eticheta>/ (cadrele, json-ul sondei, sf_loc_summary.json), ca rularile
# repetate si cele doua moduri sa poata fi comparate. Exemple:
#   bash tools/sf_loc_pilot_runs.sh cod_1
#   bash tools/sf_loc_pilot_runs.sh glb_1 --glb
#   bash tools/sf_loc_pilot_runs.sh cod_resplit_1 --resplit
set -u
LABEL="$1"; shift
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/snapshots/sf_loc_runs/$LABEL"
rm -f "$ROOT"/snapshots/sf_loc_meas_*.png "$ROOT/snapshots/sf_loc_meas.json"
bash "$ROOT/tools/sf_loc_measure.sh" "$@" > /dev/null
mkdir -p "$OUT"
cp "$ROOT"/snapshots/sf_loc_meas_*.png "$ROOT/snapshots/sf_loc_meas.json" "$OUT/"
python "$ROOT/tools/sf_loc_stats.py" "$OUT" | tee "$OUT/stats.txt"
