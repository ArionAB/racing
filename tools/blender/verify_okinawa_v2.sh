#!/usr/bin/env bash
# Verifica kitul Okinawa v2 fata de docs/asset_briefs/okinawa_kit_v2.md.
# Pe tiparul verify_monumentvalley.sh: o rulare, un verdict, exceptiile DECLARATE.
# `verify_okinawa.sh` ramane al kitului vechi (Track08) si NU se atinge.
#
#     bash tools/blender/verify_okinawa_v2.sh
#
# Verdictul verde NU e livrare (memoria harnasul-de-kit-nu-vede-forma-nici-
# culoarea): piesa se accepta doar dupa comparatia alaturata decupare | randare
# (`preview_okinawa.py --compare <nume>`), vazuta de coordonator.
#
# Exceptii, fiecare cu motivul:
#   --origin=assembly            piesele au mai multe noduri pe rol (lac / olane /
#                                mortar / calcar / aur); offsetul de origine e
#                                calculat o data pe ansamblu, ansamblul atinge solul.
#   --allow-car-slots=Gate_Gold  ornamentele aurii sunt CAR_YELLOW (16), puncte mici
#                                (kit §0, tabelul de sloturi).
# Garzi suplimentare (nu le face verify_glb.py):
#   - scala/rotatia aplicate pe nodurile radacina (memoria scala-glb-neaplicata-
#     la-radacina)
#   - golul portii, masurat ca GOL (measure_gap.py): lateral >= 14,0 m pe banda
#     0,15-2,0 m, inaltime libera >= 6,0 m pe tot golul (contract §1.1)

set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="assets/models/okinawa"

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
  # scala aplicata pe radacini
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
  local out
  out=$(python tools/blender/measure_gap.py "$f" --band=0.15,2.0 --need="$3" 2>&1)
  local gap clear util
  gap=$(printf '%s' "$out" | awk '$1=="gap"{print $2}')
  clear=$(printf '%s' "$out" | awk '$1=="clear_min"{print $2}')
  util=$(printf '%s' "$out" | awk '$1=="usable_gap"{print $2}')
  if python -c "import sys; g,c,u=float('${gap:-0}'),float('${clear:-0}'),float('${util:-0}'); sys.exit(0 if g>=$2 and c>=$3 and u>=$2 else 1)"; then
    printf "%-34s GOL: OK   lateral %s m (>= %s), inaltime libera %s m (>= %s), gol util %s m\n" \
      "$(basename "$f")" "$gap" "$2" "$clear" "$3" "$util"
  else
    printf "%-34s GOL: SUB CONTRACT   lateral %s (>= %s), inaltime libera %s (>= %s), gol util %s\n" \
      "$(basename "$f")" "${gap:-?}" "$2" "${clear:-?}" "$3" "${util:-?}"
    fail=1
  fi
}

echo "== pilotul (kit §3, val 0): poarta =="
check "structures/ryukyu_gate.glb" 40000 --origin=assembly --allow-car-slots=Gate_Gold
gap_check "structures/ryukyu_gate.glb" 14.0 6.0

echo
echo "== val 1, ok-b: coasta =="
# --origin=assembly: piesele au mai multe noduri (calcar / iarba / tencuiala / metal);
# offsetul de origine e calculat o data pe ansamblu, ansamblul atinge solul.
check "rocks/notch_rock_a.glb" 2000 --origin=assembly
check "rocks/notch_rock_b.glb" 2000 --origin=assembly
check "rocks/notch_rock_c.glb" 2000 --origin=assembly
check "rocks/heart_rock.glb" 2500 --origin=assembly
check "rocks/limestone_cliff_module.glb" 3500 --origin=assembly
check "buildings/cape_lighthouse.glb" 6000 --origin=assembly
check "structures/coral_stone_wall.glb" 1500 --origin=assembly

if [ "$fail" -eq 0 ]; then echo "VERDICT KIT: OK"; else echo "VERDICT KIT: PROBLEME"; fi
exit "$fail"
