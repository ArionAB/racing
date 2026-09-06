#!/usr/bin/env bash
# Verifica tot kitul Serengeti fata de contractul din docs/blender_export.md.
# Ca `verify_cappadocia.sh`: o rulare, un verdict, exceptiile DECLARATE aici.
#
#     bash tools/blender/verify_serengeti.sh
#
# Exceptii, fiecare cu motivul in build script:
#   --origin=assembly   piese COMPUSE la care nu tot atinge solul: kopje_camp
#                       (bolovani stivuiti), kopje_kicker (rampa + bolovani),
#                       crater_gap (doua fete), crater_far_wall, lengai (con
#                       ingropat), elephant (armatura + mesh).
#   --allow-car-slots   maasai_boma (shuka = CAR_RED, brief §4: rosul Maasai e
#                       unul din cele trei accente saturate), safari_balloon_landed
#                       (CAR_YELLOW pe panza, ca baloanele din Cappadocia).
#   slotul 31           flamingii: NEON_PINK din scripts/palette.gd (Chongqing),
#                       exact rozul de flamingo; brief §4 il numeste explicit.

set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="assets/models/serengeti"

fail=0
check() {  # check <cale> <buget> [flag...]
  local f="$ROOT/$1"; local budget="$2"; shift 2
  if [ ! -f "$f" ]; then
    printf "%-38s LIPSESTE\n" "$(basename "$f")"; fail=1; return
  fi
  local out verdict
  out=$(python tools/blender/verify_glb.py "$f" "$budget" "$@" 2>&1)
  verdict=$(printf '%s' "$out" | grep -o "VERDICT: [A-Z]*" | head -1)
  local tris
  tris=$(printf '%s' "$out" | grep -o "TOTAL: [0-9]* tris" | grep -o "[0-9]*")
  printf "%-38s %-16s %8s tris\n" "$(basename "$f")" "${verdict:-FARA VERDICT}" "${tris:-?}"
  printf '%s' "$out" | grep -q "VERDICT: OK" || { fail=1; printf '%s\n' "$out" | grep "!!"; }
}

echo "== animale =="
check "animals/wildebeest.glb" 900
check "animals/zebra.glb" 900
check "animals/elephant.glb" 3000 --origin=assembly
check "animals/hippo_back.glb" 1400
check "animals/crocodile.glb" 1300

echo
echo "== granit si pamant =="
check "rocks/kopje_camp.glb" 3500 --origin=assembly
check "rocks/lion_kopje.glb" 1600
check "rocks/kopje_kicker.glb" 2500 --origin=assembly
check "rocks/crater_gap.glb" 6000 --origin=assembly
for n in kopje_boulder_a kopje_boulder_b kopje_boulder_c; do check "rocks/$n.glb" 300; done
for n in termite_mound_a termite_mound_b; do check "rocks/$n.glb" 500; done
check "rocks/carcass_vultures.glb" 2400

echo
echo "== vegetatie =="
for n in acacia_umbrella_a acacia_umbrella_b acacia_umbrella_c fever_tree; do check "plants/$n.glb" 1600; done
check "plants/fig_tree.glb" 3800
check "plants/euphorbia.glb" 1700
check "plants/baobab.glb" 1600
check "plants/dead_tree.glb" 500
check "plants/flamingo.glb" 800 --allow-slots=31
check "plants/flamingo_wings.glb" 900 --allow-slots=31

echo
echo "== oameni =="
check "buildings/maasai_boma.glb" 8500 --allow-car-slots=Maasai_Boma
check "props/ankole_horns.glb" 400
check "props/safari_tent.glb" 400
check "props/land_rover.glb" 900
check "props/campfire.glb" 1500
check "props/safari_balloon_landed.glb" 700 --allow-car-slots=Safari_Balloon_Landed

echo
echo "== fundal =="
check "rocks/lengai.glb" 400 --origin=assembly
check "rocks/crater_far_wall.glb" 6000 --origin=assembly

echo
echo "== reuse (NU se genereaza aici) =="
for cand in "assets/models/signs/chevron_post.glb" "assets/models/chongqing/props/chevron_post.glb"; do
  if [ -f "$cand" ]; then echo "chevron_post                           OK (reuse $cand)"; found=1; break; fi
done
[ "${found:-0}" -eq 1 ] || { echo "chevron_post                           LIPSESTE"; fail=1; }
if [ -f "assets/models/props/cow.glb" ]; then
  echo "cow (pentru ankole_horns)              OK (reuse props/cow.glb)"
else
  echo "cow                                    LIPSESTE din props/"; fail=1
fi

echo
total=$(find "$ROOT" -name '*.glb' | wc -l)
echo "GLB-uri in $ROOT: $total"
if [ "$fail" -eq 0 ]; then echo "VERDICT KIT: OK"; else echo "VERDICT KIT: PROBLEME"; fi
exit "$fail"
