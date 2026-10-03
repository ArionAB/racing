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

echo "== grupa kit-b: pagode vermilion + Kinkaku-ji =="
check "structures/sanjunoto_pagoda.glb" 7300 --origin=assembly --allow-car-slots=Pagoda_Spire
check "structures/koyasu_pagoda.glb"    6800 --origin=assembly --allow-car-slots=Pagoda_Spire
check "structures/kinkakuji.glb"        5600 --origin=assembly --allow-car-slots=Kin_Gold

echo "== arborii (kit §1.2, grupa kit-c) =="
check "plants/momiji_b.glb"           2500 --origin=assembly
check "plants/momiji_c.glb"           3100 --origin=assembly
check "plants/ginkgo.glb"             3100 --origin=assembly --allow-car-slots=Ginkgo_Crown
check "plants/niwaki_pine.glb"         750 --origin=assembly

echo
echo "== orasul (kit §1.6, grupa kit-d) =="
for m in a c d e; do check "buildings/machiya_$m.glb" 3200 --origin=assembly; done
check "buildings/machiya_b.glb"       3200 --origin=assembly --allow-car-slots=Machiya_Noren
check "props/teahouse_front.glb"      1800 --origin=assembly --allow-car-slots=Tea_Red
check "props/paper_lantern.glb"        800 --origin=assembly
check "structures/temple_wall.glb"    2000 --origin=assembly

echo
echo "== poduri (kit §1.5) =="
# waterline: modulele au puntea la Y=0 (glTF), piloni dedesubt, acoperis deasupra
check "structures/tsutenkyo_roof_module.glb" 6000 --origin=waterline
check "structures/togetsukyo_module.glb"     4000 --origin=waterline
check "structures/iron_truss_bridge.glb"     3000 --origin=assembly --allow-car-slots=Truss_Iron

echo "== sala, scena, portile (kit §1.3) =="
check "structures/niomon_gate.glb"    7000 --origin=assembly
check "structures/inari_romon.glb"    6600 --origin=assembly
check "structures/kakezukuri_scaffold.glb" 1000 --origin=assembly
check "structures/kiyomizu_hondo.glb"  5600 --origin=assembly

echo
echo "== gradina si bambus (kit §1.8, grupa kit-g) =="
check "props/shiba_fence.glb"            400 --origin=assembly
check "plants/karikomi_shrub_a.glb"      120 --origin=assembly
check "plants/karikomi_shrub_b.glb"      120 --origin=assembly
check "rocks/garden_rock_a.glb"          200 --origin=assembly
check "rocks/garden_rock_b.glb"           80 --origin=assembly
check "rocks/garden_rock_c.glb"          200 --origin=assembly
check "rocks/stepping_stones.glb"        300 --origin=assembly
check "rocks/moss_mound.glb"             400 --origin=assembly
check "props/leaf_pile.glb"             2800 --origin=assembly
check "plants/moso_culm.glb"             300 --origin=assembly
check "plants/bamboo_crown.glb"        2500 --origin=assembly

total=$(find "$ROOT" -name '*.glb' 2>/dev/null | wc -l)
echo "GLB-uri in $ROOT: $total (5 existente, nu ale kitului)"
if [ "$fail" -eq 0 ]; then echo "VERDICT KIT: OK"; else echo "VERDICT KIT: PROBLEME"; fi
exit "$fail"
