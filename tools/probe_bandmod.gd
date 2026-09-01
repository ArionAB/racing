extends SceneTree
func _init() -> void:
	for path in ["res://assets/models/cappadocia/rocks/cliff_band_module.glb",
			"res://assets/models/cappadocia/props/balloon_landed.glb",
			"res://assets/models/cappadocia/rocks/chimney_a.glb"]:
		var sc: PackedScene = load(path)
		var inst := sc.instantiate()
		print("=== %s ===" % path.get_file())
		_walk(inst, 0)
		inst.free()
	quit()

func _walk(n: Node, d: int) -> void:
	var pad := "  ".repeat(d)
	if n is MeshInstance3D and n.mesh != null:
		var m: Mesh = n.mesh
		var a: AABB = m.get_aabb()
		# normale: cate fete au normala predominant in sus
		var up := 0
		var tot := 0
		for s in m.get_surface_count():
			var arr: Array = m.surface_get_arrays(s)
			var nor: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
			for v in nor:
				tot += 1
				if v.y > 0.6: up += 1
		print("%s%s  aabb=(%.2f,%.2f,%.2f) verts=%d  normale-sus=%d (%.0f%%)" % [
			pad, n.name, a.size.x, a.size.y, a.size.z, tot, up,
			100.0 * float(up) / maxf(1.0, float(tot))])
	else:
		print("%s%s [%s]" % [pad, n.name, n.get_class()])
	for c in n.get_children():
		_walk(c, d + 1)
