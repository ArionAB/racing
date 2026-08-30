extends Node3D
## Ce culori are DE FAPT modulul de faleza pe ecran: citesc UV-ul fiecarui
## vertex, il traduc in slot si insumez aria. Memoria `aria-slotului-spune-cat`:
## slotul se identifica din UV, nu din numele piesei.

func _ready() -> void:
	await get_tree().process_frame
	var scn := load("res://assets/models/cappadocia/rocks/chimney_c.glb")
	var inst := (scn as PackedScene).instantiate()
	add_child(inst)
	var area := {}
	for mi in _all_mesh(inst):
		var m := mi.mesh
		for si in m.get_surface_count():
			var arr := m.surface_get_arrays(si)
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			var vx: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var ix: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			for t in range(0, ix.size(), 3):
				var a := vx[ix[t]]
				var b := vx[ix[t + 1]]
				var c := vx[ix[t + 2]]
				var ar := (b - a).cross(c - a).length() * 0.5
				var slot := int(uv[ix[t]].x * 32.0)
				area[slot] = float(area.get(slot, 0.0)) + ar
	var keys := area.keys()
	keys.sort()
	var tot := 0.0
	for k in keys:
		tot += area[k]
	for k in keys:
		print("  slot %2d  %s  aria %.1f m2  (%.1f%%)"
			% [k, Palette.HEX[k], area[k], 100.0 * area[k] / tot])
	get_tree().quit()

func _all_mesh(n: Node) -> Array[MeshInstance3D]:
	var r: Array[MeshInstance3D] = []
	if n is MeshInstance3D:
		r.append(n)
	for c in n.get_children():
		r.append_array(_all_mesh(c))
	return r
