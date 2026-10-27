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
