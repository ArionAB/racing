#!/usr/bin/env bash
# Verifica kitul Jodhpur fata de contractul din
# docs/asset_briefs/jodhpur_kit.md. Ca `verify_fiordland.sh`: o rulare, un
# verdict, exceptiile DECLARATE aici.
#
#     bash tools/blender/verify_jodhpur.sh
#
# Structura: fiecare val al brief-ului (§3) adauga liniile lui aici. Valul 1
# (pilotul, §1.1) e primul si singurul complet la scrierea asta.
#
# Exceptii, fiecare cu motivul:
#
#   --origin=assembly   ghanta_ghar: 3 noduri (Tower_Stone, Clock_Glow,
#                       Tower_Glow) cu origine COMUNA -- Clock_Glow/
#                       Tower_Glow sunt geometrie mica, ingropata in peretii
#                       lui Tower_Stone, si nu ating solul separat prin
#                       constructie (aceeasi capcana ca la Machu Picchu/
#                       Fiordland: `finish()` per nod le-ar re-centra
#                       independent si ansamblul s-ar desface).
#
#                       blue_house_a: 3 noduri (House_Wall, House_Trim,
#                       House_Rail) cu acelasi motiv -- House_Trim (usa,
#                       obloanele) si House_Rail (balustrada scarii) nu ating
#                       solul la baza LOR proprie de bounding box.

set -u
cd "$(dirname "$0")/../.." || exit 1
ROOT="assets/models/jodhpur"

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

echo "== pilotul (brief §1.1, val 1) =="
check "buildings/ghanta_ghar.glb"   5200 --origin=assembly
check "buildings/blue_house_a.glb"  1800 --origin=assembly

echo
total=$(find "$ROOT" -name '*.glb' 2>/dev/null | wc -l)
echo "GLB-uri in $ROOT: $total"
if [ "$fail" -eq 0 ]; then echo "VERDICT KIT: OK"; else echo "VERDICT KIT: PROBLEME"; fi
exit "$fail"
