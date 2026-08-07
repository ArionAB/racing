#!/usr/bin/env bash
# Verifica tot kitul Okinawa fata de contractul din docs/blender_export.md.
#
# Bugetele sunt per NOD, nu per fisier, si sunt puse cu ~15% marja peste ce
# masoara azi cel mai scump nod din fisier — destul cat sa prinda clasa de
# accident care conteaza (o primitiva lasata la rezolutia implicita sare cu
# zeci de mii dintr-un foc), fara sa respinga o corectie de forma legitima.
#
#   bash tools/blender/verify_okinawa.sh
#
# Iese cu 1 daca vreun fisier nu da OK.
set -u
cd "$(dirname "$0")/../.."

fail=0
check() {
	name=$(basename "$1")
	out=$(python tools/blender/verify_glb.py "$@" 2>&1)
	verdict=$(printf '%s' "$out" | grep -E "^VERDICT" | sed 's/VERDICT: //')
	printf "%-28s %s\n" "$name" "$verdict"
	printf '%s' "$out" | grep -E "^\s*!!" || true
	printf '%s' "$out" | grep -q "VERDICT: OK" || fail=1
}

check assets/models/structures/tetrapod.glb 4000 --class-parts=Tetrapod_01,Tetrapod_04,Tetrapod_Stack_01
check assets/models/rocks/coral_rock.glb 900
check assets/models/scatter/island_scatter.glb 500
check assets/models/structures/sea_wall_segment.glb 400 --class-parts=Sea_Wall_A,Sea_Wall_B,Sea_Wall_C
check assets/models/trees/coconut_palm.glb 2000 --class-parts=Palm_Bark --origin=assembly
check assets/models/trees/beach_palm_bent.glb 1600 --class-parts=BentPalm_Bark --origin=assembly
check assets/models/trees/pandanus.glb 2400 --class-parts=Pandanus_Bark --origin=assembly
check assets/models/trees/banyan.glb 5200 --class-parts=Banyan_Bark --origin=assembly
check assets/models/plants/hibiscus_bush.glb 900
check assets/models/plants/sugar_cane_clump.glb 4000
check assets/models/structures/stone_gate_torii.glb 1200 --class-parts=Torii_Stone,Torii_Roof --origin=assembly
check assets/models/buildings/lighthouse.glb 3000 --class-parts=Lighthouse_Stone,Lighthouse_White --origin=assembly
check assets/models/props/shisa_statue.glb 5000 --class-parts=Shisa_Base,Shisa_Stone --origin=assembly
check assets/models/props/shisa_statue_closed.glb 5000 --class-parts=Shisa_Base,Shisa_Stone --origin=assembly
check assets/models/structures/gusuku_wall.glb 2500 --class-parts=Gusuku_Wall_A,Gusuku_Wall_B,Gusuku_Wall_C
check assets/models/vehicles/sabani_boat.glb 1500 --class-parts=Sabani_Hull --origin=assembly
check assets/models/scatter/beach_clutter.glb 1300
check assets/models/effects/horizon_island.glb 400
check assets/models/effects/wave_surge.glb 600 --origin=assembly
check assets/models/structures/wooden_pier.glb 2600 --class-parts=Pier_Wood --origin=waterline

exit $fail
