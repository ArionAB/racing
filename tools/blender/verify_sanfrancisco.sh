#!/usr/bin/env bash
# Verifica piesele San Francisco fata de briefurile din docs/asset_briefs/sf_*.md.
# Pe tiparul verify_angkor.sh: o rulare, un verdict, exceptiile DECLARATE.
#
#     bash tools/blender/verify_sanfrancisco.sh
#
# Verdictul verde NU e livrare (memoria harnasul-de-kit-nu-vede-forma-nici-
# culoarea): forma se accepta doar pe randarea pusa langa decupare
# (`preview_sf_*.py`) si pe capturile din joc, vazute de coordonator.
#
# Exceptii, fiecare cu motivul:
#   fara --front=-Z     la vagon, utilaj si casa: testul numeste „fata” planul cu
#                       cea mai mare arie, deci pe orice piesa mai lunga decat lata
#                       (vagon 8,5 m, utilaj 10 m, casa adanca de 12 m) castiga
#                       laturile. Fata reala (clopotul vagonului pe -Z, fatada pe -Z)
#                       se vede in randarea de control; cotele le tine garda de mai jos.
#   --origin=waterline  piesele asezate pe cadrul podului (turn, tablier, ancoraj,
#                       trotuar) si casa (fusta-soclu pana la -2,4): geometria
#                       INCALECA Y = 0 prin contract, nu sta cu baza pe el.
#   --origin=assembly   parapet, evazari, felinar: mai multe noduri, baza la Y = 0.
#   cablurile           nu pot trece niciun mod de origine: cel mai jos punct e la
#                       Y +0,20 (mufele tirantilor stau pe trotuar). Se accepta DOAR
#                       daca asta e singura linie semnalata.
# Fara plafon de triunghiuri pe hero (CLAUDE.md); bugetele de mai jos sunt cele din
# briefuri si conteaza pe piesele repetate (tablier x25, parapet x28, bloc x145,
# casa x sute).
# Garzile de cote (pe GLB, coordonate Godot, cu selftest pe copii sabotate):
#   measure_sf_bridge.py   gabaritul liber al podului (brief §3)
#   measure_sf_gabarit.py  cutiile pe care le citeste fizica: vagon, utilaj, bloc, casa
#   measure_sf_street.py   mobilierul valului 2 (masinile parcate, semaforul, felinarul, piesele mici)
#   measure_sf_plants.py   vegetatia valului 2 (chiparosii, arborele de strada, hortensiile, gradinita)

set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="assets/models/sanfrancisco"
fail=0
declare -A DECLARED

check() {  # check <cale> <buget> [flag...]
  local f="$ROOT/$1" budget="$2"; shift 2
  DECLARED["$f"]=1
  if [ ! -f "$f" ]; then
    printf "%-30s LIPSESTE\n" "$(basename "$f")"; fail=1; return
  fi
  local out verdict tris
  out=$(python tools/blender/verify_glb.py "$f" "$budget" "$@" 2>&1)
  verdict=$(printf '%s' "$out" | grep -o "VERDICT: [A-Z]*" | head -1)
  tris=$(printf '%s' "$out" | grep -o "TOTAL: [0-9]* tris" | grep -o "[0-9]*")
  printf "%-30s %-14s %7s tris (buget %s)\n" "$(basename "$f")" "${verdict:-FARA VERDICT}" "${tris:-?}" "$budget"
  printf '%s' "$out" | grep -q "VERDICT: OK" || { fail=1; printf '%s\n' "$out" | grep "!!"; }
}

check_cable() {  # singura linie admisa: „nu atinge solul” (Y +0,20)
  local f="$ROOT/$1" budget="$2"
  DECLARED["$f"]=1
  if [ ! -f "$f" ]; then
    printf "%-30s LIPSESTE\n" "$(basename "$f")"; fail=1; return
  fi
  local out tris n
  out=$(python tools/blender/verify_glb.py "$f" "$budget" --origin=assembly 2>&1)
  tris=$(printf '%s' "$out" | grep -o "TOTAL: [0-9]* tris" | grep -o "[0-9]*")
  n=$(printf '%s\n' "$out" | grep -c "!!")
  if [ "$n" -eq 1 ] && printf '%s' "$out" | grep "!!" | grep -q "nu atinge solul.*Y=0.200"; then
    printf "%-30s %-14s %7s tris (buget %s)\n" "$(basename "$f")" "OK (exceptie)" "${tris:-?}" "$budget"
  else
    printf "%-30s %-14s %7s tris (buget %s)\n" "$(basename "$f")" "PROBLEME" "${tris:-?}" "$budget"
    printf '%s\n' "$out" | grep "!!"; fail=1
  fi
}

echo "== vehicule si hazard (sf_cable_car.md, sf_median_truck.md) =="
check "vehicles/cable_car.glb" 20000
check "vehicles/sf_median_truck.glb" 8000
check "props/sf_median_block.glb" 120

