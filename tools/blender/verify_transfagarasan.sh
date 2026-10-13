#!/usr/bin/env bash
# Verifica kitul Transfagarasan fata de docs/asset_briefs/transfagarasan_kit.md.
# Pe tiparul verify_okinawa_v2.sh: o rulare, un verdict, exceptiile DECLARATE.
#
#     bash tools/blender/verify_transfagarasan.sh
#
# Verdictul verde NU e livrare (memoria harnasul-de-kit-nu-vede-forma-nici-
# culoarea): piesa se accepta doar dupa comparatia alaturata decupare | randare
# (`preview_transfagarasan.py --compare <nume>`), vazuta de coordonator.
#
# Exceptii, fiecare cu motivul:
#   --origin=assembly   piesele au mai multe noduri pe rol (beton / zapada / praf /
#                       umbra); offsetul de origine e calculat o data pe ansamblu.
#   --origin=rim        zidurile de sprijin: creasta la 0, zidul atarna dedesubt.
# Fara plafon de triunghiuri (CLAUDE.md): bugetul dat lui verify_glb e doar o
# plasa de siguranta (1.000.000). Garzi suplimentare:
#   - scala/rotatia aplicate pe nodurile radacina (memoria scala-glb-neaplicata-
#     la-radacina)
#   - golul portalului, MASURAT CA GOL (measure_tf_gap.py): >= 13,0 m lateral pe
#     banda caroseriei 0-2 m, >= 7,0 m inaltime libera in |x| <= 6,5 (kit §1.1, contract nou)
#   - golul portalului de stanca (tf-a): >= 15,0 m pe 0-2 m, >= 7,0 m in |x| <= 6,5
#   - orice GLB din assets/models/transfagarasan/ care NU e declarat mai jos e
#     verificat cu verify_glb.py fara exceptii (si pica daca nu trece).

set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="assets/models/transfagarasan"
BIG=1000000
fail=0
declare -A DECLARED

check() {  # check <cale> [flag...]
  local f="$ROOT/$1"; shift
  DECLARED["$f"]=1
  if [ ! -f "$f" ]; then
    printf "%-34s LIPSESTE\n" "$(basename "$f")"; fail=1; return
  fi
  local out verdict tris
  out=$(python tools/blender/verify_glb.py "$f" "$BIG" "$@" 2>&1)
  verdict=$(printf '%s' "$out" | grep -o "VERDICT: [A-Z]*" | head -1)
  tris=$(printf '%s' "$out" | grep -o "TOTAL: [0-9]* tris" | grep -o "[0-9]*")
  printf "%-34s %-14s %7s tris\n" "$(basename "$f")" "${verdict:-FARA VERDICT}" "${tris:-?}"
  printf '%s' "$out" | grep -q "VERDICT: OK" || { fail=1; printf '%s\n' "$out" | grep "!!"; }
  python - "$f" <<'PY' || fail=1
import sys, os
sys.path.insert(0, os.path.join("tools", "blender"))
from verify_glb import load_glb
g = load_glb(sys.argv[1])[0]
kids = {c for n in g["nodes"] for c in n.get("children", [])}
bad = []
for i, n in enumerate(g["nodes"]):
    if i in kids:
        continue
    s = n.get("scale", [1, 1, 1])
    r = n.get("rotation", [0, 0, 0, 1])
    if any(abs(v - 1) > 1e-4 for v in s) or any(abs(r[k]) > 1e-4 for k in range(3)):
        bad.append((n.get("name"), s, r))
if bad:
    print("   !! scala/rotatie neaplicata pe radacina:", bad)
    sys.exit(1)
PY
}

