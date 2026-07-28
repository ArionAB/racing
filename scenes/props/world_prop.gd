@tool
extends Node3D
## Pentru un prop GLB asezat de mana in editor care respecta contractul de atlas
## (UV-urile arata spre sloturi de culoare, AO copt in vertex colors, FARA material
## propriu — vezi docs/blender_export.md). Aplica materialul comun al lumii pe tot
## subarborele: prop-ul isi preia culorile din sloturile spre care arata UV-urile
## lui si se grupeaza cu restul lumii intr-un singur draw call.
##
## Fara asta, un GLB exportat fara material iese ALB (Godot pune un material
## implicit si ignora vertex color-urile). Ruleaza si in editor (@tool) ca decorul
## sa se vada corect inca de la asezare.
func _ready() -> void:
	Palette.apply_world_material(self)
