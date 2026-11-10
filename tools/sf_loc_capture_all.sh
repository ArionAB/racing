#!/usr/bin/env bash
# tools/sf_loc_capture_all.sh — cele 25 de capturi ale testului de loc San Francisco
# (brief §7 pasul 0): 5 de pe strada sintetica + cate 5 de pe Jodhpur, Kyoto, Chongqing,
# Okinawa, toate cu camera REALA de joc (--gamecam) si masina jucatorului in cadru (--car),
# fara HUD (Snapshot nu porneste cursa). Serial, pe lacatul de GPU (sf_loc_capture.sh).
# Iese in snapshots/sf_loc_src/<sursa>_<k>.png; amestecarea o face sf_loc_shuffle.py.
# ONLY=sf|jodhpur|kyoto|chongqing|okinawa [ONLY_K=n] reface doar o sursa (o captura).
set -u
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/snapshots/sf_loc_src"
mkdir -p "$OUT"
SF_FRACS="0.0586 0.0856 0.1149 0.1734 0.2252"   # = vederile de masura (probe_sf_loc.gd VIEWS)
TR_FRACS="0.08 0.27 0.46 0.64 0.83"
k=0; for f in $SF_FRACS; do k=$((k+1))
  [ -n "${ONLY:-}" ] && [ "$ONLY" != sf ] && continue
  bash "$ROOT/tools/sf_loc_capture.sh" "$OUT/sf_$k.png" --scene=res://tools/SfLoc.tscn --frac=$f --gamecam --car || exit 1
done
# indicii din GameState.TRACK_SCENES (pozitie, nu numar de scena; memoria indici-de-pista-intre-unelte)
for pair in jodhpur:10 kyoto:11 chongqing:5 okinawa:13; do
  name=${pair%%:*}; idx=${pair##*:}
  fr="$TR_FRACS"
  # Kyoto la 0.46 trece pe sub un acoperis (cadrul e plin de tigla): 0.50
  [ "$name" = kyoto ] && fr="0.08 0.27 0.50 0.64 0.83"
  [ -n "${ONLY:-}" ] && [ "$ONLY" != "$name" ] && continue
  k=0; for f in $fr; do k=$((k+1))
    [ -n "${ONLY_K:-}" ] && [ "$ONLY_K" != "$k" ] && continue
    bash "$ROOT/tools/sf_loc_capture.sh" "$OUT/${name}_$k.png" --track=$idx --frac=$f --gamecam --car || exit 1
  done
done
echo "GATA: $(ls "$OUT" | wc -l) capturi in $OUT"