gap_check() {  # gap_check <cale> <lat_min> <inalt_min>
  local f="$ROOT/$1"
  [ -f "$f" ] || { printf "%-34s GOL: LIPSESTE\n" "$(basename "$f")"; fail=1; return; }
  local out gap clear
  out=$(python tools/blender/measure_tf_gap.py "$f" --contract="$2,$3" --window=6.5 2>&1); local rc=$?
  gap=$(printf '%s' "$out" | awk '$1=="gap"{print $2}')
  clear=$(printf '%s' "$out" | awk '$1=="clear_min"{print $2}')
  if [ "$rc" -eq 0 ]; then
    printf "%-34s GOL: OK   lateral %s m (>= %s, banda 0-2 m), inaltime libera %s m (>= %s)\n" \
      "$(basename "$f")" "$gap" "$2" "$clear" "$3"
  else
    printf "%-34s GOL: SUB CONTRACT   lateral %s (>= %s), inaltime libera %s (>= %s)\n" \
      "$(basename "$f")" "${gap:-?}" "$2" "${clear:-?}" "$3"
    fail=1
  fi
}

echo "== pilotul (kit §3, val 0): portalul =="
check "structures/tunnel_portal_balea.glb" --origin=assembly
gap_check "structures/tunnel_portal_balea.glb" 13.0 7.0

echo
echo "== val 1, tf-a (drumul, kit §1.1) =="
# --origin=assembly: snow_wall are variantele ca radacini goale (SnowWall_A/_B)
#   cu copiii *_Snow/*_Dust; portalul de stanca are 3 noduri pe rol; recuzita are
#   noduri cu pivot propriu (conuri, bratele barierei pe balama).
# --origin=rim: zidurile de sprijin au creasta la cota 0 (marginea drumului) si
#   atarna sub ea, ca si craterul.
check "structures/snow_wall.glb" --origin=assembly
check "structures/rock_tunnel_portal.glb" --origin=assembly
gap_check "structures/rock_tunnel_portal.glb" 15.0 7.0
check "structures/retaining_wall_straight.glb" --origin=rim
check "structures/retaining_wall_curve.glb" --origin=rim
check "props/snow_pole.glb" --origin=assembly
check "props/road_works.glb" --origin=assembly
check "props/level_crossing.glb" --origin=assembly
check "props/bear_warning_sign.glb" --origin=assembly

echo
echo "== valul 1, tf-c: ursul animat (kit §1.6) =="
# Fara exceptii de origine: un singur mesh skinnuit, baza la 0, centrat; armatura
# la identitate pe nodul radacina (nimic de aplicat). Garda in plus: clipurile
# exact Idle/Walk/Stand (contractul cu SlidingHazard.ANIM_*), citite din GLB.
check "animals/brown_bear.glb"
if [ -f "$ROOT/animals/brown_bear.glb" ]; then
  python tools/blender/check_glb_anims.py "$ROOT/animals/brown_bear.glb" Idle Walk Stand || fail=1
fi

echo
echo "== val 1, tf-b: stanci si plante (kit §1.4, §1.5) =="
# Exceptii tf-b, cu motiv:
#   --origin=assembly  toate: noduri pe rol (Schist_Schist + Schist_Crack;
#                      *_Bark/*_Needles/*_Leaves/*_Bloom/*_Berry), offsetul de
#                      origine calculat O DATA pe ansamblu; nodul de fisuri si
#                      coroanele nu ating solul. La copaci originea e la BAZA
#                      TRUNCHIULUI (coliziunea `trunk` a coordonatorului), nu pe
#                      centrul bbox-ului (fagul b e aplecat si asimetric).
#   --allow-slots=31   bujor_de_munte: florile pe FLAMINGO_PINK 31 (kit §0,
#                      tabelul de sloturi), ca bougainvillea din Okinawa.
for f in rocks/schist_outcrop_a rocks/schist_outcrop_b rocks/schist_outcrop_c          rocks/scree_cone plants/jneapan_a plants/jneapan_b plants/beech_tree_a          plants/beech_tree_b plants/afin; do
  check "$f.glb" --origin=assembly
done
check "plants/bujor_de_munte.glb" --origin=assembly --allow-slots=31

