@tool
extends Node3D
## Pentru un prop GLB asezat de mana in editor. Ii pune pe fiecare parte
## materialul corect: textura de CLASA acolo unde partea are UV-uri reale
## (scoarta, beton, olane, tencuiala), atlasul comun peste tot restul.
##
## De ce nu doar atlasul, ca inainte: contractul atlasului (vezi palette.gd) cere
## UV-uri COLAPSATE pe centrul slotului — o fata = un texel = o culoare. Un GLB
## venit din kit, cu unwrap real, matura in schimb intreaga latime a atlasului si
## culege toate cele 32 de sloturi, inclusiv rezerva 24..31 care e MAGENTA
## intentionat (generate_palette_atlas.gd o lasa asa ca greseala de UV sa sara in
## ochi). Rezultatul, vazut pe Okinawa manual: tetrapozi in dungi curcubeu cu
## benzi magenta, trunchiuri de palmier vargate, zidul de piatra al casei la fel.
##
## Masurat pe assets-urile insulei: Tetrapod_* matura 29-32 de sloturi,
## Banyan_Bark 32, Palm_Bark 31, House_Stone 28, BentPalm_Bark 24. Doar
## House_Sand respecta contractul (u 0.016 .. 0.016, colapsat).
##
## Codul procedural stia deja asta — track.gd trece landmark-urile cu "classes"
## prin apply_class_materials si scrie negru pe alb ca apply_world_material le-ar
## face dungi. Ce lipsea era calea MANUALA: docs/decor_manual.md spune sa pui
## scriptul asta pe container, deci scriptul asta trebuie sa faca aceeasi treaba.
##
## `apply_class_materials` cade oricum pe materialul lumii pentru partile
## nemapate, deci e un inlocuitor direct: prop-urile facute in casa, cu UV-uri pe
## sloturi, se comporta exact ca inainte.
func _ready() -> void:
	Palette.apply_class_materials(self, _prop_classes())


## Maparea nume-de-parte -> clasa de material, adunata din sursele EXISTENTE.
##
## Nu e o copie: ISLAND_CLASSES si tabelul de landmark-uri rămân singurul adevar,
## iar aici doar se citesc. O a doua listă scrisa de mana ar rămâne in urma la
## primul asset nou — exact capcana descrisa in track08.gd despre punctele de
## control duplicate.
static func _prop_classes() -> Dictionary:
	var out := {}
	out.merge(TrackDecor.ISLAND_CLASSES)
	out.merge(TrackDecor.BAIKAL_CLASSES)
	for id: int in Track._LANDMARKS:
		var info: Dictionary = Track._LANDMARKS[id]
		if info.has("classes"):
			out.merge(info["classes"])
	return out
