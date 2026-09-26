@tool
class_name WoodDeckStrip
extends Node3D
## Fasie plana pe atlas, urmarind un sir de puncte cu latime variabila —
## mecanismul comun pentru DOUA decoruri POI D (Fiordland, Chasm):
## tabliera de scanduri a podetului (`slot` = WOOD_WEATHERED, implicit) SI
## panza de apa alba a raului Cleddau de sub el (`slot` = FOAM_WHITE),
## instantiat de doua ori cu puncte diferite. Aceeasi geometrie (placi plane
## intre puncte coapte, memoria `suprafete-din-placi-plane`), doua roluri.
##
## Podetul de scanduri de peste Chasm (POI D, Fiordland brief §2 randul D:
## "podetul de scanduri de 40 m peste Chasm... podet 0,85x grip (lemn ud)").
##
## [b]De ce nu e un pod cu gol (`LiftBridgeHazard`/`TrackChannel`).[/b] Masurat
## cu sonda pe teren (`tools/sv_fiord_bridge_terrain.gd`, folosinta unica,
## stearsa): pe axa drumului solul e la doar ~0,3 m sub asfalt pe tot
## intervalul 0,406-0,424 — rapa "raul D" (custom_ravines index 1, side -1)
## sapa lateral, incepand de la ~12 m de axa, nu SUB drum. Drumul merge pe
## COAMA/marginea vaii, nu peste un gol transversal. Un `LiftBridgeHazard`
## (gaura reala in asfalt) ar fi taiat o gaura acolo unde e teren solid —
## verificat cu raycast dupa constructie, prototip respins (vezi istoricul PR).
## Solutia corecta pentru geometria reala: SUPRAFATA de lemn peste asfaltul
## existent (grip separat prin `Track.custom_loose_ranges`/`loose_grip`,
## NU geometrie noua de carosabil), plus balustrada si raul vazute in vale,
## pe partea -1.
##
## [b]De ce placi plane, nu o banda curbata.[/b] Coarda intervalului (0,406-
## 0,424) are doar 1,16% deviatie fata de arcul real (37,96 m arc / 37,52 m
## coarda) — sub pragul la care abaterea s-ar vedea de la camera de joc.
## Memoria `suprafete-din-placi-plane`: fiecare placa e liniara intre cele doua
## capete ei (nu smoothstep), iar muchiile CAD PE PUNCTELE COAPTE date, nu pe
## o subdiviziune aleasa — trei placi ajung pentru variatia reala de latime
## (6,5 -> 6,5 -> 6,5 -> 5,5 m).
##
## Zero material nou: implicit `WOOD_WEATHERED` (9), acelasi slot ca
## podetul/pontonul din paleta (§4 randul "podetul, balustradele, pontonul").
## Raul foloseste `FOAM_WHITE` (22), slotul lui FoamPool/WaterfallVisual.
const WOOD_SLOT: int = 9   # Palette.WOOD_WEATHERED
## Cat de sus deasupra suprafetei de sub ea sta fasia — peste orice decal
## existent (linia de mijloc 0.045, marcaje 0.03-0.038), sub balustrada.
const DECK_LIFT: float = 0.06
## Grosimea vizuala a fasiei (fata de sus la DECK_LIFT, talpa mai jos).
const DECK_THICK: float = 0.12


## Punctele coapte ale axei fasiei, in coordonatele PARINTELUI (nu locale la
## acest nod — se scriu direct din Track.baked la constructia scenei).
## Minim 2 puncte.
@export var points: Array[Vector3] = []
## Vectorul lateral ("side_at") la fiecare punct, aceeasi lungime ca `points`.
@export var sides: Array[Vector3] = []
## Jumatatea de latime la fiecare punct (width_at_index pentru pod, latimea
## albiei pentru rau).
@export var half_widths: Array[float] = []
## Slotul de paleta: WOOD_WEATHERED (implicit, podet) sau FOAM_WHITE (rau).
@export var slot: int = WOOD_SLOT
## Grosimea vizuala si liftul, suprascriabile (raul sta pe teren neregulat,
## nu pe asfalt neted — un lift mai mare evita z-fighting cu solul).
@export var lift: float = DECK_LIFT
@export var thickness: float = DECK_THICK


func _ready() -> void:
	if points.size() >= 2 and get_child_count() == 0:
		build()


func build() -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	if points.size() < 2 or sides.size() != points.size() \
			or half_widths.size() != points.size():
		return
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in points.size() - 1:
		var p0: Vector3 = to_local(points[i]) + Vector3.UP * lift
		var p1: Vector3 = to_local(points[i + 1]) + Vector3.UP * lift
		var s0: Vector3 = sides[i]
		var s1: Vector3 = sides[i + 1]
		var hw0: float = half_widths[i]
		var hw1: float = half_widths[i + 1]
		var a := p0 - s0 * hw0
		var b := p0 + s0 * hw0
		var c := p1 + s1 * hw1
		var d := p1 - s1 * hw1
		PaletteBox.quad_slab(st, a, b, c, d, thickness, slot, i == 0
			or i == points.size() - 2, true)
	var mi := PaletteBox.emit(st, name + "Mesh")
	if mi != null:
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(mi)
