#!/usr/bin/env bash
# Verifica tot kitul Cappadocia fata de contractul din docs/blender_export.md.
# Ca `verify_okinawa.sh`: o rulare, un verdict, exceptiile DECLARATE aici.
#
#     bash tools/blender/verify_cappadocia.sh
#
# Doua clase de exceptii, ambele cu motivul in build script:
#
#   --origin=assembly   piese COMPUSE, la care nu toate bucatile ating solul:
#                       hollow_rock (rampa elicoidala porneste la 3 m),
#                       twin_chimney_gate (puntea sta la 12 m intre gaturi),
#                       cracked_chimney_b (hornul culcat sta pe moloz),
#                       uchisar_castle / erciyes (corpuri suprapuse).
#   --origin=center     piese care se ROSTOGOLESC: millstone_door. Vezi
#                       `bake_ao(gradient="spherical")` din dio_lib.
#   --allow-car-slots   sloturile 14-16 sunt rezervate masinilor; baloanele
#                       sunt exceptia declarata in brief §4 ("baloane:
#                       CAR_RED 14, CAR_BLUE 15, CAR_YELLOW 16"), fiindca
#                       atlasul nu are alta sursa de rosu/albastru/galben
#                       saturat si panzele sunt semnal de gameplay, nu decor.
#
# `base_axis` (cliff_band_module, vent_shaft, balloon_*) trece pe --origin=base
# cu un AVERTISMENT de necentrare — asta e corect si intentionat: piesele
# modulare se insiruie de la un capat, iar cele de balon au originea pe punctul
# de prindere. Avertismentul nu pica scriptul.

set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="assets/models/cappadocia"

fail=0
check() {  # check <cale> [flag...]
  local f="$ROOT/$1"; shift
  if [ ! -f "$f" ]; then
    printf "%-38s LIPSESTE\n" "$(basename "$f")"; fail=1; return
  fi
  local out verdict
  out=$(python tools/blender/verify_glb.py "$f" "$@" 2>&1)
  verdict=$(printf '%s' "$out" | grep -o "VERDICT: [A-Z]*" | head -1)
  local tris
  tris=$(printf '%s' "$out" | grep -o "TOTAL: [0-9]* tris" | grep -o "[0-9]*")
  printf "%-38s %-16s %8s tris\n" "$(basename "$f")" "${verdict:-FARA VERDICT}" "${tris:-?}"
  printf '%s' "$out" | grep -q "VERDICT: OK" || { fail=1; printf '%s\n' "$out" | grep "!!"; }
}

echo "== tuf (kit A) =="
for n in chimney_a chimney_b chimney_c chimney_d chimney_mushroom chimney_triple \
         rock_church_facade; do check "rocks/$n.glb"; done
check "rocks/cliff_band_module.glb"

echo
echo "== hero =="
check "structures/hollow_rock.glb"        --origin=assembly
check "structures/twin_chimney_gate.glb"  --origin=assembly
check "structures/cave_entrance.glb"
check "structures/vent_shaft.glb"

echo
echo "== subteran =="
for n in hall_column hall_arch hall_ceiling_module hall_alcove church_arch \
         millstone_slot; do check "structures/$n.glb"; done
check "structures/millstone_door.glb"     --origin=center
check "props/torch.glb"

echo
echo "== baloane (exceptie de slot declarata, brief §4) =="
check "props/balloon_envelope_a.glb" --allow-car-slots=Balloon_Envelope_A
check "props/balloon_envelope_b.glb" --allow-car-slots=Balloon_Envelope_B
check "props/balloon_envelope_c.glb" --allow-car-slots=Balloon_Envelope_C
check "props/balloon_basket.glb"
check "props/balloon_landed.glb"     --allow-car-slots=Balloon_Landed
check "props/balloon_tether.glb"

echo
echo "== hornul crapat (3 stari) =="
check "rocks/cracked_chimney_a.glb"
check "rocks/cracked_chimney_b.glb"       --origin=assembly
check "rocks/cracked_chimney_c.glb"

echo
echo "== sat si figuranti =="
for n in cave_house_a cave_house_b cave_house_c dovecote farmhouse; do
  check "buildings/$n.glb"; done
for n in carpet_terrace pottery_cart pot_stack; do check "props/$n.glb"; done
for n in poplar_a poplar_b vine_row shrub_dry pigeon; do check "plants/$n.glb"; done

echo
echo "== fundal =="
check "rocks/uchisar_castle.glb"          --origin=assembly
check "rocks/erciyes.glb"                 --origin=assembly
check "rocks/balloon_far.glb"             --allow-car-slots=Balloon_Far

echo
echo "== reuse (NU se genereaza aici) =="
if [ -f "assets/models/chongqing/props/chevron_post.glb" ]; then
  echo "chevron_post                           OK (reuse chongqing/props)"
else
  echo "chevron_post                           LIPSESTE din chongqing/props"; fail=1
fi

echo
total=$(find "$ROOT" -name '*.glb' | wc -l)
echo "GLB-uri in $ROOT: $total"
if [ "$fail" -eq 0 ]; then echo "VERDICT KIT: OK"; else echo "VERDICT KIT: PROBLEME"; fi
exit "$fail"
