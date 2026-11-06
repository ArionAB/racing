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


# --- val 1, grupul C ---
# Elefantul asiatic (kit 1.3). Aceleasi flaguri ca elefantul din Serengeti
# (verify_serengeti.sh: --origin=assembly) si plafon de triunghiuri propriu
# (plasa 3000, ca acolo: meshul e rigat si decimat la ~1100). Garda de cote
# (umar, lungime, oase, animatii, radacina) e measure_angkor_w1c.py, cu selftest.
echo
echo "== val 1, grupul C: elefantul asiatic =="
ELE="$ROOT/animals/asian_elephant.glb"
BIG_SAVE=$BIG; BIG=3000
check "animals/asian_elephant.glb" --origin=assembly
BIG=$BIG_SAVE
if [ -f "$ELE" ]; then
  python tools/blender/measure_angkor_w1c.py elephant "$ELE" || fail=1
  st=$(python tools/blender/measure_angkor_w1c.py --selftest "$ELE" 2>&1); rc=$?
  printf '%s
' "$st" | grep -E "^-- sabotaj|garda a|SELFTEST"
  [ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei elefantului a esuat"; fail=1; }
fi
# --- sfarsit val 1, grupul C ---

# --- val 1, grupul B ---
echo
echo "== val 1, grupul B: aw_west_gopura + ta_prohm_tree_gate (kit §1.2) =="
GB_G="$ROOT/structures/aw_west_gopura.glb"; GB_T="$ROOT/structures/ta_prohm_tree_gate.glb"
check "structures/aw_west_gopura.glb" --origin=assembly
check "structures/ta_prohm_tree_gate.glb" --origin=assembly
if [ -f "$GB_G" ] && [ -f "$GB_T" ]; then
  python tools/blender/measure_angkor_w1b.py gopura "$GB_G" || fail=1
  python tools/blender/measure_angkor_w1b.py treegate "$GB_T" || fail=1
  st=$(python tools/blender/measure_angkor_w1b.py --selftest "$GB_G" "$GB_T" 2>&1); rc=$?
  printf '%s
' "$st" | grep -E "^-- sabotaj|garda a|SELFTEST"
  [ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei grupului B a esuat"; fail=1; }
fi
# --- sfarsit grupul B ---
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

# --- val 2, grupul B ---
echo
echo "== val 2, grupul B: bolta intacta/prabusita, blocul dominoului, sprijinul (kit 1.5) =="
W2="tools/blender/measure_angkor_w2b.py"
check "kit/vault_intact.glb" --origin=assembly
check "kit/vault_broken.glb" --origin=assembly
check "props/fallen_block.glb" --origin=assembly
check "props/restoration_prop.glb" --origin=assembly
if [ -f "$ROOT/kit/vault_intact.glb" ] && [ -f "$ROOT/kit/vault_broken.glb" ] && [ -f "$ROOT/props/fallen_block.glb" ]; then
  python $W2 vault_intact "$ROOT/kit/vault_intact.glb" || fail=1
  python $W2 vault_broken "$ROOT/kit/vault_broken.glb" || fail=1
  python $W2 block "$ROOT/props/fallen_block.glb" || fail=1
  python $W2 prop "$ROOT/props/restoration_prop.glb" || fail=1
  st=$(python $W2 --selftest "$ROOT/kit/vault_intact.glb" "$ROOT/kit/vault_broken.glb" "$ROOT/props/fallen_block.glb" 2>&1); rc=$?
  printf '%s
' "$st" | grep -E "^-- sabotaj|garda a|SELFTEST"
  [ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei grupului B (val 2) a esuat"; fail=1; }
fi
# --- sfarsit val 2, grupul B ---
# --- val 2, grupul A ---
echo
echo "== val 2, grupul A: terasa elefantilor, stalp, Regele Lepros, radacina-rampa (kit 1.4) =="
W2="tools/blender/measure_angkor_w2a.py"
check "kit/elephant_terrace_module.glb" --origin=assembly
check "kit/elephant_terrace_end.glb" --origin=assembly
check "kit/elephant_trunk_pillar.glb" --origin=assembly
check "props/leper_king_statue.glb" --origin=assembly
check "kit/giant_root_ramp.glb" --origin=assembly
if [ -f "$ROOT/kit/elephant_terrace_module.glb" ] && [ -f "$ROOT/kit/giant_root_ramp.glb" ]; then
  python $W2 terrace "$ROOT/kit/elephant_terrace_module.glb" "$ROOT/kit/elephant_terrace_end.glb" || fail=1
  python $W2 pillar "$ROOT/kit/elephant_trunk_pillar.glb" || fail=1
  python $W2 statue "$ROOT/props/leper_king_statue.glb" || fail=1
  python $W2 ramp "$ROOT/kit/giant_root_ramp.glb" || fail=1
  st=$(python $W2 --selftest "$ROOT/kit/elephant_terrace_module.glb" "$ROOT/kit/giant_root_ramp.glb" 2>&1); rc=$?
  printf '%s
' "$st" | grep -E "^-- sabotaj|garda a|SELFTEST"
  [ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei grupului A (val 2) a esuat"; fail=1; }
fi
# --- sfarsit val 2, grupul A ---
# --- val 2, grupul C ---
echo
echo "== val 2, grupul C: naga (balustrada, gap, cap) + uriasii deva/asura (kit 1.5) =="
W2="tools/blender/measure_angkor_w2c.py"
for F in naga_balustrade naga_balustrade_gap naga_head deva_giant asura_giant; do
  check "kit/$F.glb" --origin=assembly
done
KB="$ROOT/kit"
if [ -f "$KB/naga_balustrade.glb" ] && [ -f "$KB/deva_giant.glb" ]; then
  python $W2 balustrade "$KB/naga_balustrade.glb" || fail=1
  python $W2 gap "$KB/naga_balustrade_gap.glb" || fail=1
  python $W2 head "$KB/naga_head.glb" || fail=1
  python $W2 giant "$KB/deva_giant.glb" || fail=1
  python $W2 giant "$KB/asura_giant.glb" || fail=1
  st=$(python $W2 --selftest "$KB/naga_balustrade.glb" "$KB/deva_giant.glb" 2>&1); rc=$?
  printf '%s
' "$st" | grep -E "^-- sabotaj|garda a|SELFTEST"
  [ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei grupului C (val 2) a esuat"; fail=1; }
fi
# --- sfarsit val 2, grupul C ---

# --- val 3, grupul A ---
echo
echo "== val 3, grupul A: templul Angkor Wat (kit 1.2) =="
W3="tools/blender/measure_angkor_w3a.py"
check "structures/angkor_wat_temple.glb" --origin=assembly
if [ -f "$ROOT/structures/angkor_wat_temple.glb" ]; then
  python $W3 temple "$ROOT/structures/angkor_wat_temple.glb" || fail=1
  st=$(python $W3 --selftest "$ROOT/structures/angkor_wat_temple.glb" 2>&1); rc=$?
  printf '%s
' "$st" | grep -E "^-- sabotaj|garda a|SELFTEST"
  [ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei grupului A (val 3) a esuat"; fail=1; }
fi
# --- sfarsit val 3, grupul A ---
# --- val 3, grupul C ---
echo
echo "== val 3, grupul C: debarcader, tuk-tuk (2 radacini), calugar, blocuri mici (kit 1.4-1.6) =="
W3="tools/blender/measure_angkor_w3c.py"
# debarcaderul are originea la cota platformei (geometria incaleca Y=0, ca la ponton): --origin=waterline
check "structures/srah_srang_landing.glb" --origin=waterline
check "vehicles/tuk_tuk.glb" --origin=assembly
check "animals/monk_standing.glb" --origin=assembly
check "props/laterite_block.glb" --origin=assembly
check "props/rubble_pile.glb" --origin=assembly
check "props/numbered_block.glb" --origin=assembly
if [ -f "$ROOT/vehicles/tuk_tuk.glb" ] && [ -f "$ROOT/structures/srah_srang_landing.glb" ]; then
  python $W3 landing "$ROOT/structures/srah_srang_landing.glb" || fail=1
  python $W3 tuk "$ROOT/vehicles/tuk_tuk.glb" || fail=1
  python $W3 monk "$ROOT/animals/monk_standing.glb" || fail=1
  python $W3 laterite "$ROOT/props/laterite_block.glb" || fail=1
  python $W3 rubble "$ROOT/props/rubble_pile.glb" || fail=1
  python $W3 numbered "$ROOT/props/numbered_block.glb" || fail=1
  st=$(python $W3 --selftest "$ROOT/vehicles/tuk_tuk.glb" "$ROOT/structures/srah_srang_landing.glb" 2>&1); rc=$?
  printf '%s
' "$st" | grep -E "^-- sabotaj|garda a|SELFTEST"
  [ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei grupului C (val 3) a esuat"; fail=1; }
fi
# --- sfarsit val 3, grupul C ---
# --- val 3, grupul B ---
echo
echo "== val 3, grupul B: galeria (stalp, acoperis, zid de relief, colt) + Bakheng (etaj, turnulet, scara) (kit 1.5) =="
W3="tools/blender/measure_angkor_w3b.py"
KB3="$ROOT/kit"
for F in gallery_column gallery_roof gallery_relief_wall gallery_corner bakheng_terrace_tier bakheng_shrine_tower bakheng_side_stair; do
  check "kit/$F.glb" --origin=assembly
done
if [ -f "$KB3/gallery_column.glb" ] && [ -f "$KB3/gallery_roof.glb" ] && [ -f "$KB3/bakheng_side_stair.glb" ]; then
  python $W3 column "$KB3/gallery_column.glb" || fail=1
  python $W3 roof "$KB3/gallery_roof.glb" || fail=1
  python $W3 wall "$KB3/gallery_relief_wall.glb" || fail=1
  python $W3 corner "$KB3/gallery_corner.glb" || fail=1
  python $W3 tier "$KB3/bakheng_terrace_tier.glb" || fail=1
  python $W3 shrine "$KB3/bakheng_shrine_tower.glb" || fail=1
  python $W3 stair "$KB3/bakheng_side_stair.glb" || fail=1
  st=$(python $W3 --selftest "$KB3" 2>&1); rc=$?
  printf '%s\n' "$st" | grep -E "^-- sabotaj|garda a|SELFTEST"
  [ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei grupului B (val 3) a esuat"; fail=1; }
fi
# --- sfarsit val 3, grupul B ---

# --- val 4, grupul A ---
echo
echo "== val 4, grupul A: copaci Ta Prohm / Cambodgia (tetrameles a/b, dipterocarp, palmier de zahar, kit 1.7) =="
W4="tools/blender/measure_angkor_w4a.py"
for F in tetrameles_a tetrameles_b dipterocarp sugar_palm; do
  check "plants/$F.glb" --origin=assembly
done
if [ -f "$ROOT/plants/tetrameles_a.glb" ] && [ -f "$ROOT/plants/sugar_palm.glb" ]; then
  python $W4 tetrameles "$ROOT/plants/tetrameles_a.glb" || fail=1
  python $W4 tetrameles "$ROOT/plants/tetrameles_b.glb" || fail=1
  python $W4 dipterocarp "$ROOT/plants/dipterocarp.glb" || fail=1
  python $W4 palm "$ROOT/plants/sugar_palm.glb" || fail=1
  st=$(python $W4 --selftest "$ROOT/plants/tetrameles_a.glb" 2>&1); rc=$?
  printf '%s
' "$st" | grep -E "^-- sabotaj|garda a|SELFTEST"
  [ "$rc" -eq 0 ] || { echo "   !! selftest-ul gardei grupului A (val 4) a esuat"; fail=1; }
fi
# --- sfarsit val 4, grupul A ---

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
