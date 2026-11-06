#!/usr/bin/env bash
# Verifica kitul Angkor fata de docs/asset_briefs/angkor_kit.md.
# Pe tiparul verify_carrara.sh: o rulare, un verdict, exceptiile DECLARATE.
#
#     bash tools/blender/verify_angkor.sh
#
# Verdictul verde NU e livrare (memoria harnasul-de-kit-nu-vede-forma-nici-
# culoarea): forma si fetele se accepta doar dupa comparatia alaturata
# (`preview_angkor.py --compare <nume>`) si capturile `--gamecam`, vazute de
# coordonator.
#
# Exceptii, fiecare cu motivul:
#   --origin=assembly   piesele au mai multe noduri pe rol (*_Stone/_Lichen/
#                       _Streak); offsetul de origine e calculat O DATA pe
#                       ansamblu (lichenul si darele n-ating solul).
# Fara plafon de triunghiuri (CLAUDE.md): bugetul dat lui verify_glb e doar o
# plasa de siguranta (1.000.000). Garzi suplimentare:
#   - scala/rotatia aplicate pe nodurile radacina (memoria scala-glb-neaplicata-
#     la-radacina) -- in measure_angkor.py
#   - anvelopa turnului Bayon (measure_angkor.py bayon, pe GLB, coordonate
#     Godot): nimic dincolo de +-1,5 m pe X/Z, inaltime 9,0 +-0,1, min Y ~ 0,
#     numele nodurilor, lichen portocaliu sub 3% din arie, doar sloturile din
#     tabel; `--selftest` dovedeste ca garda pica pe copii sabotate
#   - orice GLB din assets/models/angkor/ NEdeclarat e verificat fara exceptii.

set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="assets/models/angkor"
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
}

echo "== pilotul (kit §1.1, val 0): turnul Bayon =="
check "structures/bayon_face_tower_a.glb" --origin=assembly
if [ -f "$ROOT/structures/bayon_face_tower_a.glb" ]; then
  python tools/blender/measure_angkor.py bayon "$ROOT/structures/bayon_face_tower_a.glb" || fail=1
  st=$(python tools/blender/measure_angkor.py --selftest "$ROOT/structures/bayon_face_tower_a.glb" 2>&1); rc=$?
  printf '%s
' "$st" | grep -E "^-- sabotaj|garda a|SELFTEST"
  [ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei a esuat"; fail=1; }
fi

# --- val 1, grupul A ---
echo
echo "== val 1, grupul A: turnurile Bayon b/c + Poarta de Sud =="
for L in b c; do
  check "structures/bayon_face_tower_$L.glb" --origin=assembly
  if [ -f "$ROOT/structures/bayon_face_tower_$L.glb" ]; then
    python tools/blender/measure_angkor.py bayon "$ROOT/structures/bayon_face_tower_$L.glb" || fail=1
  fi
done
check "structures/south_gate_face_tower.glb" --origin=assembly
if [ -f "$ROOT/structures/south_gate_face_tower.glb" ]; then
  python tools/blender/measure_angkor_w1a.py gate "$ROOT/structures/south_gate_face_tower.glb" || fail=1
  st=$(python tools/blender/measure_angkor_w1a.py --selftest "$ROOT/structures/south_gate_face_tower.glb" 2>&1); rc=$?
  printf '%s
' "$st" | grep -E "^-- sabotaj|garda a|SELFTEST"
  [ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei Portii a esuat"; fail=1; }
fi
# --- sfarsit val 1, grupul A ---

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
