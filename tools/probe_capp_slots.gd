extends Node
## Ce SLOTURI de paleta matura modulul de faleza, si cu ce arie. Fara asta,
## "e prea crem" ramane o parere: aria spune CAT, hexul spune CE.

const PATH := "res://assets/models/rocks/rock_medium.glb"

func _ready() -> void:
	var ps := load(PATH) as PackedScene
	var inst := ps.instantiate()
	var area := {}
	for mi in inst.find_children("*", "MeshInstance3D", true, false):
		var mesh := (mi as MeshInstance3D).mesh
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var arr := mesh.surface_get_arrays(s)
			var vt: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
			var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
			var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
			if uv.size() == 0:
				print("  surface ", s, " FARA UV")
				continue
			var count := idx.size() if idx.size() > 0 else vt.size()
			var i := 0
			while i + 2 < count:
				var a := idx[i] if idx.size() > 0 else i
				var b := idx[i + 1] if idx.size() > 0 else i + 1
				var c := idx[i + 2] if idx.size() > 0 else i + 2
				var ar: float = 0.5 * ((vt[b] - vt[a]).cross(vt[c] - vt[a])).length()
				var slot: int = clampi(int(((uv[a].x + uv[b].x + uv[c].x) / 3.0) * 32.0), 0, 31)
				area[slot] = float(area.get(slot, 0.0)) + ar
				i += 3
	var keys := area.keys()
	keys.sort_custom(func(x, y): return area[x] > area[y])
	var tot := 0.0
	for k in keys:
		tot += area[k]
	for k in keys:
		print("  slot %2d  hex %s  arie %7.2f m2  (%5.1f%%)" % [
			k, Palette.HEX[k], area[k], 100.0 * area[k] / tot])
	get_tree().quit(0)
