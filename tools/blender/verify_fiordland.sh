#!/usr/bin/env bash
# Verifica tot kitul Fiordland fata de contractul din
# docs/asset_briefs/fiordland_kit.md. Ca `verify_machupicchu.sh`: o rulare,
# un verdict, exceptiile DECLARATE aici.
#
#     bash tools/blender/verify_fiordland.sh
#
# Structura: fiecare val al brief-ului (§3) adauga liniile lui aici. Valul 1
# (stancile-hero, §1.1) e primul si singurul complet la scrierea asta.
#
# Exceptii, fiecare cu motivul:
#
#   --origin=assembly   stirling_ledge: trei noduri (Wall, Overhang, Shelf) cu
#                       origine COMUNA — Overhang iese peste Wall si Shelf sta
#                       la cota lui proprie; `finish()` per nod le-ar re-centra
#                       independent si ansamblul s-ar desface (aceeasi capcana
#                       ca la inca_house_a / Machu Picchu).
#
#   ROCK_DARK / ROCK_LIGHT interzise (brief §0.4): niciuna dintre piesele de
#                       mai jos nu le foloseste — verify_glb.py le-ar semnala
#                       oricum ca sloturi ilegale in decor, dar sunt duble
#                       verificate pe ochi la fiecare val.

set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="assets/models/fiordland"

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

echo "== stancile-hero (brief §1.1, val 1) =="
check "rocks/stirling_ledge.glb"   3000 --origin=assembly
check "rocks/torrent_chute.glb"    1500
check "rocks/chasm_rock.glb"        1500
check "rocks/guard_rock.glb"         200
check "rocks/scree_slab.glb"        3300

echo "== padurea (brief §1.4, val 2) =="
# beech_a/b/c: DOUA noduri (Trunk+Crown, brief §0.6) cu origine comuna —
# aceeasi exceptie ca stirling_ledge, si pentru acelasi motiv (Crown nu
# atinge solul prin constructie, deci finish() per nod l-ar re-centra si
# ansamblul s-ar desface).
check "plants/beech_a.glb"         1050 --origin=assembly
check "plants/beech_b.glb"          950 --origin=assembly
check "plants/beech_c.glb"         1020 --origin=assembly
check "plants/beech_dead.glb"       560
check "plants/rata_tree.glb"       880
check "plants/tussock_clump.glb"    760
check "props/stump.glb"             330
check "props/driftwood.glb"         280
# chasm_bridge_rail: Rail_L/Rail_R, origine "waterline" — Y=0 e cota
# TABLIEI (brief: "origine pe axa drumului, la cota tabliei"), nu solul:
# grinda laterala coboara sub 0, balustrada urca deasupra, exact geometria
# care "incaleca" originea pe care verify_glb.py o numeste waterline (in
# lipsa unui mod "deck", contractul e identic: nimic n-are voie sa atinga
# solul, originea trebuie STRADUITA de geometrie pe ambele parti).
check "structures/chasm_bridge_rail.glb" 780 --origin=waterline

echo "== avalansa (brief §1.5, val 3) =="
# tree_avalanche: 4 noduri Boulder_A..D, origine CENTRU (contractul
# AvalancheHazard — obiectul se rostogoleste, vezi memoria
# `sonda-scurta-extrapolata-gresit` si docul din avalanche_hazard.gd).
check "effects/tree_avalanche.glb" 2600 --origin=center

echo "== vehiculele (brief §1.6, val 3) =="
check "vehicles/coach_fiordland.glb" 3600
# bush_plane: origine CENTRU (PathMover in aer, stick_to_ground=false) +
# exceptie CAR_RED declarata pe dungile fuzelajului/aripilor (brief §1.6).
check "vehicles/bush_plane.glb"     1900 --origin=center --allow-car-slots=Plane
# cruise_boat: origine LA LINIA DE PLUTIRE — geometria INCALECA Y=0 (carena
# sub, suprastructura deasupra), acelasi contract ca "waterline" din
# verify_glb.py (memoria stirling_ledge/waterline).
# cruise_boat.glb = reuse descarcat ("Cruise Ship - toofan", 1640 tri, decizia
# dezvoltatorului): bugetul e numarul masurat + margine, nu un plafon de Builder.
check "vehicles/cruise_boat.glb"    1700 --origin=waterline
# cruise_boat_builder.glb = candidatul Builder (grupa E, kit v2); nu e in joc
# pana nu decide coordonatorul inlocuirea.
check "vehicles/cruise_boat_builder.glb" 4300 --origin=waterline
# kayak_a/b: exceptia CAR_BLUE/CAR_YELLOW declarata (brief §4 paleta —
# caiacele sunt accent saturat, ca avionul).
check "props/kayak_a.glb"           1300 --allow-car-slots=KayakA
check "props/kayak_b.glb"           1300 --allow-car-slots=KayakB

echo "== satul (brief §1.3, val 4) =="
check "structures/wharf.glb"          2300
# cafe_shed/lodge: House_Wall + House_Roof, origine ASSEMBLY — acoperisul nu
# atinge solul prin constructie (aceeasi exceptie ca stirling_ledge/beech).
check "buildings/cafe_shed.glb"       2100 --origin=assembly
check "buildings/lodge.glb"           3700 --origin=assembly
check "structures/heli_pad.glb"       1150
check "props/luggage_container.glb"   950
check "props/road_sign_blank.glb"     160
check "props/traffic_light_pole.glb"  250
check "props/snow_pole.glb"            90

echo "== animalele (brief §1.7, val 4) =="
# kea: rig, actiuni Idle/Open (nu se verifica prin verify_glb.py, care nu
# citeste actiuni) — verificat separat prin preview + raportul de culoare
# din build_fiordland_animals.py.
check "animals/kea.glb"              700
check "animals/penguin_tawaki.glb"   300 --allow-car-slots=Penguin

echo "== fundalul (brief §1.2, val 4) =="
check "rocks/fiordland_horizon.glb"  5000 --origin=assembly

echo
total=$(find "$ROOT" -name '*.glb' 2>/dev/null | wc -l)
echo "GLB-uri in $ROOT: $total"
if [ "$fail" -eq 0 ]; then echo "VERDICT KIT: OK"; else echo "VERDICT KIT: PROBLEME"; fi
exit "$fail"
