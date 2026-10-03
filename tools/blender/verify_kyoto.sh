#!/usr/bin/env bash
# Verifica kitul Kyoto fata de contractul din docs/asset_briefs/kyoto_kit.md.
# Ca `verify_jodhpur.sh`: o rulare, un verdict, exceptiile DECLARATE aici.
#
#     bash tools/blender/verify_kyoto.sh
#
# Verdictul verde NU e livrare (memoria harnasul-de-kit-nu-vede-forma-nici-
# culoarea): piesa se accepta doar dupa comparatia alaturata decupare | randare
# (`preview_kyoto.py --compare <nume>`), vazuta de un om.
#
# GLB-urile existente (daruma_otoshi, shishi_odoshi, torii_*, cedar_dark) NU
# se verifica aici -- nu sunt ale kitului.
#
# Exceptii, fiecare cu motivul:
#   --origin=assembly   piesele cu mai multe noduri (corp/acoperis/sorin): nodurile
#                       mici nu ating solul la baza LOR; originea e comuna.
#   --allow-car-slots=Pagoda_Spire  sorin-ul e aurit (CAR_YELLOW 16, brief pistei
#                       §4: aurul = CAR_YELLOW + SAND_LIGHT).

set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="assets/models/kyoto"

fail=0
check() {  # check <cale> <buget> [flag...]
  local f="$ROOT/$1"; local budget="$2"; shift 2
  if [ ! -f "$f" ]; then
    printf "%-34s LIPSESTE\n" "$(basename "$f")"; fail=1; return
  fi
  local out verdict tris
  out=$(python tools/blender/verify_glb.py "$f" "$budget" "$@" 2>&1)
  verdict=$(printf '%s' "$out" | grep -o "VERDICT: [A-Z]*" | head -1)
  tris=$(printf '%s' "$out" | grep -o "TOTAL: [0-9]* tris" | grep -o "[0-9]*")
  printf "%-34s %-14s %7s tris\n" "$(basename "$f")" "${verdict:-FARA VERDICT}" "${tris:-?}"
  printf '%s' "$out" | grep -q "VERDICT: OK" || { fail=1; printf '%s\n' "$out" | grep "!!"; }
}

echo "== pilotul (kit §3, val 0) =="
check "structures/yasaka_pagoda.glb"  7700 --origin=assembly --allow-car-slots=Pagoda_Spire
check "plants/momiji_a.glb"           3100 --origin=assembly

echo
total=$(find "$ROOT" -name '*.glb' 2>/dev/null | wc -l)
echo "GLB-uri in $ROOT: $total (5 existente, nu ale kitului)"
if [ "$fail" -eq 0 ]; then echo "VERDICT KIT: OK"; else echo "VERDICT KIT: PROBLEME"; fi
exit "$fail"
