#!/usr/bin/env bash
# Verifica kitul Carrara fata de docs/asset_briefs/carrara_kit.md.
# Pe tiparul verify_transfagarasan.sh: o rulare, un verdict, exceptiile DECLARATE.
#
#     bash tools/blender/verify_carrara.sh
#
# Verdictul verde NU e livrare (memoria harnasul-de-kit-nu-vede-forma-nici-
# culoarea): piesa se accepta doar dupa comparatia alaturata decupare | randare
# (`preview_carrara.py --compare <nume>`), vazuta de coordonator.
#
# Exceptii, fiecare cu motivul:
#   --origin=assembly   piesele au mai multe noduri pe rol (*_Marble/_MarbleBase/
#                       _Rust/_Black); offsetul de origine e calculat O DATA pe
#                       ansamblu, iar blocurile din bena nu ating solul.
# Fara plafon de triunghiuri (CLAUDE.md): bugetul dat lui verify_glb e doar o
# plasa de siguranta (1.000.000). Garzi suplimentare:
#   - scala/rotatia aplicate pe nodurile radacina (memoria scala-glb-neaplicata-
#     la-radacina)
#   - anvelopa camionului (measure_carrara_truck.py, pe GLB, coordonate Godot)
#   - orice GLB din assets/models/carrara/ NEdeclarat e verificat fara exceptii.

set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="assets/models/carrara"
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

echo "== pilotul (kit §3, val 0): basculanta =="
check "vehicles/quarry_truck.glb" --origin=assembly
if [ -f "$ROOT/vehicles/quarry_truck.glb" ]; then
  python tools/blender/measure_carrara_truck.py "$ROOT/vehicles/quarry_truck.glb" || fail=1
  python - "$ROOT/vehicles/quarry_truck.glb" <<'PY' || fail=1
import sys, os
sys.path.insert(0, os.path.join("tools", "blender"))
from verify_glb import load_glb
g = load_glb(sys.argv[1])[0]
names = sorted(n.get("name") for n in g["nodes"] if "mesh" in n)
want = ["Truck_Black", "Truck_Body", "Truck_Marble", "Truck_MarbleBase", "Truck_Rust"]
if names != want:
    print("   !! noduri %s, cerute %s" % (names, want))
    sys.exit(1)
print("   noduri: OK (%s)" % ", ".join(names))
PY
fi

nodes_are() {  # nodes_are <cale> <nume...>: numele nodurilor-mesh, sortate
  python - "$@" <<'PY' || fail=1
import sys, os
sys.path.insert(0, os.path.join("tools", "blender"))
from verify_glb import load_glb
g = load_glb(sys.argv[1])[0]
names = sorted(n.get("name") for n in g["nodes"] if "mesh" in n)
want = sorted(sys.argv[2:])
if names != want:
    print("   !! noduri %s, cerute %s" % (names, want))
    sys.exit(1)
print("   noduri: OK (%s)" % ", ".join(names))
PY
}

echo
echo "== val 1, crr-a: utilajele-hazard (kit §1.1) =="
# Exceptii declarate (crr-a):
#   derrick.glb   --origin=waterline: doua RADACINI cu ancore diferite --
#                 `TowerCrane` cu baza la 0, `Jib` cu originea in BALAMA (codul
#                 il muta pe pivotul de la JIB_HEIGHT), carligul lui atarna
#                 sub balama (-0,41). verify_glb citeste fiecare nod in spatiul
#                 lui, deci ansamblul „incaleca" Y=0; contractul real (varful
#                 catargului 22,05, +-1,8 pe X, carligul la Z -17,9, Jib fara
#                 translatie) e in measure_carrara_crr_a.py derrick.
#   quarry_excavator.glb --origin=waterline: `arm` e copil al lui `body`, cu
#                 pivotul la (0,55; 1,95; -0,42); mesh-urile bratului au Y local
#                 negativ (-1,03). verify_glb nu compune ierarhia; rigul se
#                 masoara in lume, cu ierarhie, in measure_carrara_excavator.py.
#   marble_block_hooked.glb --origin=rim: blocul ATARNA sub origine (carligul),
#                 de la -3,05 la 0 (chingi + inel), ca prefab_slab.glb.
check "structures/derrick.glb" --origin=waterline
if [ -f "$ROOT/structures/derrick.glb" ]; then
  python tools/blender/measure_carrara_crr_a.py derrick "$ROOT/structures/derrick.glb" || fail=1
  nodes_are "$ROOT/structures/derrick.glb" Jib TowerCrane
fi
check "props/marble_block_hooked.glb" --origin=rim
if [ -f "$ROOT/props/marble_block_hooked.glb" ]; then
  python tools/blender/measure_carrara_crr_a.py block "$ROOT/props/marble_block_hooked.glb" || fail=1
  nodes_are "$ROOT/props/marble_block_hooked.glb" Block_Marble Block_MarbleBase Block_Strap Block_Paint
fi
check "props/lizza_sled.glb" --origin=assembly
if [ -f "$ROOT/props/lizza_sled.glb" ]; then
  python tools/blender/measure_carrara_crr_a.py sled "$ROOT/props/lizza_sled.glb" || fail=1
  nodes_are "$ROOT/props/lizza_sled.glb" Sled_Wood Sled_Rope Sled_Marble Sled_MarbleBase
fi
check "rocks/block_informe_a.glb"
if [ -f "$ROOT/rocks/block_informe_a.glb" ]; then
  python tools/blender/measure_carrara_crr_a.py informe "$ROOT/rocks/block_informe_a.glb" || fail=1
  nodes_are "$ROOT/rocks/block_informe_a.glb" Informe_Marble
