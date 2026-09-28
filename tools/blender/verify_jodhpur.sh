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
#
#                       fort_gate_jai/fateh/loha: 2 noduri (*_Stone, *_Doors)
#                       -- canaturile deschise (*_Doors) nu ating solul la
#                       baza lor proprie de bounding box (balamale sus pe
#                       perete, canatul se roteste deschis). rampart_cannon:
#                       2 noduri (Cannon_Metal, Cannon_Wood) -- teava e
#                       inclinata ~10 deg si nu atinge solul la baza proprie.

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
# Bugetele au crescut fata de v1 (5200/1800) odata cu rescrierea pe
# vocabularul de forme (arcade/dome/chhatri/solid_stair reale, nu cutii
# tesite). v3 (runda 3 -- forme corectate dupa critic+sef) a scazut fata
# de v2 (8154 vs 10156 turn): panourile "box-margin" (fix runda 3) sunt mai
# ieftine decat inelul radial vechi.
check "buildings/ghanta_ghar.glb"   8600 --origin=assembly
check "buildings/blue_house_a.glb"  5300 --origin=assembly

echo "== cetatea (brief §1.2, val 2a) =="
# Bugetele: masurate dupa build, cu marja mica pentru iteratii ulterioare de
# fidelitate (crenelurile marite de doua ori dupa --compare au crescut usor
# tri-count-ul fata de prima versiune). rampart_cannon a primit buget mai
# mare (3000 -> 3300) dupa rescrierea rotii cu spite vizibile (janta+butuc+
# bare, nu disc plin fara relief).
check "structures/fort_wall_segment.glb"  900  --origin=assembly
check "structures/fort_wall_turret.glb"   1300 --origin=assembly
check "structures/fort_bastion.glb"       3400 --origin=assembly
check "structures/fort_gate_jai.glb"      4200 --origin=assembly
check "structures/fort_gate_fateh.glb"    6200 --origin=assembly
check "structures/fort_gate_loha.glb"     4200 --origin=assembly
check "structures/palace_facade_a.glb"    15000 --origin=assembly
check "structures/palace_facade_b.glb"    14000 --origin=assembly
check "props/rampart_cannon.glb"          3300 --origin=assembly

echo
total=$(find "$ROOT" -name '*.glb' 2>/dev/null | wc -l)
echo "GLB-uri in $ROOT: $total"
if [ "$fail" -eq 0 ]; then echo "VERDICT KIT: OK"; else echo "VERDICT KIT: PROBLEME"; fi
exit "$fail"