echo
echo "== podul rosu (sf_red_bridge.md) =="
check "structures/sf_bridge_tower.glb" 8000 --origin=waterline
check "structures/sf_bridge_deck_8.glb" 600 --origin=waterline
check "structures/sf_bridge_parapet_8.glb" 300 --origin=assembly
check "structures/sf_bridge_flares.glb" 300 --origin=assembly
check_cable "structures/sf_bridge_cable_main.glb" 3000
check_cable "structures/sf_bridge_cable_side.glb" 1500
check "structures/sf_bridge_anchor.glb" 2500 --origin=waterline
check "structures/sf_bridge_walkway_8.glb" 600 --origin=waterline
check "structures/sf_bridge_lamp.glb" 600 --origin=assembly

echo
echo "== kitul casei de rand (sf_painted_row_kit.md): sapte case + variantele _m =="
for h in sf_row_a_canted sf_row_a_square sf_row_b_canted sf_row_b_square          sf_row_c_canted sf_row_c_square; do
  check "buildings/$h.glb" 2500 --origin=waterline
  check "buildings/${h}_m.glb" 2500 --origin=waterline
done
# coltul: 9 x 12 m, doua fatade si turnuletul (brief §8: <= 3.500)
check "buildings/sf_row_corner_turret.glb" 3500 --origin=waterline
check "buildings/sf_row_corner_turret_m.glb" 3500 --origin=waterline
# casele de capat (pasul 8c): ca o casa de rand (<= 2.500), cu latura -X (`_m`: +X) finisata
for h in sf_row_end_a sf_row_end_b sf_row_end_c; do
  check "buildings/$h.glb" 2500 --origin=waterline
  check "buildings/${h}_m.glb" 2500 --origin=waterline
done
# casele pictate (K2, inventar: <= 5.000, sase instante). Exceptie declarata:
#   --allow-slots=31    doar `a`: accentul ei e FLAMINGO_PINK (benzile, coloanele, turnuletul)
for k in a b c d e f; do
  fl=""; [ "$k" = a ] && fl="--allow-slots=31"
  check "buildings/sf_painted_lady_$k.glb" 5000 --origin=waterline $fl
  check "buildings/sf_painted_lady_${k}_m.glb" 5000 --origin=waterline $fl
done

echo
echo "== valul 2: mobilierul de strada si vegetatia (inventar §5.3-§5.4) =="
# Bugetele sunt cele din inventar / din garzile constructorilor (measure_sf_street.py, measure_sf_plants.py).
# Exceptii declarate:
#   --origin=assembly   arborii (chiparosii, arborele de strada): patru noduri (trunchi, coroana, miez,
#                       carduri); doar trunchiul atinge Y = 0, coroana incepe la +1,8..+3,3 prin constructie.
#   --allow-slots=31    hortensiile si gradinita: florile pe FLAMINGO_PINK (inventar §5, V3/N2).
check "vehicles/sf_parked_sedan.glb" 2500
check "vehicles/sf_parked_wagon.glb" 2500
check "vehicles/sf_parked_van.glb" 2500
check "props/sf_signal_mast.glb" 1000
check "props/sf_street_lamp.glb" 400
check "props/sf_street_props.glb" 1500
check "props/sf_bollard.glb" 200
check "props/sf_crab_traps.glb" 900
check "props/sf_bench.glb" 400
check "props/sf_bike_rack.glb" 400
check "plants/sf_cypress_a.glb" 6000 --origin=assembly
check "plants/sf_cypress_b.glb" 6000 --origin=assembly
check "plants/sf_cypress_c.glb" 6000 --origin=assembly
check "plants/sf_street_tree.glb" 1200 --origin=assembly
check "plants/sf_hydrangea.glb" 600 --allow-slots=31
check "plants/sf_hydrangea_blue.glb" 600 --allow-slots=31
check "props/sf_front_garden.glb" 400 --allow-slots=31

echo
echo "== garzile de cote =="
python tools/blender/measure_sf_bridge.py || fail=1
st=$(python tools/blender/measure_sf_bridge.py --selftest 2>&1); rc=$?
printf '%s\n' "$st" | grep -E "ASTEPTAT|PICA|SELFTEST"
[ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei podului a esuat"; fail=1; }
python tools/blender/measure_sf_gabarit.py || fail=1
st=$(python tools/blender/measure_sf_gabarit.py --selftest 2>&1); rc=$?
printf '%s\n' "$st" | grep -E "ASTEPTAT|PICA|SELFTEST"
[ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei de gabarit a esuat"; fail=1; }
python tools/blender/measure_sf_street.py || fail=1
st=$(python tools/blender/measure_sf_street.py --selftest 2>&1); rc=$?
printf '%s
' "$st" | grep -E "SELFTEST"
[ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei de strada a esuat"; fail=1; }
python tools/blender/measure_sf_plants.py || fail=1
st=$(python tools/blender/measure_sf_plants.py --selftest 2>&1); rc=$?
printf '%s
' "$st" | grep -E "SELFTEST"
[ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei de vegetatie a esuat"; fail=1; }

echo
echo "== GLB-uri nedeclarate (verificate fara exceptii) =="
found=0
while IFS= read -r f; do
  [ -n "${DECLARED[$f]:-}" ] && continue
  found=1
  check "${f#$ROOT/}" 20000
done < <(find "$ROOT" -name "*.glb" | sort)
[ "$found" -eq 0 ] && echo "(niciunul)"

echo
if [ "$fail" -eq 0 ]; then echo "VERDICT SAN FRANCISCO: OK"; else echo "VERDICT SAN FRANCISCO: PROBLEME"; fi
exit "$fail"
