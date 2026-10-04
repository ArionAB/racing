#!/usr/bin/env bash
# Verifica kitul Monument Valley fata de docs/asset_briefs/monumentvalley_kit.md.
# Ca `verify_kyoto.sh`: o rulare, un verdict, exceptiile DECLARATE aici.
#
#     bash tools/blender/verify_monumentvalley.sh
#
# Verdictul verde NU e livrare (memoria harnasul-de-kit-nu-vede-forma-nici-
# culoarea): piesa se accepta doar dupa comparatia alaturata decupare | randare
# (`preview_monument.py --compare <nume>`), vazuta de un om.
#
# Exceptii, fiecare cu motivul:
#   --origin=assembly   monolitii au mai multe noduri (Rock/Scree/Cap) si
#                       originea e la baza TURNULUI, nu la centrul bbox-ului:
#                       fusta si degetul fac bbox-ul asimetric.

#   plante cu 2 noduri (juniper, rabbitbrush): --origin=assembly, ca monolitii
#   (baza ansamblului la Y=0; coroana/floarea stau deasupra bazei trunchiului).
#   rabbitbrush: --allow-car-slots=Rabbitbrush_Bloom (CAR_YELLOW = floarea).

set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="assets/models/monumentvalley"

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
check "rocks/west_mitten.glb" 12000 --origin=assembly

echo
echo "== grupa mv-b: plante =="
check "plants/sagebrush.glb" 4000
check "plants/juniper.glb" 6000 --origin=assembly
check "plants/yucca.glb" 3000
check "plants/rabbitbrush.glb" 4000 --origin=assembly --allow-car-slots=Rabbitbrush_Bloom
check "plants/tumbleweed.glb" 3000

echo
if [ "$fail" -eq 0 ]; then echo "VERDICT KIT: OK"; else echo "VERDICT KIT: PROBLEME"; fi
exit "$fail"
