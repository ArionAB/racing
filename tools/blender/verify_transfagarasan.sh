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
# Fara plafon de triunghiuri (CLAUDE.md): bugetul dat lui verify_glb e doar o
# plasa de siguranta (1.000.000). Garzi suplimentare:
#   - scala/rotatia aplicate pe nodurile radacina (memoria scala-glb-neaplicata-
#     la-radacina)
#   - golul portalului, MASURAT CA GOL (measure_tf_gap.py): >= 13,0 m lateral pe
#     banda caroseriei 0-2 m, >= 7,0 m inaltime libera in |x| <= 6,5 (kit §1.1, contract nou)
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
echo "== valul 1, tf-c: ursul animat (kit §1.6) =="
# Fara exceptii de origine: un singur mesh skinnuit, baza la 0, centrat; armatura
# la identitate pe nodul radacina (nimic de aplicat). Garda in plus: clipurile
# exact Idle/Walk/Stand (contractul cu SlidingHazard.ANIM_*), citite din GLB.
check "animals/brown_bear.glb"
if [ -f "$ROOT/animals/brown_bear.glb" ]; then
  python tools/blender/check_glb_anims.py "$ROOT/animals/brown_bear.glb" Idle Walk Stand || fail=1
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
