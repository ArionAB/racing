extends SceneTree
## Pe ce sloturi cad UV-urile hornurilor, si cu ce pondere de ARIE.
## Ancheta pentru dungile portocaliu/alb de pe captura r2l: e maturare de atlas
## (capcana din world_prop) sau chiar asa e pictata piesa?
func _init() -> void:
	for n in ["chimney_a", "chimney_b", "chimney_c", "chimney_d",
			"chimney_mushroom", "chimney_triple", "cracked_chimney_a",
			"cracked_chimney_c"]:
		var sc: PackedScene = load(
			"res://assets/models/cappadocia/rocks/%s.glb" % n)
		var inst := sc.instantiate()
		var hist := {}
		var total := 0.0
		for mi in _m(inst):
			var mesh: Mesh = mi.mesh
			for si in mesh.get_surface_count():
				var arr: Array = mesh.surface_get_arrays(si)
				var v: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
				var uv: PackedVector2Array = arr[Mesh.ARRAY_TEX_UV]
				var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
				for t in range(0, idx.size(), 3):
					var a: Vector3 = v[idx[t]]
					var b: Vector3 = v[idx[t + 1]]
					var c: Vector3 = v[idx[t + 2]]
					var area: float = 0.5 * (b - a).cross(c - a).length()
					var slot: int = int(uv[idx[t]].x * 32.0)
					hist[slot] = float(hist.get(slot, 0.0)) + area
					total += area
		var parts := PackedStringArray()
		var keys := hist.keys()
		keys.sort()
		for k in keys:
			var pct: float = 100.0 * float(hist[k]) / total
			if pct >= 1.0:
				parts.append("slot %d = %.0f%%" % [k, pct])
		print("%-22s %s" % [n, ", ".join(parts)])
		inst.free()
	quit()

func _m(n: Node) -> Array:
	var o := []
	if n is MeshInstance3D and n.mesh != null:
		o.append(n)
	for c in n.get_children():
		o.append_array(_m(c))
	return o
