#!/usr/bin/env bash
# Verifica tot kitul Machu Picchu fata de contractul din
# docs/asset_briefs/machu_picchu_kit.md §1.1-§1.6.
# Ca `verify_serengeti.sh`: o rulare, un verdict, exceptiile DECLARATE aici.
#
#     bash tools/blender/verify_machupicchu.sh
#
# Exceptii, fiecare cu motivul:
#
#   --origin=assembly   piese COMPUSE la care nu tot atinge solul:
#                       huayna_picchu (baza se ingroapa 3 m in teren, geometria
#                       coboara la -3 sub origine — brief §1.1), inti_punku
#                       (doua camere separate cu drumul intre ele, originea pe
#                       axa drumului), main_gate (idem, originea pe axa
#                       drumului, nu sub toc), inca_bridge_ledge (originea pe
#                       axa golului, la baza cornisei, nu sub peretele de
#                       stanca), condor (stanca + pasarea asezata pe ea),
#                       gorge_far_wall si machu_picchu_mountain (siluete de
#                       fundal, corpuri suprapuse, base_axis).
#
#   --allow-car-slots   sloturile 14-16 sunt rezervate masinilor; brief §0.4 le
#                       declara EXPLICIT exceptie pe vehicule, fiindca atlasul
#                       n-are alta sursa de galben/albastru saturat, iar
#                       autobuzul Consettur si trenul PeruRail sunt hazarde —
#                       semnal de gameplay, nu decor. Trenul isi cere nodurile
#                       pe nume (`train_hazard.gd:38-41`), deci lista e pe cele
#                       trei noduri.
#
#   --allow-slots=31    orhideele: 31 e FLAMINGO_PINK (NEON_PINK din paleta
#                       Chongqing) si se randeaza magenta daca nu e declarat.
#                       Brief §0.4 il numeste explicit "accent rar", exact ca
#                       flamingii de la Serengeti. Singura planta saturata.
#
# `base_axis` (zidurile modulare, water_channel, rope_rail — capete plane la
# x = ±jumatate ca sa se inlantuie) trece pe --origin=base cu un AVERTISMENT de
# necentrare. E corect si intentionat: piesele modulare se insiruie de la un
# capat. Avertismentul nu pica scriptul.

set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="assets/models/machupicchu"

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

echo "== hero =="
check "rocks/huayna_picchu.glb"            2500 --origin=assembly
check "structures/inti_punku.glb"          1800 --origin=assembly
check "structures/main_gate.glb"           1500 --origin=assembly
check "structures/inca_bridge_ledge.glb"   2500 --origin=assembly

echo
echo "== sacre =="
check "structures/sun_temple.glb"          1200
check "structures/intihuatana.glb"          500
check "structures/three_windows.glb"        600

echo
echo "== cetate =="
check "structures/inca_wall_a.glb"          300
check "structures/inca_wall_b.glb"          300
check "structures/inca_wall_c.glb"          200
check "structures/inca_stair_a.glb"         300
check "structures/inca_stair_b.glb"         500
check "structures/fountain_basin.glb"       200
check "structures/water_channel.glb"        100
check "structures/trail_marker.glb"          80
check "structures/rope_rail.glb"            200

echo
echo "== cladiri =="
check "buildings/inca_house_a.glb"          700
check "buildings/inca_house_b.glb"          500
check "buildings/guardhouse.glb"            800

echo
echo "== padure de nori =="
check "plants/polylepis_a.glb"             1000
check "plants/polylepis_b.glb"             1400
check "plants/tree_fern.glb"                900
check "plants/bromeliad.glb"                200
check "plants/orchid_cluster.glb"           200 --allow-slots=31
check "plants/bamboo_clump.glb"             600
check "rocks/moss_boulder_a.glb"            200
check "rocks/moss_boulder_b.glb"            250
check "rocks/moss_boulder_c.glb"            300

echo
echo "== tabara =="
check "props/tent_a.glb"                    300
check "props/tent_b.glb"                    300
check "props/backpack_pile.glb"             400

echo
echo "== animale =="
check "animals/llama.glb"                   400
check "animals/llama_b.glb"                 400
check "animals/llama_c.glb"                 400
check "animals/condor.glb"                  900 --origin=assembly

echo
echo "== vehicule (exceptie de slot declarata, brief §0.4) =="
check "vehicles/consettur_bus.glb"         1200 --allow-car-slots=Consettur_Bus
check "vehicles/perurail_train.glb"        3000 --allow-car-slots=Train_Loco,Train_Tender,Train_Wagon

echo
echo "== fundal =="
check "rocks/gorge_far_wall.glb"           5000 --origin=assembly
check "rocks/machu_picchu_mountain.glb"    1500 --origin=assembly

echo
echo "== NU se genereaza aici =="
# Podul de franghie, turnurile lui si barnele traveei nu sunt assets: hazardele
# isi construiesc geometria singure, in SurfaceTool, si o deformeaza pe cadru.
# Un GLB n-ar avea consumator — verificat in sursa, nu presupus.
echo "rope_bridge, bridge_tower_a/b          N/A (RopeBridgeHazard isi face tablierul,"
echo "                                       cablurile, legaturile SI turnurile in"
echo "                                       SurfaceTool: rope_bridge_hazard.gd:313-392,"
echo "                                       deformate de assets/shaders/rope_bridge.gdshader."
echo "                                       Clasa n-are export deck_model/tower_model.)"
echo "inca_bridge_beams                      N/A (LiftBridgeHazard construieste traveea"
echo "                                       procedural din cele doua buze:"
echo "                                       lift_bridge_hazard.gd:406-460. Cotele ies din"
echo "                                       near_lip/far_lip, deci un GLB fix nici n-ar"
echo "                                       putea sa le respecte. Clasa n-are export model.)"
echo "cloud_bank                             N/A (CloudRiseHazard: panza billboard cu"
echo "                                       gradient radial procedural,"
echo "                                       cloud_rise_hazard.gd:90-101. Nu e GLB.)"

echo
echo "== reuse (NU se genereaza aici) =="
if [ -f "assets/models/chongqing/props/chevron_post.glb" ]; then
  echo "chevron_post                           OK (reuse chongqing/props)"
else
  echo "chevron_post                           LIPSESTE din chongqing/props"; fail=1
fi
if [ -f "assets/models/props/cow.glb" ]; then
  echo "cow (placeholder lame)                 OK (reuse props/cow.glb)"
else
  echo "cow                                    LIPSESTE din props/"; fail=1
fi

echo
total=$(find "$ROOT" -name '*.glb' 2>/dev/null | wc -l)
echo "GLB-uri in $ROOT: $total"
if [ "$fail" -eq 0 ]; then echo "VERDICT KIT: OK"; else echo "VERDICT KIT: PROBLEME"; fi
exit "$fail"
