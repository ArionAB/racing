extends SceneTree
func _init() -> void:
	for n in ["rocks/chimney_a","rocks/chimney_b","rocks/chimney_c","rocks/chimney_d",
			"rocks/chimney_mushroom","rocks/chimney_triple","rocks/cracked_chimney_a",
			"rocks/cracked_chimney_b","rocks/cracked_chimney_c","plants/shrub_dry"]:
		var p := "res://assets/models/cappadocia/%s.glb" % n
		var sc: PackedScene = load(p)
		var inst := sc.instantiate()
		var aabb := AABB(); var first := true; var tris := 0
		for m in _m(inst):
			var a: AABB = m.mesh.get_aabb()
			if first: aabb = a; first = false
			else: aabb = aabb.merge(a)
			for s in m.mesh.get_surface_count():
				tris += m.mesh.surface_get_array_index_len(s) / 3
		print("%-26s h=%.2f  w=%.2f  tri=%d" % [n.get_file(), aabb.size.y, aabb.size.x, tris])
		inst.free()
	quit()
func _m(n: Node) -> Array:
	var o := []
	if n is MeshInstance3D and n.mesh != null: o.append(n)
	for c in n.get_children(): o.append_array(_m(c))
	return o