echo
echo "== val 2, tf-d: barajul si reperele (kit §1.2) =="
# Exceptii tf-d, cu motiv:
#   vidraru_dam  --origin=rim --rim-above=8.1: originea FIECARUI nod (Dam_Module,
#                Dam_Tower, Dam_PowerHouse) e la cota drumului, pe axa; corpul
#                atarna 40 m sub ea. Peste ea stau doar parapetul (+1,1, pe
#                6,25 <= |x| <= 7,0) si turnul de priza (+8, la x ~ -16). Banda
#                drumului se verifica separat, PE GLB: measure_tf_deck.py ->
#                nimic peste Y = -0,05 in |x| <= 6,0, coronament sub tot drumul.
deck_check() {  # deck_check <cale>
  local f="$ROOT/$1"
  [ -f "$f" ] || { printf "%-34s DRUM: LIPSESTE\n" "$(basename "$f")"; fail=1; return; }
  local out; out=$(python tools/blender/measure_tf_deck.py "$f" --contract=-0.05 2>&1); local rc=$?
  local dmax; dmax=$(printf '%s' "$out" | awk '$1=="deck_max"{print $2}')
  local par; par=$(printf '%s' "$out" | grep -o "parapet_lac.*")
  if [ "$rc" -eq 0 ]; then
    printf "%-34s DRUM: OK   max %s m in |x| <= 6,0 (<= -0,05), %s\n" "$(basename "$f")" "$dmax" "$par"
  else
    printf "%-34s DRUM: INCALCAT   max %s m in |x| <= 6,0 (<= -0,05)\n" "$(basename "$f")" "${dmax:-?}"
    fail=1
  fi
}
check "structures/vidraru_dam.glb" --origin=rim --rim-above=8.1
deck_check "structures/vidraru_dam.glb"
# poenari_ruin       --origin=assembly: noduri pe rol (Poenari_Schist / _Brick /
#                    _Stone / _Grass), offsetul calculat O DATA pe ansamblu;
#                    iarba si zidurile nu ating solul.
# prometheus_statue  --origin=assembly (Statue_Bronze / _Bolt / _Schist / _Grass,
#                    figura sta pe soclu la 3 m); --allow-car-slots=Statue_Bolt:
#                    fulgerul pe CAR_YELLOW 16 (kit §0, tabelul de sloturi). Potrivirea
#                    e pe PREFIX, deci se scrie numele nodului, nu `*_Bolt`.
check "buildings/poenari_ruin.glb" --origin=assembly
check "props/prometheus_statue.glb" --origin=assembly --allow-car-slots=Statue_Bolt

echo
echo "== val 2, tf-e: cladirile (kit §1.3) =="
# Exceptii tf-e, cu motiv:
#   --origin=assembly  cladirile sunt sparte pe roluri (*_Stone, *_Wood, *_Roof,
#                      *_Void); acoperisul, golurile si cosul nu ating solul,
#                      deci offsetul de origine e calculat O DATA pe ansamblu.
#                      Originea e pe CENTRUL CORPULUI (piatra / tencuiala), nu
#                      pe bbox: terasa, prispa, gardul si anexele ies pe o parte
#                      (cabana Lac: +5,85 m pe +Y). La stana originea e pe
#                      centrul tarcului (coliba e in coltul din spate).
check "buildings/cabana_balea_lac.glb" --origin=assembly
check "buildings/cabana_balea_cascada.glb" --origin=assembly
check "buildings/stana.glb" --origin=assembly
check "buildings/arges_house_a.glb" --origin=assembly
check "buildings/arges_house_b.glb" --origin=assembly
# taraba: originea pe centrul tarabei; marfa si acoperisul nu ating solul
check "props/souvenir_stall.glb" --origin=assembly

