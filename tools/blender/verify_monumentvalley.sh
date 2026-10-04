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
echo "== grupa mv-a =="
check "rocks/sandstone_arch.glb" 12000 --origin=assembly
check "rocks/east_mitten.glb" 12000 --origin=assembly
check "rocks/merrick_butte.glb" 14000 --origin=assembly
check "rocks/mesa_wall_module.glb" 8000 --origin=assembly

echo
echo "== grupa mv-f (stanci mici, grohotis, fundal) =="
check "rocks/butte_small_a.glb" 6000 --origin=assembly
check "rocks/butte_small_b.glb" 6000 --origin=assembly
check "rocks/butte_small_c.glb" 9000 --origin=assembly
check "rocks/rock_fin.glb" 3000 --origin=assembly
check "rocks/hoodoo.glb" 3000 --origin=assembly
check "rocks/talus_boulders_a.glb" 1500 --origin=assembly
check "rocks/talus_boulders_b.glb" 1800 --origin=assembly
# fundalul: 7 noduri copii directe, TOATE cu originea la baza in acelasi punct
# (consumatorul le extrage pe rand); numarul de triunghiuri se raporteaza, fara plafon
check "rocks/horizon_mesas.glb" 60000 --origin=assembly

echo
if [ "$fail" -eq 0 ]; then echo "VERDICT KIT: OK"; else echo "VERDICT KIT: PROBLEME"; fi
exit "$fail"