fi
check "vehicles/quarry_excavator.glb" --origin=waterline
if [ -f "$ROOT/vehicles/quarry_excavator.glb" ]; then
  python tools/blender/measure_carrara_excavator.py "$ROOT/vehicles/quarry_excavator.glb" || fail=1
  nodes_are "$ROOT/vehicles/quarry_excavator.glb" Body_Paint Body_Rust Body_Black Arm_Paint Arm_Rust Arm_Black
fi

echo
echo "== val 1, crr-b: structurile (kit §1.3) =="
# Exceptii crr-b, cu motiv:
#   ponti_di_vara     --origin=rim --rim-above=0.95: originea pe axa drumului la
#                     cota drumului (asfaltul e din cod, la 0); viaductul atarna
#                     26 m sub ea. Peste 0 sta DOAR `Viaduct_Parapet` (+0,90 pe
#                     4,7 <= |x| <= 5,3), nod separat pe care integrarea il poate
#                     stinge. Banda drumului se verifica separat, PE GLB:
#                     measure_crr_structures.py deck -> nimic in afara de
#                     Viaduct_Parapet peste Y = -0,05 in |x| <= 4,6, tablier sub
#                     >= 99% din banda, parapetul pe ambele parti in 4,7..5,3.
#   gallery_portal    --origin=assembly: noduri pe rol (Portal_Marble/_MarbleBase/
#   marmifera_portal  _Rust/_Glow/_Void, Portal_Stone/_Moss/_Rail/...), originea
#                     pe axa drumului la planul fetei, baza la 0; lampa si
#                     captuseala nu ating solul.
#   golurile          MASURATE CA GOL (measure_crr_structures.py gap: proiectie pe
#                     planul fetei, grila 5 cm, toate nodurile): galeria >= 10,0 m
#                     liber pe toata banda 0-10,5 m; Marmifera >= 10,0 m pe 0-6 m
#                     si cheia >= 8,5 m la mijloc. --floor=0.1 doar la Marmifera:
#                     sinele (7 cm) si traversele (2 cm) stau pe drum IN gol (kit
#                     §1.3: „pot fi si pe drum: se taie la integrare").
crr_nodes() {  # crr_nodes <cale> <nod1,nod2,...>
  local f="$ROOT/$1"
  [ -f "$f" ] || return
  python - "$f" "$2" <<'PY' || fail=1
import sys, os
sys.path.insert(0, os.path.join("tools", "blender"))
from verify_glb import load_glb
g = load_glb(sys.argv[1])[0]
names = sorted(n.get("name") for n in g["nodes"] if "mesh" in n)
want = sorted(sys.argv[2].split(","))
if names != want:
    print("   !! noduri %s, cerute %s" % (names, want))
    sys.exit(1)
print("   noduri: OK (%s)" % ", ".join(names))
PY
}
crr_deck() {  # crr_deck <cale>
  local f="$ROOT/$1"
  [ -f "$f" ] || { printf "%-34s DRUM: LIPSESTE\n" "$(basename "$f")"; fail=1; return; }
  local out; out=$(python tools/blender/measure_crr_structures.py deck "$f" 2>&1); local rc=$?
  local dmax; dmax=$(printf '%s' "$out" | awk '$1=="deck_max"{print $2}')
  if [ "$rc" -eq 0 ]; then
    printf "%-34s DRUM: OK   deck_max %s (<= -0,05 in |x| <= 4,6), parapet separat\n" "$(basename "$f")" "$dmax"
  else
    printf "%-34s DRUM: INCALCAT\n" "$(basename "$f")"; printf '%s\n' "$out" | grep "!!"; fail=1
  fi
}
crr_gap() {  # crr_gap <cale> [argumente pentru measure_crr_structures.py gap]
  local f="$ROOT/$1"; shift
  [ -f "$f" ] || { printf "%-34s GOL: LIPSESTE\n" "$(basename "$f")"; fail=1; return; }
  local out; out=$(python tools/blender/measure_crr_structures.py gap "$f" "$@" 2>&1); local rc=$?
  local g c; g=$(printf '%s' "$out" | awk '$1=="gap_rect"{print $2}'); c=$(printf '%s' "$out" | awk '$1=="crown"{print $2}')
  if [ "$rc" -eq 0 ]; then
    printf "%-34s GOL: OK   %s m liber pe banda de contract, %s m la mijloc (%s)\n" "$(basename "$f")" "$g" "$c" "$*"
  else
    printf "%-34s GOL: SUB CONTRACT   %s / %s (%s)\n" "$(basename "$f")" "${g:-?}" "${c:-?}" "$*"; fail=1
  fi
}
check "structures/ponti_di_vara.glb" --origin=rim --rim-above=0.95
crr_deck "structures/ponti_di_vara.glb"
crr_nodes "structures/ponti_di_vara.glb" "Viaduct_Brick,Viaduct_Marble,Viaduct_MarbleBase,Viaduct_Parapet,Viaduct_Rust,Viaduct_Void"
check "structures/gallery_portal.glb" --origin=assembly
crr_gap "structures/gallery_portal.glb" --rect=10.0,10.5
crr_nodes "structures/gallery_portal.glb" "Portal_Glow,Portal_Marble,Portal_MarbleBase,Portal_Rust,Portal_Void"
check "structures/marmifera_portal.glb" --origin=assembly
crr_gap "structures/marmifera_portal.glb" --rect=10.0,6.0 --crown=8.5 --floor=0.1
crr_nodes "structures/marmifera_portal.glb" "Portal_Glow,Portal_Moss,Portal_Rail,Portal_Stone,Portal_Void"

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