echo
echo "== val 2, tf-f: vehicule de decor si ciobanescul (kit §1.6, §1.7) =="
# Exceptii tf-f, cu motiv:
#   --origin=assembly   vehiculele: un nod pe slot (Car_Body/Glass/Tyre/Trim/Hub/
#                       Lamp/Tail, Moto_Body/Metal/Dark/Lamp/Tail); offsetul de
#                       origine e calculat O DATA pe ansamblu (centrul amprentei,
#                       la sol), geamurile si caroseria nu ating solul.
#   --allow-car-slots   caroseria pe CAR_BLUE 15 / CAR_RED 14 (kit §0, tabelul de
#                       sloturi): DOAR nodurile Car_Body si Moto_Body.
#   sheepdog            FARA exceptii (rev. 2): contractul HerdHazard cere UN singur mesh
#                       (toate sloturile in el), origine la sol; un singur nod.
check "vehicles/parked_car_a.glb" --origin=assembly --allow-car-slots=Car_Body
check "vehicles/parked_car_b.glb" --origin=assembly --allow-car-slots=Car_Body
check "vehicles/motorbike.glb" --origin=assembly --allow-car-slots=Moto_Body
check "animals/sheepdog.glb"
if [ -f "$ROOT/animals/sheepdog.glb" ]; then
  python - "$ROOT/animals/sheepdog.glb" <<'PY' || fail=1
import sys, os
sys.path.insert(0, os.path.join("tools", "blender"))
from verify_glb import load_glb
g = load_glb(sys.argv[1])[0]
n = sum(1 for nd in g["nodes"] if "mesh" in nd)
if n != 1:
    print("   !! sheepdog: %d noduri cu mesh, HerdHazard ia doar primul (cerut 1)" % n)
    sys.exit(1)
PY
fi

echo
echo "== val 3, tf-h: garnitura si cabina mare (kit §1.7) =="
# Exceptii tf-h, cu motiv:
#   ro_train   --origin=assembly   trei noduri pe rol (Train_Loco / _Tender /
#              _Wagon), cautate dupa nume EXACT de TrainHazard; offsetul de
#              origine e calculat O DATA pe ansamblu (baza rotilor la y = 0,
#              ecartamentul centrat pe z = 0), nu pe bbox-ul fiecarui nod.
#              --allow-car-slots=Train_Loco,Train_Tender,Train_Wagon: caroseria
#              pe CAR_RED 14 (kit §0, tabelul de sloturi, randul „trenul”).
#   cable_cabin_large   --origin=rim: originea e pe LINIA CABLULUI (varful
#              rotilor caruciorului), cabina atarna 7,5 m sub ea. Fara
#              --rim-above: nimic nu trece peste cablu.
#              --allow-car-slots=Cabin_Body: caroseria pe CAR_RED 14 (kit §0,
#              randul „cabina telecabinei”).
check "vehicles/ro_train.glb" --origin=assembly --allow-car-slots=Train_Loco,Train_Tender,Train_Wagon
if [ -f "$ROOT/vehicles/ro_train.glb" ]; then
  python - "$ROOT/vehicles/ro_train.glb" <<'PY2' || fail=1
import sys, os
sys.path.insert(0, os.path.join("tools", "blender"))
from verify_glb import load_glb
g = load_glb(sys.argv[1])[0]
root = g["scenes"][g.get("scene", 0)]["nodes"]
names = [g["nodes"][i].get("name") for i in root]
miss = [n for n in ("Train_Loco", "Train_Tender", "Train_Wagon") if n not in names]
if miss:
    print("   !! TrainHazard cere copii DIRECTI ai radacinii %s; lipsesc: %s" % (names, miss))
    sys.exit(1)
PY2
fi
check "vehicles/cable_cabin_large.glb" --origin=rim --allow-car-slots=Cabin_Body

echo
echo "== GLB-uri nedeclarate (fara exceptii) =="
if [ -d "$ROOT" ]; then
  while IFS= read -r f; do
    [ -n "${DECLARED[$f]:-}" ] && continue
    out=$(python tools/blender/verify_glb.py "$f" "$BIG" 2>&1)
    if printf '%s' "$out" | grep -q "VERDICT: OK"; then
      printf "%-34s VERDICT: OK (nedeclarat)\n" "$(basename "$f")"
    else
      printf "%-34s NEDECLARAT si PICA\n" "$(basename "$f")"; fail=1
    fi
  done < <(find "$ROOT" -name '*.glb' | sort)
fi

echo
if [ "$fail" -eq 0 ]; then echo "VERDICT KIT: OK"; else echo "VERDICT KIT: PROBLEME"; fi
exit "$fail"
