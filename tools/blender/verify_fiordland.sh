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
check "rocks/chasm_rock.glb"        600
check "rocks/guard_rock.glb"         80
check "rocks/scree_slab.glb"        300

# Valurile urmatoare (§1.2-§1.7) isi adauga liniile aici pe masura ce se
# construiesc: fundalul, satul, padurea, avalansa, vehiculele, animalele.
# Pana atunci nu apar in verdict — kitul se livreaza in valuri (brief §3).

echo
total=$(find "$ROOT" -name '*.glb' 2>/dev/null | wc -l)
echo "GLB-uri in $ROOT: $total"
if [ "$fail" -eq 0 ]; then echo "VERDICT KIT: OK"; else echo "VERDICT KIT: PROBLEME"; fi
exit "$fail"
