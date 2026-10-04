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
#   --origin=assembly   (grupa mv-c) piesele de drum/gard/semne au mai multe noduri
#                       pe rol (otel / lemn / izolatori): rotorul morii are PIVOT
#                       propriu (butucul), semnul are rombul la 2 m. Ansamblul
#                       trebuie doar sa atinga solul.
#   --allow-car-slots=Sign_Face  rombul semnului "open range" e CAR_YELLOW (16):
#                       galbenul de avertizare rutiera e singurul accent saturat
#                       al grupei; stalpii cattle_guard NU il folosesc (galben
#                       SAND_LIGHT + negru VOLCANIC_BLACK), deci n-au exceptie.

#   plante cu 2 noduri (sagebrush, juniper, rabbitbrush): --origin=assembly, ca monolitii
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
echo "== grupa mv-a =="
check "rocks/sandstone_arch.glb" 12000 --origin=assembly
check "rocks/east_mitten.glb" 12000 --origin=assembly
check "rocks/merrick_butte.glb" 14000 --origin=assembly
check "rocks/mesa_wall_module.glb" 8000 --origin=assembly

echo
echo "== grupa mv-b: plante =="
check "plants/sagebrush.glb" 4000 --origin=assembly
check "plants/juniper.glb" 6000 --origin=assembly
check "plants/yucca.glb" 3000
check "plants/rabbitbrush.glb" 4000 --origin=assembly --allow-car-slots=Rabbitbrush_Bloom
check "plants/tumbleweed.glb" 3000

echo
echo "== grupa mv-c: drum, gard, semne =="
check "props/cattle_guard.glb" 2500 --origin=assembly
check "props/open_range_sign.glb" 1500 --origin=assembly --allow-car-slots=Sign_Face
check "structures/telegraph_pole.glb" 1500 --origin=assembly
check "structures/wire_fence.glb" 1500 --origin=assembly
check "structures/windmill_pump.glb" 4000 --origin=assembly
check "structures/water_tower.glb" 4000 --origin=assembly
check "structures/corral.glb" 5000 --origin=assembly
check "structures/shade_ramada.glb" 4000 --origin=assembly

echo
echo "== grupa mv-d: cladiri, vehicule, oameni =="
check "buildings/trading_post.glb" 9000 --origin=assembly
check "buildings/homestead_house.glb" 9000 --origin=assembly
check "buildings/hogan.glb" 9000 --origin=assembly
check "vehicles/pickup_old.glb" 6000 --origin=assembly
check "vehicles/tour_truck.glb" 8000 --origin=assembly --allow-car-slots=Truck_Body
check "props/tourist_group.glb" 8000 --origin=assembly --allow-car-slots=Tourist_Clothes

echo
echo "== grupa mv-e: animale =="
# --origin=assembly: nodurile Pose_Stand/Pose_Walk (si Raven_Body/Raven_Wings)
# stau in acelasi sistem; ansamblul trebuie doar sa atinga solul.
check "animals/horse_bay.glb" 3200 --origin=assembly
check "animals/horse_pinto.glb" 3200 --origin=assembly
check "animals/horse_black.glb" 3200 --origin=assembly
check "animals/sheep.glb" 2400 --origin=assembly
check "animals/raven.glb" 1800 --origin=assembly

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
