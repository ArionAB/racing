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

echo
echo "== val 1, crr-c: kitul de cariera (kit §1.5) =="
# --origin=assembly pe piesele cu noduri *_Marble / *_MarbleBase (sau _Paint,
# _Glow): baza patinei atinge solul, partea in lumina incepe la o treime, deci
# fiecare nod luat separat n-ar trece garda de talpa. Piesele cu un singur nod
# (pe atlas) trec pe originea implicita.
for f in rocks/marble_block_a.glb rocks/marble_block_b.glb rocks/marble_block_c.glb          rocks/block_stack_a.glb rocks/block_stack_b.glb rocks/block_informe_b.glb          rocks/rubble_pile_a.glb rocks/rubble_pile_b.glb structures/safety_berm.glb          props/work_lamp.glb props/pipe_run.glb; do
  check "$f" --origin=assembly
done
for f in props/cable_reel.glb props/water_tank.glb props/fuel_tank.glb          buildings/office_container.glb props/quarry_sign_a.glb props/quarry_sign_b.glb; do
  check "$f"
done
# noduri, cote fata de tabel, sloturi interzise (FOAM_WHITE 22, CAR_* 14-16),
# capete identice la modulele de 6 m (berma, conductele)
python tools/blender/measure_crr_kit.py || fail=1

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
